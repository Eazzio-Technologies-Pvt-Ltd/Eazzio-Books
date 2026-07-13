const express = require("express");
const router = express.Router();
const notificationController = require("../controllers/notificationController");
const authMiddleware = require("../middleware/authMiddleware");
const tenantMiddleware = require("../middleware/tenantMiddleware");

// All routes require authentication and tenant isolation
router.use(authMiddleware);
router.use(tenantMiddleware);

router.get("/", notificationController.getNotifications);

module.exports = router;
