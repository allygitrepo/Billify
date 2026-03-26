const express = require("express");
const router = express.Router();
const settingsController = require("./settings.controller");

router.get("/business/:business_id", settingsController.getSettings);
router.put("/business/:business_id", settingsController.updateSettings);

module.exports = router;
