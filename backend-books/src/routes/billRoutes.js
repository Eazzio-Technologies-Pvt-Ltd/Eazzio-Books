const express = require("express");
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');
const tenantMiddleware = require('../middleware/tenantMiddleware');
const { requirePermission } = require('../middleware/roleMiddleware');
const { MODULES, ACTIONS } = require('../config/permissions');
const {
  getBills,
  getBillById,
  createBill,
  updateBill,
  deleteBill,
} = require("../controllers/billController");

router.get("/bills",     authMiddleware, tenantMiddleware, requirePermission(MODULES.BILLS, ACTIONS.VIEW), getBills);
router.get("/bills/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.BILLS, ACTIONS.VIEW), getBillById);
router.post("/bills",    authMiddleware, tenantMiddleware, requirePermission(MODULES.BILLS, ACTIONS.CREATE), createBill);
router.put("/bills/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.BILLS, ACTIONS.EDIT), updateBill);
router.delete("/bills/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.BILLS, ACTIONS.DELETE), deleteBill);

module.exports = router;
