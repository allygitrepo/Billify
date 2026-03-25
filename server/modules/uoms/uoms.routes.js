const express = require("express");
const router = express.Router();
const uomsController = require("./uoms.controller");

router.post("/create", uomsController.createUOM);
router.get("/business/:business_id", uomsController.getUOMsByBusinessId);
router.put("/update/:id", uomsController.updateUOM);
router.delete("/delete/:id", uomsController.deleteUOM);

module.exports = router;
