const express = require("express");
const router = express.Router();
const businessController = require("./businesses.controller");
const { authenticate } = require("../../middleware/auth.middleware");

// Get user's businesses
router.get("/my-businesses", authenticate, businessController.getMyBusinesses);

// Create new business
router.post("/", authenticate, businessController.createBusiness);

// Update business
router.put("/:id", authenticate, businessController.updateBusiness);

// Delete business
router.delete("/:id", authenticate, businessController.deleteBusiness);

module.exports = router;
