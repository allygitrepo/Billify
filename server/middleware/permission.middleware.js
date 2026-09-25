const { Op } = require("sequelize");
const RolePermission = require("../modules/role_permission/role_permission.model");
const UserBusiness = require("../modules/users/user_businesses.model");
const Role = require("../modules/roles/roles.model");
const User = require("../modules/users/users.model");
const Business = require("../modules/businesses/businesses.model");

/**
 * Returns all recognized alias forms for a module name to ensure seamless matching
 * regardless of camelCase, lower case, or display label variations.
 */
const getModuleAliases = (moduleName) => {
    if (!moduleName) return [];
    const clean = moduleName.toLowerCase().replace(/[^a-z0-9]/g, '');
    
    const aliasMap = {
        'dashboard': ['dashboard', 'Dashboard'],
        'reports': ['reports', 'Reports'],
        'analytics': ['analytics', 'Analytics', 'analyticsReports', 'Analytics & Reports'],
        'products': ['products', 'Products', 'product', 'Product', 'Products Master'],
        'categories': ['categories', 'Categories', 'category', 'Category', 'Categories Master'],
        'usermanagement': ['userManagement', 'User Management', 'staff', 'Staff', 'staff management', 'Staff Management', 'users', 'Users'],
        'billing': ['billing', 'Billing', 'billingpos', 'Billing / POS', 'pos', 'POS', 'invoice', 'Invoices'],
        'transactionlogs': ['transactionLogs', 'Transaction Logs', 'transactions', 'Transactions', 'logs', 'Logs'],
        'inventory': ['inventory', 'Inventory', 'inventoryManagement', 'Inventory Management', 'stock', 'Stock'],
        'uom': ['uom', 'UOM', 'units', 'Units', 'unitsOfMeasurement', 'Units of Measurement'],
        'customers': ['customers', 'Customers', 'customer', 'Customer', 'customerManagement', 'customer management', 'Customer Management'],
        'payments': ['payments', 'Payments', 'payment', 'Payment', 'khata', 'Khata', 'khataManagement', 'Khata management', 'Khata Management'],
        'systemsettings': ['systemSettings', 'System Settings', 'settings', 'Settings'],
        'businesses': ['businesses', 'Businesses', 'business', 'Business', 'bussinesses', 'Bussinesses'],
    };

    const found = aliasMap[clean];
    if (found) {
        return Array.from(new Set([moduleName, ...found]));
    }
    return [moduleName];
};

/**
 * Helper function to check if a role/user has permission for a specific module and action.
 * Supports both:
 * - checkPermission(role_id, module_name, action) [3 args]
 * - checkPermission(user_id, business_id, module_name, action) [4 args]
 * @returns {Promise<boolean>}
 */
const checkPermission = async (...args) => {
    try {
        let role_id;
        let module_name;
        let action;

        if (args.length === 3) {
            role_id = parseInt(args[0]);
            module_name = args[1];
            action = args[2];
        } else if (args.length >= 4) {
            const user_id = args[0];
            const business_id = parseInt(args[1]);
            module_name = args[2];
            action = args[3];

            if (isNaN(business_id)) return false;

            // 1. Direct Business Owner Check
            const isOwner = await Business.findOne({
                where: { id: business_id, owner_user_id: user_id, status: true }
            });
            if (isOwner) return true;

            // 2. Fetch role_id and role from user_businesses
            const mapping = await UserBusiness.findOne({
                where: {
                    user_id,
                    business_id,
                    status: true
                },
                include: [{ model: Role, as: 'role' }]
            });

            if (!mapping) return false;

            // Admin / Owner fast-pass within business
            const roleName = mapping.role?.name?.toLowerCase();
            if (!mapping.role_id || mapping.role_id === 1 || roleName === 'admin' || roleName === 'owner') {
                return true;
            }

            role_id = mapping.role_id;
        } else {
            return false;
        }

        if (!role_id) return true;

        const moduleAliases = getModuleAliases(module_name);

        // 3. Check permission for that role across all alias forms
        const permission = await RolePermission.findOne({
            where: {
                role_id,
                module_name: {
                    [Op.in]: moduleAliases
                },
                [action]: true,
                status: true
            }
        });

        return !!permission;
    } catch (error) {
        console.error("Check Permission Error:", error);
        return false;
    }
};

/**
 * Middleware wrapper for checkPermission
 * @param {string} module_name 
 * @param {string} action 
 */
const authorize = (module_name, action) => {
    return async (req, res, next) => {
        try {
            const user_id = req.user ? req.user.id : null;
            const business_id = req.headers['x-business-id'] || req.params.business_id || (req.body ? req.body.business_id : null) || (req.query ? req.query.business_id : null);

            if (!user_id) {
                return res.status(403).json({ message: "Access denied. User not identified." });
            }

            // 1. Global Admin / Superuser Check
            const user = await User.findByPk(user_id, {
                include: [{ model: Role, as: 'role' }]
            });

            if (user && (user.role_id === 1 || (user.role && (user.role.name?.toLowerCase() === 'admin' || user.role.name?.toLowerCase() === 'global admin')))) {
                return next();
            }

            if (!business_id) {
                return res.status(403).json({ message: "Access denied. Business not identified." });
            }

            const numericBusinessId = parseInt(business_id);
            if (isNaN(numericBusinessId)) {
                return res.status(403).json({ message: "Access denied. Invalid Business ID." });
            }

            // 2. Direct Business Owner Check
            const isOwner = await Business.findOne({
                where: { id: numericBusinessId, owner_user_id: user_id, status: true }
            });
            if (isOwner) {
                return next();
            }

            // 3. Business Admin / Owner Fast-Pass from UserBusiness mapping
            const mapping = await UserBusiness.findOne({
                where: { user_id, business_id: numericBusinessId, status: true },
                include: [{ model: Role, as: 'role' }]
            });

            if (mapping) {
                const roleName = mapping.role?.name?.toLowerCase();
                if (!mapping.role_id || mapping.role_id === 1 || roleName === 'admin' || roleName === 'owner') {
                    return next();
                }
            }

            // 4. Granular Role Permission Check
            const hasPermission = await checkPermission(user_id, numericBusinessId, module_name, action);

            if (!hasPermission) {
                return res.status(403).json({ message: `Access denied. You do not have '${action}' permission for '${module_name}'.` });
            }

            next();
        } catch (error) {
            console.error("Authorization Middleware Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    };
};

module.exports = { checkPermission, authorize };

