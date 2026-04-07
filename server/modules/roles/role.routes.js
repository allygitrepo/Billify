const express = require("express");
const router = express.Router();
const rolesController = require("./roles.controller");

const { authenticate } = require("../../middleware/auth.middleware");
const { authorize } = require("../../middleware/permission.middleware");

// Role Routes
router.post("/create", authenticate, authorize('userManagement', 'can_add'), rolesController.createRole);
router.get("/", authenticate, authorize('userManagement', 'can_view'), rolesController.getAllRoles);
router.get("/business/:business_id", authenticate, authorize('userManagement', 'can_view'), rolesController.getRolesByBusinessId); // Specific route above :id
router.get("/:id", authenticate, authorize('userManagement', 'can_view'), rolesController.getRoleById);
router.put("/update/:id", authenticate, authorize('userManagement', 'can_update'), rolesController.updateRole);
router.delete("/delete/:id", authenticate, authorize('userManagement', 'can_delete'), rolesController.deleteRole);

module.exports = router;
