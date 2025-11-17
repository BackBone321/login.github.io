const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Create email transporter
const transporter = nodemailer.createTransporter({
  service: 'gmail',
  auth: {
    user: functions.config().gmail.email, // Set this using: firebase functions:config:set gmail.email="your@gmail.com"
    pass: functions.config().gmail.password, // Set this using: firebase functions:config:set gmail.password="your-app-password"
  },
});

exports.sendOTP = functions.https.onCall(async (data, context) => {
  const { email, code, purpose } = data;

  try {
    // Email content
    const mailOptions = {
      from: functions.config().gmail.email,
      to: email,
      subject: 'Your OTP Code',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #2E7D32;">AGRI GUARD OTP Verification</h2>
          <p>Your verification code is:</p>
          <div style="background-color: #f5f5f5; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 10px; color: #2E7D32;">
            ${code}
          </div>
          <p>This code will expire in 10 minutes.</p>
          <p>If you didn't request this code, please ignore this email.</p>
          <hr>
          <p style="color: #666; font-size: 12px;">AGRI GUARD Team</p>
        </div>
      `,
    };

    // Send email
    await transporter.sendMail(mailOptions);
    
    return { success: true, message: 'OTP sent successfully' };
  } catch (error) {
    console.error('Error sending email:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send OTP email');
  }
});