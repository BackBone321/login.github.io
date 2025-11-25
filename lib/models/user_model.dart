import 'package:cloud_firestore/cloud_firestore.dart';

const String defaultAvatarStyle = 'sprout_guardian';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isAdmin;
  final String? bio;
  final DateTime createdAt;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? avatarStyle;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isAdmin = false,
    this.bio,
    required this.createdAt,
    this.isOnline = false,
    this.lastSeen,
    this.avatarStyle,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isAdmin': isAdmin,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'avatarStyle': avatarStyle,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      isAdmin: map['isAdmin'] ?? false,
      bio: map['bio'],
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      isOnline: map['isOnline'] ?? false,
      lastSeen: _parseDate(map['lastSeen']),
      avatarStyle: map['avatarStyle'],
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




