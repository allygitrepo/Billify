import { motion } from 'framer-motion';

const Button = ({ 
  children, 
  variant = 'primary', 
  isLoading = false, 
  disabled = false, 
  onClick, 
  type = 'button',
  className = '',
  ...props 
}) => {
  return (
    <motion.button
      type={type}
      className={`btn btn-${variant} ${className}`}
      disabled={disabled || isLoading}
      onClick={onClick}
      whileHover={{ scale: 1.03 }}
      whileTap={{ scale: 0.97 }}
      {...props}
    >
      {isLoading ? (
        <svg className="spinner" viewBox="0 0 24 24" width="16" height="16" style={{ marginRight: '8px' }}>
          <circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" strokeWidth="3" strokeDasharray="31.4 31.4" strokeLinecap="round" />
        </svg>
      ) : null}
      {children}
    </motion.button>
  );
};

export default Button;
