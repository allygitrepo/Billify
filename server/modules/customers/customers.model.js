const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const Customer = sequelize.define("Customer", {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    business_id: { type: DataTypes.BIGINT, allowNull: false },
    name: { type: DataTypes.STRING, allowNull: false },
    phone_number: { type: DataTypes.STRING, allowNull: false },
    opening_balance: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    remaining_balance: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    photo: { type: DataTypes.TEXT, allowNull: true },
    city: { type: DataTypes.STRING, allowNull: true },
    status: { type: DataTypes.STRING, defaultValue: 'active' }, // 'active', 'deleted'
    created_by: { type: DataTypes.INTEGER, allowNull: true },
}, {
    tableName: "customers",
    timestamps: true,
    indexes: [
        {
            unique: true,
            fields: ['business_id', 'phone_number']
        }
    ]
});

module.exports = Customer;
