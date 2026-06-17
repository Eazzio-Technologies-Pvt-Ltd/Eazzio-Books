const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const tenantMiddleware = require("../middleware/tenantMiddleware");
const { getUsers, getOrganizationSettings, updateOrganizationSettings, updateUserRole, createStaffAccount } = require("../controllers/usersController");

const { requirePermission } = require("../middleware/roleMiddleware");
const { MODULES, ACTIONS } = require("../config/permissions");

router.get("/users", authMiddleware, tenantMiddleware, requirePermission(MODULES.USERS, ACTIONS.VIEW), getUsers);
router.post("/users", authMiddleware, tenantMiddleware, requirePermission(MODULES.USERS, ACTIONS.CREATE), createStaffAccount);
router.put("/users/:id/role", authMiddleware, tenantMiddleware, requirePermission(MODULES.USERS, ACTIONS.MANAGE), updateUserRole);

router.get("/organization-settings", authMiddleware, tenantMiddleware, requirePermission(MODULES.SETTINGS, ACTIONS.VIEW), getOrganizationSettings);
router.put("/organization-settings", authMiddleware, tenantMiddleware, requirePermission(MODULES.SETTINGS, ACTIONS.MANAGE), updateOrganizationSettings);

module.exports = router;