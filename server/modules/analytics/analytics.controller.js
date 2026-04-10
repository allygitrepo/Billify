const { Op, fn, col, where } = require("sequelize");
const Invoice = require("../invoice/invoice.model");
const InvoiceItem = require("../invoiceItems/invoice_items.model");
const Product = require("../products/products.model");
const Category = require("../categories/categories.model");
const Customer = require("../customers/customers.model");
const Payment = require("../payments/payments.model");

exports.getSalesSummary = async (req, res) => {
    try {
        const { businessId } = req.params;
        const { start_date, end_date } = req.query;

        const bId = parseInt(businessId);
        const filter = { business_id: bId };
        if (start_date && end_date) {
            filter.createdAt = { [Op.between]: [new Date(start_date), new Date(end_date)] };
        }

        const stats = await Invoice.findOne({
            where: filter,
            attributes: [
                [fn("SUM", col("final_amount")), "totalSales"],
                [fn("COUNT", col("id")), "totalOrders"],
                [fn("AVG", col("final_amount")), "avgBillValue"],
            ],
            raw: true
        });

        // Items sold count from items table
        const itemsSold = await InvoiceItem.sum('quantity', {
            include: [{
                model: Invoice,
                as: 'invoice',
                where: filter,
                attributes: []
            }]
        });

        res.status(200).json({
            summary: {
                totalSales: parseFloat(stats?.totalSales || 0),
                totalOrders: parseInt(stats?.totalOrders || 0),
                avgBillValue: parseFloat(stats?.avgBillValue || 0),
                totalItemsSold: parseInt(itemsSold || 0)
            }
        });
    } catch (error) {
        console.error("Error fetching sales summary:", error);
        res.status(500).json({ message: "Summary error: " + error.message });
    }
};

exports.getSalesTrend = async (req, res) => {
    try {
        const { businessId } = req.params;
        const { start_date, end_date } = req.query;

        const bId = parseInt(businessId);
        const filter = { business_id: bId };
        if (start_date && end_date) {
            filter.createdAt = { [Op.between]: [new Date(start_date), new Date(end_date)] };
        }

        const trend = await Invoice.findAll({
            where: filter,
            attributes: [
                [fn("DATE", col("createdAt")), "date"],
                [fn("SUM", col("final_amount")), "amount"],
            ],
            group: [fn("DATE", col("createdAt"))],
            order: [[fn("DATE", col("createdAt")), "ASC"]],
            raw: true
        });

        res.status(200).json({ trend });
    } catch (error) {
        console.error("Error fetching sales trend:", error);
        res.status(500).json({ message: "Trend error: " + error.message });
    }
};

exports.getTopProducts = async (req, res) => {
    try {
        const { businessId } = req.params;
        const { start_date, end_date } = req.query;

        const bId = parseInt(businessId);
        const filter = { business_id: bId };
        if (start_date && end_date) {
            filter.createdAt = { [Op.between]: [new Date(start_date), new Date(end_date)] };
        }

        const products = await InvoiceItem.findAll({
            attributes: [
                "product_id",
                "product_name",
                [fn("SUM", col("quantity")), "quantity"],
                [fn("SUM", col("subtotal")), "revenue"],
            ],
            include: [{
                model: Invoice,
                as: 'invoice',
                where: filter,
                attributes: []
            }],
            group: ["product_id", "product_name"],
            order: [[fn("SUM", col("subtotal")), "DESC"]],
            limit: 5,
            raw: true
        });

        // Calculate percentages
        const totalRevenue = products.reduce((sum, p) => sum + parseFloat(p.revenue), 0);
        const productsWithPercent = products.map(p => ({
            id: p.product_id,
            name: p.product_name,
            quantity: parseInt(p.quantity),
            revenue: parseFloat(p.revenue),
            percentage: totalRevenue > 0 ? (parseFloat(p.revenue) / totalRevenue * 100) : 0
        }));

        res.status(200).json({ products: productsWithPercent });
    } catch (error) {
        console.error("Error fetching top products:", error);
        res.status(500).json({ message: "Products error: " + error.message });
    }
};

