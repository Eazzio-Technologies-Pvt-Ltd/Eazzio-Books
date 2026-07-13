const pool = require("../config/db");

const checkSubscription = (resourceType) => {
  return async (req, res, next) => {
    // TEMPORARILY DISABLED FOR DEMO: By-pass all subscription locks
    return next();

    // Only apply limits for POST requests (creating new resources), unless it's a premium feature check
    if (req.method !== 'POST' && resourceType !== 'premium_feature') return next();

    const tenantId = req.tenantId || req.user.organization_id;
    if (!tenantId) return next();

    try {
      const orgResult = await pool.query("SELECT plan_id FROM organizations WHERE id = $1", [tenantId]);
      if (orgResult.rows.length === 0) return next();

      const planId = orgResult.rows[0].plan_id || 'free';

      if (planId === 'free') {
        if (resourceType === 'customer') {
          const countRes = await pool.query("SELECT COUNT(*) FROM customers WHERE organization_id = $1", [tenantId]);
          if (parseInt(countRes.rows[0].count) >= 50) {
            return res.status(403).json({ 
              message: "Limit Reached", 
              upgradeNudge: "Ready for vendors, inventory, and cash flow forecasting? Standard Premium starts at ₹749/month." 
            });
          }
        }
        
        if (resourceType === 'invoice') {
          // Count invoices in the current month
          const countRes = await pool.query(
            `SELECT COUNT(*) FROM invoices 
             WHERE organization_id = $1 
             AND EXTRACT(MONTH FROM invoice_date) = EXTRACT(MONTH FROM CURRENT_DATE)
             AND EXTRACT(YEAR FROM invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE)`,
            [tenantId]
          );
          if (parseInt(countRes.rows[0].count) >= 100) {
            return res.status(403).json({ 
              message: "Limit Reached", 
              upgradeNudge: "Ready for vendors, inventory, and cash flow forecasting? Standard Premium starts at ₹749/month." 
            });
          }
        }

        if (resourceType === 'premium_feature') {
          return res.status(403).json({ 
            message: "Premium Feature", 
            upgradeNudge: "Ready for vendors, inventory, and cash flow forecasting? Standard Premium starts at ₹749/month." 
          });
        }

        if (resourceType === 'user') {
          const countRes = await pool.query("SELECT COUNT(*) FROM users WHERE organization_id = $1", [tenantId]);
          if (parseInt(countRes.rows[0].count) >= 1) {
            return res.status(403).json({ 
              message: "Limit Reached", 
              upgradeNudge: "Ready for vendors, inventory, and cash flow forecasting? Standard Premium starts at ₹749/month." 
            });
          }
        }
      }

      next();
    } catch (err) {
      console.error("Subscription check error:", err);
      next(err);
    }
  };
};

module.exports = checkSubscription;
