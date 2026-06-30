const express = require("express");
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');
const tenantMiddleware = require('../middleware/tenantMiddleware');
const { requirePermission } = require('../middleware/roleMiddleware');
const { MODULES, ACTIONS } = require('../config/permissions');
const {
  getItems,
  getItemById,
  createItem,
  updateItem,
  deleteItem,
  getItemHistory,
  getItemMovements,
  getLowStockItems,
} = require("../controllers/itemController");

// All routes require authentication + tenant isolation
router.get("/items", authMiddleware, tenantMiddleware, requirePermission(MODULES.ITEMS, ACTIONS.VIEW), getItems);
router.get("/items/low-stock", authMiddleware, tenantMiddleware, requirePermission(MODULES.ITEMS, ACTIONS.VIEW), getLowStockItems);
router.get("/items/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.ITEMS, ACTIONS.VIEW), getItemById);
router.get("/items/:id/history", authMiddleware, tenantMiddleware, requirePermission(MODULES.ITEMS, ACTIONS.VIEW), getItemHistory);
router.get("/items/:id/movements", authMiddleware, tenantMiddleware, requirePermission(MODULES.ITEMS, ACTIONS.VIEW), getItemMovements);
router.post("/items", authMiddleware, tenantMiddleware, requirePermission(MODULES.ITEMS, ACTIONS.CREATE), createItem);
router.put("/items/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.ITEMS, ACTIONS.EDIT), updateItem);
router.delete("/items/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.ITEMS, ACTIONS.DELETE), deleteItem);

module.exports = router;