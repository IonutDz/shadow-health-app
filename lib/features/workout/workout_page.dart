import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'workout_provider.dart';

class WorkoutPage extends ConsumerWidget {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWorkout = ref.watch(activeWorkoutProvider);
    final historyAsync = ref.watch(workoutHistoryProvider);

    if (activeWorkout.session != null) {
      return const WorkoutPlayerPage();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Entrenamientos')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sessions) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar entreno libre'),
                onPressed: () => _showStartDialog(context, ref),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
            ),
            Expanded(
              child: sessions.isEmpty
                  ? const Center(child: Text('Sin historial de entrenamientos'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: sessions.length,
                      itemBuilder: (ctx, i) => _WorkoutCard(session: sessions[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStartDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: 'Entreno libre');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo entreno'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nombre')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(activeWorkoutProvider.notifier).startWorkout(ctrl.text);
            },
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final dynamic session;
  const _WorkoutCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.fitness_center)),
        title: Text(session.name as String),
        subtitle: Text(_formatDate(session.startedAt as String)),
        trailing: session.finishedAt != null
            ? Text(_formatDuration(session.totalTimeMs as int?), style: const TextStyle(color: Colors.grey))
            : const Text('En curso', style: TextStyle(color: AppTheme.primary)),
      ),
    );
  }

  String _formatDate(String iso) {
    final d = DateTime.parse(iso).toLocal();
    return '${d.day}/${d.month}/${d.year}';
  }

  String _formatDuration(int? ms) {
    if (ms == null) return '';
    final minutes = ms ~/ 60000;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
  }
}

class WorkoutPlayerPage extends ConsumerWidget {
  const WorkoutPlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeWorkoutProvider);
    final exercise = state.currentExercise;
    final session = state.session!;

    return Scaffold(
      appBar: AppBar(
        title: Text(session.name),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showDiscardDialog(context, ref),
        ),
        actions: [
          TextButton(
            onPressed: () => _showFinishDialog(context, ref),
            child: const Text('Finalizar'),
          ),
        ],
      ),
      body: exercise == null
          ? const Center(child: Text('Sin ejercicios'))
          : Column(
              children: [
                // Progress indicator
                LinearProgressIndicator(
                  value: (state.currentExerciseIndex + 1) / session.exercises.length,
                  backgroundColor: AppTheme.card,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ejercicio ${state.currentExerciseIndex + 1}/${session.exercises.length}',
                        style: const TextStyle(color: Colors.grey)),
                      if (state.isResting)
                        Text('Descanso: ${state.restTimeRemaining}s',
                          style: const TextStyle(color: AppTheme.secondary)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(exercise.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      ...exercise.sets.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final set = entry.value;
                        return _SetRow(
                          setNumber: idx + 1,
                          set: set,
                          onComplete: (weight, reps) {
                            ref.read(activeWorkoutProvider.notifier).completeSet(
                              state.currentExerciseIndex, idx,
                              weight: weight, reps: reps,
                            );
                          },
                        );
                      }),
                    ],
                  ),
                ),
                // Navigation
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (state.currentExerciseIndex > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => ref.read(activeWorkoutProvider.notifier).prevExercise(),
                            child: const Text('Anterior'),
                          ),
                        ),
                      if (state.currentExerciseIndex > 0) const SizedBox(width: 12),
                      if (state.currentExerciseIndex < session.exercises.length - 1)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => ref.read(activeWorkoutProvider.notifier).nextExercise(),
                            child: const Text('Siguiente'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showDiscardDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Descartar entreno?'),
        content: const Text('Se perderán todos los datos del entreno actual.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(activeWorkoutProvider.notifier).discardWorkout();
            },
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Finalizar entreno?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(activeWorkoutProvider.notifier).finishWorkout();
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  final int setNumber;
  final dynamic set;
  final Function(double? weight, int? reps) onComplete;

  const _SetRow({required this.setNumber, required this.set, required this.onComplete});

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: widget.set.weight?.toString() ?? '');
    _repsCtrl = TextEditingController(text: widget.set.reps?.toString() ?? '');
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.set.isCompleted as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted ? AppTheme.primary.withOpacity(0.1) : AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCompleted ? AppTheme.primary : Colors.transparent),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? AppTheme.primary : Colors.grey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text('${widget.setNumber}',
              style: TextStyle(fontWeight: FontWeight.bold, color: isCompleted ? Colors.white : Colors.grey))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(child: TextField(
                  controller: _weightCtrl,
                  decoration: const InputDecoration(labelText: 'kg', isDense: true),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  enabled: !isCompleted,
                )),
                const SizedBox(width: 8),
                Expanded(child: TextField(
                  controller: _repsCtrl,
                  decoration: const InputDecoration(labelText: 'reps', isDense: true),
                  keyboardType: TextInputType.number,
                  enabled: !isCompleted,
                )),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!isCompleted)
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: AppTheme.primary),
              onPressed: () {
                widget.onComplete(
                  double.tryParse(_weightCtrl.text),
                  int.tryParse(_repsCtrl.text),
                );
              },
            )
          else
            const Icon(Icons.check_circle, color: AppTheme.primary),
        ],
      ),
    );
  }
}
