class Profile {
  final String id;
  final String? displayName;
  final DateTime createdAt;

  const Profile({
    required this.id,
    this.displayName,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        displayName: json['display_name'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'created_at': createdAt.toIso8601String(),
      };
}
