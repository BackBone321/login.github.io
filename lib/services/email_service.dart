import 'package:cloud_functions/cloud_functions.dart';

class EmailService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static Future<bool> sendOTPEmail(
    String toEmail,
    String otpCode, {
    String purpose = 'auth_verification',
  }) async {
    try {
      final callable = _functions.httpsCallable('sendOTP');
      final response = await callable.call(<String, dynamic>{
        'email': toEmail,
        'code': otpCode,
        'purpose': purpose,
      });

      final data = response.data;
      final wasSuccessful =
          data is Map && (data['success'] == true || data['status'] == 'ok');

      if (wasSuccessful) {
        print('✅ Gmail OTP sent to $toEmail');
        return true;
      }

      print('❌ Gmail OTP failed with payload: $data');
      return false;
    } catch (e) {
      print('❌ Error calling sendOTP function: $e');
      return false;
    }
  }

  static Future<bool> sendInviteEmail(
    String toEmail,
    String inviteCode, {
    String invitedBy = 'Admin',
  }) async {
    try {
      final callable = _functions.httpsCallable('sendInvitation');
      final response = await callable.call(<String, dynamic>{
        'email': toEmail,
        'code': inviteCode,
        'invitedBy': invitedBy,
      });

      final data = response.data;
      final wasSuccessful =
          data is Map && (data['success'] == true || data['status'] == 'ok');

      if (wasSuccessful) {
        print('✅ Invitation email sent to $toEmail');
        return true;
      }

      print('❌ Invitation email failed with payload: $data');
      return false;
    } catch (e) {
      print('❌ Error calling sendInvitation function: $e');
      return false;
    }
  }
}
