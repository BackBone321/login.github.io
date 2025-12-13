import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../models/detection_model.dart';
import '../models/announcement_model.dart';
import 'friends_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import '../widgets/detection_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final WeatherService _weatherService = WeatherService();
  WeatherModel? _currentWeather;
  StreamSubscription<WeatherModel>? _weatherSubscription;
  String? _userId;
  final List<DetectionModel> _cachedDetections = [];
  StreamSubscription<List<DetectionModel>>? _detectionSubscription;
  bool _detectionsLoading = true;
  final Widget _friendsScreen = const FriendsScreen();
  final Widget _messagesScreen = const EnhancedMessagesScreen(key: ValueKey('messages_screen'));
  final Widget _profileScreen = const ProfileScreen();

  // Notification badge counts
  int _unreadDirectMessages = 0;
  int _unreadGroupMessages = 0;
  StreamSubscription<int>? _unreadDirectSubscription;
  StreamSubscription<int>? _unreadGroupSubscription;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid;
    _listenToDetections();
    _listenToUnreadMessages();
    WidgetsBinding.instance.addObserver(this);
    _weatherService.startWeatherMonitoring();
    _weatherSubscription = _weatherService.weatherStream.listen((weather) {
      if (!mounted) return;
      setState(() {
        _currentWeather = weather;
      });
    });
    _updatePresence(true);
  }

  void _listenToUnreadMessages() {
    if (_userId == null) return;

    // Listen to unread direct messages
    _unreadDirectSubscription?.cancel();
    _unreadDirectSubscription = _dbService.getUnreadMessageCount(_userId!).listen((count) {
      if (!mounted) return;
      setState(() {
        _unreadDirectMessages = count;
      });
    });

    // Listen to unread group messages
    _unreadGroupSubscription?.cancel();
    _unreadGroupSubscription = _dbService.getUnreadGroupMessageCount(_userId!).listen((count) {
      if (!mounted) return;
      setState(() {
        _unreadGroupMessages = count;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _weatherSubscription?.cancel();
    _weatherService.stopWeatherMonitoring();
    _detectionSubscription?.cancel();
    _unreadDirectSubscription?.cancel();
    _unreadGroupSubscription?.cancel();
    _updatePresence(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updatePresence(true);
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _updatePresence(false);
    }
  }

  Future<void> _updatePresence(bool isOnline) async {
    if (_userId == null) return;
    await _dbService.updateUserPresence(isOnline: isOnline, uid: _userId);
  }

  void _listenToDetections() {
    _detectionSubscription?.cancel();
    if (_userId == null) {
      setState(() {
        _cachedDetections.clear();
        _detectionsLoading = false;
      });
      return;
    }

    _detectionsLoading = true;
    _detectionSubscription = _dbService
        .getDetectionsForUser(_userId!)
        .listen(
          (detections) {
            if (!mounted) return;
            setState(() {
              _cachedDetections
                ..clear()
                ..addAll(detections);
              _detectionsLoading = false;
            });
          },
          onError: (_) {
            if (!mounted) return;
            setState(() {
              _cachedDetections.clear();
              _detectionsLoading = false;
            });
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Color(0xFF2E7D32);
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
            child: Icon(Icons.agriculture, size: 20),
          ),
          SizedBox(width: 12),
          Text(
            'Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar(Color primaryGreen) {
    final totalUnreadMessages = _unreadDirectMessages + _unreadGroupMessages;

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
          icon: Icon(Icons.camera_alt_outlined),
          activeIcon: Icon(Icons.camera),
          label: 'Detections',
        ),
        BottomNavigationBarItem(
          icon: _buildIconWithBadge(
            Icons.message_outlined,
            totalUnreadMessages,
            isActive: false,
          ),
          activeIcon: _buildIconWithBadge(
            Icons.message,
            totalUnreadMessages,
            isActive: true,
          ),
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

  /// Builds an icon with a sky blue notification badge
  Widget _buildIconWithBadge(IconData icon, int count, {bool isActive = false}) {
    const skyBlue = Color(0xFF87CEEB);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            top: -4,
            right: -8,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: skyBlue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: skyBlue.withOpacity(0.4),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _getCurrentScreen() {
    // Use IndexedStack to keep all screens alive and preserve their state
    return IndexedStack(
      index: _currentIndex,
      children: [
        _buildHomeScreen(),
        _friendsScreen,
        _buildPlantScreen(),
        _messagesScreen,
        _profileScreen,
      ],
    );
  }

  Widget _buildHomeScreen() {
    final primaryGreen = Color(0xFF2E7D32);
    final user = _auth.currentUser;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header with Gradient Card
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryGreen.withOpacity(0.1), Color(0xFFE8F5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryGreen.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.08),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.wb_sunny_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      SizedBox(height: 4),
                      Text(
                        'Welcome back to your dashboard',
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryGreen.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Quick Stats Cards
          Row(
            children: [
              Expanded(child: _buildWeatherCard(_currentWeather)),
              SizedBox(width: 12),
              Expanded(child: _buildWindCard(_currentWeather)),
            ],
          ),
          SizedBox(height: 28),

          // Announcements Section
          _buildAnnouncementsSection(),
          SizedBox(height: 28),

          // Recent Detections Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notifications_active,
                  color: primaryGreen,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Recent Detections',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildDetectionsList(),
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
                final isOwner = announcement.userId == _auth.currentUser!.uid;
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              announcement.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isOwner)
                            GestureDetector(
                              onTap: () => _confirmDeleteAnnouncement(announcement),
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: Colors.red[400],
                                  size: 18,
                                ),
                              ),
                            ),
                        ],
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
    if (_detectionsLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }
    if (_cachedDetections.isEmpty) {
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
      children: _cachedDetections.take(3).map((detection) {
        return _buildDetectionCard(detection);
      }).toList(),
    );
  }

  Widget _buildDetectionCard(DetectionModel detection) {
    return DetectionCard(detection: detection);
  }

  Widget _buildPlantScreen() {
    final primaryGreen = Color(0xFF2E7D32);
    final user = _auth.currentUser;
    if (user == null) return Center(child: Text('Please login'));

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
              child: Icon(Icons.camera_alt, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              'Detections',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detection Categories Header with icon
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGreen.withOpacity(0.08), Color(0xFFE8F5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: primaryGreen.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.category, color: primaryGreen, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detection Categories',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'View your farm detections',
                          style: TextStyle(
                            fontSize: 13,
                            color: primaryGreen.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28),

            // Detection Icon Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDetectionIconButton(
                  'Animals',
                  Icons.pets,
                  Color(0xFF2E7D32),
                  () => _showDetectionCategory('animals'),
                ),
                _buildDetectionIconButton(
                  'Insects',
                  Icons.bug_report,
                  Color(0xFFD84315),
                  () => _showDetectionCategory('insects'),
                ),
                _buildDetectionIconButton(
                  'Plant Health',
                  Icons.local_florist,
                  Color(0xFF7CB342),
                  () => _showDetectionCategory('plant_health'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionIconButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 15,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 36, color: color),
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetectionCategory(String category) {
    final primaryGreen = Color(0xFF2E7D32);
    if (_userId == null) return;

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
            types = [
              'cow',
              'cows',
              'animal',
              'animals',
              'mammal',
              'mammals',
              'livestock',
            ];
            break;
          case 'insects':
            title = 'Insect Detections';
            icon = Icons.bug_report;
            types = ['insect', 'insects', 'pest', 'pests'];
            break;
          case 'plant_health':
            title = 'Plant Health Detections';
            icon = Icons.local_florist;
            types = ['plant_health', 'health_plant', 'plant', 'plants'];
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
                child: _detectionsLoading
                    ? Center(
                        child: CircularProgressIndicator(color: primaryGreen),
                      )
                    : _buildFilteredDetectionsList(
                        icon: icon,
                        category: category,
                        types: types,
                        primaryGreen: primaryGreen,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilteredDetectionsList({
    required IconData icon,
    required String category,
    required List<String> types,
    required Color primaryGreen,
  }) {
    if (_cachedDetections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: primaryGreen.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No detections found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    final normalizedTypes = types.map((type) => type.toLowerCase()).toList();
    final filteredDetections = _cachedDetections.where((detection) {
      final detectionType = detection.type.toLowerCase();
      return normalizedTypes.any((type) => detectionType.contains(type));
    }).toList();

    if (filteredDetections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: primaryGreen.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No $category detections',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredDetections.length,
      itemBuilder: (context, index) =>
          _buildDetectionCard(filteredDetections[index]),
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

  Future<void> _confirmDeleteAnnouncement(AnnouncementModel announcement) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Announcement'),
        content: Text(
          'Are you sure you want to delete "${announcement.title}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbService.deleteAnnouncement(announcement.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Announcement deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete announcement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildWeatherCard(WeatherModel? weather) {
    final primaryGreen = Color(0xFF2E7D32);

    return InkWell(
      onTap: () => _showWeatherDetails(weather),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFFAFDFA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: primaryGreen.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.1),
              blurRadius: 15,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (weather?.weatherColor ?? primaryGreen).withOpacity(
                  0.12,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                weather?.weatherIcon ?? Icons.wb_sunny,
                color: weather?.weatherColor ?? primaryGreen,
                size: 32,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Weather',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 6),
            Text(
              weather != null ? weather.condition : 'Loading...',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              weather?.temperatureString ?? '--°C',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (weather?.hasTyphoon ?? false) ...[
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 12),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        weather!.typhoonWarning,
                        style: TextStyle(
                          color: Colors.red[800],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWindCard(WeatherModel? weather) {
    final primaryGreen = Color(0xFF2E7D32);

    return InkWell(
      onTap: () => _showWeatherDetails(weather),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFC8E6C9), Color(0xFFE8F5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: primaryGreen.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.12),
              blurRadius: 15,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.air, color: primaryGreen, size: 32),
            ),
            SizedBox(height: 16),
            Text(
              'Wind & Humidity',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 6),
            Text(
              weather != null ? weather.windDirection : 'Loading...',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              weather != null ? weather.windSpeedString : '--',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.water_drop, size: 14, color: Colors.blue[700]),
                SizedBox(width: 4),
                Text(
                  weather?.humidityString ?? '--',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showWeatherDetails(WeatherModel? weather) {
    if (weather == null) return;

    final primaryGreen = Color(0xFF2E7D32);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with time and date
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  weather.weatherIcon,
                  color: weather.weatherColor,
                  size: 32,
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.datetimeString,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                    Text(
                      weather.isDaytime ? 'Daytime' : 'Nighttime',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),

            // Weather details grid
            Row(
              children: [
                Expanded(
                  child: _buildWeatherDetailCard(
                    'Temperature',
                    weather.temperatureString,
                    Icons.thermostat,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildWeatherDetailCard(
                    'Humidity',
                    weather.humidityString,
                    Icons.water_drop,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildWeatherDetailCard(
                    'Wind Speed',
                    weather.windSpeedString,
                    Icons.air,
                    Colors.teal,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildWeatherDetailCard(
                    'Direction',
                    weather.windDirection,
                    Icons.explore,
                    Colors.purple,
                  ),
                ),
              ],
            ),

            if (weather.hasTyphoon) ...[
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Typhoon Alert!',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${weather.typhoonName} - ${weather.typhoonWarning}',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 24),
            Text(
              'Weather updates every 30 seconds',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetailCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
