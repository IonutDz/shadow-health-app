import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/nutrition.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';

final mealsProvider = FutureProvider.family.autoDispose<List<Meal>, String>((ref, date) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get(ApiEndpoints.meals, params: {'date': date});
  return (response.data as List).map((e) => Meal.fromJson(e as Map<String, dynamic>)).toList();
});

final hydrationProvider = FutureProvider.family.autoDispose<List<HydrationEntry>, String>((ref, date) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get(ApiEndpoints.hydration, params: {'date': date});
  return (response.data as List).map((e) => HydrationEntry.fromJson(e as Map<String, dynamic>)).toList();
});

final supplementsProvider = FutureProvider.autoDispose<List<Supplement>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get(ApiEndpoints.supplements);
  return (response.data as List).map((e) => Supplement.fromJson(e as Map<String, dynamic>)).toList();
});

class NutritionPage extends ConsumerStatefulWidget {
  const NutritionPage({super.key});

  @override
  ConsumerState<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends ConsumerState<NutritionPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final String _today = DateTime.now().toIso8601String().substring(0, 10);

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
        title: const Text('Nutrición'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Comidas'),
            Tab(text: 'Hidratación'),
            Tab(text: 'Suplementos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MealsTab(date: _today),
          _HydrationTab(date: _today),
          _SupplementsTab(),
        ],
      ),
    );
  }
}

class _MealsTab extends ConsumerWidget {
  final String date;
  const _MealsTab({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(mealsProvider(date));

    return mealsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (meals) {
        final totalCal = meals.fold(0, (sum, m) => sum + (m.calories ?? 0));
        final totalProt = meals.fold(0.0, (sum, m) => sum + (m.protein ?? 0));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MacroChip(label: 'Calorías', value: '$totalCal kcal', color: AppTheme.warning),
                  _MacroChip(label: 'Proteína', value: '${totalProt.toStringAsFixed(0)}g', color: AppTheme.primary),
                ],
              ),
            ),
            Expanded(
              child: meals.isEmpty
                  ? const Center(child: Text('Sin comidas registradas'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: meals.length,
                      itemBuilder: (ctx, i) {
                        final m = meals[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.restaurant),
                            title: Text(m.name),
                            subtitle: Text(m.time),
                            trailing: m.calories != null ? Text('${m.calories} kcal') : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _HydrationTab extends ConsumerWidget {
  final String date;
  const _HydrationTab({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hydrationAsync = ref.watch(hydrationProvider(date));

    return hydrationAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (entries) {
        final totalMl = entries.fold(0, (sum, h) => sum + h.amount);
        final liters = totalMl / 1000;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('${liters.toStringAsFixed(2)}L',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                  const Text('de agua hoy', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir 250ml'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                    onPressed: () async {
                      final api = ref.read(apiClientProvider);
                      await api.post(ApiEndpoints.hydration, data: {'date': date, 'amount': 250});
                      ref.invalidate(hydrationProvider(date));
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: entries.length,
                itemBuilder: (ctx, i) {
                  final h = entries[i];
                  return ListTile(
                    leading: const Icon(Icons.water_drop, color: AppTheme.secondary),
                    title: Text('${h.amount} ml'),
                    trailing: Text(h.time, style: const TextStyle(color: Colors.grey)),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SupplementsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplementsAsync = ref.watch(supplementsProvider);

    return supplementsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (supplements) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: supplements.length,
        itemBuilder: (ctx, i) {
          final s = supplements[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.medication_outlined,
                color: s.isActive ? AppTheme.success : Colors.grey),
              title: Text(s.name),
              subtitle: s.dosage != null ? Text(s.dosage!) : null,
              trailing: Text(s.schedule ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          );
        },
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );
}
