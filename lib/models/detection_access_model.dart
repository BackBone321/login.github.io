import 'package:cloud_firestore/cloud_firestore.dart';

class DetectionAccessModel {
  final String userId;
  final bool canAccess;
  final List<String> allowedTypes;
  final String grantedBy;
  final DateTime? grantedAt;
  final DateTime updatedAt;

  const DetectionAccessModel({
    required this.userId,
    required this.canAccess,
    required this.allowedTypes,
    required this.grantedBy,
    this.grantedAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'canAccess': canAccess,
      'allowedTypes': allowedTypes,
      'grantedBy': grantedBy,
      'grantedAt': grantedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DetectionAccessModel.fromMap(Map<String, dynamic> map) {
    return DetectionAccessModel(
      userId: map['userId'] ?? '',
      canAccess: map['canAccess'] ?? false,
      allowedTypes: List<String>.from(
        (map['allowedTypes'] ?? const <String>[]) as List,
      ),
      grantedBy: map['grantedBy'] ?? 'admin',
      grantedAt: _parseDate(map['grantedAt']),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
