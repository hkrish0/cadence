import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enrollment.dart';
import '../services/enrollment_service.dart';
import 'auth_provider.dart';

final enrollmentServiceProvider =
    Provider<EnrollmentService>((ref) => EnrollmentService());

// All enrollments for the current user.
final userEnrollmentsProvider = FutureProvider<List<Enrollment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(enrollmentServiceProvider).fetchUserEnrollments(user.id);
});

// Single enrollment for a specific track, keyed by trackId.
final enrollmentProvider =
    FutureProvider.family<Enrollment?, String>((ref, trackId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(enrollmentServiceProvider).fetchEnrollment(
        userId: user.id,
        trackId: trackId,
      );
});
