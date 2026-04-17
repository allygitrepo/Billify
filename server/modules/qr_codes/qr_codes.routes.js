const express = require("express");
const router = express.Router();
const qrCodesController = require("./qr_codes.controller");

router.get("/:business_id", qrCodesController.getQrByBusinessId);

module.exports = router;
