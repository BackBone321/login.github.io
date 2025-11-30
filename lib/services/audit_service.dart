import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/audit_log_model.dart';

class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> logAction({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
    String severity = AuditSeverity.info,
    String? targetUserId,
    String? description,
    String? actorIdOverride,
    String? actorEmailOverride,
    String? actorNameOverride,
  }) async {
    try {
      final actor = _auth.currentUser;
      final docRef = _firestore.collection('audit_logs').doc();
      final log = AuditLogModel(
        id: docRef.id,
        action: action,
        entityType: entityType,
        entityId: entityId,
        severity: severity,
        actorId: actorIdOverride ?? actor?.uid ?? 'system',
        actorEmail: actorEmailOverride ?? actor?.email ?? 'system@agriguard',
        actorName: actorNameOverride ?? actor?.displayName,
        targetUserId: targetUserId,
        description: description,
        timestamp: DateTime.now().toUtc(),
        metadata: metadata,
      );

      await docRef.set(log.toMap());
    } catch (e) {
      print('AuditService error for $action: $e');
    }
  }

  Stream<List<AuditLogModel>> streamLogs({int limit = 100, String? severity}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (severity != null) {
      query = query.where('severity', isEqualTo: severity);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => AuditLogModel.fromMap(doc.data(), documentId: doc.id))
          .toList(),
    );
  }
}

