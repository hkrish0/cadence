class Track {
  final String id;
  final String creatorId;
  final String title;
  final String? category;
  final String? description;
  final DateTime createdAt;

  const Track({
    required this.id,
    required this.creatorId,
    required this.title,
    this.category,
    this.description,
    required this.createdAt,
  });

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'] as String,
        creatorId: json['creator_id'] as String,
        title: json['title'] as String,
        category: json['category'] as String?,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'creator_id': creatorId,
        'title': title,
        'category': category,
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };
}