exports.getCategorySales = async (req, res) => {
    try {
        const { businessId } = req.params;
        const { start_date, end_date } = req.query;

        const bId = parseInt(businessId);
        const filter = { business_id: bId };
        if (start_date && end_date) {
            filter.createdAt = { [Op.between]: [new Date(start_date), new Date(end_date)] };
        }

        const categories = await InvoiceItem.findAll({
            attributes: [
                [fn("SUM", col("subtotal")), "sales"],
            ],
            include: [
                {
                    model: Invoice,
                    as: 'invoice',
                    where: filter,
                    attributes: []
                },
                {
                    model: Product,
                    as: 'product',
                    attributes: ["category_id"],
                    include: [{
                        model: Category,
                        as: 'category',
                        attributes: ["name"]
                    }]
                }
            ],
            group: [col("InvoiceItem.id"), col("product.id"), col("product.category.id")],
            raw: true,
            nest: true
        });

        const grouped = {};
        categories.forEach(item => {
            const catName = item.product?.category?.name || 'Uncategorized';
            grouped[catName] = (grouped[catName] || 0) + parseFloat(item.sales);
        });

        const totalSales = Object.values(grouped).reduce((a, b) => a + b, 0);
        const categoriesWithPercent = Object.entries(grouped).map(([name, sales]) => ({
            category: name,
            sales: sales,
            percentage: totalSales > 0 ? (sales / totalSales * 100) : 0
        }));

        res.status(200).json({ categories: categoriesWithPercent });
    } catch (error) {
        console.error("Error fetching category sales:", error);
        res.status(500).json({ message: "Category error: " + error.message });
    }
};

exports.getPaymentSummary = async (req, res) => {
    try {
        const { businessId } = req.params;
        const { start_date, end_date } = req.query;

        const bId = parseInt(businessId);
        const filter = { business_id: bId };
        if (start_date && end_date) {
            filter.createdAt = { [Op.between]: [new Date(start_date), new Date(end_date)] };
        }

        const payments = await Invoice.findAll({
            where: filter,
            attributes: [
                "payment_mode",
                [fn("SUM", col("final_amount")), "amount"],
                [fn("COUNT", col("id")), "count"],
            ],
            group: ["payment_mode"],
            raw: true
        });

        const totalAmount = payments.reduce((sum, p) => sum + parseFloat(p.amount), 0);
        const paymentSummary = payments.map(p => ({
            method: p.payment_mode,
            amount: parseFloat(p.amount),
            percentage: totalAmount > 0 ? (parseFloat(p.amount) / totalAmount * 100) : 0
        }));

        res.status(200).json({ payments: paymentSummary });
    } catch (error) {
        console.error("Error fetching payment summary:", error);
        res.status(500).json({ message: "Payment error: " + error.message });
    }
};

exports.getSalesList = async (req, res) => {
    try {
        const { businessId } = req.params;
        const { start_date, end_date, page = 1, limit = 20 } = req.query;

        const bId = parseInt(businessId);
        const filter = { business_id: bId };
        if (start_date && end_date) {
            filter.createdAt = { [Op.between]: [new Date(start_date), new Date(end_date)] };
        }

        const offset = (page - 1) * limit;

        const invoices = await Invoice.findAll({
            where: filter,
            include: [
                { model: InvoiceItem, as: 'items' },
                { model: require("../customers/customers.model"), as: 'customer', attributes: ['name', 'phone_number'] }
            ],
            order: [["createdAt", "DESC"]],
            limit: parseInt(limit),
            offset: offset,
        });

        res.status(200).json({ invoices });
    } catch (error) {
        console.error("Error fetching sales list:", error);
        res.status(500).json({ message: "List error: " + error.message });
    }
};

// ============ Profit Reports ============

