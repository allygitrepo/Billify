import React, { useState, useMemo } from 'react';
import { useDataContext } from '../../hooks/useDataContext';
import PageContainer from '../../components/layout/PageContainer';
import Button from '../../components/common/Button';
import Input from '../../components/common/Input';
import Select from '../../components/common/Select';
import { formatDate } from '../../utils/formatDate';
import { formatCurrency } from '../../utils/formatCurrency';

const Transactions = () => {
  const { transactions, settings } = useDataContext();
  const [searchTerm, setSearchTerm] = useState('');
  const [typeFilter, setTypeFilter] = useState('All');
  const [paymentFilter, setPaymentFilter] = useState('All');
  const [dateFilter, setDateFilter] = useState('');
  const [expandedId, setExpandedId] = useState(null);

  const toggleExpand = (id) => {
    setExpandedId(expandedId === id ? null : id);
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
    alert('Exporting transactions to CSV...');
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
          <div className="custom-table-container">
            <table className="custom-table">
              <thead>
                <tr>
                  <th>Invoice No</th>
                  <th>Type</th>
                  <th>Date</th>
                  <th>Items</th>
                  <th>Payment</th>
                  <th>Total</th>
                  <th>Status</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {filteredTransactions.length === 0 ? (
                  <tr>
                    <td colSpan="8" className="text-center py-8 text-neutral-400">No transactions found</td>
                  </tr>
                ) : (
                  filteredTransactions.map(t => (
                    <React.Fragment key={t.id}>
                      <tr className={expandedId === t.id ? 'row-expanded-header' : ''}>
                        <td className="font-semibold">{t.id}</td>
                        <td>
                          <span className={`type-tag ${t.type.toLowerCase()}`}>{t.type}</span>
                        </td>
                        <td>{formatDate(t.date)}</td>
                        <td>{t.items.length} items</td>
                        <td>{t.paymentMethod}</td>
                        <td className="font-bold">{formatCurrency(t.total)}</td>
                        <td>
                          <span className={`status-badge ${t.status.toLowerCase()}`}>{t.status}</span>
                        </td>
                        <td>
                          <button 
                            className="btn-text p-0" 
                            style={{color: 'var(--primary-600)', fontWeight: '600'}}
                            onClick={() => toggleExpand(t.id)}
                          >
                            {expandedId === t.id ? 'Close' : 'View'}
                          </button>
                        </td>
                      </tr>
                      {expandedId === t.id && (
                        <tr className="expanded-row">
                          <td colSpan="8">
                            <div className="detail-container animate-fade-in">
                              <div className="detail-header">
                                <h4>Invoice Details: {t.id}</h4>
                                <div className="detail-meta">
                                  <span><strong>Date:</strong> {formatDate(t.date)} {new Date(t.date).toLocaleTimeString()}</span>
                                  <span><strong>Cashier:</strong> Admin</span>
                                </div>
                              </div>
                              
                              <table className="detail-items-table">
                                <thead>
                                  <tr>
                                    <th>Item Name</th>
                                    <th>Qty</th>
                                    <th>Price</th>
                                    <th className="text-right">Total</th>
                                  </tr>
                                </thead>
                                <tbody>
                                  {t.items.map((item, idx) => (
                                    <tr key={idx}>
                                      <td>{item.name} ({item.variantName})</td>
                                      <td>{item.quantity}</td>
                                      <td>{formatCurrency(item.price)}</td>
                                      <td className="text-right">{formatCurrency(item.price * item.quantity)}</td>
                                    </tr>
                                  ))}
                                </tbody>
                              </table>

                              <div className="detail-footer">
                                <div className="detail-summary">
                                  <div className="summary-line">
                                    <span>Subtotal</span>
                                    <span>{formatCurrency(t.subtotal)}</span>
                                  </div>
                                  <div className="summary-line">
                                    <span>Tax ({settings.taxPercentage || 0}%)</span>
                                    <span>{formatCurrency(t.tax)}</span>
                                  </div>
                                  <div className="summary-line">
                                    <span>GST ({settings.gstPercentage || 0}%)</span>
                                    <span>{formatCurrency(t.gst)}</span>
                                  </div>
                                  <div className="summary-line discount">
                                    <span>Discount</span>
                                    <span>-{formatCurrency(t.discount)}</span>
                                  </div>
                                  <div className="summary-line grand-total">
                                    <span>Grand Total</span>
                                    <span>{formatCurrency(t.total)}</span>
                                  </div>
                                </div>
                                <div className="detail-actions">
                                  <Button variant="secondary" onClick={() => window.print()}>Print Invoice</Button>
                                  <Button variant="secondary">Email to Customer</Button>
                                </div>
                              </div>
                            </div>
                          </td>
                        </tr>
                      )}
                    </React.Fragment>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </PageContainer>
  );
};

export default Transactions;
