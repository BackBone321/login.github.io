import 'package:cloud_firestore/cloud_firestore.dart';

class DetectionModel {
  final String id;
  final String userId;
  final String type; // 'cow', 'insect', 'plant_health', 'weather', 'wind'
  final String? imageUrl;
  final String? description;
  final DateTime detectedAt;
  final Map<String, dynamic>? data; // Additional data like weather info

  DetectionModel({
    required this.id,
    required this.userId,
    required this.type,
    this.imageUrl,
    this.description,
    required this.detectedAt,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'imageUrl': imageUrl,
      'description': description,
      'detectedAt': detectedAt.toIso8601String(),
      'data': data,
    };
  }

  factory DetectionModel.fromMap(Map<String, dynamic> map) {
    return DetectionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      imageUrl: map['imageUrl'],
      description: map['description'],
      detectedAt: _parseDetectedAt(map['detectedAt']),
      data: _coerceToMap(map['data']),
    );
  }

  static DateTime _parseDetectedAt(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static Map<String, dynamic>? _coerceToMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return value.map<String, dynamic>((key, dynamic val) {
        return MapEntry(key.toString(), val);
      });
    }
    return null;
  }
}


