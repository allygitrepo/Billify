const request = require("supertest");
const express = require("express");
const sequelize = require("../config/db");
const RolePermission = require("../modules/role_permission/role_permission.model");
const rolePermissionRoutes = require("../modules/role_permission/role_permission.routes");
const { checkPermission } = require("../middleware/permission.middleware");

const app = express();
app.use(express.json());
app.use("/role-permissions", rolePermissionRoutes);

describe("Role-Based Permissions API", () => {
    beforeAll(async () => {
        await sequelize.sync({ alter: true });
    });

    beforeEach(async () => {
        // Clear the table before each test
        await RolePermission.destroy({ where: {}, force: true });
    });

    afterAll(async () => {
        await sequelize.close();
    });

    test("POST /role-permissions - should save/update permissions with soft delete of old ones", async () => {
        const payload = {
            role_id: 1,
            permissions: [
                {
                    module_name: "products",
                    can_add: true,
                    can_view: true,
                    can_update: true,
                    can_delete: true,
                    can_export: true,
                    can_bulk_upload: false,
                    can_download: true,
                    can_print: false
                }
            ]
        };

        const response = await request(app)
            .post("/role-permissions")
            .send(payload);

        expect(response.statusCode).toBe(200);
        expect(response.body.message).toBe("Permissions updated successfully");

        const perms = await RolePermission.findAll({ where: { role_id: 1, status: true } });
        expect(perms.length).toBe(1);
        expect(perms[0].module_name).toBe("products");
        expect(perms[0].can_add).toBe(true);
        expect(perms[0].can_bulk_upload).toBe(false);
    });

    test("GET /role-permissions/:role_id - should return structured response", async () => {
        // First seed some data
        await RolePermission.create({
            role_id: 1,
            module_name: "reports",
            can_view: true,
            status: true
        });

        const response = await request(app).get("/role-permissions/1");

        expect(response.statusCode).toBe(200);
        expect(response.body.reports).toBeDefined();
        expect(response.body.reports.can_view).toBe(true);
    });

    test("checkPermission function - should return true for active valid permissions", async () => {
        await RolePermission.create({
            role_id: 1,
            module_name: "dashboard",
            can_view: true,
            status: true
        });

        const hasAccess = await checkPermission(1, "dashboard", "can_view");
        expect(hasAccess).toBe(true);

        const noAccess = await checkPermission(1, "dashboard", "can_delete");
        expect(noAccess).toBe(false);
    });

    test("Soft delete behavior - modules NOT in the update should stay inactive", async () => {
        // Initial insert
        await RolePermission.create({
            role_id: 1,
            module_name: "old_module",
            can_add: true,
            status: true
        });

        // Update via API with a NEW module
        const payload = {
            role_id: 1,
            permissions: [
                {
                    module_name: "new_module",
                    can_add: true,
                    can_view: true
                }
            ]
        };

        await request(app).post("/role-permissions").send(payload);

        // Check database
        const allPerms = await RolePermission.findAll({ where: { role_id: 1 } });
        const activePerms = allPerms.filter(p => p.status === true);
        const inactivePerms = allPerms.filter(p => p.status === false);

        expect(activePerms.length).toBe(1);
        expect(activePerms[0].module_name).toBe("new_module");
        expect(inactivePerms.length).toBe(1);
        expect(inactivePerms[0].module_name).toBe("old_module");
    });
});
