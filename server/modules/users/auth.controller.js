const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("./users.model");
const Business = require("../businesses/businesses.model");
const UserBusiness = require("./user_businesses.model");
const RolePermission = require("../role_permission/role_permission.model");
const Role = require("../roles/roles.model");
const UOM = require("../uoms/uoms.model");
const Settings = require("../settings/settings.model");
const sequelize = require("../../config/db");
require("dotenv").config();

const MODULES = [
    "Reports",
    "Dashboard",
    "Analytics & Reports",
    "Products Master",
    "Categories Master",
    "User Management",
    "Billing / POS",
    "Transaction Logs",
    "Inventory Management",
    "Units of Measurement",
    "System Settings"
];

const authController = {
    // ============ User Registration ============
    register: async (req, res) => {
        const t = await sequelize.transaction();
        try {
            const { 
                name, email, password, business_name, phone, gstin, address,
                userPhoto, userMobile, businessPhoto,
                taxPercentage, gstPercentage, currency, 
                invoicePrefix, startingNumber, invoiceFormat, footerNote
            } = req.body;

            console.log("Registration Request:", { 
                name, 
                email, 
                business_name,
                userPhotoSize: userPhoto ? userPhoto.length : 0,
                businessPhotoSize: businessPhoto ? businessPhoto.length : 0
            });

            if (!name || !email || !password || !business_name) {
                console.log("Registration Failed: Missing fields");
                return res.status(400).json({ message: "Name, Email, Password, and Business Name are required" });
            }

            // 1. Check if user exists
            const existingUser = await User.findOne({ where: { email } });
            if (existingUser) {
                console.log("Registration Failed: Email exists", email);
                return res.status(400).json({ message: "Email already registered" });
            }

            // 2. Hash password
            const hashedPassword = await bcrypt.hash(password, 10);

            // 3. Ensure "Global Admin" Role exists (business_id is NULL for system roles)
            const [adminRole] = await Role.findOrCreate({
                where: { name: 'Admin', business_id: null },
                defaults: { 
                    description: 'System Administrator with full access',
                    business_id: null 
                },
                transaction: t
            });
            console.log("Global Admin role ID resolved:", adminRole.id);

            // 4. Create User assigned to Global Admin role
            const user = await User.create({
                name,
                email,
                mobile: userMobile,
                password: hashedPassword,
                role_id: adminRole.id,
                photo: userPhoto
            }, { transaction: t });
            console.log("User created:", user.id);

            // 5. Create Business
            const business = await Business.create({
                owner_user_id: user.id,
                name: business_name,
                phone,
                gstin,
                address
            }, { transaction: t });
            console.log("Business created:", business.id);

            // 6. Create Settings for the business
            await Settings.create({
                business_id: business.id,
                business_name: business_name,
                business_phone: phone,
                business_address: address,
                gst_number: gstin,
                business_logo: businessPhoto,
                tax_percentage: taxPercentage || 0,
                gst_percentage: gstPercentage || 0,
                currency: currency || 'INR',
                invoice_prefix: invoicePrefix || 'INV',
                starting_invoice_number: startingNumber || 1,
                invoice_format: invoiceFormat || 'thermal',
                footer_note: footerNote || '',
                category_compulsory: true,
                variants_enabled: true
            }, { transaction: t });
            console.log("Settings created for business:", business.id);

            // 7. Create default UOMs
            await UOM.bulkCreate([
                { business_id: business.id, name: 'Kilograms', shortCode: 'kg' },
                { business_id: business.id, name: 'Litres', shortCode: 'ltr' },
                { business_id: business.id, name: 'Pieces', shortCode: 'pcs' }
            ], { transaction: t });
            console.log("Default UOMs created for business:", business.id);

            // 8. Map User to Business as Admin
            await UserBusiness.create({
                user_id: user.id,
                business_id: business.id,
                role_id: adminRole.id,
                status: true
            }, { transaction: t });

            // 9. Initial Setup: Ensure Global Admin has all permissions (Only runs once in system lifetime)
            const existingPermissions = await RolePermission.count({ where: { role_id: adminRole.id } });
            if (existingPermissions === 0) {
                console.log("Initializing Global Admin permissions...");
                const adminPerms = MODULES.map(module_name => ({
                    role_id: adminRole.id,
                    module_name,
                    can_add: true,
                    can_view: true,
                    can_update: true,
                    can_delete: true,
                    can_export: true,
                    can_bulk_upload: true,
                    can_download: true,
                    can_print: true,
                    status: true
                }));
                await RolePermission.bulkCreate(adminPerms, { transaction: t });
            }

            await t.commit();
            console.log("Registration Successful for:", email);

            return res.status(201).json({
                message: "User and Business registered successfully",
                user: { id: user.id, name: user.name, email: user.email },
                business: { id: business.id, name: business.name }
            });

        } catch (error) {
            await t.rollback();
            console.error("Registration Error:", error);
            return res.status(500).json({ message: "Internal server error", error: error.message });
        }
    },

    // ============ User Login ============
    login: async (req, res) => {
        try {
            const { email, password } = req.body;
            console.log("Login Request received for:", email);

            if (!email || !password) {
                console.log("Login Error: Missing credentials");
                return res.status(400).json({ message: "Email and Password are required" });
            }

            // 1. Find user
            const user = await User.findOne({ where: { email, status: true } });
            if (!user) {
                console.log("Login Error: User not found:", email);
                return res.status(401).json({ message: "Invalid credentials" });
            }

            // 2. Check password
            const isMatch = await bcrypt.compare(password, user.password);
            if (!isMatch) {
                console.log("Login Error: Password mismatch for:", email);
                return res.status(401).json({ message: "Invalid credentials" });
            }

            // 3. Fetch all active businesses for user with roles
            console.log("Fetching businesses for user ID:", user.id);
            const userBusinesses = await UserBusiness.findAll({
                where: { user_id: user.id, status: true },
                include: [
                    { 
                        model: Business, 
                        as: 'business', 
                        where: { status: true },
                        include: [{ model: Settings, as: 'settings' }]
                    },
                    { model: Role, as: 'role' }
                ]
            });
            console.log(`Found ${userBusinesses.length} businesses for user`);
            
            // 4. Generate token
            const token = jwt.sign(
                { id: user.id, email: user.email },
                process.env.JWT_SECRET,
                { expiresIn: "7d" }
            );

            const responseData = {
                message: "Login successful",
                token,
                user: { 
                    id: user.id, 
                    name: user.name, 
                    email: user.email,
                    mobile: user.mobile,
                    role_id: user.role_id,
                    photo: user.photo
                },
                businesses: userBusinesses.map(ub => {
                    const b = ub.business.get({ plain: true });
                    const s = b.settings || {};
                    return {
                        ...b,
                        // Override/Fallback from settings table
                        business_logo: s.business_logo || b.business_logo,
                        tax: s.tax_percentage || b.tax,
                        gst_percentage: s.gst_percentage || b.gst_percentage,
                        invoice_prefix: s.invoice_prefix || b.invoice_prefix,
                        role: ub.role ? ub.role.name : 'User',
                        role_id: ub.role_id
                    };
                })
            };

            console.log("Login successful, sending response context");
            return res.status(200).json(responseData);

        } catch (error) {
            console.error("Login Error Deep Detail:", error);
            return res.status(500).json({ message: "Internal server error", error: error.message });
        }
    }
};

module.exports = authController;
