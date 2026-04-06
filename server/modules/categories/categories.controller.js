const Category = require("./categories.model");
const Product = require("../products/products.model");

const categoriesController = {
    // ============ Create Category ============
    createCategory: async (req, res) => {
        try {
            const { business_id, name, description, status } = req.body;

            if (!business_id || !name) {
                return res.status(400).json({ message: "Business ID and Name are required" });
            }

            // Check for collision
            const existingCategory = await Category.findOne({
                where: { business_id, name, status: 'active' }
            });
            if (existingCategory) {
                return res.status(409).json({ message: `Category "${name}" already exists` });
            }

            const category = await Category.create({
                business_id,
                name,
                description,
                status: status || 'active'
            });

            return res.status(201).json({
                message: "Category created successfully",
                category
            });
        } catch (error) {
            console.error("Create Category Error:", error);
            if (error.name === 'SequelizeUniqueConstraintError') {
                return res.status(409).json({ message: `A category with this name already exists.` });
            }
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Get Categories by Business ID ============
    getCategoriesByBusinessId: async (req, res) => {
        try {
            const { business_id } = req.params;
            const categories = await Category.findAll({ 
                where: { business_id, status: 'active' } 
            });
            return res.status(200).json({ categories });
        } catch (error) {
            console.error("Get Categories Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Update Category ============
    updateCategory: async (req, res) => {
        try {
            const { id } = req.params;
            const { name, description, status } = req.body;

            const category = await Category.findByPk(id);
            if (!category) {
                return res.status(404).json({ message: "Category not found" });
            }

            await category.update({
                name: name || category.name,
                description: description !== undefined ? description : category.description,
                status: status || category.status
            });

            return res.status(200).json({
                message: "Category updated successfully",
                category
            });
        } catch (error) {
            console.error("Update Category Error:", error);
            if (error.name === 'SequelizeUniqueConstraintError') {
                return res.status(409).json({ message: `A category with this name already exists.` });
            }
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Delete Category (Soft Delete) ============
    deleteCategory: async (req, res) => {
        try {
            const { id } = req.params;
            const category = await Category.findByPk(id);
            if (!category) {
                return res.status(404).json({ message: "Category not found" });
            }

            // Soft delete by setting status to inactive
            await category.update({ status: 'inactive' });
            
            // Optionally: Handle associated products status as well?
            // User said: "This will also delete all associated products" in UI
            await Product.update({ status: 'inactive' }, { where: { category_id: id } });

            return res.status(200).json({ message: "Category deleted successfully" });
        } catch (error) {
            console.error("Delete Category Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = categoriesController;
