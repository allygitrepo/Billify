import React, { useState } from 'react';
import { createPortal } from 'react-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { formatCurrency } from '../../utils/formatCurrency';

const CustomerSelectorModal = ({ customers, onClose, onSelect }) => {
  const [searchTerm, setSearchTerm] = useState('');

  const filteredCustomers = customers.filter(c => 
    c.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
    c.phone?.includes(searchTerm)
  );

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
          style={{ maxWidth: '500px' }}
          initial={{ opacity: 0, scale: 0.95, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 20 }}
          transition={{ type: 'spring', damping: 25, stiffness: 300 }}
        >
          <div className="modal-header">
            <h3 className="modal-title">Select Customer</h3>
            <button className="modal-close-btn" onClick={onClose}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
              </svg>
            </button>
          </div>

          <div className="modal-content" style={{ maxHeight: '70vh', display: 'flex', flexDirection: 'column' }}>
            {/* Search */}
            <div style={{ marginBottom: '1rem' }}>
              <div style={{ position: 'relative' }}>
                <svg style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--neutral-400)', width: '18px', height: '18px' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
                <input
                  autoFocus
                  type="text"
                  placeholder="Search by name or phone..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  style={{ width: '100%', padding: '0.75rem 0.75rem 0.75rem 40px', borderRadius: '10px', border: '1px solid var(--neutral-200)', outline: 'none', backgroundColor: 'var(--neutral-50)' }}
                />
              </div>
            </div>

            {/* List */}
            <div className="customer-list-scroll" style={{ overflowY: 'auto', flex: 1, paddingRight: '4px' }}>
              {/* Walk-in Option */}
              <motion.button
                whileTap={{ scale: 0.98 }}
                onClick={() => onSelect(null, 'WALKIN')}
                style={{
                  width: '100%',
                  display: 'flex',
                  alignItems: 'center',
                  padding: '1rem',
                  borderRadius: '12px',
                  border: '1px solid var(--primary-100)',
                  background: 'var(--primary-50)',
                  marginBottom: '10px',
                  cursor: 'pointer',
                  textAlign: 'left'
                }}
              >
                <div style={{ width: '40px', height: '40px', borderRadius: '20px', background: 'var(--primary-500)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', marginRight: '12px' }}>
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
                </div>
                <div>
                  <div style={{ fontWeight: 700, color: 'var(--primary-900)' }}>Walk-in Customer</div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--primary-600)' }}>Default for quick sales</div>
                </div>
              </motion.button>

              <div style={{ margin: '1rem 0', display: 'flex', alignItems: 'center' }}>
                <div style={{ flex: 1, height: '1px', background: 'var(--neutral-100)' }}></div>
                <span style={{ margin: '0 10px', fontSize: '0.75rem', color: 'var(--neutral-400)', fontWeight: 600, textTransform: 'uppercase' }}>Registered Customers</span>
                <div style={{ flex: 1, height: '1px', background: 'var(--neutral-100)' }}></div>
              </div>

              {filteredCustomers.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--neutral-400)' }}>No customers found</div>
              ) : (
                filteredCustomers.map(customer => {
                  const balance = parseFloat(customer.opening_balance || 0); // Logic will be improved based on actual balance field
                  return (
                    <motion.button
                      key={customer.id}
                      whileHover={{ background: 'var(--neutral-50)' }}
                      whileTap={{ scale: 0.98 }}
                      onClick={() => onSelect(customer, 'REGULAR')}
                      style={{
                        width: '100%',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        padding: '1rem',
                        borderRadius: '12px',
                        border: '1px solid transparent',
                        background: 'white',
                        marginBottom: '8px',
                        cursor: 'pointer',
                        textAlign: 'left',
                        transition: 'all 0.2s'
                      }}
                    >
                      <div style={{ display: 'flex', alignItems: 'center' }}>
                        <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: 'var(--neutral-100)', color: 'var(--neutral-700)', display: 'flex', alignItems: 'center', justifyContent: 'center', marginRight: '12px', fontWeight: 700 }}>
                          {customer.name[0]}
                        </div>
                        <div>
                          <div style={{ fontWeight: 600, color: 'var(--neutral-800)' }}>{customer.name}</div>
                          <div style={{ fontSize: '0.75rem', color: 'var(--neutral-500)' }}>{customer.phone || 'No phone'}</div>
                        </div>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <div style={{ fontSize: '0.875rem', fontWeight: 700, color: balance >= 0 ? 'var(--danger-600)' : 'var(--success-600)' }}>
                          {formatCurrency(Math.abs(balance))}
                        </div>
                        <div style={{ fontSize: '10px', color: 'var(--neutral-400)', textTransform: 'uppercase', fontWeight: 700 }}>Balance</div>
                      </div>
                    </motion.button>
                  );
                })
              )}
            </div>
          </div>
        </motion.div>
      </div>

      <style jsx>{`
        .customer-list-scroll::-webkit-scrollbar { width: 6px; }
        .customer-list-scroll::-webkit-scrollbar-track { background: transparent; }
        .customer-list-scroll::-webkit-scrollbar-thumb { background: var(--neutral-200); border-radius: 3px; }
      `}</style>
    </AnimatePresence>,
    document.body
  );
};

export default CustomerSelectorModal;
