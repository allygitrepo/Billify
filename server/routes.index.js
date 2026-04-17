const express = require("express");
const router = express.Router();

const { authenticate } = require("./middleware/auth.middleware");

// Role Routes
const roleRoutes = require("./modules/roles/role.routes");
router.use("/roles", authenticate, roleRoutes);

// Role Permission Routes
const rolePermissionRoutes = require("./modules/role_permission/role_permission.routes");
router.use("/role-permissions", authenticate, rolePermissionRoutes);

// Auth Routes
const authRoutes = require("./modules/users/auth.routes");
router.use("/auth", authRoutes); // Public

// User Routes
const userRoutes = require("./modules/users/users.routes");
router.use("/users", authenticate, userRoutes);

// Business Routes
const businessRoutes = require("./modules/businesses/businesses.routes");
router.use("/businesses", authenticate, businessRoutes);

// User-Business Mapping Routes
const userBusinessRoutes = require("./modules/users/user_businesses.routes");
router.use("/user-businesses", authenticate, userBusinessRoutes);

// Category Routes
const categoryRoutes = require("./modules/categories/categories.routes");
router.use("/categories", authenticate, categoryRoutes);

// Product Routes
const productRoutes = require("./modules/products/products.routes.js");
router.use("/products", authenticate, productRoutes);

// UOM Routes
const uomRoutes = require("./modules/uoms/uoms.routes");
router.use("/uoms", authenticate, uomRoutes);

// Invoice Routes
const invoiceRoutes = require("./modules/invoice/invoice.routes");
router.use("/invoices", authenticate, invoiceRoutes);

// Inventory Routes
const inventoryRoutes = require("./modules/inventory/inventory.routes");
router.use("/inventory", authenticate, inventoryRoutes);

// Setting Routes
const settingsRoutes = require("./modules/settings/settings.routes");
router.use("/settings", authenticate, settingsRoutes);

// Customer Routes
const customerRoutes = require("./modules/customers/customers.routes");
router.use("/customers", authenticate, customerRoutes);

// Payment Routes
const paymentRoutes = require("./modules/payments/payments.routes");
router.use("/payments", authenticate, paymentRoutes);

// Analytics Routes
const analyticsRoutes = require("./modules/analytics/analytics.routes");
router.get("/analytics/test-reachability", (req, res) => res.json({ message: "Analytics route is reachable" }));
router.use("/analytics", authenticate, analyticsRoutes);

// QR Code Routes
const qrCodeRoutes = require("./modules/qr_codes/qr_codes.routes");
router.use("/qr-codes", authenticate, qrCodeRoutes);

module.exports = router;

