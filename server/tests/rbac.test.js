const request = require("supertest");
const express = require("express");
const sequelize = require("../config/db");
const routes = require("../routes.index");
const User = require("../modules/users/users.model");
const Business = require("../modules/businesses/businesses.model");
const UserBusiness = require("../modules/users/user_businesses.model");
const Role = require("../modules/roles/roles.model");
const RolePermission = require("../modules/role_permission/role_permission.model");
const { checkPermission } = require("../middleware/permission.middleware");

const app = express();
app.use(express.json());
app.use("/api", routes);

describe("Multi-Tenant RBAC System", () => {
    beforeAll(async () => {
        await sequelize.sync({ alter: true });
        // Seed roles
        await Role.upsert({ id: 1, name: "Admin", status: true });
        await Role.upsert({ id: 2, name: "Manager", status: true });
    });

    beforeEach(async () => {
        // Clear tables in order of dependency
        await RolePermission.destroy({ where: {}, force: true });
        await UserBusiness.destroy({ where: {}, force: true });
        await Business.destroy({ where: {}, force: true });
        await User.destroy({ where: {}, force: true });
    });

    afterAll(async () => {
        await sequelize.close();
    });

    test("POST /api/auth/register - should create user, business, and assign Admin role", async () => {
        const payload = {
            name: "Test User",
            email: "test@example.com",
            password: "password123",
            business_name: "Test Business",
            phone: "1234567890"
        };

        const response = await request(app)
            .post("/api/auth/register")
            .send(payload);

        expect(response.statusCode).toBe(201);
        expect(response.body.message).toBe("User and Business registered successfully");

        const user = await User.findOne({ where: { email: "test@example.com" } });
        expect(user).toBeDefined();

        const business = await Business.findOne({ where: { owner_user_id: user.id } });
        expect(business).toBeDefined();

        const mapping = await UserBusiness.findOne({ where: { user_id: user.id, business_id: business.id } });
        expect(mapping.role_id).toBe(1);

        const perms = await RolePermission.findAll({ where: { role_id: 1 } });
        expect(perms.length).toBeGreaterThan(0);
        expect(perms[0].can_view).toBe(true);
    });

    test("POST /api/auth/login - should return token and business list", async () => {
        // First register
        await request(app).post("/api/auth/register").send({
            name: "Login User",
            email: "login@example.com",
            password: "password123",
            business_name: "Login Business"
        });

        const response = await request(app)
            .post("/api/auth/login")
            .send({ email: "login@example.com", password: "password123" });

        expect(response.statusCode).toBe(200);
        expect(response.body.token).toBeDefined();
        expect(response.body.businesses.length).toBe(1);
        expect(response.body.businesses[0].name).toBe("Login Business");
    });

    test("checkPermission helper - should correctly identify permissions across businesses", async () => {
        // 1. Setup Data
        const user = await User.create({ name: "Perm User", email: "perm@example.com", password: "p1" });
        const biz1 = await Business.create({ name: "Biz 1", owner_user_id: user.id });
        const biz2 = await Business.create({ name: "Biz 2", owner_user_id: user.id });

        // User is Admin in Biz 1
        await UserBusiness.create({ user_id: user.id, business_id: biz1.id, role_id: 1 });
        // User is Manager in Biz 2
        await UserBusiness.create({ user_id: user.id, business_id: biz2.id, role_id: 2 });

        // Admin has Dashboard-view (True)
        await RolePermission.create({ role_id: 1, module_name: "Dashboard", can_view: true, status: true });
        // Manager has NOT Dashboard-view (False)
        await RolePermission.create({ role_id: 2, module_name: "Dashboard", can_view: false, status: true });

        // 2. Check
        const hasAccessBiz1 = await checkPermission(user.id, biz1.id, "Dashboard", "can_view");
        expect(hasAccessBiz1).toBe(true);

        const hasAccessBiz2 = await checkPermission(user.id, biz2.id, "Dashboard", "can_view");
        expect(hasAccessBiz2).toBe(false);
    });

    test("Soft delete check - status=false records should be ignored", async () => {
        const user = await User.create({ name: "Soft User", email: "soft@example.com", password: "p1" });
        const biz = await Business.create({ name: "Soft Biz", owner_user_id: user.id });
        
        // Active mapping
        await UserBusiness.create({ user_id: user.id, business_id: biz.id, role_id: 1, status: true });
        
        const activeCheck = await checkPermission(user.id, biz.id, "Reports", "can_view");
        // Role Permission doesn't exist yet, so false. Let's create it.
        await RolePermission.create({ role_id: 1, module_name: "Reports", can_view: true, status: true });
        
        expect(await checkPermission(user.id, biz.id, "Reports", "can_view")).toBe(true);
        
        // Deactivate mapping
        await UserBusiness.update({ status: false }, { where: { user_id: user.id, business_id: biz.id } });
        
        expect(await checkPermission(user.id, biz.id, "Reports", "can_view")).toBe(false);
    });
});
