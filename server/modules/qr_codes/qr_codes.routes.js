const express = require("express");
const router = express.Router();
const qrCodesController = require("./qr_codes.controller");

router.get("/business/:business_id", qrCodesController.getByBusiness);
router.get("/:id", qrCodesController.getById);
router.delete("/:id", qrCodesController.delete);

module.exports = router;
