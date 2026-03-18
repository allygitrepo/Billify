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
  ...props
}) => {
  return (
    <div className={`input-group ${className}`}>
      {label && (
        <label className="input-label">
          {label} {required && <span style={{color: 'var(--danger-500)'}}>*</span>}
        </label>
      )}
      <input
        type={type}
        className={`input ${error ? 'input-error' : ''}`}
        placeholder={placeholder}
        {...(type !== 'file' ? { value } : {})}
        onChange={onChange}
        {...props}
      />
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
