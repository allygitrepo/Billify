const express = require("express");
const router = express.Router();

// Role Routes
const roleRoutes = require("./modules/roles/role.routes");
router.use("/roles", roleRoutes);

// Role Permission Routes
const rolePermissionRoutes = require("./modules/role_permission/role_permission.routes");
router.use("/role-permissions", rolePermissionRoutes);

module.exports = router;
