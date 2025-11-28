import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../services/database_service.dart';
import '../services/admin_gatekeeper.dart';
import '../models/user_model.dart';
import '../admin/admin_dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Widget _buildLoadingShell() {
    const primaryGreen = Color(0xFF2E7D32);
    const tint = Color(0xFFF3FBF3);

    return Scaffold(
      backgroundColor: tint,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(Icons.eco_outlined, size: 48, color: primaryGreen),
              ),
              const SizedBox(height: 24),
              const Text(
                'AGRI GUARD',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Syncing your profile and live telemetry…',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
              const SizedBox(height: 12),
              Text(
                'Hang tight, preparing the dashboard.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShell();
        }
        if (!snapshot.hasData) {
          return LoginScreen();
        }

        final firebaseUser = snapshot.data!;
        return StreamBuilder<UserModel?>(
          stream: dbService.getUserStream(firebaseUser.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingShell();
            }

            final profile = userSnapshot.data;
            if (shouldRouteToAdmin(profile, firebaseUser.email)) {
              return const AdminDashboardScreen();
            }
            return const HomeScreen();
          },
        );
      },
    );
  }
}
