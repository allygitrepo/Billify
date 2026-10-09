const Invoice = require("../modules/invoice/invoice.model");
const InventoryLog = require("../modules/inventory/inventory.model");
const Settings = require("../modules/settings/settings.model");
const Business = require("../modules/businesses/businesses.model");

/**
 * Generates the next sequential invoice/voucher number for a business.
 * Checks both Invoice and InventoryLog to ensure a continuous sequence.
 */
const getNextSequenceNumber = async (business_id) => {
    let prefix = "INV";
    let startingNumber = 1;

    const settings = await Settings.findOne({ where: { business_id } });
    if (settings) {
        prefix = settings.invoice_prefix || prefix;
        if (settings.starting_invoice_number !== undefined && settings.starting_invoice_number !== null) {
            startingNumber = Number(settings.starting_invoice_number);
        }
    } else {
        const business = await Business.findByPk(business_id);
        if (business) {
            prefix = business.invoice_prefix || prefix;
            if (business.starting_invoice_number !== undefined && business.starting_invoice_number !== null) {
                startingNumber = Number(business.starting_invoice_number);
            }
        }
    }

    // Count existing invoices
    const invoiceCount = await Invoice.count({ where: { business_id } });

    const nextNumber = startingNumber + invoiceCount;
    const paddedNumber = String(nextNumber).padStart(3, '0');

    if (prefix.endsWith('/') || prefix.endsWith('-') || prefix.endsWith('_')) {
        return `${prefix}${paddedNumber}`;
    }
    return `${prefix}-${paddedNumber}`;
};

module.exports = { getNextSequenceNumber };

