import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../config/emailjs_config.dart';
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
    final response = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_id': EmailJsConfig.serviceId,
        'template_id': EmailJsConfig.templateId,
        'user_id': EmailJsConfig.publicKey,
        'template_params': {'to_email': email, 'otp': otp, 'purpose': purpose},
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
      metadata: {'purpose': purpose},
    );
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
