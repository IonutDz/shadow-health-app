import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/download/download_page.dart';
import '../../features/workout/workout_page.dart';
import '../../features/workout/workout_live_page.dart';
import '../../features/nutrition/nutrition_page.dart';
import '../../features/health/health_page.dart';
import '../../features/body/body_page.dart';
import '../../features/settings/settings_page.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../utils/platform_utils.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final path = state.uri.toString();
      final isAuthRoute =
          path.startsWith('/login') || path.startsWith('/register');
      final isDownload = path.startsWith('/download');

      // If on web + Android, redirect to /download page
      // (unless user explicitly navigated away from it)
      if (kIsWeb && isWebOnAndroid && !isDownload) {
        // Only redirect once — if they're going to auth or are authenticated,
        // we still show the banner (AndroidAppBanner) but don't force-redirect.
        // Force redirect only on initial '/' or '/dashboard' while unauthenticated.
        if (!isAuth && !isAuthRoute && (path == '/' || path == '/dashboard')) {
          return '/download';
        }
      }

      // Normal auth guard
      if (!isDownload) {
        if (!isAuth && !isAuthRoute) return '/login';
        if (isAuth && isAuthRoute) return '/dashboard';
      }

      return null;
    },
    routes: [
      // Download / APK page (always accessible)
      GoRoute(
          path: '/download',
          builder: (ctx, state) => const DownloadPage()),

      // Auth routes (no scaffold)
      GoRoute(path: '/login', builder: (ctx, state) => const LoginPage()),
      GoRoute(
          path: '/register',
          builder: (ctx, state) => const RegisterPage()),

      // Main app routes (with bottom nav scaffold)
      ShellRoute(
        builder: (ctx, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
              path: '/dashboard',
              builder: (ctx, state) => const DashboardPage()),
          GoRoute(
              path: '/workout',
              builder: (ctx, state) => const WorkoutPage()),
          GoRoute(
              path: '/workout/live',
              builder: (ctx, state) {
                final routineId =
                    state.uri.queryParameters['routineId'];
                final date = state.uri.queryParameters['date'];
                final workoutId =
                    state.uri.queryParameters['workoutId'];
                return WorkoutLivePage(
                  routineId: routineId,
                  date: date,
                  workoutId: workoutId,
                );
              }),
          GoRoute(
              path: '/nutrition',
              builder: (ctx, state) => const NutritionPage()),
          GoRoute(
              path: '/body',
              builder: (ctx, state) => const BodyPage()),
          GoRoute(
              path: '/health',
              builder: (ctx, state) => const HealthPage()),
          GoRoute(
              path: '/settings',
              builder: (ctx, state) => const SettingsPage()),
        ],
      ),
    ],
  );
});
