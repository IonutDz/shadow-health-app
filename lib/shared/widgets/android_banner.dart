import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/platform_utils.dart';

/// Shows a sticky top banner on web-Android, prompting the user to
/// download the native APK. Dismissible for the session.
class AndroidAppBanner extends StatefulWidget {
  final Widget child;
  const AndroidAppBanner({super.key, required this.child});

  @override
  State<AndroidAppBanner> createState() => _AndroidAppBannerState();
}

class _AndroidAppBannerState extends State<AndroidAppBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    // Only show on Flutter Web running on Android
    if (!kIsWeb || !isWebOnAndroid || _dismissed) {
      return widget.child;
    }

    return Column(
      children: [
        // The sticky banner
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary.withOpacity(0.9),
                AppTheme.primary,
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.android, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Descarga la app nativa!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Mejor rendimiento y acceso offline',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.go('/download'),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Descargar',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => _dismissed = true),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, color: Colors.white70, size: 18),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
