const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const Category = require("../categories/categories.model");

const Product = sequelize.define("Product", {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    business_id: { type: DataTypes.INTEGER, allowNull: false },
    category_id: { type: DataTypes.INTEGER, allowNull: true }, // Not mandatory
    name: { type: DataTypes.STRING, allowNull: false },
    description: { type: DataTypes.TEXT, allowNull: true },
    basePrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    purchasePrice: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    hsnCode: { type: DataTypes.STRING, allowNull: true },
    uom: { type: DataTypes.STRING, defaultValue: 'Pcs' },
    status: { type: DataTypes.STRING, defaultValue: 'active' }, // 'active' or 'inactive'
    photo: { type: DataTypes.TEXT, allowNull: true }, // Base64 string
    barcode: { type: DataTypes.STRING, allowNull: true }
}, {
    tableName: "products",
    timestamps: true,
    indexes: [
        {
            unique: true,
            fields: ['business_id', 'hsnCode'],
            where: {
                hsnCode: {
                    [require('sequelize').Op.ne]: null
                }
            }
        },
        {
            unique: true,
            fields: ['business_id', 'name']
        },
        {
            unique: true,
            fields: ['business_id', 'barcode'],
            where: {
                barcode: {
                    [require('sequelize').Op.ne]: null
                }
            }
        }
    ]
});

// Associations
Category.hasMany(Product, { foreignKey: 'category_id', as: 'products' });
Product.belongsTo(Category, { foreignKey: 'category_id', as: 'category' });

module.exports = Product;
