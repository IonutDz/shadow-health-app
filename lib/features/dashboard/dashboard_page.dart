import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import '../workout/workout_provider.dart';
import '../nutrition/nutrition_provider.dart';
import '../health/health_provider.dart';
import '../body/body_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workoutProvider.notifier).fetchHistory();
    });
  }

  String get _selectedDateIso {
    return DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  String get _selectedDateLabel {
    return DateFormat('EEEE, d MMMM', 'es').format(_selectedDate);
  }

  void _shiftDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final workout = ref.watch(workoutProvider);
    final nutrition = ref.watch(nutritionProvider);
    final health = ref.watch(healthProvider);
    final body = ref.watch(bodyProvider);

    final userName = auth.user?['name'] as String? ?? '';
    final welcomeTitle = userName.isNotEmpty ? 'Bienvenido, $userName!' : '¡Bienvenido!';
    final now = DateTime.now();
    final dateLabel = DateFormat('EEEE, d MMMM', 'es').format(now);

    final activePlanning = workout.activePlanning;
    final selectedRoutine = workout.routineForDate(_selectedDate);
    final hasRoutines = (activePlanning?.routines.length ?? 0) > 0;

    // Check if selected date has a completed workout
    final selectedDateStr = _selectedDateIso;
    final selectedSession = workout.history
        .where((w) => w.finishedAt != null && DateFormat('yyyy-MM-dd').format(w.startedAt) == selectedDateStr)
        .firstOrNull;

    final hasAnyData = hasRoutines ||
        nutrition.meals.isNotEmpty ||
        health.cardioSessions.isNotEmpty ||
        body.latestCheck != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Text(
                dateLabel,
                style: const TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                welcomeTitle,
                style: const TextStyle(
                  color: AppTheme.foreground,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),

              // Quick nav grid (4 modules)
              _QuickNavGrid(),
              const SizedBox(height: 20),

              // Welcome card for new users
              if (!workout.initialized || !hasAnyData) ...[
                _WelcomeCard(welcomeTitle: welcomeTitle),
                const SizedBox(height: 20),
              ],

              // Hero workout card
              _WorkoutCard(
                workout: workout,
                selectedDate: _selectedDate,
                selectedDateLabel: _selectedDateLabel,
                selectedRoutine: selectedRoutine,
                selectedSession: selectedSession,
                hasRoutines: hasRoutines,
                onShiftDate: _shiftDate,
                onSelectDate: (d) => setState(() => _selectedDate = d),
              ),
              const SizedBox(height: 16),

              // Daily stats grid
              _DailyStatsGrid(nutrition: nutrition, health: health),
              const SizedBox(height: 16),

              // Daily tasks
              _DailyTasksList(nutrition: nutrition),
              const SizedBox(height: 16),

              // Recent activity
              _RecentActivity(nutrition: nutrition, health: health, body: body),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Nav Grid ────────────────────────────────────────────────────────────
class _QuickNavGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _QNItem('/workout', 'Ejercicios', Icons.fitness_center, AppTheme.primary),
      _QNItem('/nutrition', 'Nutrición', Icons.restaurant_outlined, AppTheme.pink400),
      _QNItem('/body', 'Cuerpo', Icons.accessibility_new_outlined, AppTheme.blue400),
      _QNItem('/health', 'Salud', Icons.monitor_heart_outlined, AppTheme.red400),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.85,
      children: items.map((item) => _QNTile(item: item)).toList(),
    );
  }
}

class _QNItem {
  final String path;
  final String label;
  final IconData icon;
  final Color color;
  const _QNItem(this.path, this.label, this.icon, this.color);
}

