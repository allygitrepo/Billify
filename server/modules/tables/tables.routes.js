const express = require("express");
const router = express.Router();
const tableController = require("./tables.controller");

// POST /tables - Create a new table
router.post("/", tableController.createTable);

// GET /tables/business/:business_id - Get all tables for a business
router.get("/business/:business_id", tableController.getTablesByBusiness);

// DELETE /tables/:id - Delete a specific table
router.delete("/:id", tableController.deleteTable);

// DELETE /tables/bulk - Delete multiple tables
router.delete("/bulk/delete", tableController.deleteTablesBulk);

module.exports = router;
