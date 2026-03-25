const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const Product = require("../products/products.model");

const Variant = sequelize.define("Variant", {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    product_id: { type: DataTypes.INTEGER, allowNull: false },
    name: { type: DataTypes.STRING, allowNull: false },
    sku: { type: DataTypes.STRING, allowNull: true },
    price: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
    stock: { type: DataTypes.INTEGER, defaultValue: 0 },
    status: { type: DataTypes.STRING, defaultValue: 'active' } // 'active' or 'inactive'
}, {
    tableName: "variants",
    timestamps: true
});

// Associations
Product.hasMany(Variant, { foreignKey: 'product_id', as: 'variants' });
Variant.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });

module.exports = Variant;
