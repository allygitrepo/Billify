const RolePermission = require("./role_permission.model");
const sequelize = require("../../config/db");

const rolePermissionController = {
    // ============ Save / Update Permissions ============
    savePermissions: async (req, res) => {
        const t = await sequelize.transaction();
        try {
            const { role_id, permissions } = req.body;

            if (!role_id || !Array.isArray(permissions)) {
                return res.status(400).json({ message: "Role ID and permissions array are required" });
            }

            // 1. Soft delete (status = false) all existing permissions for the role
            await RolePermission.update(
                { status: false },
                { where: { role_id }, transaction: t }
            );

            // 2. Insert new records or update existing ones with status = true
            for (const perm of permissions) {
                const existing = await RolePermission.findOne({
                    where: { role_id, module_name: perm.module_name },
                    transaction: t
                });

                if (existing) {
                    await existing.update(
                        {
                            can_add: perm.can_add || false,
                            can_view: perm.can_view || false,
                            can_update: perm.can_update || false,
                            can_delete: perm.can_delete || false,
                            can_export: perm.can_export || false,
                            can_bulk_upload: perm.can_bulk_upload || false,
                            can_download: perm.can_download || false,
                            can_print: perm.can_print || false,
                            status: true
                        },
                        { transaction: t }
                    );
                } else {
                    await RolePermission.create(
                        {
                            role_id,
                            module_name: perm.module_name,
                            can_add: perm.can_add || false,
                            can_view: perm.can_view || false,
                            can_update: perm.can_update || false,
                            can_delete: perm.can_delete || false,
                            can_export: perm.can_export || false,
                            can_bulk_upload: perm.can_bulk_upload || false,
                            can_download: perm.can_download || false,
                            can_print: perm.can_print || false,
                            status: true
                        },
                        { transaction: t }
                    );
                }
            }
            await t.commit();

            return res.status(200).json({
                message: "Permissions updated successfully"
            });
        } catch (error) {
            await t.rollback();
            console.error("Save Permissions Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Get Permissions by Role ============
    getPermissionsByRoleId: async (req, res) => {
        try {
            const { role_id } = req.params;

            if (isNaN(role_id)) {
                return res.status(400).json({ message: "Invalid Role ID format" });
            }

            const permissions = await RolePermission.findAll({
                where: { role_id, status: true }
            });

            // Return structured response
            const structuredResponse = {};
            permissions.forEach(perm => {
                structuredResponse[perm.module_name] = {
                    can_add: perm.can_add,
                    can_view: perm.can_view,
                    can_update: perm.can_update,
                    can_delete: perm.can_delete,
                    can_export: perm.can_export,
                    can_bulk_upload: perm.can_bulk_upload,
                    can_download: perm.can_download,
                    can_print: perm.can_print
                };
            });

            return res.status(200).json(structuredResponse);
        } catch (error) {
            console.error("Get Permissions Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = rolePermissionController;
