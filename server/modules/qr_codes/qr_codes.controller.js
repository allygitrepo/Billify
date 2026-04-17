const QrCode = require("./qr_codes.model");
const Business = require("../businesses/businesses.model");
const QRCode = require("qrcode");

const qrCodesController = {
    // ============ Get All QR Codes for a Business ============
    getByBusiness: async (req, res) => {
        try {
            const business_id = 
                (req.params && (req.params.business_id || req.params.id)) || 
                (req.headers && req.headers['x-business-id']) ||
                (req.user && req.user.business_id);
            
            if (!business_id) {
                return res.status(400).json({ message: "Business ID is required" });
            }
            
            let qrCodes = await QrCode.findAll({
                where: { business_id, status: true },
                order: [['createdAt', 'DESC']]
            });

            // If no Profile QR exists, generate it (for older businesses)
            const profileQr = qrCodes.find(q => q.qr_type === 'Profile');
            if (!profileQr) {
                console.log(`Generating Profile QR for Business ID: ${business_id}`);
                const qrProfileData = JSON.stringify({
                    id: business_id,
                    type: 'business_profile'
                });

                const qrBase64 = await QRCode.toDataURL(qrProfileData);
                const newQr = await QrCode.create({
                    business_id,
                    qr_type: 'Profile',
                    qr_data: qrBase64,
                    status: true
                });
                qrCodes.unshift(newQr);
            }

            return res.status(200).json({ qrCodes });
        } catch (error) {
            console.error("Get QR Codes By Business Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Get Specific QR Code ============
    getById: async (req, res) => {
        try {
            const { id } = req.params;
            const qrCode = await QrCode.findByPk(id);

            if (!qrCode) {
                return res.status(404).json({ message: "QR Code not found" });
            }

            return res.status(200).json({ qrCode });
        } catch (error) {
            console.error("Get QR Code Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Delete (Soft Delete) ============
    delete: async (req, res) => {
        try {
            const { id } = req.params;
            const qrCode = await QrCode.findByPk(id);

            if (!qrCode) {
                return res.status(404).json({ message: "QR Code not found" });
            }

            await qrCode.update({ status: false });
            return res.status(200).json({ message: "QR Code removed successfully" });
        } catch (error) {
            console.error("Delete QR Code Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = qrCodesController;
