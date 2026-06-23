import '../models/track.dart';
import '../models/video.dart';
import 'supabase_service.dart';

class TrackService {
  Future<List<Track>> fetchAllTracks() async {
    final data = await supabase
        .from('tracks')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => Track.fromJson(e)).toList();
  }

  Future<Track> fetchTrack(String trackId) async {
    final data =
        await supabase.from('tracks').select().eq('id', trackId).single();
    return Track.fromJson(data);
  }

  Future<List<Video>> fetchVideosForTrack(String trackId) async {
    final data = await supabase
        .from('videos')
        .select()
        .eq('track_id', trackId)
        .order('order_index', ascending: true);
    return (data as List).map((e) => Video.fromJson(e)).toList();
  }

  Future<Video> fetchVideo(String videoId) async {
    final data =
        await supabase.from('videos').select().eq('id', videoId).single();
    return Video.fromJson(data);
  }
}
