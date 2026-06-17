const express = require("express");
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');
const tenantMiddleware = require('../middleware/tenantMiddleware');
const { requirePermission } = require('../middleware/roleMiddleware');
const { MODULES, ACTIONS } = require('../config/permissions');
const {
  getVendors,
  getVendorById,
  createVendor,
  updateVendor,
  deleteVendor,
} = require("../controllers/vendorController");

router.get("/vendors",     authMiddleware, tenantMiddleware, requirePermission(MODULES.VENDORS, ACTIONS.VIEW), getVendors);
router.get("/vendors/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.VENDORS, ACTIONS.VIEW), getVendorById);
router.post("/vendors",    authMiddleware, tenantMiddleware, requirePermission(MODULES.VENDORS, ACTIONS.CREATE), createVendor);
router.put("/vendors/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.VENDORS, ACTIONS.EDIT), updateVendor);
router.delete("/vendors/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.VENDORS, ACTIONS.DELETE), deleteVendor);

module.exports = router;
