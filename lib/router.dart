import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/track_directory_screen.dart';
import 'screens/quiz/quiz_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/track/track_detail_screen.dart';
import 'screens/video/video_player_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // While the auth stream is loading, stay on splash.
      if (authState.isLoading) return '/splash';

      final isLoggedIn = authState.valueOrNull?.session != null;
      final isOnAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/splash';

      if (!isLoggedIn && !isOnAuthRoute) return '/login';
      if (isLoggedIn && isOnAuthRoute) return '/tracks';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (ctx, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (ctx, state) => const SignupScreen()),
      GoRoute(
        path: '/tracks',
        builder: (ctx, state) => const TrackDirectoryScreen(),
        routes: [
          GoRoute(
            path: ':trackId',
            builder: (_, state) =>
                TrackDetailScreen(trackId: state.pathParameters['trackId']!),
            routes: [
              GoRoute(
                path: 'videos/:videoId',
                builder: (_, state) => VideoPlayerScreen(
                  trackId: state.pathParameters['trackId']!,
                  videoId: state.pathParameters['videoId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'quiz',
                    builder: (_, state) => QuizScreen(
                      trackId: state.pathParameters['trackId']!,
                      videoId: state.pathParameters['videoId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
