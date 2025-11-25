import 'package:flutter/material.dart';
import '../models/user_model.dart';

class GuardianAvatarData {
  final String id;
  final String name;
  final String tagline;
  final Color startColor;
  final Color endColor;
  final IconData icon;

  const GuardianAvatarData({
    required this.id,
    required this.name,
    required this.tagline,
    required this.startColor,
    required this.endColor,
    required this.icon,
  });
}

const List<GuardianAvatarData> guardianAvatarOptions = [
  GuardianAvatarData(
    id: defaultAvatarStyle,
    name: 'Sprout Guardian',
    tagline: 'Nurtures young plants with gentle care.',
    startColor: Color(0xFF43A047),
    endColor: Color(0xFF66BB6A),
    icon: Icons.eco,
  ),
  GuardianAvatarData(
    id: 'field_ranger',
    name: 'Field Ranger',
    tagline: 'Patrols the crops against pests and threats.',
    startColor: Color(0xFFF57C00),
    endColor: Color(0xFFFFA726),
    icon: Icons.agriculture,
  ),
  GuardianAvatarData(
    id: 'sky_sentinel',
    name: 'Sky Sentinel',
    tagline: 'Reads the clouds and guards the weather.',
    startColor: Color(0xFF1E88E5),
    endColor: Color(0xFF64B5F6),
    icon: Icons.cloud_queue,
  ),
  GuardianAvatarData(
    id: 'river_keeper',
    name: 'River Keeper',
    tagline: 'Balances water and nourishes the fields.',
    startColor: Color(0xFF00897B),
    endColor: Color(0xFF4DB6AC),
    icon: Icons.water_drop,
  ),
  GuardianAvatarData(
    id: 'tech_tiller',
    name: 'Tech Tiller',
    tagline: 'Blends innovation with tradition.',
    startColor: Color(0xFF8E24AA),
    endColor: Color(0xFFBA68C8),
    icon: Icons.smart_toy,
  ),
];

GuardianAvatarData guardianAvatarFor(String? id) {
  return guardianAvatarOptions.firstWhere(
    (option) => option.id == (id ?? defaultAvatarStyle),
    orElse: () => guardianAvatarOptions.firstWhere(
      (option) => option.id == defaultAvatarStyle,
      orElse: () => guardianAvatarOptions.first,
    ),
  );
}

class GuardianAvatar extends StatelessWidget {
  final String? style;
  final double size;
  final bool addShadow;

  const GuardianAvatar({
    super.key,
    this.style,
    this.size = 60,
    this.addShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final data = guardianAvatarFor(style);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [data.startColor, data.endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: addShadow
            ? [
                BoxShadow(
                  color: data.endColor.withOpacity(0.3),
                  blurRadius: size * 0.3,
                  offset: Offset(0, size * 0.1),
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(data.icon, color: Colors.white, size: size * 0.55),
          Positioned(
            top: size * 0.35,
            child: Row(
              children: List.generate(
                2,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: size * 0.07,
                  height: size * 0.07,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
