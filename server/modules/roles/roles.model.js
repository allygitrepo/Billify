const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const Role = sequelize.define("Roles",
    {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        business_id: { type: DataTypes.BIGINT, allowNull: true },
        name: { type: DataTypes.STRING, allowNull: false },
        description: { type: DataTypes.STRING, allowNull: true },
        status: { type: DataTypes.BOOLEAN, defaultValue: true }
    },
    {
        tableName: "roles",
        timestamps: true
    }
);

module.exports = Role;
