exports.sendOTP = functions.https.onCall(async (data, context) => {
    // Note: Removed authentication check for OTP sending since users might not be logged in during password reset
    
    const { email, code } = data;
    
    if (!email || !code) {
      throw new functions.https.HttpsError('invalid-argument', 'Email and code are required');
    }
  
    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid email format');
    }
  
    try {
      const mailOptions = {
        from: `"AGRI GUARD" <${functions.config().email.user}>`,
        to: email,
        subject: 'Your OTP Verification Code - AGRI GUARD',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <div style="background-color: #2E7D32; color: white; padding: 20px; text-align: center;">
              <h1>AGRI GUARD</h1>
              <p>Password Change Verification</p>
            </div>
            <div style="padding: 30px; background-color: #f9f9f9;">
              <h2 style="color: #2E7D32; text-align: center;">Your Verification Code</h2>
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
                If you didn't request this code, please ignore this email.
              </p>
            </div>
            <div style="background-color: #2E7D32; color: white; padding: 15px; text-align: center;">
              <p style="margin: 0;">© 2024 AGRI GUARD. All rights reserved.</p>
            </div>
          </div>
        `
      };
  
      await transporter.sendMail(mailOptions);
      
      console.log(`OTP sent successfully to ${email}`);
      return { success: true, message: 'OTP sent successfully' };
      
    } catch (error) {
      console.error('Error sending OTP:', error);
      throw new functions.https.HttpsError('internal', `Failed to send OTP email: ${error.message}`);
    }
  });