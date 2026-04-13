import React from 'react';
import Modal from '../common/Modal';
import Button from '../common/Button';
import { formatDate } from '../../utils/formatDate';
import { formatCurrency } from '../../utils/formatCurrency';

const InvoiceModal = ({ isOpen, onClose, transaction, settings, user, onPrint }) => {
  if (!transaction) return null;

  return (
    <Modal 
      isOpen={isOpen} 
      onClose={onClose}
      title={null}
      maxWidth="500px"
      padding="0"
    >
      <div className="voucher-modal animate-fade-in">
        <div className="voucher-header">
          <div className="voucher-badge">
            {transaction.type === 'Quotation' ? 'QUOTATION' : 'TAX INVOICE'}
          </div>
          <button className="close-btn" onClick={onClose}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
          </button>
        </div>

        <div className="voucher-body">
          <div className="voucher-business-header" style={{ textAlign: 'center', marginBottom: '24px' }}>
            {settings.photo && (
              <img src={settings.photo} alt="Logo" style={{ maxWidth: '100px', maxHeight: '60px', marginBottom: '12px' }} />
            )}
            <h2 style={{ margin: 0, fontSize: '1.25rem', fontWeight: 800 }}>{settings.businessName || 'Billify POS'}</h2>
            <p style={{ margin: '4px 0', fontSize: '0.75rem', color: 'var(--neutral-500)' }}>{settings.address}</p>
            {settings.gstNumber && <p style={{ margin: 0, fontSize: '0.75rem', fontWeight: 600 }}>GSTIN: {settings.gstNumber}</p>}
          </div>

          <div className="voucher-main-info">
            <div className="info-group">
              <label>Invoice No</label>
              <span>{transaction.id || transaction.invoice_number}</span>
            </div>
            <div className="info-group text-right">
              <label>Date & Time</label>
              <span>{formatDate(transaction.date)}</span>
            </div>
          </div>

          <div className="voucher-party-info card" style={{ background: 'var(--neutral-50)', padding: '12px', borderRadius: '12px', display: 'flex', gap: '16px', marginBottom: '24px' }}>
            <div style={{ flex: 1 }}>
              <label style={{ display: 'block', fontSize: '10px', fontWeight: 700, color: 'var(--neutral-400)', textTransform: 'uppercase' }}>Customer</label>
              <p style={{ margin: 0, fontWeight: 700, fontSize: '0.875rem' }}>{transaction.customerName || 'Walking Customer'}</p>
            </div>
            <div style={{ width: '1px', background: 'var(--neutral-200)' }}></div>
            <div style={{ flex: 1 }}>
              <label style={{ display: 'block', fontSize: '10px', fontWeight: 700, color: 'var(--neutral-400)', textTransform: 'uppercase' }}>Payment</label>
              <p style={{ margin: 0, fontWeight: 700, fontSize: '0.875rem' }}>{transaction.paymentMethod || 'Cash'}</p>
            </div>
          </div>

          <div className="voucher-item-details card" style={{ border: '1px solid var(--neutral-100)', borderRadius: '12px', overflow: 'hidden', marginBottom: '24px' }}>
            <div className="item-row header" style={{ display: 'grid', gridTemplateColumns: '2.5fr 0.6fr 1.2fr 1.2fr', gap: '12px', padding: '10px 16px', background: 'var(--neutral-50)', fontSize: '10px', fontWeight: 800, color: 'var(--neutral-500)' }}>
              <span>ITEM</span>
              <span style={{ textAlign: 'right' }}>QTY</span>
              <span style={{ textAlign: 'right' }}>PRICE</span>
              <span style={{ textAlign: 'right' }}>TOTAL</span>
            </div>
            {(transaction.items || []).map((item, idx) => (
              <div key={idx} className="item-row" style={{ display: 'grid', gridTemplateColumns: '2.5fr 0.6fr 1.2fr 1.2fr', gap: '12px', padding: '12px 16px', borderBottom: '1px solid var(--neutral-50)', fontSize: '0.875rem' }}>
                <span style={{ fontWeight: 600 }}>{item.name || item.productName}</span>
                <span style={{ textAlign: 'right' }}>{item.quantity}</span>
                <span style={{ textAlign: 'right' }}>{formatCurrency(item.price)}</span>
                <span style={{ textAlign: 'right', fontWeight: 700 }}>{formatCurrency(item.price * item.quantity)}</span>
              </div>
            ))}
          </div>

          <div className="voucher-summary" style={{ borderTop: '2px dashed var(--neutral-200)', paddingTop: '16px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', marginBottom: '8px', color: 'var(--neutral-500)' }}>
              <span>Subtotal</span>
              <span>{formatCurrency(transaction.subtotal)}</span>
            </div>
            {transaction.tax > 0 && (
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', marginBottom: '4px', color: 'var(--neutral-500)' }}>
                <span>Tax</span>
                <span>{formatCurrency(transaction.tax)}</span>
              </div>
            )}
            {transaction.gst > 0 && (
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', marginBottom: '4px', color: 'var(--neutral-500)' }}>
                <span>GST</span>
                <span>{formatCurrency(transaction.gst)}</span>
              </div>
            )}
            {transaction.discount > 0 && (
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', marginBottom: '4px', color: 'var(--danger-500)' }}>
                <span>Discount</span>
                <span>-{formatCurrency(transaction.discount)}</span>
              </div>
            )}
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '1.25rem', fontWeight: 900, marginTop: '8px', paddingBottom: '12px', borderBottom: '1px solid var(--neutral-100)' }}>
              <span>Grand Total</span>
              <span>{formatCurrency(transaction.total || transaction.final_amount)}</span>
            </div>

            {/* Split/Khata Details */}
            {(transaction.paymentMode === 'SPLIT' || transaction.paymentMode === 'KHATA') && (
              <div style={{ marginTop: '12px', padding: '12px', background: 'var(--neutral-50)', borderRadius: '8px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem', marginBottom: '4px' }}>
                  <span style={{ fontWeight: 600 }}>Amount Paid (Cash)</span>
                  <span style={{ fontWeight: 700, color: 'var(--primary-600)' }}>{formatCurrency(transaction.paidAmount || 0)}</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.875rem' }}>
                  <span style={{ fontWeight: 600 }}>Remaining to Khata</span>
                  <span style={{ fontWeight: 700, color: 'var(--danger-600)' }}>
                    {formatCurrency((transaction.total || transaction.final_amount) - (transaction.paidAmount || 0))}
                  </span>
                </div>
              </div>
            )}
          </div>

          <div className="voucher-footer" style={{ marginTop: '24px', textAlign: 'center', fontSize: '0.75rem', color: 'var(--neutral-400)' }}>
            <p>Thank you for shopping with us! 🙏</p>
          </div>
        </div>

        <div className="voucher-actions" style={{ padding: '20px', background: 'var(--neutral-50)', display: 'flex', gap: '12px' }}>
          <Button variant="secondary" onClick={onClose} fullWidth>Close</Button>
          <Button variant="primary" onClick={() => onPrint(transaction)} fullWidth>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: '8px' }}>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="6 9 6 2 18 2 18 9"></polyline><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path><rect x="6" y="14" width="12" height="8"></rect></svg>
              Print Invoice
            </span>
          </Button>
        </div>
      </div>

      <style jsx>{`
        .voucher-modal { background: white; border-radius: 20px; overflow: hidden; }
        .voucher-header { padding: 20px; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--neutral-100); }
        .voucher-badge { background: var(--neutral-900); color: white; padding: 4px 12px; border-radius: 6px; font-size: 11px; font-weight: 800; }
        .close-btn { background: none; border: none; color: var(--neutral-400); cursor: pointer; }
        .voucher-body { padding: 32px; }
        .voucher-main-info { display: flex; justify-content: space-between; margin-bottom: 24px; }
        .info-group label { display: block; font-size: 10px; color: var(--neutral-400); text-transform: uppercase; font-weight: 700; margin-bottom: 4px; }
        .info-group span { font-weight: 700; color: var(--neutral-800); }
      `}</style>
    </Modal>
  );
};

export default InvoiceModal;
