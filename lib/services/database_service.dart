import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/friend_model.dart';
import '../models/announcement_model.dart';
import '../models/detection_model.dart';
import '../models/message_model.dart';
import '../models/group_model.dart';
import '../models/group_message_model.dart';
import '../models/invite_model.dart';
import '../models/detection_access_model.dart';
import '../models/audit_log_model.dart';
import 'audit_service.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuditService _auditService = AuditService();
  final Random _random = Random.secure();
  final Map<String, Stream<UserModel?>> _userStreamCache = {};

  String _generateInviteCode([int length = 8]) {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      length,
      (_) => characters[_random.nextInt(characters.length)],
    ).join();
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  void _recordAudit({
    required String action,
    required String entityType,
    String? entityId,
    String severity = AuditSeverity.info,
    String? description,
    String? targetUserId,
    Map<String, dynamic>? metadata,
    String? actorId,
    String? actorEmail,
    String? actorName,
  }) {
    unawaited(
      _auditService.logAction(
        action: action,
        entityType: entityType,
        entityId: entityId,
        severity: severity,
        description: description,
        targetUserId: targetUserId,
        metadata: metadata,
        actorIdOverride: actorId,
        actorEmailOverride: actorEmail,
        actorNameOverride: actorName,
      ),
    );
  }

  Future<bool> _hasSharedDetectionInvite(String? email) async {
    if (email == null || email.trim().isEmpty) return false;
    final normalized = email.trim().toLowerCase();

    final snapshot = await _firestore
        .collection('invites')
        .where('email', isEqualTo: normalized)
        .where('shareDetections', isEqualTo: true)
        .limit(5)
        .get();

    final now = DateTime.now();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = (data['status'] ?? 'pending') as String;
      if (status == 'revoked') continue;
      final expiresAt = _parseDateTime(data['expiresAt']);
      if (expiresAt != null && expiresAt.isBefore(now)) continue;
      return true;
    }
    return false;
  }

  Future<DetectionAccessModel?> _getDetectionAccess(String userId) async {
    final doc = await _firestore
        .collection('detection_access')
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return DetectionAccessModel.fromMap(doc.data()!);
  }

  bool _isDetectionTypeAllowed(String type, List<String>? allowedTypes) {
    if (allowedTypes == null ||
        allowedTypes.isEmpty ||
        allowedTypes.contains('all')) {
      return true;
    }

    final normalizedType = type.toLowerCase();
    for (final allowed in allowedTypes) {
      if (normalizedType.contains(allowed)) {
        return true;
      }
    }
    return false;
  }

  // User operations
  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
    _recordAudit(
      action: 'user.create',
      entityType: 'user',
      entityId: user.uid,
      severity: AuditSeverity.info,
      description: 'Created user ${user.email}',
      targetUserId: user.uid,
      metadata: {
        'email': user.email,
        'displayName': user.displayName,
        'isAdmin': user.isAdmin,
      },
      actorId: user.uid,
      actorEmail: user.email,
      actorName: user.displayName,
    );
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
    _recordAudit(
      action: 'user.update',
      entityType: 'user',
      entityId: uid,
      severity: AuditSeverity.info,
      description: 'Updated profile fields for $uid',
      targetUserId: uid,
      metadata: {'updatedFields': data.keys.toList()},
    );
  }

  Future<void> updateUserPresence({required bool isOnline, String? uid}) async {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return;
    await _firestore.collection('users').doc(userId).update({
      'isOnline': isOnline,
      'lastSeen': DateTime.now().toIso8601String(),
    });
  }

  Stream<UserModel?> getUserStream(String uid) {
    if (_userStreamCache.containsKey(uid)) {
      return _userStreamCache[uid]!;
    }
    final stream = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null)
        .asBroadcastStream();
    _userStreamCache[uid] = stream;
    return stream;
  }

  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<GroupModel>> getAllGroups() {
    return _firestore
        .collection('groups')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Friend operations
  Future<void> sendFriendRequest(String friendId) async {
    final currentUserId = _auth.currentUser!.uid;
    final requestId = '$currentUserId-$friendId';

    await _firestore.collection('friends').doc(requestId).set({
      'id': requestId,
      'userId': currentUserId,
      'friendId': friendId,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    });
    _recordAudit(
      action: 'friends.request_sent',
      entityType: 'friend_request',
      entityId: requestId,
      severity: AuditSeverity.info,
      description: 'Sent friend request to $friendId',
      targetUserId: friendId,
      metadata: {'requestId': requestId, 'friendId': friendId},
    );
  }

  Future<void> acceptFriendRequest(String requestId) async {
    await _firestore.collection('friends').doc(requestId).update({
      'status': 'accepted',
      'updatedAt': DateTime.now().toIso8601String(),
    });
    final ids = requestId.split('-');
    _recordAudit(
      action: 'friends.request_accepted',
      entityType: 'friend_request',
      entityId: requestId,
      severity: AuditSeverity.info,
      description: 'Accepted friend request $requestId',
      targetUserId: ids.length > 1 ? ids[1] : null,
      metadata: {
        'requestId': requestId,
        'initiatorId': ids.isNotEmpty ? ids.first : null,
        'receiverId': ids.length > 1 ? ids[1] : null,
      },
    );
  }

  Future<void> rejectFriendRequest(String requestId) async {
    final docRef = _firestore.collection('friends').doc(requestId);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    await docRef.delete();
    _recordAudit(
      action: 'friends.request_rejected',
      entityType: 'friend_request',
      entityId: requestId,
      severity: AuditSeverity.warning,
      description: 'Rejected friend request $requestId',
      targetUserId: data?['userId'] ?? data?['friendId'],
      metadata: data,
    );
  }

  Future<void> unfriend(String userId, String friendId) async {
    // Try both possible request IDs since friendship can be in either direction
    final requestId1 = '$userId-$friendId';
    final requestId2 = '$friendId-$userId';

    // Delete both possible friendship documents
    await _firestore.collection('friends').doc(requestId1).delete();
    await _firestore.collection('friends').doc(requestId2).delete();
    _recordAudit(
      action: 'friends.unfriend',
      entityType: 'friendship',
      entityId: '$userId:$friendId',
      severity: AuditSeverity.warning,
      description: 'Removed friendship between $userId and $friendId',
      metadata: {
        'requestIds': [requestId1, requestId2],
      },
    );
  }

  Future<void> connectWithUser(String friendId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final directId = '$currentUserId-$friendId';
    final reverseId = '$friendId-$currentUserId';
    final friendsCollection = _firestore.collection('friends');
    final timestamp = DateTime.now().toIso8601String();

    final reverseDoc = await friendsCollection.doc(reverseId).get();
    String outcome = 'created';
    String? recordedRequestId;

    if (reverseDoc.exists) {
      await friendsCollection.doc(reverseId).update({
        'status': 'accepted',
        'updatedAt': timestamp,
      });
      outcome = 'accepted_reverse';
      recordedRequestId = reverseId;
    } else {
      final directDoc = await friendsCollection.doc(directId).get();
      if (directDoc.exists) {
        await friendsCollection.doc(directId).update({
          'status': 'accepted',
          'updatedAt': timestamp,
        });
        outcome = 'accepted_direct';
        recordedRequestId = directId;
      } else {
        await friendsCollection.doc(directId).set({
          'id': directId,
          'userId': currentUserId,
          'friendId': friendId,
          'status': 'accepted',
          'createdAt': timestamp,
          'updatedAt': timestamp,
        });
        recordedRequestId = directId;
      }
    }

    _recordAudit(
      action: 'friends.connect',
      entityType: 'friendship',
      entityId: recordedRequestId,
      severity: AuditSeverity.info,
      description: 'Connected $currentUserId with $friendId via $outcome',
      targetUserId: friendId,
      metadata: {'requestId': recordedRequestId, 'outcome': outcome},
    );
  }

  Stream<List<String>> getFriends(String userId) {
    return _firestore.collection('friends').snapshots().map((snapshot) {
      final friendIds = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final friendUserId = data['userId'] as String;
        final friendFriendId = data['friendId'] as String;
        final status = data['status'] as String;

        if (status == 'accepted') {
          if (friendUserId == userId) {
            friendIds.add(friendFriendId);
          } else if (friendFriendId == userId) {
            friendIds.add(friendUserId);
          }
        }
      }
      return friendIds.toList();
    });
  }

  Stream<List<FriendModel>> getPendingRequests(String userId) {
    return _firestore
        .collection('friends')
        .where('friendId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<bool> areFriends(String userId1, String userId2) async {
    final requestId1 = '$userId1-$userId2';
    final requestId2 = '$userId2-$userId1';

    final doc1 = await _firestore.collection('friends').doc(requestId1).get();
    final doc2 = await _firestore.collection('friends').doc(requestId2).get();

    if (doc1.exists && doc1.data()!['status'] == 'accepted') return true;
    if (doc2.exists && doc2.data()!['status'] == 'accepted') return true;
    return false;
  }

  /// Check if there's a pending friend request between two users
  /// Returns: 'none', 'pending_sent', 'pending_received', or 'friends'
  Future<String> getFriendshipStatus(String currentUserId, String otherUserId) async {
    final sentRequestId = '$currentUserId-$otherUserId';
    final receivedRequestId = '$otherUserId-$currentUserId';

    final sentDoc = await _firestore.collection('friends').doc(sentRequestId).get();
    final receivedDoc = await _firestore.collection('friends').doc(receivedRequestId).get();

    // Check if already friends
    if (sentDoc.exists && sentDoc.data()!['status'] == 'accepted') return 'friends';
    if (receivedDoc.exists && receivedDoc.data()!['status'] == 'accepted') return 'friends';

    // Check if current user sent a pending request
    if (sentDoc.exists && sentDoc.data()!['status'] == 'pending') return 'pending_sent';

    // Check if current user received a pending request
    if (receivedDoc.exists && receivedDoc.data()!['status'] == 'pending') return 'pending_received';

    return 'none';
  }

  /// Stream version to get real-time friendship status updates
  Stream<String> getFriendshipStatusStream(String currentUserId, String otherUserId) {
    final sentRequestId = '$currentUserId-$otherUserId';
    final receivedRequestId = '$otherUserId-$currentUserId';

    return _firestore.collection('friends').snapshots().map((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;

        if (doc.id == sentRequestId) {
          if (status == 'accepted') return 'friends';
          if (status == 'pending') return 'pending_sent';
        }

        if (doc.id == receivedRequestId) {
          if (status == 'accepted') return 'friends';
          if (status == 'pending') return 'pending_received';
        }
      }
      return 'none';
    });
  }

  // Announcement operations
  Future<void> createAnnouncement(AnnouncementModel announcement) async {
    await _firestore
        .collection('announcements')
        .doc(announcement.id)
        .set(announcement.toMap());
    _recordAudit(
      action: 'announcement.create',
      entityType: 'announcement',
      entityId: announcement.id,
      severity: AuditSeverity.info,
      description: 'Published announcement "${announcement.title}"',
      targetUserId: announcement.userId,
      metadata: {'title': announcement.title, 'author': announcement.userName},
    );
  }

  Stream<List<AnnouncementModel>> getAnnouncementsForUser(String userId) {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AnnouncementModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Detection operations
  Future<void> createDetection(DetectionModel detection) async {
    await _firestore
        .collection('detections')
        .doc(detection.id)
        .set(detection.toMap());
    _recordAudit(
      action: 'detection.create',
      entityType: 'detection',
      entityId: detection.id,
      severity: AuditSeverity.info,
      description: 'Recorded ${detection.type} detection',
      targetUserId: detection.userId,
      metadata: {
        'type': detection.type,
        'hasImage': detection.imageUrl != null,
      },
    );
  }

  Stream<List<DetectionModel>> getDetectionsForUser(String userId) async* {
    final user = await getUser(userId);
    final adminSnapshot = await _firestore
        .collection('users')
        .where('isAdmin', isEqualTo: true)
        .get();

    if (adminSnapshot.docs.isEmpty) {
      yield [];
      return;
    }

    if (user?.isAdmin == true) {
      yield* _firestore
          .collection('detections')
          .orderBy('detectedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => DetectionModel.fromMap(doc.data()))
                .toList(),
          );
      return;
    }

    final allAdminIds = adminSnapshot.docs.map((doc) => doc.id).toList();
    final accessibleAdminIds = <String>{};
    bool hasAccess = false;
    bool shareAllDetections = false;
    List<String>? allowedTypes;

    final manualAccess = await _getDetectionAccess(userId);
    if (manualAccess != null) {
      if (manualAccess.canAccess != true) {
        yield [];
        return;
      }
      hasAccess = true;
      shareAllDetections = true;
      allowedTypes = manualAccess.allowedTypes;
      final grantedBy = manualAccess.grantedBy.trim();
      if (grantedBy.isNotEmpty) {
        accessibleAdminIds.add(grantedBy);
      }
    }

    if (!hasAccess) {
      for (final adminDoc in adminSnapshot.docs) {
        final adminId = adminDoc.id;
        if (await areFriends(userId, adminId)) {
          accessibleAdminIds.add(adminId);
          hasAccess = true;
        }
      }
    }

    if (!hasAccess) {
      final sharedInvite = await _hasSharedDetectionInvite(user?.email);
      if (sharedInvite) {
        hasAccess = true;
        shareAllDetections = true;
        accessibleAdminIds.addAll(allAdminIds);
      }
    }

    if (!hasAccess) {
      yield [];
      return;
    }

    if (accessibleAdminIds.isEmpty) {
      accessibleAdminIds.addAll(allAdminIds);
    }

    yield* _buildDetectionShareStream(
      adminIds: accessibleAdminIds,
      allowedTypes: allowedTypes,
      filterByAdminIds: !shareAllDetections,
    );
  }

  Stream<List<DetectionModel>> getAllDetections() {
    return _firestore
        .collection('detections')
        .orderBy('detectedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DetectionModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<DetectionModel>> _buildDetectionShareStream({
    required Set<String> adminIds,
    List<String>? allowedTypes,
    bool filterByAdminIds = true,
  }) {
    if (filterByAdminIds && adminIds.isEmpty) {
      return const Stream.empty();
    }

    if (filterByAdminIds && adminIds.length == 1) {
      final adminId = adminIds.first;
      return _firestore
          .collection('detections')
          .where('userId', isEqualTo: adminId)
          .orderBy('detectedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => DetectionModel.fromMap(doc.data()))
                .where(
                  (detection) => _isDetectionTypeAllowed(
                    detection.type.toLowerCase(),
                    allowedTypes,
                  ),
                )
                .toList(),
          );
    }

    const maxRecentDetections = 200;
    final query = _firestore
        .collection('detections')
        .orderBy('detectedAt', descending: true)
        .limit(maxRecentDetections);

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => DetectionModel.fromMap(doc.data()))
          .where(
            (detection) =>
                !filterByAdminIds || adminIds.contains(detection.userId),
          )
          .where(
            (detection) => _isDetectionTypeAllowed(
              detection.type.toLowerCase(),
              allowedTypes,
            ),
          )
          .toList(),
    );
  }

  // Detection access operations
  Stream<List<DetectionAccessModel>> getDetectionAccessList() {
    return _firestore
        .collection('detection_access')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DetectionAccessModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> setDetectionAccess({
    required String userId,
    required bool enabled,
    List<String>? allowedTypes,
  }) async {
    final docRef = _firestore.collection('detection_access').doc(userId);
    final now = DateTime.now();
    final normalizedTypes = (allowedTypes ?? ['all'])
        .map((type) => type.toLowerCase())
        .toSet()
        .toList();

    await docRef.set({
      'userId': userId,
      'canAccess': enabled,
      'allowedTypes': enabled ? normalizedTypes : <String>[],
      'grantedBy': _auth.currentUser?.uid ?? 'admin',
      'grantedAt': enabled ? now.toIso8601String() : null,
      'updatedAt': now.toIso8601String(),
    }, SetOptions(merge: true));

    _recordAudit(
      action: enabled ? 'detection_access.grant' : 'detection_access.revoke',
      entityType: 'detection_access',
      entityId: userId,
      severity: enabled ? AuditSeverity.info : AuditSeverity.warning,
      description: enabled
          ? 'Granted detection access to $userId'
          : 'Revoked detection access from $userId',
      targetUserId: userId,
      metadata: {'allowedTypes': enabled ? normalizedTypes : []},
    );
  }

  // Message operations
  Future<void> sendMessage(MessageModel message) async {
    await _firestore
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
    _recordAudit(
      action: 'messages.send',
      entityType: 'message',
      entityId: message.id,
      severity: AuditSeverity.info,
      description: 'Sent message to ${message.receiverId}',
      targetUserId: message.receiverId,
      metadata: {
        'senderId': message.senderId,
        'receiverId': message.receiverId,
      },
    );
  }

  Future<void> deleteMessage(String messageId) async {
    final docRef = _firestore.collection('messages').doc(messageId);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    await docRef.delete();
    _recordAudit(
      action: 'messages.delete',
      entityType: 'message',
      entityId: messageId,
      severity: AuditSeverity.warning,
      description: 'Deleted message $messageId',
      metadata: data,
      targetUserId: data?['receiverId'],
    );
  }

  Stream<List<MessageModel>> getMessages(String userId, String otherUserId) {
    final stream1 = _firestore
        .collection('messages')
        .where('senderId', isEqualTo: userId)
        .where('receiverId', isEqualTo: otherUserId)
        .snapshots();

    final stream2 = _firestore
        .collection('messages')
        .where('senderId', isEqualTo: otherUserId)
        .where('receiverId', isEqualTo: userId)
        .snapshots();

    final controller = StreamController<List<MessageModel>>();
    QuerySnapshot? snapshot1;
    QuerySnapshot? snapshot2;
    StreamSubscription<QuerySnapshot>? sub1;
    StreamSubscription<QuerySnapshot>? sub2;

    void updateMessages() {
      if (controller.isClosed) return;

      final allMessages = <MessageModel>[];

      if (snapshot1 != null) {
        for (final doc in snapshot1!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          allMessages.add(MessageModel.fromMap(data));
        }
      }

      if (snapshot2 != null) {
        for (final doc in snapshot2!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          allMessages.add(MessageModel.fromMap(data));
        }
      }

      final uniqueMessages = <String, MessageModel>{};
      for (final message in allMessages) {
        uniqueMessages[message.id] = message;
      }

      final sortedMessages = uniqueMessages.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (!controller.isClosed) {
        controller.add(sortedMessages);
      }
    }

    controller.onListen = () {
      sub1 = stream1.listen((snapshot) {
        snapshot1 = snapshot;
        updateMessages();
      });

      sub2 = stream2.listen((snapshot) {
        snapshot2 = snapshot;
        updateMessages();
      });
    };

    controller.onCancel = () async {
      await sub1?.cancel();
      await sub2?.cancel();
      if (!controller.isClosed) {
        await controller.close();
      }
    };

    return controller.stream;
  }

  Stream<List<Map<String, dynamic>>> getConversations(String userId) {
    return _firestore
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final conversations = <String, Map<String, dynamic>>{};

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final senderId = (data['senderId'] ?? '') as String;
            final receiverId = (data['receiverId'] ?? '') as String;

            if (senderId != userId && receiverId != userId) {
              continue;
            }

            final otherUserId = senderId == userId ? receiverId : senderId;
            if (otherUserId.isEmpty) continue;

            final timestampRaw = data['timestamp'];
            DateTime timestamp;
            if (timestampRaw is Timestamp) {
              timestamp = timestampRaw.toDate();
            } else if (timestampRaw is String) {
              timestamp = DateTime.tryParse(timestampRaw) ?? DateTime.now();
            } else if (timestampRaw is DateTime) {
              timestamp = timestampRaw;
            } else {
              timestamp = DateTime.now();
            }

            final lastMessage = (data['content'] ?? '') as String;
            final senderName = (data['senderName'] ?? '') as String;

            final existing = conversations[otherUserId];
            if (existing == null ||
                (existing['timestamp'] as DateTime).isBefore(timestamp)) {
              conversations[otherUserId] = {
                'userId': otherUserId,
                'userName': senderName,
                'lastMessage': lastMessage,
                'timestamp': timestamp,
                'unread': 0,
              };
            }
          }

          final list = conversations.values.toList();
          list.sort(
            (a, b) => (b['timestamp'] as DateTime).compareTo(
              a['timestamp'] as DateTime,
            ),
          );
          return list;
        });
  }

  // Search users
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) {
      return [];
    }
    final snapshot = await _firestore.collection('users').get();
    final allUsers = snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList();

    // Filter by query (case insensitive)
    return allUsers.where((user) {
      final name = (user.displayName ?? user.email).toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();
  }

  // ===== GROUP METHODS - ADD THESE HERE =====

  // Group Management Methods
  Future<void> createGroup(GroupModel group) async {
    await _firestore.collection('groups').doc(group.id).set(group.toMap());
    _recordAudit(
      action: 'group.create',
      entityType: 'group',
      entityId: group.id,
      severity: AuditSeverity.info,
      description: 'Created group "${group.name}"',
      targetUserId: group.creatorId,
      metadata: {'name': group.name, 'memberCount': group.memberIds.length},
    );
  }

  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> updateGroup(
    String groupId, {
    String? name,
    String? description,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;

    if (updates.isEmpty) return;
    await _firestore.collection('groups').doc(groupId).update(updates);
    _recordAudit(
      action: 'group.update',
      entityType: 'group',
      entityId: groupId,
      severity: AuditSeverity.info,
      description: 'Updated group $groupId',
      metadata: updates,
    );
  }

  Future<void> removeGroupMember(String groupId, String memberId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([memberId]),
      'adminIds': FieldValue.arrayRemove([memberId]),
    });
    _recordAudit(
      action: 'group.member_removed',
      entityType: 'group',
      entityId: groupId,
      severity: AuditSeverity.warning,
      description: 'Removed member $memberId from group $groupId',
      targetUserId: memberId,
    );
  }

  Future<void> addGroupAdmin(String groupId, String adminId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'adminIds': FieldValue.arrayUnion([adminId]),
    });
    _recordAudit(
      action: 'group.admin_added',
      entityType: 'group',
      entityId: groupId,
      severity: AuditSeverity.info,
      description: 'Granted admin to $adminId',
      targetUserId: adminId,
    );
  }

  Future<void> removeGroupAdmin(String groupId, String adminId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'adminIds': FieldValue.arrayRemove([adminId]),
    });
    _recordAudit(
      action: 'group.admin_removed',
      entityType: 'group',
      entityId: groupId,
      severity: AuditSeverity.warning,
      description: 'Revoked admin from $adminId',
      targetUserId: adminId,
    );
  }

  // Add members to a group
  Future<void> addGroupMembers(String groupId, List<String> memberIds) async {
    if (memberIds.isEmpty) return;
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion(memberIds),
    });
    _recordAudit(
      action: 'group.members_added',
      entityType: 'group',
      entityId: groupId,
      severity: AuditSeverity.info,
      description: 'Added ${memberIds.length} member(s) to $groupId',
      metadata: {'members': memberIds},
    );
  }

  Future<void> deleteGroup(String groupId) async {
    final groupRef = _firestore.collection('groups').doc(groupId);
    final groupSnapshot = await groupRef.get();

    final messagesSnapshot = await _firestore
        .collection('group_messages')
        .where('groupId', isEqualTo: groupId)
        .get();

    for (final doc in messagesSnapshot.docs) {
      await doc.reference.delete();
    }

    await groupRef.delete();
    _recordAudit(
      action: 'group.delete',
      entityType: 'group',
      entityId: groupId,
      severity: AuditSeverity.critical,
      description: 'Deleted group $groupId',
      metadata: {
        'deletedMessages': messagesSnapshot.docs.length,
        'group': groupSnapshot.data(),
      },
    );
  }

  // Group Message Methods
  Future<void> sendGroupMessage(GroupMessageModel message) async {
    await _firestore
        .collection('group_messages')
        .doc(message.id)
        .set(message.toMap());
    _recordAudit(
      action: 'group.message_send',
      entityType: 'group_message',
      entityId: message.id,
      severity: AuditSeverity.info,
      description: 'Sent group message in ${message.groupId}',
      metadata: {'groupId': message.groupId, 'senderId': message.senderId},
    );
  }

  Future<void> deleteGroupMessage(String messageId) async {
    final collection = _firestore.collection('group_messages');
    final docRef = collection.doc(messageId);
    final doc = await docRef.get();
    Map<String, dynamic>? deletedData;

    if (doc.exists) {
      deletedData = doc.data();
      await docRef.delete();
    } else {
      final query = await collection
          .where('id', isEqualTo: messageId)
          .limit(1)
          .get();

      for (final docSnapshot in query.docs) {
        deletedData = docSnapshot.data();
        await docSnapshot.reference.delete();
      }
    }

    _recordAudit(
      action: 'group.message_delete',
      entityType: 'group_message',
      entityId: messageId,
      severity: AuditSeverity.warning,
      description: 'Deleted group message $messageId',
      metadata: deletedData,
    );
  }

  Stream<List<GroupMessageModel>> getGroupMessages(String groupId) {
    return _firestore
        .collection('group_messages')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => GroupMessageModel.fromMap(doc.data()))
              .toList();
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return messages;
        });
  }

  // ===== INVITE METHODS =====
  Future<InviteModel> createInvite(
    String email, {
    String? message,
    Duration validity = const Duration(days: 7),
    bool shareDetections = false,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final docRef = _firestore.collection('invites').doc();
    final now = DateTime.now();
    final invite = InviteModel(
      id: docRef.id,
      email: trimmedEmail,
      invitedBy: _auth.currentUser?.uid ?? 'admin',
      code: _generateInviteCode(),
      status: 'pending',
      createdAt: now,
      expiresAt: now.add(validity),
      message: message,
      shareDetections: shareDetections,
    );

    await docRef.set(invite.toMap());
    _recordAudit(
      action: 'invite.create',
      entityType: 'invite',
      entityId: invite.id,
      severity: AuditSeverity.info,
      description: 'Created invite for $trimmedEmail',
      metadata: {
        'email': trimmedEmail,
        'code': invite.code,
        'expiresAt': invite.expiresAt.toIso8601String(),
        'shareDetections': shareDetections,
      },
    );
    return invite;
  }

  Stream<List<InviteModel>> getInvites({bool onlyActive = false}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('invites')
        .orderBy('createdAt', descending: true);

    if (onlyActive) {
      query = query.where('status', isEqualTo: 'pending');
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => InviteModel.fromMap(doc.data())).toList(),
    );
  }

  Future<void> updateInviteStatus(String inviteId, String status) async {
    final docRef = _firestore.collection('invites').doc(inviteId);
    final snapshot = await docRef.get();
    final previous = snapshot.data();
    await docRef.update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    final lowered = status.toLowerCase();
    final severity = (lowered == 'expired' || lowered == 'revoked')
        ? AuditSeverity.warning
        : AuditSeverity.info;
    _recordAudit(
      action: 'invite.status_update',
      entityType: 'invite',
      entityId: inviteId,
      severity: severity,
      description: 'Invite $inviteId marked as $status',
      metadata: {
        'email': previous?['email'],
        'previousStatus': previous?['status'],
        'newStatus': status,
      },
    );
  }

  // ===== END INVITE METHODS =====

  // ===== UNREAD MESSAGE METHODS =====

  /// Stream to get count of unread direct messages for a user
  Stream<int> getUnreadMessageCount(String userId) {
    return _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Stream to get count of unread group messages for a user
  Stream<int> getUnreadGroupMessageCount(String userId) {
    // First get user's groups, then count unread messages
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .asyncMap((groupsSnapshot) async {
      if (groupsSnapshot.docs.isEmpty) return 0;

      final groupIds = groupsSnapshot.docs.map((doc) => doc.id).toList();
      int totalUnread = 0;

      // Check each group for unread messages
      for (final groupId in groupIds) {
        final messagesSnapshot = await _firestore
            .collection('group_messages')
            .where('groupId', isEqualTo: groupId)
            .where('senderId', isNotEqualTo: userId)
            .get();

        // Count messages that the user hasn't read
        for (final doc in messagesSnapshot.docs) {
          final data = doc.data();
          final readBy = (data['readBy'] as List<dynamic>?) ?? [];
          if (!readBy.contains(userId)) {
            totalUnread++;
          }
        }
      }

      return totalUnread;
    });
  }

  /// Mark a direct message as read
  Future<void> markMessageAsRead(String messageId) async {
    await _firestore.collection('messages').doc(messageId).update({
      'isRead': true,
    });
  }

  /// Mark all messages from a specific sender as read
  Future<void> markMessagesAsRead(String senderId, String receiverId) async {
    final snapshot = await _firestore
        .collection('messages')
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  /// Mark a group message as read by a user
  Future<void> markGroupMessageAsRead(String messageId, String userId) async {
    await _firestore.collection('group_messages').doc(messageId).update({
      'readBy': FieldValue.arrayUnion([userId]),
    });
  }

  /// Mark all group messages as read for a user in a specific group
  Future<void> markAllGroupMessagesAsRead(String groupId, String userId) async {
    final snapshot = await _firestore
        .collection('group_messages')
        .where('groupId', isEqualTo: groupId)
        .where('senderId', isNotEqualTo: userId)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final readBy = (data['readBy'] as List<dynamic>?) ?? [];
      if (!readBy.contains(userId)) {
        await doc.reference.update({
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }
    }
  }

  /// Stream to get unread count from a specific user (for conversation cards)
  Stream<int> getUnreadCountFromUser(String senderId, String receiverId) {
    return _firestore
        .collection('messages')
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Stream to get unread group message count for a specific group
  Stream<int> getUnreadGroupCountForGroup(String groupId, String userId) {
    return _firestore
        .collection('group_messages')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
      int unreadCount = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final senderId = data['senderId'] as String?;
        // Don't count messages sent by the user themselves
        if (senderId == userId) continue;

        final readBy = (data['readBy'] as List<dynamic>?) ?? [];
        if (!readBy.contains(userId)) {
          unreadCount++;
        }
      }
      return unreadCount;
    });
  }

  // ===== END UNREAD MESSAGE METHODS =====

  // ===== END OF GROUP METHODS =====
}
