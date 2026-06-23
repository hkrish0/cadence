class Enrollment {
  final String id;
  final String userId;
  final String trackId;
  final DateTime enrolledAt;
  final int currentUnlockIndex;
  final DateTime lastUnlockedAt;

  const Enrollment({
    required this.id,
    required this.userId,
    required this.trackId,
    required this.enrolledAt,
    required this.currentUnlockIndex,
    required this.lastUnlockedAt,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) => Enrollment(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        trackId: json['track_id'] as String,
        enrolledAt: DateTime.parse(json['enrolled_at'] as String),
        currentUnlockIndex: json['current_unlock_index'] as int,
        lastUnlockedAt: DateTime.parse(json['last_unlocked_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'track_id': trackId,
        'enrolled_at': enrolledAt.toIso8601String(),
        'current_unlock_index': currentUnlockIndex,
        'last_unlocked_at': lastUnlockedAt.toIso8601String(),
      };

  // True when the next video's 24h window has elapsed AND the quiz gate is handled in the app layer.
  bool get isNextVideoEligible =>
      DateTime.now().difference(lastUnlockedAt).inHours >= 24;
}
