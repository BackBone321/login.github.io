import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/announcement_model.dart';
import '../models/detection_model.dart';
import '../services/database_service.dart';
import '../widgets/detection_card.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import '../auth/login_screen.dart';
import 'admin_animal_detection_screen.dart';
import 'admin_audit_screen.dart';
import 'admin_detection_access_screen.dart';
import 'admin_friends_screen.dart';
import 'admin_messages_screen.dart';
import 'widgets/announcement_composer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final WeatherService _weatherService = WeatherService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  WeatherModel? _currentWeather;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _weatherService.startWeatherMonitoring();
    _weatherService.weatherStream.listen((weather) {
      setState(() {
        _currentWeather = weather;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _weatherService.stopWeatherMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = const Color(0xFFF5F7FB);
    final deepGreen = const Color(0xFF1B4332);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final isMedium = constraints.maxWidth >= 600;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: surface,
          drawer: isWide ? null : _buildDrawer(deepGreen),
          appBar: _buildAppBar(deepGreen, isWide, isMedium),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48 : (isMedium ? 24 : 16),
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(context, isWide, isMedium),
                  const SizedBox(height: 24),
                  _buildStatsSection(isWide, isMedium),
                  const SizedBox(height: 24),
                  _buildEnvironmentRow(isWide),
                  const SizedBox(height: 24),
                  _buildMonitoringSection(isWide, isMedium),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    Color deepGreen,
    bool isWide,
    bool isMedium,
  ) {
    return PreferredSize(
      preferredSize: Size.fromHeight(isWide ? 88 : 64),
      child: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: isWide
            ? null
            : IconButton(
                icon: Icon(Icons.menu, color: deepGreen),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        centerTitle: false,
        titleSpacing: isWide ? 24 : 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isWide ? 'Admin Control Center' : 'Admin Panel',
              style: TextStyle(
                color: deepGreen,
                fontWeight: FontWeight.w700,
                fontSize: isWide ? 20 : 18,
              ),
            ),
            if (isWide) ...[
              const SizedBox(height: 4),
              Text(
                'Web dashboard for live monitoring & collaboration',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ],
        ),
        actions: isWide
            ? _buildWideActions(deepGreen)
            : _buildCompactActions(deepGreen),
      ),
    );
  }

  List<Widget> _buildWideActions(Color deepGreen) {
    return [
      TextButton.icon(
        onPressed: () => _navigateTo(const AdminAnimalDetectionScreen()),
        icon: const Icon(Icons.pets_outlined),
        label: const Text('Animal module'),
        style: TextButton.styleFrom(foregroundColor: deepGreen),
      ),
      TextButton.icon(
        onPressed: () => _navigateTo(const AdminDetectionAccessScreen()),
        icon: const Icon(Icons.manage_accounts_outlined),
        label: const Text('Detection access'),
        style: TextButton.styleFrom(foregroundColor: deepGreen),
      ),
      TextButton.icon(
        onPressed: () => _navigateTo(const AdminFriendsScreen()),
        icon: const Icon(Icons.people_outline),
        label: const Text('Friend network'),
        style: TextButton.styleFrom(foregroundColor: deepGreen),
      ),
      TextButton.icon(
        onPressed: () => _navigateTo(const AdminMessagesScreen()),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Chat workspace'),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF2E7D32)),
      ),
      TextButton.icon(
        onPressed: () => _navigateTo(const AdminAuditScreen()),
        icon: const Icon(Icons.shield_outlined),
        label: const Text('Audit trail'),
        style: TextButton.styleFrom(foregroundColor: deepGreen),
      ),
      const SizedBox(width: 8),
      IconButton(
        tooltip: 'Logout',
        icon: const Icon(Icons.logout),
        color: deepGreen,
        onPressed: _handleLogout,
      ),
      const SizedBox(width: 8),
    ];
  }

  List<Widget> _buildCompactActions(Color deepGreen) {
    return [
      IconButton(
        tooltip: 'Chat workspace',
        icon: const Icon(Icons.chat_bubble_outline),
        color: deepGreen,
        onPressed: () => _navigateTo(const AdminMessagesScreen()),
      ),
      PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: deepGreen),
        onSelected: (value) {
          switch (value) {
            case 'animal':
              _navigateTo(const AdminAnimalDetectionScreen());
              break;
            case 'access':
              _navigateTo(const AdminDetectionAccessScreen());
              break;
            case 'friends':
              _navigateTo(const AdminFriendsScreen());
              break;
            case 'audit':
              _navigateTo(const AdminAuditScreen());
              break;
            case 'logout':
              _handleLogout();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'animal',
            child: ListTile(
              leading: Icon(Icons.pets_outlined, color: deepGreen),
              title: Text('Animal module'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'access',
            child: ListTile(
              leading: Icon(Icons.manage_accounts_outlined, color: deepGreen),
              title: Text('Detection access'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'friends',
            child: ListTile(
              leading: Icon(Icons.people_outline, color: deepGreen),
              title: Text('Friend network'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'audit',
            child: ListTile(
              leading: Icon(Icons.shield_outlined, color: deepGreen),
              title: Text('Audit trail'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'logout',
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildDrawer(Color deepGreen) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), deepGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Admin Control',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your AgriGuard system',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    color: deepGreen,
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.pets_outlined,
                    label: 'Animal Module',
                    color: deepGreen,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateTo(const AdminAnimalDetectionScreen());
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.manage_accounts_outlined,
                    label: 'Detection Access',
                    color: deepGreen,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateTo(const AdminDetectionAccessScreen());
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_outline,
                    label: 'Friend Network',
                    color: deepGreen,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateTo(const AdminFriendsScreen());
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat Workspace',
                    color: deepGreen,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateTo(const AdminMessagesScreen());
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.shield_outlined,
                    label: 'Security Audit',
                    color: deepGreen,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateTo(const AdminAuditScreen());
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.campaign_outlined,
                    label: 'Broadcast Announcement',
                    color: deepGreen,
                    onTap: () {
                      Navigator.pop(context);
                      _showAnnouncementComposer();
                    },
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    label: 'Logout',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _handleLogout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildHeroBanner(BuildContext context, bool isWide, bool isMedium) {
    final weather = _currentWeather;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 32 : (isMedium ? 24 : 20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B4332)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isWide ? 32 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Web-first incident response',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: isMedium ? 16 : 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isWide
                ? 'Monitor detections & coordinate teams in real-time.'
                : 'Monitor & coordinate in real-time.',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWide ? 26 : (isMedium ? 22 : 20),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          if (isWide || isMedium)
            Wrap(
              spacing: 20,
              runSpacing: 16,
              children: [
                _buildHeroStat(
                  icon: weather?.weatherIcon ?? Icons.wb_sunny_outlined,
                  title: 'Current weather',
                  value: weather != null
                      ? '${weather.temperatureString} · ${weather.condition}'
                      : 'Fetching latest data…',
                  isWide: isWide,
                ),
                _buildHeroStat(
                  icon: Icons.air,
                  title: 'Wind & humidity',
                  value: weather != null
                      ? '${weather.windSpeedString} · ${weather.humidityString}'
                      : 'Syncing sensors…',
                  isWide: isWide,
                ),
              ],
            )
          else
            _buildCompactWeatherInfo(weather),
          const SizedBox(height: 24),
          _buildHeroButtons(isWide, isMedium),
        ],
      ),
    );
  }

  Widget _buildCompactWeatherInfo(WeatherModel? weather) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(
            weather?.weatherIcon ?? Icons.wb_sunny_outlined,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather != null
                      ? '${weather.temperatureString} · ${weather.condition}'
                      : 'Fetching weather…',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (weather != null)
                  Text(
                    '${weather.windSpeedString} · ${weather.humidityString}',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroButtons(bool isWide, bool isMedium) {
    if (!isMedium) {
      // Compact vertical buttons for small screens
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () => _navigateTo(const AdminMessagesScreen()),
            icon: const Icon(Icons.forum_outlined),
            label: const Text('Launch chat workspace'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B4332),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _tabController.animateTo(0),
                  icon: const Icon(
                    Icons.insights_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Detections',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAnnouncementComposer,
                  icon: const Icon(
                    Icons.campaign_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Broadcast',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ElevatedButton.icon(
          onPressed: () => _navigateTo(const AdminMessagesScreen()),
          icon: const Icon(Icons.forum_outlined),
          label: const Text('Launch chat workspace'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1B4332),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _tabController.animateTo(0),
          icon: const Icon(Icons.insights_outlined, color: Colors.white),
          label: const Text(
            'View detections',
            style: TextStyle(color: Colors.white),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white54),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _navigateTo(const AdminFriendsScreen()),
          icon: const Icon(Icons.groups_2_outlined, color: Colors.white),
          label: const Text(
            'Manage friends',
            style: TextStyle(color: Colors.white),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white54),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _showAnnouncementComposer,
          icon: const Icon(Icons.campaign_outlined, color: Colors.white),
          label: const Text(
            'Broadcast announcement',
            style: TextStyle(color: Colors.white),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white54),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _dbService.updateUserPresence(isOnline: false, uid: user.uid);
    }
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildHeroStat({
    required IconData icon,
    required String title,
    required String value,
    required bool isWide,
  }) {
    return Container(
      constraints: BoxConstraints(minWidth: isWide ? 220 : 180),
      padding: EdgeInsets.all(isWide ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isWide ? 44 : 40,
            height: isWide ? 44 : 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: isWide ? 24 : 20),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isWide ? 13 : 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWide ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool isWide, bool isMedium) {
    final accent = const Color(0xFF2E7D32);

    return StreamBuilder<List<DetectionModel>>(
      stream: _dbService.getAllDetections(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final detections = snapshot.data ?? [];
        final insects = _countByTypes(detections, [
          'insect',
          'insects',
          'pest',
          'pests',
          'bug',
          'bugs',
        ]);
        final animals = _countByTypes(detections, [
          'cow',
          'cows',
          'animal',
          'animals',
          'mammal',
          'mammals',
          'livestock',
        ]);
        final plant = _countByTypes(detections, [
          'plant_health',
          'health_plant',
          'plant',
          'plants',
          'crop',
          'crops',
        ]);
        final last24h = detections
            .where((d) => DateTime.now().difference(d.detectedAt).inHours < 24)
            .length;
        final latest = detections.isNotEmpty
            ? detections.first.detectedAt
            : null;

        if (!isMedium) {
          // Grid layout for small screens
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildCompactMetricCard(
                title: 'Total',
                value: '${detections.length}',
                icon: Icons.timeline_outlined,
                color: accent,
              ),
              _buildCompactMetricCard(
                title: 'Insects',
                value: '$insects',
                icon: Icons.bug_report_outlined,
                color: const Color(0xFF4CAF50),
              ),
              _buildCompactMetricCard(
                title: 'Animals',
                value: '$animals',
                icon: Icons.pets_outlined,
                color: const Color(0xFF8E24AA),
              ),
              _buildCompactMetricCard(
                title: 'Plants',
                value: '$plant',
                icon: Icons.grass_outlined,
                color: const Color(0xFF1976D2),
              ),
            ],
          );
        }

        final cards = [
          _buildMetricCard(
            title: 'Total alerts',
            value: '${detections.length}',
            subtitle: last24h > 0
                ? '$last24h in the last 24h'
                : 'Awaiting new signals',
            icon: Icons.timeline_outlined,
            color: accent,
            isWide: isWide,
          ),
          _buildMetricCard(
            title: 'Insect activity',
            value: '$insects',
            subtitle: _formatRelativeTime(latest),
            icon: Icons.bug_report_outlined,
            color: const Color(0xFF4CAF50),
            isWide: isWide,
          ),
          _buildMetricCard(
            title: 'Animal detections',
            value: '$animals',
            subtitle: animals == 0
                ? 'All livestock calm'
                : 'Review recent movements',
            icon: Icons.pets_outlined,
            color: const Color(0xFF8E24AA),
            isWide: isWide,
          ),
          _buildMetricCard(
            title: 'Plant health alerts',
            value: '$plant',
            subtitle: plant == 0
                ? 'No stress signals'
                : 'Check agronomist feed',
            icon: Icons.grass_outlined,
            color: const Color(0xFF1976D2),
            isWide: isWide,
          ),
        ];

        return Wrap(spacing: 16, runSpacing: 16, children: cards);
      },
    );
  }

  Widget _buildCompactMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isWide,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: isWide ? 240 : 200,
        maxWidth: isWide ? 320 : 280,
      ),
      child: Container(
        padding: EdgeInsets.all(isWide ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isWide ? 48 : 44,
              height: isWide ? 48 : 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: isWide ? 24 : 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: isWide ? 24 : 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentRow(bool isWide) {
    if (isWide) {
      return Row(
        children: [
          Expanded(child: _buildWeatherCard(_currentWeather, isWide)),
          const SizedBox(width: 24),
          Expanded(child: _buildWindCard(_currentWeather, isWide)),
        ],
      );
    }

    return Column(
      children: [
        _buildWeatherCard(_currentWeather, isWide),
        const SizedBox(height: 16),
        _buildWindCard(_currentWeather, isWide),
      ],
    );
  }

  Widget _buildMonitoringSection(bool isWide, bool isMedium) {
    final accent = const Color(0xFF2E7D32);
    final deepGreen = const Color(0xFF1B4332);
    final panelHeight = isWide ? 520.0 : (isMedium ? 460.0 : 400.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 24 : (isMedium ? 20 : 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWide ? 28 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detection streams',
                      style: TextStyle(
                        color: deepGreen,
                        fontSize: isWide ? 18 : 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isMedium) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Toggle between categories to review incoming alerts.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _tabController.animateTo(
                  (_tabController.index + 1) % _tabController.length,
                ),
                icon: const Icon(Icons.swap_horiz),
                tooltip: 'Next tab',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              indicatorPadding: EdgeInsets.zero,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: accent,
              unselectedLabelColor: deepGreen.withOpacity(0.7),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isMedium ? 14 : 12,
              ),
              tabs: [
                Tab(
                  height: isMedium ? 48 : 44,
                  icon: Icon(Icons.pets_outlined, size: isMedium ? 24 : 20),
                  text: 'Animals',
                ),
                Tab(
                  height: isMedium ? 48 : 44,
                  icon: Icon(
                    Icons.bug_report_outlined,
                    size: isMedium ? 24 : 20,
                  ),
                  text: 'Insects',
                ),
                Tab(
                  height: isMedium ? 48 : 44,
                  icon: Icon(
                    Icons.local_florist_outlined,
                    size: isMedium ? 24 : 20,
                  ),
                  text: 'Plants',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: panelHeight,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryView([
                  'cow',
                  'cows',
                  'animal',
                  'animals',
                  'mammal',
                  'mammals',
                  'livestock',
                ]),
                _buildCategoryView([
                  'insect',
                  'insects',
                  'pest',
                  'pests',
                  'bug',
                  'bugs',
                ]),
                _buildCategoryView([
                  'plant_health',
                  'health_plant',
                  'plant',
                  'plants',
                  'crop',
                  'crops',
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAnnouncementComposer() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AnnouncementComposer(
        onSubmit: _submitAnnouncement,
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  Future<void> _submitAnnouncement(String title, String body) async {
    final user = _auth.currentUser;
    final announcement = AnnouncementModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user?.uid ?? 'admin',
      userName: user?.displayName ?? user?.email ?? 'Admin',
      title: title,
      content: body,
      createdAt: DateTime.now(),
    );

    try {
      await _dbService.createAnnouncement(announcement);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish announcement: $e'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }

  int _countByTypes(List<DetectionModel> detections, List<String> types) {
    final normalizedTypes = types.map((t) => t.toLowerCase()).toList();
    return detections.where((detection) {
      final detectionType = detection.type.toLowerCase();
      return normalizedTypes.any((type) => detectionType.contains(type));
    }).length;
  }

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'No events yet';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildCategoryView(List<String> types) {
    final primaryGreen = const Color(0xFF2E7D32);

    return StreamBuilder<List<DetectionModel>>(
      stream: _dbService.getAllDetections(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryGreen));
        }
        final normalizedTypes = types.map((t) => t.toLowerCase()).toList();
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No detections found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        final filtered = snapshot.data!.where((d) {
          final detectionType = d.type.toLowerCase();
          return normalizedTypes.any((type) => detectionType.contains(type));
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              'No detections for this category',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          primary: false,
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return DetectionCard(detection: filtered[index]);
          },
        );
      },
    );
  }

  Widget _buildWeatherCard(WeatherModel? weather, bool isWide) {
    final accent = const Color(0xFF2E7D32);

    return Container(
      padding: EdgeInsets.all(isWide ? 24 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.12), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: isWide ? 64 : 52,
            height: isWide ? 64 : 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              weather?.weatherIcon ?? Icons.wb_sunny_outlined,
              color: weather?.weatherColor ?? accent,
              size: isWide ? 32 : 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather overview',
                  style: TextStyle(
                    fontSize: isWide ? 15 : 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weather != null
                      ? '${weather.temperatureString} • ${weather.condition}'
                      : 'Fetching latest data…',
                  style: TextStyle(
                    color: accent,
                    fontSize: isWide ? 20 : 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weather?.windDirection ?? 'Awaiting sensor feed',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isWide ? 14 : 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindCard(WeatherModel? weather, bool isWide) {
    final deepGreen = const Color(0xFF1B4332);
    final bool showWindAlert = weather != null && weather.windSpeed >= 25;

    return Container(
      padding: EdgeInsets.all(isWide ? 24 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isWide ? 48 : 44,
                height: isWide ? 48 : 44,
                decoration: BoxDecoration(
                  color: deepGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.air,
                  color: deepGreen,
                  size: isWide ? 24 : 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Wind & humidity',
                style: TextStyle(
                  color: deepGreen,
                  fontSize: isWide ? 16 : 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            weather != null
                ? '${weather.windSpeedString} ${weather.windDirection}'
                : 'Syncing telemetry…',
            style: TextStyle(
              color: deepGreen,
              fontSize: isWide ? 22 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            weather != null
                ? 'Humidity · ${weather.humidityString}'
                : 'Humidity data pending',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isWide ? 14 : 13,
            ),
          ),
          if (showWindAlert) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: deepGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: deepGreen.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: deepGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gusty winds detected. Secure equipment.',
                      style: TextStyle(
                        color: deepGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
