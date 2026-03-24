import React, { useState, useMemo } from 'react';
import { useDataContext } from '../../hooks/useDataContext';
import PageContainer from '../../components/layout/PageContainer';
import Button from '../../components/common/Button';
import Input from '../../components/common/Input';
import Select from '../../components/common/Select';
import { formatDate } from '../../utils/formatDate';
import { formatCurrency } from '../../utils/formatCurrency';
import { exportToCSV } from '../../utils/csvService';
import Table from '../../components/common/Table';
import Modal from '../../components/common/Modal';

const Transactions = () => {
  const { transactions, settings, showToast } = useDataContext();
  const [searchTerm, setSearchTerm] = useState('');
  const [typeFilter, setTypeFilter] = useState('All');
  const [paymentFilter, setPaymentFilter] = useState('All');
  const [dateFilter, setDateFilter] = useState('');
  const [selectedTransaction, setSelectedTransaction] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const openInvoice = (transaction) => {
    setSelectedTransaction(transaction);
    setIsModalOpen(true);
  };

  const handlePrint = (transaction) => {
    const isThermal = settings.invoiceFormat === 'thermal';
    
    // Create a temporary div to render the invoice content for printing
    const printContainer = document.createElement('div');
    printContainer.className = `print-only-invoice ${isThermal ? 'thermal' : 'a4'}`;

    // Construct the invoice HTML based on the selected format
    const invoiceHTML = `
      <div class="print-header">
        <div class="business-info">
          ${settings.photo ? `<img src="${settings.photo}" alt="Logo" class="print-logo" />` : ''}
          <h1>${settings.businessName || 'Billify'}</h1>
          <p class="biz-address">${settings.address || ''}</p>
          ${settings.gstNumber ? `<p class="biz-gst">GSTIN: ${settings.gstNumber}</p>` : ''}
          <p class="biz-contact">Ph: ${settings.phone || ''} ${settings.email ? `| ${settings.email}` : ''}</p>
        </div>
        <div class="invoice-meta" style="text-align: ${isThermal ? 'center' : 'right'};">
          <h2 class="invoice-title">${isThermal ? 'INVOICE' : 'TAX INVOICE'}</h2>
          <div class="meta-details">
            <p><strong>Invoice #:</strong> ${transaction.id}</p>
            <p><strong>Date:</strong> ${formatDate(transaction.date)}</p>
            ${!isThermal ? `<p><strong>Payment:</strong> ${transaction.paymentMethod}</p>` : ''}
          </div>
        </div>
      </div>

      <div class="invoice-info-grid">
        <div class="info-block">
          <h5>Bill To:</h5>
          <p class="customer-name"><strong>Walking Customer</strong></p>
          ${isThermal ? `<p>Payment: ${transaction.paymentMethod}</p>` : ''}
        </div>
        ${!isThermal ? `
        <div class="info-block" style="text-align: right;">
          <h5>Place of Supply:</h5>
          <p>${settings.address?.split(',').pop()?.trim() || 'N/A'}</p>
        </div>
        ` : ''}
      </div>

      <table class="invoice-table">
        <thead>
          <tr>
            <th style="width: 40px;">Sl.</th>
            <th>Item Description</th>
            ${!isThermal ? '<th>HSN/SAC</th>' : ''}
            <th>Price</th>
            <th>Qty</th>
            <th style="text-align: right;">Total</th>
          </tr>
        </thead>
        <tbody>
          ${transaction.items.map((item, idx) => `
            <tr>
              <td>${idx + 1}</td>
              <td>
                <div class="item-name">${item.name}</div>
                ${item.variantName ? `<div class="item-variant">${item.variantName}</div>` : ''}
              </td>
              ${!isThermal ? `<td>${item.hsnCode || '-'}</td>` : ''}
              <td>${formatCurrency(item.price)}</td>
              <td>${item.quantity}</td>
              <td style="text-align: right;">${formatCurrency(item.price * item.quantity)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>

      <div class="print-footer-container">
        <div class="notes-section">
          ${!isThermal ? `
            <div class="amount-in-words">
              <h5>Amount in Words:</h5>
              <p style="text-transform: capitalize;">${transaction.total.toLocaleString('en-IN')} Only</p>
            </div>
          ` : ''}
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
            <span>${formatCurrency(transaction.subtotal)}</span>
          </div>
          ${(transaction.tax > 0 || settings.taxPercentage > 0) ? `
            <div class="summary-row">
              <span>Tax (${settings.taxPercentage || 0}%):</span>
              <span>${formatCurrency(transaction.tax)}</span>
            </div>
          ` : ''}
          ${(transaction.gst > 0 || settings.gstPercentage > 0) ? `
            <div class="summary-row">
              <span>GST (${settings.gstPercentage || 0}%):</span>
              <span>${formatCurrency(transaction.gst)}</span>
            </div>
          ` : ''}
          ${transaction.discount > 0 ? `
            <div class="summary-row discount">
              <span>Discount:</span>
              <span>-${formatCurrency(transaction.discount)}</span>
            </div>
          ` : ''}
          <div class="summary-row total">
            <span>Grand Total:</span>
            <span>${formatCurrency(transaction.total)}</span>
          </div>
        </div>
      </div>

      <div class="declaration-section">
        <p>This is a computer-generated invoice and does not require a signature.</p>
        <p>Thank you for your business! Powered by Billify POS</p>
      </div>
    `;

    printContainer.innerHTML = invoiceHTML;
    document.body.appendChild(printContainer);


    // Create a hidden iframe
    const iframe = document.createElement('iframe');
    // Using visibility instead of display:none as some browsers block print on display:none
    Object.assign(iframe.style, {
      position: 'fixed',
      right: '0',
      bottom: '0',
      width: '1px',
      height: '1px',
      border: '0',
      visibility: 'hidden'
    });
    document.body.appendChild(iframe);

    const doc = iframe.contentWindow.document;
    
    // Create style element
    const style = doc.createElement('style');
    // Minimal styles for testing
    style.textContent = `
      body { margin: 0; padding: 20px; font-family: sans-serif; }
      .print-only-invoice { display: block !important; }
      .print-header { display: flex; justify-content: space-between; border-bottom: 2px solid #0d9488; padding-bottom: 10px; margin-bottom: 20px; }
      .business-info h1 { margin: 0; color: #0d9488; font-size: 24px; }
      .invoice-info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 20px; }
      .invoice-table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
      .invoice-table th { background: #f1f5f9; text-align: left; padding: 8px; font-size: 12px; }
      .invoice-table td { padding: 8px; border-bottom: 1px solid #eee; font-size: 12px; }
      .print-footer { display: flex; justify-content: flex-end; }
      .print-summary { width: 200px; }
      .print-summary-row { display: flex; justify-content: space-between; padding: 4px 0; font-size: 12px; }
      .total { border-top: 2px solid #0d9488; font-weight: bold; font-size: 14px; margin-top: 10px; padding-top: 10px; }
      .thermal { width: 80mm; }
      .a4 { width: 210mm; }
      .footer-note { margin-top: 30px; text-align: center; font-size: 10px; color: #666; border-top: 1px dashed #eee; padding-top: 10px; }
    `;
    doc.head.appendChild(style);

    // Append the generated invoice HTML to the iframe's body
    doc.body.appendChild(printContainer.cloneNode(true)); // Clone to avoid moving the original element

    // Trigger print
    setTimeout(() => {
      iframe.contentWindow.focus();
      iframe.contentWindow.print();
      
      // Cleanup
      setTimeout(() => {
        if (document.body.contains(iframe)) {
          document.body.removeChild(iframe);
        }
        if (document.body.contains(printContainer)) {
          document.body.removeChild(printContainer); // Remove the temporary container
        }
      }, 1000);
    }, 300);
  };

  const filteredTransactions = useMemo(() => {
    return transactions.filter(t => {
      const matchesSearch = t.id.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesType = typeFilter === 'All' || t.type === typeFilter;
      const matchesPayment = paymentFilter === 'All' || t.paymentMethod === paymentFilter;
      const matchesDate = !dateFilter || formatDate(t.date).includes(dateFilter);
      return matchesSearch && matchesType && matchesPayment && matchesDate;
    });
  }, [transactions, searchTerm, typeFilter, paymentFilter, dateFilter]);

  const handleExport = () => {
    const exportData = filteredTransactions.map(t => ({
      invoiceNo: t.id,
      type: t.type,
      date: formatDate(t.date),
      itemsCount: t.items.length,
      paymentMethod: t.paymentMethod,
      subtotal: t.subtotal,
      tax: t.tax,
      gst: t.gst,
      discount: t.discount,
      total: t.total,
      status: t.status
    }));
    exportToCSV(exportData, 'billify_transactions');
  };

  return (
    <PageContainer title="Transactions & Invoices">
      <div className="animate-fade-in">
        {/* Filters Section */}
        <div className="card mb-6">
          <div className="table-controls">
            <h3 className="card-title">Filter Transactions</h3>
            <Button variant="secondary" onClick={handleExport}>
              <span style={{display: 'inline-flex', alignItems: 'center', gap: '6px'}}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="17 8 12 3 7 8"></polyline><line x1="12" y1="3" x2="12" y2="15"></line></svg>
                Export CSV
              </span>
            </Button>
          </div>
          <div className="transactions-filter-grid">
            <Input 
              placeholder="Search Invoice No..." 
              value={searchTerm} 
              onChange={(e) => setSearchTerm(e.target.value)} 
              style={{ marginBottom: 0 }}
            />
            <Select 
              value={typeFilter} 
              onChange={(e) => setTypeFilter(e.target.value)}
              options={[
                { label: 'All Types', value: 'All' },
                { label: 'Invoice', value: 'Invoice' },
                { label: 'Order', value: 'Order' },
                { label: 'Quotation', value: 'Quotation' }
              ]}
              style={{ marginBottom: 0 }}
            />
            <Select 
              value={paymentFilter} 
              onChange={(e) => setPaymentFilter(e.target.value)}
              options={[
                { label: 'All Payments', value: 'All' },
                { label: 'Cash', value: 'Cash' },
                { label: 'UPI', value: 'UPI' },
                { label: 'Card', value: 'Card' }
              ]}
              style={{ marginBottom: 0 }}
            />
            <Input 
              type="date" 
              value={dateFilter} 
              onChange={(e) => setDateFilter(e.target.value)} 
              style={{ marginBottom: 0 }}
            />
          </div>
        </div>

        {/* Transactions Table */}
        <div className="card no-padding">
          <Table 
            columns={[
              { key: 'id', label: 'Invoice No', render: (val) => <span className="font-semibold">{val}</span> },
              { key: 'type', label: 'Type', render: (val) => <span className={`type-tag ${val.toLowerCase()}`}>{val}</span> },
              { key: 'date', label: 'Date', render: (val) => formatDate(val) },
              { key: 'items', label: 'Items', render: (val) => `${val.length} items` },
              { key: 'paymentMethod', label: 'Payment' },
              { key: 'total', label: 'Total', render: (val) => <span className="font-bold">{formatCurrency(val)}</span> },
              { key: 'status', label: 'Status', render: (val) => <span className={`status-badge ${val.toLowerCase()}`}>{val}</span> },
              { 
                key: 'actions', 
                label: 'Action', 
                render: (_, row) => (
                  <button 
                    className="btn-text p-0" 
                    style={{color: 'var(--primary-600)', fontWeight: '600'}}
                    onClick={() => openInvoice(row)}
                  >
                    View
                  </button>
                )
              }
            ]} 
            data={filteredTransactions} 
          />
        </div>

        {/* Invoice Modal */}
        <Modal 
          isOpen={isModalOpen} 
          onClose={() => setIsModalOpen(false)}
          title={`Invoice Detail: ${selectedTransaction?.id}`}
          maxWidth="550px"
        >
          {selectedTransaction && (
            <div className="invoice-modal animate-fade-in">
              <div className="invoice-modal-header">
                <div className="invoice-modal-logo">🏪</div>
                <h2 className="invoice-modal-business-name">{settings.businessName || 'Billify'}</h2>
                <p className="invoice-modal-business-addr">{settings.address || 'Business Address Line'}</p>
                <p className="invoice-modal-business-addr" style={{marginTop: '2px'}}>GST: {settings.gstNumber || 'XXXXXXXXXXXXX'}</p>
              </div>

              <div className="invoice-modal-meta-box">
                <div className="meta-item">
                  <label>Invoice No</label>
                  <span>{selectedTransaction.id}</span>
                </div>
                <div className="meta-item">
                  <label>Date</label>
                  <span>{formatDate(selectedTransaction.date)}</span>
                </div>
                <div className="meta-item">
                  <label>Cashier</label>
                  <span>Arjun Rathod</span>
                </div>
                <div className="meta-item">
                  <label>Payment</label>
                  <span>{selectedTransaction.paymentMethod}</span>
                </div>
              </div>

              <table className="invoice-modal-table">
                <thead>
                  <tr>
                    <th>Item</th>
                    <th className="text-right">Qty</th>
                    <th className="text-right">Rate</th>
                    <th className="text-right">Amount</th>
                  </tr>
                </thead>
                <tbody>
                  {selectedTransaction.items.map((item, idx) => (
                    <tr key={idx}>
                      <td>{item.name}</td>
                      <td className="text-right">{item.quantity}</td>
                      <td className="text-right">{formatCurrency(item.price)}</td>
                      <td className="text-right">{formatCurrency(item.price * item.quantity)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>

              <div className="invoice-modal-summary-box">
                <div className="summary-line-modal">
                  <span>Subtotal</span>
                  <span>{formatCurrency(selectedTransaction.subtotal)}</span>
                </div>
                <div className="summary-line-modal">
                  <span>CGST (9%)</span>
                  <span>{formatCurrency(selectedTransaction.gst / 2)}</span>
                </div>
                <div className="summary-line-modal">
                  <span>SGST (9%)</span>
                  <span>{formatCurrency(selectedTransaction.gst / 2)}</span>
                </div>
                <div className="total-line-modal">
                  <span>TOTAL</span>
                  <span>{formatCurrency(selectedTransaction.total)}</span>
                </div>
              </div>

              <p style={{textAlign: 'center', fontSize: '11px', color: 'var(--neutral-400)', marginBottom: '20px'}}>
                Thank you for shopping with us! 🙏
              </p>

              <div className="social-sharing">
                <button className="share-icon-btn" onClick={() => showToast('WhatsApp Sharing coming soon!', 'info')}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"></path></svg>
                  WhatsApp
                </button>
                <button className="share-icon-btn" onClick={() => showToast('Email Sharing coming soon!', 'info')}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path><polyline points="22,6 12,13 2,6"></polyline></svg>
                  Email
                </button>
              </div>

              <div className="modal-actions">
                <Button variant="secondary" onClick={() => setIsModalOpen(false)}>Close</Button>
                <Button variant="primary" onClick={() => handlePrint(selectedTransaction)}>
                  <span style={{display: 'inline-flex', alignItems: 'center', gap: '8px'}}>
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="6 9 6 2 18 2 18 9"></polyline><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path><rect x="6" y="14" width="12" height="8"></rect></svg>
                    Print Invoice
                  </span>
                </Button>
              </div>
            </div>
          )}
        </Modal>
      </div>
    </PageContainer>
  );
};

export default Transactions;
