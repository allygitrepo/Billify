const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");
const Product = require("../products/products.model");
const Variant = require("../variants/variants.model");

const InventoryLog = sequelize.define("InventoryLog", {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    business_id: { type: DataTypes.BIGINT, allowNull: false },
    product_id: { type: DataTypes.INTEGER, allowNull: false },
    variant_id: { type: DataTypes.INTEGER, allowNull: true },
    variant_name: { type: DataTypes.STRING, allowNull: true },
    change_type: { type: DataTypes.STRING, allowNull: false }, // 'IN' or 'OUT'
    quantity_change: { type: DataTypes.DECIMAL(12, 3), defaultValue: 0 },
    reason: { type: DataTypes.STRING, defaultValue: 'Manual Adjustment' },
    source: { type: DataTypes.STRING, defaultValue: 'manual' }, // 'manual' or 'invoice'
    stock_after: { type: DataTypes.DECIMAL(12, 3), allowNull: true },
    user_id: { type: DataTypes.INTEGER, allowNull: true },
    reference_no: { type: DataTypes.STRING, allowNull: true },
    entity_name: { type: DataTypes.STRING, allowNull: true },
    unit_price: { type: DataTypes.DECIMAL(12, 2), allowNull: true },
    total_amount: { type: DataTypes.DECIMAL(12, 2), allowNull: true }
}, {
    tableName: "inventory_logs",
    timestamps: true,
    indexes: [
        {
            fields: ['business_id'],
            name: 'inventory_logs_business_idx'
        },
        {
            fields: ['product_id'],
            name: 'inventory_logs_product_idx'
        }
    ]
});

InventoryLog.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });
InventoryLog.belongsTo(Variant, { foreignKey: 'variant_id', as: 'variant' });
Product.hasMany(InventoryLog, { foreignKey: 'product_id', as: 'inventory_logs' });

module.exports = InventoryLog;
