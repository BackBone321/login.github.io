import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
    // Use Firebase Cloud Functions for all platforms (web and mobile)
    // This allows EmailJS to work on mobile through the backend
    try {
      await _sendOtpViaFirebaseFunctions(
        email: email,
        otp: otp,
        purpose: purpose,
      );
      _recordOtpAudit(
        action: 'otp.email_sent',
        severity: AuditSeverity.info,
        description: 'OTP email dispatched via Firebase Functions (EmailJS)',
        email: email,
        metadata: {
          'purpose': purpose,
          'platform': kIsWeb ? 'web' : 'mobile',
          'method': 'firebase_functions_emailjs',
        },
      );
    } catch (e) {
      print('❌ OTP email failed for $email: $e');
      _recordOtpAudit(
        action: 'otp.email_failed',
        severity: AuditSeverity.warning,
        description: 'Firebase Functions failed to deliver OTP',
        email: email,
        metadata: {
          'purpose': purpose,
          'platform': kIsWeb ? 'web' : 'mobile',
          'error': e.toString(),
        },
      );
      // Re-throw with more context for debugging
      throw Exception('Failed to send OTP email. Error: $e');
    }
  }

  Future<void> _sendOtpViaFirebaseFunctions({
    required String email,
    required String otp,
    required String purpose,
  }) async {
    try {
      print('📧 Attempting to send OTP via Firebase Functions to $email');

      // Use the same region as defined in Firebase Functions (us-central1)
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable(
        'sendOTP',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );

      print('📡 Calling Firebase Function sendOTP...');
      final response = await callable.call(<String, dynamic>{
        'email': email,
        'code': otp,
        'purpose': purpose,
      });

      print('📨 Firebase Function response received: ${response.data}');
      final data = response.data;

      // Check for success in various formats
      final wasSuccessful =
          data is Map &&
          (data['success'] == true ||
              data['status'] == 'ok' ||
              (data['message'] != null &&
                  data['message'].toString().toLowerCase().contains(
                    'success',
                  )));

      if (!wasSuccessful) {
        final errorMsg = data is Map
            ? 'Error: ${data['error'] ?? data['message'] ?? data.toString()}'
            : 'Unknown error: ${data.toString()}';
        print('❌ Firebase Function error response: $data');
        throw Exception(errorMsg);
      }

      print('✅ Firebase Function OTP sent successfully to $email');
    } on FirebaseFunctionsException catch (e) {
      print('❌ Firebase Functions exception: ${e.code} - ${e.message}');
      print('Details: ${e.details}');
      
      // Provide user-friendly error messages
      if (e.code == 'not-found') {
        throw Exception('Email service not configured. Please contact support or check Firebase Functions deployment.');
      } else if (e.code == 'failed-precondition') {
        throw Exception('Email service configuration is missing. Please check Firebase Functions setup.');
      }
      
      // Generic error message for users
      throw Exception('Failed to send email. Please try again later or contact support.');
    } catch (e, stackTrace) {
      print('❌ Firebase Functions error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to send OTP via Firebase Functions: $e');
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
