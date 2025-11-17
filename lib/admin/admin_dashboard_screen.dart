import 'package:flutter/material.dart';
import '../models/detection_model.dart';
import '../services/database_service.dart';
import '../widgets/detection_card.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import 'admin_messages_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
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
    final primaryGreen = const Color(0xFF2E7D32);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            tooltip: 'Messages',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminMessagesScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Insects'),
            Tab(text: 'Animals'),
            Tab(text: 'Plant Health'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _buildWeatherCard(_currentWeather)),
                const SizedBox(width: 16),
                Expanded(child: _buildWindCard(_currentWeather)),
              ],
            ),
          ),
          Expanded(
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

  Widget _buildCategoryView(List<String> types) {
    final primaryGreen = const Color(0xFF2E7D32);

    return StreamBuilder<List<DetectionModel>>(
      stream: _dbService.getAllDetections(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: primaryGreen),
          );
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
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return DetectionCard(detection: filtered[index]);
          },
        );
      },
    );
  }

  Widget _buildWeatherCard(WeatherModel? weather) {
    final primaryGreen = const Color(0xFF2E7D32);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            weather?.weatherIcon ?? Icons.wb_sunny,
            color: weather?.weatherColor ?? primaryGreen,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weather != null
                      ? '${weather.condition}, ${weather.temperatureString}'
                      : 'Loading...',
                  style: TextStyle(
                    color: primaryGreen.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindCard(WeatherModel? weather) {
    final primaryGreen = const Color(0xFF2E7D32);
    final lightGreen = const Color(0xFFC8E6C9);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGreen, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.air, color: primaryGreen, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wind & Humidity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weather != null
                      ? 'Speed: ${weather.windSpeedString}, ${weather.windDirection}'
                      : 'Loading...',
                  style: TextStyle(
                    color: primaryGreen.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                if (weather != null)
                  Text(
                    'Humidity: ${weather.humidityString}',
                    style: TextStyle(
                      color: primaryGreen.withOpacity(0.6),
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
}
