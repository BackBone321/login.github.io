class OTPModel {
  final String id;
  final String email;
  final String code;
  final String purpose; // 'password_reset', 'change_password', etc.
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUsed;

  OTPModel({
    required this.id,
    required this.email,
    required this.code,
    required this.purpose,
    required this.createdAt,
    required this.expiresAt,
    this.isUsed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'code': code,
      'purpose': purpose,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isUsed': isUsed,
    };
  }

  factory OTPModel.fromMap(Map<String, dynamic> map) {
    return OTPModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      code: map['code'] ?? '',
      purpose: map['purpose'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'])
          : DateTime.now(),
      isUsed: map['isUsed'] ?? false,
    );
  }

  bool get isValid {
    return !isUsed && DateTime.now().isBefore(expiresAt);
  }
}

