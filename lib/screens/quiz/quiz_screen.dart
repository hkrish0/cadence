import 'package:flutter/material.dart';

class QuizScreen extends StatelessWidget {
  final String trackId;
  final String videoId;

  const QuizScreen({
    super.key,
    required this.trackId,
    required this.videoId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Quiz ($videoId) — TODO')),
    );
  }
}
