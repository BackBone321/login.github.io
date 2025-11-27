import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/detection_model.dart';
import '../services/database_service.dart';
import '../widgets/detection_card.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import '../auth/login_screen.dart';
import 'admin_messages_screen.dart';
import 'admin_animal_detection_screen.dart';

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

    return Scaffold(
      backgroundColor: surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(88),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: false,
          titleSpacing: 24,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Control Center',
                style: TextStyle(
                  color: deepGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Web dashboard for live monitoring & collaboration',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminAnimalDetectionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.pets_outlined),
              label: const Text('Animal module'),
              style: TextButton.styleFrom(foregroundColor: deepGreen),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminMessagesScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Open chat workspace'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
              color: deepGreen,
              onPressed: _handleLogout,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1100;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48 : 20,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(context, isWide),
                  const SizedBox(height: 24),
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  _buildEnvironmentRow(isWide),
                  const SizedBox(height: 24),
                  _buildMonitoringSection(isWide),
                ],
              ),
            );
          },
        ),
      ),
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

  Widget _buildHeroBanner(BuildContext context, bool isWide) {
    final weather = _currentWeather;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 32 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B4332)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
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
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Monitor detections & coordinate teams in real-time.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
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
              ),
              _buildHeroStat(
                icon: Icons.air,
                title: 'Wind & humidity',
                value: weather != null
                    ? '${weather.windSpeedString} · ${weather.humidityString}'
                    : 'Syncing sensors…',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminMessagesScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.forum_outlined),
                label: const Text('Launch chat workspace'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1B4332),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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

  Widget _buildStatsSection() {
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
        final insects = _countByTypes(detections, ['insect', 'pest']);
        final animals = _countByTypes(detections, ['cow', 'mammal', 'mammals']);
        final plant = _countByTypes(detections, [
          'plant_health',
          'health_plant',
        ]);
        final last24h = detections
            .where((d) => DateTime.now().difference(d.detectedAt).inHours < 24)
            .length;
        final latest = detections.isNotEmpty
            ? detections.first.detectedAt
            : null;

        final cards = [
          _buildMetricCard(
            title: 'Total alerts',
            value: '${detections.length}',
            subtitle: last24h > 0
                ? '$last24h in the last 24h'
                : 'Awaiting new signals',
            icon: Icons.timeline_outlined,
            color: accent,
          ),
          _buildMetricCard(
            title: 'Insect activity',
            value: '$insects',
            subtitle: _formatRelativeTime(latest),
            icon: Icons.bug_report_outlined,
            color: const Color(0xFF4CAF50),
          ),
          _buildMetricCard(
            title: 'Animal detections',
            value: '$animals',
            subtitle: animals == 0
                ? 'All livestock calm'
                : 'Review recent movements',
            icon: Icons.pets_outlined,
            color: const Color(0xFF8E24AA),
          ),
          _buildMetricCard(
            title: 'Plant health alerts',
            value: '$plant',
            subtitle: plant == 0
                ? 'No stress signals'
                : 'Check agronomist feed',
            icon: Icons.grass_outlined,
            color: const Color(0xFF1976D2),
          ),
        ];

        return Wrap(spacing: 16, runSpacing: 16, children: cards);
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.all(20),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
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
                      fontSize: 24,
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
          Expanded(child: _buildWeatherCard(_currentWeather)),
          const SizedBox(width: 24),
          Expanded(child: _buildWindCard(_currentWeather)),
        ],
      );
    }

    return Column(
      children: [
        _buildWeatherCard(_currentWeather),
        const SizedBox(height: 16),
        _buildWindCard(_currentWeather),
      ],
    );
  }

  Widget _buildMonitoringSection(bool isWide) {
    final accent = const Color(0xFF2E7D32);
    final deepGreen = const Color(0xFF1B4332);
    final panelHeight = isWide ? 520.0 : 460.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toggle between categories to review incoming alerts.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
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
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: deepGreen,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(icon: Icon(Icons.bug_report_outlined), text: 'Insects'),
                Tab(icon: Icon(Icons.pets_outlined), text: 'Animals'),
                Tab(
                  icon: Icon(Icons.local_florist_outlined),
                  text: 'Plant health',
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
                _buildCategoryView(['insect', 'pest']),
                _buildCategoryView(['cow', 'mammal', 'mammals']),
                _buildCategoryView(['plant_health', 'health_plant']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _countByTypes(List<DetectionModel> detections, List<String> types) {
    return detections
        .where((detection) => types.contains(detection.type))
        .length;
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No detections found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        final filtered = snapshot.data!
            .where((d) => types.contains(d.type))
            .toList();

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

  Widget _buildWeatherCard(WeatherModel? weather) {
    final accent = const Color(0xFF2E7D32);

    return Container(
      padding: const EdgeInsets.all(24),
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
            width: 64,
            height: 64,
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
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather overview',
                  style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  weather != null
                      ? '${weather.temperatureString} • ${weather.condition}'
                      : 'Fetching latest data…',
                  style: TextStyle(
                    color: accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weather?.windDirection ?? 'Awaiting sensor feed',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindCard(WeatherModel? weather) {
    final deepGreen = const Color(0xFF1B4332);

    return Container(
      padding: const EdgeInsets.all(24),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: deepGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.air, color: deepGreen),
              ),
              const SizedBox(width: 12),
              Text(
                'Wind & humidity',
                style: TextStyle(
                  color: deepGreen,
                  fontSize: 16,
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
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            weather != null
                ? 'Humidity · ${weather.humidityString}'
                : 'Humidity data pending',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
