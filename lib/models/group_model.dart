class GroupModel {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final List<String> memberIds;
  final List<String> adminIds;
  final DateTime createdAt;
  final String? imageUrl;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.memberIds,
    required this.adminIds,
    required this.createdAt,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      creatorId: map['creatorId'],
      memberIds: List<String>.from(map['memberIds']),
      adminIds: List<String>.from(map['adminIds']),
      createdAt: DateTime.parse(map['createdAt']),
      imageUrl: map['imageUrl'],
    );
  }
}
