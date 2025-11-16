class OTPModel {
  final String id;
  final String email;
  final String code;
  final String purpose;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUsed;
  final int attempts;

  OTPModel({
    required this.id,
    required this.email,
    required this.code,
    required this.purpose,
    required this.createdAt,
    required this.expiresAt,
    this.isUsed = false,
    this.attempts = 0,
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
      'attempts': attempts,
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
      attempts: map['attempts'] ?? 0,
    );
  }

  bool get isValid {
    return !isUsed && !isExpired && attempts < 3;
  }

  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  bool get hasExceededAttempts {
    return attempts >= 3;
  }
}
