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

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Random _random = Random.secure();

  String _generateInviteCode([int length = 8]) {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      length,
      (_) => characters[_random.nextInt(characters.length)],
    ).join();
  }

  // User operations
  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
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
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
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
  }

  Future<void> acceptFriendRequest(String requestId) async {
    await _firestore.collection('friends').doc(requestId).update({
      'status': 'accepted',
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _firestore.collection('friends').doc(requestId).delete();
  }

  Future<void> unfriend(String userId, String friendId) async {
    // Try both possible request IDs since friendship can be in either direction
    final requestId1 = '$userId-$friendId';
    final requestId2 = '$friendId-$userId';

    // Delete both possible friendship documents
    await _firestore.collection('friends').doc(requestId1).delete();
    await _firestore.collection('friends').doc(requestId2).delete();
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

  // Announcement operations
  Future<void> createAnnouncement(AnnouncementModel announcement) async {
    await _firestore
        .collection('announcements')
        .doc(announcement.id)
        .set(announcement.toMap());
  }

  Stream<List<AnnouncementModel>> getAnnouncementsForUser(String userId) {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          // Get user's friends
          final friendsSnapshot = await _firestore
              .collection('friends')
              .where('userId', isEqualTo: userId)
              .where('status', isEqualTo: 'accepted')
              .get();

          final friendIds = friendsSnapshot.docs
              .map((doc) => doc.data()['friendId'] as String)
              .toList();
          friendIds.add(userId); // Include own announcements

          // Filter announcements to only show from friends
          return snapshot.docs
              .where((doc) {
                final data = doc.data();
                return friendIds.contains(data['userId']);
              })
              .map((doc) => AnnouncementModel.fromMap(doc.data()))
              .toList();
        });
  }

  // Detection operations
  Future<void> createDetection(DetectionModel detection) async {
    await _firestore
        .collection('detections')
        .doc(detection.id)
        .set(detection.toMap());
  }

  Stream<List<DetectionModel>> getDetectionsForUser(String userId) async* {
    final user = await getUser(userId);
    if (user?.isAdmin == true) {
      // Admin sees all detections
      yield* _firestore
          .collection('detections')
          .orderBy('detectedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => DetectionModel.fromMap(doc.data()))
                .toList(),
          );
    } else {
      // Check if user is friend with admin
      final adminSnapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .limit(1)
          .get();

      if (adminSnapshot.docs.isNotEmpty) {
        final adminId = adminSnapshot.docs.first.id;
        final isFriend = await areFriends(userId, adminId);

        if (isFriend) {
          // Friends of admin see admin's detections
          yield* _firestore
              .collection('detections')
              .where('userId', isEqualTo: adminId)
              .orderBy('detectedAt', descending: true)
              .snapshots()
              .map(
                (snapshot) => snapshot.docs
                    .map((doc) => DetectionModel.fromMap(doc.data()))
                    .toList(),
              );
        }
      }
    }
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

  // Message operations
  Future<void> sendMessage(MessageModel message) async {
    await _firestore
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }

  Future<void> deleteMessage(String messageId) async {
    await _firestore.collection('messages').doc(messageId).delete();
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

    await _firestore.collection('groups').doc(groupId).update(updates);
  }

  Future<void> removeGroupMember(String groupId, String memberId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([memberId]),
      'adminIds': FieldValue.arrayRemove([memberId]),
    });
  }

  Future<void> addGroupAdmin(String groupId, String adminId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'adminIds': FieldValue.arrayUnion([adminId]),
    });
  }

  Future<void> removeGroupAdmin(String groupId, String adminId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'adminIds': FieldValue.arrayRemove([adminId]),
    });
  }

  // Add members to a group
  Future<void> addGroupMembers(String groupId, List<String> memberIds) async {
    if (memberIds.isEmpty) return;
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion(memberIds),
    });
  }

  // Group Message Methods
  Future<void> sendGroupMessage(GroupMessageModel message) async {
    await _firestore
        .collection('group_messages')
        .doc(message.id)
        .set(message.toMap());
  }

  Future<void> deleteGroupMessage(String messageId) async {
    final docRef = _firestore.collection('group_messages').doc(messageId);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
      return;
    }

    final query = await _firestore
        .collection('group_messages')
        .where('id', isEqualTo: messageId)
        .limit(1)
        .get();

    for (final docSnapshot in query.docs) {
      await docSnapshot.reference.delete();
    }
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
    );

    await docRef.set(invite.toMap());
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
    await _firestore.collection('invites').doc(inviteId).update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ===== END INVITE METHODS =====

  // ===== END OF GROUP METHODS =====
}
