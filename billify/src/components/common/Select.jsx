import React from 'react';

const Select = ({
  label,
  error,
  options = [],
  value,
  onChange,
  className = '',
  placeholder = 'Select an option',
  required = false,
  ...props
}) => {
  return (
    <div className={`input-group ${className}`}>
      {label && (
        <label className="label">
          {label} {required && <span style={{color: 'var(--danger-500)'}}>*</span>}
        </label>
      )}
      <select
        className={`select ${error ? 'input-error' : ''}`}
        value={value}
        onChange={onChange}
        {...props}
      >
        {placeholder && <option value="" disabled>{placeholder}</option>}
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
      {error && <span className="error-text">{error}</span>}
    </div>
  );
};

export default Select;
