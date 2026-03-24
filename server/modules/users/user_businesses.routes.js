const express = require("express");
const router = express.Router();
const userBusinessController = require("./user_businesses.controller");

// Assign/Update user role in a business
router.post("/assign-user", userBusinessController.assignUser);

module.exports = router;
