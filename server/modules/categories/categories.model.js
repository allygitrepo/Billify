const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const Category = sequelize.define("Category", {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    business_id: { type: DataTypes.BIGINT, allowNull: false },
    name: { type: DataTypes.STRING, allowNull: false },
    description: { type: DataTypes.TEXT, allowNull: true },
    status: { type: DataTypes.STRING, defaultValue: 'active' } // 'active' or 'inactive' to match UI
}, {
    tableName: "categories",
    timestamps: true,
    indexes: [
        {
            unique: true,
            fields: ['business_id', 'name']
        }
    ]
});

module.exports = Category;
