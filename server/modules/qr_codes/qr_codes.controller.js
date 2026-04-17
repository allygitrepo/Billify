const QrCode = require("./qr_codes.model");
const QRCode = require("qrcode");

const qrCodesController = {
    // ============ Generate Business Profile QR ============
    generateBusinessQR: async (businessId, businessData) => {
        try {
            // We can encode a specific registration data or a link
            // For now, let's encode the business information as a JSON or a dummy URL
            const rawData = JSON.stringify({
                id: businessId,
                name: businessData.name || businessData.businessName,
                phone: businessData.phone || businessData.businessPhone,
                type: 'business_profile'
            });

            // Generate Base64 QR Image
            const qrImageBase64 = await QRCode.toDataURL(rawData, {
                errorCorrectionLevel: 'H',
                margin: 2,
                color: {
                    dark: '#0d9488', // Matching primary teal-600
                    light: '#ffffff'
                }
            });

            // Save to database
            const [qrRecord, created] = await QrCode.findOrCreate({
                where: { business_id: businessId, qr_type: 'business_profile' },
                defaults: {
                    business_id: businessId,
                    qr_type: 'business_profile',
                    reference_id: businessId,
                    raw_data: rawData,
                    qr_image: qrImageBase64,
                    status: true
                }
            });

            if (!created) {
                await qrRecord.update({ raw_data: rawData, qr_image: qrImageBase64 });
            }

            return qrRecord;
        } catch (error) {
            console.error("QR Generation Error:", error);
            throw error;
        }
    },

    generateTableQR: async (businessId, tableId, tableNumber, capacity = 0) => {
        try {
            // Data for Table QR (e.g., for ordering)
            const qrData = JSON.stringify({
                type: 'table_order',
                business_id: businessId,
                table_id: tableId,
                table_number: tableNumber,
                capacity: capacity
            });

            // Generate QR Image (with different color for distinction if desired)
            const qrImage = await QRCode.toDataURL(qrData, {
                color: {
                    dark: '#0f172a', // Slate 900 for tables
                    light: '#ffffff'
                },
                width: 1000,
                margin: 2
            });

            // Save or Update in database
            const [qrRecord, created] = await QrCode.findOrCreate({
                where: { 
                    business_id: businessId, 
                    qr_type: 'table',
                    reference_id: tableId 
                },
                defaults: {
                    raw_data: qrData,
                    qr_image: qrImage,
                    status: true
                }
            });

            if (!created) {
                qrRecord.qr_image = qrImage;
                qrRecord.raw_data = qrData;
                await qrRecord.save();
            }

            return qrRecord;
        } catch (error) {
            console.error("Error generating Table QR:", error);
            throw error;
        }
    },

    // ============ Get QR by Business ID ============
    getQrByBusinessId: async (req, res) => {
        try {
            const { business_id } = req.params;
            const { type = 'business_profile' } = req.query;

            let qrCode = await QrCode.findOne({
                where: { business_id, qr_type: type, status: true }
            });

            // If QR doesn't exist (legacy businesses), generate it on the fly
            if (!qrCode && type === 'business_profile') {
                const Business = require("../businesses/businesses.model");
                const business = await Business.findByPk(business_id);
                if (business) {
                    qrCode = await qrCodesController.generateBusinessQR(business_id, {
                        name: business.name,
                        phone: business.phone
                    });
                }
            }

            if (!qrCode) {
                return res.status(404).json({ message: "QR Code not found for this business" });
            }

            return res.status(200).json({ qrCode });
        } catch (error) {
            console.error("Fetch QR Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = qrCodesController;
