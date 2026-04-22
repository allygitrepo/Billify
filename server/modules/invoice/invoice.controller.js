const Invoice = require("./invoice.model");
const InvoiceItem = require("../invoiceItems/invoice_items.model");
const Product = require("../products/products.model");
const Variant = require("../variants/variants.model");
const InventoryLog = require("../inventory/inventory.model");
const Settings = require("../settings/settings.model");
const User = require("../users/users.model");
const Customer = require("../customers/customers.model");
const Business = require("../businesses/businesses.model");
const Payment = require("../payments/payments.model");
const sequelize = require("../../config/db");
const { getNextSequenceNumber } = require("../../utils/sequence");

const invoiceController = {
    // ============ Create Invoice ============
    createInvoice: async (req, res) => {
        const t = await sequelize.transaction();
        try {
            const { 
                items,
            } = req.body;

            // 1. Normalize and Validate Body
            const business_id = parseInt(req.body.business_id);
            const user_id = req.body.user_id ? parseInt(req.body.user_id) : null;
            const customer_id = req.body.customer_id ? parseInt(req.body.customer_id) : null;
            const customer_type = req.body.customer_type || 'WALKIN';
            const {
                customer_name, 
                customer_phone, 
                total_amount, 
                discount, 
                tax_amount, 
                final_amount, 
                paid_amount,
                payment_mode, 
                status,
            } = req.body;

            if (isNaN(business_id)) {
                await t.rollback();
                return res.status(400).json({ message: "Invalid Business ID" });
            }

            // 2. Generate Sequential Invoice Number
            const invoice_number = await getNextSequenceNumber(business_id);

            // 2. Create Invoice
            const invoice = await Invoice.create({
                business_id,
                user_id, // Link the user who created it
                customer_id,
                customer_type: customer_type || 'WALKIN',
                invoice_number,
                customer_name,
                customer_phone,
                total_amount,
                discount,
                tax_amount,
                final_amount,
                paid_amount: paid_amount || 0,
                payment_mode,
                status: status || 'Paid'
            }, { transaction: t });

            // 3. Handle Customer Balance for "Regular" customers
            if (customer_type === 'REGULAR' && customer_id) {
                const customer = await Customer.findByPk(customer_id, { transaction: t });
                if (customer) {
                    const creditAmount = parseFloat(final_amount) - parseFloat(paid_amount || 0);
                    
                    if (creditAmount > 0) {
                        // Create a "credit" payment entry (customer owes)
                        await Payment.create({
                            business_id,
                            customer_id,
                            amount: creditAmount,
                            type: 'credit',
                            payment_method: payment_mode,
                            note: `Invoice #${invoice_number}`,
                            reference_invoice_id: invoice.id,
                            created_by: user_id
                        }, { transaction: t });

                        // Update customer remaining balance
                        const newBalance = parseFloat(customer.remaining_balance) + creditAmount;
                        await customer.update({ remaining_balance: newBalance }, { transaction: t });
                    }
                }
            }

            // 3. Process Items
            for (const item of items) {
                const productId = parseInt(item.productId);
                
                // a. Create Invoice Item record
                await InvoiceItem.create({
                    invoice_id: invoice.id,
                    product_id: productId,
                    product_name: item.productName,
                    variant_name: item.variantName,
                    quantity: item.quantity,
                    price: item.price,
                    subtotal: item.subtotal
                }, { transaction: t });

                // b. Update stock for the variant or product
                // Improved matching: try specific variant first, then 'Default', then first available
                let variant = await Variant.findOne({ 
                    where: { product_id: productId, name: item.variantName || 'Default' },
                    transaction: t
                });

                if (!variant && item.variantName && item.variantName !== 'Default') {
                    variant = await Variant.findOne({ 
                        where: { product_id: productId, name: 'Default' },
                        transaction: t
                    });
                }

                if (!variant) {
                    variant = await Variant.findOne({ 
                        where: { product_id: productId, status: 'active' },
                        transaction: t
                    });
                }

                let stockAfter;
                let currentStock;
                const quantityChange = -Math.abs(item.quantity);

                if (variant) {
                    currentStock = parseFloat(variant.current_stock) || 0;
                    stockAfter = parseFloat((currentStock + quantityChange).toFixed(3));
                    
                    await variant.update({ current_stock: stockAfter }, { transaction: t });

                    // Synchronize the parent Product current_stock column as well
                    const product = await Product.findByPk(productId, { transaction: t });
                    if (product) {
                        const allVariants = await Variant.findAll({ where: { product_id: productId, status: 'active' }, transaction: t });
                        const totalStock = allVariants.reduce((sum, v) => sum + parseFloat(v.current_stock), 0);
                        await product.update({ current_stock: parseFloat(totalStock.toFixed(3)) }, { transaction: t });
                    }
                } else {
                    // Update Product directly if no variant found
                    const product = await Product.findByPk(productId, { transaction: t });
                    if (product) {
                        currentStock = parseFloat(product.current_stock) || 0;
                        stockAfter = parseFloat((currentStock + quantityChange).toFixed(3));
                        await product.update({ current_stock: stockAfter }, { transaction: t });
                    } else {
                        // Product not found, skip stock update or handle error
                        console.warn(`Product ID ${productId} not found during invoice generation. Skipping stock update.`);
                        continue; 
                    }
                }

                // c. Log Inventory Change
                await InventoryLog.create({
                    business_id,
                    product_id: productId,
                    variant_name: variant ? (item.variantName || variant.name) : 'No Variant',
                    change_type: 'OUT',
                    quantity_change: quantityChange,
                    reason: 'Sale',
                    stock_after: stockAfter,
                    user_id,
                    reference_no: invoice_number // Use generating invoice number as reference
                }, { transaction: t });
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
            
            // Validation: Ensure business_id is numeric
            const numericBusinessId = parseInt(business_id);
            if (isNaN(numericBusinessId)) {
                return res.status(400).json({ message: "Invalid Business ID format" });
            }

            const invoices = await Invoice.findAll({ 
                where: { business_id: numericBusinessId },
                include: [
                    { 
                        model: InvoiceItem, 
                        as: 'items',
                        include: [{ model: Product, as: 'product' }]
                    },
                    { model: User, as: 'user' },
                    { model: Customer, as: 'customer' }
                ],
                order: [['createdAt', 'DESC']]
            });
            return res.status(200).json({ invoices });
        } catch (error) {
            console.error("Get Invoices Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },
    
    // ============ Get Invoice by ID ============
    getInvoiceById: async (req, res) => {
        try {
            const { id } = req.params;
            let invoice;

            // 1. Try finding by Primary Key (ID) if it's numeric
            if (!isNaN(id)) {
                invoice = await Invoice.findByPk(id, {
                    include: [
                        { 
                            model: InvoiceItem, 
                            as: 'items',
                            include: [{ model: Product, as: 'product' }]
                        },
                        { model: User, as: 'user' },
                        { model: Customer, as: 'customer' },
                        { model: Business, as: 'business' }
                    ]
                });
            }

            // 2. Try finding by Invoice Number (INV-XXXX) if not found or ID not numeric
            if (!invoice) {
                invoice = await Invoice.findOne({
                    where: { invoice_number: id },
                    include: [
                        { 
                            model: InvoiceItem, 
                            as: 'items',
                            include: [{ model: Product, as: 'product' }]
                        },
                        { model: User, as: 'user' },
                        { model: Customer, as: 'customer' },
                        { model: Business, as: 'business' }
                    ]
                });
            }

            if (!invoice) {
                return res.status(404).json({ message: "Invoice not found" });
            }

            return res.status(200).json({ invoice });
        } catch (error) {
            console.error("Get Invoice Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = invoiceController;
