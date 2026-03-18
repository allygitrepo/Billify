import React, { useState, useMemo } from 'react';
import { useDataContext } from '../../hooks/useDataContext';
import PageContainer from '../../components/layout/PageContainer';
import Select from '../../components/common/Select';
import Input from '../../components/common/Input';
import Button from '../../components/common/Button';
import Table from '../../components/common/Table';
import { formatDate } from '../../utils/formatDate';

const Inventory = () => {
  const { products, inventoryLog, addInventoryEntry } = useDataContext();

  const [filterType, setFilterType] = useState('all');
  const [filterDate, setFilterDate] = useState('');

  // Form States
  const [inForm, setInForm] = useState({ productId: '', variantName: '', quantity: '', reason: 'Purchase' });
  const [outForm, setOutForm] = useState({ productId: '', variantName: '', quantity: '', reason: 'Sale' });
  const [inErrors, setInErrors] = useState({});
  const [outErrors, setOutErrors] = useState({});

  // Product Helper
  const getVariants = (productId) => {
    const product = products.find(p => p.id === productId);
    return product ? product.variants.map(v => ({ label: v.name, value: v.name })) : [];
  };

  const handleStockUpdate = (formType) => {
    const form = formType === 'IN' ? inForm : outForm;
    const errors = {};
    
    if (!form.productId) errors.productId = 'Product required';
    if (!form.variantName) errors.variantName = 'Variant required';
    if (!form.quantity || isNaN(form.quantity) || parseFloat(form.quantity) <= 0) errors.quantity = 'Invalid qty';

    if (Object.keys(errors).length > 0) {
      formType === 'IN' ? setInErrors(errors) : setOutErrors(errors);
      return;
    }

    const selectedProduct = products.find(p => p.id === form.productId);
    
    const qty = parseFloat(form.quantity);
    const change = formType === 'IN' ? qty : -qty;

    addInventoryEntry({
      productId: selectedProduct.id,
      productName: selectedProduct.name,
      variantName: form.variantName,
      type: formType,
      quantityChange: change,
      reason: form.reason
    });
    
    // Reset
    if (formType === 'IN') {
      setInForm({ productId: '', variantName: '', quantity: '', reason: 'Purchase' });
      setInErrors({});
    } else {
      setOutForm({ productId: '', variantName: '', quantity: '', reason: 'Sale' });
      setOutErrors({});
    }
  };

  const filteredLogs = useMemo(() => {
    return inventoryLog.filter(log => {
      const matchesType = filterType === 'all' || log.type === filterType;
      const matchesDate = !filterDate || formatDate(log.date).includes(filterDate); 
      return matchesType && matchesDate;
    });
  }, [inventoryLog, filterType, filterDate]);

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
    { key: 'doneBy', label: 'Done By' },
    { 
      key: 'date', 
      label: 'Date & Time',
      render: (val) => {
        const d = new Date(val);
        return formatDate(val) + ' ' + d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      }
    }
  ];

  return (
    <PageContainer title="Inventory Management">
      <div className="animate-fade-in">
        {/* IN / OUT Panels */}
        <div className="inventory-panels">
          <div className="card inventory-panel in">
            <h3 className="panel-title text-success">Stock IN (Receive)</h3>
            <div className="panel-form">
              <Select 
                label="Product" 
                value={inForm.productId} 
                onChange={(e) => setInForm({...inForm, productId: e.target.value, variantName: ''})} 
                options={products.map(p => ({ label: p.name, value: p.id }))}
                error={inErrors.productId}
              />
              <Select 
                label="Variant" 
                value={inForm.variantName} 
                onChange={(e) => setInForm({...inForm, variantName: e.target.value})} 
                options={getVariants(inForm.productId)}
                disabled={!inForm.productId}
                error={inErrors.variantName}
              />
              <Input 
                label="Quantity" 
                type="number" 
                value={inForm.quantity} 
                onChange={(e) => setInForm({...inForm, quantity: e.target.value})}
                error={inErrors.quantity}
              />
              <Select 
                label="Reason" 
                value={inForm.reason} 
                onChange={(e) => setInForm({...inForm, reason: e.target.value})}
                options={[{label: 'Purchase', value: 'Purchase'}, {label: 'Adjustment', value: 'Adjustment'}]}
              />
              <Button onClick={() => handleStockUpdate('IN')} className="w-full btn-success">Add Stock</Button>
            </div>
          </div>

          <div className="card inventory-panel out">
            <h3 className="panel-title text-danger">Stock OUT (Reduce)</h3>
            <div className="panel-form">
              <Select 
                label="Product" 
                value={outForm.productId} 
                onChange={(e) => setOutForm({...outForm, productId: e.target.value, variantName: ''})} 
                options={products.map(p => ({ label: p.name, value: p.id }))}
                error={outErrors.productId}
              />
              <Select 
                label="Variant" 
                value={outForm.variantName} 
                onChange={(e) => setOutForm({...outForm, variantName: e.target.value})} 
                options={getVariants(outForm.productId)}
                disabled={!outForm.productId}
                error={outErrors.variantName}
              />
              <Input 
                label="Quantity" 
                type="number" 
                value={outForm.quantity} 
                onChange={(e) => setOutForm({...outForm, quantity: e.target.value})}
                error={outErrors.quantity}
              />
              <Select 
                label="Reason" 
                value={outForm.reason} 
                onChange={(e) => setOutForm({...outForm, reason: e.target.value})}
                options={[
                  {label: 'Sale', value: 'Sale'}, 
                  {label: 'Damage', value: 'Damage'}, 
                  {label: 'Expiry', value: 'Expiry'},
                  {label: 'Return', value: 'Return'}
                ]}
              />
              <Button onClick={() => handleStockUpdate('OUT')} className="w-full btn-danger">Reduce Stock</Button>
            </div>
          </div>
        </div>

        {/* Inventory Log */}
        <div className="card">
          <div className="table-controls">
            <h3 className="card-title">Inventory Log</h3>
            <div className="filters-row">
              <Select 
                value={filterType} 
                onChange={(e) => setFilterType(e.target.value)}
                options={[{label: 'All Types', value: 'all'}, {label: 'Stock IN', value: 'IN'}, {label: 'Stock OUT', value: 'OUT'}]}
                placeholder={null}
                style={{ marginBottom: 0 }}
              />
              <Input 
                type="date"
                value={filterDate}
                onChange={(e) => setFilterDate(e.target.value)}
                style={{ marginBottom: 0 }}
              />
            </div>
          </div>
          <Table columns={columns} data={filteredLogs} />
        </div>
      </div>
    </PageContainer>
  );
};

export default Inventory;
