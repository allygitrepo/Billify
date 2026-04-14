import React from 'react';

const Logo = ({ size = 'md', showText = true, variant = 'primary' }) => {
  const sizes = {
    xs: { box: '20px', text: '0.9rem', gap: '4px' },
    sm: { box: '24px', text: '1.1rem', gap: '6px' },
    md: { box: '28px', text: '1.3rem', gap: '8px' },
    lg: { box: '36px', text: '1.8rem', gap: '10px' }
  };

  const currentSize = sizes[size] || sizes.md;

  const textColor = variant === 'white' ? 'white' : 'var(--primary-600)';

  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: currentSize.gap }}>
      <div style={{
        width: currentSize.box,
        height: currentSize.box,
        borderRadius: '8px',
        background: 'white',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        boxShadow: '0 2px 4px rgba(0, 0, 0, 0.1)',
        overflow: 'hidden',
        flexShrink: 0
      }}>
        <img src="/billify.png" alt="Billify Logo" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
      </div>
      {showText && (
        <span style={{
          fontSize: currentSize.text,
          fontWeight: '900',
          color: textColor,
          letterSpacing: '0.04em',
          fontStyle: 'italic',
          display: 'inline-block',
          transform: 'scaleX(1.15)',
          transformOrigin: 'left',
          lineHeight: 1
        }}>
          BilliFy
        </span>
      )}
    </div>
  );
};

export default Logo;
