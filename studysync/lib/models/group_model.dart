class GroupModel {
  final String id;
  final String name;
  final String subject;
  final String description;
  final double latitude;
  final double longitude;
  final String locationName;
  final String creatorId;
  final int maxMembers;
  final bool isActive;
  final DateTime createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.creatorId,
    required this.maxMembers,
    required this.isActive,
    required this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationName: json['locationName'] as String,
      creatorId: json['creatorId'] as String,
      maxMembers: json['maxMembers'] as int,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subject': subject,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'creatorId': creatorId,
        'maxMembers': maxMembers,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };
}
