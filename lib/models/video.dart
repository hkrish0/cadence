class Video {
  final String id;
  final String trackId;
  final int orderIndex;
  final String title;
  final String videoUrl;
  final String quizQuestion;
  final List<String> quizOptions;
  final int correctOptionIndex;

  const Video({
    required this.id,
    required this.trackId,
    required this.orderIndex,
    required this.title,
    required this.videoUrl,
    required this.quizQuestion,
    required this.quizOptions,
    required this.correctOptionIndex,
  });

  factory Video.fromJson(Map<String, dynamic> json) => Video(
        id: json['id'] as String,
        trackId: json['track_id'] as String,
        orderIndex: json['order_index'] as int,
        title: json['title'] as String,
        videoUrl: json['video_url'] as String,
        quizQuestion: json['quiz_question'] as String,
        quizOptions: List<String>.from(json['quiz_options'] as List),
        correctOptionIndex: json['correct_option_index'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'track_id': trackId,
        'order_index': orderIndex,
        'title': title,
        'video_url': videoUrl,
        'quiz_question': quizQuestion,
        'quiz_options': quizOptions,
        'correct_option_index': correctOptionIndex,
      };
}
