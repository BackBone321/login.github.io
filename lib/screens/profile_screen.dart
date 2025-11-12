import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../auth/change_password_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final darkGreen = Color(0xFF2E7D32);
    final lightBeige = Color(0xFFF5F5DC);
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      backgroundColor: lightBeige,
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: Icon(Icons.check),
              onPressed: () async {
                await _saveProfile();
                setState(() {
                  _isEditing = false;
                });
              },
            ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: _dbService.getUserStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final userModel = snapshot.data;
          if (userModel != null && !_isEditing) {
            _nameController.text = userModel.displayName ?? '';
            _bioController.text = userModel.bio ?? '';
          }
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Picture
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: darkGreen,
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: darkGreen,
                          child: Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 24),
                // Name
                _isEditing
                    ? TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : Text(
                        userModel?.displayName ?? user.email ?? 'User',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                SizedBox(height: 16),
                // Bio
                _isEditing
                    ? TextField(
                        controller: _bioController,
                        decoration: InputDecoration(
                          labelText: 'Bio',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                      )
                    : userModel?.bio != null
                        ? Text(
                            userModel!.bio!,
                            style: TextStyle(
                              fontSize: 16,
                              color: darkGreen.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          )
                        : SizedBox.shrink(),
                SizedBox(height: 32),
                // Settings Section
                _buildSettingsSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      children: [
        _buildSettingTile(
          icon: Icons.lock,
          title: 'Change Password',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangePasswordScreen(email: _auth.currentUser!.email ?? ''),
              ),
            );
          },
        ),
        Divider(),
        _buildSettingTile(
          icon: Icons.logout,
          title: 'Logout',
          onTap: () async {
            await _auth.signOut();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final darkGreen = Color(0xFF2E7D32);

    return ListTile(
      leading: Icon(icon, color: darkGreen),
      title: Text(title, style: TextStyle(color: darkGreen)),
      trailing: Icon(Icons.chevron_right, color: darkGreen),
      onTap: onTap,
    );
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _dbService.updateUser(user.uid, {
      'displayName': _nameController.text,
      'bio': _bioController.text,
    });

    // Update Firebase Auth display name
    await user.updateDisplayName(_nameController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}

