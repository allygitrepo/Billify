import React from 'react';
import { formatCurrency } from '../../../utils/formatCurrency';

const CustomerBalanceCard = ({ summary }) => {
  const balance = parseFloat(summary?.remainingBalance || 0);
  const isCredit = balance >= 0; // Customer owes you (Red)
  const isDebit = balance < 0;   // You owe customer (Green)

  return (
    <div className="card mb-6" style={{ 
      background: 'var(--neutral-50)', 
      border: '1px solid var(--neutral-200)',
      borderRadius: 'var(--radius-xl)'
    }}>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1px 1fr', gap: 'var(--spacing-6)', padding: 'var(--spacing-6)' }}>
        <div>
          <p style={{ fontSize: '0.75rem', color: 'var(--neutral-500)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 'var(--spacing-2)' }}>Total Given (Sales)</p>
          <p style={{ fontSize: '1.25rem', fontWeight: '700', color: 'var(--danger-600)' }}>{formatCurrency(summary?.totalCredit || 0)}</p>
        </div>
        
        <div style={{ backgroundColor: 'var(--neutral-200)' }}></div>
        
        <div style={{ textAlign: 'right' }}>
          <p style={{ fontSize: '0.75rem', color: 'var(--neutral-500)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 'var(--spacing-2)' }}>Total Got (Payments)</p>
          <p style={{ fontSize: '1.25rem', fontWeight: '700', color: 'var(--primary-600)' }}>{formatCurrency(summary?.totalDebit || 0)}</p>
        </div>
      </div>

      <div style={{ 
        padding: 'var(--spacing-6)', 
        borderTop: '1px solid var(--neutral-200)', 
        display: 'flex', 
        justifyContent: 'space-between', 
        alignItems: 'center',
        backgroundColor: isCredit ? 'rgba(239, 68, 68, 0.05)' : isDebit ? 'rgba(16, 185, 129, 0.05)' : 'transparent'
      }}>
        <div>
          <p style={{ fontSize: '0.875rem', fontWeight: '600', color: 'var(--neutral-700)' }}>Net Outstanding Balance</p>
          <p style={{ fontSize: '0.75rem', color: 'var(--neutral-500)' }}>
            {isCredit ? 'Customer owes you money' : isDebit ? 'You owe money to customer' : 'Settled balance'}
          </p>
        </div>
        <div style={{ textAlign: 'right' }}>
          <p style={{ 
            fontSize: '1.75rem', 
            fontWeight: '800', 
            color: isCredit ? 'var(--danger-600)' : isDebit ? 'var(--primary-600)' : 'var(--neutral-800)' 
          }}>
            {formatCurrency(Math.abs(balance))}
          </p>
        </div>
      </div>
    </div>
  );
};

export default CustomerBalanceCard;
