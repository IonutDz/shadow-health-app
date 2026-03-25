import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ShadowHealthApp()));
}

class ShadowHealthApp extends ConsumerWidget {
  const ShadowHealthApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check auth on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuth();
    });

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ShadowHealth',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
