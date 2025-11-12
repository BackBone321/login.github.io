import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
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
      UserCredential user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await user.user?.updateDisplayName(_nameController.text.trim());
      
      // Create user in Firestore
      final dbService = DatabaseService();
      await dbService.createUser(UserModel(
        uid: user.user!.uid,
        email: user.user!.email!,
        displayName: _nameController.text.trim(),
        isAdmin: false,
        createdAt: DateTime.now(),
      ));
      
      // Sign out the user so they need to login
      await FirebaseAuth.instance.signOut();
      
      // Show success message and navigate to login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created successfully! Please login.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
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
    final darkGreen = Color(0xFF2E7D32);
    final lightGreen = Color(0xFFC8E6C9);
    final lightBeige = Color(0xFFF5F5DC);

    return Scaffold(
      backgroundColor: lightBeige,
      body: SafeArea(
        child: Column(
          children: [
            // Header Image (Greenhouse)
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF81C784),
                    Color(0xFF66BB6A),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GreenhousePainter(),
                    ),
                  ),
                ],
              ),
            ),
            // Logo
            Transform.translate(
              offset: Offset(0, -40),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.eco,
                  size: 50,
                  color: darkGreen,
                ),
              ),
            ),
            SizedBox(height: 20),
            // Content Box
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          controller: _nameController,
                          label: 'Enter your name',
                          icon: Icons.person,
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 16),
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 16),
                        CustomTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 16),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Enter password',
                          icon: Icons.lock,
                          obscureText: true,
                          validator: (val) => val!.length < 6 ? 'At least 6 characters' : null,
                        ),
                        SizedBox(height: 16),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm password',
                          icon: Icons.lock,
                          obscureText: true,
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 24),
                        CustomButton(
                          text: 'Create account',
                          onPressed: _isLoading ? null : _signup,
                          isLoading: _isLoading,
                          isPrimary: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Footer Wave
            CustomPaint(
              size: Size(double.infinity, 80),
              painter: WavePainter(darkGreen),
            ),
          ],
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

// Custom painter for greenhouse pattern
class GreenhousePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      path.moveTo(i * size.width / 4, size.height);
      path.quadraticBezierTo(
        i * size.width / 4 + size.width / 8,
        size.height * 0.3,
        (i + 1) * size.width / 4,
        size.height,
      );
      canvas.drawPath(path, paint);
    }

    for (int i = 0; i < 3; i++) {
      final y = size.height * 0.6 + i * 30.0;
      for (int j = 0; j < 8; j++) {
        canvas.drawCircle(
          Offset(j * size.width / 7 + 20, y),
          8,
          Paint()..color = Colors.white.withOpacity(0.3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for wave footer
class WavePainter extends CustomPainter {
  final Color color;

  WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.2,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.8,
      size.width,
      size.height * 0.5,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
