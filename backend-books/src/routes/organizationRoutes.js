const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const { requirePermission } = require("../middleware/roleMiddleware");
const { MODULES, ACTIONS } = require("../config/permissions");
const {
  getOrganizations,
  onboardOrganization,
  toggleOrganizationStatus,
  createOrganization,
  getMyOrganizations,
  switchOrganization
} = require("../controllers/organizationController");

// All routes are strictly Super Admin only — ORGANIZATIONS module is blocked for all other roles
router.get(
  "/organizations",
  authMiddleware,
  requirePermission(MODULES.ORGANIZATIONS, ACTIONS.VIEW),
  getOrganizations
);

router.post(
  "/organizations",
  authMiddleware,
  requirePermission(MODULES.ORGANIZATIONS, ACTIONS.CREATE),
  onboardOrganization
);

router.patch(
  "/organizations/:id/toggle-status",
  authMiddleware,
  requirePermission(MODULES.ORGANIZATIONS, ACTIONS.MANAGE),
  toggleOrganizationStatus
);

// Routes for regular Admins to manage their 5 organizations
router.get(
  "/my-organizations",
  authMiddleware,
  getMyOrganizations
);

router.post(
  "/my-organizations",
  authMiddleware,
  createOrganization
);

router.post(
  "/switch-organization/:id",
  authMiddleware,
  switchOrganization
);

module.exports = router;
