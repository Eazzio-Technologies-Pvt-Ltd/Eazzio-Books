const express = require("express");
const router = express.Router();
const dashboardController = require("../controllers/dashboardController");
const authMiddleware = require("../middleware/authMiddleware");
const { requirePermission } = require("../middleware/roleMiddleware");
const { MODULES, ACTIONS } = require("../config/permissions");

router.get("/finance-summary", 
  authMiddleware, 
  requirePermission(MODULES.DASHBOARD, ACTIONS.VIEW), 
  dashboardController.getFinanceSummary
);

router.get("/monthly-finance-summary", 
  authMiddleware, 
  requirePermission(MODULES.DASHBOARD, ACTIONS.VIEW), 
  dashboardController.getMonthlyFinanceSummary
);

module.exports = router;
