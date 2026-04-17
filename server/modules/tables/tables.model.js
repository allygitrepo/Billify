const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const Table = sequelize.define("Tables", {
    id: {
        type: DataTypes.BIGINT,
        primaryKey: true,
        autoIncrement: true
    },
    business_id: {
        type: DataTypes.BIGINT,
        allowNull: false
    },
    table_number: {
        type: DataTypes.STRING,
        allowNull: false
    },
    capacity: {
        type: DataTypes.INTEGER,
        allowNull: true,
        defaultValue: 0
    },
    status: {
        type: DataTypes.STRING,
        defaultValue: 'active' // active, inactive
    }
}, {
    tableName: "tables",
    timestamps: true
});

module.exports = Table;
