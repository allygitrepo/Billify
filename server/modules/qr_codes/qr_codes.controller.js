const QrCode = require("./qr_codes.model");
const Business = require("../businesses/businesses.model");

const qrCodesController = {
    // ============ Get All QR Codes for a Business ============
    getByBusiness: async (req, res) => {
        try {
            const { business_id } = req.params;
            
            const qrCodes = await QrCode.findAll({
                where: { business_id, status: true },
                order: [['createdAt', 'DESC']]
            });

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
