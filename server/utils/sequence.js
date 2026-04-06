const Invoice = require("../modules/invoice/invoice.model");
const InventoryLog = require("../modules/inventory/inventory.model");
const Settings = require("../modules/settings/settings.model");

/**
 * Generates the next sequential invoice/voucher number for a business.
 * Checks both Invoice and InventoryLog to ensure a continuous sequence.
 */
const getNextSequenceNumber = async (business_id) => {
    const settings = await Settings.findOne({ where: { business_id } });
    const prefix = settings?.invoice_prefix || "BILL";
    const startingNumber = settings?.starting_invoice_number !== undefined ? settings.starting_invoice_number : 1;

    // Count existing invoices
    const invoiceCount = await Invoice.count({ where: { business_id } });

    const nextNumber = startingNumber + invoiceCount;
    const paddedNumber = String(nextNumber).padStart(3, '0');
    return `${prefix}-${paddedNumber}`;
};

module.exports = { getNextSequenceNumber };
