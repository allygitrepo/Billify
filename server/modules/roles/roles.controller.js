const Role = require("./roles.model");
const RolePermission = require("../role_permission/role_permission.model");
const sequelize = require("../../config/db");

const rolesController = {
    // ============ Create Role ============
    createRole: async (req, res) => {
        const t = await sequelize.transaction();
        try {
            const { business_id, name, description, permissions } = req.body;

            if (!business_id || !name) {
                await t.rollback();
                return res.status(400).json({ message: "Business ID and Name are required" });
            }

            const role = await Role.create({
                business_id,
                name,
                description
            }, { transaction: t });

            // Save permissions if provided
            if (permissions && typeof permissions === 'object') {
                const permEntries = Object.entries(permissions).map(([module_name, actions]) => ({
                    role_id: role.id,
                    module_name,
                    can_add: !!actions.add,
                    can_view: !!actions.view,
                    can_update: !!actions.update,
                    can_delete: !!actions.delete,
                    can_export: !!actions.export,
                    can_bulk_upload: !!actions.import,
                    can_download: !!actions.download,
                    can_print: !!actions.print
                }));

                await RolePermission.bulkCreate(permEntries, { transaction: t });
            }

            await t.commit();
            return res.status(201).json({
                message: "Role created successfully",
                role
            });
        } catch (error) {
            await t.rollback();
            console.error("Create Role Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Get All Roles (Active Only) ============
    getAllRoles: async (req, res) => {
        try {
            const roles = await Role.findAll({ 
                where: { status: true },
                include: [{ model: RolePermission, as: 'permissions' }]
            });
            return res.status(200).json({ roles });
        } catch (error) {
            console.error("Get All Roles Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Get Role By ID ============
    getRoleById: async (req, res) => {
        try {
            const { id } = req.params;

            // Validate ID is numeric
            if (isNaN(id)) {
                return res.status(400).json({ message: "Invalid Role ID format" });
            }

            const role = await Role.findOne({ where: { id, status: true } });

            if (!role) {
                return res.status(404).json({ message: "Role not found" });
            }

            return res.status(200).json({ role });
        } catch (error) {
            console.error("Get Role By ID Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Get Roles By Business ID ============
    getRolesByBusinessId: async (req, res) => {
        try {
            const { business_id } = req.params;
            const roles = await Role.findAll({ 
                where: { business_id, status: true },
                include: [{ model: RolePermission, as: 'permissions' }]
            });
            return res.status(200).json({ roles });
        } catch (error) {
            console.error("Get Roles By Business ID Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Update Role ============
    updateRole: async (req, res) => {
        const t = await sequelize.transaction();
        try {
            const { id } = req.params;
            const { name, description, permissions } = req.body;

            if (isNaN(id)) {
                await t.rollback();
                return res.status(400).json({ message: "Invalid Role ID format" });
            }

            const role = await Role.findOne({ where: { id, status: true } });
            if (!role) {
                await t.rollback();
                return res.status(404).json({ message: "Role not found" });
            }

            role.name = name || role.name;
            role.description = description || role.description;
            await role.save({ transaction: t });

            // Update permissions if provided
            if (permissions && typeof permissions === 'object') {
                // Simplest way: Delete existing and bulk create
                await RolePermission.destroy({ where: { role_id: id }, transaction: t });

                const permEntries = Object.entries(permissions).map(([module_name, actions]) => ({
                    role_id: id,
                    module_name,
                    can_add: !!actions.add,
                    can_view: !!actions.view,
                    can_update: !!actions.update,
                    can_delete: !!actions.delete,
                    can_export: !!actions.export,
                    can_bulk_upload: !!actions.import,
                    can_download: !!actions.download,
                    can_print: !!actions.print
                }));

                await RolePermission.bulkCreate(permEntries, { transaction: t });
            }

            await t.commit();
            return res.status(200).json({
                message: "Role updated successfully",
                role
            });
        } catch (error) {
            await t.rollback();
            console.error("Update Role Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Delete Role (Soft Delete) ============
    deleteRole: async (req, res) => {
        try {
            const { id } = req.params;

            // Validate ID is numeric
            if (isNaN(id)) {
                return res.status(400).json({ message: "Invalid Role ID format" });
            }

            const role = await Role.findOne({ where: { id, status: true } });

            if (!role) {
                return res.status(404).json({ message: "Role not found" });
            }

            // Soft delete by setting status to false
            role.status = false;
            await role.save();

            return res.status(200).json({
                message: "Role deleted successfully"
            });
        } catch (error) {
            console.error("Delete Role Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = rolesController;
