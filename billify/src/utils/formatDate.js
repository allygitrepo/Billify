/**
 * Format a date string or object into a readable format (e.g., 18 Mar 2026)
 * @param {Date | string | number} date 
 * @returns {string}
 */
export const formatDate = (date) => {
  if (!date) return '-';
  const d = new Date(date);
  if (isNaN(d.getTime())) return '-';
  
  return d.toLocaleDateString('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric'
  });
};

/**
 * Format a date with time (e.g., 18 Mar 2026, 11:45 AM)
 * @param {Date | string | number} date 
 * @returns {string}
 */
export const formatDateTime = (date) => {
  if (!date) return '-';
  const d = new Date(date);
  if (isNaN(d.getTime())) return '-';

  return d.toLocaleDateString('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true
  });
};
