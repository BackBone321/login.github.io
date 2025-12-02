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
    const background = Color(0xFFF5FBF4);
    const primaryGreen = Color(0xFF2E7D32);
    const accentGreen = Color(0xFF66BB6A);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: accentGreen.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        color: primaryGreen,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Verify your email',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the 6-digit code we sent to',
                      style: TextStyle(color: Colors.grey[700], fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: primaryGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
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
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Code expires in 10 minutes',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Verify & Continue',
                      onPressed: _isLoading ? null : _verify,
                      isLoading: _isLoading,
                      isPrimary: true,
                    ),
                    const SizedBox(height: 14),
                    CustomButton(
                      text: 'Resend Code',
                      onPressed: _isResending ? null : _resend,
                      isLoading: _isResending,
                      isPrimary: false,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Didn\'t get the email? Check spam or tap Resend.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
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

