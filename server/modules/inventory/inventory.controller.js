const InventoryLog = require("./inventory.model");
const Product = require("../products/products.model");
const Variant = require("../variants/variants.model");
const sequelize = require("../../config/db");
const { getNextSequenceNumber } = require("../../utils/sequence");

const inventoryController = {
    // ============ Get Inventory Log by Business ============
    getInventoryLog: async (req, res) => {
        try {
            const business_id = 
                (req.params && (req.params.business_id || req.params.id)) || 
                (req.headers && req.headers['x-business-id']) ||
                (req.user && req.user.business_id);
            
            if (!business_id) {
                return res.status(400).json({ message: "Business ID is required" });
            }

            const logs = await InventoryLog.findAll({
                where: { business_id },
                include: [{ 
                    model: Product, 
                    attributes: ['name'],
                    as: 'product' 
                }],
                order: [['createdAt', 'DESC']]
            });
            return res.status(200).json({ logs });
        } catch (error) {
            console.error("Get Inventory Log Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Manual Stock Update (Bulk Support) ============
    manualStockUpdate: async (req, res) => {
        const t = await sequelize.transaction();
        try {
            const { 
                business_id, 
                type, // 'IN' or 'OUT'
                reason,
                user_id,
                reference_no,
                entity_name,
                items // Array of { product_id, variant_name, quantity_change, unit_price, total_amount }
            } = req.body;

            if (!items || !Array.isArray(items) || items.length === 0) {
                await t.rollback();
                return res.status(400).json({ message: "No items provided" });
            }

            // 1. Generate Reference No if it's a sale and not provided
            let finalReferenceNo = reference_no;
            if (type === 'OUT' && reason === 'Sale' && !reference_no) {
                finalReferenceNo = await getNextSequenceNumber(business_id);
            }

            const logs = [];

            // 2. Process each item
            for (const item of items) {
                const { product_id, variant_name, quantity_change, unit_price, total_amount, type: itemType } = item;
                
                // Allow per-item type, fallback to root type
                const finalType = itemType || type;

                // Improved matching: try specific variant first, then 'Default', then first available
                let variant = await Variant.findOne({ 
                    where: { product_id, name: variant_name || 'Default' },
                    transaction: t
                });

                if (!variant && variant_name && variant_name !== 'Default') {
                    variant = await Variant.findOne({ 
                        where: { product_id, name: 'Default' },
                        transaction: t
                    });
                }

                if (!variant) {
                    variant = await Variant.findOne({ 
                        where: { product_id, status: 'active' },
                        transaction: t
                    });
                }

                let currentStock;
                let stockAfter;
                let netChange;
                const change = Math.abs(parseFloat(quantity_change));
                netChange = finalType === 'IN' ? change : -change;

                if (variant) {
                    currentStock = parseFloat(variant.current_stock) || 0;
                    stockAfter = parseFloat((currentStock + netChange).toFixed(3));

                    // Update Variant Stock
                    await variant.update({ current_stock: stockAfter }, { transaction: t });

                    // Synchronize parent Product current_stock
                    const product = await Product.findByPk(product_id, { transaction: t });
                    if (product) {
                        const allVariants = await Variant.findAll({ where: { product_id, status: 'active' }, transaction: t });
                        const totalProductStock = allVariants.reduce((sum, v) => sum + parseFloat(v.current_stock), 0);
                        await product.update({ current_stock: parseFloat(totalProductStock.toFixed(3)) }, { transaction: t });
                    }
                } else {
                    // Update Product directly if no variant found
                    const product = await Product.findByPk(product_id, { transaction: t });
                    if (!product) {
                        throw new Error(`Product ID ${product_id} not found. Stock cannot be updated.`);
                    }

                    currentStock = parseFloat(product.current_stock) || 0;
                    stockAfter = parseFloat((currentStock + netChange).toFixed(3));

                    // Update Product Stock
                    await product.update({ current_stock: stockAfter }, { transaction: t });
                }

                // Create Log Entry
                const log = await InventoryLog.create({
                    business_id,
                    product_id,
                    variant_name: variant ? (variant_name || variant.name) : 'No Variant',
                    change_type: finalType,
                    quantity_change: netChange,
                    reason: reason || 'Manual Update',
                    stock_after: stockAfter,
                    user_id,
                    reference_no: finalReferenceNo,
                    entity_name,
                    unit_price,
                    total_amount
                }, { transaction: t });

                logs.push(log);
            }

            await t.commit();
            return res.status(200).json({
                message: `${items.length} items updated successfully`,
                logs,
                reference_no: finalReferenceNo
            });
        } catch (error) {
            await t.rollback();
            console.error("Bulk Stock Update Error:", error);
            return res.status(500).json({ message: error.message || "Internal server error" });
        }
    }
};

module.exports = inventoryController;
