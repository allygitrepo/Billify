const express = require("express");
const router = express.Router();

const { authenticate } = require("./middleware/auth.middleware");

// Role Routes
const roleRoutes = require("./modules/roles/role.routes");
router.use("/roles", authenticate, roleRoutes);

// Role Permission Routes
const rolePermissionRoutes = require("./modules/role_permission/role_permission.routes");
router.use("/role-permissions", authenticate, rolePermissionRoutes);

// Auth Routes
const authRoutes = require("./modules/users/auth.routes");
router.use("/auth", authRoutes); // Public

// User Routes
const userRoutes = require("./modules/users/users.routes");
router.use("/users", authenticate, userRoutes);

// Business Routes
const businessRoutes = require("./modules/businesses/businesses.routes");
router.use("/businesses", authenticate, businessRoutes);

// User-Business Mapping Routes
const userBusinessRoutes = require("./modules/users/user_businesses.routes");
router.use("/user-businesses", authenticate, userBusinessRoutes);

module.exports = router;

