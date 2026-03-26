const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const User = sequelize.define("Users",
    {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        name: { type: DataTypes.STRING, allowNull: false },
        email: { type: DataTypes.STRING, allowNull: false, unique: true },
        mobile: { type: DataTypes.STRING, allowNull: true },
        password: { type: DataTypes.STRING, allowNull: false },
        role_id: { type: DataTypes.INTEGER, allowNull: true },
        photo: { type: DataTypes.TEXT, allowNull: true },
        status: { type: DataTypes.BOOLEAN, defaultValue: true }
    },
    {
        tableName: "users",
        timestamps: true
    }
);

module.exports = User;
