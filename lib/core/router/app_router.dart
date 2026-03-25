import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/workout/workout_page.dart';
import '../../features/nutrition/nutrition_page.dart';
import '../../features/health/health_page.dart';
import '../../features/settings/settings_page.dart';
import '../../shared/widgets/app_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isAuthRoute = state.uri.toString().startsWith('/login') ||
          state.uri.toString().startsWith('/register');

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (ctx, state) => const LoginPage()),
      GoRoute(path: '/register', builder: (ctx, state) => const RegisterPage()),
      ShellRoute(
        builder: (ctx, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (ctx, state) => const DashboardPage()),
          GoRoute(path: '/workout', builder: (ctx, state) => const WorkoutPage()),
          GoRoute(path: '/nutrition', builder: (ctx, state) => const NutritionPage()),
          GoRoute(path: '/health', builder: (ctx, state) => const HealthPage()),
        ],
      ),
      GoRoute(path: '/settings', builder: (ctx, state) => const SettingsPage()),
    ],
  );
});
