import 'package:flutter/material.dart';

import '../models/detection_model.dart';
import '../services/database_service.dart';
import '../widgets/detection_card.dart';
import 'admin_detection_access_screen.dart';

class AdminAnimalDetectionScreen extends StatefulWidget {
  const AdminAnimalDetectionScreen({super.key});

  @override
  State<AdminAnimalDetectionScreen> createState() =>
      _AdminAnimalDetectionScreenState();
}

class _AdminAnimalDetectionScreenState
    extends State<AdminAnimalDetectionScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final surface = const Color(0xFFF5F7FB);
    final deepGreen = const Color(0xFF1B4332);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        title: const Text('Animal Detection Module'),
        backgroundColor: Colors.white,
        foregroundColor: deepGreen,
        elevation: 1,
        actions: const [],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(deepGreen),
              const SizedBox(height: 20),
              _buildInsightRow(),
              const SizedBox(height: 24),
              _buildLiveFeed(),
              const SizedBox(height: 24),
              _buildAccessShortcut(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(Color deepGreen) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B4332)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Animal signals',
            style: TextStyle(color: Colors.white70, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track and simulate livestock detections.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 8),
          Text(
            'Use detection access control to grant or revoke live feed visibility.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow() {
    final tiles = [
      _InsightTile(
        icon: Icons.pets_outlined,
        title: 'Tracked animals',
        value: 'Cow herd',
        subtitle: 'Priority livestock',
        color: const Color(0xFF2E7D32),
      ),
      _InsightTile(
        icon: Icons.sensors,
        title: 'Detection type',
        value: 'Vision + IoT',
        subtitle: 'Edge device feed',
        color: const Color(0xFF00897B),
      ),
      _InsightTile(
        icon: Icons.lock_outline,
        title: 'Access',
        value: 'Invite only',
        subtitle: 'Admin approved',
        color: const Color(0xFF6A1B9A),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return Row(
            children: [
              for (final tile in tiles)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: tile == tiles.last ? 0 : 16,
                    ),
                    child: tile,
                  ),
                ),
            ],
          );
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: tiles
              .map(
                (tile) => SizedBox(
                  width: constraints.maxWidth >= 420
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth,
                  child: tile,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildLiveFeed() {
    final accent = const Color(0xFF2E7D32);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.live_tv, color: Color(0xFF1B4332)),
              const SizedBox(width: 8),
              Text(
                'Live animal detections',
                style: TextStyle(
                  color: const Color(0xFF1B4332),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<DetectionModel>>(
            stream: _dbService.getAllDetections(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final detections = (snapshot.data ?? [])
                  .where(
                    (detection) => _matchesDetectionTags(detection.type, const [
                      'cow',
                      'cows',
                      'animal',
                      'animals',
                      'mammal',
                      'mammals',
                      'livestock',
                    ]),
                  )
                  .toList();

              if (detections.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.sensors_off,
                        color: Colors.grey,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No animal detections yet',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Awaiting the first reading from field sensors.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              final feedLength = detections.length > 5 ? 5 : detections.length;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: feedLength,
                itemBuilder: (context, index) {
                  final detection = detections[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == feedLength - 1 ? 0 : 12,
                    ),
                    child: DetectionCard(detection: detection),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccessShortcut(BuildContext context) {
    final accent = const Color(0xFF1B4332);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.manage_accounts_outlined,
                  color: Color(0xFF1B4332)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Detection access control',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Grant or revoke user access to shared detections from a dedicated workspace.',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminDetectionAccessScreen(),
                ),
              );
            },
            icon: const Icon(Icons.tune_outlined),
            label: const Text('Open access controls'),
          ),
        ],
      ),
    );
  }

  bool _matchesDetectionTags(String detectionType, List<String> tags) {
    final normalized = detectionType.toLowerCase();
    for (final tag in tags) {
      if (normalized.contains(tag)) return true;
    }
    return false;
  }
}

class _InsightTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _InsightTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
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
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
