import 'package:cloud_firestore/cloud_firestore.dart';

class AuditSeverity {
  static const info = 'info';
  static const warning = 'warning';
  static const critical = 'critical';

  static const values = [info, warning, critical];
}

class AuditLogModel {
  final String id;
  final String action;
  final String entityType;
  final String? entityId;
  final String severity;
  final String actorId;
  final String actorEmail;
  final String? actorName;
  final String? targetUserId;
  final String? description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AuditLogModel({
    required this.id,
    required this.action,
    required this.entityType,
    this.entityId,
    required this.severity,
    required this.actorId,
    required this.actorEmail,
    this.actorName,
    this.targetUserId,
    this.description,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'severity': severity,
      'actorId': actorId,
      'actorEmail': actorEmail,
      'actorName': actorName,
      'targetUserId': targetUserId,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory AuditLogModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return AuditLogModel(
      id: map['id'] ?? documentId ?? '',
      action: map['action'] ?? '',
      entityType: map['entityType'] ?? '',
      entityId: map['entityId'],
      severity: map['severity'] ?? AuditSeverity.info,
      actorId: map['actorId'] ?? '',
      actorEmail: map['actorEmail'] ?? '',
      actorName: map['actorName'],
      targetUserId: map['targetUserId'],
      description: map['description'],
      timestamp: _parseTimestamp(map['timestamp']) ?? DateTime.now(),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
