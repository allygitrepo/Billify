const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const Business = sequelize.define("Businesses",
    {
        id: { type: DataTypes.BIGINT, primaryKey: true, autoIncrement: true },
        owner_user_id: { type: DataTypes.INTEGER, allowNull: false },
        name: { type: DataTypes.STRING, allowNull: false, defaultValue: "" },
        phone: { type: DataTypes.STRING, allowNull: true },
        gstin: { type: DataTypes.STRING, allowNull: true },
        address: { type: DataTypes.TEXT, allowNull: true },
        tax: { type: DataTypes.STRING, allowNull: true },
        gst_percentage: { type: DataTypes.FLOAT, allowNull: true },
        invoice_prefix: { type: DataTypes.STRING, allowNull: true },
        invoice_format: { type: DataTypes.STRING, allowNull: true },
        business_logo: { type: DataTypes.TEXT, allowNull: true },
        status: { type: DataTypes.BOOLEAN, defaultValue: true }
    },
    {
        tableName: "businesses",
        timestamps: true
    }
);

module.exports = Business;
