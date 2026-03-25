import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/models/workout.dart';
import '../auth/auth_provider.dart';

// Active workout state
class ActiveWorkoutState {
  final WorkoutSession? session;
  final int currentExerciseIndex;
  final bool isResting;
  final int restTimeRemaining;
  final bool isLoading;
  final String? error;

  const ActiveWorkoutState({
    this.session,
    this.currentExerciseIndex = 0,
    this.isResting = false,
    this.restTimeRemaining = 0,
    this.isLoading = false,
    this.error,
  });

  ActiveWorkoutState copyWith({
    WorkoutSession? session,
    int? currentExerciseIndex,
    bool? isResting,
    int? restTimeRemaining,
    bool? isLoading,
    String? error,
  }) => ActiveWorkoutState(
    session: session ?? this.session,
    currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
    isResting: isResting ?? this.isResting,
    restTimeRemaining: restTimeRemaining ?? this.restTimeRemaining,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );

  WorkoutExercise? get currentExercise {
    if (session == null || session!.exercises.isEmpty) return null;
    if (currentExerciseIndex >= session!.exercises.length) return null;
    return session!.exercises[currentExerciseIndex];
  }
}

class WorkoutNotifier extends StateNotifier<ActiveWorkoutState> {
  final ApiClient _api;

  WorkoutNotifier(this._api) : super(const ActiveWorkoutState());

  Future<void> startWorkout(String name, {String? routineId, String? date}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.post(ApiEndpoints.workouts, data: {
        'name': name,
        if (routineId != null) 'routineId': routineId,
        if (date != null) 'date': date,
      });
      final session = WorkoutSession.fromJson(response.data as Map<String, dynamic>);
      state = state.copyWith(session: session, isLoading: false, currentExerciseIndex: 0);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> completeSet(int exerciseIdx, int setIdx, {double? weight, int? reps}) async {
    if (state.session == null) return;
    final exercise = state.session!.exercises[exerciseIdx];
    final set = exercise.sets[setIdx];
    final sessionId = state.session!.id;

    try {
      await _api.put(ApiEndpoints.workoutSet(sessionId, set.id), data: {
        'weight': weight,
        'reps': reps,
        'isCompleted': true,
      });

      // Update local state
      final updatedSet = set.copyWith(weight: weight, reps: reps, isCompleted: true, completedAt: DateTime.now().toIso8601String());
      final updatedSets = List<WorkoutSet>.from(exercise.sets)..[setIdx] = updatedSet;
      final updatedExercise = WorkoutExercise(
        id: exercise.id, name: exercise.name,
        routineExerciseId: exercise.routineExerciseId,
        sortOrder: exercise.sortOrder, restTime: exercise.restTime,
        sets: updatedSets,
      );
      final updatedExercises = List<WorkoutExercise>.from(state.session!.exercises)..[exerciseIdx] = updatedExercise;
      final updatedSession = WorkoutSession(
        id: state.session!.id, name: state.session!.name,
        routineId: state.session!.routineId,
        startedAt: state.session!.startedAt,
        exercises: updatedExercises,
        completedSets: state.session!.completedSets + 1,
      );

      state = state.copyWith(session: updatedSession, isResting: true, restTimeRemaining: exercise.restTime);
    } catch (e) {
      // Ignore sync errors for now
    }
  }

  Future<void> finishWorkout({String? notes}) async {
    if (state.session == null) return;
    final id = state.session!.id;
    final now = DateTime.now().toIso8601String();
    final totalMs = DateTime.now().millisecondsSinceEpoch -
        DateTime.parse(state.session!.startedAt).millisecondsSinceEpoch;

    try {
      await _api.put(ApiEndpoints.workoutById(id), data: {
        'finishedAt': now,
        'totalTimeMs': totalMs,
        if (notes != null) 'notes': notes,
      });
    } catch (_) {}

    state = const ActiveWorkoutState();
  }

  Future<void> discardWorkout() async {
    if (state.session == null) return;
    final id = state.session!.id;
    state = const ActiveWorkoutState();
    try {
      await _api.delete(ApiEndpoints.workoutById(id));
    } catch (_) {}
  }

  void nextExercise() {
    if (state.session == null) return;
    if (state.currentExerciseIndex < state.session!.exercises.length - 1) {
      state = state.copyWith(
        currentExerciseIndex: state.currentExerciseIndex + 1,
        isResting: false,
        restTimeRemaining: 0,
      );
    }
  }

  void prevExercise() {
    if (state.currentExerciseIndex > 0) {
      state = state.copyWith(currentExerciseIndex: state.currentExerciseIndex - 1);
    }
  }

  void stopRest() {
    state = state.copyWith(isResting: false, restTimeRemaining: 0);
  }
}

// History
final workoutHistoryProvider = FutureProvider.autoDispose<List<WorkoutSession>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get(ApiEndpoints.workouts, params: {'limit': '20'});
  return (response.data as List).map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>)).toList();
});

final activeWorkoutProvider = StateNotifierProvider<WorkoutNotifier, ActiveWorkoutState>((ref) {
  return WorkoutNotifier(ref.watch(apiClientProvider));
});
