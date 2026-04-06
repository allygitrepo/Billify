const Invoice = require("./invoice.model");
const InvoiceItem = require("../invoiceItems/invoice_items.model");
const Product = require("../products/products.model");
const Variant = require("../variants/variants.model");
const InventoryLog = require("../inventory/inventory.model");
const Settings = require("../settings/settings.model");
const User = require("../users/users.model");
const sequelize = require("../../config/db");
const { getNextSequenceNumber } = require("../../utils/sequence");

const invoiceController = {
    // ============ Create Invoice ============
    createInvoice: async (req, res) => {
        const t = await sequelize.transaction();
        try {
            const { 
                business_id, 
                customer_name, 
                customer_phone, 
                total_amount, 
                discount, 
                tax_amount, 
                final_amount, 
                payment_mode, 
                status,
                items,
                user_id // ID of the user creating the invoice
            } = req.body;

            // 1. Generate Sequential Invoice Number using shared utility
            const invoice_number = await getNextSequenceNumber(business_id);

            // 2. Create Invoice
            const invoice = await Invoice.create({
                business_id,
                user_id, // Link the user who created it
                invoice_number,
                customer_name,
                customer_phone,
                total_amount,
                discount,
                tax_amount,
                final_amount,
                payment_mode,
                status: status || 'Paid'
            }, { transaction: t });

            // 3. Process Items
            for (const item of items) {
                // a. Create Invoice Item record
                await InvoiceItem.create({
                    invoice_id: invoice.id,
                    product_id: item.productId,
                    product_name: item.productName,
                    variant_name: item.variantName,
                    quantity: item.quantity,
                    price: item.price,
                    subtotal: item.subtotal
                }, { transaction: t });

                // b. Update stock for the variant
                const variant = await Variant.findOne({ 
                    where: { product_id: item.productId, name: item.variantName },
                    transaction: t
                });

                if (variant) {
                    const stockBefore = parseInt(variant.stock) || 0;
                    const stockAfter = stockBefore - Math.abs(item.quantity);
                    
                    await variant.update({ stock: stockAfter }, { transaction: t });

                    // c. Log Inventory Change
                    await InventoryLog.create({
                        business_id,
                        product_id: item.productId,
                        variant_name: item.variantName,
                        change_type: 'OUT',
                        quantity_change: -Math.abs(item.quantity),
                        reason: 'Sale',
                        stock_after: stockAfter,
                        user_id
                    }, { transaction: t });
                }
            }

            await t.commit();
            return res.status(201).json({
                message: "Invoice created successfully",
                invoice
            });
        } catch (error) {
            await t.rollback();
            console.error("Create Invoice Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Get Invoices by Business ============
    getInvoicesByBusiness: async (req, res) => {
        try {
            const { business_id } = req.params;
            const invoices = await Invoice.findAll({ 
                where: { business_id },
                include: [
                    { 
                        model: InvoiceItem, 
                        as: 'items',
                        include: [{ model: Product, as: 'product' }]
                    },
                    { model: User, as: 'user' }
                ],
                order: [['createdAt', 'DESC']]
            });
            return res.status(200).json({ invoices });
        } catch (error) {
            console.error("Get Invoices Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = invoiceController;
