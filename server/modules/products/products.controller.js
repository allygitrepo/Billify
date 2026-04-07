const Product = require("./products.model");
const Variant = require("../variants/variants.model");
const Category = require("../categories/categories.model");
const sequelize = require("../../config/db");

const productsController = {
    // ============ Create Product ============
    createProduct: async (req, res) => {
        const t = await sequelize.transaction();
        try {
            const { 
                business_id, 
                category_id, 
                category_name,
                name, 
                description, 
                basePrice, 
                hsnCode, 
                uom, 
                status, 
                photo,
                barcode,
                variants 
            } = req.body;

            if (!business_id || !name) {
                await t.rollback();
                return res.status(400).json({ message: "Business ID and Name are required" });
            }

            // Check for HSN collision
            if (hsnCode) {
                const existingProduct = await Product.findOne({
                    where: { business_id, hsnCode, status: 'active' }
                });
                if (existingProduct) {
                    await t.rollback();
                    return res.status(409).json({ 
                        message: `Product with HSN code ${hsnCode} already exists`,
                        existingProduct 
                    });
                }
            }

            // 1. Handle Category Auto-creation if category_id is missing but name is provided
            let finalCategoryId = category_id || null;
            if (!finalCategoryId && category_name) {
                const [category] = await Category.findOrCreate({
                    where: { business_id, name: category_name, status: 'active' },
                    defaults: { business_id, name: category_name, status: 'active' },
                    transaction: t
                });
                finalCategoryId = category.id;
            }

            // 2. Create Product
            const product = await Product.create({
                business_id,
                category_id: finalCategoryId,
                name,
                description,
                basePrice,
                hsnCode,
                uom,
                status: status || 'active',
                photo,
                barcode
            }, { transaction: t });

            // 2. Create Variants if provided, otherwise create 'Default'
            if (variants && Array.isArray(variants) && variants.length > 0) {
                const variantEntries = variants.map(v => ({
                    product_id: product.id,
                    name: v.name,
                    sku: v.sku || barcode,
                    price: v.price || basePrice,
                    stock: v.stock || 0,
                    status: v.status || 'active'
                }));
                await Variant.bulkCreate(variantEntries, { transaction: t });
            } else {
                // Create a single default variant to hold the product's basePrice and barcode
                await Variant.create({
                    product_id: product.id,
                    name: 'Default',
                    sku: barcode,
                    price: basePrice,
                    stock: 0,
                    status: 'active'
                }, { transaction: t });
            }

            await t.commit();

            const newlyCreatedProduct = await Product.findByPk(product.id, {
                include: [
                    { model: Category, as: 'category' },
                    { model: Variant, as: 'variants' }
                ]
            });
            
            // Add custom hasVariants flag for flutter app compatibility
            newlyCreatedProduct.dataValues.hasVariants = newlyCreatedProduct.variants && newlyCreatedProduct.variants.length > 0;

            return res.status(201).json({
                message: "Product created successfully",
                product: newlyCreatedProduct
            });
        } catch (error) {
            await t.rollback();
            console.error("Create Product Error:", error);
            if (error.name === 'SequelizeUniqueConstraintError') {
                return res.status(409).json({ message: "A product with this name or barcode already exists." });
            }
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Get Products by Business ID ============
    getProductsByBusinessId: async (req, res) => {
        try {
            const { business_id } = req.params;
            const products = await Product.findAll({ 
                where: { business_id, status: 'active' },
                include: [
                    { model: Category, as: 'category' },
                    { model: Variant, as: 'variants' }
                ]
            });
            
            // Add custom hasVariants flag for flutter app compatibility
            const productsWithFlags = products.map(p => {
                p.dataValues.hasVariants = p.variants && p.variants.length > 0;
                return p;
            });

            return res.status(200).json({ products: productsWithFlags });
        } catch (error) {
            console.error("Get Products Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Update Product ============
    updateProduct: async (req, res) => {
        const t = await sequelize.transaction();
        try {
            const { id } = req.params;
            const { 
                category_id, 
                name, 
                description, 
                basePrice, 
                hsnCode, 
                uom, 
                status, 
                photo,
                barcode,
                variants 
            } = req.body;

            const product = await Product.findByPk(id);
            if (!product) {
                await t.rollback();
                return res.status(404).json({ message: "Product not found" });
            }

            // 1. Update Product
            await product.update({
                category_id: category_id !== undefined ? category_id : product.category_id,
                name: name || product.name,
                description: description !== undefined ? description : product.description,
                basePrice: basePrice !== undefined ? basePrice : product.basePrice,
                hsnCode: hsnCode !== undefined ? hsnCode : product.hsnCode,
                uom: uom || product.uom,
                status: status || product.status,
                photo: photo !== undefined ? photo : product.photo,
                barcode: barcode !== undefined ? barcode : product.barcode
            }, { transaction: t });

            // 2. Update Variants (Simple approach: Delete and recreate if provided)
            if (variants && Array.isArray(variants) && variants.length > 0) {
                await Variant.destroy({ where: { product_id: id }, transaction: t });
                const variantEntries = variants.map(v => ({
                    product_id: id,
                    name: v.name,
                    sku: v.sku || barcode,
                    price: v.price || basePrice,
                    stock: v.stock || 0,
                    status: v.status || 'active'
                }));
                await Variant.bulkCreate(variantEntries, { transaction: t });
            } else if (variants && Array.isArray(variants) && variants.length === 0) {
                // If variants was explicitly cleared, ensure we still have a Default
                await Variant.destroy({ where: { product_id: id }, transaction: t });
                await Variant.create({
                    product_id: id,
                    name: 'Default',
                    sku: barcode || product.barcode,
                    price: basePrice || product.basePrice,
                    stock: 0,
                    status: 'active'
                }, { transaction: t });
            }

            await t.commit();

            const updatedProduct = await Product.findByPk(id, {
                include: [
                    { model: Category, as: 'category' },
                    { model: Variant, as: 'variants' }
                ]
            });

            // Add custom hasVariants flag for flutter app compatibility
            updatedProduct.dataValues.hasVariants = updatedProduct.variants && updatedProduct.variants.length > 0;

            return res.status(200).json({
                message: "Product updated successfully",
                product: updatedProduct
            });
        } catch (error) {
            await t.rollback();
            console.error("Update Product Error:", error);
            if (error.name === 'SequelizeUniqueConstraintError') {
                return res.status(409).json({ message: "A product with this name or barcode already exists." });
            }
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Delete Product (Soft Delete) ============
    deleteProduct: async (req, res) => {
        try {
            const { id } = req.params;
            const product = await Product.findByPk(id);
            if (!product) {
                return res.status(404).json({ message: "Product not found" });
            }

            // Soft delete by setting status to inactive
            await product.update({ status: 'inactive' });
            
            // Soft delete variants as well
            await Variant.update({ status: 'inactive' }, { where: { product_id: id } });

            return res.status(200).json({ message: "Product deleted successfully" });
        } catch (error) {
            console.error("Delete Product Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = productsController;
