const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");

const UOM = sequelize.define("UOM", {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    business_id: { type: DataTypes.BIGINT, allowNull: false },
    name: { type: DataTypes.STRING, allowNull: false },
    shortCode: { type: DataTypes.STRING, allowNull: false, field: 'symbol' },
    conversion_factor: { type: DataTypes.DECIMAL(10, 4), defaultValue: 1.0000 },
    base_unit_id: { type: DataTypes.INTEGER, allowNull: true }, // Points to self
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
            fields: ['business_id', 'symbol']
        }
    ]
});

// Self-association for unit hierarchy
UOM.belongsTo(UOM, { as: 'baseUnit', foreignKey: 'base_unit_id' });
UOM.hasMany(UOM, { as: 'derivedUnits', foreignKey: 'base_unit_id' });

module.exports = UOM;
