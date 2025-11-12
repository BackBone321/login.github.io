import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import 'verify_code_screen.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  @override
  _PasswordRecoveryScreenState createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // For email password reset
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailPhoneController.text.trim(),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(
            email: _emailPhoneController.text.trim(),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Failed to send code'),
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
                        Text(
                          'Recovery password',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                        SizedBox(height: 24),
                        CustomTextField(
                          controller: _emailPhoneController,
                          label: 'Email or mobile number',
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 24),
                        CustomButton(
                          text: 'Send code',
                          onPressed: _isLoading ? null : _sendCode,
                          isLoading: _isLoading,
                          isPrimary: true,
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
    _emailPhoneController.dispose();
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

