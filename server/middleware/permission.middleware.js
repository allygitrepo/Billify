const RolePermission = require("../modules/role_permission/role_permission.model");
const UserBusiness = require("../modules/users/user_businesses.model");

/**
 * Helper function to check if a role has permission for a specific module and action.
 * @param {number} user_id 
 * @param {number} business_id 
 * @param {string} module_name 
 * @param {string} action - e.g., 'can_add', 'can_view', etc.
 * @returns {Promise<boolean>}
 */
const checkPermission = async (user_id, business_id, module_name, action) => {
    try {
        // Validation: If business_id is not a valid number, it can't be in the database
        const numericBusinessId = parseInt(business_id);
        if (isNaN(numericBusinessId)) {
            console.log(`Check Permission: Invalid business_id provided: ${business_id}`);
            return false;
        }

        // 1. Fetch role_id from user_businesses
        const mapping = await UserBusiness.findOne({
            where: {
                user_id,
                business_id: numericBusinessId,
                status: true
            }
        });

        if (!mapping) return false;

        const role_id = mapping.role_id;

        // 2. Check permission for that role
        const permission = await RolePermission.findOne({
            where: {
                role_id,
                module_name,
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

            // Validation: If business_id is provided, it MUST be numeric
            if (business_id) {
                const numericBusinessId = parseInt(business_id);
                if (isNaN(numericBusinessId)) {
                    return res.status(403).json({ message: "Access denied. Invalid Business ID." });
                }
            }

            // 1. Check if user has a Global Admin role (bypass business check)
            const User = require("../modules/users/users.model");
            const Role = require("../modules/roles/roles.model");
            const user = await User.findByPk(user_id, {
                include: [{ model: Role, as: 'role' }]
            });

            if (user && user.role && user.role.name === 'Admin' && user.role.business_id === null) {
                return next();
            }

            if (!business_id) {
                return res.status(403).json({ message: "Access denied. Business not identified." });
            }

            const numericBusinessId = parseInt(business_id);
            if (isNaN(numericBusinessId)) {
                return res.status(403).json({ message: "Access denied. Invalid Business ID." });
            }

            const hasPermission = await checkPermission(user_id, numericBusinessId, module_name, action);

            // 3. Fast-pass for Admin role
            const mapping = await UserBusiness.findOne({
                where: { user_id, business_id: numericBusinessId, status: true },
                include: [{ model: require("../modules/roles/roles.model"), as: 'role' }]
            });

            if (mapping && mapping.role && mapping.role.name === 'Admin') {
                return next();
            }

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
