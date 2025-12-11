const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const oracledb = require('oracledb');
const axios = require('axios');
require('dotenv').config();

admin.initializeApp();

// ============================================
// ORACLE DATABASE CONFIGURATION
// ============================================
const oracleConfig = {
  user: process.env.ORACLE_USER,
  password: process.env.ORACLE_PASSWORD,
  connectString: process.env.ORACLE_CONNECTION_STRING,
  // For Oracle Cloud Autonomous DB, set wallet location:
  // configDir: process.env.ORACLE_WALLET_DIR,
};

// Check if Oracle is configured
const isOracleConfigured = () => {
  return oracleConfig.user && oracleConfig.password && oracleConfig.connectString;
};

// Initialize Oracle client (for thick mode with Instant Client)
// Uncomment if using Oracle Instant Client:
// try {
//   oracledb.initOracleClient({ libDir: process.env.ORACLE_CLIENT_DIR });
// } catch (err) {
//   console.error('Oracle Client initialization failed:', err);
// }

/**
 * Sync audit log to Oracle Database
 * Triggered automatically when a new audit log is created in Firestore
 */
async function syncAuditToOracle(auditLog) {
  if (!isOracleConfigured()) {
    console.warn('Oracle not configured. Skipping sync for audit log:', auditLog.id);
    return { success: false, reason: 'Oracle not configured' };
  }

  let connection;
  try {
    connection = await oracledb.getConnection(oracleConfig);

    const result = await connection.execute(
      `INSERT INTO AUDIT_LOGS (
        ID, ACTION, ENTITY_TYPE, ENTITY_ID, SEVERITY,
        ACTOR_ID, ACTOR_EMAIL, ACTOR_NAME, TARGET_USER_ID,
        DESCRIPTION, TIMESTAMP, METADATA, SYNCED_AT
      ) VALUES (
        :id, :action, :entityType, :entityId, :severity,
        :actorId, :actorEmail, :actorName, :targetUserId,
        :description, TO_TIMESTAMP(:timestamp, 'YYYY-MM-DD"T"HH24:MI:SS.FF3"Z"'),
        :metadata, CURRENT_TIMESTAMP
      )`,
      {
        id: auditLog.id || null,
        action: auditLog.action || null,
        entityType: auditLog.entityType || null,
        entityId: auditLog.entityId || null,
        severity: auditLog.severity || 'info',
        actorId: auditLog.actorId || null,
        actorEmail: auditLog.actorEmail || null,
        actorName: auditLog.actorName || null,
        targetUserId: auditLog.targetUserId || null,
        description: auditLog.description || null,
        timestamp: auditLog.timestamp || new Date().toISOString(),
        metadata: auditLog.metadata ? JSON.stringify(auditLog.metadata) : null,
      },
      { autoCommit: true }
    );

    console.log(`✅ Audit log synced to Oracle: ${auditLog.id}`);
    return { success: true, rowsAffected: result.rowsAffected };
  } catch (error) {
    console.error('❌ Oracle sync error:', error.message);
    return { success: false, error: error.message };
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (err) {
        console.error('Error closing Oracle connection:', err);
      }
    }
  }
}

/**
 * Firestore Trigger: Sync new audit logs to Oracle
 * Fires whenever a document is created in 'audit_logs' collection
 */
