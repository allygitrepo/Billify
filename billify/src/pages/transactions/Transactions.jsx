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
import InvoiceModal from '../../components/pos/InvoiceModal';
import { printInvoice } from '../../utils/printService';

const Transactions = () => {
  const { transactions, settings, user, showToast } = useDataContext();
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
    printInvoice(transaction, settings);
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
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}>
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
                    style={{ color: 'var(--primary-600)', fontWeight: '600' }}
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
        <InvoiceModal 
          isOpen={isModalOpen}
          onClose={() => setIsModalOpen(false)}
          transaction={selectedTransaction}
          settings={settings}
          user={user}
          onPrint={handlePrint}
        />
      </div>
    </PageContainer>
  );
};

export default Transactions;
