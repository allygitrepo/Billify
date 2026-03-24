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
        // 1. Fetch role_id from user_businesses
        const mapping = await UserBusiness.findOne({
            where: {
                user_id,
                business_id,
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
            const business_id = req.headers['x-business-id'] || req.body.business_id || req.query.business_id;

            if (!user_id || !business_id) {
                return res.status(403).json({ message: "Access denied. User or Business not identified." });
            }

            const hasPermission = await checkPermission(user_id, business_id, module_name, action);

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
