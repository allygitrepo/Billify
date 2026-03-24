const express = require("express");
const router = express.Router();
const rolesController = require("./roles.controller");

// Role Routes
router.post("/create", rolesController.createRole);
router.get("/", rolesController.getAllRoles);
router.get("/business/:business_id", rolesController.getRolesByBusinessId); // Specific route above :id
router.get("/:id", rolesController.getRoleById);
router.put("/update/:id", rolesController.updateRole);
router.delete("/delete/:id", rolesController.deleteRole);

module.exports = router;
