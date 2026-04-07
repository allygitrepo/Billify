const express = require("express");
const router = express.Router();
const paymentsController = require("./payments.controller");

router.post("/receive", paymentsController.receivePayment);
router.post("/give", paymentsController.givePayment);
router.get("/", paymentsController.getPayments);
router.delete("/:id", paymentsController.deletePayment);

module.exports = router;
