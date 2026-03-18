import React from 'react';

const EmptyState = ({ 
  title = 'No data found', 
  message = 'Try adjusting your filters or adding a new record.',
  icon
}) => {
  return (
    <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: 'var(--spacing-8)', textAlign: 'center', backgroundColor: 'var(--neutral-50)', borderRadius: 'var(--radius-lg)', border: '2px dashed var(--neutral-200)'}}>
      <div style={{width: '4rem', height: '4rem', marginBottom: 'var(--spacing-4)', color: 'var(--neutral-300)', display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
        {icon || (
          <svg style={{width: '100%', height: '100%'}} fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1" d="9 13h6m-3-3v6m-9 1V7a2 2 0 012-2h6l2 2h6a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2z" />
          </svg>
        )}
      </div>
      <h3 style={{fontSize: '1rem', fontWeight: '600', color: 'var(--neutral-700)', marginBottom: 'var(--spacing-1)'}}>{title}</h3>
      <p style={{fontSize: '0.875rem', color: 'var(--neutral-500)', maxWidth: '20rem'}}>{message}</p>
    </div>
  );
};

export default EmptyState;
