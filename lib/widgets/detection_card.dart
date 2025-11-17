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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
            if (detection.imageUrl != null && detection.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    detection.imageUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (detection.description != null && detection.description!.isNotEmpty) ...[
              Text(
                detection.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              _formatDate(detection.detectedAt),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _DetectionTypeInfo _iconAndTitleForType(String type) {
    IconData icon;
    String title;

    switch (type) {
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

    return _DetectionTypeInfo(icon, title);
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
