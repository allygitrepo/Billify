const express = require("express");
const router = express.Router();
const businessController = require("./businesses.controller");
const { authenticate } = require("../../middleware/auth.middleware");

// Get user's businesses
router.get("/my-businesses", authenticate, businessController.getMyBusinesses);

module.exports = router;
