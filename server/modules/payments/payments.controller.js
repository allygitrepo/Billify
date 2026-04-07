const Payment = require("./payments.model");
const Customer = require("../customers/customers.model");
const sequelize = require("../../config/db");

exports.receivePayment = async (req, res) => {
    const transaction = await sequelize.transaction();
    try {
        console.log('SERVER DEBUG: receivePayment START', req.body);
        const { customer_id, amount, payment_method, note, date } = req.body;
        const business_id = req.user.business_id;
        console.log('SERVER DEBUG: Business ID:', business_id);

        const customer = await Customer.findOne({ where: { id: customer_id, business_id } });
        if (!customer) {
            console.log('SERVER DEBUG: Customer NOT FOUND with ID:', customer_id);
            await transaction.rollback();
            return res.status(404).json({ success: false, message: "Customer not found" });
        }

        // Create debit payment (customer paid)
        const payment = await Payment.create({
            business_id,
            customer_id,
            amount,
            type: 'debit',
            payment_method,
            note,
            created_by: req.user.id,
            createdAt: date || new Date()
        }, { transaction });

        // Update customer balance: decrement remaining_balance
        // Positive = customer owes us. Payment reduces that amount.
        const newBalance = parseFloat(customer.remaining_balance) - parseFloat(amount);
        await customer.update({ remaining_balance: newBalance }, { transaction });

        await transaction.commit();
        console.log('SERVER DEBUG: receivePayment SUCCESS. New Balance:', newBalance);
        res.status(201).json({ success: true, message: "Payment received successfully", data: payment });
    } catch (error) {
        console.log('SERVER DEBUG: receivePayment ERROR:', error.message);
        await transaction.rollback();
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.givePayment = async (req, res) => {
    const transaction = await sequelize.transaction();
    try {
        console.log('SERVER DEBUG: givePayment (Credit) START', req.body);
        const { customer_id, amount, payment_method, note, date } = req.body;
        const business_id = req.user.business_id;
        console.log('SERVER DEBUG: Business ID:', business_id);

        const customer = await Customer.findOne({ where: { id: customer_id, business_id } });
        if (!customer) {
            console.log('SERVER DEBUG: Customer NOT FOUND with ID:', customer_id);
            await transaction.rollback();
            return res.status(404).json({ success: false, message: "Customer not found" });
        }

        // Create credit payment (business gave to customer or credit invoice)
        const payment = await Payment.create({
            business_id,
            customer_id,
            amount,
            type: 'credit',
            payment_method,
            note,
            created_by: req.user.id,
            createdAt: date || new Date()
        }, { transaction });

        // Update customer balance: increment remaining_balance
        const newBalance = parseFloat(customer.remaining_balance) + parseFloat(amount);
        await customer.update({ remaining_balance: newBalance }, { transaction });

        await transaction.commit();
        console.log('SERVER DEBUG: givePayment SUCCESS. New Balance:', newBalance);
        res.status(201).json({ success: true, message: "Credit entry added successfully", data: payment });
    } catch (error) {
        console.log('SERVER DEBUG: givePayment ERROR:', error.message);
        await transaction.rollback();
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.getPayments = async (req, res) => {
    try {
        const { customerId, page = 1, limit = 10 } = req.query;
        const business_id = req.user.business_id;
        const offset = (page - 1) * limit;

        const where = { business_id, status: 'active' };
        if (customerId) where.customer_id = customerId;

        const { count, rows } = await Payment.findAndCountAll({
            where,
            offset,
            limit: parseInt(limit),
            order: [['createdAt', 'DESC']],
            include: [{ model: Customer, as: 'customer', attributes: ['name', 'phone_number'] }]
        });

        res.status(200).json({
            success: true,
            data: rows,
            pagination: {
                total: count,
                page: parseInt(page),
                limit: parseInt(limit),
                totalPages: Math.ceil(count / limit)
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.deletePayment = async (req, res) => {
    const transaction = await sequelize.transaction();
    try {
        const payment = await Payment.findOne({
            where: { id: req.params.id, business_id: req.user.business_id }
        });

        if (!payment) {
            await transaction.rollback();
            return res.status(404).json({ success: false, message: "Payment not found" });
        }

        const customer = await Customer.findOne({ where: { id: payment.customer_id, business_id: req.user.business_id } });
        if (customer) {
            let rollbackBalance;
            if (payment.type === 'debit') {
                rollbackBalance = parseFloat(customer.remaining_balance) + parseFloat(payment.amount);
            } else {
                rollbackBalance = parseFloat(customer.remaining_balance) - parseFloat(payment.amount);
            }
            await customer.update({ remaining_balance: rollbackBalance }, { transaction });
        }

        await payment.update({ status: 'deleted' }, { transaction });
        await transaction.commit();
        res.status(200).json({ success: true, message: "Payment deleted and balance reverted successfully" });
    } catch (error) {
        await transaction.rollback();
        res.status(500).json({ success: false, message: error.message });
    }
};
