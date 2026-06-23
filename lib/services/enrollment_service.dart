import '../models/enrollment.dart';
import 'supabase_service.dart';

class EnrollmentService {
  Future<Enrollment?> fetchEnrollment({
    required String userId,
    required String trackId,
  }) async {
    final data = await supabase
        .from('enrollments')
        .select()
        .eq('user_id', userId)
        .eq('track_id', trackId)
        .maybeSingle();
    return data == null ? null : Enrollment.fromJson(data);
  }

  Future<List<Enrollment>> fetchUserEnrollments(String userId) async {
    final data = await supabase
        .from('enrollments')
        .select()
        .eq('user_id', userId)
        .order('enrolled_at', ascending: false);
    return (data as List).map((e) => Enrollment.fromJson(e)).toList();
  }

  Future<Enrollment> enroll({
    required String userId,
    required String trackId,
  }) async {
    final data = await supabase
        .from('enrollments')
        .insert({'user_id': userId, 'track_id': trackId})
        .select()
        .single();
    return Enrollment.fromJson(data);
  }

  // Called after the user passes the quiz for video at [completedIndex].
  // Advances current_unlock_index and resets the 24h timer.
  Future<Enrollment> advanceUnlock({
    required String enrollmentId,
    required int nextUnlockIndex,
  }) async {
    final data = await supabase
        .from('enrollments')
        .update({
          'current_unlock_index': nextUnlockIndex,
          'last_unlocked_at': DateTime.now().toIso8601String(),
        })
        .eq('id', enrollmentId)
        .select()
        .single();
    return Enrollment.fromJson(data);
  }
}
