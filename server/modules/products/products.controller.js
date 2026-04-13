const Product = require("./products.model");
const Variant = require("../variants/variants.model");
const Category = require("../categories/categories.model");
const Inventory = require("../inventory/inventory.model");
const UOM = require("../uoms/uoms.model");
const sequelize = require("../../config/db");
const { Op } = require("sequelize");

const productsController = {
    // ============ Create Product ============
    createProduct: async (req, res) => {
        const t = await sequelize.transaction();
        try {
            let { 
                business_id, 
                category_id, 
                category_name,
                name, 
                description, 
                price, 
                basePrice, // Legacy support from frontend
                stock,
                hsnCode, 
                barcode,
                has_variants,
                hasVariants, // Legacy support from frontend
                is_weighted,
                base_uom_id,
                uom,
                price_per_unit,
                variants,
                status,
                photo
            } = req.body;

            // Normalize fields from frontend
            has_variants = has_variants !== undefined ? has_variants : (hasVariants !== undefined ? hasVariants : false);
            is_weighted = is_weighted || false;

            // Handle price: Prioritize price_per_unit for weighted items
            if (is_weighted && price_per_unit !== undefined) {
                price = price_per_unit;
            } else {
                price = price !== undefined ? price : (basePrice !== undefined ? basePrice : 0);
            }

            stock = stock !== undefined ? stock : 0;
            
            // Map UOM ID to base_uom_id if base_uom_id is missing but uom (ID) is present
            if (!base_uom_id && uom && !isNaN(parseInt(uom))) {
                base_uom_id = parseInt(uom);
            }

            // Ensure barcode is null if empty string to avoid unique constraint issues
            barcode = (barcode && barcode.trim() !== "") ? barcode.trim() : null;

            // Basic Validation
            if (!business_id || !name) {
                await t.rollback();
                return res.status(400).json({ message: "Business ID and Name are required" });
            }

            // Logic Validation
            if (has_variants) {
                if (!variants || !Array.isArray(variants) || variants.length === 0) {
                    await t.rollback();
                    return res.status(400).json({ message: "Variants are required when has_variants is true" });
                }
            } else {
                if (price === undefined || stock === undefined) {
                    await t.rollback();
                    return res.status(400).json({ message: "Price and Stock are required for products without variants" });
                }
            }

            // 1. Handle Category Auto-creation
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
                price: has_variants ? null : price,
                opening_stock: has_variants ? null : stock,
                current_stock: has_variants ? null : stock,
                hsnCode,
                status: status || 'active',
                photo,
                barcode,
                has_variants,
                is_weighted: is_weighted,
                uom: uom || 'Pcs',
                base_uom_id: base_uom_id || null
            }, { transaction: t });

            // 3. Handle Variants and Inventory
            if (has_variants) {
                // Bulk create variants
                const variantEntries = variants.map(v => ({
                    product_id: product.id,
                    name: v.name,
                    sku: v.sku || v.barcode || barcode,
                    price: v.price || 0,
                    opening_stock: v.stock || 0,
                    current_stock: v.stock || 0,
                    status: v.status || 'active'
                }));
                const createdVariants = await Variant.bulkCreate(variantEntries, { transaction: t, returning: true });

                // Create Inventory for each variant
                const inventoryEntries = createdVariants.map(v => ({
                    business_id,
                    product_id: product.id,
                    variant_id: v.id,
                    current_stock: v.current_stock || 0
                }));
                await Inventory.bulkCreate(inventoryEntries, { transaction: t });
            } else {
                // No variants: Create single Inventory record for product
                await Inventory.create({
                    business_id,
                    product_id: product.id,
                    variant_id: null,
                    current_stock: stock || 0
                }, { transaction: t });
            }

            await t.commit();

            const newlyCreatedProduct = await Product.findByPk(product.id, {
                include: [
                    { model: Category, as: 'category' },
                    { model: Variant, as: 'variants' },
                    { model: UOM, as: 'baseUom' },
                    { model: Inventory, as: 'inventory' }
                ]
            });
            
            return res.status(201).json({
                message: "Product created successfully",
                product: newlyCreatedProduct
            });
        } catch (error) {
            if (t) await t.rollback();
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
                    { model: Variant, as: 'variants', where: { status: 'active' }, required: false },
                    { model: UOM, as: 'baseUom' },
                    { model: Inventory, as: 'inventory' }
                ],
                order: [['createdAt', 'DESC']]
            });
            
            return res.status(200).json({ products });
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
            let { 
                category_id, 
                name, 
                description, 
                price, 
                basePrice, // Legacy support from frontend
                stock,
                hsnCode, 
                status, 
                photo,
                barcode,
                has_variants,
                hasVariants, // Legacy support from frontend
                is_weighted,
                base_uom_id,
                uom,
                price_per_unit,
                variants 
            } = req.body;

            const product = await Product.findByPk(id);
            if (!product) {
                await t.rollback();
                return res.status(404).json({ message: "Product not found" });
            }

            // Normalize fields from frontend
            has_variants = has_variants !== undefined ? has_variants : (hasVariants !== undefined ? hasVariants : product.has_variants);
            is_weighted = is_weighted !== undefined ? is_weighted : product.is_weighted;

            // Handle price: Prioritize price_per_unit for weighted items
            if (is_weighted && price_per_unit !== undefined) {
                price = price_per_unit;
            } else if (price !== undefined) {
                price = price;
            } else if (basePrice !== undefined) {
                price = basePrice;
            } else {
                price = product.price;
            }

            stock = stock !== undefined ? stock : product.stock;

            // Map UOM ID to base_uom_id if missing
            if (!base_uom_id && uom && !isNaN(parseInt(uom))) {
                base_uom_id = parseInt(uom);
            }

            // Ensure barcode is null if empty string
            barcode = (barcode && barcode.trim() !== "") ? barcode.trim() : null;

            // 1. Update Product fields
            await product.update({
                category_id: category_id !== undefined ? category_id : product.category_id,
                name: name || product.name,
                description: description !== undefined ? description : product.description,
                price: has_variants ? null : price,
                opening_stock: has_variants ? null : stock, // Allow updating opening stock as well if provided
                current_stock: has_variants ? null : stock, // Logic assumes manual update of stock via updateProduct sets both
                hsnCode: hsnCode !== undefined ? hsnCode : product.hsnCode,
                status: status || product.status,
                photo: photo !== undefined ? photo : product.photo,
                barcode: barcode !== undefined ? barcode : product.barcode,
                has_variants,
                is_weighted,
                uom: uom !== undefined ? uom : product.uom,
                base_uom_id: base_uom_id !== undefined ? base_uom_id : product.base_uom_id
            }, { transaction: t });

            // 2. Handle Variants update (Robust Sync)
            if (has_variants) {
                // Get existing variants
                const existingVariants = await Variant.findAll({ where: { product_id: id }, transaction: t });
                const existingVariantIds = existingVariants.map(v => v.id.toString());
                const incomingVariantIds = variants ? variants.filter(v => v.id).map(v => v.id.toString()) : [];

                // A. Mark variants as inactive if not in payload
                const toRemoveIds = existingVariantIds.filter(id => !incomingVariantIds.includes(id));
                if (toRemoveIds.length > 0) {
                    await Variant.update({ status: 'inactive' }, { where: { id: toRemoveIds }, transaction: t });
                }

                // B. Sync existing and create new
                if (variants && Array.isArray(variants)) {
                    for (const vData of variants) {
                        if (vData.id && existingVariantIds.includes(vData.id.toString())) {
                            // Update
                            const variant = existingVariants.find(ev => ev.id.toString() === vData.id.toString());
                            await variant.update({
                                name: vData.name || variant.name,
                                sku: vData.sku || vData.barcode || variant.sku,
                                price: vData.price !== undefined ? vData.price : variant.price,
                                opening_stock: vData.stock !== undefined ? vData.stock : variant.opening_stock,
                                current_stock: vData.stock !== undefined ? vData.stock : variant.current_stock,
                                status: vData.status || 'active'
                            }, { transaction: t });

                            await Inventory.upsert({
                                business_id: product.business_id,
                                product_id: id,
                                variant_id: variant.id,
                                current_stock: vData.stock !== undefined ? vData.stock : variant.current_stock
                            }, { transaction: t });

                        } else {
                            // Create New
                            const newVariant = await Variant.create({
                                product_id: id,
                                name: vData.name,
                                sku: vData.sku || vData.barcode || barcode || product.barcode,
                                price: vData.price || 0,
                                opening_stock: vData.stock || 0,
                                current_stock: vData.stock || 0,
                                status: vData.status || 'active'
                            }, { transaction: t });

                            // Create Inventory
                            await Inventory.create({
                                business_id: product.business_id,
                                product_id: id,
                                variant_id: newVariant.id,
                                current_stock: vData.stock || 0
                            }, { transaction: t });
                        }
                    }
                }
            } else {
                // No variants logic: Ensure no stale active variants exist and update inventory
                await Variant.update({ status: 'inactive' }, { where: { product_id: id }, transaction: t });
                
                // Update or Create Product-level Inventory snapshot
                await Inventory.upsert({
                    business_id: product.business_id,
                    product_id: id,
                    variant_id: null,
                    current_stock: stock
                }, { transaction: t });
            }

            await t.commit();

            const updatedProduct = await Product.findByPk(id, {
                include: [
                    { model: Category, as: 'category' },
                    { model: Variant, as: 'variants', where: { status: 'active' }, required: false },
                    { model: UOM, as: 'baseUom' },
                    { model: Inventory, as: 'inventory' }
                ]
            });

            return res.status(200).json({
                message: "Product updated successfully",
                product: updatedProduct
            });
        } catch (error) {
            if (t) await t.rollback();
            console.error("Update Product Error:", error);
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

            // Soft delete
            await product.update({ status: 'inactive' });
            await Variant.update({ status: 'inactive' }, { where: { product_id: id } });

            return res.status(200).json({ message: "Product deleted successfully" });
        } catch (error) {
            console.error("Delete Product Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = productsController;
