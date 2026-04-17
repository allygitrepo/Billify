const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const Invoice = sequelize.define("Invoice", {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    business_id: { type: DataTypes.BIGINT, allowNull: false },
    invoice_number: { type: DataTypes.STRING, allowNull: false },
    customer_id: { type: DataTypes.INTEGER, allowNull: true }, // For regular customers
    customer_type: { type: DataTypes.STRING, defaultValue: 'WALKIN' }, // 'WALKIN', 'REGULAR'
    customer_name: { type: DataTypes.STRING, allowNull: true }, // Still here for display or walk-ins
    customer_phone: { type: DataTypes.STRING, allowNull: true },
    total_amount: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    discount: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    tax_amount: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    final_amount: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    paid_amount: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 }, // New field to track credit
    payment_mode: { type: DataTypes.STRING, defaultValue: 'Cash' }, // 'Cash', 'UPI', 'Card'
    status: { type: DataTypes.STRING, defaultValue: 'Paid' }, // 'Paid', 'Pending'
    user_id: { type: DataTypes.INTEGER, allowNull: true }
}, {
    tableName: "invoices",
    timestamps: true,
    indexes: [
        {
            unique: true,
            fields: ['business_id', 'invoice_number']
        }
    ]
});

module.exports = Invoice;

// Associations
const InvoiceItem = require("../invoiceItems/invoice_items.model");
const User = require("../users/users.model");
const Customer = require("../customers/customers.model");

Invoice.hasMany(InvoiceItem, { foreignKey: 'invoice_id', as: 'items' });
InvoiceItem.belongsTo(Invoice, { foreignKey: 'invoice_id' });

Invoice.belongsTo(User, { foreignKey: 'user_id', as: 'user' });
User.hasMany(Invoice, { foreignKey: 'user_id' });

Invoice.belongsTo(Customer, { foreignKey: 'customer_id', as: 'customer' });
Customer.hasMany(Invoice, { foreignKey: 'customer_id' });

const Business = require("../businesses/businesses.model");
Invoice.belongsTo(Business, { foreignKey: 'business_id', as: 'business' });
Business.hasMany(Invoice, { foreignKey: 'business_id' });
