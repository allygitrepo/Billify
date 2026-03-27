const Business = require("./businesses.model");
const UserBusiness = require("../users/user_businesses.model");
const Role = require("../roles/roles.model");
const Settings = require("../settings/settings.model");
const sequelize = require("../../config/db");

const businessController = {
    // ============ Get All Businesses for User ============
    getMyBusinesses: async (req, res) => {
        try {
            // Assuming req.user is populated by auth middleware
            if (!req.user) {
                return res.status(401).json({ message: "Unauthorized" });
            }

            const userBusinesses = await UserBusiness.findAll({
                where: { user_id: req.user.id, status: true },
                include: [
                    { model: Business, as: 'business', where: { status: true } },
                    { model: Role, as: 'role' }
                ]
            });

            return res.status(200).json({
                businesses: userBusinesses.map(ub => ({
                    ...ub.business.get({ plain: true }),
                    role: ub.role ? ub.role.name : 'User',
                    role_id: ub.role_id
                }))
            });
        } catch (error) {
            console.error("Get My Businesses Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Create New Business ============
    createBusiness: async (req, res) => {
        const t = await sequelize.transaction();
        try {
            const { businessName, phone, gstin, address, photo } = req.body;
            const userId = req.user.id;

            if (!businessName) {
                return res.status(400).json({ message: "Business Name is required" });
            }

            // 1. Create Business
            const business = await Business.create({
                owner_user_id: userId,
                name: businessName,
                phone: phone || '',
                gstin: gstin || '',
                address: address || ''
            }, { transaction: t });

            // 2. Resolve Admin Role
            const [adminRole] = await Role.findOrCreate({
                where: { name: 'Admin' },
                defaults: { description: 'System Administrator with full access' },
                transaction: t
            });

            // 3. Map User to Business as Admin
            await UserBusiness.create({
                user_id: userId,
                business_id: business.id,
                role_id: adminRole.id,
                status: true
            }, { transaction: t });

            // 4. Create Default Settings
            await Settings.create({
                business_id: business.id,
                business_name: businessName,
                business_phone: phone || '',
                business_address: address || '',
                gst_number: gstin || '',
                business_logo: photo || '',
                tax_percentage: 0,
                gst_percentage: 0,
                currency: 'INR',
                invoice_prefix: 'INV',
                starting_invoice_number: 1,
                invoice_format: 'thermal',
                footer_note: ''
            }, { transaction: t });

            await t.commit();

            return res.status(201).json({
                message: "Business created successfully",
                business: {
                    ...business.get({ plain: true }),
                    role: 'Admin',
                    role_id: adminRole.id
                }
            });
        } catch (error) {
            await t.rollback();
            console.error("Create Business Error:", error);
            return res.status(500).json({ message: "Internal server error", error: error.message });
        }
    },

    // ============ Update Business ============
    updateBusiness: async (req, res) => {
        try {
            const { id } = req.params;
            const { name, phone, gstin, address, status } = req.body;

            const business = await Business.findByPk(id);
            if (!business) {
                return res.status(404).json({ message: "Business not found" });
            }

            await business.update({
                name: name !== undefined ? name : business.name,
                phone: phone !== undefined ? phone : business.phone,
                gstin: gstin !== undefined ? gstin : business.gstin,
                address: address !== undefined ? address : business.address,
                status: status !== undefined ? status : business.status
            });

            return res.status(200).json({
                message: "Business updated successfully",
                business
            });
        } catch (error) {
            console.error("Update Business Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Delete Business (Soft Delete) ============
    deleteBusiness: async (req, res) => {
        try {
            const { id } = req.params;
            const business = await Business.findByPk(id);
            if (!business) {
                return res.status(404).json({ message: "Business not found" });
            }

            // Soft delete
            await business.update({ status: false });
            
            // Also deactivate associations
            await UserBusiness.update(
                { status: false },
                { where: { business_id: id } }
            );

            return res.status(200).json({ message: "Business deleted successfully" });
        } catch (error) {
            console.error("Delete Business Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = businessController;
