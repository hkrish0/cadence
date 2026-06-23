import 'package:flutter/material.dart';

class TrackDetailScreen extends StatelessWidget {
  final String trackId;

  const TrackDetailScreen({super.key, required this.trackId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Track Detail ($trackId) — TODO')),
    );
  }
}
