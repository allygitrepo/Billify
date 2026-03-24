const User = require("./users.model");
const UserBusiness = require("./user_businesses.model");
const Business = require("../businesses/businesses.model");
const Role = require("../roles/roles.model");
const bcrypt = require("bcryptjs");
const sequelize = require("../../config/db");

const usersController = {
    // ============ Get All Users for a Business ============
    getUsersByBusiness: async (req, res) => {
        try {
            const { business_id } = req.params;
            
            const userBusinesses = await UserBusiness.findAll({
                where: { business_id, status: true },
                include: [
                    { 
                        model: User, 
                        as: 'user',
                        attributes: { exclude: ['password'] } 
                    },
                    { model: Role, as: 'role' }
                ]
            });

            const users = userBusinesses.map(ub => {
                const userObj = ub.user.get({ plain: true });
                return {
                    ...userObj,
                    status: userObj.status ? 'active' : 'inactive',
                    role: ub.role ? ub.role.name : 'User',
                    role_id: ub.role_id,
                    business_status: ub.status ? 'active' : 'inactive'
                };
            });

            return res.status(200).json({ users });
        } catch (error) {
            console.error("Get Users By Business Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Create User and Assign to Business ============
    createUser: async (req, res) => {
        const t = await sequelize.transaction();
        try {
            const { name, email, password, role_id, business_id, mobile } = req.body;

            if (!name || !email || !password || !role_id || !business_id) {
                return res.status(400).json({ message: "Missing required fields" });
            }

            // 1. Check if user already exists
            let user = await User.findOne({ where: { email } });
            
            if (!user) {
                // Create new user
                const hashedPassword = await bcrypt.hash(password, 10);
                user = await User.create({
                    name,
                    email,
                    password: hashedPassword,
                    role_id: role_id // Default role
                }, { transaction: t });
            }

            // 2. Check if already assigned to this business
            const existingMapping = await UserBusiness.findOne({
                where: { user_id: user.id, business_id }
            });

            if (existingMapping) {
                await t.rollback();
                return res.status(400).json({ message: "User is already assigned to this business" });
            }

            // 3. Create mapping
            await UserBusiness.create({
                user_id: user.id,
                business_id,
                role_id,
                status: true
            }, { transaction: t });

            await t.commit();
            return res.status(201).json({ 
                message: "User created and assigned successfully",
                user: { id: user.id, name: user.name, email: user.email }
            });

        } catch (error) {
            await t.rollback();
            console.error("Create User Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Update User (in current business context) ============
    updateUser: async (req, res) => {
        const t = await sequelize.transaction();
        try {
            const { id } = req.params; // User ID
            const { name, email, role_id, business_id, status } = req.body;

            const user = await User.findByPk(id);
            if (!user) {
                await t.rollback();
                return res.status(404).json({ message: "User not found" });
            }

            // Update user info
            await user.update({ 
                name: name || user.name,
                email: email || user.email
            }, { transaction: t });

            // Update business mapping
            if (business_id && role_id) {
                const mapping = await UserBusiness.findOne({
                    where: { user_id: id, business_id }
                });
                if (mapping) {
                    await mapping.update({ 
                        role_id, 
                        status: status !== undefined ? status : mapping.status 
                    }, { transaction: t });
                }
            }

            await t.commit();
            return res.status(200).json({ message: "User updated successfully" });
        } catch (error) {
            await t.rollback();
            console.error("Update User Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Delete User from Business ============
    deleteUser: async (req, res) => {
        try {
            const { id } = req.params; // User ID
            const { business_id } = req.query;

            if (!business_id) {
                return res.status(400).json({ message: "Business ID is required" });
            }

            const mapping = await UserBusiness.findOne({
                where: { user_id: id, business_id }
            });

            if (!mapping) {
                return res.status(404).json({ message: "User assignment not found" });
            }

            // Soft delete assignment
            await mapping.update({ status: false });

            return res.status(200).json({ message: "User removed from business" });
        } catch (error) {
            console.error("Delete User Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = usersController;
