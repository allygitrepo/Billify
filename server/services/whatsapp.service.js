const axios = require('axios');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const BASE_URL = 'https://silverapi.allysoftsolutions.com/wa-mitra/api/v1';

/**
 * Get headers for API request.
 * @returns {Object} Headers object containing Authorization and Content-Type.
 */
const getHeaders = (isMultipart = false) => {
    const token = process.env.WA_MITRA_TOKEN;
    if (!token) {
        console.warn('[WhatsApp Service] Warning: WA_MITRA_TOKEN is not defined in the environment.');
    }
    const headers = {
        'Authorization': `Bearer ${token}`
    };
    if (!isMultipart) {
        headers['Content-Type'] = 'application/json';
    }
    return headers;
};

/**
 * Step 1 / Step 2: Initiate a WhatsApp session or refresh an existing QR code.
 * 
 * @param {string} businessName - The business name (used as custom identifier).
 * @param {string|null} [instanceKey=null] - The existing instance key to refresh/poll.
 * @returns {Promise<Object|null>} Response data from the initiate API.
 */
const initiateInstance = async (businessName, instanceKey = null) => {
    try {
        const apiUrl = `${BASE_URL}/instance/initiate`;
        const payload = {};
        
        if (instanceKey) {
            payload.instanceKey = instanceKey;
            console.log(`[WhatsApp Service] Refreshing QR/Polling for instance key: ${instanceKey}`);
        } else {
            payload.name = `Billify_${businessName}`;
            console.log(`[WhatsApp Service] Initiating new instance with name: ${payload.name}`);
        }

        const response = await axios.post(apiUrl, payload, {
            headers: getHeaders()
        });

        if (response.data && response.data.success) {
            console.log(`[WhatsApp Service] Initiate/Refresh response: success=true, status=${response.data.status}`);
            return response.data;
        } else {
            console.error('[WhatsApp Service] Initiate failed. API responded with success=false:', response.data);
            return response.data || null;
        }
    } catch (error) {
        console.error('[WhatsApp Service] Error initiating WhatsApp instance:', error.response ? error.response.data : error.message);
        throw error;
    }
};

/**
 * Check the live status of any instance at any time.
 * 
 * @param {string} instanceKey - The ID of the instance to check.
 * @returns {Promise<Object>} Status response from API.
 */
const getInstanceStatus = async (instanceKey) => {
    try {
        if (!instanceKey) {
            throw new Error('instanceKey is required to check status');
        }

        const apiUrl = `${BASE_URL}/instance/status?instanceKey=${instanceKey}`;
        console.log(`[WhatsApp Service] Fetching status for instance key: ${instanceKey}`);

        const response = await axios.get(apiUrl, {
            headers: getHeaders()
        });

        return response.data;
    } catch (error) {
        console.error('[WhatsApp Service] Error checking status:', error.response ? error.response.data : error.message);
        throw error;
    }
};

/**
 * Permanently remove an instance from the database and clean up session files.
 * 
 * @param {string} instanceKey - The ID of the instance to delete.
 * @returns {Promise<Object>} Success message/response.
 */
const deleteInstance = async (instanceKey) => {
    try {
        if (!instanceKey) {
            throw new Error('instanceKey is required to delete instance');
        }

        const apiUrl = `${BASE_URL}/instance/delete?instanceKey=${instanceKey}`;
        console.log(`[WhatsApp Service] Requesting deletion of instance key: ${instanceKey}`);

        const response = await axios.delete(apiUrl, {
            headers: getHeaders()
        });

        return response.data;
    } catch (error) {
        console.error('[WhatsApp Service] Error deleting instance:', error.response ? error.response.data : error.message);
        throw error;
    }
};

/**
 * Dispatch a plain text message to any WhatsApp number.
 * 
 * @param {string} instanceKey - Your connected instance key.
 * @param {string} number - Recipient's phone with country code (e.g. 919876...).
 * @param {string} message - The text content of the message.
 * @returns {Promise<Object>} Send API response.
 */
