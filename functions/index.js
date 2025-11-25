const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

const gmailEmail = functions.config().gmail?.email;
const gmailPassword = functions.config().gmail?.password;

if (!gmailEmail || !gmailPassword) {
  console.warn(
    'Gmail credentials are not configured. Run ' +
      '"firebase functions:config:set gmail.email=\'you@gmail.com\' gmail.password=\'app-password\'"'
  );
}

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: gmailEmail,
    pass: gmailPassword,
  },
});

exports.sendOTP = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    const { email, code, purpose = 'auth_verification' } = data;

    if (!email || !code) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Email and code are required'
      );
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid email format'
      );
    }

    if (!gmailEmail || !gmailPassword) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Email service is not configured'
      );
    }

    const purposeCopy =
      purpose === 'change_password'
        ? 'Use this code to reset your password.'
        : 'Use this code to verify your login.';
    const subject =
      purpose === 'change_password'
        ? 'Reset your AGRI GUARD password'
        : 'Your AGRI GUARD verification code';

    try {
      const mailOptions = {
        from: `"AGRI GUARD" <${gmailEmail}>`,
        to: email,
        subject,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <div style="background-color: #2E7D32; color: white; padding: 20px; text-align: center;">
              <h1>AGRI GUARD</h1>
              <p>${purpose === 'change_password' ? 'Password Reset' : 'Sign-In Verification'}</p>
            </div>
            <div style="padding: 30px; background-color: #f9f9f9;">
              <h2 style="color: #2E7D32; text-align: center;">Your One-Time Password</h2>
              <div style="text-align: center; margin: 30px 0;">
                <div style="font-size: 36px; font-weight: bold; color: #2E7D32;
                            background-color: #C8E6C9; padding: 20px; border-radius: 10px;
                            display: inline-block; letter-spacing: 5px;">
                  ${code}
                </div>
              </div>
              <p style="text-align: center; color: #666; font-size: 16px;">
                This code will expire in <strong>10 minutes</strong>.
              </p>
              <p style="text-align: center; color: #666; font-size: 14px;">
                ${purposeCopy}
              </p>
              <p style="text-align: center; color: #666; font-size: 12px;">
                If you did not request this code, you can safely ignore this email.
              </p>
            </div>
            <div style="background-color: #2E7D32; color: white; padding: 15px; text-align: center;">
              <p style="margin: 0;">© ${new Date().getFullYear()} AGRI GUARD. All rights reserved.</p>
            </div>
          </div>
        `,
      };

      await transporter.sendMail(mailOptions);
      console.log(`OTP sent successfully to ${email}`);

      return { success: true, message: 'OTP sent successfully' };
    } catch (error) {
      console.error('Error sending OTP:', error);
      throw new functions.https.HttpsError(
        'internal',
        `Failed to send OTP email: ${error.message}`
      );
    }
  });

exports.sendInvitation = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    const { email, code, invitedBy = 'Admin' } = data;

    if (!email || !code) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Email and invite code are required'
      );
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid email format'
      );
    }

    if (!gmailEmail || !gmailPassword) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Email service is not configured'
      );
    }

    try {
      const mailOptions = {
        from: `"AGRI GUARD" <${gmailEmail}>`,
        to: email,
        subject: 'You are invited to AGRI GUARD',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 640px; margin: 0 auto;">
            <div style="background-color: #1B4332; color: white; padding: 24px;">
              <h1 style="margin: 0;">AGRI GUARD</h1>
              <p style="margin: 6px 0 0;">Detection & Collaboration Portal</p>
            </div>
            <div style="padding: 32px; background-color: #f9f9f9;">
              <p style="font-size: 16px; color: #333;">Hi there,</p>
              <p style="font-size: 15px; color: #444;">
                <strong>${invitedBy}</strong> invited you to join the AGRI GUARD detection workspace.
                Use the invite code below to create your account and access live animal & crop detections.
              </p>
              <div style="text-align: center; margin: 30px 0;">
                <div style="font-size: 32px; font-weight: bold; color: #2E7D32;
                            background-color: #C8E6C9; padding: 20px 30px; border-radius: 12px;
                            display: inline-block; letter-spacing: 6px;">
                  ${code}
                </div>
              </div>
              <p style="font-size: 14px; color: #555; text-align: center;">
                This invite expires in 7 days. Share this code only with trusted teammates.
              </p>
            </div>
            <div style="background-color: #1B4332; color: white; padding: 16px; text-align: center;">
              <p style="margin: 0;">© ${new Date().getFullYear()} AGRI GUARD • Smart farming insights</p>
            </div>
          </div>
        `,
      };

      await transporter.sendMail(mailOptions);
      console.log(`Invitation sent successfully to ${email}`);

      return { success: true, message: 'Invitation email sent' };
    } catch (error) {
      console.error('Error sending invitation email:', error);
      throw new functions.https.HttpsError(
        'internal',
        `Failed to send invitation email: ${error.message}`
      );
    }
  });