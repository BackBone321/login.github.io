import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../auth/change_password_screen.dart';
import '../auth/login_screen.dart';
import '../widgets/guardian_avatar.dart';

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
  UserModel? _cachedUser;
  String? _selectedAvatarId;

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Color(0xFF2E7D32);
    final lightGreen = Color(0xFFE8F5E8);
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8FFF8),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryGreen, Color(0xFF1B5E20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              'My Profile',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          if (!_isEditing)
            Container(
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                    _selectedAvatarId ??=
                        _cachedUser?.avatarStyle ?? defaultAvatarStyle;
                  });
                },
                tooltip: 'Edit Profile',
              ),
            )
          else
            Container(
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(Icons.check),
                onPressed: () async {
                  await _saveProfile();
                  setState(() {
                    _isEditing = false;
                    _selectedAvatarId = null;
                  });
                },
                tooltip: 'Save Changes',
              ),
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
          _cachedUser = userModel;
          if (userModel != null && !_isEditing) {
            _nameController.text = userModel.displayName ?? '';
            _bioController.text = userModel.bio ?? '';
          }
          final avatarId =
              _selectedAvatarId ?? userModel?.avatarStyle ?? defaultAvatarStyle;
          final avatarCharacter = guardianAvatarFor(avatarId);

          return SingleChildScrollView(
            child: Column(
              children: [
                // Farm Header Banner
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryGreen,
                        Color(0xFF1B5E20),
                        primaryGreen.withOpacity(0.85),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative Pattern
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.1,
                          child: CustomPaint(painter: _PatternPainter()),
                        ),
                      ),
                      // Farm Icon Overlay
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.95),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.agriculture,
                            size: 48,
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
                  padding: EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Color(0xFFFAFDFA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: primaryGreen.withOpacity(0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.12),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Picture
                      GestureDetector(
                        onTap: _isEditing
                            ? () => _openAvatarPicker(avatarId)
                            : null,
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GuardianAvatar(
                                  style: avatarCharacter.id,
                                  size: 104,
                                ),
                                if (_isEditing)
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primaryGreen,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.brush,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              avatarCharacter.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: primaryGreen,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              avatarCharacter.tagline,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_isEditing) ...[
                              SizedBox(height: 8),
                              Text(
                                'Tap to customize your guardian',
                                style: TextStyle(
                                  color: primaryGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ] else ...[
                              SizedBox(height: 10),
                              _buildGuardianUsageChip(avatarCharacter),
                            ],
                            _buildStatusBadge(userModel),
                          ],
                        ),
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
                    gradient: LinearGradient(
                      colors: [Colors.white, Color(0xFFFAFDFA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryGreen.withOpacity(0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.1),
                        blurRadius: 15,
                        offset: Offset(0, 6),
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
                          _showHelpAndSupport();
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
                            final currentUid = _auth.currentUser?.uid;
                            if (currentUid != null) {
                              await _dbService.updateUserPresence(
                                isOnline: false,
                                uid: currentUid,
                              );
                            }
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryGreen.withOpacity(0.15),
                    primaryGreen.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryGreen, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryGreen,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: primaryGreen.withOpacity(0.6),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final avatarId =
        _selectedAvatarId ?? _cachedUser?.avatarStyle ?? defaultAvatarStyle;

    await _dbService.updateUser(user.uid, {
      'displayName': _nameController.text,
      'bio': _bioController.text,
      'avatarStyle': avatarId,
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

  void _showHelpAndSupport() {
    final primaryGreen = Color(0xFF2E7D32);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: primaryGreen,
            elevation: 0,
            title: Text(
              'Help & Support',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFFE8F5E8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.agriculture, size: 48, color: primaryGreen),
                      SizedBox(height: 16),
                      Text(
                        'Welcome to FarmGuard!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your smart farming companion for pest detection, weather monitoring, and community support.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),

                // Quick Help Section
                Text(
                  'Quick Help',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                SizedBox(height: 16),

                _buildHelpCard(
                  icon: Icons.camera_alt,
                  title: 'Taking Photos for Detection',
                  description:
                      'Take clear photos of plants or pests. Ensure good lighting and focus on the affected area for best results.',
                ),

                _buildHelpCard(
                  icon: Icons.people,
                  title: 'Connecting with Farmers',
                  description:
                      'Add friends to share detections and get advice. Join groups to discuss farming topics with the community.',
                ),

                _buildHelpCard(
                  icon: Icons.message,
                  title: 'Messaging & Groups',
                  description:
                      'Use private messages for direct communication. Create or join groups for farming discussions.',
                ),

                _buildHelpCard(
                  icon: Icons.wb_sunny,
                  title: 'Weather & Alerts',
                  description:
                      'Check weather conditions and receive alerts about optimal farming conditions.',
                ),

                SizedBox(height: 32),

                // Farming Tips Section
                Text(
                  'Farming Tips',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                SizedBox(height: 16),

                _buildTipCard(
                  '🌱 Plant Health',
                  'Regular monitoring helps catch issues early. Use our detection feature weekly for best results.',
                ),

                _buildTipCard(
                  '🐛 Pest Control',
                  'Identify pests early to prevent crop damage. Natural solutions are often most effective.',
                ),

                _buildTipCard(
                  '🌦️ Weather Planning',
                  'Plan activities around weather forecasts. Monitor soil moisture and irrigation needs.',
                ),

                _buildTipCard(
                  '👥 Community Support',
                  'Connect with other farmers for advice and support. Share your experiences and learn from others.',
                ),

                SizedBox(height: 32),

                // Contact Information
                Text(
                  'Contact Us',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                SizedBox(height: 16),

                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryGreen.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      _buildContactItem(
                        icon: Icons.email,
                        title: 'Email Support',
                        subtitle: 'support@farmguard.com',
                        onTap: () {
                          // Could open email app
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Email: support@farmguard.com'),
                            ),
                          );
                        },
                      ),
                      Divider(),
                      _buildContactItem(
                        icon: Icons.phone,
                        title: 'Phone Support',
                        subtitle: '+1 (555) 123-4567',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Phone: +1 (555) 123-4567')),
                          );
                        },
                      ),
                      Divider(),
                      _buildContactItem(
                        icon: Icons.language,
                        title: 'Website',
                        subtitle: 'www.farmguard.com',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Website: www.farmguard.com'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // FAQ Section
                Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                SizedBox(height: 16),

                _buildFAQItem(
                  'How accurate is the pest detection?',
                  'Our AI detection system is trained on thousands of pest images and typically achieves 85-95% accuracy. Always consult with local agricultural experts for critical decisions.',
                ),

                _buildFAQItem(
                  'Can I use this app offline?',
                  'Basic features work offline, but detection analysis and messaging require internet connection.',
                ),

                _buildFAQItem(
                  'How do I invite friends to join?',
                  'Go to the People screen and use the search function to find friends. Send friend requests and start messaging once accepted.',
                ),

                _buildFAQItem(
                  'What types of crops are supported?',
                  'The app works with most common crops including vegetables, fruits, grains, and ornamental plants.',
                ),

                SizedBox(height: 32),

                // App Version
                Center(
                  child: Text(
                    'FarmGuard v1.0.0',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final primaryGreen = Color(0xFF2E7D32);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGreen.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryGreen, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: primaryGreen,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(String emoji, String tip) {
    final primaryGreen = Color(0xFF2E7D32);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 24)),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(color: primaryGreen, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final primaryGreen = Color(0xFF2E7D32);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: primaryGreen, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: primaryGreen,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: primaryGreen.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    final primaryGreen = Color(0xFF2E7D32);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGreen.withOpacity(0.1)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: primaryGreen,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 16, left: 16, right: 16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _openAvatarPicker(String currentId) {
    final primaryGreen = Color(0xFF2E7D32);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 24),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Text(
                      'Choose Your Guardian',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryGreen,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pick a character who represents your farming spirit.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.85,
                        physics: BouncingScrollPhysics(),
                        children: guardianAvatarOptions.map((character) {
                          final isSelected = character.id == currentId;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedAvatarId = character.id;
                              });
                              Navigator.pop(context);
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 250),
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryGreen
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                color: isSelected
                                    ? primaryGreen.withOpacity(0.08)
                                    : Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GuardianAvatar(
                                    style: character.id,
                                    size: 64,
                                    addShadow: false,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    character.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: primaryGreen,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    character.tagline,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuardianUsageChip(GuardianAvatarData character) {
    final primaryGreen = Color(0xFF2E7D32);
    final lightGreen = Color(0xFFE8F5E8);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield, color: primaryGreen, size: 16),
          SizedBox(width: 6),
          Text(
            'Guardian: ${character.name}',
            style: TextStyle(
              color: primaryGreen,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(UserModel? user) {
    final isOnline = user?.isOnline ?? false;
    final lastSeen = user?.lastSeen;
    final MaterialColor palette = isOnline ? Colors.green : Colors.grey;
    final statusColor = palette.shade600;
    String statusText;
    if (isOnline) {
      statusText = 'Online now';
    } else if (lastSeen != null) {
      statusText = 'Last seen ${_formatRelativeTime(lastSeen)}';
    } else {
      statusText = 'Offline';
    }

    return Container(
      margin: EdgeInsets.only(top: 14),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: palette.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.circle : Icons.timelapse,
            color: statusColor,
            size: 14,
          ),
          SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: palette.shade800,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}

// Decorative pattern painter for profile header
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw decorative circles
    for (var i = 0; i < 5; i++) {
      for (var j = 0; j < 3; j++) {
        final x = (i * size.width / 4) + (size.width / 8);
        final y = (j * size.height / 2) + (size.height / 4);
        canvas.drawCircle(Offset(x, y), 30, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PatternPainter oldDelegate) => false;
}
