const Customer = require("./customers.model");
const Payment = require("../payments/payments.model");
const { Op } = require("sequelize");

exports.createCustomer = async (req, res) => {
    try {
        const { name, phone_number, opening_balance, city, photo } = req.body;
        const business_id = req.user.business_id;

        const customer = await Customer.create({
            business_id,
            name,
            phone_number,
            opening_balance: opening_balance || 0,
            remaining_balance: opening_balance || 0,
            city,
            photo,
            created_by: req.user.id
        });

        res.status(201).json({ success: true, message: "Customer created successfully", data: customer });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.getCustomers = async (req, res) => {
    try {
        const { search, page = 1, limit = 10 } = req.query;
        const business_id = req.user.business_id;
        const offset = (page - 1) * limit;

        const where = { business_id, status: 'active' };
        if (search) {
            where[Op.or] = [
                { name: { [Op.like]: `%${search}%` } },
                { phone_number: { [Op.like]: `%${search}%` } }
            ];
        }

        const { count, rows } = await Customer.findAndCountAll({
            where,
            offset,
            limit: parseInt(limit),
            order: [['name', 'ASC']]
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

exports.getCustomerById = async (req, res) => {
    try {
        const customer = await Customer.findOne({
            where: { id: req.params.id, business_id: req.user.business_id, status: 'active' }
        });

        if (!customer) {
            return res.status(404).json({ success: false, message: "Customer not found" });
        }

        res.status(200).json({ success: true, data: customer });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.updateCustomer = async (req, res) => {
    try {
        const customer = await Customer.findOne({
            where: { id: req.params.id, business_id: req.user.business_id }
        });

        if (!customer) {
            return res.status(404).json({ success: false, message: "Customer not found" });
        }

        await customer.update(req.body);
        res.status(200).json({ success: true, message: "Customer updated successfully", data: customer });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.deleteCustomer = async (req, res) => {
    try {
        const customer = await Customer.findOne({
            where: { id: req.params.id, business_id: req.user.business_id }
        });

        if (!customer) {
            return res.status(404).json({ success: false, message: "Customer not found" });
        }

        await customer.update({ status: 'deleted' });
        res.status(200).json({ success: true, message: "Customer deleted successfully" });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.getCustomerDropdown = async (req, res) => {
    try {
        const customers = await Customer.findAll({
            where: { business_id: req.user.business_id, status: 'active' },
            attributes: ['id', 'name', 'phone_number', 'remaining_balance'],
            order: [['name', 'ASC']]
        });

        res.status(200).json({ success: true, data: customers });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.getCustomerLedger = async (req, res) => {
    try {
        const { id } = req.params;
        const business_id = req.user.business_id;

        const customer = await Customer.findOne({ where: { id, business_id } });
        if (!customer) {
            return res.status(404).json({ success: false, message: "Customer not found" });
        }

        // Fetch payments/ledger entries
        const payments = await Payment.findAll({
            where: { customer_id: id, business_id, status: 'active' },
            order: [['createdAt', 'DESC']]
        });

        // Calculate summary
        let totalCredit = 0; // Customer owes
        let totalDebit = 0; // Customer paid
        
        payments.forEach(p => {
            if (p.type === 'credit') totalCredit += parseFloat(p.amount);
            else totalDebit += parseFloat(p.amount);
        });

        const calculatedBalance = parseFloat(customer.opening_balance || 0) + totalCredit - totalDebit;
        console.log(`DEBUG: Ledger Summary for ${customer.name} - Open: ${customer.opening_balance}, Credit: ${totalCredit}, Debit: ${totalDebit}, Calculated: ${calculatedBalance}`);

        res.status(200).json({
            success: true,
            data: {
                customer,
                ledger: payments,
                summary: {
                    openingBalance: customer.opening_balance,
                    totalCredit,
                    totalDebit,
                    remainingBalance: calculatedBalance // Always calculate from ledger for 100% accuracy
                }
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.bulkImportCustomers = async (req, res) => {
    try {
        const { customers } = req.body;
        const business_id = req.user.business_id;
        const created_by = req.user.id;

        const results = [];
        for (const c of customers) {
            // Check if phone already exists for this business
            const exists = await Customer.findOne({ where: { business_id, phone_number: c.phone_number } });
            if (!exists) {
                const newCustomer = await Customer.create({
                    business_id,
                    name: c.name,
                    phone_number: c.phone_number,
                    created_by
                });
                results.push(newCustomer);
            }
        }

        res.status(201).json({ success: true, message: `${results.length} customers imported`, data: results });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