exports.getProfitSummary = async (req, res) => {
    try {
        const { businessId } = req.params;
        const { start_date, end_date } = req.query;

        const bId = parseInt(businessId);
        const filter = { business_id: bId };
        if (start_date && end_date) {
            filter.createdAt = { [Op.between]: [new Date(start_date), new Date(end_date)] };
        }

        // Get all invoice items for identifying cost
        const items = await InvoiceItem.findAll({
            include: [
                {
                    model: Invoice,
                    as: 'invoice',
                    where: filter,
                    attributes: []
                },
                {
                    model: Product,
                    as: 'product',
                    attributes: ['purchasePrice', 'category_id']
                }
            ],
            raw: true,
            nest: true
        });

        let totalRevenue = 0;
        let totalCost = 0;
        let totalOrders = new Set();
        const dateMap = {};

        items.forEach(item => {
            const revenue = parseFloat(item.subtotal || 0);
            const costPerUnit = parseFloat(item.product?.purchasePrice || 0);
            const cost = costPerUnit * parseInt(item.quantity || 0);
            
            totalRevenue += revenue;
            totalCost += cost;
            totalOrders.add(item.invoice_id);

            // Chart Data (Daily Trend)
            const date = item.createdAt.toISOString().split('T')[0];
            if (!dateMap[date]) dateMap[date] = 0;
            dateMap[date] += (revenue - cost);
        });

        const totalProfit = totalRevenue - totalCost;
        const profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue * 100) : 0;

        const chartData = Object.entries(dateMap).map(([date, profit]) => ({
            date,
            profit: parseFloat(profit.toFixed(2))
        })).sort((a,b) => a.date.localeCompare(b.date));

        res.status(200).json({
            summary: {
                totalProfit: parseFloat(totalProfit.toFixed(2)),
                totalRevenue: parseFloat(totalRevenue.toFixed(2)),
                totalCost: parseFloat(totalCost.toFixed(2)),
                profitMargin: parseFloat(profitMargin.toFixed(1)),
                totalOrders: totalOrders.size
            },
            chartData
        });
    } catch (error) {
        console.error("Profit Summary Error:", error);
        res.status(500).json({ message: "Profit summary error: " + error.message });
    }
};

exports.getProfitByProducts = async (req, res) => {
    try {
        const { businessId } = req.params;
        const { start_date, end_date } = req.query;

        const bId = parseInt(businessId);
        const filter = { business_id: bId };
        if (start_date && end_date) {
            filter.createdAt = { [Op.between]: [new Date(start_date), new Date(end_date)] };
        }

        const items = await InvoiceItem.findAll({
            include: [
                {
                    model: Invoice,
                    as: 'invoice',
                    where: filter,
                    attributes: []
                },
                {
                    model: Product,
                    as: 'product',
                    attributes: ['purchasePrice']
                }
            ],
            raw: true,
            nest: true
        });

        const productMap = {};
        items.forEach(item => {
            const pid = item.product_id;
            if (!productMap[pid]) {
                productMap[pid] = {
                    id: pid,
                    name: item.product_name,
                    quantity: 0,
                    revenue: 0,
                    cost: 0,
                    profit: 0
                };
            }
            const revenue = parseFloat(item.subtotal || 0);
            const cost = parseFloat(item.product?.purchasePrice || 0) * parseInt(item.quantity || 0);
            
            productMap[pid].quantity += parseInt(item.quantity || 0);
            productMap[pid].revenue += revenue;
            productMap[pid].cost += cost;
            productMap[pid].profit += (revenue - cost);
        });

        const sortedProducts = Object.values(productMap)
            .map(p => ({
                ...p,
                margin: p.revenue > 0 ? (p.profit / p.revenue * 100).toFixed(1) : 0
            }))
            .sort((a, b) => b.profit - a.profit);

        res.status(200).json({ topProducts: sortedProducts });
    } catch (error) {
        console.error("Product Profit Error:", error);
        res.status(500).json({ message: "Product profit error: " + error.message });
    }
};

