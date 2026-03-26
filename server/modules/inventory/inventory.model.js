const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const InventoryLog = sequelize.define("InventoryLog", {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    business_id: { type: DataTypes.INTEGER, allowNull: false },
    product_id: { type: DataTypes.INTEGER, allowNull: false },
    variant_name: { type: DataTypes.STRING, allowNull: true },
    change_type: { type: DataTypes.STRING, allowNull: false }, // 'IN' or 'OUT'
    quantity_change: { type: DataTypes.INTEGER, allowNull: false },
    reason: { type: DataTypes.STRING, allowNull: true }, // 'Sale', 'Restock', 'Damage', 'Return'
    stock_after: { type: DataTypes.INTEGER, allowNull: true },
    user_id: { type: DataTypes.INTEGER, allowNull: true }, // Who performed the move
    reference_no: { type: DataTypes.STRING, allowNull: true },
    entity_name: { type: DataTypes.STRING, allowNull: true }, // Vendor or Customer
    unit_price: { type: DataTypes.DECIMAL(10, 2), allowNull: true, defaultValue: 0 },
    total_amount: { type: DataTypes.DECIMAL(12, 2), allowNull: true, defaultValue: 0 }
}, {
    tableName: "inventory_log",
    timestamps: true
});

// Associations
const Product = require("../products/products.model");
InventoryLog.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });

module.exports = InventoryLog;
