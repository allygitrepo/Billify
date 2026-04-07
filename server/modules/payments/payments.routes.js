const express = require("express");
const router = express.Router();
const paymentsController = require("./payments.controller");
const { authenticate } = require("../../middleware/auth.middleware");
const { authorize } = require("../../middleware/permission.middleware");

router.post("/receive", authenticate, authorize('payments', 'can_add'), paymentsController.receivePayment);
router.post("/give", authenticate, authorize('payments', 'can_add'), paymentsController.givePayment);
router.get("/", authenticate, authorize('payments', 'can_view'), paymentsController.getPayments);
router.delete("/:id", authenticate, authorize('payments', 'can_delete'), paymentsController.deletePayment);

module.exports = router;
