const express = require("express");
const router = express.Router();
const usersController = require("./users.controller");

// Get users associated with a business
router.get("/business/:business_id", usersController.getUsersByBusiness);

// Create and assign user
router.post("/create", usersController.createUser);

// Update user
router.put("/update/:id", usersController.updateUser);

// Delete/Remove user from business
router.delete("/delete/:id", usersController.deleteUser);

// Change password
router.post("/change-password", usersController.changePassword);

// Update profile (own data)
router.put("/profile/update", usersController.updateProfile);

module.exports = router;