exports.getProfitByCategories = async (req, res) => {
    try {
        const { businessId } = req.params;
        const { start_date, end_date } = req.query;

        const bId = parseInt(businessId);
        const filter = { business_id: bId };
        if (start_date && end_date) {
            filter.createdAt = { [Op.between]: [new Date(start_date), new Date(end_date)] };
        }

        const items = await InvoiceItem.findAll({
            include: [
                {
                    model: Invoice,
                    as: 'invoice',
                    where: filter,
                    attributes: []
                },
                {
                    model: Product,
                    as: 'product',
                    attributes: ['purchasePrice'],
                    include: [{ model: Category, as: 'category', attributes: ['name'] }]
                }
            ],
            raw: true,
            nest: true
        });

        const categoryMap = {};
        items.forEach(item => {
            const catName = item.product?.category?.name || 'Uncategorized';
            if (!categoryMap[catName]) {
                categoryMap[catName] = { category: catName, profit: 0, revenue: 0 };
            }
            const revenue = parseFloat(item.subtotal || 0);
            const cost = parseFloat(item.product?.purchasePrice || 0) * parseInt(item.quantity || 0);
            categoryMap[catName].profit += (revenue - cost);
            categoryMap[catName].revenue += revenue;
        });

        const sortedCategories = Object.values(categoryMap).map(c => ({
            category: c.category,
            profit: parseFloat(c.profit.toFixed(2)),
            margin: c.revenue > 0 ? parseFloat((c.profit / c.revenue * 100).toFixed(1)) : 0
        })).sort((a,b) => b.profit - a.profit);

        res.status(200).json({ topCategories: sortedCategories });
    } catch (error) {
        console.error("Category Profit Error:", error);
        res.status(500).json({ message: "Category profit error: " + error.message });
    }
};

// ============ Customer Reports ============

exports.getCustomersAnalytics = async (req, res) => {
    try {
        const { businessId } = req.params;
        const { search } = req.query;

        const bId = parseInt(businessId);
        const where = { business_id: bId, status: 'active' };
        
        if (search) {
            where[Op.or] = [
                { name: { [Op.like]: `%${search}%` } },
                { phone_number: { [Op.like]: `%${search}%` } }
            ];
        }

        const customers = await Customer.findAll({
            where,
            attributes: ['id', 'name', 'phone_number', 'opening_balance', 'remaining_balance', 'city', 'createdAt'],
            order: [['name', 'ASC']]
        });

        // Fetch all payments for this business and group in JS
        const customerStatsMap = {};
        const allPayments = await Payment.findAll({
            where: { business_id: bId, status: 'active' },
            attributes: ['customer_id', 'type', 'amount'],
            raw: true
        });

        allPayments.forEach(p => {
            if (!customerStatsMap[p.customer_id]) {
                customerStatsMap[p.customer_id] = { billed: 0, paid: 0 };
            }
            if (p.type === 'credit') customerStatsMap[p.customer_id].billed += parseFloat(p.amount);
            else customerStatsMap[p.customer_id].paid += parseFloat(p.amount);
        });

        let totalReceivable = 0; // Customers owe us (Balance > 0)
        let totalPayable = 0;    // We owe customers (Balance < 0)

        const reportItems = customers.map(c => {
            const stats = customerStatsMap[c.id] || { billed: 0, paid: 0 };
            const balance = parseFloat(c.remaining_balance);
            
            if (balance > 0) totalReceivable += balance;
            else if (balance < 0) totalPayable += Math.abs(balance);

            return {
                id: c.id,
                name: c.name,
                phoneNumber: c.phone_number,
                city: c.city,
                openingBalance: parseFloat(c.opening_balance),
                totalBilled: stats.billed,
                totalPaid: stats.paid,
                remainingBalance: balance,
                lastActivity: c.createdAt // Simplification
            };
        });

        res.status(200).json({
            summary: {
                totalCustomers: customers.length,
                totalReceivable: parseFloat(totalReceivable.toFixed(2)),
                totalPayable: parseFloat(totalPayable.toFixed(2)),
                netBalance: parseFloat((totalReceivable - totalPayable).toFixed(2))
            },
            customers: reportItems
        });
    } catch (error) {
        console.error("Customer Analytics Error:", error);
        res.status(500).json({ message: "Customer analytics error: " + error.message });
    }
};

// ============ Khata Reports ============

