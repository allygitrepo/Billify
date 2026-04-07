const express = require("express");
const router = express.Router();
const productsController = require("./products.controller");
const { authenticate } = require("../../middleware/auth.middleware");
const { authorize } = require("../../middleware/permission.middleware");

router.post("/create", authenticate, authorize('products', 'can_add'), productsController.createProduct);
router.get("/business/:business_id", authenticate, authorize('products', 'can_view'), productsController.getProductsByBusinessId);
router.put("/update/:id", authenticate, authorize('products', 'can_update'), productsController.updateProduct);
router.delete("/delete/:id", authenticate, authorize('products', 'can_delete'), productsController.deleteProduct);

module.exports = router;
