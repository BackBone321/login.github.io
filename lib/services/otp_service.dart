import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/otp_model.dart';

class OTPService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a 6-digit OTP code
  String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Send OTP for password change
  Future<String> sendOTPForPasswordChange(String email) async {
    // Generate OTP
    final code = _generateOTP();
    final otpId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    final expiresAt = now.add(Duration(minutes: 10)); // OTP expires in 10 minutes

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

    // Send email via Firebase Auth (this will send a password reset email with the code)
    // For a real implementation, you might want to use a service like SendGrid, Twilio, etc.
    // For now, we'll use Firebase's sendPasswordResetEmail and store the OTP in Firestore
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      // If email sending fails, still store the OTP
      print('Email sending failed: $e');
    }

    // In a real app, you would send the OTP via email/SMS service
    // For now, we'll also log it (remove in production)
    print('OTP for $email: $code'); // Remove this in production

    return code; // Return code for testing (remove in production)
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
        return false;
      }

      final doc = snapshot.docs.first;
      final otp = OTPModel.fromMap(doc.data());

      // Check if OTP is valid
      if (!otp.isValid) {
        return false;
      }

      // Check if code matches
      if (otp.code != code) {
        return false;
      }

      // Mark OTP as used
      await _firestore.collection('otps').doc(doc.id).update({
        'isUsed': true,
      });

      return true;
    } catch (e) {
      print('OTP verification error: $e');
      return false;
    }
  }

  // Resend OTP
  Future<String> resendOTP(String email) async {
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
  }

  // Clean up expired OTPs (can be called periodically)
  Future<void> cleanupExpiredOTPs() async {
    final now = DateTime.now();
    final expiredOtps = await _firestore
        .collection('otps')
        .where('expiresAt', isLessThan: now.toIso8601String())
        .get();

    for (var doc in expiredOtps.docs) {
      await doc.reference.delete();
    }
  }
}

