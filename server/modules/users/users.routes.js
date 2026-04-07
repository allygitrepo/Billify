const express = require("express");
const router = express.Router();
const usersController = require("./users.controller");

const { authenticate } = require("../../middleware/auth.middleware");
const { authorize } = require("../../middleware/permission.middleware");

// Get users associated with a business
router.get("/business/:business_id", authenticate, authorize('userManagement', 'can_view'), usersController.getUsersByBusiness);

// Create and assign user
router.post("/create", authenticate, authorize('userManagement', 'can_add'), usersController.createUser);

// Update user
router.put("/update/:id", authenticate, authorize('userManagement', 'can_update'), usersController.updateUser);

// Delete/Remove user from business
router.delete("/delete/:id", authenticate, authorize('userManagement', 'can_delete'), usersController.deleteUser);

// Change password
router.post("/change-password", usersController.changePassword);

// Update profile (own data)
router.put("/profile/update", usersController.updateProfile);

module.exports = router;
