import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/health.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';

final sleepLogsProvider = FutureProvider.autoDispose<List<SleepLog>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get(ApiEndpoints.sleep, params: {'limit': '14'});
  return (response.data as List).map((e) => SleepLog.fromJson(e as Map<String, dynamic>)).toList();
});

final cardioLogsProvider = FutureProvider.autoDispose<List<CardioSession>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final response = await api.get(ApiEndpoints.cardio, params: {'date': today});
  return (response.data as List).map((e) => CardioSession.fromJson(e as Map<String, dynamic>)).toList();
});

final bodyChecksProvider = FutureProvider.autoDispose<List<BodyCheck>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get(ApiEndpoints.bodyChecks, params: {'limit': '10'});
  return (response.data as List).map((e) => BodyCheck.fromJson(e as Map<String, dynamic>)).toList();
});

class HealthPage extends ConsumerStatefulWidget {
  const HealthPage({super.key});

  @override
  ConsumerState<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends ConsumerState<HealthPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salud'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sueño'),
            Tab(text: 'Cardio'),
            Tab(text: 'Cuerpo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SleepTab(),
          _CardioTab(),
          _BodyTab(),
        ],
      ),
    );
  }
}

class _SleepTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepAsync = ref.watch(sleepLogsProvider);

    return sleepAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (logs) => logs.isEmpty
          ? const Center(child: Text('Sin registros de sueño'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (ctx, i) {
                final s = logs[i];
                final hours = s.totalMinutes ~/ 60;
                final mins = s.totalMinutes % 60;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(s.date, style: const TextStyle(color: Colors.grey)),
                            Text('${hours}h ${mins}m',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _SleepPhase('Profundo', s.deepMinutes, Colors.indigo),
                            const SizedBox(width: 16),
                            _SleepPhase('Ligero', s.lightMinutes, Colors.blue),
                            const SizedBox(width: 16),
                            _SleepPhase('REM', s.remMinutes, Colors.purple),
                          ],
                        ),
                        if (s.quality > 0) ...[
                          const SizedBox(height: 8),
                          Text('Calidad: ${s.quality}/10', style: const TextStyle(color: Colors.grey)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _SleepPhase extends StatelessWidget {
  final String label;
  final int minutes;
  final Color color;

  const _SleepPhase(this.label, this.minutes, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('${minutes}m', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ],
  );
}

class _CardioTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardioAsync = ref.watch(cardioLogsProvider);

    return cardioAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (sessions) => sessions.isEmpty
          ? const Center(child: Text('Sin actividad cardio hoy'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (ctx, i) {
                final s = sessions[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.directions_run, color: AppTheme.success),
                    title: Text(s.type),
                    subtitle: Text(s.time),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (s.steps != null) Text('${s.steps} pasos', style: const TextStyle(fontSize: 12)),
                        if (s.totalMinutes != null) Text('${s.totalMinutes} min', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _BodyTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bodyAsync = ref.watch(bodyChecksProvider);

    return bodyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (checks) => checks.isEmpty
          ? const Center(child: Text('Sin registros de cuerpo'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: checks.length,
              itemBuilder: (ctx, i) {
                final bc = checks[i];
                final dateStr = bc.date is String ? (bc.date as String).substring(0, 10) : bc.date.toString();
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (bc.weight != null) ...[
                              Text('${bc.weight} kg',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 16),
                            ],
                            if (bc.bodyFat != null)
                              Text('${bc.bodyFat}% grasa', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
