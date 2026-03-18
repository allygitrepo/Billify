/**
 * Utility to convert a File object to a Base64 string
 * @param {File} file - The file to convert
 * @returns {Promise<string>} - The Base64 string
 */
export const fileToBase64 = (file) => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => resolve(reader.result);
    reader.onerror = (error) => reject(error);
  });
};

/**
 * Validates if the file is an image and within size limits
 * @param {File} file - The file to validate
 * @param {number} maxSizeMB - Maximum size in MB
 * @returns {string|null} - Error message or null if valid
 */
export const validateImage = (file, maxSizeMB = 2) => {
  if (!file) return null;
  
  const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg', 'image/webp'];
  if (!allowedTypes.includes(file.type)) {
    return 'Invalid file type. Please upload a JPG, PNG, or WEBP image.';
  }

  const maxSizeBytes = maxSizeMB * 1024 * 1024;
  if (file.size > maxSizeBytes) {
    return `File size exceeds ${maxSizeMB}MB limit.`;
  }

  return null;
};
