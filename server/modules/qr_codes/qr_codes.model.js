const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");
const Business = require("../businesses/businesses.model");

const QrCode = sequelize.define("QrCodes",
    {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        business_id: { type: DataTypes.INTEGER, allowNull: false },
        qr_type: { 
            type: DataTypes.STRING, 
            allowNull: false, 
            defaultValue: "Profile",
            comment: "Type of QR: Profile, Payment, etc."
        },
        qr_data: { 
            type: DataTypes.TEXT, 
            allowNull: false, 
            comment: "Base64 string of the QR code"
        },
        status: { type: DataTypes.BOOLEAN, defaultValue: true }
    },
    {
        tableName: "qr_codes",
        timestamps: true
    }
);

// Associations
Business.hasMany(QrCode, { foreignKey: 'business_id', as: 'qrCodes' });
QrCode.belongsTo(Business, { foreignKey: 'business_id', as: 'business' });

module.exports = QrCode;
