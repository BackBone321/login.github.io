import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/friend_model.dart';
import '../models/announcement_model.dart';
import '../models/detection_model.dart';
import '../models/message_model.dart';
import '../models/group_model.dart';
import '../models/group_message_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
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

  // Message operations
  Future<void> sendMessage(MessageModel message) async {
    await _firestore
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }

  Stream<List<MessageModel>> getMessages(String userId, String otherUserId) {
    // Get messages where current user is sender and other user is receiver
    final stream1 = _firestore
        .collection('messages')
        .where('senderId', isEqualTo: userId)
        .where('receiverId', isEqualTo: otherUserId)
        .orderBy('timestamp', descending: true)
        .snapshots();

    // Get messages where other user is sender and current user is receiver
    final stream2 = _firestore
        .collection('messages')
        .where('senderId', isEqualTo: otherUserId)
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();

    // Combine both streams manually
    StreamController<List<MessageModel>> controller =
        StreamController<List<MessageModel>>.broadcast();
    QuerySnapshot? snapshot1;
    QuerySnapshot? snapshot2;

    void updateMessages() {
      final allMessages = <MessageModel>[];

      // Add messages from stream1 if available
      if (snapshot1 != null) {
        for (var doc in snapshot1!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          allMessages.add(MessageModel.fromMap(data));
        }
      }

      // Add messages from stream2 if available
      if (snapshot2 != null) {
        for (var doc in snapshot2!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          allMessages.add(MessageModel.fromMap(data));
        }
      }

      // Remove duplicates and sort by timestamp descending
      final uniqueMessages = <String, MessageModel>{};
      for (var message in allMessages) {
        uniqueMessages[message.id] = message;
      }
      final sortedMessages = uniqueMessages.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      controller.add(sortedMessages);
    }

    stream1.listen((snapshot) {
      snapshot1 = snapshot;
      updateMessages();
    });

    stream2.listen((snapshot) {
      snapshot2 = snapshot;
      updateMessages();
    });

    return controller.stream;
  }

  Stream<List<Map<String, dynamic>>> getConversations(String userId) {
    return _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final conversations = <String, Map<String, dynamic>>{};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final senderId = data['senderId'] as String;
            if (!conversations.containsKey(senderId)) {
              conversations[senderId] = {
                'userId': senderId,
                'userName': data['senderName'] ?? '',
                'lastMessage': data['content'] ?? '',
                'timestamp': data['timestamp'],
                'unread': 0,
              };
            }
          }
          return conversations.values.toList();
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

  // Group Message Methods
  Future<void> sendGroupMessage(GroupMessageModel message) async {
    await _firestore.collection('group_messages').add(message.toMap());
  }

  Stream<List<GroupMessageModel>> getGroupMessages(String groupId) {
    return _firestore
        .collection('group_messages')
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupMessageModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // ===== END OF GROUP METHODS =====
}
