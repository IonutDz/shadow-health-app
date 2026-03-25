import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';

const _apkUrl = 'https://github.com/IonutDz/shadow-health-app/releases/download/v1.0.0/app-release.apk';

class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // App icon + logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary.withOpacity(0.15), AppTheme.primary.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: const Icon(Icons.show_chart, color: AppTheme.primary, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Shadow Health',
                style: TextStyle(color: AppTheme.foreground, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tu compañero modular de fitness',
                style: TextStyle(color: AppTheme.mutedForeground, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // QR code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _apkUrl,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escanea para descargar el APK',
                style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12),
              ),
              const SizedBox(height: 24),

              // Download button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl(context, _apkUrl),
                  icon: const Icon(Icons.android, size: 20),
                  label: const Text('Descargar APK Android', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Copy URL button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: _apkUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('URL copiada al portapapeles')),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: const Text('Copiar URL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.foreground,
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Features
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('¿Qué incluye?', style: TextStyle(color: AppTheme.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    for (final item in [
                      [Icons.fitness_center_outlined, 'Plannings y rutinas de entrenamiento'],
                      [Icons.restaurant_outlined, 'Nutrición, macros e hidratación'],
                      [Icons.accessibility_new_outlined, 'Revisión corporal mensual'],
                      [Icons.monitor_heart_outlined, 'Cardio, sueño y frecuencia cardíaca'],
                      [Icons.settings_outlined, 'Módulos activables y personalizables'],
                    ]) ...[
                      Row(
                        children: [
                          Icon(item[0] as IconData, color: AppTheme.primary, size: 16),
                          const SizedBox(width: 10),
                          Text(item[1] as String, style: const TextStyle(color: AppTheme.foreground, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Already have account?
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  '¿Ya tienes cuenta? Iniciar sesión →',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
