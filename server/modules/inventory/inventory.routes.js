const express = require("express");
const router = express.Router();
const inventoryController = require("./inventory.controller");

router.get("/business/:business_id", inventoryController.getInventoryLog);
router.post("/update-stock", inventoryController.manualStockUpdate);

module.exports = router;
