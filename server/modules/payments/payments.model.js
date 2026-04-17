const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const Payment = sequelize.define("Payment", {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    business_id: { type: DataTypes.BIGINT, allowNull: false },
    customer_id: { type: DataTypes.INTEGER, allowNull: false },
    amount: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    type: { type: DataTypes.STRING, allowNull: false }, // 'credit' (customer owes), 'debit' (customer paid)
    payment_method: { type: DataTypes.STRING, defaultValue: 'Cash' }, // 'Cash', 'UPI', 'Bank', 'Other'
    note: { type: DataTypes.TEXT, allowNull: true },
    reference_invoice_id: { type: DataTypes.INTEGER, allowNull: true },
    created_by: { type: DataTypes.INTEGER, allowNull: true },
    status: { type: DataTypes.STRING, defaultValue: 'active' }, // 'active', 'deleted'
}, {
    tableName: "payments",
    timestamps: true
});

module.exports = Payment;
