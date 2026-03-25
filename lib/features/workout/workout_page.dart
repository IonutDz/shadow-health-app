import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'workout_provider.dart';

const _dayLabels = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

class WorkoutPage extends ConsumerStatefulWidget {
  const WorkoutPage({super.key});

  @override
  ConsumerState<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends ConsumerState<WorkoutPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _activeTab = 0;

  // Add planning form
  final _planNameCtrl = TextEditingController();
  bool _showAddPlanning = false;

  // Add routine form
  String _newRoutineName = '';
  int _newRoutineDay = 0;
  String _newRoutinePlanId = '';
  bool _showAddRoutine = false;
  bool _addingRoutine = false;

  // Add gym form
  final _gymNameCtrl = TextEditingController();
  bool _showAddGym = false;

  // Expanded states
  final Map<String, bool> _expandedPlannings = {};
  final Map<String, bool> _expandedRoutines = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) setState(() => _activeTab = _tabs.index);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _planNameCtrl.dispose();
    _gymNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(workoutProvider);

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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ejercicios', style: TextStyle(color: AppTheme.foreground, fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('Plannings, rutinas y gimnasios', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (workout.todayRoutine != null)
                    ElevatedButton.icon(
                      onPressed: () => context.go('/workout/live?routineId=${workout.todayRoutine!.id}'),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Iniciar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                ],
              ),
            ),

            // Tab pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _TabPill(
                          label: ['Plannings', 'Rutinas', 'Gimnasios'][i],
                          icon: [Icons.calendar_month_outlined, Icons.fitness_center_outlined, Icons.warehouse_outlined][i],
                          active: _activeTab == i,
                          onTap: () {
                            setState(() => _activeTab = i);
                            _tabs.animateTo(i);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _PlanningsTab(
                    workout: workout,
                    expandedPlannings: _expandedPlannings,
                    expandedRoutines: _expandedRoutines,
                    showAddPlanning: _showAddPlanning,
                    showAddRoutine: _showAddRoutine,
                    planNameCtrl: _planNameCtrl,
                    newRoutineName: _newRoutineName,
                    newRoutineDay: _newRoutineDay,
                    newRoutinePlanId: _newRoutinePlanId,
                    addingRoutine: _addingRoutine,
                    onTogglePlanning: (id) => setState(() => _expandedPlannings[id] = !(_expandedPlannings[id] ?? false)),
                    onToggleRoutine: (id) => setState(() => _expandedRoutines[id] = !(_expandedRoutines[id] ?? false)),
                    onToggleAddPlanning: () => setState(() => _showAddPlanning = !_showAddPlanning),
                    onOpenAddRoutine: (planId) => setState(() {
                      _newRoutinePlanId = planId;
                      _showAddRoutine = true;
                    }),
                    onCloseAddRoutine: () => setState(() => _showAddRoutine = false),
                    onRoutineNameChange: (v) => setState(() => _newRoutineName = v),
                    onRoutineDayChange: (v) => setState(() => _newRoutineDay = v),
                    onCreatePlanning: () async {
                      if (_planNameCtrl.text.trim().isEmpty) return;
                      await ref.read(workoutProvider.notifier).addPlanning(name: _planNameCtrl.text.trim());
                      _planNameCtrl.clear();
                      setState(() => _showAddPlanning = false);
                    },
                    onCreateRoutine: () async {
                      if (_newRoutineName.trim().isEmpty || _addingRoutine) return;
                      setState(() => _addingRoutine = true);
                      await ref.read(workoutProvider.notifier).addRoutine(
                            _newRoutinePlanId,
                            name: _newRoutineName.trim(),
                            dayOfWeek: _newRoutineDay,
                          );
                      setState(() {
                        _addingRoutine = false;
                        _showAddRoutine = false;
                        _newRoutineName = '';
                        _newRoutineDay = 0;
                      });
                    },
                    onSetActive: (id) => ref.read(workoutProvider.notifier).setActivePlanning(id),
                  ),
                  _RoutinesTab(workout: workout, expandedRoutines: _expandedRoutines),
                  _GymsTab(
                    workout: workout,
                    showAddGym: _showAddGym,
                    gymNameCtrl: _gymNameCtrl,
                    onToggleAddGym: () => setState(() => _showAddGym = !_showAddGym),
                    onCreateGym: () async {
                      if (_gymNameCtrl.text.trim().isEmpty) return;
                      await ref.read(workoutProvider.notifier).addGym(name: _gymNameCtrl.text.trim());
                      _gymNameCtrl.clear();
                      setState(() => _showAddGym = false);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TabPill({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppTheme.primary : AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: active ? Colors.white : AppTheme.mutedForeground),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: active ? Colors.white : AppTheme.mutedForeground, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Plannings Tab ─────────────────────────────────────────────────────────────
class _PlanningsTab extends StatelessWidget {
  final WorkoutState workout;
  final Map<String, bool> expandedPlannings;
  final Map<String, bool> expandedRoutines;
  final bool showAddPlanning;
  final bool showAddRoutine;
  final TextEditingController planNameCtrl;
  final String newRoutineName;
  final int newRoutineDay;
  final String newRoutinePlanId;
  final bool addingRoutine;
  final void Function(String) onTogglePlanning;
  final void Function(String) onToggleRoutine;
  final VoidCallback onToggleAddPlanning;
  final void Function(String) onOpenAddRoutine;
  final VoidCallback onCloseAddRoutine;
  final void Function(String) onRoutineNameChange;
  final void Function(int) onRoutineDayChange;
  final VoidCallback onCreatePlanning;
  final VoidCallback onCreateRoutine;
  final void Function(String) onSetActive;

  const _PlanningsTab({
    required this.workout,
    required this.expandedPlannings,
    required this.expandedRoutines,
    required this.showAddPlanning,
    required this.showAddRoutine,
    required this.planNameCtrl,
    required this.newRoutineName,
    required this.newRoutineDay,
    required this.newRoutinePlanId,
    required this.addingRoutine,
    required this.onTogglePlanning,
    required this.onToggleRoutine,
    required this.onToggleAddPlanning,
    required this.onOpenAddRoutine,
    required this.onCloseAddRoutine,
    required this.onRoutineNameChange,
    required this.onRoutineDayChange,
    required this.onCreatePlanning,
    required this.onCreateRoutine,
    required this.onSetActive,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: [
        // Today quick start
        if (workout.todayRoutine != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.15), AppTheme.primary.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HOY', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(workout.todayRoutine!.name, style: const TextStyle(color: AppTheme.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/workout/live?routineId=${workout.todayRoutine!.id}'),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Iniciar Entrenamiento', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // List of plannings
        for (final planning in workout.plannings)
          _PlanningCard(
            planning: planning,
            isExpanded: expandedPlannings[planning.id] ?? false,
            expandedRoutines: expandedRoutines,
            onToggle: () => onTogglePlanning(planning.id),
            onToggleRoutine: onToggleRoutine,
            onAddRoutine: () => onOpenAddRoutine(planning.id),
            onSetActive: () => onSetActive(planning.id),
          ),

        // Add routine inline form
        if (showAddRoutine)
          _AddRoutineForm(
            planId: newRoutinePlanId,
            planName: workout.plannings.where((p) => p.id == newRoutinePlanId).firstOrNull?.name ?? '',
            name: newRoutineName,
            day: newRoutineDay,
            adding: addingRoutine,
            onChangeName: onRoutineNameChange,
            onChangeDay: onRoutineDayChange,
            onClose: onCloseAddRoutine,
            onCreate: onCreateRoutine,
          ),

        const SizedBox(height: 12),

        // Add planning button / form
        if (!showAddPlanning)
          OutlinedButton.icon(
            onPressed: onToggleAddPlanning,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nuevo Planning', style: TextStyle(fontWeight: FontWeight.w500)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: BorderSide(color: AppTheme.primary.withOpacity(0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          )
        else
          _AddPlanningForm(ctrl: planNameCtrl, onCreate: onCreatePlanning, onClose: onToggleAddPlanning),

        const SizedBox(height: 80),
      ],
    );
  }
}

class _PlanningCard extends StatelessWidget {
  final Planning planning;
  final bool isExpanded;
  final Map<String, bool> expandedRoutines;
  final VoidCallback onToggle;
  final void Function(String) onToggleRoutine;
  final VoidCallback onAddRoutine;
  final VoidCallback onSetActive;

  const _PlanningCard({
    required this.planning,
    required this.isExpanded,
    required this.expandedRoutines,
    required this.onToggle,
    required this.onToggleRoutine,
    required this.onAddRoutine,
    required this.onSetActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: planning.isActive ? AppTheme.primary.withOpacity(0.3) : AppTheme.border),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  if (planning.isActive)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('ACTIVO', style: TextStyle(color: AppTheme.primary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(planning.name, style: const TextStyle(color: AppTheme.foreground, fontSize: 15, fontWeight: FontWeight.w600)),
                        Text('${planning.routines.length} rutinas', style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (!planning.isActive)
                    TextButton(
                      onPressed: onSetActive,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Activar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.mutedForeground, size: 20),
                ],
              ),
            ),
          ),

          // Routines list
          if (isExpanded) ...[
            const Divider(height: 1, color: AppTheme.border),
            for (final routine in planning.routines)
              _RoutineRow(
                routine: routine,
                planningId: planning.id,
                isExpanded: expandedRoutines[routine.id] ?? false,
                onToggle: () => onToggleRoutine(routine.id),
              ),
            // Add routine row
            InkWell(
              onTap: onAddRoutine,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    const Text('Añadir rutina', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  final Routine routine;
  final String planningId;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _RoutineRow({
    required this.routine,
    required this.planningId,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = routine.dayOfWeek < _dayLabels.length ? _dayLabels[routine.dayOfWeek] : 'Día ${routine.dayOfWeek + 1}';

    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(dayName, style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(routine.name, style: const TextStyle(color: AppTheme.foreground, fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('${routine.exercises.length} ejercicios', style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/workout/live?routineId=${routine.id}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.play_arrow, color: AppTheme.primary, size: 14),
                        SizedBox(width: 4),
                        Text('Iniciar', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.mutedForeground, size: 18),
              ],
            ),
          ),
        ),
        if (isExpanded && routine.exercises.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: 14, right: 14, bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < routine.exercises.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${i + 1}', style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(routine.exercises[i].name, style: const TextStyle(color: AppTheme.foreground, fontSize: 12, fontWeight: FontWeight.w500)),
                              Text(
                                '${routine.exercises[i].defaultSets} series · ${routine.exercises[i].defaultReps ?? '?'} reps · ${routine.exercises[i].defaultRestTime}s descanso',
                                style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < routine.exercises.length - 1) const Divider(height: 1, color: AppTheme.border),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _AddPlanningForm extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onCreate;
  final VoidCallback onClose;

  const _AddPlanningForm({required this.ctrl, required this.onCreate, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nuevo Planning', style: TextStyle(color: AppTheme.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          TextField(
            controller: ctrl,
            style: const TextStyle(color: AppTheme.foreground, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Nombre del planning',
              hintStyle: const TextStyle(color: AppTheme.mutedForeground),
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Crear', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onClose,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.mutedForeground,
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddRoutineForm extends StatelessWidget {
  final String planId;
  final String planName;
  final String name;
  final int day;
  final bool adding;
  final void Function(String) onChangeName;
  final void Function(int) onChangeDay;
  final VoidCallback onClose;
  final VoidCallback onCreate;

  const _AddRoutineForm({
    required this.planId,
    required this.planName,
    required this.name,
    required this.day,
    required this.adding,
    required this.onChangeName,
    required this.onChangeDay,
    required this.onClose,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nueva Rutina en "$planName"', style: const TextStyle(color: AppTheme.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          TextField(
            onChanged: onChangeName,
            style: const TextStyle(color: AppTheme.foreground, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Nombre de la rutina',
              hintStyle: const TextStyle(color: AppTheme.mutedForeground),
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Día de la semana', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_dayLabels.length, (i) {
                final selected = day == i;
                return GestureDetector(
                  onTap: () => onChangeDay(i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
                    ),
                    child: Text(
                      _dayLabels[i].substring(0, 3),
                      style: TextStyle(color: selected ? Colors.white : AppTheme.mutedForeground, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: adding ? null : onCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: adding
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Crear Rutina', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onClose,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.mutedForeground,
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Routines Tab ──────────────────────────────────────────────────────────────
class _RoutinesTab extends StatelessWidget {
  final WorkoutState workout;
  final Map<String, bool> expandedRoutines;

  const _RoutinesTab({required this.workout, required this.expandedRoutines});

  @override
  Widget build(BuildContext context) {
    final allRoutines = <Map<String, dynamic>>[];
    for (final p in workout.plannings) {
      for (final r in p.routines) {
        allRoutines.add({'routine': r, 'planning': p});
      }
    }

    if (allRoutines.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, color: AppTheme.mutedForeground, size: 40),
            SizedBox(height: 12),
            Text('No hay rutinas todavía', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 14)),
            SizedBox(height: 4),
            Text('Crea un planning y añade rutinas', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: allRoutines.length,
      itemBuilder: (context, i) {
        final routine = allRoutines[i]['routine'] as Routine;
        final planning = allRoutines[i]['planning'] as Planning;
        final dayName = routine.dayOfWeek < _dayLabels.length ? _dayLabels[routine.dayOfWeek] : 'Día ${routine.dayOfWeek + 1}';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: InkWell(
            onTap: () => context.go('/workout/live?routineId=${routine.id}'),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fitness_center, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(routine.name, style: const TextStyle(color: AppTheme.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('$dayName · ${routine.exercises.length} ejercicios · ${planning.name}',
                            style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.mutedForeground, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Gyms Tab ──────────────────────────────────────────────────────────────────
class _GymsTab extends StatelessWidget {
  final WorkoutState workout;
  final bool showAddGym;
  final TextEditingController gymNameCtrl;
  final VoidCallback onToggleAddGym;
  final VoidCallback onCreateGym;

  const _GymsTab({
    required this.workout,
    required this.showAddGym,
    required this.gymNameCtrl,
    required this.onToggleAddGym,
    required this.onCreateGym,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        for (final gym in workout.gyms)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.amber400.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.warehouse_outlined, color: AppTheme.amber400, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(gym.name, style: const TextStyle(color: AppTheme.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
                      if (gym.address != null && gym.address!.isNotEmpty)
                        Text(gym.address!, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                      Text('${gym.machines.length} máquinas', style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),

        if (showAddGym)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nuevo Gimnasio', style: TextStyle(color: AppTheme.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                TextField(
                  controller: gymNameCtrl,
                  style: const TextStyle(color: AppTheme.foreground, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Nombre del gimnasio',
                    hintStyle: const TextStyle(color: AppTheme.mutedForeground),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primary)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onCreateGym,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Crear', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: onToggleAddGym,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.mutedForeground,
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: onToggleAddGym,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Añadir Gimnasio', style: TextStyle(fontWeight: FontWeight.w500)),
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
}
