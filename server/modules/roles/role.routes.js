const express = require("express");
const router = express.Router();
const rolesController = require("./roles.controller");

// Role Routes
router.post("/create", rolesController.createRole);
router.get("/", rolesController.getAllRoles);
router.get("/:id", rolesController.getRoleById);
router.get("/business/:business_id", rolesController.getRolesByBusinessId);
router.put("/update/:id", rolesController.updateRole);
router.delete("/delete/:id", rolesController.deleteRole);

module.exports = router;
