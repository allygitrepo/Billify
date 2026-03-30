const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const Settings = sequelize.define("Settings", {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    business_id: { type: DataTypes.INTEGER, allowNull: false, unique: true },
    tax_percentage: { type: DataTypes.DECIMAL(5, 2), defaultValue: 0 },
    gst_percentage: { type: DataTypes.DECIMAL(5, 2), defaultValue: 0 },
    currency: { type: DataTypes.STRING, defaultValue: 'INR' },
    invoice_prefix: { type: DataTypes.STRING, defaultValue: 'INV' },
    starting_invoice_number: { type: DataTypes.INTEGER, defaultValue: 1 },
    footer_note: { type: DataTypes.TEXT, allowNull: true },
    invoice_format: { type: DataTypes.STRING, defaultValue: 'thermal' }, // 'thermal', 'a4'
    business_name: { type: DataTypes.STRING, allowNull: true },
    business_logo: { type: DataTypes.TEXT, allowNull: true },
    business_address: { type: DataTypes.TEXT, allowNull: true },
    business_phone: { type: DataTypes.STRING, allowNull: true },
    gst_number: { type: DataTypes.STRING, allowNull: true },
    category_compulsory: { type: DataTypes.BOOLEAN, defaultValue: true },
    variants_enabled: { type: DataTypes.BOOLEAN, defaultValue: true }
}, {
    tableName: "settings",
    timestamps: true
});

module.exports = Settings;
