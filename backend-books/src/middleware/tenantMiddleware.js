// src/middleware/tenantMiddleware.js

/**
 * Global Data Isolation Middleware
 * This middleware ensures that every database query is scoped to the logged-in user's organization.
 */
const tenantMiddleware = (req, res, next) => {
  // 1. Ensure the user is logged in (authMiddleware should run before this)
  if (!req.user) {
    return res.status(401).json({ message: "Unauthorized" });
  }

  // 2. Super Admins bypass tenant isolation to see all data
  if (req.user.role === 'Super Admin') {
    req.tenantId = null; // null means no filtering
    return next();
  }

  // 3. For everyone else (Org Admin, Accountant, Staff), strictly enforce their organization
  if (!req.user.organization_id) {
    return res.status(403).json({ 
      message: "Data Access Denied: You are not assigned to an organization." 
    });
  }

  // 4. Attach the exact organization_id to the request object
  req.tenantId = req.user.organization_id;

  next();
};

module.exports = tenantMiddleware;
