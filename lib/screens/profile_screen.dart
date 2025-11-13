import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../auth/change_password_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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
    final primaryGreen = Color(0xFF2E7D32);
    final lightGreen = Color(0xFFE8F5E8);
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Edit Profile',
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
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: _dbService.getUserStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          }
          final userModel = snapshot.data;
          if (userModel != null && !_isEditing) {
            _nameController.text = userModel.displayName ?? '';
            _bioController.text = userModel.bio ?? '';
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Farm Header Image
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        'assets/images/farm_header.jpg',
                      ), // Add farm image to assets
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        primaryGreen.withOpacity(0.3),
                        BlendMode.overlay,
                      ),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [primaryGreen, primaryGreen.withOpacity(0.7)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Farm Icon Overlay
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.agriculture,
                            size: 40,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile Information Card
                Container(
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Picture
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: primaryGreen,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Name Field
                      _isEditing
                          ? TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                labelStyle: TextStyle(color: primaryGreen),
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: primaryGreen,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryGreen),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: primaryGreen.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryGreen),
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                Text(
                                  userModel?.displayName ??
                                      user.email ??
                                      'Farmer',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Farm Owner',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),

                      SizedBox(height: 16),

                      // Email Display
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: lightGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.email, color: primaryGreen, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                user.email ?? 'No email',
                                style: TextStyle(
                                  color: primaryGreen,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Bio Field
                      _isEditing
                          ? TextFormField(
                              controller: _bioController,
                              decoration: InputDecoration(
                                labelText: 'About Your Farm',
                                labelStyle: TextStyle(color: primaryGreen),
                                prefixIcon: Icon(
                                  Icons.info,
                                  color: primaryGreen,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryGreen),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: primaryGreen.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryGreen),
                                ),
                              ),
                              maxLines: 3,
                            )
                          : userModel?.bio != null && userModel!.bio!.isNotEmpty
                          ? Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: lightGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'About My Farm',
                                    style: TextStyle(
                                      color: primaryGreen,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    userModel.bio!,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 16,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox.shrink(),
                    ],
                  ),
                ),

                // Account Actions Section
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildActionTile(
                        icon: Icons.lock,
                        title: 'Change Password',
                        subtitle: 'Update your account security',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangePasswordScreen(
                                email: _auth.currentUser!.email ?? '',
                              ),
                            ),
                          );
                        },
                      ),
                      Divider(height: 1),
                      _buildActionTile(
                        icon: Icons.help,
                        title: 'Help & Support',
                        subtitle: 'Get help with farming',
                        onTap: () {
                          // Add help functionality
                        },
                      ),
                      Divider(height: 1),
                      _buildActionTile(
                        icon: Icons.logout,
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                'Logout',
                                style: TextStyle(color: primaryGreen),
                              ),
                              content: Text('Are you sure you want to logout?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('Logout'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _auth.signOut();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final primaryGreen = Color(0xFF2E7D32);

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: primaryGreen, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: primaryGreen),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: primaryGreen.withOpacity(0.5)),
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
