import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailService {
  // IMPORTANT: Get these from https://dashboard.emailjs.com/admin/account
  // NOT from Firebase - these are EmailJS credentials
  static const String serviceId = 'your_emailjs_service_id';  // From EmailJS dashboard → Email Services
  static const String templateId = 'your_emailjs_template_id'; // From EmailJS dashboard → Email Templates  
  static const String userId = 'your_emailjs_public_key';     // From EmailJS dashboard → Account → General → Public Key

  static Future<bool> sendOTPEmail(String toEmail, String otpCode) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'to_email': toEmail,
            'otp_code': otpCode,
            'app_name': 'AGRI GUARD',
            'expiry_time': '10 minutes',
          },
        }),
      );

      print('📧 EmailJS Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Email sent successfully to $toEmail');
        return true;
      } else {
        print('❌ Email failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending email: $e');
      return false;
    }
  }
}
