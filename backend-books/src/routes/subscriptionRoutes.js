const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const {
  createRegisterOrder,
  createRenewOrder,
  renewSubscription
} = require("../controllers/subscriptionPaymentController");

// Public endpoint for order creation during registration
router.post("/register/create-order", createRegisterOrder);

// Authenticated endpoints for renewals
router.post("/subscription/create-order", authMiddleware, createRenewOrder);
router.post("/subscription/renew", authMiddleware, renewSubscription);

module.exports = router;
