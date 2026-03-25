import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'nutrition_provider.dart';

class NutritionPage extends ConsumerStatefulWidget {
  const NutritionPage({super.key});

  @override
  ConsumerState<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends ConsumerState<NutritionPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() { if (_tabs.indexIsChanging) setState(() => _activeTab = _tabs.index); });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nutrition = ref.watch(nutritionProvider);

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
                    decoration: BoxDecoration(color: AppTheme.pink400.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.restaurant_outlined, color: AppTheme.pink400, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nutrición', style: TextStyle(color: AppTheme.foreground, fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Comidas, agua y suplementos', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
                    ],
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Macro summary strip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _MacroPill(label: 'Kcal', value: '${nutrition.totalCalories.toInt()}', color: AppTheme.primary),
                  const SizedBox(width: 8),
                  _MacroPill(label: 'P', value: '${nutrition.totalProtein.toInt()}g', color: AppTheme.blue400),
                  const SizedBox(width: 8),
                  _MacroPill(label: 'C', value: '${nutrition.totalCarbs.toInt()}g', color: AppTheme.amber400),
                  const SizedBox(width: 8),
                  _MacroPill(label: 'G', value: '${nutrition.totalFat.toInt()}g', color: AppTheme.red400),
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
                        onTap: () { setState(() => _activeTab = i); _tabs.animateTo(i); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeTab == i ? AppTheme.primary : AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _activeTab == i ? AppTheme.primary : AppTheme.border),
                          ),
                          child: Text(
                            ['Comidas', 'Hidratación', 'Suplementos'][i],
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
              child: TabBarView(
                controller: _tabs,
                children: [
                  _MealsTab(nutrition: nutrition),
                  _HydrationTab(nutrition: nutrition),
                  _SupplementsTab(nutrition: nutrition),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Meals Tab ─────────────────────────────────────────────────────────────────
class _MealsTab extends ConsumerWidget {
  final NutritionState nutrition;
  const _MealsTab({required this.nutrition});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const mealTypes = ['desayuno', 'almuerzo', 'snack', 'cena'];
    const mealLabels = {'desayuno': 'Desayuno', 'almuerzo': 'Almuerzo', 'snack': 'Snack', 'cena': 'Cena'};
    const mealIcons = {
      'desayuno': Icons.coffee_outlined,
      'almuerzo': Icons.lunch_dining_outlined,
      'snack': Icons.cookie_outlined,
      'cena': Icons.dinner_dining_outlined,
    };

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        for (final type in mealTypes) ...[
          _MealSection(
            type: type,
            label: mealLabels[type]!,
            icon: mealIcons[type]!,
            meals: nutrition.meals.where((m) => m.type == type).toList(),
            onAddMeal: () => _showAddMealDialog(context, ref, type),
            onRemoveMeal: (id) => ref.read(nutritionProvider.notifier).removeMeal(id),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  void _showAddMealDialog(BuildContext context, WidgetRef ref, String type) {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final protCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final fatCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registrar ${type[0].toUpperCase()}${type.substring(1)}',
                style: const TextStyle(color: AppTheme.foreground, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _FormField(ctrl: nameCtrl, label: 'Nombre', hint: 'ej. Pollo con arroz'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _FormField(ctrl: calCtrl, label: 'Kcal', hint: '0', numeric: true)),
              const SizedBox(width: 8),
              Expanded(child: _FormField(ctrl: protCtrl, label: 'Proteína', hint: '0g', numeric: true)),
              const SizedBox(width: 8),
              Expanded(child: _FormField(ctrl: carbCtrl, label: 'Carbos', hint: '0g', numeric: true)),
              const SizedBox(width: 8),
              Expanded(child: _FormField(ctrl: fatCtrl, label: 'Grasa', hint: '0g', numeric: true)),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  await ref.read(nutritionProvider.notifier).addMeal(
                    name: nameCtrl.text.trim(),
                    type: type,
                    time: _timeNow(),
                    calories: double.tryParse(calCtrl.text),
                    protein: double.tryParse(protCtrl.text),
                    carbs: double.tryParse(carbCtrl.text),
                    fat: double.tryParse(fatCtrl.text),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Registrar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

class _MealSection extends StatelessWidget {
  final String type;
  final String label;
  final IconData icon;
  final List<Meal> meals;
  final VoidCallback onAddMeal;
  final void Function(String) onRemoveMeal;

  const _MealSection({
    required this.type,
    required this.label,
    required this.icon,
    required this.meals,
    required this.onAddMeal,
    required this.onRemoveMeal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: meals.isNotEmpty ? AppTheme.primary.withOpacity(0.2) : AppTheme.border),
      ),
      child: Column(
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.pink400, size: 18),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: AppTheme.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
                if (meals.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${meals.fold(0.0, (s, m) => s + (m.calories ?? 0)).toInt()} kcal',
                      style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: onAddMeal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: AppTheme.primary, size: 14),
                        SizedBox(width: 4),
                        Text('Añadir', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Meals list
          if (meals.isNotEmpty) ...[
            const Divider(height: 1, color: AppTheme.border),
            for (final meal in meals) ...[
              Dismissible(
                key: Key(meal.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  decoration: BoxDecoration(color: AppTheme.destructive.withOpacity(0.15), borderRadius: BorderRadius.circular(0)),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete_outline, color: AppTheme.destructive),
                ),
                onDismissed: (_) => onRemoveMeal(meal.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(meal.name, style: const TextStyle(color: AppTheme.foreground, fontSize: 13, fontWeight: FontWeight.w500)),
                            Text(meal.time, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                          ],
                        ),
                      ),
                      Text(
                        '${meal.calories?.toInt() ?? 0} kcal',
                        style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      _MacroChip(label: 'P', value: '${meal.protein?.toInt() ?? 0}', color: AppTheme.blue400),
                      const SizedBox(width: 4),
                      _MacroChip(label: 'C', value: '${meal.carbs?.toInt() ?? 0}', color: AppTheme.amber400),
                      const SizedBox(width: 4),
                      _MacroChip(label: 'G', value: '${meal.fat?.toInt() ?? 0}', color: AppTheme.red400),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text('$label:$value', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Hydration Tab ─────────────────────────────────────────────────────────────
class _HydrationTab extends ConsumerWidget {
  final NutritionState nutrition;
  const _HydrationTab({required this.nutrition});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = nutrition.waterLiters;
    final goal = nutrition.hydrationGoal;
    final progress = (current / goal).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Big water display
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.blue400.withOpacity(0.15), AppTheme.blue400.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.blue400.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.water_drop_outlined, color: AppTheme.blue400, size: 32),
              const SizedBox(height: 8),
              Text(
                '${current.toStringAsFixed(1)} L',
                style: const TextStyle(color: AppTheme.foreground, fontSize: 36, fontWeight: FontWeight.bold),
              ),
              Text('de ${goal.toStringAsFixed(1)} L objetivo', style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 14)),
              const SizedBox(height: 16),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppTheme.border,
                  color: AppTheme.blue400,
                ),
              ),
              const SizedBox(height: 6),
              Text('${(progress * 100).toInt()}% completado', style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _WaterBtn(label: '+250ml', amount: 250),
                  const SizedBox(width: 8),
                  _WaterBtn(label: '+500ml', amount: 500),
                  const SizedBox(width: 8),
                  _WaterBtn(label: '+1L', amount: 1000),
                ],
              ),
              if (nutrition.hydrationEntries.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => ref.read(nutritionProvider.notifier).removeLastWater(),
                  icon: const Icon(Icons.undo, size: 14),
                  label: const Text('Deshacer último', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.mutedForeground),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // History
        if (nutrition.hydrationEntries.isNotEmpty) ...[
          const Text('Registros de hoy', style: TextStyle(color: AppTheme.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final entry in nutrition.hydrationEntries.reversed.take(10))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.water_drop_outlined, color: AppTheme.blue400, size: 16),
                    const SizedBox(width: 8),
                    Text('${entry.amount} ml', style: const TextStyle(color: AppTheme.foreground, fontSize: 13)),
                    const Spacer(),
                    Text(entry.time, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _WaterBtn extends ConsumerWidget {
  final String label;
  final int amount;
  const _WaterBtn({required this.label, required this.amount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => ref.read(nutritionProvider.notifier).addWater(amount: amount),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.blue400.withOpacity(0.15),
        foregroundColor: AppTheme.blue400,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Supplements Tab ───────────────────────────────────────────────────────────
class _SupplementsTab extends ConsumerWidget {
  final NutritionState nutrition;
  const _SupplementsTab({required this.nutrition});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final sup in nutrition.supplements) ...[
          _SupplementCard(
            supplement: sup,
            log: nutrition.supplementLogs.where((l) => l.supplementId == sup.id).firstOrNull,
            onToggle: () => ref.read(nutritionProvider.notifier).toggleSupplement(sup.id),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _showAddSupplementDialog(context, ref),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Añadir Suplemento', style: TextStyle(fontWeight: FontWeight.w500)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primary,
            side: BorderSide(color: AppTheme.primary.withOpacity(0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  void _showAddSupplementDialog(BuildContext context, WidgetRef ref) {
    String? selectedPreset;
    String schedule = 'anytime';
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();

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
              const Text('Añadir Suplemento', style: TextStyle(color: AppTheme.foreground, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Presets
              const Text('Atajos', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: supplementPresets.take(8).map((preset) => GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPreset = preset['name'] as String;
                        nameCtrl.text = preset['name'] as String;
                        dosageCtrl.text = preset['dosage'] as String;
                        schedule = preset['schedule'] as String;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: selectedPreset == preset['name']
                            ? AppTheme.primary.withOpacity(0.15)
                            : AppTheme.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedPreset == preset['name']
                              ? AppTheme.primary
                              : AppTheme.border,
                        ),
                      ),
                      child: Text(
                        preset['name'] as String,
                        style: TextStyle(
                          color: selectedPreset == preset['name'] ? AppTheme.primary : AppTheme.mutedForeground,
                          fontSize: 11, fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 12),

              _FormField(ctrl: nameCtrl, label: 'Nombre', hint: 'Whey Protein'),
              const SizedBox(height: 8),
              _FormField(ctrl: dosageCtrl, label: 'Dosis', hint: '30g'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty || dosageCtrl.text.trim().isEmpty) return;
                    await ref.read(nutritionProvider.notifier).addSupplement(
                      name: nameCtrl.text.trim(),
                      dosage: dosageCtrl.text.trim(),
                      schedule: schedule,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
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

class _SupplementCard extends StatelessWidget {
  final Supplement supplement;
  final SupplementLog? log;
  final VoidCallback onToggle;

  const _SupplementCard({required this.supplement, required this.log, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final taken = log?.taken ?? false;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        decoration: BoxDecoration(
          color: taken ? AppTheme.primary.withOpacity(0.08) : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: taken ? AppTheme.primary.withOpacity(0.3) : AppTheme.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: taken ? AppTheme.primary : Colors.transparent,
                border: Border.all(color: taken ? AppTheme.primary : AppTheme.border),
              ),
              child: taken ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.medication_outlined, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(supplement.name, style: TextStyle(
                    color: taken ? AppTheme.mutedForeground : AppTheme.foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: taken ? TextDecoration.lineThrough : null,
                  )),
                  Text(
                    '${supplement.dosage} · ${supplementScheduleLabels[supplement.schedule] ?? supplement.schedule}',
                    style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (taken && log?.takenAt != null)
              Text(log!.takenAt!, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Shared form field ──────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final bool numeric;

  const _FormField({required this.ctrl, required this.label, required this.hint, this.numeric = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          style: const TextStyle(color: AppTheme.foreground, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.mutedForeground),
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
