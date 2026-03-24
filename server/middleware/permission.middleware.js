const RolePermission = require("../modules/role_permission/role_permission.model");

/**
 * Helper function to check if a role has permission for a specific module and action.
 * @param {number} role_id 
 * @param {string} module_name 
 * @param {string} action - e.g., 'can_add', 'can_view', etc.
 * @returns {Promise<boolean>}
 */
const checkPermission = async (role_id, module_name, action) => {
    try {
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
            // Assuming req.user.role_id is populated by authentication middleware
            const role_id = req.user ? req.user.role_id : req.body.role_id; 

            if (!role_id) {
                return res.status(403).json({ message: "Access denied. No role identified." });
            }

            const hasPermission = await checkPermission(role_id, module_name, action);

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
