class DetectionModel {
  final String id;
  final String userId;
  final String type; // 'cow', 'insect', 'plant_health', 'weather', 'wind'
  final String? imageUrl;
  final String? description;
  final DateTime detectedAt;
  final Map<String, dynamic>? data; // Additional data like weather info

  DetectionModel({
    required this.id,
    required this.userId,
    required this.type,
    this.imageUrl,
    this.description,
    required this.detectedAt,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'imageUrl': imageUrl,
      'description': description,
      'detectedAt': detectedAt.toIso8601String(),
      'data': data,
    };
  }

  factory DetectionModel.fromMap(Map<String, dynamic> map) {
    return DetectionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      imageUrl: map['imageUrl'],
      description: map['description'],
      detectedAt: map['detectedAt'] != null
          ? DateTime.parse(map['detectedAt'])
          : DateTime.now(),
      data: map['data'],
    );
  }
}




