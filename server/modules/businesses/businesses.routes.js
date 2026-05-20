const express = require("express");
const router = express.Router();
const businessController = require("./businesses.controller");
const { authenticate } = require("../../middleware/auth.middleware");
const { authorize } = require("../../middleware/permission.middleware");

// Get user's businesses
router.get("/my-businesses", authenticate, businessController.getMyBusinesses);

// Create new business
router.post("/", authenticate, businessController.createBusiness);

// Update business
router.put("/:id", authenticate, authorize('businesses', 'can_update'), businessController.updateBusiness);

// Delete business
router.delete("/:id", authenticate, authorize('businesses', 'can_delete'), businessController.deleteBusiness);

// WhatsApp Integration Routes
router.post("/:id/whatsapp/initiate", authenticate, businessController.initiateWhatsApp);
router.get("/:id/whatsapp/status", authenticate, businessController.getWhatsAppStatus);
router.delete("/:id/whatsapp/delete", authenticate, businessController.deleteWhatsApp);
router.post("/:id/whatsapp/send-media", authenticate, businessController.sendWhatsAppMedia);
router.post("/:id/whatsapp/send-bulk", authenticate, businessController.sendWhatsAppBulk);

module.exports = router;
