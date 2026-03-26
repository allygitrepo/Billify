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
            } else if (business && (!settings.business_name || !settings.business_phone)) {
                // Backfill if settings exist but major fields are missing
                await settings.update({
                    business_name: settings.business_name || business.name,
                    business_phone: settings.business_phone || business.phone,
                    business_address: settings.business_address || business.address,
                    gst_number: settings.gst_number || business.gstin
                });
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
