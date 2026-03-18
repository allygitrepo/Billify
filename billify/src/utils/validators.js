/**
 * Basic form validation rules
 */

export const required = (value) => {
  if (value === undefined || value === null || value === '') {
    return 'This field is required';
  }
  return null;
};

export const validateEmail = (email) => {
  if (!email) return null;
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(email) ? null : 'Invalid email address';
};

export const validateMobile = (mobile) => {
  if (!mobile) return null;
  // Only numbers allowed, exactly 10 digits
  const re = /^[0-9]{10}$/;
  return re.test(mobile) ? null : 'Mobile number must be exactly 10 digits';
};

export const validatePassword = (password) => {
  if (!password) return null;
  return password.length >= 6 ? null : 'Password must be at least 6 characters';
};

/**
 * Run multiple validators on a single value
 * @param {any} value 
 * @param {Array<Function>} validators 
 * @returns {string | null}
 */
export const validate = (value, validators = []) => {
  for (const validator of validators) {
    const error = validator(value);
    if (error) return error;
  }
  return null;
};
