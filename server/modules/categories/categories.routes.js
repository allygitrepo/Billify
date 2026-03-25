const express = require("express");
const router = express.Router();
const categoriesController = require("./categories.controller");

router.post("/create", categoriesController.createCategory);
router.get("/business/:business_id", categoriesController.getCategoriesByBusinessId);
router.put("/update/:id", categoriesController.updateCategory);
router.delete("/delete/:id", categoriesController.deleteCategory);

module.exports = router;
