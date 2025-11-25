class InviteModel {
  final String id;
  final String email;
  final String invitedBy;
  final String code;
  final String status; // pending, accepted, expired
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? message;

  InviteModel({
    required this.id,
    required this.email,
    required this.invitedBy,
    required this.code,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.message,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'invitedBy': invitedBy,
      'code': code,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'message': message,
    };
  }

  factory InviteModel.fromMap(Map<String, dynamic> map) {
    return InviteModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      invitedBy: map['invitedBy'] ?? '',
      code: map['code'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'])
          : DateTime.now().add(const Duration(days: 7)),
      message: map['message'],
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

