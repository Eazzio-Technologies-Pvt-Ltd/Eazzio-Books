const pool = require("../config/db");
const Razorpay = require("razorpay");
const crypto = require("crypto");

// Pricing plan configurations
const PLANS = {
  free: { price: 0, name: "Free Plan" },
  premium: { price: 749, name: "Standard Premium" },
  professional: { price: 1499, name: "Professional" },
  enterprise: { price: 1999, name: "Enterprise" }
};

// Initialize Razorpay client safely
const getRazorpayInstance = () => {
  const keyId = process.env.RAZORPAY_KEY_ID || 'rzp_live_T30ux1vLXgkLFL';
  const keySecret = process.env.RAZORPAY_KEY_SECRET || 'OolUbfvItr07ZLATzKGCjmyg';
  
  if (!keyId || !keySecret) {
    console.warn("WARNING: Razorpay keys are not fully configured in environment.");
  }
  
  return new Razorpay({
    key_id: keyId,
    key_secret: keySecret
  });
};

// Automatically ensure schema columns exist on startup (self-healing db layer)
const ensureSubscriptionSchema = async () => {
  try {
    // 1. Add subscription columns to organizations if missing
    await pool.query(`
      ALTER TABLE organizations 
      ADD COLUMN IF NOT EXISTS plan_id VARCHAR(50) DEFAULT 'free'
    `);
    
    await pool.query(`
      ALTER TABLE organizations 
      ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMP DEFAULT NULL
    `);

    // 2. Create payment_transactions table if missing
    await pool.query(`
      CREATE TABLE IF NOT EXISTS payment_transactions (
        id SERIAL PRIMARY KEY,
        organization_id INTEGER REFERENCES organizations(id) ON DELETE CASCADE,
        razorpay_order_id VARCHAR(255) NOT NULL,
        razorpay_payment_id VARCHAR(255),
        razorpay_signature VARCHAR(255),
        amount NUMERIC(12,2) NOT NULL,
        currency VARCHAR(10) DEFAULT 'INR',
        status VARCHAR(50) NOT NULL,
        plan_id VARCHAR(50) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    console.log("Subscription DB columns and logging table verified successfully.");
  } catch (err) {
    console.error("ensureSubscriptionSchema error:", err);
  }
};
ensureSubscriptionSchema();

/**
 * Generate Razorpay Order for new user registration
 */
const createRegisterOrder = async (req, res) => {
  const { plan_id } = req.body;
  
  if (!plan_id || !PLANS[plan_id]) {
    return res.status(400).json({ message: "Invalid or missing plan ID." });
  }
  
  if (plan_id === 'free') {
    return res.status(400).json({ message: "Free plan does not require a payment order." });
  }

  try {
    const razorpay = getRazorpayInstance();
    const plan = PLANS[plan_id];
    
    const options = {
      amount: plan.price * 100, // Razorpay amount in paise
      currency: "INR",
      receipt: `reg_order_${Date.now()}`
    };
    
    const order = await razorpay.orders.create(options);
    
    res.json({
      success: true,
      order,
      keyId: process.env.RAZORPAY_KEY_ID || 'rzp_live_T30ux1vLXgkLFL'
    });
  } catch (err) {
    console.error("CREATE REGISTER ORDER ERROR:", err);
    res.status(500).json({ message: "Failed to generate payment order." });
  }
};

/**
 * Generate Razorpay Order for renewing an active or expired subscription
 */
const createRenewOrder = async (req, res) => {
  const { plan_id } = req.body;
  
  if (!plan_id || !PLANS[plan_id]) {
    return res.status(400).json({ message: "Invalid or missing plan ID." });
  }
  
  if (plan_id === 'free') {
    return res.status(400).json({ message: "Free plan does not require renewal payment." });
  }

  try {
    const razorpay = getRazorpayInstance();
    const plan = PLANS[plan_id];
    
    const options = {
      amount: plan.price * 100,
      currency: "INR",
      receipt: `renew_order_${req.user.organization_id}_${Date.now()}`
    };
    
    const order = await razorpay.orders.create(options);
    
    res.json({
      success: true,
      order,
      keyId: process.env.RAZORPAY_KEY_ID || 'rzp_live_T30ux1vLXgkLFL'
    });
  } catch (err) {
    console.error("CREATE RENEW ORDER ERROR:", err);
    res.status(500).json({ message: "Failed to generate renewal payment order." });
  }
};

/**
 * Verify renewal payment signature and extend organization subscription by 30 days
 */
const renewSubscription = async (req, res) => {
  const { plan_id, razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;
  const orgId = req.user.organization_id;

  if (!plan_id || !razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
    return res.status(400).json({ message: "Missing required payment verification details." });
  }

  if (!PLANS[plan_id] || plan_id === 'free') {
    return res.status(400).json({ message: "Invalid plan ID for subscription renewal." });
  }

  // Verify payment signature
  const keySecret = process.env.RAZORPAY_KEY_SECRET || 'OolUbfvItr07ZLATzKGCjmyg';
  const generated_signature = crypto
    .createHmac("sha256", keySecret)
    .update(razorpay_order_id + "|" + razorpay_payment_id)
    .digest("hex");

  if (generated_signature !== razorpay_signature) {
    return res.status(400).json({ message: "Invalid payment signature verification failed." });
  }

  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    // Fetch current subscription status of organization
    const orgRes = await client.query(
      "SELECT plan_id, subscription_expires_at FROM organizations WHERE id = $1", 
      [orgId]
    );

    if (orgRes.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({ message: "Organization not found." });
    }

    const currentExpiry = orgRes.rows[0].subscription_expires_at;
    let newExpiry;
    
    // If current expiry is in the future, extend from that timestamp. Otherwise, start from now.
    if (currentExpiry && new Date(currentExpiry) > new Date()) {
      newExpiry = new Date(new Date(currentExpiry).getTime() + 30 * 24 * 60 * 60 * 1000);
    } else {
      newExpiry = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    }

    // Update organization plan and expiration
    await client.query(
      `UPDATE organizations 
       SET plan_id = $1, subscription_expires_at = $2 
       WHERE id = $3`,
      [plan_id, newExpiry, orgId]
    );

    // Record the transaction log
    await client.query(
      `INSERT INTO payment_transactions (organization_id, razorpay_order_id, razorpay_payment_id, razorpay_signature, amount, plan_id, status)
       VALUES ($1, $2, $3, $4, $5, $6, 'paid')`,
      [orgId, razorpay_order_id, razorpay_payment_id, razorpay_signature, PLANS[plan_id].price, plan_id]
    );

    await client.query("COMMIT");
    
    res.json({
      success: true,
      message: `Subscription successfully renewed for ${PLANS[plan_id].name}.`,
      plan_id,
      subscription_expires_at: newExpiry
    });
  } catch (err) {
    await client.query("ROLLBACK");
    console.error("RENEW SUBSCRIPTION ERROR:", err);
    res.status(500).json({ message: "Failed to renew subscription." });
  } finally {
    client.release();
  }
};

module.exports = {
  createRegisterOrder,
  createRenewOrder,
  renewSubscription,
  PLANS
};
