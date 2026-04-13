const sequelize = require("../config/db");

async function migrate() {
    console.log("Starting migration...");
    const t = await sequelize.transaction();
    try {
        const queryInterface = sequelize.getQueryInterface();

        // 1. Rename 'stock' to 'opening_stock' if it exists in 'products'
        const productsTable = await queryInterface.describeTable('products');
        if (productsTable.stock && !productsTable.opening_stock) {
            console.log("Renaming products.stock to products.opening_stock");
            await queryInterface.renameColumn('products', 'stock', 'opening_stock', { transaction: t });
        }

        // 2. Add 'current_stock' to 'products' if it doesn't exist
        const productsTableAfter = await queryInterface.describeTable('products');
        if (!productsTableAfter.current_stock) {
            console.log("Adding products.current_stock");
            await queryInterface.addColumn('products', 'current_stock', {
                type: require('sequelize').DataTypes.DECIMAL(12, 3),
                defaultValue: 0
            }, { transaction: t });
            
            // Initialize current_stock from opening_stock
            await sequelize.query("UPDATE products SET current_stock = opening_stock", { transaction: t });
        }

        // 3. Rename 'stock' to 'opening_stock' if it exists in 'variants'
        const variantsTable = await queryInterface.describeTable('variants');
        if (variantsTable.stock && !variantsTable.opening_stock) {
            console.log("Renaming variants.stock to variants.opening_stock");
            await queryInterface.renameColumn('variants', 'stock', 'opening_stock', { transaction: t });
        }

        // 4. Add 'current_stock' to 'variants' if it doesn't exist
        const variantsTableAfter = await queryInterface.describeTable('variants');
        if (!variantsTableAfter.current_stock) {
            console.log("Adding variants.current_stock");
            await queryInterface.addColumn('variants', 'current_stock', {
                type: require('sequelize').DataTypes.DECIMAL(12, 3),
                defaultValue: 0
            }, { transaction: t });
            
            // Initialize current_stock from opening_stock
            await sequelize.query("UPDATE variants SET current_stock = opening_stock", { transaction: t });
        }

        // 5. Rename 'stock' to 'current_stock' in 'inventory'
        const inventoryTable = await queryInterface.describeTable('inventory');
        if (inventoryTable.stock && !inventoryTable.current_stock) {
            console.log("Renaming inventory.stock to inventory.current_stock");
            await queryInterface.renameColumn('inventory', 'stock', 'current_stock', { transaction: t });
        }

        await t.commit();
        console.log("Migration completed successfully!");
    } catch (error) {
        await t.rollback();
        console.error("Migration failed:", error);
    } finally {
        process.exit();
    }
}

migrate();
