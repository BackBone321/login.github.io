import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_textfield.dart';
import 'login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String email;

  const ChangePasswordScreen({
    super.key,
    required this.email,
  });

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // User is logged in, update password directly
        await user.updatePassword(_passwordController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
        );
      } else {
        // User is not logged in, need to sign in first
        // Try to sign in with email and temporary password, then change
        // For password reset flow, user should use the email link
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please login first to change password'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Failed to change password'),
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

    return Scaffold(
      backgroundColor: Color(0xFFF8FFF8),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryGreen, Color(0xFF1B5E20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.lock_reset, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              'Change Password',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryGreen.withOpacity(0.08), Color(0xFFE8F5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: primaryGreen.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryGreen.withOpacity(0.15),
                            primaryGreen.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.security,
                        color: primaryGreen,
                        size: 32,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secure Your Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Create a strong password with at least 6 characters',
                            style: TextStyle(
                              fontSize: 13,
                              color: primaryGreen.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Form Card
              Container(
                padding: EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Color(0xFFFAFDFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: primaryGreen.withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.12),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // New Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.lock_outline,
                                  size: 16,
                                  color: primaryGreen,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'New Password',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: primaryGreen,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Enter new password',
                            obscureText: true,
                            icon: Icons.lock,
                            validator: (val) => val!.length < 6
                                ? 'At least 6 characters required'
                                : null,
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Confirm Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.lock_clock,
                                  size: 16,
                                  color: primaryGreen,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Confirm Password',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: primaryGreen,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          CustomTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm your password',
                            obscureText: true,
                            icon: Icons.lock,
                            validator: (val) =>
                                val!.isEmpty ? 'Please confirm password' : null,
                          ),
                        ],
                      ),
                      SizedBox(height: 32),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shadowColor: primaryGreen.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Update Password',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Security Tips Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Password Tips',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildPasswordTip('Use at least 6 characters'),
                    _buildPasswordTip('Mix uppercase & lowercase letters'),
                    _buildPasswordTip('Include numbers and symbols'),
                    _buildPasswordTip('Avoid common words or patterns'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordTip(String tip) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(color: Colors.blue[900], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
