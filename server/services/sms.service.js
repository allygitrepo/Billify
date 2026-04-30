const axios = require('axios');
require('dotenv').config();

const sendOTPSMS = async (phoneNumber, otp) => {
    try {
        const deviceCode = process.env.SMS_DEVICE_CODE; // User will edit this
        const apiUrl = "http://silverapi.allysoftsolutions.com/smsmitra/v1/sms/trigger";

        const message = `Your Billify verification code is: ${otp}. Valid for 5 minutes.`;

        console.log(`[SMS Service] Attempting to send OTP to ${phoneNumber} via ${apiUrl}`);
        const response = await axios.post(apiUrl, {
            deviceCode: deviceCode,
            phoneNumber: phoneNumber,
            message: message
        }, {
            headers: {
                'Content-Type': 'application/json'
            }
        });

        if (response.status === 200 || response.status === 201) {
            console.log(`[SMS Service] SMS sent successfully to ${phoneNumber}. Response:`, response.data);
            return true;
        } else {
            console.error(`[SMS Service] Failed to send SMS to ${phoneNumber}. Status: ${response.status}`, response.data);
            return false;
        }
    } catch (error) {
        console.error(`[SMS Service] Error sending SMS to ${phoneNumber}:`, error.response ? error.response.data : error.message);
        return false;
    }
};

module.exports = {
    sendOTPSMS,
};
