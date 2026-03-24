const Role = require("./roles.model");

const rolesController = {
    // ============ Create Role ============
    createRole: async (req, res) => {
        try {
            const { business_id, name, description } = req.body;

            if (!business_id || !name) {
                return res.status(400).json({ message: "Business ID and Name are required" });
            }

            const role = await Role.create({
                business_id,
                name,
                description
            });

            return res.status(201).json({
                message: "Role created successfully",
                role
            });
        } catch (error) {
            console.error("Create Role Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Get All Roles (Active Only) ============
    getAllRoles: async (req, res) => {
        try {
            const roles = await Role.findAll({ where: { status: true } });
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
            const roles = await Role.findAll({ where: { business_id, status: true } });
            return res.status(200).json({ roles });
        } catch (error) {
            console.error("Get Roles By Business ID Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Update Role ============
    updateRole: async (req, res) => {
        try {
            const { id } = req.params;
            const { name, description } = req.body;

            const role = await Role.findOne({ where: { id, status: true } });

            if (!role) {
                return res.status(404).json({ message: "Role not found" });
            }

            role.name = name || role.name;
            role.description = description || role.description;

            await role.save();

            return res.status(200).json({
                message: "Role updated successfully",
                role
            });
        } catch (error) {
            console.error("Update Role Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Delete Role (Soft Delete) ============
    deleteRole: async (req, res) => {
        try {
            const { id } = req.params;
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
