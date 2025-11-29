import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../services/database_service.dart';
import '../services/otp_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'email_otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpService = OTPService();
  bool _isLoading = false;

  Future<void> _signup() async {
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
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw FirebaseAuthException(
          code: 'user-not-created',
          message: 'Unable to create account. Please try again.',
        );
      }

      await firebaseUser.updateDisplayName(_nameController.text.trim());

      // Create user in Firestore
      final dbService = DatabaseService();
      await dbService.createUser(
        UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email!,
          displayName: _nameController.text.trim(),
          isAdmin: false,
          createdAt: DateTime.now(),
          isOnline: false,
          lastSeen: DateTime.now(),
          avatarStyle: defaultAvatarStyle,
        ),
      );

      await _otpService.sendSignupOtp(firebaseUser.email!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account created! Enter the verification code sent to ${firebaseUser.email}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailOtpScreen(
            email: firebaseUser.email!,
            userId: firebaseUser.uid,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        try {
          final signInCredential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
              );

          final existingUser = signInCredential.user;
          if (existingUser != null && existingUser.email != null) {
            final dbService = DatabaseService();
            var profile = await dbService.getUser(existingUser.uid);

            if (profile == null) {
              profile = UserModel(
                uid: existingUser.uid,
                email: existingUser.email!,
                displayName: existingUser.displayName ?? _nameController.text,
                isAdmin: false,
                createdAt: DateTime.now(),
                isOnline: false,
                avatarStyle: defaultAvatarStyle,
              );
              await dbService.createUser(profile);
            }

            if (!profile.isEmailVerified) {
              await _otpService.resendSignupOtp(existingUser.email!);
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'An account already exists for ${existingUser.email}. '
                    'Enter the verification code we just re-sent to finish signup.',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => EmailOtpScreen(
                    email: existingUser.email!,
                    userId: existingUser.uid,
                  ),
                ),
              );
              return;
            }
          }

          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'This email is already verified. Please sign in instead.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          return;
        } on FirebaseAuthException catch (signInError) {
          final message = signInError.code == 'wrong-password'
              ? 'This email is already registered. Enter the password you used for this account or tap "Forgot Password".'
              : (signInError.message ?? 'Unable to reuse existing account.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Signup failed'),
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
          'Create Account',
          style: TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(height: 20),

              // Simple Logo Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: lightGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.eco, size: 60, color: primaryGreen),
              ),
              SizedBox(height: 32),

              // Title
              Text(
                'Join Us',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Create your account to get started',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 48),

              // Signup Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      validator: (val) =>
                          val!.isEmpty ? 'Name is required' : null,
                      icon: Icons.person,
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) =>
                          val!.isEmpty ? 'Email is required' : null,
                      icon: Icons.email,
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      validator: (val) =>
                          val!.isEmpty ? 'Phone number is required' : null,
                      icon: Icons.phone,
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      obscureText: true,
                      showPasswordToggle: true,
                      validator: (val) => val!.length < 6
                          ? 'Password must be at least 6 characters'
                          : null,
                      icon: Icons.lock,
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      obscureText: true,
                      showPasswordToggle: true,
                      validator: (val) =>
                          val!.isEmpty ? 'Please confirm your password' : null,
                      icon: Icons.lock,
                    ),
                    SizedBox(height: 32),

                    // Create Account Button
                    CustomButton(
                      text: 'Create Account',
                      onPressed: _isLoading ? null : _signup,
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

                    // Sign In Button
                    CustomButton(
                      text: 'Already have an account? Sign In',
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                      ),
                      isPrimary: false,
                    ),
                    SizedBox(height: 32),
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
