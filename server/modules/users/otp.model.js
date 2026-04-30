const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const OTP = sequelize.define("OTP",
    {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        phoneNumber: { type: DataTypes.STRING, allowNull: true },
        otp: { type: DataTypes.STRING, allowNull: false },
        expires_at: { type: DataTypes.DATE, allowNull: false }
    },
    {
        tableName: "otp_verifications",
        timestamps: true
    }
);

module.exports = OTP;
