import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'workout_provider.dart';

class WorkoutLivePage extends ConsumerStatefulWidget {
  final String? routineId;
  final String? date;
  final String? workoutId;

  const WorkoutLivePage({super.key, this.routineId, this.date, this.workoutId});

  @override
  ConsumerState<WorkoutLivePage> createState() => _WorkoutLivePageState();
}

class _WorkoutLivePageState extends ConsumerState<WorkoutLivePage> {
  ActiveWorkout? _workout;
  bool _isLoading = true;
  bool _isResting = false;
  int _restRemaining = 0;
  Timer? _restTimer;
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;
  int _currentExerciseIdx = 0;

  // Per-set editing state
  final Map<String, TextEditingController> _weightCtrls = {};
  final Map<String, TextEditingController> _repsCtrls = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isResting) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _elapsedTimer?.cancel();
    for (final c in _weightCtrls.values) c.dispose();
    for (final c in _repsCtrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final notifier = ref.read(workoutProvider.notifier);
    ActiveWorkout? w;

    if (widget.workoutId != null) {
      w = await notifier.loadWorkout(widget.workoutId!);
    } else {
      w = await notifier.startWorkout(
        routineId: widget.routineId,
        date: widget.date,
      );
    }

    if (w != null) {
      // Init text controllers for each set
      for (final ex in w.exercises) {
        for (final s in ex.sets) {
          _weightCtrls[s.id] = TextEditingController(text: s.weight?.toString() ?? '');
          _repsCtrls[s.id] = TextEditingController(text: s.reps?.toString() ?? '');
        }
      }
    }

    setState(() {
      _workout = w;
      _isLoading = false;
    });
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restRemaining = seconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _restRemaining--;
        if (_restRemaining <= 0) {
          _isResting = false;
          timer.cancel();
        }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restRemaining = 0;
    });
  }

  Future<void> _completeSet(LiveExercise exercise, WorkoutSet set) async {
    final w = _workout;
    if (w == null) return;

    final weightText = _weightCtrls[set.id]?.text ?? '';
    final repsText = _repsCtrls[set.id]?.text ?? '';
    final weight = double.tryParse(weightText);
    final reps = int.tryParse(repsText);

    setState(() => set.isCompleted = true);

    await ref.read(workoutProvider.notifier).updateSet(
          w.id,
          exercise.id,
          set.id,
          weight: weight,
          reps: reps,
          isCompleted: true,
        );

    // Start rest timer
    _startRest(exercise.restTime);
  }

  Future<void> _undoSet(LiveExercise exercise, WorkoutSet set) async {
    final w = _workout;
    if (w == null) return;
    setState(() => set.isCompleted = false);
    await ref.read(workoutProvider.notifier).updateSet(
          w.id,
          exercise.id,
          set.id,
          isCompleted: false,
        );
  }

  Future<void> _finishWorkout() async {
    final w = _workout;
    if (w == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Finalizar entrenamiento', style: TextStyle(color: AppTheme.foreground, fontWeight: FontWeight.bold)),
        content: Text(
          '¿Estás seguro? Se registrará el tiempo total de ${_formatElapsed(_elapsedSeconds)}.',
          style: const TextStyle(color: AppTheme.mutedForeground),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(workoutProvider.notifier).finishWorkout(w.id);
      if (mounted) context.go('/workout');
    }
  }

  String _formatElapsed(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 16),
              const Text('Preparando entrenamiento...', style: TextStyle(color: AppTheme.mutedForeground)),
            ],
          ),
        ),
      );
    }

    if (_workout == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(backgroundColor: AppTheme.background, leading: BackButton(onPressed: () => context.go('/workout'))),
        body: const Center(
          child: Text('No se pudo cargar el entrenamiento', style: TextStyle(color: AppTheme.mutedForeground)),
        ),
      );
    }

    final workout = _workout!;
    final exercises = workout.exercises;

    if (exercises.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          leading: BackButton(onPressed: () => context.go('/workout')),
          title: Text(workout.name, style: const TextStyle(color: AppTheme.foreground, fontWeight: FontWeight.bold)),
        ),
        body: const Center(
          child: Text('Esta rutina no tiene ejercicios todavía.', style: TextStyle(color: AppTheme.mutedForeground)),
        ),
      );
    }

    final currentEx = exercises[_currentExerciseIdx.clamp(0, exercises.length - 1)];
    final completedSets = exercises.expand((e) => e.sets).where((s) => s.isCompleted).length;
    final totalSets = exercises.expand((e) => e.sets).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _LiveHeader(
              workoutName: workout.name,
              elapsedSeconds: _elapsedSeconds,
              completedSets: completedSets,
              totalSets: totalSets,
              onFinish: _finishWorkout,
              onBack: () => context.go('/workout'),
            ),

            // Rest timer overlay
            if (_isResting)
              _RestTimerBar(remaining: _restRemaining, onSkip: _skipRest),

            // Exercise selector pills
            SizedBox(
              height: 44,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: exercises.length,
                itemBuilder: (ctx, i) {
                  final ex = exercises[i];
                  final isActive = i == _currentExerciseIdx;
                  final exCompleted = ex.sets.every((s) => s.isCompleted);
                  return GestureDetector(
                    onTap: () => setState(() => _currentExerciseIdx = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.primary : exCompleted ? AppTheme.primary.withOpacity(0.15) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive ? AppTheme.primary : exCompleted ? AppTheme.primary.withOpacity(0.3) : AppTheme.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (exCompleted && !isActive)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(Icons.check, color: AppTheme.primary, size: 12),
                            ),
                          Text(
                            ex.name.length > 12 ? '${ex.name.substring(0, 12)}…' : ex.name,
                            style: TextStyle(
                              color: isActive ? Colors.white : exCompleted ? AppTheme.primary : AppTheme.mutedForeground,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Exercise details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ExercisePanel(
                  exercise: currentEx,
                  weightCtrls: _weightCtrls,
                  repsCtrls: _repsCtrls,
                  onCompleteSet: (set) => _completeSet(currentEx, set),
                  onUndoSet: (set) => _undoSet(currentEx, set),
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentExerciseIdx > 0)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _currentExerciseIdx--),
                      icon: const Icon(Icons.chevron_left, size: 18),
                      label: const Text('Anterior'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.mutedForeground,
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  const Spacer(),
                  if (_currentExerciseIdx < exercises.length - 1)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _currentExerciseIdx++),
                      icon: const Text('Siguiente'),
                      label: const Icon(Icons.chevron_right, size: 18),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        elevation: 0,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _finishWorkout,
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: const Text('Finalizar', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        elevation: 0,
                      ),
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

class _LiveHeader extends StatelessWidget {
  final String workoutName;
  final int elapsedSeconds;
  final int completedSets;
  final int totalSets;
  final VoidCallback onFinish;
  final VoidCallback onBack;

  const _LiveHeader({
    required this.workoutName,
    required this.elapsedSeconds,
    required this.completedSets,
    required this.totalSets,
    required this.onFinish,
    required this.onBack,
  });

  String _format(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.close, color: AppTheme.mutedForeground, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(workoutName, style: const TextStyle(color: AppTheme.foreground, fontSize: 15, fontWeight: FontWeight.w600)),
                Text(
                  '${_format(elapsedSeconds)} · $completedSets/$totalSets series',
                  style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary.withOpacity(0.15),
              foregroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Finalizar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _RestTimerBar extends StatelessWidget {
  final int remaining;
  final VoidCallback onSkip;

  const _RestTimerBar({required this.remaining, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.blue400.withOpacity(0.15), AppTheme.violet400.withOpacity(0.1)],
        ),
        border: const Border(
          bottom: BorderSide(color: AppTheme.border),
          top: BorderSide(color: AppTheme.border),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: AppTheme.blue400, size: 18),
          const SizedBox(width: 8),
          Text(
            'Descansando: ${remaining}s',
            style: const TextStyle(color: AppTheme.foreground, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            child: const Text('Saltar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _ExercisePanel extends StatelessWidget {
  final LiveExercise exercise;
  final Map<String, TextEditingController> weightCtrls;
  final Map<String, TextEditingController> repsCtrls;
  final void Function(WorkoutSet) onCompleteSet;
  final void Function(WorkoutSet) onUndoSet;

  const _ExercisePanel({
    required this.exercise,
    required this.weightCtrls,
    required this.repsCtrls,
    required this.onCompleteSet,
    required this.onUndoSet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exercise info header
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary.withOpacity(0.08), AppTheme.primary.withOpacity(0.03)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, style: const TextStyle(color: AppTheme.foreground, fontSize: 17, fontWeight: FontWeight.bold)),
                    if (exercise.machineName != null)
                      Text(exercise.machineName!, style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 12)),
                    if (exercise.muscleGroups != null && exercise.muscleGroups!.isNotEmpty)
                      Text(exercise.muscleGroups!, style: const TextStyle(color: AppTheme.primary, fontSize: 11)),
                    if (exercise.planningNotes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(exercise.planningNotes.join(' · '), style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11)),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  '${exercise.restTime}s desc.',
                  style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Sets header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const SizedBox(width: 28),
              const SizedBox(width: 8),
              const Expanded(child: Center(child: Text('PESO (kg)', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)))),
              const SizedBox(width: 8),
              const Expanded(child: Center(child: Text('REPS', style: TextStyle(color: AppTheme.mutedForeground, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)))),
              const SizedBox(width: 8),
              const SizedBox(width: 64),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Sets list
        for (int i = 0; i < exercise.sets.length; i++)
          _SetRow(
            set: exercise.sets[i],
            setIndex: i,
            targetReps: i < exercise.targetReps.length ? exercise.targetReps[i] : '',
            targetRir: i < exercise.targetRir.length ? exercise.targetRir[i] : '',
            weightCtrl: weightCtrls[exercise.sets[i].id] ?? TextEditingController(),
            repsCtrl: repsCtrls[exercise.sets[i].id] ?? TextEditingController(),
            onComplete: () => onCompleteSet(exercise.sets[i]),
            onUndo: () => onUndoSet(exercise.sets[i]),
          ),

        const SizedBox(height: 80),
      ],
    );
  }
}

class _SetRow extends StatelessWidget {
  final WorkoutSet set;
  final int setIndex;
  final String targetReps;
  final String targetRir;
  final TextEditingController weightCtrl;
  final TextEditingController repsCtrl;
  final VoidCallback onComplete;
  final VoidCallback onUndo;

  const _SetRow({
    required this.set,
    required this.setIndex,
    required this.targetReps,
    required this.targetRir,
    required this.weightCtrl,
    required this.repsCtrl,
    required this.onComplete,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: set.isCompleted ? AppTheme.primary.withOpacity(0.08) : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: set.isCompleted ? AppTheme.primary.withOpacity(0.3) : AppTheme.border,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Set number
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: set.isCompleted ? AppTheme.primary : AppTheme.primary.withOpacity(0.1),
            ),
            child: Center(
              child: set.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : Text('${setIndex + 1}', style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 8),

          // Weight input
          Expanded(
            child: Column(
              children: [
                if (targetReps.isNotEmpty)
                  Text('obj: $targetReps${targetRir.isNotEmpty ? ' RIR$targetRir' : ''}',
                      style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 9)),
                _SetInput(ctrl: weightCtrl, hint: '0', enabled: !set.isCompleted),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Reps input
          Expanded(
            child: _SetInput(ctrl: repsCtrl, hint: targetReps.isNotEmpty ? targetReps : '?', enabled: !set.isCompleted),
          ),
          const SizedBox(width: 8),

          // Complete/Undo button
          SizedBox(
            width: 64,
            height: 36,
            child: set.isCompleted
                ? OutlinedButton(
                    onPressed: onUndo,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.mutedForeground,
                      side: const BorderSide(color: AppTheme.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.undo, size: 16),
                  )
                : ElevatedButton(
                    onPressed: onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.check, size: 16),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SetInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool enabled;

  const _SetInput({required this.ctrl, required this.hint, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: enabled ? AppTheme.foreground : AppTheme.mutedForeground,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.mutedForeground, fontSize: 13),
        filled: true,
        fillColor: enabled ? AppTheme.background : Colors.transparent,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }
}
