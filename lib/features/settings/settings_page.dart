import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final userName = auth.user?['name'] as String? ?? 'Usuario';
    final userEmail = auth.user?['email'] as String? ?? '';
    final avatarLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text('Configuración', style: TextStyle(color: AppTheme.foreground, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              const Text('Configura tu experiencia', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13)),
              const SizedBox(height: 20),

              // Profile card
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.08), AppTheme.primary.withOpacity(0.03)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          avatarLetter,
                          style: const TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, style: const TextStyle(color: AppTheme.foreground, fontSize: 16, fontWeight: FontWeight.w600)),
                          if (userEmail.isNotEmpty)
                            Text(userEmail, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                      ),
                      child: const Text('Pro', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Modules section
              const _SectionHeader(label: 'Módulos', icon: Icons.grid_view_outlined),
              const SizedBox(height: 8),
              _ModulesCard(),
              const SizedBox(height: 20),

              // Preferences section
              const _SectionHeader(label: 'Preferencias', icon: Icons.tune_outlined),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _SettingsRow(icon: Icons.dark_mode_outlined, label: 'Tema oscuro', trailing: const Icon(Icons.check, color: AppTheme.primary, size: 18)),
                    const Divider(height: 1, color: AppTheme.border),
                    _SettingsRow(icon: Icons.language_outlined, label: 'Idioma', trailing: const Text('Español', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13))),
                    const Divider(height: 1, color: AppTheme.border),
                    _SettingsRow(icon: Icons.notifications_outlined, label: 'Notificaciones', trailing: const Icon(Icons.chevron_right, color: AppTheme.mutedForeground, size: 18)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Data section
              const _SectionHeader(label: 'Datos', icon: Icons.storage_outlined),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _SettingsRow(icon: Icons.download_outlined, label: 'Exportar datos', onTap: () {}, trailing: const Icon(Icons.chevron_right, color: AppTheme.mutedForeground, size: 18)),
                    const Divider(height: 1, color: AppTheme.border),
                    _SettingsRow(icon: Icons.upload_outlined, label: 'Importar datos', onTap: () {}, trailing: const Icon(Icons.chevron_right, color: AppTheme.mutedForeground, size: 18)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // App info section
              const _SectionHeader(label: 'Aplicación', icon: Icons.info_outline),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _SettingsRow(icon: Icons.system_update_outlined, label: 'Versión', trailing: const Text('1.0.0', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13))),
                    const Divider(height: 1, color: AppTheme.border),
                    _SettingsRow(icon: Icons.android_outlined, label: 'Descargar APK', onTap: () => context.go('/download'), trailing: const Icon(Icons.chevron_right, color: AppTheme.mutedForeground, size: 18)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Logout button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Cerrar Sesión', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.destructive,
                    side: BorderSide(color: AppTheme.destructive.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 15),
        const SizedBox(width: 6),
        Text(label.toUpperCase(), style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({required this.icon, required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.mutedForeground, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(color: AppTheme.foreground, fontSize: 14))),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ── Modules Card ──────────────────────────────────────────────────────────────
class _ModulesCard extends StatefulWidget {
  @override
  State<_ModulesCard> createState() => _ModulesCardState();
}

class _ModulesCardState extends State<_ModulesCard> {
  final Map<String, bool> _modules = {
    'exercise': true,
    'nutrition': true,
    'hydration': true,
    'supplements': true,
    'body_review': true,
    'health': true,
    'cardio': true,
    'heart_rate': true,
    'sleep': true,
  };

  final Map<String, String> _labels = {
    'exercise': 'Ejercicio',
    'nutrition': 'Nutrición',
    'hydration': 'Hidratación',
    'supplements': 'Suplementos',
    'body_review': 'Revisión corporal',
    'health': 'Salud',
    'cardio': 'Cardio',
    'heart_rate': 'Frecuencia cardíaca',
    'sleep': 'Sueño',
  };

  final Map<String, IconData> _icons = {
    'exercise': Icons.fitness_center_outlined,
    'nutrition': Icons.restaurant_outlined,
    'hydration': Icons.water_drop_outlined,
    'supplements': Icons.medication_outlined,
    'body_review': Icons.accessibility_new_outlined,
    'health': Icons.monitor_heart_outlined,
    'cardio': Icons.directions_walk_outlined,
    'heart_rate': Icons.favorite_border,
    'sleep': Icons.bedtime_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: _modules.entries.toList().asMap().entries.map((entry) {
          final i = entry.key;
          final module = entry.value;
          final isLast = i == _modules.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(_icons[module.key] ?? Icons.circle, color: module.value ? AppTheme.primary : AppTheme.mutedForeground, size: 18),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_labels[module.key] ?? module.key, style: const TextStyle(color: AppTheme.foreground, fontSize: 14))),
                    Switch(
                      value: module.value,
                      onChanged: (v) => setState(() => _modules[module.key] = v),
                      activeColor: AppTheme.primary,
                      inactiveThumbColor: AppTheme.mutedForeground,
                      trackColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected) ? AppTheme.primary.withOpacity(0.3) : AppTheme.border,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, color: AppTheme.border),
            ],
          );
        }).toList(),
      ),
    );
  }
}
