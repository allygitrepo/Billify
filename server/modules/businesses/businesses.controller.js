const Business = require("./businesses.model");
const UserBusiness = require("../users/user_businesses.model");
const Role = require("../roles/roles.model");

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
    }
};

module.exports = businessController;
