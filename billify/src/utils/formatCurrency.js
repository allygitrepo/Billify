/**
 * Format a number into Indian Rupee (₹) currency format.
 * @param {number | string} amount 
 * @returns {string}
 */
export const formatCurrency = (amount) => {
  const num = Number(amount);
  if (isNaN(num)) return '₹0.00';
  
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(num);
};

/**
 * Format a number to Indian numbering system without currency symbol.
 * @param {number | string} num 
 * @returns {string}
 */
export const formatNumber = (num) => {
  const val = Number(num);
  if (isNaN(val)) return '0';
  
  return new Intl.NumberFormat('en-IN').format(val);
};
