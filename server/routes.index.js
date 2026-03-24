const express = require("express");
const router = express.Router();

// Role Routes
const roleRoutes = require("./modules/roles/role.routes");
router.use("/roles", roleRoutes);

// Add other routes here as needed...
// const userRoutes = require("./modules/users/user.routes");
// router.use("/users", userRoutes);

module.exports = router;
