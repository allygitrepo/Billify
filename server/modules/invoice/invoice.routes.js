const express = require("express");
const router = express.Router();
const invoiceController = require("./invoice.controller");
const { authenticate } = require("../../middleware/auth.middleware");
const { authorize } = require("../../middleware/permission.middleware");

router.post("/create", authenticate, authorize('billing', 'can_add'), invoiceController.createInvoice);
router.get("/:id", authenticate, authorize('billing', 'can_view'), invoiceController.getInvoiceById);
router.get("/business/:business_id", authenticate, authorize('billing', 'can_view'), invoiceController.getInvoicesByBusiness);

module.exports = router;
