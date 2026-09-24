const axios = require('axios');
require('dotenv').config();

const sendOTPSMS = async (phoneNumber, otp) => {
    const deviceCode = process.env.SMS_DEVICE_CODE;
    const apiUrl = "https://silverapi.allysoftsolutions.com/smsmitra/v1/sms/trigger";
    const message = `Hello, your billify code is: ${otp}. Please do not share it with anyone.`;

    const requestPayload = {
        deviceCode: deviceCode,
        phoneNumber: phoneNumber,
        message: message
    };

    console.log(`\n================== [SMS Service] REQUEST START ==================`);
    console.log(`[SMS Service] Target URL: ${apiUrl}`);
    console.log(`[SMS Service] Device Code: ${deviceCode ? deviceCode : '(NOT SET / UNDEFINED in .env)'}`);
    console.log(`[SMS Service] Request Body:`, JSON.stringify(requestPayload, null, 2));
    console.log(`=================================================================\n`);

    try {
        const response = await axios.post(apiUrl, requestPayload, {
            headers: {
                'Content-Type': 'application/json'
            }
        });

        console.log(`\n================== [SMS Service] RESPONSE SUCCESS ==================`);
        console.log(`[SMS Service] Status: ${response.status} ${response.statusText || ''}`);
        console.log(`[SMS Service] Response Data:`, JSON.stringify(response.data, null, 2));
        console.log(`====================================================================\n`);

        if (response.status === 200 || response.status === 201) {
            return true;
        } else {
            console.error(`[SMS Service] Unexpected status code received: ${response.status}`);
            return false;
        }
    } catch (error) {
        console.error(`\n================== [SMS Service] RESPONSE ERROR ==================`);
        if (error.response) {
            console.error(`[SMS Service] Status Code: ${error.response.status}`);
            console.error(`[SMS Service] Response Data:`, JSON.stringify(error.response.data, null, 2));
            console.error(`[SMS Service] Response Headers:`, JSON.stringify(error.response.headers, null, 2));
        } else if (error.request) {
            console.error(`[SMS Service] No response received from server. Request details:`, error.message);
        } else {
            console.error(`[SMS Service] Request setup error:`, error.message);
        }
        console.error(`==================================================================\n`);
        return false;
    }
};

module.exports = {
    sendOTPSMS,
};

