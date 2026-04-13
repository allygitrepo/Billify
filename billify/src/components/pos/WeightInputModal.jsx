import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { useDataContext } from '../../hooks/useDataContext';
import { formatCurrency } from '../../utils/formatCurrency';

const WeightInputModal = ({ product, variant, onClose, onAdd }) => {
  const { uoms = [] } = useDataContext();
  const [quantity, setQuantity] = useState('');
  const [error, setError] = useState('');

  // Resolve UOM (Matching Mobile Logic)
  const getUomSymbol = (p) => {
    const rawUom = p.uom;
    const found = uoms.find(u => u.id === rawUom || u.id === parseInt(rawUom));
    if (found) return (found.shortCode || found.name).toUpperCase();
    return (rawUom || 'KG').toString().toUpperCase();
  };

  const baseUom = getUomSymbol(product);
  
  // Determine sub-unit (Matching weight_input_sheet.dart logic)
  const getSubUnitInfo = (baseUnit) => {
    if (baseUnit === 'KG') {
      return { symbol: 'GM', factor: 1000.0 };
    } else if (baseUnit === 'LTR' || baseUnit === 'L' || baseUnit === 'LITRE') {
      return { symbol: 'ML', factor: 1000.0 };
    }
    return null;
  };

  const subUnitInfo = getSubUnitInfo(baseUom);
  const [isSubUnit, setIsSubUnit] = useState(false);

  const activeUnit = (isSubUnit && subUnitInfo) ? subUnitInfo.symbol : baseUom;
  const conversionFactor = (isSubUnit && subUnitInfo) ? subUnitInfo.factor : 1.0;

  const price = variant ? variant.price : product.price;
  const stock = variant ? (variant.current_stock ?? variant.stock) : (product.current_stock ?? product.opening_stock);
  
  // Calculate display price and converted quantity
  const displayPrice = price / conversionFactor;
  const totalPrice = (parseFloat(quantity) || 0) * displayPrice;

  const handleConfirm = () => {
    const qtyValue = parseFloat(quantity);
    if (!qtyValue || qtyValue <= 0) {
      setError(`Quantity must be greater than zero`);
      return;
    }

    // Convert back to base unit (enteredValue / conversionFactor)
    const baseQty = qtyValue / conversionFactor;

    if (baseQty > stock) {
      setError(`Insufficient stock! Only ${stock} ${baseUom} available.`);
      return;
    }

    onAdd(product, variant, baseQty);
    onClose();
  };

  const handleQuantityChange = (e) => {
    const val = e.target.value;
    if (val === '') {
      setQuantity('');
      setError('');
      return;
    }

    // Prevent negative
    if (parseFloat(val) < 0) return;

    // Max 3 decimal places (Matching mobile parity)
    if (val.includes('.')) {
      const parts = val.split('.');
      if (parts[1] && parts[1].length > 3) return;
    }

    setQuantity(val);
    setError('');
  };

  return createPortal(
    <AnimatePresence>
      <div className="modal-root">
        <motion.div
          className="modal-overlay"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
        />
        <motion.div
          className="modal-container"
          style={{ maxWidth: '400px' }}
          initial={{ opacity: 0, scale: 0.95, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 20 }}
          transition={{ type: 'spring', damping: 25, stiffness: 300 }}
        >
          <div className="modal-header">
            <h3 className="modal-title">Loose Item Entry</h3>
            <button className="modal-close-btn" onClick={onClose}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
              </svg>
            </button>
          </div>

          <div className="modal-content">
            <div style={{ textAlign: 'center', marginBottom: '1.25rem' }}>
              <div style={{ fontSize: '1.125rem', fontWeight: 700, color: 'var(--neutral-800)' }}>{product.name}</div>
              {variant && variant.name !== 'Standard' && (
                <div style={{ fontSize: '0.875rem', color: 'var(--neutral-500)' }}>{variant.name}</div>
              )}
              <div style={{ fontSize: '0.875rem', color: 'var(--primary-600)', fontWeight: 600, marginTop: '4px' }}>
                Rate: {formatCurrency(displayPrice)} / {activeUnit}
              </div>
            </div>

            {/* Unit Selection Toggle (Matching Mobile Parity) */}
            {subUnitInfo && (
              <div style={{ display: 'flex', background: 'var(--neutral-100)', padding: '4px', borderRadius: '10px', marginBottom: '1.5rem' }}>
                <button
                  onClick={() => setIsSubUnit(false)}
                  style={{
                    flex: 1,
                    padding: '8px',
                    borderRadius: '8px',
                    border: 'none',
                    fontSize: '0.875rem',
                    fontWeight: 700,
                    cursor: 'pointer',
                    background: !isSubUnit ? 'var(--primary-500)' : 'transparent',
                    color: !isSubUnit ? 'white' : 'var(--neutral-500)',
                    boxShadow: !isSubUnit ? '0 2px 4px rgba(0,0,0,0.1)' : 'none',
                    transition: 'all 0.2s'
                  }}
                >
                  {baseUom}
                </button>
                <button
                  onClick={() => setIsSubUnit(true)}
                  style={{
                    flex: 1,
                    padding: '8px',
                    borderRadius: '8px',
                    border: 'none',
                    fontSize: '0.875rem',
                    fontWeight: 700,
                    cursor: 'pointer',
                    background: isSubUnit ? 'var(--primary-500)' : 'transparent',
                    color: isSubUnit ? 'white' : 'var(--neutral-500)',
                    boxShadow: isSubUnit ? '0 2px 4px rgba(0,0,0,0.1)' : 'none',
                    transition: 'all 0.2s'
                  }}
                >
                  {subUnitInfo.symbol}
                </button>
              </div>
            )}

            <div className="form-group" style={{ marginBottom: '1.5rem' }}>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, color: 'var(--neutral-500)', textTransform: 'uppercase', marginBottom: '8px' }}>
                Quantity in {activeUnit}
              </label>
              <div style={{ position: 'relative' }}>
                <input
                  autoFocus
                  type="number"
                  min="0"
                  step="0.001"
                  placeholder="0.000"
                  value={quantity}
                  onChange={handleQuantityChange}
                  onKeyDown={(e) => e.key === 'Enter' && handleConfirm()}
                  className="no-spinners"
                  style={{
                    width: '100%',
                    padding: '1rem',
                    fontSize: '2rem',
                    fontWeight: 800,
                    textAlign: 'center',
                    borderRadius: '12px',
                    border: error ? '2px solid var(--danger-500)' : '2px solid var(--neutral-200)',
                    outline: 'none',
                    backgroundColor: 'var(--neutral-50)',
                    transition: 'all 0.2s'
                  }}
                />
                <div style={{ position: 'absolute', right: '1rem', top: '50%', transform: 'translateY(-50%)', fontWeight: 700, color: 'var(--neutral-400)', fontSize: '1.125rem' }}>
                  {activeUnit}
                </div>
              </div>
              {error && (
                <div style={{ color: 'var(--danger-500)', fontSize: '0.75rem', marginTop: '8px', fontWeight: 600, textAlign: 'center' }}>
                  {error}
                </div>
              )}
            </div>

            <style dangerouslySetInnerHTML={{ __html: `
              input.no-spinners::-webkit-outer-spin-button,
              input.no-spinners::-webkit-inner-spin-button {
                -webkit-appearance: none;
                margin: 0;
              }
              input.no-spinners[type=number] {
                -moz-appearance: textfield;
              }
            `}} />

            <div style={{ background: 'var(--primary-50)', padding: '1.25rem', borderRadius: '12px', marginBottom: '1.5rem', display: 'flex', flexDirection: 'column', gap: '4px', border: '1px solid var(--primary-100)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.875rem', color: 'var(--neutral-500)' }}>
                <span>Rate per {baseUom}</span>
                <span>{formatCurrency(price)}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontWeight: 700, color: 'var(--primary-700)' }}>Subtotal</span>
                <span style={{ fontSize: '1.5rem', fontWeight: 900, color: 'var(--primary-800)' }}>
                  {formatCurrency(totalPrice)}
                </span>
              </div>
            </div>

            <button
              className="btn btn-primary"
              style={{ width: '100%', padding: '1rem', height: 'auto', borderRadius: '14px', fontSize: '1.125rem', fontWeight: 700, boxShadow: '0 4px 12px rgba(var(--primary-rgb), 0.3)' }}
              onClick={handleConfirm}
            >
              Add to Cart
            </button>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>,
    document.body
  );
};

export default WeightInputModal;