exports.getKhataSummary = async (req, res) => {
    try {
        const { businessId } = req.params;
        console.log(`[Khata] Summary request for Business: ${businessId}`);
        const bId = parseInt(businessId);

        const totalReceivable = await Customer.sum('remaining_balance', {
            where: { business_id: bId, remaining_balance: { [Op.gt]: 0 }, status: 'active' }
        });

        const customersWithDue = await Customer.count({
            where: { business_id: bId, remaining_balance: { [Op.gt]: 0 }, status: 'active' }
        });

        // Get received vs credit from payments table
        const paymentStats = await Payment.findAll({
            where: { business_id: bId, status: 'active' },
            attributes: [
                'type',
                [fn('SUM', col('amount')), 'total']
            ],
            group: ['type'],
            raw: true
        });

        let totalReceived = 0;
        let totalCreditSales = 0;

        paymentStats.forEach(p => {
            if (p.type === 'payment') totalReceived = parseFloat(p.total || 0);
            if (p.type === 'credit') totalCreditSales = parseFloat(p.total || 0);
        });

        res.status(200).json({
            summary: {
                totalReceivable: parseFloat(totalReceivable || 0),
                totalReceived,
                totalCreditSales,
                customersWithDue,
                avgDueAmount: customersWithDue > 0 ? (parseFloat(totalReceivable || 0) / customersWithDue) : 0
            }
        });
    } catch (error) {
        console.error("Khata Summary Error:", error);
        res.status(500).json({ message: "Khata summary error: " + error.message });
    }
};

exports.getKhataDueReport = async (req, res) => {
    try {
        const { businessId } = req.params;
        const { page = 1, limit = 20 } = req.query;
        const bId = parseInt(businessId);
        const offset = (parseInt(page) - 1) * parseInt(limit);

        const customers = await Customer.findAll({
            where: { business_id: bId, remaining_balance: { [Op.gt]: 0 }, status: 'active' },
            attributes: ['id', 'name', 'phone_number', 'remaining_balance'],
            order: [['remaining_balance', 'DESC']],
            limit: parseInt(limit),
            offset: offset,
            raw: true
        });

        const report = customers.map(c => ({
            customer_id: c.id,
            name: c.name,
            phone: c.phone_number,
            total_due: parseFloat(c.remaining_balance)
        }));

        res.status(200).json({ report });
    } catch (error) {
        console.error("Khata Due Report Error:", error);
        res.status(500).json({ message: "Khata due report error: " + error.message });
    }
};

exports.getKhataPayments = async (req, res) => {
    try {
        const { businessId } = req.params;
        console.log(`[Khata] Payments trend request for Business: ${businessId}`);
        const bId = parseInt(businessId);

        const payments = await Payment.findAll({
            where: { business_id: bId, type: 'payment', status: 'active' },
            attributes: [
                [fn('DATE', col('createdAt')), 'date'],
                [fn('SUM', col('amount')), 'value']
            ],
            group: [fn('DATE', col('createdAt'))],
            order: [[fn('DATE', col('createdAt')), 'ASC']],
            raw: true
        });

        res.status(200).json({ payments: { trend: payments } });
    } catch (error) {
        console.error("Khata Payments Error:", error);
        res.status(500).json({ message: "Khata payments error: " + error.message });
    }
};

exports.getKhataCreditReport = async (req, res) => {
    try {
        const { businessId } = req.params;
        const bId = parseInt(businessId);

        const credits = await Payment.findAll({
            where: { business_id: bId, type: 'credit', status: 'active' },
            attributes: [
                [fn('DATE', col('createdAt')), 'date'],
                [fn('SUM', col('amount')), 'value']
            ],
            group: [fn('DATE', col('createdAt'))],
            order: [[fn('DATE', col('createdAt')), 'ASC']],
            raw: true
        });

        res.status(200).json({ credit: credits });
    } catch (error) {
        console.error("Khata Credit Error:", error);
        res.status(500).json({ message: "Khata credit error: " + error.message });
    }
};

exports.getKhataCustomersAnalytics = async (req, res) => {
    try {
        const { businessId } = req.params;
        const bId = parseInt(businessId);

        const topCustomers = await Customer.findAll({
            where: { business_id: bId, remaining_balance: { [Op.gt]: 0 }, status: 'active' },
            attributes: ['id', 'name', 'phone_number', 'remaining_balance'],
            order: [['remaining_balance', 'DESC']],
            limit: 5,
            raw: true
        });

        const report = topCustomers.map(c => ({
            customer_id: c.id,
            name: c.name,
            phone: c.phone_number,
            total_due: parseFloat(c.remaining_balance)
        }));

        res.status(200).json({ top_due: report });
    } catch (error) {
        console.error("Khata Customers Analytics Error:", error);
        res.status(500).json({ message: "Khata customers analytics error: " + error.message });
    }
};
