import React from 'react';
import { formatCurrency } from '../../utils/formatCurrency';

const CartPanel = ({ cart, onUpdateQty, onRemove, onCheckout, discount, onDiscountChange, settings }) => {
  const [paymentMethod, setPaymentMethod] = React.useState('Cash');
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
          <span>Subtotal</span>
          <span>{formatCurrency(subtotal)}</span>
        </div>
        <div className="summary-row">
          <span>Tax ({settings.taxPercentage || 0}%)</span>
          <span>{formatCurrency(taxAmount)}</span>
        </div>
        <div className="summary-row">
          <span>GST ({settings.gstPercentage || 0}%)</span>
          <span>{formatCurrency(gstAmount)}</span>
        </div>
        <div className="summary-row discount">
          <span>Discount (₹)</span>
          <input 
            type="number" 
            value={discount} 
            onChange={(e) => onDiscountChange(e.target.value)}
            placeholder="0"
          />
        </div>
        <div className="summary-row total">
          <span>Total Amount</span>
          <span>{formatCurrency(total > 0 ? total : 0)}</span>
        </div>
      </div>

      <div className="payment-section">
        <p className="pay-label">Select Payment Method</p>
        <div className="pay-methods">
          <button 
            className={`pay-btn ${paymentMethod === 'Cash' ? 'active' : ''}`}
            onClick={() => setPaymentMethod('Cash')}
          >
            Cash
          </button>
          <button 
            className={`pay-btn ${paymentMethod === 'UPI' ? 'active' : ''}`}
            onClick={() => setPaymentMethod('UPI')}
          >
            UPI
          </button>
          <button 
            className={`pay-btn ${paymentMethod === 'Card' ? 'active' : ''}`}
            onClick={() => setPaymentMethod('Card')}
          >
            Card
          </button>
        </div>
        <button 
          className="btn btn-primary complete-btn" 
          disabled={cart.length === 0}
          onClick={() => onCheckout(paymentMethod)}
        >
          Complete Payment
        </button>
      </div>
    </div>
  );
};

export default CartPanel;
