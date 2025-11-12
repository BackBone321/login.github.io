import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import 'change_password_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;

  VerifyCodeScreen({required this.email});

  @override
  _VerifyCodeScreenState createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  void _verifyCode() {
    if (!_formKey.currentState!.validate()) return;
    // In a real app, you would verify the code here
    // For now, we'll just navigate to change password screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangePasswordScreen(email: widget.email),
      ),
    );
  }

  void _resendCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code resent successfully'),
        backgroundColor: Colors.green,
      ),
    );
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
                          'Verify Code',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                        SizedBox(height: 24),
                        CustomTextField(
                          controller: _codeController,
                          label: 'Enter verification code',
                          keyboardType: TextInputType.number,
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 24),
                        CustomButton(
                          text: 'Resend code',
                          onPressed: _isLoading ? null : _resendCode,
                          isLoading: _isLoading,
                          isPrimary: true,
                        ),
                        SizedBox(height: 16),
                        CustomButton(
                          text: 'Verify',
                          onPressed: _isLoading ? null : _verifyCode,
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
    _codeController.dispose();
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

