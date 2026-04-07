const express = require("express");
const router = express.Router();
const categoriesController = require("./categories.controller");
const { authenticate } = require("../../middleware/auth.middleware");
const { authorize } = require("../../middleware/permission.middleware");

router.post("/create", authenticate, authorize('categories', 'can_add'), categoriesController.createCategory);
router.get("/business/:business_id", authenticate, authorize('categories', 'can_view'), categoriesController.getCategoriesByBusinessId);
router.put("/update/:id", authenticate, authorize('categories', 'can_update'), categoriesController.updateCategory);
router.delete("/delete/:id", authenticate, authorize('categories', 'can_delete'), categoriesController.deleteCategory);

module.exports = router;
