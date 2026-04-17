import { formatDate } from './formatDate';
import { formatCurrency } from './formatCurrency';

export const printInvoice = (transaction, settings) => {
  if (!transaction || !settings) return;

  const isThermal = settings.invoiceFormat === 'thermal';
  
  // 1. Create a print-specific div
  const printDiv = document.createElement('div');
  printDiv.id = 'print-section';
  printDiv.className = `print-only-invoice ${isThermal ? 'thermal' : 'a4'}`;

  // 2. Build HTML (using a safe approach - we'll use a template string but avoid scripts)
  const itemsHTML = (transaction.items || []).map((item, idx) => `
    <tr>
      <td>${idx + 1}</td>
      <td>
        <div class="item-name">${item.name || item.productName || 'Item'}</div>
        ${item.variantName ? `<div class="item-variant">${item.variantName}</div>` : ''}
      </td>
      ${!isThermal ? `<td>${item.hsnCode || '-'}</td>` : ''}
      <td>${formatCurrency(item.price || item.unitPrice || 0)}</td>
      <td>${Math.abs(item.quantity || item.quantityChange || 0)}</td>
      <td style="text-align: right;">${formatCurrency((item.price || item.unitPrice || 0) * Math.abs(item.quantity || item.quantityChange || 0))}</td>
    </tr>
  `).join('');

  const invoiceHTML = `
    <div class="print-container">
      <div class="print-header">
        <div class="business-info">
          ${settings.photo ? `<img src="${settings.photo}" alt="Logo" class="print-logo" />` : ''}
          <h1>${settings.businessName || 'Your Business'}</h1>
          <p class="biz-address">${settings.address || ''}</p>
          ${settings.gstNumber ? `<p class="biz-gst">GSTIN: ${settings.gstNumber}</p>` : ''}
          <p class="biz-contact">Ph: ${settings.phone || ''}</p>
        </div>
        <div class="invoice-meta">
          <h2 class="invoice-title">${isThermal ? 'BILL' : 'TAX INVOICE'}</h2>
          <div class="meta-details">
            <p><strong>No:</strong> ${transaction.id || transaction.invoice_number || transaction.reference_no}</p>
            <p><strong>Date:</strong> ${formatDate(transaction.date || transaction.createdAt)}</p>
            <p><strong>Ref:</strong> ${transaction.reference_no || '-'}</p>
          </div>
        </div>
      </div>

      <div class="invoice-info-grid">
        <div class="info-block">
          <h5 style="margin: 0 0 5px 0;">Bill To:</h5>
          <p class="customer-name"><strong>${transaction.customerName || transaction.entity_name || 'Walking Customer'}</strong></p>
          ${transaction.customerPhone ? `<p>Ph: ${transaction.customerPhone}</p>` : ''}
          <p>Payment: ${transaction.paymentMethod || transaction.payment_mode || 'Cash'}</p>
        </div>
      </div>

      <table class="invoice-table">
        <thead>
          <tr>
            <th style="width: 30px;">#</th>
            <th>Item Description</th>
            ${!isThermal ? '<th>HSN</th>' : ''}
            <th>Rate</th>
            <th>Qty</th>
            <th style="text-align: right;">Total</th>
          </tr>
        </thead>
        <tbody>
          ${itemsHTML}
        </tbody>
      </table>

      <div class="print-footer-container">
        <div class="notes-section">
          ${settings.footerNote ? `
            <div class="merchant-note">
              <h5>Notes:</h5>
              <p>${settings.footerNote}</p>
            </div>
          ` : ''}
        </div>
        
        <div class="print-summary">
          <div class="summary-row">
            <span>Subtotal:</span>
            <span>${formatCurrency(transaction.subtotal || transaction.total_amount || 0)}</span>
          </div>
          ${(transaction.tax > 0 || transaction.tax_amount > 0) ? `
            <div class="summary-row">
              <span>Tax/GST:</span>
              <span>${formatCurrency(transaction.tax || transaction.tax_amount || 0)}</span>
            </div>
          ` : ''}
          ${(transaction.discount > 0) ? `
            <div class="summary-row discount">
              <span>Discount:</span>
              <span>-${formatCurrency(transaction.discount)}</span>
            </div>
          ` : ''}
          <div class="summary-row total">
            <span>GRAND TOTAL:</span>
            <span>${formatCurrency(transaction.total || transaction.final_amount || transaction.total_amount || 0)}</span>
          </div>
        </div>
      </div>

      <div class="declaration-section">
        <p>This is a computer-generated document.</p>
        <p>Thank you! Powered by Self Billing</p>
      </div>
    </div>
  `;

  // 3. Add styles
  const style = document.createElement('style');
  style.id = 'print-styles';
  style.textContent = `
    @media screen {
      #print-section { display: none; }
    }
    @media print {
      body * { visibility: hidden; }
      #print-section, #print-section * { visibility: visible; }
      #print-section {
        position: absolute;
        left: 0;
        top: 0;
        width: 100%;
        display: block !important;
        background: white;
        padding: 0;
        margin: 0;
      }
      .print-container { padding: 40px; }
      .print-header { display: flex; justify-content: space-between; border-bottom: 2px solid #333; padding-bottom: 15px; margin-bottom: 25px; }
      .business-info h1 { margin: 0; font-size: 24px; color: #111; }
      .business-info p { margin: 2px 0; font-size: 11px; color: #555; }
      .print-logo { max-width: 100px; max-height: 60px; margin-bottom: 10px; }
      .invoice-meta { text-align: right; }
      .invoice-title { margin: 0; font-size: 20px; letter-spacing: 2px; color: #111; }
      .meta-details p { margin: 2px 0; font-size: 11px; }
      .invoice-info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 30px; }
      .info-block p { margin: 2px 0; font-size: 11px; }
      .invoice-table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
      .invoice-table th { background: #f5f5f5; text-align: left; padding: 10px; font-size: 11px; border-bottom: 1px solid #ddd; }
      .invoice-table td { padding: 10px; border-bottom: 1px solid #eee; font-size: 11px; }
      .item-variant { font-size: 10px; color: #666; }
      .print-footer-container { display: flex; justify-content: space-between; gap: 40px; }
      .print-summary { width: 250px; }
      .summary-row { display: flex; justify-content: space-between; padding: 5px 0; font-size: 11px; }
      .summary-row.total { border-top: 2px solid #333; font-weight: 800; font-size: 14px; margin-top: 10px; padding-top: 10px; }
      .declaration-section { margin-top: 50px; text-align: center; font-size: 10px; color: #888; border-top: 1px dashed #ccc; padding-top: 15px; }
      .thermal { width: 80mm; }
    }
  `;

  printDiv.innerHTML = invoiceHTML;
  document.body.appendChild(printDiv);
  document.head.appendChild(style);

  // 4. Trigger print and clean up
  window.print();

  // Clean up after print (using a slight delay to ensure print dialog opened)
  setTimeout(() => {
    document.body.removeChild(printDiv);
    document.head.removeChild(style);
  }, 1000);
};
