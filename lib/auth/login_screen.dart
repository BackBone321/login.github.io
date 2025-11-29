import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../services/database_service.dart';
import '../services/otp_service.dart';
import '../services/admin_gatekeeper.dart';
import '../models/user_model.dart';
import 'password_recovery_screen.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'email_otp_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final OTPService _otpService = OTPService();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final normalizedEmail = normalizeAdminEmailInput(
        _emailPhoneController.text.trim(),
      );
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: normalizedEmail,
            password: _passwordController.text.trim(),
          );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Unable to sign in. Please try again.',
        );
      }

      // Check if user exists in Firestore, if not create them
      final dbService = DatabaseService();
      final bool isAdminAccount = isAdminEmail(firebaseUser.email);

      UserModel? userModel = await dbService.getUser(firebaseUser.uid);
      bool shouldOpenAdmin = isAdminAccount || (userModel?.isAdmin ?? false);

      if (userModel == null) {
        userModel = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email!,
          displayName: firebaseUser.displayName,
          isAdmin: isAdminAccount,
          isEmailVerified: false,
          createdAt: DateTime.now(),
          isOnline: true,
          lastSeen: DateTime.now(),
          avatarStyle: defaultAvatarStyle,
        );
        await dbService.createUser(userModel);
        shouldOpenAdmin = isAdminAccount;
      } else {
        await dbService.updateUserPresence(
          isOnline: true,
          uid: firebaseUser.uid,
        );
        if (isAdminAccount && userModel.isAdmin != true) {
          await dbService.updateUser(firebaseUser.uid, {'isAdmin': true});
        }
        shouldOpenAdmin = isAdminAccount || userModel.isAdmin;
      }

      final isVerified = userModel.isEmailVerified;
      if (!isVerified) {
        await _otpService.sendSignupOtp(firebaseUser.email!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Enter the verification code sent to ${firebaseUser.email}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailOtpScreen(
              email: firebaseUser.email!,
              userId: firebaseUser.uid,
              shouldOpenAdmin: shouldOpenAdmin,
            ),
          ),
        );
        return;
      }

      // Success - AuthWrapper will automatically navigate to HomeScreen
      // But we can also explicitly navigate to ensure immediate feedback
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                shouldOpenAdmin ? const AdminDashboardScreen() : HomeScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Login failed'),
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
    const primaryGreen = Color(0xFF2E7D32);
    const lightGreen = Color(0xFFE8F5E8);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                      child: Icon(Icons.eco, size: 60, color: primaryGreen),
                    ),
                    SizedBox(height: 32),

                    // Title
                    Text(
                      'AGRI GUARD',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sign in to continue',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 48),

                    // Login Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _emailPhoneController,
                            label: 'Email Address',
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) =>
                                val!.isEmpty ? 'Email is required' : null,
                            icon: Icons.email,
                          ),
                          SizedBox(height: 16),
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            obscureText: true,
                            showPasswordToggle: true,
                            validator: (val) =>
                                val!.isEmpty ? 'Password is required' : null,
                            icon: Icons.lock,
                          ),
                          SizedBox(height: 12),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PasswordRecoveryScreen(),
                                ),
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 32),

                          // Login Button
                          CustomButton(
                            text: 'Sign In',
                            onPressed: _isLoading ? null : _login,
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

                          // Sign Up Button
                          CustomButton(
                            text: 'Create Account',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => SignupScreen()),
                            ),
                            isPrimary: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
