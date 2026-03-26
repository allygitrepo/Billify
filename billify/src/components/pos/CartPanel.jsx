import React from 'react';
import { formatCurrency } from '../../utils/formatCurrency';

const CartPanel = ({ cart, onUpdateQty, onRemove, onCheckout, discount, onDiscountChange, settings }) => {
  const [paymentMethod, setPaymentMethod] = React.useState('Cash');
  const [customerName, setCustomerName] = React.useState('');
  const [customerPhone, setCustomerPhone] = React.useState('');
  const subtotal = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
  const taxRate = parseFloat(settings.taxPercentage || 0) / 100;
  const gstRate = parseFloat(settings.gstPercentage || 0) / 100;
  
  const taxAmount = subtotal * taxRate;
  const gstAmount = subtotal * gstRate;
  const total = subtotal + taxAmount + gstAmount - (parseFloat(discount) || 0);

  return (
    <div className="cart-panel">
      <div className="cart-header">
        <h3 className="panel-title">Current Order</h3>
        <span className="item-count">{cart.length} items</span>
      </div>

      <div className="cart-items">
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

      <div className="payment-section">
        <div className="customer-info-section">
          <p className="pay-label">Customer Info (Optional)</p>
          <div className="customer-inputs" style={{ marginBottom: '16px' }}>
            <input 
              type="text" 
              placeholder="Customer Name" 
              value={customerName}
              onChange={(e) => setCustomerName(e.target.value)}
              className="pos-input"
              style={{ width: '100%', marginBottom: '8px', padding: '10px', borderRadius: '8px', border: '1px solid var(--neutral-200)' }}
            />
            <input 
              type="text" 
              placeholder="Mobile Number" 
              value={customerPhone}
              onChange={(e) => setCustomerPhone(e.target.value)}
              className="pos-input"
              style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid var(--neutral-200)' }}
            />
          </div>
        </div>

        <p className="pay-label">Select Payment Method</p>
        <div className="pay-methods">
          <button 
            className={`pay-btn ${paymentMethod === 'Cash' ? 'active' : ''}`}
            onClick={() => setPaymentMethod('Cash')}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="6" width="20" height="12" rx="2"></rect><circle cx="12" cy="12" r="2"></circle><path d="M6 12h.01M18 12h.01"></path></svg>
            Cash
          </button>
          <button 
            className={`pay-btn ${paymentMethod === 'UPI' ? 'active' : ''}`}
            onClick={() => setPaymentMethod('UPI')}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
            UPI
          </button>
          <button 
            className={`pay-btn ${paymentMethod === 'Card' ? 'active' : ''}`}
            onClick={() => setPaymentMethod('Card')}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"></rect><line x1="1" y1="10" x2="23" y2="10"></line></svg>
            Card
          </button>
        </div>
        <button 
          className="btn btn-primary complete-btn" 
          disabled={cart.length === 0}
          onClick={() => onCheckout(paymentMethod, { customerName, customerPhone })}
        >
          Complete Payment
        </button>
      </div>
    </div>
  );
};

export default CartPanel;
