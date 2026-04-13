const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");
const Invoice = require("../invoice/invoice.model");

const InvoiceItem = sequelize.define("InvoiceItem", {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    invoice_id: { type: DataTypes.INTEGER, allowNull: false },
    product_id: { type: DataTypes.INTEGER, allowNull: false },
    product_name: { type: DataTypes.STRING, allowNull: true },
    variant_name: { type: DataTypes.STRING, allowNull: true },
    quantity: { type: DataTypes.DECIMAL(12, 3), allowNull: false },
    price: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
    subtotal: { type: DataTypes.DECIMAL(10, 2), allowNull: false }
}, {
    tableName: "invoice_items",
    timestamps: true
});

// Associations
const Product = require("../products/products.model");
InvoiceItem.belongsTo(Invoice, { foreignKey: 'invoice_id', as: 'invoice' });
InvoiceItem.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });

module.exports = InvoiceItem;
