/**
 * Utility service for CSV Import/Export
 */

/**
 * Exports data to a CSV file and triggers download
 * @param {Array} data - Array of objects to export
 * @param {string} filename - Desired filename (without .csv)
 * @param {Array} headers - Optional array of custom header labels
 */
export const exportToCSV = (data, filename = 'export', headers = null) => {
  if (!data || !data.length) {
    alert('No data available to export');
    return;
  }

  // Get keys from first object if headers not provided
  const keys = headers || Object.keys(data[0]);
  
  // Format header row
  const headerRow = keys.join(',');
  
  // Format data rows
  const rows = data.map(obj => {
    return keys.map(key => {
      let value = obj[key];
      
      // Handle null/undefined
      if (value === null || value === undefined) value = '';
      
      // Handle objects/arrays (convert to string)
      if (typeof value === 'object') value = JSON.stringify(value);
      
      // Handle strings with commas (wrap in quotes)
      if (typeof value === 'string' && value.includes(',')) {
        value = `"${value.replace(/"/g, '""')}"`;
      }
      
      return value;
    }).join(',');
  });

  const csvContent = [headerRow, ...rows].join('\n');
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  
  const url = URL.createObjectURL(blob);
  link.setAttribute('href', url);
  link.setAttribute('download', `${filename}_${new Date().toISOString().slice(0,10)}.csv`);
  link.style.visibility = 'hidden';
  
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

/**
 * Parses a CSV file into an array of objects
 * @param {File} file - The file object from input change event
 * @returns {Promise<Array>} - Promise resolving to array of objects
 */
export const importFromCSV = (file) => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    
    reader.onload = (e) => {
      const text = e.target.result;
      const lines = text.split('\n').filter(line => line.trim() !== '');
      
      if (lines.length < 2) {
        reject('File is empty or contains no data');
        return;
      }

      const headers = lines[0].split(',').map(h => h.trim());
      const data = lines.slice(1).map(line => {
        // Simple CSV split (not handling escaped commas for now for simplicity, 
        // or can use a regex if needed)
        const values = line.split(',');
        const obj = {};
        
        headers.forEach((header, index) => {
          let val = values[index] ? values[index].trim() : '';
          
          // Remove wrapping quotes if present
          if (val.startsWith('"') && val.endsWith('"')) {
            val = val.slice(1, -1).replace(/""/g, '"');
          }
          
          obj[header] = val;
        });
        
        return obj;
      });
      
      resolve(data);
    };
    
    reader.onerror = () => reject('Error reading file');
    reader.readAsText(file);
  });
};

/**
 * Downloads a sample template CSV
 * @param {Array} headers - Array of header strings
 * @param {string} filename - Desired filename
 */
export const downloadTemplate = (headers, filename = 'template') => {
  const content = headers.join(',') + '\n';
  const blob = new Blob([content], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.setAttribute('href', url);
  link.setAttribute('download', `${filename}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};
