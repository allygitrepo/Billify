import React from 'react';
import { formatCurrency } from '../../utils/formatCurrency';

const CartPanel = ({ 
  cart, 
  onUpdateQty, 
  onRemove, 
  onCheckout, 
  discount, 
  onDiscountChange, 
  settings,
  customers,
  selectedCustomer,
  onSelectCustomer,
  paymentMode,
  onPaymentModeChange,
  paidAmount,
  onPaidAmountChange
}) => {
  const [isCustomerSearchOpen, setIsCustomerSearchOpen] = React.useState(false);
  const [customerSearch, setCustomerSearch] = React.useState('');

  const subtotal = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
  const taxRate = parseFloat(settings.taxPercentage || 0) / 100;
  const gstRate = parseFloat(settings.gstPercentage || 0) / 100;
  
  const taxAmount = subtotal * taxRate;
  const gstAmount = subtotal * gstRate;
  const total = subtotal + taxAmount + gstAmount - (parseFloat(discount) || 0);

  const remainingToKhata = total - (parseFloat(paidAmount) || 0);

  const filteredCustomers = customers.filter(c => 
    c.name.toLowerCase().includes(customerSearch.toLowerCase()) || 
    c.phone?.includes(customerSearch)
  );

  return (
    <div className="cart-panel animate-slide-in-right">
      <div className="cart-header" style={{ paddingBottom: '0.5rem' }}>
        <h3 className="panel-title">Checkout Terminal</h3>
        <span className="item-count">{cart.length} items</span>
      </div>

      {/* Customer Selection Section */}
      <div className="customer-selector-container" style={{ margin: '0 1rem 1rem 1rem', position: 'relative' }}>
        {selectedCustomer ? (
          <div className="selected-customer-card animate-scale-in" style={{ 
            background: 'var(--primary-50)', 
            border: '1px solid var(--primary-200)', 
            padding: '12px', 
            borderRadius: '12px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <div style={{ width: '32px', height: '32px', borderRadius: '8px', background: 'var(--primary-500)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700 }}>
                {selectedCustomer.name[0]}
              </div>
              <div>
                <div style={{ fontWeight: 700, fontSize: '0.875rem', color: 'var(--primary-900)' }}>{selectedCustomer.name}</div>
                <div style={{ fontSize: '0.75rem', color: 'var(--primary-600)' }}>{selectedCustomer.phone} • Balance: {formatCurrency(selectedCustomer.opening_balance)}</div>
              </div>
            </div>
            <button 
              onClick={() => onSelectCustomer(null)}
              style={{ background: 'white', border: '1px solid var(--primary-200)', padding: '4px', borderRadius: '6px', color: 'var(--primary-600)', cursor: 'pointer' }}
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
            </button>
          </div>
        ) : (
          <div style={{ position: 'relative' }}>
            <button 
              className="btn-select-customer"
              onClick={() => setIsCustomerSearchOpen(!isCustomerSearchOpen)}
              style={{
                width: '100%',
                padding: '12px',
                borderRadius: '12px',
                border: '2px dashed var(--neutral-200)',
                background: 'white',
                color: 'var(--neutral-500)',
                fontWeight: 600,
                fontSize: '0.875rem',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '8px',
                cursor: 'pointer',
                transition: 'all 0.2s'
              }}
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle><line x1="12" y1="11" x2="12" y2="17"></line><line x1="9" y1="14" x2="15" y2="14"></line></svg>
              Select Registered Customer
            </button>

            {isCustomerSearchOpen && (
              <div className="customer-dropdown animate-fade-in" style={{
                position: 'absolute',
                top: '100%',
                left: 0,
                right: 0,
                background: 'white',
                borderRadius: '12px',
                boxShadow: '0 10px 25px rgba(0,0,0,0.1)',
                zIndex: 100,
                marginTop: '8px',
                border: '1px solid var(--neutral-100)',
                overflow: 'hidden'
              }}>
                <div style={{ padding: '8px' }}>
                  <input 
                    autoFocus
                    type="text"
                    placeholder="Search by name or phone..."
                    value={customerSearch}
                    onChange={(e) => setCustomerSearch(e.target.value)}
                    style={{ width: '100%', padding: '10px 12px', borderRadius: '8px', border: '1px solid var(--neutral-200)', fontSize: '0.875rem', outline: 'none' }}
                  />
                </div>
                <div style={{ maxHeight: '200px', overflowY: 'auto' }}>
                  {filteredCustomers.length === 0 ? (
                    <div style={{ padding: '20px', textAlign: 'center', color: 'var(--neutral-400)', fontSize: '0.875rem' }}>No customers found</div>
                  ) : (
                    filteredCustomers.map(c => (
                      <div 
                        key={c.id} 
                        className="dropdown-item"
                        onClick={() => {
                          onSelectCustomer(c);
                          setIsCustomerSearchOpen(false);
                          setCustomerSearch('');
                        }}
                        style={{ padding: '10px 16px', cursor: 'pointer', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid var(--neutral-50)' }}
                      >
                        <div>
                          <div style={{ fontWeight: 600, fontSize: '0.875rem' }}>{c.name}</div>
                          <div style={{ fontSize: '0.75rem', color: 'var(--neutral-400)' }}>{c.phone}</div>
                        </div>
                        <div style={{ fontSize: '0.8125rem', fontWeight: 700, color: 'var(--danger-500)' }}>
                          {formatCurrency(c.opening_balance)}
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </div>
            )}
          </div>
        )}
      </div>

      <div className="cart-items" style={{ flex: 1 }}>
        {cart.length === 0 ? (
          <div className="empty-cart">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1" strokeLinecap="round" strokeLinejoin="round" style={{color: 'var(--neutral-300)', marginBottom: 'var(--spacing-4)'}}>
              <circle cx="9" cy="21" r="1"></circle>
              <circle cx="20" cy="21" r="1"></circle>
              <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>
            </svg>
            <p>Your cart is empty</p>
          </div>
        ) : (
          cart.map(item => (
            <div key={item.cartItemId} className="cart-item">
              <div className="item-details">
                <span className="item-name">{item.name}</span>
                <span className="item-variant">{item.variantName}</span>
              </div>
              <div className="item-actions">
                <div className="qty-controls">
                  <button onClick={() => onUpdateQty(item.cartItemId, -1)} aria-label="Decrease quantity">−</button>
                  <span className="qty-val">{item.quantity}</span>
                  <button onClick={() => onUpdateQty(item.cartItemId, 1)} aria-label="Increase quantity">+</button>
                </div>
                <div className="item-price">
                  <span>{formatCurrency(item.price * item.quantity)}</span>
                  <button className="remove-btn" onClick={() => onRemove(item.cartItemId)} aria-label="Remove item">×</button>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      <div className="cart-summary">
        <div className="summary-row">
          <span className="summary-label">Subtotal</span>
          <div className="summary-leader"></div>
          <span className="summary-value">{formatCurrency(subtotal)}</span>
        </div>
        <div className="summary-row">
          <span className="summary-label">Tax ({settings.taxPercentage || 0}%)</span>
          <div className="summary-leader"></div>
          <span className="summary-value">{formatCurrency(taxAmount)}</span>
        </div>
        <div className="summary-row">
          <span className="summary-label">GST ({settings.gstPercentage || 0}%)</span>
          <div className="summary-leader"></div>
          <span className="summary-value">{formatCurrency(gstAmount)}</span>
        </div>
        <div className="summary-row discount">
          <span className="summary-label">Discount (₹)</span>
          <div className="summary-leader"></div>
          <input 
            type="number" 
            value={discount} 
            onChange={(e) => onDiscountChange(e.target.value)}
            placeholder="0"
          />
        </div>
      </div>

      <div className="cart-total-box">
        <span className="cart-total-label">Total Amount</span>
        <span className="cart-total-value">{formatCurrency(total > 0 ? total : 0)}</span>
      </div>

      <div className="payment-section" style={{ background: 'var(--neutral-50)', padding: '1.25rem', borderTop: '1px solid var(--neutral-100)' }}>
        <p className="pay-label" style={{ marginBottom: '12px' }}>Choose Billing Mode</p>
        
        <div className="payment-mode-grid" style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '8px', marginBottom: '1rem' }}>
          <button 
            className={`mode-btn ${paymentMode === 'CASH' ? 'active' : ''}`}
            onClick={() => onPaymentModeChange('CASH')}
            style={{ 
              padding: '10px 4px', 
              borderRadius: '10px', 
              border: paymentMode === 'CASH' ? '2px solid var(--success-500)' : '2px solid var(--neutral-200)',
              background: paymentMode === 'CASH' ? 'var(--success-50)' : 'white',
              color: paymentMode === 'CASH' ? 'var(--success-700)' : 'var(--neutral-500)',
              fontSize: '0.75rem',
              fontWeight: 700,
              cursor: 'pointer'
            }}
          >
            PAID
          </button>
          <button 
            className={`mode-btn ${paymentMode === 'KHATA' ? 'active' : ''}`}
            disabled={!selectedCustomer}
            onClick={() => onPaymentModeChange('KHATA')}
            style={{ 
              padding: '10px 4px', 
              borderRadius: '10px', 
              border: paymentMode === 'KHATA' ? '2px solid var(--danger-500)' : '2px solid var(--neutral-200)',
              background: paymentMode === 'KHATA' ? 'var(--danger-50)' : 'white',
              color: paymentMode === 'KHATA' ? 'var(--danger-700)' : 'var(--neutral-500)',
              fontSize: '0.75rem',
              fontWeight: 700,
              cursor: 'pointer',
              opacity: selectedCustomer ? 1 : 0.5
            }}
          >
            KHATA
          </button>
          <button 
            className={`mode-btn ${paymentMode === 'SPLIT' ? 'active' : ''}`}
            disabled={!selectedCustomer}
            onClick={() => onPaymentModeChange('SPLIT')}
            style={{ 
              padding: '10px 4px', 
              borderRadius: '10px', 
              border: paymentMode === 'SPLIT' ? '2px solid var(--warning-500)' : '2px solid var(--neutral-200)',
              background: paymentMode === 'SPLIT' ? 'var(--warning-50)' : 'white',
              color: paymentMode === 'SPLIT' ? 'var(--warning-700)' : 'var(--neutral-500)',
              fontSize: '0.75rem',
              fontWeight: 700,
              cursor: 'pointer',
              opacity: selectedCustomer ? 1 : 0.5
            }}
          >
            SPLIT
          </button>
        </div>

        {paymentMode === 'SPLIT' && (
          <div className="split-entry animate-fade-in" style={{ marginBottom: '1rem', background: 'white', padding: '12px', borderRadius: '12px', border: '1px solid var(--warning-100)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
              <span style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--neutral-500)' }}>Received Amount (₹)</span>
              <input 
                type="number"
                value={paidAmount}
                autoFocus
                onChange={(e) => onPaidAmountChange(e.target.value)}
                placeholder="0.00"
                style={{ width: '100px', border: 'none', borderBottom: '2px solid var(--warning-400)', outline: 'none', textAlign: 'right', fontWeight: 700, padding: '4px' }}
              />
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: '4px' }}>
              <span style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--danger-500)' }}>Balance to Khata</span>
              <span style={{ fontSize: '0.875rem', fontWeight: 700, color: 'var(--danger-700)' }}>{formatCurrency(remainingToKhata > 0 ? remainingToKhata : 0)}</span>
            </div>
          </div>
        )}

        <button 
          className={`btn complete-btn ${cart.length === 0 ? 'disabled' : 'btn-primary'}`}
          disabled={cart.length === 0}
          onClick={() => onCheckout('Cash')}
          style={{ width: '100%', height: '52px', fontSize: '1.125rem', borderRadius: '14px', boxShadow: cart.length > 0 ? '0 8px 24px rgba(var(--primary-rgb), 0.25)' : 'none' }}
        >
          {paymentMode === 'CASH' ? 'Confirm Sale (PAID)' : paymentMode === 'KHATA' ? 'Add to Khata (CREDIT)' : 'Confirm Split Entry'}
        </button>
      </div>

      <style jsx>{`
        .btn-select-customer:hover { border-color: var(--primary-300); color: var(--primary-500); background: var(--primary-50); }
        .dropdown-item:hover { background: var(--neutral-50); }
        .mode-btn:hover:not(:disabled) { border-color: var(--neutral-300); }
      `}</style>
    </div>
  );
};


export default CartPanel;
