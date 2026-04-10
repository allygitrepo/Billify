const express = require("express");
const router = express.Router();
const analyticsController = require("./analytics.controller");

router.get("/sales/summary/:businessId", analyticsController.getSalesSummary);
router.get("/sales/trend/:businessId", analyticsController.getSalesTrend);
router.get("/sales/top-products/:businessId", analyticsController.getTopProducts);
router.get("/sales/category-wise/:businessId", analyticsController.getCategorySales);
router.get("/sales/payment-summary/:businessId", analyticsController.getPaymentSummary);
router.get("/sales/invoices/:businessId", analyticsController.getSalesList);

// Profit Routes
router.get("/profit/:businessId", analyticsController.getProfitSummary);
router.get("/profit/products/:businessId", analyticsController.getProfitByProducts);
router.get("/profit/categories/:businessId", analyticsController.getProfitByCategories);

// Customer Routes
router.get("/customers/:businessId", analyticsController.getCustomersAnalytics);

// Khata Routes
router.get("/khata/summary/:businessId", analyticsController.getKhataSummary);
router.get("/khata/due/:businessId", analyticsController.getKhataDueReport);
router.get("/khata/payments/:businessId", analyticsController.getKhataPayments);
router.get("/khata/credit/:businessId", analyticsController.getKhataCreditReport);
router.get("/khata/customers/:businessId", analyticsController.getKhataCustomersAnalytics);

module.exports = router;
