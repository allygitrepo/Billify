const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const UOM = sequelize.define("UOM", {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    business_id: { type: DataTypes.INTEGER, allowNull: false },
    name: { type: DataTypes.STRING, allowNull: false },
    shortCode: { type: DataTypes.STRING, allowNull: false },
    status: { type: DataTypes.BOOLEAN, defaultValue: true }
}, {
    tableName: "uoms",
    timestamps: true,
    indexes: [
        {
            unique: true,
            fields: ['business_id', 'name']
        },
        {
            unique: true,
            fields: ['business_id', 'shortCode']
        }
    ]
});

module.exports = UOM;
