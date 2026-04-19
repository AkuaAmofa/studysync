class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? studentId;
  final bool isAdmin;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.studentId,
    this.isAdmin = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      studentId: json['studentId'] as String?,
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'studentId': studentId,
        'isAdmin': isAdmin,
      };

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    String? studentId,
    bool? isAdmin,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      studentId: studentId ?? this.studentId,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
