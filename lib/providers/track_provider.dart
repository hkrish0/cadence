import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/track.dart';
import '../models/video.dart';
import '../services/track_service.dart';

final trackServiceProvider = Provider<TrackService>((ref) => TrackService());

// All tracks for the directory screen.
final allTracksProvider = FutureProvider<List<Track>>((ref) {
  return ref.watch(trackServiceProvider).fetchAllTracks();
});

// Single track detail, keyed by trackId.
final trackProvider =
    FutureProvider.family<Track, String>((ref, trackId) {
  return ref.watch(trackServiceProvider).fetchTrack(trackId);
});

// Ordered videos for a track, keyed by trackId.
final trackVideosProvider =
    FutureProvider.family<List<Video>, String>((ref, trackId) {
  return ref.watch(trackServiceProvider).fetchVideosForTrack(trackId);
});
