import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../config/emailjs_config.dart';
import '../config/resend_config.dart';
import '../models/audit_log_model.dart';
import '../models/otp_model.dart';
import 'audit_service.dart';

class OTPService {
  OTPService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random.secure();
  final AuditService _auditService = AuditService();

  String _generateCode() => (100000 + _random.nextInt(900000)).toString();
  String _docId(String email, String purpose) => '${email}_$purpose';

  Future<String> sendSignupOtp(String email) {
    return _createAndSendOtp(email: email, purpose: 'signup_verification');
  }

  Future<String> resendSignupOtp(String email) {
    return _createAndSendOtp(
      email: email,
      purpose: 'signup_verification',
      invalidateExisting: true,
    );
  }

  Future<String> _createAndSendOtp({
    required String email,
    required String purpose,
    bool invalidateExisting = false,
  }) async {
    final docRef = _firestore.collection('otps').doc(_docId(email, purpose));

    if (invalidateExisting) {
      final existing = await docRef.get();
      if (existing.exists) {
        await docRef.update({'isUsed': true});
      }
    }

    final now = DateTime.now();
    final otp = OTPModel(
      id: docRef.id,
      email: email,
      code: _generateCode(),
      purpose: purpose,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 10)),
    );

    await docRef.set(otp.toMap());
    await _sendOtpViaEmailJs(email: email, otp: otp.code, purpose: purpose);
    _recordOtpAudit(
      action: invalidateExisting ? 'otp.resend' : 'otp.create',
      severity: AuditSeverity.info,
      description: 'Issued OTP for $purpose',
      email: email,
      metadata: {
        'purpose': purpose,
        'expiresAt': otp.expiresAt.toIso8601String(),
        'invalidateExisting': invalidateExisting,
      },
    );
    return otp.code;
  }

  Future<bool> verifyOtp({
    required String email,
    required String code,
    required String purpose,
  }) async {
    final docRef = _firestore.collection('otps').doc(_docId(email, purpose));
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      _recordOtpAudit(
        action: 'otp.verify_missing',
        severity: AuditSeverity.warning,
        description: 'Attempted OTP verification but no record found',
        email: email,
        metadata: {'purpose': purpose},
      );
      return false;
    }

    final otp = OTPModel.fromMap(snapshot.data()!);

    if (otp.isUsed || otp.isExpired || otp.hasExceededAttempts) {
      await docRef.update({'isUsed': true});
      _recordOtpAudit(
        action: 'otp.verify_invalid',
        severity: AuditSeverity.warning,
        description: 'OTP invalid due to status/expiry',
        email: email,
        metadata: {
          'purpose': purpose,
          'isUsed': otp.isUsed,
          'isExpired': otp.isExpired,
          'attempts': otp.attempts,
        },
      );
      return false;
    }

    if (otp.code != code) {
      await docRef.update({'attempts': otp.attempts + 1});
      _recordOtpAudit(
        action: 'otp.verify_mismatch',
        severity: AuditSeverity.warning,
        description: 'Incorrect OTP submitted',
        email: email,
        metadata: {'purpose': purpose, 'attempts': otp.attempts + 1},
      );
      return false;
    }

    await docRef.update({'isUsed': true});
    _recordOtpAudit(
      action: 'otp.verify_success',
      severity: AuditSeverity.info,
      description: 'OTP verified successfully',
      email: email,
      metadata: {'purpose': purpose},
    );
    return true;
  }

  Future<void> _sendOtpViaEmailJs({
    required String email,
    required String otp,
    required String purpose,
  }) async {
    // Use Resend for mobile apps (Android/iOS) - works on all platforms!
    // Use EmailJS only for web (since it's already configured)
    if (!kIsWeb) {
      // Mobile platform - use Resend
      try {
        await _sendOtpViaResend(email: email, otp: otp, purpose: purpose);
        _recordOtpAudit(
          action: 'otp.email_sent',
          severity: AuditSeverity.info,
          description: 'OTP email dispatched via Resend',
          email: email,
          metadata: {'purpose': purpose, 'platform': 'mobile'},
        );
      } catch (e) {
        _recordOtpAudit(
          action: 'otp.email_failed',
          severity: AuditSeverity.warning,
          description: 'Resend failed to deliver OTP',
          email: email,
          metadata: {
            'purpose': purpose,
            'platform': 'mobile',
            'error': e.toString(),
          },
        );
        throw Exception('Failed to send OTP email: $e');
      }
    } else {
      // Web platform - use EmailJS
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': EmailJsConfig.serviceId,
          'template_id': EmailJsConfig.templateId,
          'user_id': EmailJsConfig.publicKey,
          'template_params': {
            'to_email': email,
            'otp': otp,
            'purpose': purpose,
          },
        }),
      );

      if (response.statusCode != 200) {
        _recordOtpAudit(
          action: 'otp.email_failed',
          severity: AuditSeverity.warning,
          description: 'EmailJS failed to deliver OTP',
          email: email,
          metadata: {
            'purpose': purpose,
            'platform': 'web',
            'statusCode': response.statusCode,
            'body': response.body,
          },
        );
        throw Exception('EmailJS failed: ${response.body}');
      }
      _recordOtpAudit(
        action: 'otp.email_sent',
        severity: AuditSeverity.info,
        description: 'OTP email dispatched via EmailJS',
        email: email,
        metadata: {'purpose': purpose, 'platform': 'web'},
      );
    }
  }

  Future<void> _sendOtpViaResend({
    required String email,
    required String otp,
    required String purpose,
  }) async {
    final purposeText = purpose == 'change_password'
        ? 'Use this code to reset your password.'
        : 'Use this code to verify your account.';

    final subject = purpose == 'change_password'
        ? 'Reset your AGRI GUARD password'
        : 'Your AGRI GUARD verification code';

    final htmlBody =
        '''
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <div style="background-color: #2E7D32; color: white; padding: 20px; text-align: center;">
    <h1 style="margin: 0;">AGRI GUARD</h1>
    <p style="margin: 5px 0 0;">${purpose == 'change_password' ? 'Password Reset' : 'Sign-In Verification'}</p>
  </div>
  <div style="padding: 30px; background-color: #f9f9f9;">
    <h2 style="color: #2E7D32; text-align: center;">Your One-Time Password</h2>
    <div style="text-align: center; margin: 30px 0;">
      <div style="font-size: 36px; font-weight: bold; color: #2E7D32; background-color: #C8E6C9; padding: 20px; border-radius: 10px; display: inline-block; letter-spacing: 5px;">
        $otp
      </div>
    </div>
    <p style="text-align: center; color: #666; font-size: 16px;">
      This code will expire in <strong>10 minutes</strong>.
    </p>
    <p style="text-align: center; color: #666; font-size: 14px;">
      $purposeText
    </p>
    <p style="text-align: center; color: #666; font-size: 12px;">
      If you did not request this code, you can safely ignore this email.
    </p>
  </div>
  <div style="background-color: #2E7D32; color: white; padding: 15px; text-align: center;">
    <p style="margin: 0;">© ${DateTime.now().year} AGRI GUARD. All rights reserved.</p>
  </div>
</div>
''';

    final response = await http.post(
      Uri.parse(ResendConfig.apiUrl),
      headers: {
        'Authorization': 'Bearer ${ResendConfig.apiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'from': ResendConfig.fromEmail,
        'to': [email],
        'subject': subject,
        'html': htmlBody,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Resend API error: ${response.body}');
    }
  }

  void _recordOtpAudit({
    required String action,
    required String severity,
    required String description,
    required String email,
    Map<String, dynamic>? metadata,
  }) {
    unawaited(
      _auditService.logAction(
        action: action,
        entityType: 'otp',
        entityId: email,
        severity: severity,
        description: description,
        targetUserId: email,
        metadata: metadata,
      ),
    );
  }
}
