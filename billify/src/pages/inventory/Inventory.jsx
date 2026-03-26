import React, { useState, useMemo } from 'react';
import { useDataContext } from '../../hooks/useDataContext';
import PageContainer from '../../components/layout/PageContainer';
import Select from '../../components/common/Select';
import Input from '../../components/common/Input';
import Button from '../../components/common/Button';
import Table from '../../components/common/Table';
import { formatDate } from '../../utils/formatDate';
import { exportToCSV } from '../../utils/csvService';
import { FileText, Printer, X, ShoppingCart, User, Hash, Tag, DollarSign, ArrowDownRight, ArrowUpRight, Plus, Minus, Layers } from 'lucide-react';
import InvoiceModal from '../../components/pos/InvoiceModal';
import { printInvoice } from '../../utils/printService';

const Inventory = () => {
  const { products, inventoryLog, addInventoryEntry, user, settings, loading, showToast } = useDataContext();

  const [filterType, setFilterType] = useState('all');
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');
  const [selectedVoucher, setSelectedVoucher] = useState(null);

  // Unified Form States
  const [header, setHeader] = useState({ reason: 'Manual Adjustment', referenceNo: '', entityName: '' });
  const [items, setItems] = useState([]);
  const [currentItem, setCurrentItem] = useState({ productId: '', variantName: '', quantity: '', unitPrice: '', type: 'IN' });
  const [errors, setErrors] = useState({});

  // Product Helper
  const getVariants = (productId) => {
    const product = products.find(p => p.id == productId);
    return product ? product.variants.map(v => ({ label: v.name, value: v.name })) : [];
  };

  const handleProductChange = (productId) => {
    const selectedProduct = products.find(p => p.id == productId);
    const variants = selectedProduct ? selectedProduct.variants : [];
    
    // Auto-select first variant if only one exists
    const autoVariant = variants.length === 1 ? variants[0].name : '';
    const autoPrice = (variants.length === 1) ? variants[0].price : '';

    setCurrentItem({ ...currentItem, productId, variantName: autoVariant, unitPrice: autoPrice });
    setErrors({ ...errors, productId: null, variantName: autoVariant ? null : errors.variantName });
  };

  const handleVariantChange = (variantName) => {
    const selectedProduct = products.find(p => p.id == currentItem.productId);
    const variant = selectedProduct?.variants.find(v => v.name === variantName);
    const price = variant ? variant.price : '';

    setCurrentItem({ ...currentItem, variantName, unitPrice: price });
    setErrors({ ...errors, variantName: null });
  };

  const addItem = () => {
    const itemErrors = {};

    if (!currentItem.productId) itemErrors.productId = 'Product required';
    if (!currentItem.variantName) itemErrors.variantName = 'Variant required';
    if (!currentItem.quantity || isNaN(currentItem.quantity) || parseFloat(currentItem.quantity) <= 0) {
      itemErrors.quantity = 'Qty must be > 0';
    }
    if (currentItem.unitPrice && parseFloat(currentItem.unitPrice) < 0) {
      itemErrors.unitPrice = 'Price cannot be negative';
    }

    if (Object.keys(itemErrors).length > 0) {
      setErrors(itemErrors);
      return;
    }

    const selectedProduct = products.find(p => p.id == currentItem.productId);
    const newItem = {
      ...currentItem,
      productName: selectedProduct.name,
      quantity: parseFloat(currentItem.quantity),
      unitPrice: parseFloat(currentItem.unitPrice) || 0,
      totalAmount: (parseFloat(currentItem.quantity) * (parseFloat(currentItem.unitPrice) || 0)).toFixed(2)
    };

    setItems([...items, newItem]);
    // Reset but keep type
    setCurrentItem({ ...currentItem, productId: '', variantName: '', quantity: '', unitPrice: '' });
    setErrors({});
  };

  const removeItem = (index) => {
    setItems(items.filter((_, i) => i !== index));
  };

  const handleTransactionSubmit = async () => {
    if (items.length === 0) {
      showToast('Add at least one item', 'error');
      return;
    }

    // Determine aggregate type for the log (IN, OUT, or Mixed)
    const types = [...new Set(items.map(i => i.type))];
    const aggregateType = types.length > 1 ? 'Mixed' : types[0];

    const data = {
      ...header,
      type: aggregateType, 
      items: items
    };

    const result = await addInventoryEntry(data);
    
    if (result) {
      // Reset everything
      setHeader({ reason: 'Manual Adjustment', referenceNo: '', entityName: '' });
      setItems([]);
      setCurrentItem({ productId: '', variantName: '', quantity: '', unitPrice: '', type: 'IN' });
    }
  };

  const filteredLogs = useMemo(() => {
    return inventoryLog.filter(log => {
      const matchesType = filterType === 'all' || log.type === filterType;
      
      const logDate = new Date(log.date);
      logDate.setHours(0, 0, 0, 0);
      
      let matchesDate = true;
      if (fromDate) {
        const from = new Date(fromDate);
        from.setHours(0, 0, 0, 0);
        matchesDate = matchesDate && logDate >= from;
      }
      if (toDate) {
        const to = new Date(toDate);
        to.setHours(0, 0, 0, 0);
        matchesDate = matchesDate && logDate <= to;
      }

      return matchesType && matchesDate;
    });
  }, [inventoryLog, filterType, fromDate, toDate]);

  const handleExportLogs = () => {
    const exportData = filteredLogs.map(log => ({
      product: log.productName,
      variant: log.variantName,
      type: log.type,
      change: log.quantityChange,
      stockAfter: log.stockAfter,
      doneBy: log.doneBy,
      reference: log.referenceNo || '-',
      party: log.entityName || '-',
      amount: log.totalAmount || 0,
      date: formatDate(log.date) + ' ' + new Date(log.date).toLocaleTimeString()
    }));
    exportToCSV(exportData, 'inventory_history');
  };

  const netTotal = items.reduce((acc, curr) => {
    const amount = parseFloat(curr.totalAmount);
    return curr.type === 'IN' ? acc - amount : acc + amount;
  }, 0);

  const columns = [
    { key: 'productName', label: 'Product' },
    { key: 'variantName', label: 'Variant' },
    { 
      key: 'type', 
      label: 'Type',
      render: (type) => <span className={`type-badge ${type}`}>{type}</span>
    },
    { 
      key: 'quantityChange', 
      label: 'Qty Change',
      render: (val) => <span style={{ color: val > 0 ? 'var(--success-600)' : 'var(--danger-600)', fontWeight: 'bold' }}>{val > 0 ? `+${val}` : val}</span>
    },
    { key: 'stockAfter', label: 'Stock After' },
    { 
      key: 'referenceNo', 
      label: 'Reference',
      render: (val) => <span className="text-muted">{val || '-'}</span>
    },
    { 
      key: 'actions', 
      label: 'Invoice',
      render: (_, log) => (
        <button 
          className="btn-icon-xs" 
          onClick={() => {
            const groupItems = log.referenceNo 
              ? inventoryLog.filter(l => l.referenceNo === log.referenceNo)
              : [log];
            
            const tx = {
              id: log.referenceNo || log.id,
              invoice_number: log.referenceNo,
              date: log.date,
              customerName: log.entityName,
              paymentMethod: 'Cash',
              items: groupItems.map(gi => ({
                name: gi.productName,
                variantName: gi.variantName,
                quantity: Math.abs(gi.quantityChange),
                price: gi.unitPrice,
                subtotal: gi.totalAmount
              })),
              total: groupItems.reduce((acc, gi) => acc + parseFloat(gi.totalAmount || 0), 0),
              type: log.type === 'IN' ? 'Purchase' : 'Sale'
            };
            setSelectedVoucher(tx);
          }}
          title="View Voucher"
        >
          <FileText size={16} />
        </button>
      )
    },
    { 
      key: 'date', 
      label: 'Date & Time',
      render: (val) => {
        const d = new Date(val);
        return formatDate(val) + ' ' + d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      }
    }
  ];

  const formatCurrency = (amount) => {
    const symbol = settings?.currencySymbol || '₹';
    return `${symbol}${parseFloat(Math.abs(amount) || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  };

  return (
    <PageContainer title="Inventory Management">
      <div className="animate-fade-in">
        {/* Unified Transaction Builder */}
        <div className="card unified-inventory-card">
          <div className="card-header-flex">
            <h3 className="panel-title text-primary">
              <Layers size={20} style={{ marginRight: '8px' }} />
              Create Mixed Inventory Voucher
            </h3>
            <div className="header-meta-grid">
              <Select 
                label="Reason" 
                value={header.reason} 
                onChange={(e) => setHeader({...header, reason: e.target.value})} 
                options={[
                  {label: 'Manual Adjustment', value: 'Manual Adjustment'},
                  {label: 'Bulk Purchase', value: 'Purchase'}, 
                  {label: 'Stock Return', value: 'Return'},
                  {label: 'Damage Correction', value: 'Damage'}
                ]}
              />
              <Input 
                label="Vendor / Customer" 
                placeholder="Name or Source" 
                value={header.entityName} 
                onChange={(e) => setHeader({...header, entityName: e.target.value})} 
              />
              <Input 
                label="Ref. Number" 
                placeholder="INV-001 or Bill No." 
                value={header.referenceNo} 
                onChange={(e) => setHeader({...header, referenceNo: e.target.value})} 
              />
            </div>
          </div>

          <div className="item-builder-section mt-6">
            <h4 className="section-subtitle mb-4">Add Products to Voucher</h4>
            <div className="item-builder-grid mixed-grid">
              <div className="builder-col-main">
                <Select 
                  label="Product" 
                  value={currentItem.productId} 
                  onChange={(e) => handleProductChange(e.target.value)} 
                  options={products.map(p => ({ label: p.name, value: p.id }))}
                  error={errors.productId}
                />
              </div>
              <div className="builder-col">
                <Select 
                  label="Variant" 
                  value={currentItem.variantName} 
                  onChange={(e) => handleVariantChange(e.target.value)} 
                  options={currentItem.productId ? getVariants(currentItem.productId) : []}
                  error={errors.variantName}
                />
              </div>
              <div className="builder-col">
                <Select 
                  label="Action" 
                  value={currentItem.type} 
                  onChange={(e) => setCurrentItem({...currentItem, type: e.target.value})} 
                  options={[{label: 'Inbound (Stock IN)', value: 'IN'}, {label: 'Outbound (Stock OUT)', value: 'OUT'}]}
                />
              </div>
              <div className="builder-col">
                 <Input 
                  label="Quantity" 
                  type="number" 
                  min="0"
                  value={currentItem.quantity} 
                  onChange={(e) => {
                    const val = e.target.value;
                    if (val !== '' && parseFloat(val) < 0) return;
                    setCurrentItem({...currentItem, quantity: val});
                    if (errors.quantity) setErrors({ ...errors, quantity: null });
                  }} 
                  error={errors.quantity}
                />
              </div>
              <div className="builder-col">
                <Input 
                  label="Unit Price" 
                  type="number" 
                  min="0"
                  value={currentItem.unitPrice} 
                  onChange={(e) => {
                    const val = e.target.value;
                    if (val !== '' && parseFloat(val) < 0) return;
                    setCurrentItem({...currentItem, unitPrice: val});
                    if (errors.unitPrice) setErrors({ ...errors, unitPrice: null });
                  }} 
                  error={errors.unitPrice}
                />
              </div>
              <div className="builder-col-action">
                 <Button variant="secondary" onClick={addItem} fullWidth icon={<Plus size={16} />}>
                  Add
                </Button>
              </div>
            </div>

            {/* Pending Items Table */}
            {items.length > 0 && (
              <div className="pending-items-container animate-fade-in">
                <table className="mini-table">
                  <thead>
                    <tr>
                      <th>Action</th>
                      <th>Product & Variant</th>
                      <th className="text-right">Quantity</th>
                      <th className="text-right">Unit Price</th>
                      <th className="text-right">Total</th>
                      <th className="text-center"></th>
                    </tr>
                  </thead>
                  <tbody>
                    {items.map((item, idx) => (
                      <tr key={idx} className={item.type === 'IN' ? 'row-in' : 'row-out'}>
                        <td>
                          <span className={`type-badge-sm ${item.type}`}>
                            {item.type === 'IN' ? <Plus size={12} /> : <Minus size={12} />}
                            {item.type}
                          </span>
                        </td>
                        <td>
                          <div className="item-name-cell">
                            <strong>{item.productName}</strong>
                            <span>{item.variantName}</span>
                          </div>
                        </td>
                        <td className="text-right">{item.quantity}</td>
                        <td className="text-right">{formatCurrency(item.unitPrice)}</td>
                        <td className="text-right">
                          <strong style={{ color: item.type === 'IN' ? 'var(--neutral-700)' : 'var(--danger-700)' }}>
                            {item.type === 'IN' ? '-' : '+'}{formatCurrency(item.totalAmount)}
                          </strong>
                        </td>
                        <td className="text-center">
                          <button className="remove-row-btn" onClick={() => removeItem(idx)} title="Remove item"><X size={14} /></button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                <div className="transaction-footer-unified">
                  <div className="total-calculation-summary">
                    <div className="calc-row">
                      <span>Total Inbound (Purchases):</span>
                      <span className="text-success">{formatCurrency(items.filter(i => i.type === 'IN').reduce((acc, i) => acc + parseFloat(i.totalAmount), 0))}</span>
                    </div>
                    <div className="calc-row">
                      <span>Total Outbound (Sales):</span>
                      <span className="text-danger">{formatCurrency(items.filter(i => i.type === 'OUT').reduce((acc, i) => acc + parseFloat(i.totalAmount), 0))}</span>
                    </div>
                    <div className="calc-row grand-net">
                      <span>{netTotal >= 0 ? 'Net Receivable:' : 'Net Payable:'}</span>
                      <strong>{formatCurrency(netTotal)}</strong>
                    </div>
                  </div>
                  <Button 
                    variant="primary" 
                    onClick={handleTransactionSubmit} 
                    className="submit-batch-btn"
                  >
                    <Printer size={18} style={{ marginRight: '8px' }} /> Confirm & Record Transaction
                  </Button>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Inventory Log History */}
        <div className="card mt-8">
          <div className="table-controls">
            <h3 className="card-title">Inventory Transaction History</h3>
            <div className="history-filters-container">
              <div className="filter-field-group">
                <label className="field-label">Transaction Type</label>
                <Select 
                  value={filterType} 
                  onChange={(e) => setFilterType(e.target.value)}
                  options={[{label: 'All Types', value: 'all'}, {label: 'Stock IN', value: 'IN'}, {label: 'Stock OUT', value: 'OUT'}]}
                  placeholder={null}
                  className="history-filter-select"
                />
              </div>

              <div className="filter-field-group">
                <label className="field-label">From Date</label>
                <input 
                  type="date"
                  className="history-date-input"
                  value={fromDate}
                  onChange={(e) => setFromDate(e.target.value)}
                />
              </div>

              <div className="filter-field-group">
                <label className="field-label">To Date</label>
                <input 
                  type="date"
                  className="history-date-input"
                  value={toDate}
                  onChange={(e) => setToDate(e.target.value)}
                />
              </div>

              <div className="filter-field-group action-group">
                <label className="field-label">&nbsp;</label>
                <Button variant="secondary" onClick={handleExportLogs} fullWidth icon={<FileText size={16} />}>
                  Export Report
                </Button>
              </div>
            </div>
          </div>
          <Table 
            columns={columns} 
            data={filteredLogs} 
            isLoading={loading && !inventoryLog} 
            emptyMessage="No inventory history found"
          />
        </div>
      </div>

      <InvoiceModal 
        isOpen={!!selectedVoucher}
        onClose={() => setSelectedVoucher(null)}
        transaction={selectedVoucher}
        settings={settings}
        user={user}
        onPrint={(tx) => printInvoice(tx, settings)}
      />

      <style jsx>{`
        .unified-inventory-card {
           border-top: 4px solid var(--primary-500);
        }

        .card-header-flex {
          display: flex;
          flex-direction: column;
          gap: var(--spacing-6);
          padding-bottom: var(--spacing-6);
          border-bottom: 1px solid var(--neutral-100);
        }

        .header-meta-grid {
          display: grid;
          grid-template-columns: 1fr 1fr 1fr;
          gap: var(--spacing-4);
        }

        .card-header-flex .panel-title {
          margin-bottom: 0;
          padding-bottom: 0;
          border-bottom: none;
        }

        .item-builder-grid.mixed-grid {
          grid-template-columns: 2fr 1fr 1fr 0.8fr 1fr 100px;
        }

        .type-badge-sm {
          display: inline-flex;
          align-items: center;
          gap: 4px;
          padding: 2px 8px;
          border-radius: 4px;
          font-size: 10px;
          font-weight: 800;
        }

        .type-badge-sm.IN { background: var(--success-50); color: var(--success-700); }
        .type-badge-sm.OUT { background: var(--danger-50); color: var(--danger-700); }

        .row-in { background-color: rgba(16, 185, 129, 0.02); }
        .row-out { background-color: rgba(239, 68, 68, 0.02); }

        .transaction-footer-unified {
          display: flex;
          justify-content: space-between;
          align-items: flex-end;
          margin-top: var(--spacing-8);
          padding-top: var(--spacing-6);
          border-top: 2px solid var(--neutral-100);
        }

        .total-calculation-summary {
          min-width: 300px;
          display: flex;
          flex-direction: column;
          gap: 8px;
        }

        .calc-row {
          display: flex;
          justify-content: space-between;
          font-size: 0.875rem;
          color: var(--neutral-500);
        }

        .calc-row.grand-net {
          margin-top: 8px;
          padding-top: 8px;
          border-top: 1px dashed var(--neutral-200);
          color: var(--neutral-800);
          font-size: 1.125rem;
        }

        .submit-batch-btn {
          height: 54px;
          padding: 0 40px;
          font-size: 1rem;
          border-radius: 12px;
          box-shadow: 0 8px 16px rgba(13, 148, 136, 0.15);
        }

        .history-filters-container {
          display: flex;
          align-items: center;
          gap: var(--spacing-4);
          justify-content: flex-end;
          flex-wrap: wrap;
        }

        .filter-field-group {
          display: flex;
          flex-direction: column;
          gap: 6px;
          min-width: 140px;
        }

        .filter-field-group.action-group {
          min-width: 160px;
        }

        .field-label {
          font-size: 10px;
          font-weight: 800;
          color: var(--neutral-400);
          text-transform: uppercase;
          letter-spacing: 0.05em;
        }

        .history-filter-select :global(.input-group) {
          margin-bottom: 0;
        }

        .history-filter-select :global(.select) {
          padding: 8px 12px;
          height: 38px;
          font-size: 13px;
          border-radius: 8px;
          border: 1px solid var(--neutral-200);
          background-position: right 10px center;
        }

        .history-date-input {
          height: 38px;
          padding: 8px 12px;
          border: 1px solid var(--neutral-200);
          border-radius: 8px;
          font-size: 13px;
          color: var(--neutral-700);
          outline: none;
          background: white;
          transition: border-color 0.2s;
        }

        .history-date-input:focus {
          border-color: var(--primary-500);
        }

        @media (max-width: 1024px) {
          .header-meta-grid {
            grid-template-columns: 1fr;
          }
          .item-builder-grid.mixed-grid {
            grid-template-columns: 1fr 1fr;
          }
          .transaction-footer-unified {
            flex-direction: column;
            gap: 24px;
            align-items: stretch;
          }
        }
      `}</style>
    </PageContainer>
  );
};

export default Inventory;
