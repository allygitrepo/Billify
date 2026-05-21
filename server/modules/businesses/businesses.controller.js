const Business = require("./businesses.model");
const UserBusiness = require("../users/user_businesses.model");
const Role = require("../roles/roles.model");
const Settings = require("../settings/settings.model");
const UOM = require("../uoms/uoms.model");
const sequelize = require("../../config/db");
const whatsappService = require("../../services/whatsapp.service");

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
                        business_logo: s.business_logo || b.business_logo,
                        tax: s.tax_percentage || b.tax,
                        gst_percentage: s.gst_percentage || b.gst_percentage,
                        invoice_prefix: s.invoice_prefix || b.invoice_prefix,
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

            if (!businessName) {
                return res.status(400).json({ message: "Business Name is required" });
            }

            // 1. Create Business
            const business = await Business.create({
                owner_user_id: userId,
                name: businessName,
                phone: phone || '',
                gstin: gstin || '',
                address: address || '',
                business_logo: photo || '',
                tax: String(req.body.taxPercentage || 0),
                gst_percentage: req.body.gstPercentage || 0,
                invoice_prefix: req.body.invoicePrefix || 'INV'
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

            await business.update({
                name: name !== undefined ? name : business.name,
                phone: phone !== undefined ? phone : business.phone,
                gstin: gstin !== undefined ? gstin : business.gstin,
                address: address !== undefined ? address : business.address,
                business_logo: photo !== undefined ? photo : business.business_logo,
                tax: tax !== undefined ? String(tax) : business.tax,
                gst_percentage: gst_percentage !== undefined ? gst_percentage : business.gst_percentage,
                invoice_prefix: invoice_prefix !== undefined ? invoice_prefix : business.invoice_prefix,
                status: status !== undefined ? status : business.status
            });

            // Also update settings table if it exists
            const Settings = require("../settings/settings.model");
            const settings = await Settings.findOne({ where: { business_id: id } });
            if (settings) {
                await settings.update({
                    business_name: name || settings.business_name,
                    business_phone: phone || settings.business_phone,
                    gst_number: gstin || settings.gst_number,
                    business_address: address || settings.business_address,
                    business_logo: photo || settings.business_logo,
                    tax_percentage: tax !== undefined ? tax : settings.tax_percentage,
                    gst_percentage: gst_percentage !== undefined ? gst_percentage : settings.gst_percentage,
                    invoice_prefix: invoice_prefix || settings.invoice_prefix
                });
            }

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
    },

    // ============ Initiate WhatsApp ============
    initiateWhatsApp: async (req, res) => {
        try {
            const { id } = req.params;
            const business = await Business.findByPk(id);
            if (!business) {
                return res.status(404).json({ message: "Business not found" });
            }

            // Check if requester belongs to business
            const userBusiness = await UserBusiness.findOne({
                where: { user_id: req.user.id, business_id: id, status: true }
            });
            if (!userBusiness) {
                return res.status(403).json({ message: "Unauthorized access to this business" });
            }

            // Call service
            const result = await whatsappService.initiateInstance(business.name, business.whatsapp_instance_key);
            
            if (result && result.success) {
                // Update instanceKey in db if it changed
                if (result.instanceKey && result.instanceKey !== business.whatsapp_instance_key) {
                    await business.update({ whatsapp_instance_key: result.instanceKey });
                }
                return res.status(200).json(result);
            } else {
                return res.status(400).json({ success: false, message: "Initiation failed", details: result });
            }
        } catch (error) {
            console.error("Initiate WhatsApp Error:", error);
            return res.status(500).json({ message: "Internal server error", error: error.message });
        }
    },

    // ============ Get WhatsApp Status ============
    getWhatsAppStatus: async (req, res) => {
        try {
            const { id } = req.params;
            const business = await Business.findByPk(id);
            if (!business) {
                return res.status(404).json({ message: "Business not found" });
            }

            // Check if requester belongs to business
            const userBusiness = await UserBusiness.findOne({
                where: { user_id: req.user.id, business_id: id, status: true }
            });
            if (!userBusiness) {
                return res.status(403).json({ message: "Unauthorized access to this business" });
            }

            if (!business.whatsapp_instance_key) {
                return res.status(200).json({ success: true, status: 'disconnected', message: 'No instance key found' });
            }

            // Call service
            const result = await whatsappService.getInstanceStatus(business.whatsapp_instance_key);
            
            let status = 'disconnected';
            if (result && result.success) {
                if (result.connected) {
                    status = 'connected';
                } else if (result.qr) {
                    status = 'qr_ready';
                }
            }

            return res.status(200).json({
                success: result && result.success,
                status: status,
                qr: result ? result.qr : null,
                phone: result ? result.phone : null,
                name: result ? result.name : null,
                profileImage: result ? result.profileImage : null
            });
        } catch (error) {
            console.error("Get WhatsApp Status Error:", error);
            return res.status(500).json({ message: "Internal server error", error: error.message });
        }
    },

    // ============ Delete WhatsApp Instance ============
    deleteWhatsApp: async (req, res) => {
        try {
            const { id } = req.params;
            const business = await Business.findByPk(id);
            if (!business) {
                return res.status(404).json({ message: "Business not found" });
            }

            // Check if requester belongs to business
            const userBusiness = await UserBusiness.findOne({
                where: { user_id: req.user.id, business_id: id, status: true }
            });
            if (!userBusiness) {
                return res.status(403).json({ message: "Unauthorized access to this business" });
            }

            if (!business.whatsapp_instance_key) {
                return res.status(200).json({ success: true, message: 'Instance already deleted/not linked' });
            }

            // Call service
            const result = await whatsappService.deleteInstance(business.whatsapp_instance_key);
            
            // Clear from db
            await business.update({ whatsapp_instance_key: null });
            
            return res.status(200).json(result);
        } catch (error) {
            console.error("Delete WhatsApp Error:", error);
            return res.status(500).json({ message: "Internal server error", error: error.message });
        }
    },

    // ============ Send WhatsApp Media ============
    sendWhatsAppMedia: async (req, res) => {
        try {
            const { id } = req.params;
            const { number, pdfBase64, fileName, message } = req.body;

            if (!number || !pdfBase64) {
                return res.status(400).json({ success: false, message: "number and pdfBase64 are required fields" });
            }

            const business = await Business.findByPk(id);
            if (!business) {
                return res.status(404).json({ message: "Business not found" });
            }

            // Check if requester belongs to business
            const userBusiness = await UserBusiness.findOne({
                where: { user_id: req.user.id, business_id: id, status: true }
            });
            if (!userBusiness) {
                return res.status(403).json({ message: "Unauthorized access to this business" });
            }

            if (!business.whatsapp_instance_key) {
                return res.status(400).json({ success: false, message: "No WhatsApp account is linked to this business." });
            }

            // Convert base64 back to Buffer
            const buffer = Buffer.from(pdfBase64, 'base64');
            const targetFilename = fileName || `invoice_${Date.now()}.pdf`;

            // Call service
            const result = await whatsappService.sendMediaMessage(
                business.whatsapp_instance_key,
                number,
                buffer,
                message || "",
                targetFilename
            );

            return res.status(200).json(result);
        } catch (error) {
            console.error("Send WhatsApp Media Error:", error);
            return res.status(500).json({ success: false, message: "Internal server error", error: error.message });
        }
    },

    // ============ Send WhatsApp Bulk ============
    sendWhatsAppBulk: async (req, res) => {
        try {
            const { id } = req.params;
            const { messages } = req.body;

            if (!Array.isArray(messages) || messages.length === 0) {
                return res.status(400).json({ success: false, message: "messages array is required and cannot be empty" });
            }

            const business = await Business.findByPk(id);
            if (!business) {
                return res.status(404).json({ message: "Business not found" });
            }

            // Check if requester belongs to business
            const userBusiness = await UserBusiness.findOne({
                where: { user_id: req.user.id, business_id: id, status: true }
            });
            if (!userBusiness) {
                return res.status(403).json({ message: "Unauthorized access to this business" });
            }

            if (!business.whatsapp_instance_key) {
                return res.status(400).json({ success: false, message: "No WhatsApp account is linked to this business." });
            }

            // Validate and sanitize each message
            const sanitizedMessages = messages.map(msg => {
                let num = msg.number.replace(/\D/g, '');
                if (num.length === 10) {
                    num = '91' + num;
                }
                return {
                    number: num,
                    message: msg.message
                };
            });

            // Call service
            const result = await whatsappService.sendBulkMessages(
                business.whatsapp_instance_key,
                sanitizedMessages
            );

            return res.status(200).json(result);
        } catch (error) {
            console.error("Send WhatsApp Bulk Error:", error);
            return res.status(500).json({ success: false, message: "Internal server error", error: error.message });
        }
    }
};

module.exports = businessController;
