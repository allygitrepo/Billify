const UserBusiness = require("./user_businesses.model");
const User = require("./users.model");
const Business = require("../businesses/businesses.model");
const Role = require("../roles/roles.model");

const userBusinessController = {
    // ============ Assign User to Business ============
    assignUser: async (req, res) => {
        try {
            const { user_id, business_id, role_id } = req.body;

            if (!user_id || !business_id || !role_id) {
                return res.status(400).json({ message: "User ID, Business ID, and Role ID are required" });
            }

            // Check if mapping already exists
            const existingMapping = await UserBusiness.findOne({
                where: { user_id, business_id }
            });

            if (existingMapping) {
                // Update existing mapping
                await existingMapping.update({ role_id, status: true });
                return res.status(200).json({ message: "User assignment updated successfully" });
            }

            // Create new mapping
            await UserBusiness.create({
                user_id,
                business_id,
                role_id,
                status: true
            });

            return res.status(201).json({ message: "User assigned to business successfully" });
        } catch (error) {
            console.error("Assign User Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = userBusinessController;
