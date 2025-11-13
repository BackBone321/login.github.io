import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../services/otp_service.dart';
import 'change_password_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;

  const VerifyCodeScreen({super.key, required this.email});

  @override
  _VerifyCodeScreenState createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _otpService = OTPService();
  bool _isLoading = false;

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final code = _codeController.text.trim();

      // Verify OTP
      final isValid = await _otpService.verifyOTP(
        widget.email,
        code,
        'change_password',
      );

      if (isValid) {
        // Navigate to change password screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChangePasswordScreen(email: widget.email, otpVerified: true),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid or expired code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);
    try {
      final otpCode = await _otpService.resendOTP(widget.email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Code resent successfully. Code: $otpCode (for testing)',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend code: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Color(0xFF2E7D32);
    final lightGreen = Color(0xFFE8F5E8);
    final accentGreen = Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryGreen),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Verify Code',
          style: TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Simple Logo Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: lightGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  size: 60,
                  color: primaryGreen,
                ),
              ),
              SizedBox(height: 32),

              // Title
              Text(
                'Verify Your Code',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Enter the verification code sent to',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 4),
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: primaryGreen,
                ),
              ),
              SizedBox(height: 48),

              // Verification Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _codeController,
                      label: 'Verification Code',
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                          val!.isEmpty ? 'Code is required' : null,
                      icon: Icons.lock_outline,
                    ),
                    SizedBox(height: 32),

                    // Verify Button
                    CustomButton(
                      text: 'Verify Code',
                      onPressed: _isLoading ? null : _verifyCode,
                      isLoading: _isLoading,
                      isPrimary: true,
                    ),
                    SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Resend Code Button
                    CustomButton(
                      text: 'Resend Code',
                      onPressed: _isLoading ? null : _resendCode,
                      isLoading: _isLoading,
                      isPrimary: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
