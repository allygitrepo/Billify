const express = require("express");
const router = express.Router();
const inventoryController = require("./inventory.controller");
const { authenticate } = require("../../middleware/auth.middleware");
const { authorize } = require("../../middleware/permission.middleware");

router.get("/business/:business_id", authenticate, authorize('inventory', 'can_view'), inventoryController.getInventoryLog);
router.post("/update-stock", authenticate, authorize('inventory', 'can_update'), inventoryController.manualStockUpdate);

module.exports = router;