const sendTextMessage = async (instanceKey, number, message) => {
    try {
        if (!instanceKey || !number || !message) {
            throw new Error('instanceKey, number, and message are required fields');
        }

        const apiUrl = `${BASE_URL}/messages/send`;
        console.log(`[WhatsApp Service] Sending text message to ${number}`);

        const response = await axios.post(apiUrl, {
            instanceKey,
            number,
            message
        }, {
            headers: getHeaders()
        });

        return response.data;
    } catch (error) {
        console.error('[WhatsApp Service] Error sending text message:', error.response ? error.response.data : error.message);
        throw error;
    }
};

/**
 * Upload files like JPG, PNG, PDF, or DOCX via multipart/form-data.
 * 
 * @param {string} instanceKey - Your connected instance key.
 * @param {string} number - Recipient's phone with country code.
 * @param {string|Buffer|Blob|File} fileInput - The file to upload (file path string, Buffer, Blob, or File).
 * @param {string} [message=""] - Optional text caption.
 * @returns {Promise<Object>} Send API response.
 */
const sendMediaMessage = async (instanceKey, number, fileInput, message = "", filename = 'upload_file') => {
    try {
        if (!instanceKey || !number || !fileInput) {
            throw new Error('instanceKey, number, and fileInput are required fields');
        }

        let fileToUpload;
        if (typeof fileInput === 'string') {
            if (!fs.existsSync(fileInput)) {
                throw new Error(`File path does not exist: ${fileInput}`);
            }
            const fileData = fs.readFileSync(fileInput);
            const fileName = path.basename(fileInput);
            const fileBlob = new Blob([fileData]);
            fileToUpload = new File([fileBlob], fileName);
        } else if (Buffer.isBuffer(fileInput)) {
            const fileBlob = new Blob([fileInput]);
            fileToUpload = new File([fileBlob], filename);
        } else if (fileInput instanceof Blob || fileInput instanceof File) {
            fileToUpload = fileInput;
        } else {
            throw new Error('Invalid file input. Expected file path, Buffer, Blob, or File.');
        }

        const apiUrl = `${BASE_URL}/messages/send`;
        console.log(`[WhatsApp Service] Sending media message to ${number}`);

        const formData = new FormData();
        formData.append('instanceKey', instanceKey);
        formData.append('number', number);
        formData.append('file', fileToUpload);
        if (message) {
            formData.append('message', message);
        }

        const response = await axios.post(apiUrl, formData, {
            headers: getHeaders(true)
        });

        return response.data;
    } catch (error) {
        console.error('[WhatsApp Service] Error sending media message:', error.response ? error.response.data : error.message);
        throw error;
    }
};

/**
 * Send high-volume messages in a single request.
 * 
 * @param {string} instanceKey - Your connected instance key.
 * @param {Array<Object>} messages - Array of message items. Example: [ { number: "...", message: "..." } ]
 * @returns {Promise<Object>} Bulk send API response.
 */
const sendBulkMessages = async (instanceKey, messages) => {
    try {
        if (!instanceKey || !Array.isArray(messages) || messages.length === 0) {
            throw new Error('instanceKey and a non-empty array of messages are required');
        }

        const apiUrl = `${BASE_URL}/messages/bulk`;
        console.log(`[WhatsApp Service] Triggering bulk messages. Count: ${messages.length}`);

        const response = await axios.post(apiUrl, {
            instanceKey,
            messages
        }, {
            headers: getHeaders()
        });

        return response.data;
    } catch (error) {
        console.error('[WhatsApp Service] Error sending bulk messages:', error.response ? error.response.data : error.message);
        throw error;
    }
};

module.exports = {
    initiateInstance,
    getInstanceStatus,
    deleteInstance,
    sendTextMessage,
    sendMediaMessage,
    sendBulkMessages
};
