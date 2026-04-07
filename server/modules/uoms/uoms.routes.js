const express = require("express");
const router = express.Router();
const uomsController = require("./uoms.controller");
const { authenticate } = require("../../middleware/auth.middleware");
const { authorize } = require("../../middleware/permission.middleware");

router.post("/create", authenticate, authorize('uom', 'can_add'), uomsController.createUOM);
router.get("/business/:business_id", authenticate, authorize('uom', 'can_view'), uomsController.getUOMsByBusinessId);
router.put("/update/:id", authenticate, authorize('uom', 'can_update'), uomsController.updateUOM);
router.delete("/delete/:id", authenticate, authorize('uom', 'can_delete'), uomsController.deleteUOM);

module.exports = router;
