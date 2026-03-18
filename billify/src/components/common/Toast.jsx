import React, { useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

const Toast = ({ message, type = 'success', onClose, duration = 3000 }) => {
  useEffect(() => {
    const timer = setTimeout(() => {
      onClose();
    }, duration);
    return () => clearTimeout(timer);
  }, [duration, onClose]);

  const colors = {
    success: 'var(--success-500)',
    error: 'var(--danger-500)',
    info: 'var(--info-500)'
  };

  const bgColors = {
    success: '#f0fdf4',
    error: '#fef2f2',
    info: '#eff6ff'
  };

  return (
    <motion.div
      initial={{ opacity: 0, x: 50, scale: 0.9 }}
      animate={{ opacity: 1, x: 0, scale: 1 }}
      exit={{ opacity: 0, x: 20, scale: 0.9 }}
      style={{
        position: 'fixed',
        top: '20px',
        right: '20px',
        zIndex: 1000,
        backgroundColor: bgColors[type],
        borderLeft: `4px solid ${colors[type]}`,
        padding: '12px 20px',
        borderRadius: '8px',
        boxShadow: '0 10px 15px -3px rgba(0,0,0,0.1)',
        display: 'flex',
        alignItems: 'center',
        gap: '12px',
        minWidth: '280px'
      }}
    >
      <div style={{ color: colors[type], fontSize: '1.25rem' }}>
        {type === 'success' && '✅'}
        {type === 'error' && '❌'}
        {type === 'info' && 'ℹ️'}
      </div>
      <div style={{ color: 'var(--neutral-800)', fontWeight: '500', fontSize: '0.875rem' }}>
        {message}
      </div>
      <button 
        onClick={onClose}
        style={{ 
          marginLeft: 'auto', 
          background: 'none', 
          border: 'none', 
          color: 'var(--neutral-400)', 
          cursor: 'pointer',
          fontSize: '1.125rem'
        }}
      >
        &times;
      </button>
    </motion.div>
  );
};

export default Toast;