class _QNTile extends StatelessWidget {
  final _QNItem item;
  const _QNTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(item.path),
      child: Container(
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: item.color.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              style: TextStyle(
                color: AppTheme.foreground,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Welcome Card ──────────────────────────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final String welcomeTitle;
  const _WelcomeCard({required this.welcomeTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.1),
            AppTheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(welcomeTitle, style: const TextStyle(color: AppTheme.foreground, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                  'Tu cuenta está lista. Configura tu primer gimnasio y rutina para empezar a entrenar.',
                  style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/workout'),
                          icon: const Icon(Icons.calendar_today, size: 15),
                          label: const Text('Plan de Ejercicios', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/nutrition'),
                          icon: const Icon(Icons.restaurant_outlined, size: 15),
                          label: const Text('Nutrición', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.foreground,
                            side: const BorderSide(color: AppTheme.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Workout Card ──────────────────────────────────────────────────────────────
class _WorkoutCard extends StatelessWidget {
  final WorkoutState workout;
  final DateTime selectedDate;
  final String selectedDateLabel;
  final Routine? selectedRoutine;
  final WorkoutHistoryItem? selectedSession;
  final bool hasRoutines;
  final void Function(int) onShiftDate;
  final void Function(DateTime) onSelectDate;

  const _WorkoutCard({
    required this.workout,
    required this.selectedDate,
    required this.selectedDateLabel,
    required this.selectedRoutine,
    required this.selectedSession,
    required this.hasRoutines,
    required this.onShiftDate,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final planName = workout.initialized
        ? (workout.activePlanning?.name ?? 'Sin plan activo')
        : 'Cargando planning...';
    final todayName = workout.initialized
        ? (workout.todayRoutine?.name ?? 'Día de descanso')
        : 'Preparando tu semana...';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.background,
            AppTheme.primary.withOpacity(0.05),
            AppTheme.primary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(planName, style: const TextStyle(color: AppTheme.foreground, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
                    const SizedBox(height: 2),
                    Text(todayName, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.fitness_center, color: AppTheme.primary, size: 20),
              ),
            ],
          ),

          if (!workout.initialized) ...[
            const SizedBox(height: 16),
            const _LoadingWeek(),
          ] else if (hasRoutines) ...[
            const SizedBox(height: 16),
            // Week progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Semana Actual', style: TextStyle(color: AppTheme.foreground, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(
                  '${workout.weekProgress()}/${workout.weekTotal}',
                  style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 7-day week grid
            _WeekGrid(
              workout: workout,
              selectedDate: selectedDate,
              onSelectDate: onSelectDate,
            ),
            const SizedBox(height: 12),
            // Selected day info
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ENTRENO SELECCIONADO',
                            style: TextStyle(color: AppTheme.primary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                        const SizedBox(height: 2),
                        Text(selectedDateLabel.replaceFirst(selectedDateLabel[0], selectedDateLabel[0].toUpperCase()),
                            style: const TextStyle(color: AppTheme.foreground, fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(selectedRoutine?.name ?? 'Día de descanso',
                            style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
                      ],
                    ),
                  ),
                  // Date navigator
                  Row(
                    children: [
                      _NavBtn(icon: Icons.chevron_left, onTap: () => onShiftDate(-1)),
                      const SizedBox(width: 4),
                      _NavBtn(icon: Icons.chevron_right, onTap: () => onShiftDate(1)),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              'Agrega rutinas a tu plan desde Ajustes para ver tu progreso semanal.',
              style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12),
            ),
          ],

          const SizedBox(height: 16),
          _WorkoutCta(
            selectedRoutine: selectedRoutine,
            selectedSession: selectedSession,
            selectedDate: selectedDate,
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary.withOpacity(0.08),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
      );
}

class _LoadingWeek extends StatelessWidget {
  const _LoadingWeek();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        7,
        (i) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekGrid extends StatelessWidget {
  final WorkoutState workout;
  final DateTime selectedDate;
  final void Function(DateTime) onSelectDate;

  const _WeekGrid({required this.workout, required this.selectedDate, required this.onSelectDate});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Start from Monday of the current week
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final monday = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    final dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: List.generate(7, (i) {
          final day = monday.add(Duration(days: i));
          final isToday = day == today;
          final isSelected = day == DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
          final isPast = day.isBefore(today);
          final hasRoutine = workout.routineForDate(day) != null;
          final isCompleted = workout.history.any((w) =>
              w.finishedAt != null &&
              DateFormat('yyyy-MM-dd').format(w.startedAt) == DateFormat('yyyy-MM-dd').format(day));

          return Expanded(
            child: GestureDetector(
              onTap: () => onSelectDate(day),
              child: Opacity(
                opacity: isPast && !isCompleted ? 0.5 : 1.0,
                child: Column(
                  children: [
                    Text(
                      dayLabels[i],
                      style: TextStyle(
                        color: isToday ? AppTheme.primary : AppTheme.mutedForeground,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.day}',
                      style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 9),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.primary
                            : hasRoutine
                                ? AppTheme.primary.withOpacity(0.08)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isToday
                              ? AppTheme.primary
                              : isSelected
                                  ? AppTheme.primary.withOpacity(0.6)
                                  : hasRoutine
                                      ? AppTheme.primary.withOpacity(0.3)
                                      : AppTheme.border,
                          width: isToday ? 1.5 : 1.0,
                        ),
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check
                            : hasRoutine
                                ? Icons.fitness_center
                                : Icons.bedtime_outlined,
                        color: isCompleted
                            ? Colors.white
                            : hasRoutine
                                ? AppTheme.primary
                                : AppTheme.mutedForeground,
                        size: isCompleted ? 16 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _WorkoutCta extends StatelessWidget {
  final Routine? selectedRoutine;
  final WorkoutHistoryItem? selectedSession;
  final DateTime selectedDate;

  const _WorkoutCta({
    required this.selectedRoutine,
    required this.selectedSession,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedRoutine == null) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.bedtime_outlined, size: 18),
          label: const Text('No hay rutina para este día'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.mutedForeground,
            side: const BorderSide(color: AppTheme.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    if (selectedSession != null) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () => context.go('/workout/live?workoutId=${selectedSession!.id}'),
          icon: const Icon(Icons.visibility_outlined, size: 18),
          label: const Text('Ver entrenamiento', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.foreground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.border)),
            elevation: 0,
          ),
        ),
      );
    }

    final dateIso = DateFormat('yyyy-MM-dd').format(selectedDate);
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () => context.go('/workout/live?routineId=${selectedRoutine!.id}&date=$dateIso'),
        icon: const Icon(Icons.play_arrow, size: 20),
        label: const Text('Iniciar entrenamiento', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}

// ── Daily Stats Grid ──────────────────────────────────────────────────────────
class _DailyStatsGrid extends StatelessWidget {
  final NutritionState nutrition;
  final HealthState health;

  const _DailyStatsGrid({required this.nutrition, required this.health});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _Stat('Calorías', '${nutrition.totalCalories.toInt()}', 'kcal', Icons.local_fire_department_outlined, AppTheme.primary),
      _Stat('Agua', '${nutrition.waterLiters.toStringAsFixed(1)}/${nutrition.hydrationGoal.toStringAsFixed(1)}', 'L', Icons.water_drop_outlined, AppTheme.blue400),
      _Stat('Pasos', '${health.todaySteps}', '', Icons.directions_walk_outlined, AppTheme.amber400),
      _Stat('Sueño', health.sleepHoursFormatted, '', Icons.bedtime_outlined, AppTheme.violet400),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: stats.map((s) => _StatCard(stat: s)).toList(),
    );
  }
}

class _Stat {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.unit, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _Stat stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.background, AppTheme.primary.withOpacity(0.05), AppTheme.primary.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(stat.icon, color: stat.color, size: 16),
              const SizedBox(width: 6),
              Text(stat.label.toUpperCase(),
                  style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(stat.value,
                  style: const TextStyle(color: AppTheme.foreground, fontSize: 20, fontWeight: FontWeight.bold)),
              if (stat.unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(stat.unit, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Daily Tasks ───────────────────────────────────────────────────────────────
class _DailyTasksList extends ConsumerWidget {
  final NutritionState nutrition;

  const _DailyTasksList({required this.nutrition});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = _buildMealTasks(nutrition);
    final supplements = _buildSupplementTasks(nutrition);
    final water = _buildWaterTask(nutrition);

    if (meals.isEmpty && supplements.isEmpty) return const SizedBox.shrink();

    final totalTasks = meals.length + supplements.length + (water != null ? 1 : 0);
    final completedTasks = meals.where((t) => t['completed'] as bool).length +
        supplements.where((t) => t['completed'] as bool).length +
        (water?['completed'] == true ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tareas de Hoy', style: TextStyle(color: AppTheme.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
            Text('$completedTasks/$totalTasks completadas',
                style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),

        if (meals.isNotEmpty) ...[
          _TaskGroupHeader(label: 'Comidas', icon: Icons.restaurant_outlined),
          const SizedBox(height: 6),
          ...meals.map((t) => _TaskItem(task: t, onTap: () => _handleTaskTap(context, ref, t))),
          const SizedBox(height: 12),
        ],

        if (supplements.isNotEmpty) ...[
          _TaskGroupHeader(label: 'Suplementos', icon: Icons.medication_outlined),
          const SizedBox(height: 6),
          ...supplements.map((t) => _TaskItem(task: t, onTap: () => _handleTaskTap(context, ref, t))),
          const SizedBox(height: 12),
        ],

        if (water != null) ...[
          _TaskGroupHeader(label: 'Otros', icon: Icons.list_alt_outlined),
          const SizedBox(height: 6),
          _TaskItem(task: water, onTap: () => _handleTaskTap(context, ref, water)),
        ],
      ],
    );
  }

  List<Map<String, dynamic>> _buildMealTasks(NutritionState n) {
    const types = ['desayuno', 'almuerzo', 'snack', 'cena'];
    const labels = {'desayuno': 'Desayuno', 'almuerzo': 'Almuerzo', 'snack': 'Snack', 'cena': 'Cena'};
    const icons = {
      'desayuno': Icons.coffee_outlined,
      'almuerzo': Icons.lunch_dining_outlined,
      'snack': Icons.cookie_outlined,
      'cena': Icons.dinner_dining_outlined,
    };

    return types.map((type) {
      final logged = n.meals.where((m) => m.type == type).toList();
      return {
        'id': 'meal_$type',
        'type': 'meal',
        'mealType': type,
        'title': labels[type]!,
        'subtitle': logged.isNotEmpty ? logged.last.name : 'Pendiente',
        'completed': logged.isNotEmpty,
        'icon': icons[type] ?? Icons.restaurant_outlined,
        'supplementId': null,
        'mealId': logged.isNotEmpty ? logged.last.id : null,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildSupplementTasks(NutritionState n) {
    return n.supplements.where((s) => s.isActive).map((s) {
      final log = n.supplementLogs.where((l) => l.supplementId == s.id).firstOrNull;
      return {
        'id': 'sup_${s.id}',
        'type': 'supplement',
        'mealType': null,
        'title': s.name,
        'subtitle': '${s.dosage} · ${supplementScheduleLabels[s.schedule] ?? s.schedule}',
        'completed': log?.taken ?? false,
        'icon': Icons.medication_outlined,
        'supplementId': s.id,
        'mealId': null,
      };
    }).toList();
  }

  Map<String, dynamic>? _buildWaterTask(NutritionState n) {
    return {
      'id': 'water',
      'type': 'water',
      'mealType': null,
      'title': 'Beber agua',
      'subtitle': '${n.waterLiters.toStringAsFixed(1)}/${n.hydrationGoal.toStringAsFixed(1)}L',
      'completed': n.waterLiters >= n.hydrationGoal,
      'icon': Icons.water_drop_outlined,
      'supplementId': null,
      'mealId': null,
    };
  }

  Future<void> _handleTaskTap(BuildContext context, WidgetRef ref, Map<String, dynamic> task) async {
    switch (task['type']) {
      case 'meal':
        if (task['completed'] as bool) {
          final mealId = task['mealId'] as String?;
          if (mealId != null) {
            await ref.read(nutritionProvider.notifier).removeMeal(mealId);
          }
        } else {
          context.go('/nutrition');
        }
        break;
      case 'water':
        if (task['completed'] as bool) {
          await ref.read(nutritionProvider.notifier).removeLastWater();
        } else {
          await ref.read(nutritionProvider.notifier).addWater();
        }
        break;
      case 'supplement':
        final id = task['supplementId'] as String?;
        if (id != null) {
          await ref.read(nutritionProvider.notifier).toggleSupplement(id);
        }
        break;
    }
  }
}

class _TaskGroupHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _TaskGroupHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 14),
        const SizedBox(width: 6),
        Text(label.toUpperCase(),
            style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: AppTheme.border, height: 1)),
      ],
    );
  }
}

class _TaskItem extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onTap;
  const _TaskItem({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final completed = task['completed'] as bool;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: completed ? AppTheme.primary.withOpacity(0.05) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: completed ? AppTheme.primary.withOpacity(0.3) : AppTheme.border,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed ? AppTheme.primary : Colors.transparent,
                border: Border.all(
                  color: completed ? AppTheme.primary : AppTheme.border,
                ),
              ),
              child: completed ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'] as String,
                    style: TextStyle(
                      color: completed ? AppTheme.mutedForeground : AppTheme.foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(task['subtitle'] as String, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                ],
              ),
            ),
            Icon(task['icon'] as IconData, color: AppTheme.mutedForeground, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Recent Activity ───────────────────────────────────────────────────────────
class _RecentActivity extends StatelessWidget {
  final NutritionState nutrition;
  final HealthState health;
  final BodyState body;

  const _RecentActivity({required this.nutrition, required this.health, required this.body});

  @override
  Widget build(BuildContext context) {
    final items = <Map<String, dynamic>>[];

    if (nutrition.meals.isNotEmpty) {
      final last = nutrition.meals.last;
      items.add({
        'text': last.name,
        'detail': '${last.calories?.toInt() ?? 0} kcal',
        'time': last.time,
        'icon': Icons.restaurant_outlined,
      });
    }

    if (health.cardioSessions.isNotEmpty) {
      final last = health.cardioSessions.last;
      items.add({
        'text': last.type == 'walking' ? 'Caminata' : last.type == 'running' ? 'Carrera' : 'Cardio',
        'detail': '${last.steps ?? 0} pasos',
        'time': last.time,
        'icon': Icons.directions_walk_outlined,
      });
    }

    if (body.latestCheck != null) {
      items.add({
        'text': 'Revisión Física',
        'detail': '${body.latestCheck!.weight ?? '--'} kg',
        'time': body.latestCheck!.date,
        'icon': Icons.straighten_outlined,
      });
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Actividad Reciente', style: TextStyle(color: AppTheme.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...items.take(4).map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.background, AppTheme.primary.withOpacity(0.04), AppTheme.primary.withOpacity(0.08)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item['icon'] as IconData, color: AppTheme.primary, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['text'] as String,
                          style: const TextStyle(color: AppTheme.foreground, fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(item['detail'] as String,
                          style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                    ],
                  ),
                ),
                Text(item['time'] as String, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
