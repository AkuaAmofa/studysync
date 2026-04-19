class NoteModel {
  final String id;
  final String groupId;
  final String authorId;
  final String authorName;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;

  const NoteModel({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.imageUrl,
    required this.createdAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'authorId': authorId,
        'authorName': authorName,
        'content': content,
        'imageUrl': imageUrl,
        'createdAt': createdAt.toIso8601String(),
      };
}
