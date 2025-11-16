import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
// Remove Firebase Auth import if not needed
// import 'package:firebase_auth/firebase_auth.dart';
import '../models/otp_model.dart';
import 'email_service.dart';

class OTPService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Remove Firebase Auth instance if not needed
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a 6-digit OTP code
  String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send OTP for password change
  Future<String> sendOTPForPasswordChange(String email) async {
    try {
      // Generate OTP
      final code = _generateOTP();
      final otpId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();
      final expiresAt = now.add(Duration(minutes: 10));

      // Create OTP model
      final otp = OTPModel(
        id: otpId,
        email: email,
        code: code,
        purpose: 'change_password',
        createdAt: now,
        expiresAt: expiresAt,
      );

      // Save to Firestore
      await _firestore.collection('otps').doc(otpId).set(otp.toMap());

      // Send email via EmailJS
      final emailSent = await EmailService.sendOTPEmail(email, code);

      if (emailSent) {
        print('✅ OTP email sent to $email: $code');
        return code;
      } else {
        // Fallback: show OTP in console
        print('❌ Email failed - OTP for $email: $code');
        print('📱 Please check the console for the OTP code during testing');
        return code; // Still return code for testing
      }
    } catch (e) {
      print('Error sending OTP: $e');
      // For testing, still generate and return OTP even if email fails
      final code = _generateOTP();
      print('🔄 Fallback OTP for $email: $code');
      return code;
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String email, String code, String purpose) async {
    try {
      // Find the OTP in Firestore
      final snapshot = await _firestore
          .collection('otps')
          .where('email', isEqualTo: email)
          .where('purpose', isEqualTo: purpose)
          .where('isUsed', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print('❌ No OTP found for $email');
        return false;
      }

      final doc = snapshot.docs.first;
      final otp = OTPModel.fromMap(doc.data());

      // Check if OTP is expired
      if (otp.isExpired) {
        print('❌ OTP expired for $email');
        await doc.reference.update({'isUsed': true});
        return false;
      }

      // Check attempt limit
      if (otp.hasExceededAttempts) {
        print('❌ Too many attempts for $email');
        await doc.reference.update({'isUsed': true});
        return false;
      }

      // Check if code matches
      if (otp.code != code) {
        print('❌ Invalid OTP for $email');
        // Increment attempts
        final updatedAttempts = otp.attempts + 1;
        await doc.reference.update({'attempts': updatedAttempts});
        return false;
      }

      // Mark OTP as used on successful verification
      await doc.reference.update({'isUsed': true});
      print('✅ OTP verified successfully for $email');

      return true;
    } catch (e) {
      print('OTP verification error: $e');
      return false;
    }
  }

  // Resend OTP
  Future<String> resendOTP(String email) async {
    try {
      // Invalidate old OTPs for this email and purpose
      final oldOtps = await _firestore
          .collection('otps')
          .where('email', isEqualTo: email)
          .where('purpose', isEqualTo: 'change_password')
          .where('isUsed', isEqualTo: false)
          .get();

      for (var doc in oldOtps.docs) {
        await doc.reference.update({'isUsed': true});
      }

      // Generate and send new OTP
      return await sendOTPForPasswordChange(email);
    } catch (e) {
      print('Error resending OTP: $e');
      throw Exception('Failed to resend OTP: $e');
    }
  }
}
