import React from 'react';

const PageContainer = ({ title, children, actions }) => {
  return (
    <div style={{padding: 'var(--spacing-8)'}} className="animate-fade-in page-container">
      {(title || actions) && (
        <div style={{display: 'flex', flexDirection: 'column', gap: 'var(--spacing-4)', marginBottom: 'var(--spacing-8)'}} className="sm-flex-row">
          <div style={{flex: '1'}}>
            {title && <h2 style={{fontSize: '1.5rem', fontWeight: 'bold', color: 'var(--neutral-800)', letterSpacing: '-0.025em'}}>{title}</h2>}
          </div>
          {actions && (
            <div style={{display: 'flex', alignItems: 'center', gap: 'var(--spacing-3)'}}>
              {actions}
            </div>
          )}
        </div>
      )}
      <main>
        {children}
      </main>

      <style>{`
        @media (min-width: 640px) {
          .sm-flex-row {
            flex-direction: row !important;
            align-items: center !important;
          }
        }
        @media (max-width: 640px) {
          .page-container {
            padding: var(--spacing-4) !important;
          }
        }
      `}</style>
    </div>
  );
};

export default PageContainer;
