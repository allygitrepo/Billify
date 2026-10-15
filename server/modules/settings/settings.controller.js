const Settings = require("./settings.model");

const settingsController = {
    // ============ Get Business Settings ============
    getSettings: async (req, res) => {
        try {
            const { business_id } = req.params;
            let settings = await Settings.findOne({ where: { business_id } });
            
            const Business = require("../businesses/businesses.model");
            const business = await Business.findByPk(business_id);

            // If no settings exist yet, create defaults from Business record
            if (!settings) {
                if (business) {
                    settings = await Settings.create({
                        business_id,
                        business_name: business.name,
                        business_phone: business.phone,
                        business_address: business.address,
                        gst_number: business.gstin,
                        tax_percentage: business.tax || 0,
                        gst_percentage: business.gst_percentage || 0,
                        invoice_prefix: business.invoice_prefix || 'INV',
                        invoice_format: business.invoice_format || 'thermal'
                    });
                } else {
                    settings = await Settings.create({ business_id });
                }
            } else if (business) {
                // Bidirectional sync: backfill settings from business if missing
                const settingsUpdates = {};
                if (!settings.business_name && business.name) settingsUpdates.business_name = business.name;
                if (!settings.business_phone && business.phone) settingsUpdates.business_phone = business.phone;
                if (!settings.business_address && business.address) settingsUpdates.business_address = business.address;
                if (!settings.gst_number && business.gstin) settingsUpdates.gst_number = business.gstin;
                if (Object.keys(settingsUpdates).length > 0) {
                    await settings.update(settingsUpdates);
                }

                // Also backfill business from settings if missing
                const businessUpdates = {};
                if (!business.phone && settings.business_phone) businessUpdates.phone = settings.business_phone;
                if (!business.name && settings.business_name) businessUpdates.name = settings.business_name;
                if (!business.address && settings.business_address) businessUpdates.address = settings.business_address;
                if (!business.gstin && settings.gst_number) businessUpdates.gstin = settings.gst_number;
                if (Object.keys(businessUpdates).length > 0) {
                    await business.update(businessUpdates);
                }
            }
            
            return res.status(200).json({ settings });
        } catch (error) {
            console.error("Get Settings Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Update Business Settings ============
    updateSettings: async (req, res) => {
        try {
            const { business_id } = req.params;
            const updates = req.body;

            let settings = await Settings.findOne({ where: { business_id } });
            
            if (settings) {
                await settings.update(updates);
            } else {
                settings = await Settings.create({ ...updates, business_id });
            }

            // Sync shared fields to Business table as well so both tables are always in sync
            const Business = require("../businesses/businesses.model");
            const businessUpdates = {};
            const phoneVal = updates.business_phone !== undefined ? updates.business_phone : (updates.phone !== undefined ? updates.phone : updates.businessPhone);
            if (phoneVal !== undefined) businessUpdates.phone = phoneVal;
            const nameVal = updates.business_name !== undefined ? updates.business_name : (updates.businessName !== undefined ? updates.businessName : updates.name);
            if (nameVal !== undefined) businessUpdates.name = nameVal;
            const gstinVal = updates.gst_number !== undefined ? updates.gst_number : (updates.gstin !== undefined ? updates.gstin : updates.gstNumber);
            if (gstinVal !== undefined) businessUpdates.gstin = gstinVal;
            const addressVal = updates.business_address !== undefined ? updates.business_address : (updates.address !== undefined ? updates.address : updates.businessAddress);
            if (addressVal !== undefined) businessUpdates.address = addressVal;
            const logoVal = updates.business_logo !== undefined ? updates.business_logo : (updates.photo !== undefined ? updates.photo : updates.logo);
            if (logoVal !== undefined) businessUpdates.business_logo = logoVal;
            const taxVal = updates.tax_percentage !== undefined ? updates.tax_percentage : updates.tax;
            if (taxVal !== undefined) businessUpdates.tax = String(taxVal);
            const gstVal = updates.gst_percentage !== undefined ? updates.gst_percentage : updates.gst;
            if (gstVal !== undefined) businessUpdates.gst_percentage = parseFloat(gstVal) || 0;
            const prefixVal = updates.invoice_prefix !== undefined ? updates.invoice_prefix : updates.invoicePrefix;
            if (prefixVal !== undefined) businessUpdates.invoice_prefix = prefixVal;

            if (Object.keys(businessUpdates).length > 0) {
                await Business.update(businessUpdates, { where: { id: business_id } });
            }

            return res.status(200).json({
                message: "Settings updated successfully",
                settings
            });
        } catch (error) {
            console.error("Update Settings Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = settingsController;
