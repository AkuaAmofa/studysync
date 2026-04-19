enum MemberRole { member, moderator, creator }

class MemberModel {
  final String userId;
  final String groupId;
  final String name;
  final String? avatarUrl;
  final MemberRole role;
  final DateTime joinedAt;

  const MemberModel({
    required this.userId,
    required this.groupId,
    required this.name,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      userId: json['userId'] as String,
      groupId: json['groupId'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: MemberRole.values.firstWhere(
        (r) => r.name == (json['role'] as String? ?? 'member'),
        orElse: () => MemberRole.member,
      ),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'groupId': groupId,
        'name': name,
        'avatarUrl': avatarUrl,
        'role': role.name,
        'joinedAt': joinedAt.toIso8601String(),
      };
}
