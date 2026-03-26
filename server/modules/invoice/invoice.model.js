const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const Invoice = sequelize.define("Invoice", {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    business_id: { type: DataTypes.INTEGER, allowNull: false },
    invoice_number: { type: DataTypes.STRING, allowNull: false },
    customer_name: { type: DataTypes.STRING, allowNull: true },
    customer_phone: { type: DataTypes.STRING, allowNull: true },
    total_amount: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    discount: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    tax_amount: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    final_amount: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
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

Invoice.hasMany(InvoiceItem, { foreignKey: 'invoice_id', as: 'items' });
InvoiceItem.belongsTo(Invoice, { foreignKey: 'invoice_id' });

Invoice.belongsTo(User, { foreignKey: 'user_id', as: 'user' });
User.hasMany(Invoice, { foreignKey: 'user_id' });
