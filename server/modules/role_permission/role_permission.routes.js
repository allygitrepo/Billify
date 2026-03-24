const express = require("express");
const router = express.Router();
const rolePermissionController = require("./role_permission.controller");

// Save or Update Permissions
router.post("/", rolePermissionController.savePermissions);

// Get Permissions by Role ID
router.get("/:role_id", rolePermissionController.getPermissionsByRoleId);

module.exports = router;
