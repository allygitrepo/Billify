const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const QrCode = sequelize.define("QrCodes", {
    id: {
        type: DataTypes.BIGINT,
        primaryKey: true,
        autoIncrement: true
    },
    business_id: {
        type: DataTypes.BIGINT,
        allowNull: false
    },
    qr_type: {
        type: DataTypes.STRING,
        allowNull: false,
        defaultValue: 'business_profile'
    },
    reference_id: {
        type: DataTypes.BIGINT,
        allowNull: false
    },
    raw_data: {
        type: DataTypes.TEXT,
        allowNull: false
    },
    qr_image: {
        type: DataTypes.TEXT,
        allowNull: false
    },
    status: {
        type: DataTypes.BOOLEAN,
        defaultValue: true
    }
}, {
    tableName: "qr_codes",
    timestamps: true
});

module.exports = QrCode;
