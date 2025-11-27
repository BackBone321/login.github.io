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

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) {
          return LoginScreen();
        }

        final firebaseUser = snapshot.data!;
        return StreamBuilder<UserModel?>(
          stream: dbService.getUserStream(firebaseUser.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(body: Center(child: CircularProgressIndicator()));
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
