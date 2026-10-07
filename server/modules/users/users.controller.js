const User = require("./users.model");
const UserBusiness = require("./user_businesses.model");
const Business = require("../businesses/businesses.model");
const Role = require("../roles/roles.model");
const bcrypt = require("bcryptjs");
const sequelize = require("../../config/db");
const { Op } = require("sequelize");

const usersController = {
    // ============ Get All Users for a Business ============
    getUsersByBusiness: async (req, res) => {
        try {
            const { business_id } = req.params;
            const numericBusinessId = parseInt(business_id);
            if (isNaN(numericBusinessId)) {
                return res.status(400).json({ message: "Invalid Business ID format" });
            }

            const userBusinesses = await UserBusiness.findAll({
                where: { business_id: numericBusinessId, status: true },
                include: [
                    {
                        model: User,
                        as: 'user',
                        attributes: { exclude: ['password'] }
                    },
                    { model: Role, as: 'role' }
                ]
            });

            const users = userBusinesses
                .filter(ub => ub && ub.user)
                .map(ub => {
                    const userObj = ub.user.get({ plain: true });
                    return {
                        ...userObj,
                        status: userObj.status === true || userObj.status === 'active' || userObj.status === 1,
                        role: ub.role ? ub.role.name : 'User',
                        role_id: ub.role_id,
                        roleId: ub.role_id,
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
            const { name, email, password, role_id, business_id, mobile, photo } = req.body;

            const numericBusinessId = parseInt(business_id);
            const numericRoleId = parseInt(role_id);

            if (!name || !mobile || !password || isNaN(numericRoleId) || isNaN(numericBusinessId)) {
                await t.rollback();
                return res.status(400).json({ message: "Name, mobile, password, role_id, and business_id are required" });
            }

            const cleanEmail = email && email.trim() !== "" ? email.trim() : null;
            const cleanMobile = mobile ? mobile.trim() : null;

            // 1. Check if user already exists
            const queryConditions = [];
            if (cleanMobile) queryConditions.push({ mobile: cleanMobile });
            if (cleanEmail) queryConditions.push({ email: cleanEmail });

            let user = await User.findOne({
                where: {
                    [Op.or]: queryConditions
                }
            });

            if (user) {
                // Check if this existing user is registered as a Business Owner
                const ownsBusiness = await Business.findOne({
                    where: { owner_user_id: user.id, status: true }
                });

                const isOwnerRole = user.role_id === null || user.role_id === 1;

                if (ownsBusiness || isOwnerRole) {
                    await t.rollback();
                    return res.status(400).json({
                        message: "This phone number is already registered as a business owner and cannot be added as a staff member."
                    });
                }
            }

            if (!user) {
                // Create new user
                const hashedPassword = await bcrypt.hash(password, 10);
                user = await User.create({
                    name,
                    email: cleanEmail,
                    mobile: cleanMobile,
                    photo,
                    password: hashedPassword,
                    role_id: numericRoleId
                }, { transaction: t });
            }

            // 2. Check if already assigned to this business
            const existingMapping = await UserBusiness.findOne({
                where: { user_id: user.id, business_id: numericBusinessId }
            });

            if (existingMapping) {
                if (existingMapping.status) {
                    await t.rollback();
                    return res.status(400).json({ message: "User is already assigned to this business" });
                } else {
                    // Reactivate soft-deleted mapping with new role
                    await existingMapping.update({
                        role_id: numericRoleId,
                        status: true
                    }, { transaction: t });
                }
            } else {
                // 3. Create mapping
                await UserBusiness.create({
                    user_id: user.id,
                    business_id: numericBusinessId,
                    role_id: numericRoleId,
                    status: true
                }, { transaction: t });
            }

            // Fetch role details for full response
            const assignedRole = await Role.findByPk(numericRoleId);

            await t.commit();
            return res.status(201).json({
                message: "User created and assigned successfully",
                user: {
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    mobile: user.mobile,
                    role_id: numericRoleId,
                    roleId: numericRoleId,
                    role: assignedRole ? assignedRole.name : 'Staff',
                    photo: user.photo,
                    status: true
                }
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
            const { name, email, mobile, role_id, business_id, status, photo } = req.body;

            const user = await User.findByPk(id);
            if (!user) {
                await t.rollback();
                return res.status(404).json({ message: "User not found" });
            }

            const numericBusinessId = parseInt(business_id);
            const numericRoleId = role_id !== undefined && role_id !== null ? parseInt(role_id) : null;

            // Update user info
            await user.update({
                name: name || user.name,
                email: email !== undefined ? (email && email.trim() !== "" ? email.trim() : null) : user.email,
                mobile: mobile !== undefined ? (mobile ? mobile.trim() : null) : user.mobile,
                photo: photo !== undefined ? photo : user.photo,
                role_id: numericRoleId !== null && !isNaN(numericRoleId) ? numericRoleId : user.role_id
            }, { transaction: t });

            // Update business mapping
            let assignedRoleName = 'Staff';
            if (!isNaN(numericBusinessId)) {
                const mapping = await UserBusiness.findOne({
                    where: { user_id: id, business_id: numericBusinessId }
                });
                if (mapping) {
                    let finalStatus = mapping.status;
                    if (status !== undefined) {
                        finalStatus = (status === 'active' || status === true || status === 1);
                    }

                    const updatePayload = { status: finalStatus };
                    if (numericRoleId !== null && !isNaN(numericRoleId)) {
                        updatePayload.role_id = numericRoleId;
                    }

                    await mapping.update(updatePayload, { transaction: t });

                    const r = await Role.findByPk(mapping.role_id);
                    if (r) assignedRoleName = r.name;
                }
            }

            await t.commit();
            return res.status(200).json({
                message: "User updated successfully",
                user: {
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    mobile: user.mobile,
                    photo: user.photo,
                    role_id: numericRoleId || user.role_id,
                    roleId: numericRoleId || user.role_id,
                    role: assignedRoleName,
                    status: status !== undefined ? (status === 'active' || status === true || status === 1) : user.status
                }
            });
        } catch (error) {
            await t.rollback();
            console.error("Update User Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Change Password ============
    changePassword: async (req, res) => {
        try {
            const { oldPassword, newPassword } = req.body;
            const userId = req.user.id; // From authenticate middleware

            if (!oldPassword || !newPassword) {
                return res.status(400).json({ message: "Old and new passwords are required" });
            }

            const user = await User.findByPk(userId);
            if (!user) {
                return res.status(404).json({ message: "User not found" });
            }

            // Verify old password
            const bcrypt = require("bcryptjs");
            const isMatch = await bcrypt.compare(oldPassword, user.password);
            if (!isMatch) {
                return res.status(400).json({ message: "Incorrect current password" });
            }

            // Hash and update new password
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash(newPassword, salt);

            await user.update({ password: hashedPassword });

            return res.status(200).json({ message: "Password updated successfully" });
        } catch (error) {
            console.error("Change Password Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Update Profile (Own Data) ============
    updateProfile: async (req, res) => {
        try {
            const userId = req.user.id;
            const { name, mobile, photo } = req.body;

            const user = await User.findByPk(userId);
            if (!user) {
                return res.status(404).json({ message: "User not found" });
            }

            // Update allowed fields only
            await user.update({
                name: name || user.name,
                mobile: mobile !== undefined ? mobile : user.mobile,
                photo: photo !== undefined ? photo : user.photo
            });

            return res.status(200).json({
                message: "Profile updated successfully",
                user: {
                    id: user.id,
                    name: user.name,
                    email: user.email,
                    mobile: user.mobile,
                    photo: user.photo
                }
            });
        } catch (error) {
            console.error("Update Profile Error:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // ============ Delete User from Business ============
    deleteUser: async (req, res) => {
        try {
            const { id } = req.params; // User ID
            const { business_id } = req.query;

            const numericBusinessId = parseInt(business_id);
            if (!business_id || isNaN(numericBusinessId)) {
                return res.status(400).json({ message: "Valid Business ID is required" });
            }

            const mapping = await UserBusiness.findOne({
                where: { user_id: id, business_id: numericBusinessId }
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
