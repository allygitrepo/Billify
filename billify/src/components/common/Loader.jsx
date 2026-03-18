import React from 'react';

const Loader = ({ fullPage = false }) => {
  const loader = (
    <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 'var(--spacing-3)'}}>
      <div className="spinner" style={{width: '2.5rem', height: '2.5rem', color: 'var(--primary-500)', borderWidth: '4px'}}></div>
      <p style={{fontSize: '0.875rem', fontWeight: '500', color: 'var(--neutral-500)'}}>Loading...</p>
    </div>
  );

  if (fullPage) {
    return (
      <div style={{position: 'fixed', inset: '0', backgroundColor: 'rgba(255, 255, 255, 0.8)', zIndex: '50', display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
        {loader}
      </div>
    );
  }

  return (
    <div style={{padding: 'var(--spacing-8)', display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
      {loader}
    </div>
  );
};

export default Loader;
