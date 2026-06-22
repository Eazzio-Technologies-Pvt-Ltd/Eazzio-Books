const jwt = require("jsonwebtoken");
const pool = require("../config/db");

const authMiddleware = async (req, res, next) => {
  const token = req.cookies.token;

  if (!token) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;

    // Check if the current request is for one of the allowed/bypassed endpoints
    const path = req.path.toLowerCase();
    const isExcluded = path.includes('/logout') || 
                       path.includes('/profile') || 
                       path.includes('/subscription/renew') || 
                       path.includes('/subscription/create-order') ||
                       path.includes('/login') ||
                       path.includes('/register');

    if (!isExcluded && req.user.organization_id) {
      // Query the database for the organization's subscription status
      const orgResult = await pool.query(
        "SELECT plan_id, subscription_expires_at FROM organizations WHERE id = $1",
        [req.user.organization_id]
      );

      if (orgResult.rows.length > 0) {
        const { plan_id, subscription_expires_at } = orgResult.rows[0];
        
        // Block request if the plan is paid and subscription has expired
        if (plan_id && plan_id !== 'free') {
          if (!subscription_expires_at || new Date(subscription_expires_at) < new Date()) {
            return res.status(402).json({ message: "Subscription expired. Payment required." });
          }
        }
      }
    }

    next();
  } catch (err) {
    return res.status(401).json({ message: "Invalid token" });
  }
};

module.exports = authMiddleware;