import 'package:flutter/material.dart';

class VideoPlayerScreen extends StatelessWidget {
  final String trackId;
  final String videoId;

  const VideoPlayerScreen({
    super.key,
    required this.trackId,
    required this.videoId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Video Player ($videoId) — TODO')),
    );
  }
}
