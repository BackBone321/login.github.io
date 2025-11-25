import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../admin/admin_login_screen.dart';
import 'password_recovery_screen.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailPhoneController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Check if user exists in Firestore, if not create them
      final dbService = DatabaseService();
      final userModel = await dbService.getUser(userCredential.user!.uid);
      if (userModel == null) {
        await dbService.createUser(
          UserModel(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email!,
            displayName: userCredential.user!.displayName,
            isAdmin: false,
            createdAt: DateTime.now(),
          ),
        );
      }

      // Success - AuthWrapper will automatically navigate to HomeScreen
      // But we can also explicitly navigate to ensure immediate feedback
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
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
                          SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminLoginScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Admin login',
                              style: TextStyle(
                                color: primaryGreen,
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
