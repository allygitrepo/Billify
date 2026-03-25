const express = require("express");
const router = express.Router();
const productsController = require("./products.controller");

router.post("/create", productsController.createProduct);
router.get("/business/:business_id", productsController.getProductsByBusinessId);
router.put("/update/:id", productsController.updateProduct);
router.delete("/delete/:id", productsController.deleteProduct);

module.exports = router;
