const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const Category = require("../categories/categories.model");

const Product = sequelize.define("Product", {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    business_id: { type: DataTypes.BIGINT, allowNull: false },
    category_id: { type: DataTypes.INTEGER, allowNull: true }, // Not mandatory
    name: { type: DataTypes.STRING, allowNull: false },
    description: { type: DataTypes.TEXT, allowNull: true },
    hsnCode: { type: DataTypes.STRING, allowNull: true },
    uom: { type: DataTypes.STRING, defaultValue: 'Pcs' },
    status: { type: DataTypes.STRING, defaultValue: 'active' }, // 'active' or 'inactive'
    photo: { type: DataTypes.TEXT, allowNull: true }, // Base64 string
    barcode: { type: DataTypes.STRING, allowNull: true },
    has_variants: { type: DataTypes.BOOLEAN, defaultValue: false },
    is_weighted: { type: DataTypes.BOOLEAN, defaultValue: false },
    base_uom_id: { type: DataTypes.INTEGER, allowNull: true },
    price: { type: DataTypes.DECIMAL(12, 2), allowNull: true },
    opening_stock: { type: DataTypes.DECIMAL(12, 3), defaultValue: 0 },
    current_stock: { type: DataTypes.DECIMAL(12, 3), defaultValue: 0 }
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

const UOM = require("../uoms/uoms.model");
Product.belongsTo(UOM, { foreignKey: 'base_uom_id', as: 'baseUom' });
UOM.hasMany(Product, { foreignKey: 'base_uom_id', as: 'products' });

module.exports = Product;
