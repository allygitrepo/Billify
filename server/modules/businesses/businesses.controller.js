const Business = require("./businesses.model");
const UserBusiness = require("../users/user_businesses.model");
const Role = require("../roles/roles.model");
const Settings = require("../settings/settings.model");
const UOM = require("../uoms/uoms.model");
const sequelize = require("../../config/db");

const businessController = {
    // ============ Get All Businesses for User ============
    getMyBusinesses: async (req, res) => {
        try {
            if (!req.user) {
                return res.status(401).json({ message: "Unauthorized" });
            }

            const userId = req.user.id;
            
            // Fetch only businesses explicitly mapped to this user in user_businesses
            const userBusinesses = await UserBusiness.findAll({
                where: { user_id: userId, status: true },
                include: [
                    { 
                        model: Business, 
                        as: 'business', 
                        where: { status: true },
                        include: [{ model: Settings, as: 'settings' }]
                    },
                    { model: Role, as: 'role' }
                ]
            });

            return res.status(200).json({
                businesses: userBusinesses.map(ub => {
                    const b = ub.business.get({ plain: true });
                    const s = b.settings || {};
                    return {
                        ...b,
                        // Override/Fallback fields from settings for UI consistency
                        phone: s.business_phone || b.phone || '',
                        name: s.business_name || b.name || '',
                        address: s.business_address || b.address || '',
                        gstin: s.gst_number || b.gstin || '',
                        business_logo: s.business_logo || b.business_logo || '',
                        tax: s.tax_percentage !== undefined && s.tax_percentage !== null ? s.tax_percentage : b.tax,
                        gst_percentage: s.gst_percentage !== undefined && s.gst_percentage !== null ? s.gst_percentage : b.gst_percentage,
                        invoice_prefix: s.invoice_prefix || b.invoice_prefix || 'INV',
                        role: ub.role ? ub.role.name : 'User',
                        role_id: ub.role_id
                    };
                })
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

            const finalBusinessName = businessName || req.body.name;
            const finalPhone = phone || req.body.business_phone || req.body.businessPhone || req.body.phone_number || '';
            const finalGstin = gstin || req.body.gst_number || req.body.gstNumber || '';
            const finalAddress = address || req.body.business_address || req.body.businessAddress || '';
            const finalPhoto = photo || req.body.business_logo || req.body.businessLogo || '';

            if (!finalBusinessName) {
                return res.status(400).json({ message: "Business Name is required" });
            }

            // 1. Create Business
            const taxVal = req.body.taxPercentage !== undefined ? req.body.taxPercentage : (req.body.tax !== undefined ? req.body.tax : 0);
            const gstVal = req.body.gstPercentage !== undefined ? req.body.gstPercentage : (req.body.gst_percentage !== undefined ? req.body.gst_percentage : 0);

            const business = await Business.create({
                owner_user_id: userId,
                name: finalBusinessName,
                phone: finalPhone,
                gstin: finalGstin,
                address: finalAddress,
                business_logo: finalPhoto,
                tax: String(taxVal),
                gst_percentage: parseFloat(gstVal) || 0,
                invoice_prefix: req.body.invoicePrefix || req.body.invoice_prefix || 'INV'
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
                tax_percentage: parseFloat(taxVal) || 0,
                gst_percentage: parseFloat(gstVal) || 0,
                currency: 'INR',
                invoice_prefix: req.body.invoicePrefix || req.body.invoice_prefix || 'INV',
                starting_invoice_number: 1,
                invoice_format: 'thermal',
                footer_note: '',
                category_compulsory: true,
                variants_enabled: true
            }, { transaction: t });

            // 5. Create default UOMs
            await UOM.bulkCreate([
                { business_id: business.id, name: 'Kilograms', shortCode: 'kg' },
                { business_id: business.id, name: 'Litres', shortCode: 'ltr' },
                { business_id: business.id, name: 'Pieces', shortCode: 'pcs' }
            ], { transaction: t });

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
            const { name, phone, gstin, address, status, photo, tax, gst_percentage, invoice_prefix } = req.body;

            const business = await Business.findByPk(id);
            if (!business) {
                return res.status(404).json({ message: "Business not found" });
            }

            const phoneInput = phone !== undefined ? phone : (req.body.business_phone !== undefined ? req.body.business_phone : (req.body.businessPhone !== undefined ? req.body.businessPhone : req.body.phone_number));
            const nameInput = name !== undefined ? name : (req.body.business_name !== undefined ? req.body.business_name : req.body.businessName);
            const gstinInput = gstin !== undefined ? gstin : (req.body.gst_number !== undefined ? req.body.gst_number : req.body.gstNumber);
            const addressInput = address !== undefined ? address : (req.body.business_address !== undefined ? req.body.business_address : req.body.businessAddress);
            const photoInput = photo !== undefined ? photo : (req.body.business_logo !== undefined ? req.body.business_logo : req.body.businessLogo);
            const taxInput = tax !== undefined ? tax : req.body.taxPercentage;
            const gstInput = gst_percentage !== undefined ? gst_percentage : req.body.gstPercentage;

            await business.update({
                name: nameInput !== undefined ? nameInput : business.name,
                phone: phoneInput !== undefined ? phoneInput : business.phone,
                gstin: gstinInput !== undefined ? gstinInput : business.gstin,
                address: addressInput !== undefined ? addressInput : business.address,
                business_logo: photoInput !== undefined ? photoInput : business.business_logo,
                tax: taxInput !== undefined ? String(taxInput) : business.tax,
                gst_percentage: gstInput !== undefined ? parseFloat(gstInput) : business.gst_percentage,
                invoice_prefix: invoice_prefix !== undefined ? invoice_prefix : (req.body.invoicePrefix || business.invoice_prefix),
                status: status !== undefined ? status : business.status
            });

            // Also update settings table if it exists
            const Settings = require("../settings/settings.model");
            const settings = await Settings.findOne({ where: { business_id: id } });
            if (settings) {
                await settings.update({
                    business_name: nameInput || settings.business_name,
                    business_phone: phoneInput || settings.business_phone,
                    gst_number: gstinInput || settings.gst_number,
                    business_address: addressInput || settings.business_address,
                    business_logo: photoInput || settings.business_logo,
                    tax_percentage: taxInput !== undefined ? parseFloat(taxInput) : settings.tax_percentage,
                    gst_percentage: gstInput !== undefined ? parseFloat(gstInput) : settings.gst_percentage,
                    invoice_prefix: invoice_prefix || req.body.invoicePrefix || settings.invoice_prefix
                });
            }

            return res.status(200).json({
                message: "Business updated successfully",
                business: {
                    ...business.get({ plain: true }),
                    phone: business.phone || (settings ? settings.business_phone : ''),
                    business_phone: business.phone || (settings ? settings.business_phone : ''),
                    name: business.name || (settings ? settings.business_name : ''),
                    address: business.address || (settings ? settings.business_address : ''),
                    gstin: business.gstin || (settings ? settings.gst_number : ''),
                    business_logo: business.business_logo || (settings ? settings.business_logo : '')
                }
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
