import 'package:flutter/material.dart';

class WeatherModel {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double windSpeed;
  final String windDirection;
  final String condition;
  final bool isDaytime;
  final bool hasTyphoon;
  final String? typhoonName;
  final int typhoonStrength; // 1-5 scale

  WeatherModel({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.condition,
    required this.isDaytime,
    this.hasTyphoon = false,
    this.typhoonName,
    this.typhoonStrength = 0,
  });

  // Get appropriate weather icon based on condition and time
  IconData get weatherIcon {
    if (hasTyphoon) {
      return Icons.storm;
    }

    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return isDaytime ? Icons.wb_sunny : Icons.nightlight_round;
      case 'cloudy':
      case 'partly cloudy':
        return isDaytime ? Icons.wb_cloudy : Icons.nights_stay;
      case 'rainy':
      case 'rain':
        return Icons.grain;
      case 'stormy':
      case 'thunderstorm':
        return Icons.flash_on;
      case 'windy':
        return Icons.air;
      default:
        return isDaytime ? Icons.wb_sunny : Icons.nightlight_round;
    }
  }

  // Get weather color based on condition
  Color get weatherColor {
    if (hasTyphoon) {
      return Colors.red;
    }

    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return isDaytime ? Colors.orange : Colors.indigo;
      case 'cloudy':
      case 'partly cloudy':
        return Colors.grey;
      case 'rainy':
      case 'rain':
        return Colors.blue;
      case 'stormy':
      case 'thunderstorm':
        return Colors.purple;
      case 'windy':
        return Colors.teal;
      default:
        return Colors.orange;
    }
  }

  // Get typhoon warning level
  String get typhoonWarning {
    if (!hasTyphoon) return '';

    switch (typhoonStrength) {
      case 1:
        return 'Tropical Depression';
      case 2:
        return 'Tropical Storm';
      case 3:
        return 'Severe Tropical Storm';
      case 4:
        return 'Typhoon';
      case 5:
        return 'Super Typhoon';
      default:
        return 'Tropical Cyclone';
    }
  }

  // Format temperature with unit
  String get temperatureString => '${temperature.round()}°C';

  // Format humidity with percentage
  String get humidityString => '${humidity.round()}%';

  // Format wind speed
  String get windSpeedString => '${windSpeed.round()} km/h';

  // Get time string
  String get timeString {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Get date string
  String get dateString {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${timestamp.day} ${months[timestamp.month - 1]} ${timestamp.year}';
  }

  // Get full datetime string
  String get datetimeString => '$dateString $timeString';
}
