import React from 'react';
import Modal from './Modal';
import Button from './Button';

const ConfirmDialog = ({ 
  isOpen, 
  onClose, 
  onConfirm, 
  title = "Confirm Action", 
  message = "Are you sure you want to perform this action?",
  confirmLabel = "Confirm",
  cancelLabel = "Cancel",
  variant = "danger" // 'danger' or 'primary'
}) => {
  return (
    <Modal isOpen={isOpen} onClose={onClose} title={title} maxWidth="400px">
      <div className="confirm-dialog-content">
        <p className="mb-6 text-neutral-600 leading-relaxed">
          {message}
        </p>
        <div style={{ display: 'flex', gap: 'var(--spacing-3)', justifyContent: 'flex-end' }}>
          <Button variant="secondary" onClick={onClose}>
            {cancelLabel}
          </Button>
          <Button 
            variant={variant} 
            onClick={() => {
              onConfirm();
              onClose();
            }}
          >
            {confirmLabel}
          </Button>
        </div>
      </div>
    </Modal>
  );
};

export default ConfirmDialog;
