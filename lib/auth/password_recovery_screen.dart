import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  _PasswordRecoveryScreenState createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();

      await _auth.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password reset email sent! Please check your inbox to verify.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = e.code == 'user-not-found'
          ? 'No account found for that email.'
          : (e.message ?? 'Failed to send reset email.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reset email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Color(0xFF2E7D32);
    final lightGreen = Color(0xFFE8F5E8);

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
          'Password Recovery',
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
                  Icons.lock_reset_rounded,
                  size: 60,
                  color: primaryGreen,
                ),
              ),
              SizedBox(height: 32),

              // Title
              Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Enter your email and we\'ll send you a verification link to reset your password',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 48),

              // Recovery Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) =>
                          val!.isEmpty ? 'Email is required' : null,
                      icon: Icons.email,
                    ),
                    SizedBox(height: 32),

                    // Send Code Button
                    CustomButton(
                      text: 'Send Verification Email',
                      onPressed: _isLoading ? null : _sendResetEmail,
                      isLoading: _isLoading,
                      isPrimary: true,
                    ),
                    SizedBox(height: 24),

                    // Back to Login
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Back to Login',
                        style: TextStyle(
                          color: primaryGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
    _emailController.dispose();
    super.dispose();
  }
}
