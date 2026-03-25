const UOM = require("./uoms.model");

const uomsController = {
    // ============ Create UOM ============
    createUOM: async (req, res) => {
        try {
            const { business_id, name, shortCode } = req.body;

            if (!business_id || !name || !shortCode) {
                return res.status(400).json({ message: "Business ID, Name, and Short Code are required" });
            }

            // Check for collision
            const existingUOM = await UOM.findOne({
                where: { 
                    business_id, 
                    [require('sequelize').Op.or]: [{ name }, { shortCode }],
                    status: true 
                }
            });
            if (existingUOM) {
                return res.status(409).json({ message: `Unit with name or short code already exists` });
            }

            const uom = await UOM.create({
                business_id,
                name,
                shortCode
            });

            return res.status(201).json({
                message: "UOM created successfully",
                uom
            });
        } catch (error) {
            console.error("Create UOM Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Get UOMs by Business ID ============
    getUOMsByBusinessId: async (req, res) => {
        try {
            const { business_id } = req.params;
            const uoms = await UOM.findAll({ where: { business_id, status: true } });
            return res.status(200).json({ uoms });
        } catch (error) {
            console.error("Get UOMs Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Update UOM ============
    updateUOM: async (req, res) => {
        try {
            const { id } = req.params;
            const { name, shortCode, status } = req.body;

            const uom = await UOM.findByPk(id);
            if (!uom) {
                return res.status(404).json({ message: "UOM not found" });
            }

            await uom.update({
                name: name || uom.name,
                shortCode: shortCode || uom.shortCode,
                status: status !== undefined ? status : uom.status
            });

            return res.status(200).json({
                message: "UOM updated successfully",
                uom
            });
        } catch (error) {
            console.error("Update UOM Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Delete UOM (Soft Delete) ============
    deleteUOM: async (req, res) => {
        try {
            const { id } = req.params;
            const uom = await UOM.findByPk(id);
            if (!uom) {
                return res.status(404).json({ message: "UOM not found" });
            }

            await uom.update({ status: false });
            return res.status(200).json({ message: "UOM deleted successfully" });
        } catch (error) {
            console.error("Delete UOM Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = uomsController;
