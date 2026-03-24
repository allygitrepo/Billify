const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");
const Role = require("../roles/roles.model");

const RolePermission = sequelize.define("RolePermission",
    {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        role_id: { 
            type: DataTypes.INTEGER, 
            allowNull: false,
            references: {
                model: 'roles',
                key: 'id'
            }
        },
        module_name: { type: DataTypes.STRING, allowNull: false },
        can_add: { type: DataTypes.BOOLEAN, defaultValue: false },
        can_view: { type: DataTypes.BOOLEAN, defaultValue: false },
        can_update: { type: DataTypes.BOOLEAN, defaultValue: false },
        can_delete: { type: DataTypes.BOOLEAN, defaultValue: false },
        can_export: { type: DataTypes.BOOLEAN, defaultValue: false },
        can_bulk_upload: { type: DataTypes.BOOLEAN, defaultValue: false },
        can_download: { type: DataTypes.BOOLEAN, defaultValue: false },
        can_print: { type: DataTypes.BOOLEAN, defaultValue: false },
        status: { type: DataTypes.BOOLEAN, defaultValue: true }
    },
    {
        tableName: "role_permissions",
        timestamps: true
    }
);

// Relationships
Role.hasMany(RolePermission, { foreignKey: 'role_id', as: 'permissions' });
RolePermission.belongsTo(Role, { foreignKey: 'role_id', as: 'role' });

module.exports = RolePermission;
