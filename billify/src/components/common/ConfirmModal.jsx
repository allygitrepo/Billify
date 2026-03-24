import React from 'react';
import Modal from './Modal';
import Button from './Button';

const ConfirmModal = ({ 
  isOpen, 
  onClose, 
  onConfirm, 
  title = 'Confirm Action', 
  message = 'Are you sure you want to proceed?',
  confirmText = 'Confirm',
  cancelText = 'Cancel',
  type = 'danger' // 'danger' | 'warning' | 'info'
}) => {
  const getColors = () => {
    switch (type) {
      case 'danger': return { primary: 'var(--danger-600)', bg: 'var(--danger-50)' };
      case 'warning': return { primary: 'var(--warning-600)', bg: 'var(--warning-50)' };
      default: return { primary: 'var(--primary-600)', bg: 'var(--primary-50)' };
    }
  };

  const colors = getColors();

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={title} maxWidth="400px">
      <div style={{ textAlign: 'center', padding: 'var(--spacing-4) 0' }}>
        <div style={{ 
          width: '64px', 
          height: '64px', 
          borderRadius: '50%', 
          backgroundColor: colors.bg, 
          color: colors.primary,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          margin: '0 auto var(--spacing-6)'
        }}>
          {type === 'danger' ? (
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
              <line x1="12" y1="9" x2="12" y2="13"></line>
              <line x1="12" y1="17" x2="12.01" y2="17"></line>
            </svg>
          ) : (
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="12" cy="12" r="10"></circle>
              <line x1="12" y1="16" x2="12" y2="12"></line>
              <line x1="12" y1="8" x2="12.01" y2="8"></line>
            </svg>
          )}
        </div>
        
        <p style={{ 
          color: 'var(--neutral-600)', 
          fontSize: '1rem', 
          lineHeight: '1.5',
          marginBottom: 'var(--spacing-8)'
        }}>
          {message}
        </p>

        <div style={{ display: 'flex', gap: 'var(--spacing-3)', justifyContent: 'center' }}>
          <Button variant="secondary" onClick={onClose} style={{ flex: 1 }}>
            {cancelText}
          </Button>
          <Button 
            variant={type === 'danger' ? 'danger' : 'primary'} 
            onClick={() => {
              onConfirm();
              onClose();
            }}
            style={{ flex: 1 }}
          >
            {confirmText}
          </Button>
        </div>
      </div>
    </Modal>
  );
};

export default ConfirmModal;
