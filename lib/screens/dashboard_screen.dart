import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../models/detection_model.dart';
import '../models/announcement_model.dart';
import 'friends_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final darkGreen = Color(0xFF2E7D32);
    final lightBeige = Color(0xFFF5F5DC);

    return Scaffold(
      backgroundColor: lightBeige,
      body: _getCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: darkGreen,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'People',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco),
            label: 'Plant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Message',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return FriendsScreen();
      case 2:
        return _buildPlantScreen();
      case 3:
        return MessagesScreen();
      case 4:
        return ProfileScreen();
      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    final darkGreen = Color(0xFF2E7D32);
    final user = _auth.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  user?.displayName != null
                      ? 'Hello, ${user!.displayName}'
                      : 'Hello, User',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.notifications, color: darkGreen),
                  onPressed: () {},
                ),
              ],
            ),
            SizedBox(height: 24),
            // Weather Detection Card
            _buildWeatherCard(),
            SizedBox(height: 16),
            // Wind Detection Card
            _buildWindCard(),
            SizedBox(height: 16),
            // Announcements Section
            _buildAnnouncementsSection(),
            SizedBox(height: 24),
            // Detections Section
            Text(
              'Recent Detections',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),
            SizedBox(height: 16),
            _buildDetectionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final darkGreen = Color(0xFF2E7D32);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.wb_sunny, color: Colors.white, size: 40),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sunny, 25°C',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindCard() {
    final darkGreen = Color(0xFF2E7D32);
    final lightGreen = Color(0xFFC8E6C9);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: darkGreen, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.air, color: darkGreen, size: 40),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wind Detection',
                  style: TextStyle(
                    color: darkGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Speed: 15 km/h, Direction: NE',
                  style: TextStyle(color: darkGreen.withOpacity(0.7), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    final darkGreen = Color(0xFF2E7D32);
    final lightBeige = Color(0xFFE8DCC6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Announcements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),
            if (_auth.currentUser != null)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(_auth.currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final isAdmin = snapshot.data?.data() != null
                      ? (snapshot.data!.data() as Map)['isAdmin'] ?? false
                      : false;
                  if (isAdmin) {
                    return TextButton.icon(
                      onPressed: () => _showCreateAnnouncementDialog(),
                      icon: Icon(Icons.add, color: darkGreen),
                      label: Text('Add', style: TextStyle(color: darkGreen)),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
          ],
        ),
        SizedBox(height: 12),
        StreamBuilder<List<AnnouncementModel>>(
          stream: _dbService.getAnnouncementsForUser(_auth.currentUser!.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightBeige,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No announcements yet',
                  style: TextStyle(color: darkGreen),
                ),
              );
            }
            return Column(
              children: snapshot.data!.map((announcement) {
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightBeige,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        announcement.content,
                        style: TextStyle(color: darkGreen),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'By ${announcement.userName} • ${_formatDate(announcement.createdAt)}',
                        style: TextStyle(
                          color: darkGreen.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetectionsList() {
    final user = _auth.currentUser;
    if (user == null) return SizedBox.shrink();

    return StreamBuilder<List<DetectionModel>>(
      stream: _dbService.getDetectionsForUser(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No detections yet',
              style: TextStyle(color: Color(0xFF2E7D32)),
            ),
          );
        }
        return Column(
          children: snapshot.data!.map((detection) {
            return _buildDetectionCard(detection);
          }).toList(),
        );
      },
    );
  }

  Widget _buildDetectionCard(DetectionModel detection) {
    final darkGreen = Color(0xFF2E7D32);
    IconData icon;
    String title;

    switch (detection.type) {
      case 'cow':
      case 'mammal':
      case 'mammals':
        icon = Icons.pets;
        title = 'Mammals Detection';
        break;
      case 'insect':
      case 'pest':
        icon = Icons.bug_report;
        title = 'Pest Detection';
        break;
      case 'plant_health':
      case 'health_plant':
        icon = Icons.local_florist;
        title = 'Plant Health Detection';
        break;
      case 'weather':
        icon = Icons.wb_sunny;
        title = 'Weather Detection';
        break;
      case 'wind':
        icon = Icons.air;
        title = 'Wind Detection';
        break;
      default:
        icon = Icons.notifications;
        title = 'Detection';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: darkGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: darkGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: darkGreen, size: 32),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                    fontSize: 16,
                  ),
                ),
                if (detection.description != null) ...[
                  SizedBox(height: 4),
                  Text(
                    detection.description!,
                    style: TextStyle(
                      color: darkGreen.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
                SizedBox(height: 4),
                Text(
                  _formatDate(detection.detectedAt),
                  style: TextStyle(
                    color: darkGreen.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantScreen() {
    final darkGreen = Color(0xFF2E7D32);
    final lightBeige = Color(0xFFF5F5DC);
    final user = _auth.currentUser;
    if (user == null) return Center(child: Text('Please login'));

    return Scaffold(
      backgroundColor: lightBeige,
      appBar: AppBar(
        title: Text('Detections'),
        backgroundColor: darkGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: StreamBuilder<List<DetectionModel>>(
          stream: _dbService.getDetectionsForUser(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.eco, size: 64, color: darkGreen.withOpacity(0.5)),
                    SizedBox(height: 16),
                    Text(
                      'No detections yet',
                      style: TextStyle(color: darkGreen, fontSize: 18),
                    ),
                  ],
                ),
              );
            }

            final detections = snapshot.data!;
            
            // Filter detections by type
            final plantHealthDetections = detections.where((d) => d.type == 'plant_health' || d.type == 'health_plant').toList();
            final mammalDetections = detections.where((d) => d.type == 'cow' || d.type == 'mammal' || d.type == 'mammals').toList();
            final pestDetections = detections.where((d) => d.type == 'insect' || d.type == 'pest').toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pest Detection Section
                _buildSectionHeader('Pest Detection', Icons.bug_report, darkGreen),
                SizedBox(height: 12),
                if (pestDetections.isEmpty)
                  _buildEmptySection('No pest detections')
                else
                  ...pestDetections.map((detection) => _buildDetectionCard(detection)).toList(),
                SizedBox(height: 24),
                
                // Plant Health Detection Section
                _buildSectionHeader('Plant Health Detection', Icons.local_florist, darkGreen),
                SizedBox(height: 12),
                if (plantHealthDetections.isEmpty)
                  _buildEmptySection('No plant health detections')
                else
                  ...plantHealthDetections.map((detection) => _buildDetectionCard(detection)).toList(),
                SizedBox(height: 24),
                
                // Mammals Detection Section
                _buildSectionHeader('Mammals Detection', Icons.pets, darkGreen),
                SizedBox(height: 12),
                if (mammalDetections.isEmpty)
                  _buildEmptySection('No mammal detections')
                else
                  ...mammalDetections.map((detection) => _buildDetectionCard(detection)).toList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    final darkGreen = Color(0xFF2E7D32);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: darkGreen.withOpacity(0.2)),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: darkGreen.withOpacity(0.6),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  void _showCreateAnnouncementDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final darkGreen = Color(0xFF2E7D32);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Announcement', style: TextStyle(color: darkGreen)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty) {
                final user = _auth.currentUser;
                final announcement = AnnouncementModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  userId: user!.uid,
                  userName: user.displayName ?? user.email ?? 'User',
                  title: titleController.text,
                  content: contentController.text,
                  createdAt: DateTime.now(),
                );
                await _dbService.createAnnouncement(announcement);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: darkGreen),
            child: Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
  }
}

