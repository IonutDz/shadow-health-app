import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/api/api_client.dart';
import 'features/auth/auth_provider.dart';
import 'shared/widgets/android_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Spanish locale for date formatting
  await initializeDateFormatting('es', null);

  // Initialize API client (sets base URL to Render)
  ApiClient().init();

  runApp(const ProviderScope(child: ShadowHealthApp()));
}

class ShadowHealthApp extends ConsumerWidget {
  const ShadowHealthApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check existing auth token on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuth();
    });

    final router = ref.watch(routerProvider);

    return AndroidAppBanner(
      child: MaterialApp.router(
        title: 'Shadow Health',
        theme: AppTheme.dark,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        // Ensure proper locale
        locale: const Locale('es', 'ES'),
        supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
        builder: (context, child) {
          // Override font scale to avoid accessibility size breaking layout
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.of(context).textScaler.clamp(
                minScaleFactor: 0.8,
                maxScaleFactor: 1.2,
              ),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
