import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';

final dashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);

  final response = await api.post(ApiEndpoints.dailyLogs, data: {'date': today});
  return response.data as Map<String, dynamic>;
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashAsync = ref.watch(dashboardProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hola, ${authState.user?.name.split(' ').first ?? 'Atleta'} 👋',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(_formatDate(DateTime.now()),
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  dashAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (data) => _DashboardContent(data: data),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const months = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month]}';
  }
}

class _DashboardContent extends StatelessWidget {
  final Map<String, dynamic> data;

  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final workouts = data['workoutSessions'] as List? ?? [];
    final meals = data['meals'] as List? ?? [];
    final hydration = data['hydrationLogs'] as List? ?? [];
    final totalMl = hydration.fold<int>(0, (sum, h) => sum + ((h['amount'] as int?) ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Resumen del día'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(icon: Icons.fitness_center, label: 'Entrenos', value: '${workouts.length}', color: AppTheme.primary)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(icon: Icons.restaurant, label: 'Comidas', value: '${meals.length}', color: AppTheme.success)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(icon: Icons.water_drop, label: 'Agua', value: '${(totalMl / 1000).toStringAsFixed(1)}L', color: AppTheme.secondary)),
          ],
        ),
        const SizedBox(height: 24),
        _SectionTitle('Acciones rápidas'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QuickAction(icon: Icons.play_circle_outline, label: 'Iniciar entreno', color: AppTheme.primary, route: '/workout'),
            _QuickAction(icon: Icons.add_circle_outline, label: 'Añadir comida', color: AppTheme.success, route: '/nutrition'),
            _QuickAction(icon: Icons.water, label: 'Registrar agua', color: AppTheme.secondary, route: '/nutrition'),
            _QuickAction(icon: Icons.monitor_heart_outlined, label: 'Salud', color: AppTheme.warning, route: '/health'),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.route});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push(route),
    child: Container(
      width: (MediaQuery.of(context).size.width - 56) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
        ],
      ),
    ),
  );
}
