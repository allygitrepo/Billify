const nodemailer = require('nodemailer');
const path = require('path');
require('dotenv').config();

const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: process.env.SMTP_PORT,
    secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
    auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_GOOGLE_APP_PASSCODE,
    },
});

const sendOTPEmail = async (email, otp) => {
    const mailOptions = {
        from: `"Billify" <${process.env.SMTP_USER}>`,
        to: email,
        subject: 'Your Billify Verification Code',
        attachments: [{
            filename: 'billify.png',
            path: path.join(__dirname, '../public/billify.png'),
            cid: 'logo'
        }],
        html: `
           <!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Billify OTP Verification</title>
</head>
<body style="margin: 0; padding: 0; background-color: #f4f6f9; font-family: Helvetica, Arial, sans-serif;">

  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f6f9; padding: 40px 20px;">
    <tr>
      <td align="center">

        <!-- Email Container -->
        <table width="560" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 16px; overflow: hidden; border: 1px solid #e0e0e0;">

          <!-- Header -->
          <tr>
            <td style="background-color: #00466a; padding: 32px 40px; text-align: center;">
              <table cellpadding="0" cellspacing="0" style="margin: 0 auto;">
                <tr>
                  <td style="vertical-align: middle; padding-right: 10px;">
                    <img src="cid:logo" width="28" height="28"
                      alt="Billify Icon"
                      style="border-radius: 7px; display: block;" />
                  </td>
                  <td style="vertical-align: middle;">
                    <span style="font-size: 22px; font-weight: 700; color: #ffffff; letter-spacing: 0.5px;">Billify</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding: 40px 40px 32px;">


              <!-- Heading -->
              <h2 style="font-size: 22px; font-weight: 700; color: #1a1a2e; margin: 0 0 8px;">
                Verify your identity
              </h2>

              <!-- Intro Text -->
              <p style="font-size: 15px; color: #666666; line-height: 1.7; margin: 0 0 28px;">
                Hi there! Use the one-time password below to complete your sign up.
                This code expires in <strong style="color: #00466a;">5 minutes</strong>.
              </p>

              <!-- OTP Box -->
              <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f0f8fc; border: 1.5px dashed #a8d5e8; border-radius: 12px; margin-bottom: 28px;">
                <tr>
                  <td style="padding: 28px 20px; text-align: center;">
                    <p style="font-size: 11px; font-weight: 600; color: #00466a; text-transform: uppercase; letter-spacing: 2px; margin: 0 0 12px;">
                      Your OTP Code
                    </p>
                    <span style="font-family: 'Courier New', Courier, monospace; font-size: 36px; font-weight: 700; color: #00466a; background-color: #ffffff; border: 1.5px solid #c5e4f0; border-radius: 8px; padding: 6px 20px; letter-spacing: 8px;">
                      ${otp}
                    </span>
                  </td>
                </tr>
              </table>

              <!-- Security Notice -->
              <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom: 32px;">
                <tr>
                  <td style="background-color: #fff8e1; border-left: 4px solid #f59e0b; border-radius: 0 8px 8px 0; padding: 14px 18px;">
                    <p style="font-size: 13px; color: #92400e; margin: 0; line-height: 1.6;">
                      <strong>Security notice:</strong> Billify will never ask for your OTP over phone or email.
                      Do not share this code with anyone.
                    </p>
                  </td>
                </tr>
              </table>

              <!-- Disclaimer -->
              <p style="font-size: 14px; color: #888888; line-height: 1.7; margin: 0;">
                Didn't request this? You can safely ignore this email. If you're concerned,
                please contact our support team.
              </p>

            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #f8fafc; border-top: 1px solid #e8ecef; padding: 24px 40px; text-align: center;">
              <p style="font-size: 13px; color: #999999; margin: 0 0 4px;">Warm regards,</p>
              <p style="font-size: 14px; font-weight: 600; color: #00466a; margin: 0 0 16px;">The Billify Team</p>

              <!-- Footer Links -->
              <table cellpadding="0" cellspacing="0" style="margin: 0 auto 12px;">
                <tr>
                  <td style="padding: 0 8px;">
                    <a href="#" style="font-size: 12px; color: #aaaaaa; text-decoration: none;">Privacy Policy</a>
                  </td>
                  <td style="font-size: 12px; color: #dddddd;">·</td>
                  <td style="padding: 0 8px;">
                    <a href="#" style="font-size: 12px; color: #aaaaaa; text-decoration: none;">Terms of Service</a>
                  </td>
                  <td style="font-size: 12px; color: #dddddd;">·</td>
                  <td style="padding: 0 8px;">
                    <a href="#" style="font-size: 12px; color: #aaaaaa; text-decoration: none;">Help Center</a>
                  </td>
                </tr>
              </table>

              <p style="font-size: 11px; color: #cccccc; margin: 0;">
                © 2026 Billify Inc. All rights reserved.
              </p>
            </td>
          </tr>

        </table>
        <!-- End Email Container -->

      </td>
    </tr>
  </table>

</body>
</html>
        `,
    };

    try {
        await transporter.sendMail(mailOptions);
        return true;
    } catch (error) {
        console.error('Error sending email:', error);
        return false;
    }
};

module.exports = {
    sendOTPEmail,
};
