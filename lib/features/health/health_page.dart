import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'health_provider.dart';

class HealthPage extends ConsumerStatefulWidget {
  const HealthPage({super.key});

  @override
  ConsumerState<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends ConsumerState<HealthPage> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(healthProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppTheme.red400.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.monitor_heart_outlined, color: AppTheme.red400, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Salud', style: TextStyle(color: AppTheme.foreground, fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Cardio, sueño y frecuencia cardíaca', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
                    ],
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Quick stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _QuickStat(label: 'FC actual', value: health.currentHeartRate > 0 ? '${health.currentHeartRate}' : '--', unit: 'bpm', icon: Icons.favorite_border, color: AppTheme.red400),
                  const SizedBox(width: 8),
                  _QuickStat(label: 'Pasos', value: '${health.todaySteps}', unit: '', icon: Icons.directions_walk_outlined, color: AppTheme.amber400),
                  const SizedBox(width: 8),
                  _QuickStat(label: 'Sueño', value: health.sleepHoursFormatted, unit: '', icon: Icons.bedtime_outlined, color: AppTheme.violet400),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (int i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeTab == i ? AppTheme.red400 : AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _activeTab == i ? AppTheme.red400 : AppTheme.border),
                          ),
                          child: Text(
                            ['Cardio', 'Sueño', 'Frecuencia'][i],
                            style: TextStyle(color: _activeTab == i ? Colors.white : AppTheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Tab content
            Expanded(
              child: [
                _CardioTab(health: health),
                _SleepTab(health: health),
                _HeartRateTab(health: health),
              ][_activeTab],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _QuickStat({required this.label, required this.value, required this.unit, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 9, fontWeight: FontWeight.w600)),
                  Text('$value${unit.isNotEmpty ? ' $unit' : ''}', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cardio Tab ────────────────────────────────────────────────────────────────
class _CardioTab extends ConsumerWidget {
  final HealthState health;
  const _CardioTab({required this.health});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Steps progress card
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.amber400.withOpacity(0.12), AppTheme.amber400.withOpacity(0.04)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.amber400.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_walk_outlined, color: AppTheme.amber400, size: 20),
                  SizedBox(width: 8),
                  Text('Pasos de hoy', style: TextStyle(color: AppTheme.foreground, fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Text('${health.todaySteps}', style: const TextStyle(color: AppTheme.foreground, fontSize: 36, fontWeight: FontWeight.bold)),
              Text('de ${health.stepsGoal} objetivo', style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 13)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: health.stepsProgress / 100.0,
                  minHeight: 8,
                  backgroundColor: AppTheme.border,
                  color: AppTheme.amber400,
                ),
              ),
              const SizedBox(height: 4),
              Text('${health.stepsProgress}%', style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Add cardio button
        ElevatedButton.icon(
          onPressed: () => _showAddCardioSheet(context, ref),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Registrar Cardio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.amber400.withOpacity(0.8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 16),

        // Sessions list
        if (health.cardioSessions.isNotEmpty) ...[
          const Text('Sesiones de hoy', style: TextStyle(color: AppTheme.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final session in health.cardioSessions)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.amber400.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(_cardioIcon(session.type), color: AppTheme.amber400, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_cardioLabel(session.type), style: const TextStyle(color: AppTheme.foreground, fontSize: 13, fontWeight: FontWeight.w500)),
                        Text([
                          if (session.steps != null) '${session.steps} pasos',
                          if (session.totalMinutes != null) '${session.totalMinutes} min',
                          if (session.calories != null) '${session.calories} kcal',
                        ].join(' · '), style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(session.time, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                  IconButton(
                    onPressed: () => ref.read(healthProvider.notifier).removeCardioSession(session.id),
                    icon: const Icon(Icons.delete_outline, color: AppTheme.destructive, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  IconData _cardioIcon(String type) {
    switch (type) {
      case 'running': return Icons.directions_run;
      case 'cycling': return Icons.directions_bike_outlined;
      default: return Icons.directions_walk_outlined;
    }
  }

  String _cardioLabel(String type) {
    switch (type) {
      case 'running': return 'Carrera';
      case 'cycling': return 'Ciclismo';
      case 'free': return 'Actividad libre';
      default: return 'Caminata';
    }
  }

  void _showAddCardioSheet(BuildContext context, WidgetRef ref) {
    String type = 'walking';
    final stepsCtrl = TextEditingController();
    final minutesCtrl = TextEditingController();
    final calCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Registrar Cardio', style: TextStyle(color: AppTheme.foreground, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              // Type selector
              Row(children: [
                for (final t in ['walking', 'running', 'cycling', 'free'])
                  Expanded(child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => type = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: type == t ? AppTheme.amber400.withOpacity(0.2) : AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: type == t ? AppTheme.amber400 : AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            Icon(_cardioIcon(t), color: type == t ? AppTheme.amber400 : AppTheme.mutedForeground, size: 18),
                            Text(_cardioLabel(t).substring(0, 3), style: TextStyle(color: type == t ? AppTheme.amber400 : AppTheme.mutedForeground, fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                  )),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _HealthFormField(ctrl: stepsCtrl, label: 'Pasos', hint: '0')),
                const SizedBox(width: 8),
                Expanded(child: _HealthFormField(ctrl: minutesCtrl, label: 'Minutos', hint: '0')),
                const SizedBox(width: 8),
                Expanded(child: _HealthFormField(ctrl: calCtrl, label: 'Calorías', hint: '0')),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(healthProvider.notifier).addCardioSession(
                      type: type,
                      steps: int.tryParse(stepsCtrl.text),
                      totalMinutes: int.tryParse(minutesCtrl.text),
                      calories: int.tryParse(calCtrl.text),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.amber400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Guardar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// ── Sleep Tab ─────────────────────────────────────────────────────────────────
class _SleepTab extends ConsumerWidget {
  final HealthState health;
  const _SleepTab({required this.health});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = health.latestSleep;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Latest sleep card
        if (latest != null)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.violet400.withOpacity(0.12), AppTheme.violet400.withOpacity(0.04)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.violet400.withOpacity(0.2)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bedtime_outlined, color: AppTheme.violet400, size: 20),
                    const SizedBox(width: 8),
                    const Text('Último registro de sueño', style: TextStyle(color: AppTheme.foreground, fontSize: 15, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(latest.date, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(latest.formattedDuration, style: const TextStyle(color: AppTheme.foreground, fontSize: 36, fontWeight: FontWeight.bold)),
                Text('Calidad: ${latest.quality}/10', style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 13)),
                const SizedBox(height: 12),
                // Sleep stages
                Row(
                  children: [
                    _SleepStage(label: 'Profundo', minutes: latest.deepMinutes, total: latest.totalMinutes, color: AppTheme.violet400),
                    const SizedBox(width: 8),
                    _SleepStage(label: 'Ligero', minutes: latest.lightMinutes, total: latest.totalMinutes, color: AppTheme.blue400),
                    const SizedBox(width: 8),
                    _SleepStage(label: 'REM', minutes: latest.remMinutes, total: latest.totalMinutes, color: AppTheme.cyan400),
                  ],
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            padding: const EdgeInsets.all(20),
            child: const Center(child: Text('No hay registros de sueño todavía', style: TextStyle(color: AppTheme.mutedForeground))),
          ),

        const SizedBox(height: 12),

        ElevatedButton.icon(
          onPressed: () => _showAddSleepSheet(context, ref),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Registrar Sueño', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.violet400.withOpacity(0.8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  void _showAddSleepSheet(BuildContext context, WidgetRef ref) {
    final startCtrl = TextEditingController(text: '23:00');
    final endCtrl = TextEditingController(text: '07:00');
    int quality = 7;
    final deepCtrl = TextEditingController(text: '90');
    final lightCtrl = TextEditingController(text: '240');
    final remCtrl = TextEditingController(text: '90');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Registrar Sueño', style: TextStyle(color: AppTheme.foreground, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _HealthFormField(ctrl: startCtrl, label: 'Hora inicio', hint: '23:00')),
                  const SizedBox(width: 8),
                  Expanded(child: _HealthFormField(ctrl: endCtrl, label: 'Hora fin', hint: '07:00')),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _HealthFormField(ctrl: deepCtrl, label: 'Sueño profundo (min)', hint: '90')),
                  const SizedBox(width: 8),
                  Expanded(child: _HealthFormField(ctrl: lightCtrl, label: 'Sueño ligero (min)', hint: '240')),
                  const SizedBox(width: 8),
                  Expanded(child: _HealthFormField(ctrl: remCtrl, label: 'REM (min)', hint: '90')),
                ]),
                const SizedBox(height: 12),
                Text('Calidad: $quality/10', style: const TextStyle(color: AppTheme.foreground, fontSize: 13, fontWeight: FontWeight.w600)),
                Slider(
                  value: quality.toDouble(),
                  min: 1, max: 10, divisions: 9,
                  activeColor: AppTheme.violet400,
                  inactiveColor: AppTheme.border,
                  onChanged: (v) => setState(() => quality = v.round()),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref.read(healthProvider.notifier).addSleepLog(
                        date: DateTime.now().toIso8601String().substring(0, 10),
                        sleepStart: startCtrl.text,
                        sleepEnd: endCtrl.text,
                        deepMinutes: int.tryParse(deepCtrl.text) ?? 90,
                        lightMinutes: int.tryParse(lightCtrl.text) ?? 240,
                        remMinutes: int.tryParse(remCtrl.text) ?? 90,
                        awakeMinutes: 20,
                        quality: quality,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.violet400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Guardar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SleepStage extends StatelessWidget {
  final String label;
  final int minutes;
  final int total;
  final Color color;

  const _SleepStage({required this.label, required this.minutes, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (minutes * 100 ~/ total) : 0;
    final h = minutes ~/ 60;
    final m = minutes % 60;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text('$percent%', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 10)),
            Text(h > 0 ? '${h}h ${m}m' : '${m}m', style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ── Heart Rate Tab ────────────────────────────────────────────────────────────
class _HeartRateTab extends ConsumerWidget {
  final HealthState health;
  const _HeartRateTab({required this.health});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Current heart rate card
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.red400.withOpacity(0.12), AppTheme.red400.withOpacity(0.04)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.red400.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: AppTheme.red400, size: 20),
                  SizedBox(width: 8),
                  Text('Frecuencia Cardíaca', style: TextStyle(color: AppTheme.foreground, fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                health.currentHeartRate > 0 ? '${health.currentHeartRate}' : '--',
                style: const TextStyle(color: AppTheme.foreground, fontSize: 52, fontWeight: FontWeight.bold),
              ),
              const Text('bpm actual', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _HRStat(label: 'Reposo', value: health.restingHeartRate > 0 ? '${health.restingHeartRate}' : '--', color: AppTheme.primary),
                  const SizedBox(width: 12),
                  _HRStat(label: 'Mín', value: health.minHeartRate > 0 ? '${health.minHeartRate}' : '--', color: AppTheme.amber400),
                  const SizedBox(width: 12),
                  _HRStat(label: 'Máx', value: health.maxHeartRate > 0 ? '${health.maxHeartRate}' : '--', color: AppTheme.red400),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _showAddHRSheet(context, ref),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Registrar FC', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.red400.withOpacity(0.8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 16),

        if (health.heartRateEntries.isNotEmpty) ...[
          const Text('Registros de hoy', style: TextStyle(color: AppTheme.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final entry in health.heartRateEntries.reversed.take(10))
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.favorite_border, color: AppTheme.red400, size: 16),
                  const SizedBox(width: 8),
                  Text('${entry.bpm} bpm', style: const TextStyle(color: AppTheme.foreground, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Text(entry.context, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                  const Spacer(),
                  Text(entry.time, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                ],
              ),
            ),
        ],

        // Devices section
        if (health.devices.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Dispositivos', style: TextStyle(color: AppTheme.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final device in health.devices)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(_deviceIcon(device.type), color: AppTheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(device.name, style: const TextStyle(color: AppTheme.foreground, fontSize: 13, fontWeight: FontWeight.w500)),
                        Text(device.type, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: device.isActive ? AppTheme.primary.withOpacity(0.1) : AppTheme.border,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      device.isActive ? 'Activo' : 'Inactivo',
                      style: TextStyle(color: device.isActive ? AppTheme.primary : AppTheme.mutedForeground, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  // Duplicate unused methods removed
  IconData _deviceIcon(String type) {
    switch (type) {
      case 'smartwatch': return Icons.watch_outlined;
      case 'phone': return Icons.smartphone_outlined;
      case 'chest_strap': return Icons.radio_outlined;
      default: return Icons.watch_outlined;
    }
  }

  void _showAddHRSheet(BuildContext context, WidgetRef ref) {
    final bpmCtrl = TextEditingController();
    String context2 = 'general';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Registrar FC', style: TextStyle(color: AppTheme.foreground, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _HealthFormField(ctrl: bpmCtrl, label: 'Pulsaciones por minuto', hint: '75'),
              const SizedBox(height: 12),
              const Text('Contexto', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(children: [
                for (final c in ['general', 'rest', 'workout', 'cardio'])
                  Expanded(child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => context2 = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: context2 == c ? AppTheme.red400.withOpacity(0.15) : AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context2 == c ? AppTheme.red400 : AppTheme.border),
                        ),
                        child: Text(
                          {'general': 'General', 'rest': 'Reposo', 'workout': 'Entreno', 'cardio': 'Cardio'}[c]!,
                          style: TextStyle(color: context2 == c ? AppTheme.red400 : AppTheme.mutedForeground, fontSize: 10, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final bpm = int.tryParse(bpmCtrl.text);
                    if (bpm == null || bpm <= 0) return;
                    await ref.read(healthProvider.notifier).addHeartRate(bpm: bpm, context: context2);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.red400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Guardar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HRStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _HRStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 10)),
        ],
      ),
    );
  }
}

class _HealthFormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;

  const _HealthFormField({required this.ctrl, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppTheme.foreground, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.mutedForeground, fontSize: 12),
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.red400)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }
}
