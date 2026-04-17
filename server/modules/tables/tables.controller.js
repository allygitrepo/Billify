const Table = require("./tables.model");
const qrController = require("../qr_codes/qr_codes.controller");
const QrCode = require("../qr_codes/qr_codes.model");

const tableController = {
    // Create tables in bulk
    createTable: async (req, res) => {
        try {
            const { count, capacity, business_id, prefix = "Table" } = req.body;

            if (!count || !business_id) {
                return res.status(400).json({ message: "Count and business ID are required" });
            }

            const createdTables = [];

            // Loop and create tables
            for (let i = 1; i <= count; i++) {
                const table_number = `${prefix} ${i}`;
                
                // 1. Create the table record
                const table = await Table.create({
                    table_number,
                    capacity: capacity || 0,
                    business_id
                });

                // 2. Generate the QR code for this specific table (storing capacity in the QR data)
                await qrController.generateTableQR(business_id, table.id, table_number, table.capacity || 0);
                
                createdTables.push(table);
            }

            return res.status(201).json({
                message: `${count} Tables and QR codes created successfully`,
                tables: createdTables
            });
        } catch (error) {
            console.error("Error creating tables:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // Get all tables for a business
    getTablesByBusiness: async (req, res) => {
        try {
            const { business_id } = req.params;

            const tables = await Table.findAll({
                where: { business_id },
                // We'll sort manually in JS for natural numerical order
            });

            // Fetch QR codes for these tables as well
            const tableIds = tables.map(t => t.id);
            const qrCodes = await QrCode.findAll({
                where: {
                    business_id,
                    qr_type: 'table',
                    reference_id: tableIds
                }
            });

            // Merge QR code data and sort NATURALLY (1, 2, 3... 10)
            const tablesWithQr = tables.map(t => {
                const qr = qrCodes.find(q => q.reference_id == t.id);
                return {
                    ...t.toJSON(),
                    qr_image: qr ? qr.qr_image : null
                };
            }).sort((a, b) => {
                return a.table_number.localeCompare(b.table_number, undefined, {
                    numeric: true,
                    sensitivity: 'base'
                });
            });

            return res.status(200).json({ tables: tablesWithQr });
        } catch (error) {
            console.error("Error fetching tables:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // Delete a single table
    deleteTable: async (req, res) => {
        try {
            const { id } = req.params;
            
            const table = await Table.findByPk(id);
            if (!table) {
                return res.status(404).json({ message: "Table not found" });
            }

            // Delete associated QR code first
            await QrCode.destroy({
                where: {
                    qr_type: 'table',
                    reference_id: id
                }
            });

            await table.destroy();

            return res.status(200).json({ message: "Table and its QR code deleted successfully" });
        } catch (error) {
            console.error("Error deleting table:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    },

    // Delete tables in bulk
    deleteTablesBulk: async (req, res) => {
        try {
            const { ids } = req.body;

            if (!ids || !Array.isArray(ids) || ids.length === 0) {
                return res.status(400).json({ message: "Table IDs are required" });
            }

            // Delete associated QR codes first
            await QrCode.destroy({
                where: {
                    qr_type: 'table',
                    reference_id: ids
                }
            });

            // Delete tables
            await Table.destroy({
                where: {
                    id: ids
                }
            });

            return res.status(200).json({ message: "Tables and QR codes deleted successfully" });
        } catch (error) {
            console.error("Error bulk deleting tables:", error);
            return res.status(500).json({ message: "Internal server error" });
        }
    }
};

module.exports = tableController;
