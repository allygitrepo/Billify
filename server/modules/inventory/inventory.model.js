const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const Inventory = sequelize.define("Inventory", {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    business_id: { type: DataTypes.BIGINT, allowNull: false },
    product_id: { type: DataTypes.INTEGER, allowNull: false },
    variant_id: { type: DataTypes.INTEGER, allowNull: true }, // NULL if product has no variants
    current_stock: { type: DataTypes.DECIMAL(12, 3), defaultValue: 0 }
}, {
    tableName: "inventory",
    timestamps: true,
    indexes: [
        {
            unique: true,
            fields: ['product_id', 'variant_id'],
            name: 'unique_product_variant_stock'
        }
    ]
});

// Associations
const Product = require("../products/products.model");
const Variant = require("../variants/variants.model");

Inventory.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });
Inventory.belongsTo(Variant, { foreignKey: 'variant_id', as: 'variant' });
Product.hasMany(Inventory, { foreignKey: 'product_id', as: 'inventory' });
Variant.hasOne(Inventory, { foreignKey: 'variant_id', as: 'inventory' });

module.exports = Inventory;
