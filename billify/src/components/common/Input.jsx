import { motion, AnimatePresence } from 'framer-motion';

const Input = ({
  label,
  error,
  type = 'text',
  placeholder,
  value,
  onChange,
  className = '',
  required = false,
  endIcon,
  onIconClick,
  ...props
}) => {
  return (
    <div className={`input-group ${className}`}>
      {label && (
        <label className="input-label">
          {label} {required && <span style={{color: 'var(--danger-500)'}}>*</span>}
        </label>
      )}
      <div className="input-wrapper" style={{ position: 'relative' }}>
        <input
          type={type}
          className={`input ${error ? 'input-error' : ''}`}
          placeholder={placeholder}
          {...(type !== 'file' ? { value } : {})}
          onChange={onChange}
          style={endIcon ? { paddingRight: 'var(--spacing-10)' } : {}}
          {...props}
        />
        {endIcon && (
          <button
            type="button"
            className="input-icon-btn"
            onClick={onIconClick}
            style={{
              position: 'absolute',
              right: 'var(--spacing-3)',
              top: '50%',
              transform: 'translateY(-50%)',
              background: 'none',
              border: 'none',
              cursor: 'pointer',
              color: 'var(--neutral-400)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              padding: 'var(--spacing-1)',
              borderRadius: 'var(--radius-md)'
            }}
          >
            {endIcon}
          </button>
        )}
      </div>
      <AnimatePresence>
        {error && (
          <motion.span 
            className="error-text"
            initial={{ opacity: 0, y: -5 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
          >
            {error}
          </motion.span>
        )}
      </AnimatePresence>
    </div>
  );
};

export default Input;
