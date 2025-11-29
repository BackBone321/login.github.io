import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../services/otp_service.dart';
import '../services/database_service.dart';
import 'home_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class EmailOtpScreen extends StatefulWidget {
  final String email;
  final String userId;
  final bool shouldOpenAdmin;

  const EmailOtpScreen({
    super.key,
    required this.email,
    required this.userId,
    this.shouldOpenAdmin = false,
  });

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _otpService = OTPService();
  final _dbService = DatabaseService();
  bool _isLoading = false;
  bool _isResending = false;

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final isValid = await _otpService.verifyOtp(
        email: widget.email,
        code: _codeController.text.trim(),
        purpose: 'signup_verification',
      );

      if (!isValid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid or expired code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _dbService.updateUser(widget.userId, {
        'isEmailVerified': true,
        'isOnline': true,
        'lastSeen': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => widget.shouldOpenAdmin
              ? const AdminDashboardScreen()
              : HomeScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      await _otpService.resendSignupOtp(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New code sent to ${widget.email}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF111111);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Enter the code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Type the 6-digit code we sent to\n${widget.email}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: CustomTextField(
                  controller: _codeController,
                  label: 'Verification Code',
                  keyboardType: TextInputType.number,
                  validator: (val) => val != null && val.length == 6
                      ? null
                      : 'Enter the 6-digit code',
                  icon: Icons.lock_outline,
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Verify & Continue',
                onPressed: _isLoading ? null : _verify,
                isLoading: _isLoading,
                isPrimary: true,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Resend Code',
                onPressed: _isResending ? null : _resend,
                isLoading: _isResending,
                isPrimary: false,
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
