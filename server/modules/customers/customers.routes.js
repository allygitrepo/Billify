const express = require("express");
const router = express.Router();
const customersController = require("./customers.controller");

const { authenticate } = require("../../middleware/auth.middleware");
const { authorize } = require("../../middleware/permission.middleware");

router.post("/", authenticate, authorize('customers', 'can_add'), customersController.createCustomer);
router.get("/", authenticate, authorize('customers', 'can_view'), customersController.getCustomers);
router.get("/dropdown", authenticate, authorize('customers', 'can_view'), customersController.getCustomerDropdown);
router.post("/bulk-import", authenticate, authorize('customers', 'can_add'), customersController.bulkImportCustomers);
router.get("/ledger/:id", authenticate, authorize('customers', 'can_view'), customersController.getCustomerLedger);
router.get("/:id", authenticate, authorize('customers', 'can_view'), customersController.getCustomerById);
router.put("/:id", authenticate, authorize('customers', 'can_edit'), customersController.updateCustomer);
router.delete("/:id", authenticate, authorize('customers', 'can_delete'), customersController.deleteCustomer);

module.exports = router;
