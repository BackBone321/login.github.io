import 'package:flutter/material.dart';
import '../models/detection_model.dart';

class DetectionCard extends StatelessWidget {
  final DetectionModel detection;

  const DetectionCard({super.key, required this.detection});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    final typeInfo = _iconAndTitleForType(detection.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeInfo.icon, color: primaryGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    typeInfo.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (detection.imageUrl != null &&
                detection.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(detection.imageUrl!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (detection.description != null &&
                detection.description!.isNotEmpty) ...[
              Text(
                detection.description!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              _formatDate(detection.detectedAt),
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  static _DetectionTypeInfo _iconAndTitleForType(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('cow') ||
        normalized.contains('animal') ||
        normalized.contains('livestock') ||
        normalized.contains('mammal')) {
      return const _DetectionTypeInfo(Icons.pets, 'Mammals Detection');
    }
    if (normalized.contains('insect') ||
        normalized.contains('pest') ||
        normalized.contains('bug')) {
      return const _DetectionTypeInfo(Icons.bug_report, 'Pest Detection');
    }
    if (normalized.contains('plant') ||
        normalized.contains('crop') ||
        normalized.contains('health')) {
      return const _DetectionTypeInfo(
        Icons.local_florist,
        'Plant Health Detection',
      );
    }
    if (normalized.contains('weather')) {
      return const _DetectionTypeInfo(Icons.wb_sunny, 'Weather Detection');
    }
    if (normalized.contains('wind')) {
      return const _DetectionTypeInfo(Icons.air, 'Wind Detection');
    }
    return const _DetectionTypeInfo(Icons.notifications, 'Detection');
  }

  static String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} '
        '${date.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _DetectionTypeInfo {
  final IconData icon;
  final String title;

  const _DetectionTypeInfo(this.icon, this.title);
}
