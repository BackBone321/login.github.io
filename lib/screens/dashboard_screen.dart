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
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Color(0xFF2E7D32);
    final lightGreen = Color(0xFFE8F5E8);
    final backgroundColor = Color(0xFFF8FFF8);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _currentIndex == 0 ? _buildAppBar(primaryGreen) : null,
      body: _getCurrentScreen(),
      bottomNavigationBar: _buildBottomNavigationBar(primaryGreen),
    );
  }

  AppBar _buildAppBar(Color primaryGreen) {
    return AppBar(
      backgroundColor: primaryGreen,
      elevation: 0,
      title: Text(
        'Dashboard',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      actions: [
        IconButton(icon: Icon(Icons.notifications_outlined), onPressed: () {}),
      ],
    );
  }

  BottomNavigationBar _buildBottomNavigationBar(Color primaryGreen) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey[500],
      backgroundColor: Colors.white,
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'People',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.eco_outlined),
          activeIcon: Icon(Icons.eco),
          label: 'Plant',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message_outlined),
          activeIcon: Icon(Icons.message),
          label: 'Message',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
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
    final primaryGreen = Color(0xFF2E7D32);
    final user = _auth.currentUser;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Text(
            user?.displayName != null
                ? 'Hello, ${user!.displayName}!'
                : 'Hello, User!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Welcome back to your dashboard',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 32),

          // Quick Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Weather',
                  'Sunny, 25°C',
                  Icons.wb_sunny,
                  primaryGreen,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Wind',
                  '15 km/h NE',
                  Icons.air,
                  primaryGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: 32),

          // Announcements Section
          _buildAnnouncementsSection(),
          SizedBox(height: 32),

          // Recent Detections
          Text(
            'Recent Detections',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
          SizedBox(height: 16),
          _buildDetectionsList(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    final primaryGreen = Color(0xFF2E7D32);

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
                color: primaryGreen,
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
                      icon: Icon(Icons.add, color: primaryGreen),
                      label: Text('Add', style: TextStyle(color: primaryGreen)),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
          ],
        ),
        SizedBox(height: 16),
        StreamBuilder<List<AnnouncementModel>>(
          stream: _dbService.getAnnouncementsForUser(_auth.currentUser!.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: primaryGreen),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryGreen.withOpacity(0.1)),
                ),
                child: Center(
                  child: Text(
                    'No announcements yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
            }
            return Column(
              children: snapshot.data!.map((announcement) {
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        announcement.content,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'By ${announcement.userName} • ${_formatDate(announcement.createdAt)}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
          return Center(
            child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFF2E7D32).withOpacity(0.1)),
            ),
            child: Center(
              child: Text(
                'No detections yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }
        return Column(
          children: snapshot.data!.take(3).map((detection) {
            return _buildDetectionCard(detection);
          }).toList(),
        );
      },
    );
  }

  Widget _buildDetectionCard(DetectionModel detection) {
    final primaryGreen = Color(0xFF2E7D32);
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
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
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                    fontSize: 14,
                  ),
                ),
                if (detection.description != null) ...[
                  SizedBox(height: 4),
                  Text(
                    detection.description!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
                SizedBox(height: 4),
                Text(
                  _formatDate(detection.detectedAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantScreen() {
    final primaryGreen = Color(0xFF2E7D32);
    final user = _auth.currentUser;
    if (user == null) return Center(child: Text('Please login'));

    return Scaffold(
      backgroundColor: Color(0xFFF8FFF8),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: Text(
          'Detections',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detection Categories Header
            Text(
              'Detection Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            SizedBox(height: 20),

            // Detection Icon Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDetectionIconButton(
                  'Animals',
                  Icons.pets,
                  primaryGreen,
                  () => _showDetectionCategory('animals'),
                ),
                _buildDetectionIconButton(
                  'Insects',
                  Icons.bug_report,
                  primaryGreen,
                  () => _showDetectionCategory('insects'),
                ),
                _buildDetectionIconButton(
                  'Plant Health',
                  Icons.local_florist,
                  primaryGreen,
                  () => _showDetectionCategory('plant_health'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionIconButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 32,
              color: color,
            ),
          ),
          iconSize: 80,
          padding: EdgeInsets.zero,
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showDetectionCategory(String category) {
    final primaryGreen = Color(0xFF2E7D32);
    final user = _auth.currentUser;
    
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String title;
        IconData icon;
        List<String> types;

        switch (category) {
          case 'animals':
            title = 'Animal Detections';
            icon = Icons.pets;
            types = ['cow', 'mammal', 'mammals'];
            break;
          case 'insects':
            title = 'Insect Detections';
            icon = Icons.bug_report;
            types = ['insect', 'pest'];
            break;
          case 'plant_health':
            title = 'Plant Health Detections';
            icon = Icons.local_florist;
            types = ['plant_health', 'health_plant'];
            break;
          default:
            title = 'Detections';
            icon = Icons.notifications;
            types = [];
        }

        return Container(
          padding: EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Icon(icon, color: primaryGreen, size: 28),
                  SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Divider(),

              // Detections List
              Expanded(
                child: StreamBuilder<List<DetectionModel>>(
                  stream: _dbService.getDetectionsForUser(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: primaryGreen),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              size: 48,
                              color: primaryGreen.withOpacity(0.3),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No detections found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final filteredDetections = snapshot.data!
                        .where((detection) => types.contains(detection.type))
                        .toList();

                    if (filteredDetections.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              size: 48,
                              color: primaryGreen.withOpacity(0.3),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No $category detections',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredDetections.length,
                      itemBuilder: (context, index) {
                        return _buildDetectionCard(filteredDetections[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateAnnouncementDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final primaryGreen = Color(0xFF2E7D32);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Create Announcement',
          style: TextStyle(color: primaryGreen),
        ),
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
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
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
