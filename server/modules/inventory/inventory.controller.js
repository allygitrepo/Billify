const InventoryLog = require("./inventory.model");
const Product = require("../products/products.model");
const Variant = require("../variants/variants.model");
const sequelize = require("../../config/db");
const { getNextSequenceNumber } = require("../../utils/sequence");

const inventoryController = {
    // ============ Get Inventory Log by Business ============
    getInventoryLog: async (req, res) => {
        try {
            const { business_id } = req.params;
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

                const variant = await Variant.findOne({ 
                    where: { product_id, name: variant_name },
                    transaction: t
                });

                if (!variant) {
                    throw new Error(`Variant ${variant_name} for product ID ${product_id} not found`);
                }

                const currentStock = parseInt(variant.stock) || 0;
                // Use per-item logic for netChange
                const netChange = finalType === 'IN' ? Math.abs(quantity_change) : -Math.abs(quantity_change);
                const stockAfter = Math.max(0, currentStock + netChange);

                // Update Variant Stock
                await variant.update({ stock: stockAfter }, { transaction: t });

                // Create Log Entry
                const log = await InventoryLog.create({
                    business_id,
                    product_id,
                    variant_name,
                    change_type: finalType, // Per-item type
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
