import React from 'react';

const Switch = ({ 
  label, 
  checked, 
  onChange, 
  name, 
  error, 
  className = '', 
  disabled = false,
  required = false
}) => {
  return (
    <div className={`switch-container ${className} ${error ? 'has-error' : ''}`}>
      {label && (
        <label className="field-label mb-2">
          {label} {required && <span className="text-danger">*</span>}
        </label>
      )}
      <label className={`switch ${disabled ? 'disabled' : ''}`}>
        <input
          type="checkbox"
          name={name}
          checked={checked}
          onChange={(e) => onChange({ target: { name, value: e.target.checked ? 'active' : 'inactive' } })}
          disabled={disabled}
        />
        <span className="slider round"></span>
      </label>
      {error && <span className="error-message">{error}</span>}
    </div>
  );
};

export default Switch;