exports.syncAuditLogToOracle = functions
  .region('us-central1')
  .firestore.document('audit_logs/{logId}')
  .onCreate(async (snapshot, context) => {
    const auditLog = snapshot.data();
    auditLog.id = context.params.logId;

    console.log(`📝 New audit log detected: ${auditLog.id} - ${auditLog.action}`);

    const result = await syncAuditToOracle(auditLog);

    // Optionally mark as synced in Firestore
    if (result.success) {
      await snapshot.ref.update({
        oracleSynced: true,
        oracleSyncedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      await snapshot.ref.update({
        oracleSynced: false,
        oracleSyncError: result.error || result.reason,
      });
    }

    return result;
  });

/**
 * HTTP Callable: Manual sync of existing audit logs to Oracle
 * Use this to backfill existing logs or retry failed syncs
 */
exports.manualSyncAuditLogs = functions
  .region('us-central1')
  .https.onCall(async (data, context) => {
    // Optional: Require admin authentication
    // if (!context.auth) {
    //   throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
    // }

    const { limit = 100, onlyFailed = false } = data;

    let query = admin.firestore().collection('audit_logs');

    if (onlyFailed) {
      query = query.where('oracleSynced', '==', false);
    } else {
      query = query.where('oracleSynced', '==', null);
    }

    const snapshot = await query.limit(limit).get();

    const results = {
      total: snapshot.size,
      synced: 0,
      failed: 0,
      errors: [],
    };

    for (const doc of snapshot.docs) {
      const auditLog = doc.data();
      auditLog.id = doc.id;

      const result = await syncAuditToOracle(auditLog);

      if (result.success) {
        results.synced++;
        await doc.ref.update({
          oracleSynced: true,
          oracleSyncedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        results.failed++;
        results.errors.push({ id: doc.id, error: result.error || result.reason });
      }
    }

    return results;
  });

// EmailJS Configuration (using environment variables)
const emailjsServiceId = process.env.EMAILJS_SERVICE_ID || 'service_yp8e8yv';
const emailjsTemplateId = process.env.EMAILJS_TEMPLATE_ID || 'template_cp368bp';
const emailjsPublicKey = process.env.EMAILJS_PUBLIC_KEY || 'ORSGxHfkgWz4A7WVd';
const emailjsApiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

// Gmail configuration - try Firebase config first (deprecated but still works), then environment variables
// You can set these using: firebase functions:config:set gmail.email="..." gmail.password="..."
const functionsConfig = functions.config();
const gmailEmail = functionsConfig.gmail?.email || process.env.GMAIL_EMAIL;
const gmailPassword = functionsConfig.gmail?.password || process.env.GMAIL_APP_PASSWORD;

let transporter = null;
if (gmailEmail && gmailPassword) {
  transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: gmailEmail,
      pass: gmailPassword,
    },
  });
}

// Helper function to send email via EmailJS
async function sendViaEmailJS(email, code, purpose) {
  const purposeText = purpose === 'change_password'
    ? 'Use this code to reset your password.'
    : purpose === 'signup_verification'
    ? 'Use this code to verify your account.'
    : 'Use this code to verify your login.';

  const emailBody = {
    service_id: emailjsServiceId,
    template_id: emailjsTemplateId,
    user_id: emailjsPublicKey,
    template_params: {
      to_email: email,
      otp: code,
      purpose: purposeText,
      expiry_time: '10 minutes',
    },
  };

  try {
    const response = await axios.post(emailjsApiUrl, emailBody, {
      headers: { 'Content-Type': 'application/json' },
    });

    if (response.status === 200) {
      console.log(`✅ EmailJS OTP sent successfully to ${email}`);
      return { success: true };
    } else {
      throw new Error(`EmailJS returned status ${response.status}`);
    }
  } catch (error) {
    console.error('EmailJS error:', error.message);
    throw error;
  }
}

// Helper function to send email via Gmail (fallback)
async function sendViaGmail(email, code, purpose) {
  if (!transporter) {
    throw new Error('Gmail transporter is not configured');
  }

  const purposeCopy =
    purpose === 'change_password'
      ? 'Use this code to reset your password.'
      : purpose === 'signup_verification'
      ? 'Use this code to verify your account.'
      : 'Use this code to verify your login.';
  const subject =
    purpose === 'change_password'
      ? 'Reset your AGRI GUARD password'
      : 'Your AGRI GUARD verification code';

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
  console.log(`✅ Gmail OTP sent successfully to ${email}`);
  return { success: true };
}

exports.sendOTP = functions
  .region('us-central1')
  .runWith({
    timeoutSeconds: 60,
    memory: '256MB',
  })
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

    try {
      // Try Gmail first (more reliable for server-side)
      if (transporter) {
        try {
          await sendViaGmail(email, code, purpose);
          return { success: true, message: 'OTP sent successfully via Gmail' };
        } catch (gmailError) {
          console.warn('Gmail failed, trying EmailJS fallback:', gmailError.message);
          // Fallback to EmailJS if Gmail fails
          await sendViaEmailJS(email, code, purpose);
          return { success: true, message: 'OTP sent successfully via EmailJS (fallback)' };
        }
      } else {
        // If no Gmail config, try EmailJS only
        try {
          await sendViaEmailJS(email, code, purpose);
          return { success: true, message: 'OTP sent successfully via EmailJS' };
        } catch (emailjsError) {
          console.error('EmailJS also failed:', emailjsError.message);
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Email service not configured. Please set Gmail credentials using: firebase functions:config:set gmail.email="your@gmail.com" gmail.password="app-password"'
          );
        }
      }
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