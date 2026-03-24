const { DataTypes } = require("sequelize");
const sequelize = require("../../config/db");
const User = require("../users/users.model");
const Business = require("../businesses/businesses.model");
const Role = require("../roles/roles.model");

const UserBusiness = sequelize.define("UserBusinesses",
    {
        id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
        user_id: { type: DataTypes.INTEGER, allowNull: false },
        business_id: { type: DataTypes.INTEGER, allowNull: false },
        role_id: { type: DataTypes.INTEGER, allowNull: false },
        status: { type: DataTypes.BOOLEAN, defaultValue: true }
    },
    {
        tableName: "user_businesses",
        timestamps: true
    }
);

// Associations
User.hasMany(UserBusiness, { foreignKey: 'user_id', as: 'userBusinesses' });
UserBusiness.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

Business.hasMany(UserBusiness, { foreignKey: 'business_id', as: 'businessUsers' });
UserBusiness.belongsTo(Business, { foreignKey: 'business_id', as: 'business' });

Role.hasMany(UserBusiness, { foreignKey: 'role_id', as: 'userRoles' });
UserBusiness.belongsTo(Role, { foreignKey: 'role_id', as: 'role' });

module.exports = UserBusiness;
