import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

const _baseUrl = 'https://shadow-health-api.onrender.com';

// ── Models ──────────────────────────────────────────────────────────────────

class Machine {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<Map<String, dynamic>> muscles;

  const Machine({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.muscles,
  });

  factory Machine.fromJson(Map<String, dynamic> j) => Machine(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        description: j['description'] ?? '',
        imageUrl: j['imageUrl'] ?? '',
        muscles: (j['muscles'] as List? ?? []).cast<Map<String, dynamic>>(),
      );
}

class Gym {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String? address;
  final double? latitude;
  final double? longitude;
  final List<Machine> machines;

  const Gym({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.address,
    this.latitude,
    this.longitude,
    required this.machines,
  });

  factory Gym.fromJson(Map<String, dynamic> j) => Gym(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        description: j['description'] ?? '',
        imageUrl: j['imageUrl'] ?? '',
        address: j['address'],
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        machines: (j['machines'] as List? ?? [])
            .map((m) => Machine.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

class RoutineExercise {
  final String id;
  final String? machineId;
  final String name;
  final int defaultSets;
  final int? defaultReps;
  final double? defaultWeight;
  final int defaultRestTime;
  final int sortOrder;
  final String? notes;

  const RoutineExercise({
    required this.id,
    this.machineId,
    required this.name,
    required this.defaultSets,
    this.defaultReps,
    this.defaultWeight,
    required this.defaultRestTime,
    required this.sortOrder,
    this.notes,
  });

  factory RoutineExercise.fromJson(Map<String, dynamic> j) => RoutineExercise(
        id: j['id'] ?? '',
        machineId: j['machineId'],
        name: j['name'] ?? '',
        defaultSets: (j['defaultSets'] as num?)?.toInt() ?? 3,
        defaultReps: (j['defaultReps'] as num?)?.toInt(),
        defaultWeight: (j['defaultWeight'] as num?)?.toDouble(),
        defaultRestTime: (j['defaultRestTime'] as num?)?.toInt() ?? 90,
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
        notes: j['notes'],
      );
}

class Routine {
  final String id;
  final String name;
  final int dayOfWeek;
  final List<RoutineExercise> exercises;

  const Routine({
    required this.id,
    required this.name,
    required this.dayOfWeek,
    required this.exercises,
  });

  factory Routine.fromJson(Map<String, dynamic> j) => Routine(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        dayOfWeek: (j['dayOfWeek'] as num?)?.toInt() ?? 0,
        exercises: (j['exercises'] as List? ?? [])
            .map((e) => RoutineExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Planning {
  final String id;
  final String name;
  final String? gymId;
  final bool isActive;
  final List<Routine> routines;
  final Map<String, dynamic> enabledModules;
  final Map<String, dynamic> nutritionConfig;

  const Planning({
    required this.id,
    required this.name,
    this.gymId,
    required this.isActive,
    required this.routines,
    required this.enabledModules,
    required this.nutritionConfig,
  });

  factory Planning.fromJson(Map<String, dynamic> j) => Planning(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        gymId: j['gymId'],
        isActive: j['isActive'] ?? false,
        routines: (j['routines'] as List? ?? [])
            .map((r) => Routine.fromJson(r as Map<String, dynamic>))
            .toList(),
        enabledModules: (j['enabledModules'] as Map<String, dynamic>?) ?? {},
        nutritionConfig: (j['nutritionConfig'] as Map<String, dynamic>?) ?? {},
      );
}

class WorkoutSet {
  final String id;
  final int setNumber;
  final double? weight;
  final int? reps;
  bool isCompleted;
  String? completedAt;
  final int? rpe;
  final String? notes;

  WorkoutSet({
    required this.id,
    required this.setNumber,
    this.weight,
    this.reps,
    required this.isCompleted,
    this.completedAt,
    this.rpe,
    this.notes,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> j) => WorkoutSet(
        id: j['id'] ?? '',
        setNumber: (j['setNumber'] as num?)?.toInt() ?? 1,
        weight: (j['weight'] as num?)?.toDouble(),
        reps: (j['reps'] as num?)?.toInt(),
        isCompleted: j['isCompleted'] ?? false,
        completedAt: j['completedAt'],
        rpe: (j['rpe'] as num?)?.toInt(),
        notes: j['notes'],
      );

  WorkoutSet copyWith({double? weight, int? reps, bool? isCompleted, String? completedAt}) {
    return WorkoutSet(
      id: id,
      setNumber: setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      rpe: rpe,
      notes: notes,
    );
  }
}

class LiveExercise {
  final String id;
  final String name;
  final String? routineExerciseId;
  final String? machineName;
  final String? muscleGroups;
  final int restTime;
  final int sortOrder;
  final List<String> targetReps;
  final List<String> targetRir;
  final List<String> planningNotes;
  List<WorkoutSet> sets;

  LiveExercise({
    required this.id,
    required this.name,
    this.routineExerciseId,
    this.machineName,
    this.muscleGroups,
    required this.restTime,
    required this.sortOrder,
    required this.targetReps,
    required this.targetRir,
    required this.planningNotes,
    required this.sets,
  });

  factory LiveExercise.fromJson(Map<String, dynamic> j) {
    final re = j['routineExercise'] as Map<String, dynamic>?;
    final machine = re?['machine'] as Map<String, dynamic>?;
    final setCount = (j['sets'] as List?)?.length ?? 0;

    return LiveExercise(
      id: j['id'] ?? '',
      name: j['name'] ?? '',
      routineExerciseId: j['routineExerciseId'],
      machineName: machine?['name'],
      muscleGroups: (machine?['muscleTags'] as List?)
          ?.map((m) => (m as Map)['muscleGroup']?['name'] as String?)
          .where((n) => n != null)
          .join(', '),
      restTime: (j['restTime'] as num?)?.toInt() ?? 90,
      sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
      targetReps: _parseTaggedSeries(re?['notes'], 'OBJETIVO_REPS', setCount),
      targetRir: _parseTaggedSeries(re?['notes'], 'OBJETIVO_RIR', setCount),
      planningNotes: _parsePlanningNotes(re?['notes']),
      sets: (j['sets'] as List? ?? [])
          .map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  static List<String> _parseTaggedSeries(String? notes, String tag, int setCount) {
    if (notes == null) return List.filled(setCount, '');
    final match = RegExp('$tag:\\s*([^|]+)', caseSensitive: false).firstMatch(notes);
    if (match == null) return List.filled(setCount, '');
    final parts = match.group(1)!.split('/').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (setCount == 0) return parts;
    return List.generate(setCount, (i) => i < parts.length ? parts[i] : (parts.isNotEmpty ? parts.last : ''));
  }

  static List<String> _parsePlanningNotes(String? notes) {
    if (notes == null) return [];
    return notes
        .split('|')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .where((p) => !RegExp(r'^OBJETIVO_REPS:', caseSensitive: false).hasMatch(p))
        .where((p) => !RegExp(r'^OBJETIVO_RIR:', caseSensitive: false).hasMatch(p))
        .toList();
  }
}

class ActiveWorkout {
  final String id;
  final String name;
  final String? routineId;
  final DateTime startedAt;
  List<LiveExercise> exercises;
  int currentExerciseIndex;

  ActiveWorkout({
    required this.id,
    required this.name,
    this.routineId,
    required this.startedAt,
    required this.exercises,
    this.currentExerciseIndex = 0,
  });

  factory ActiveWorkout.fromJson(Map<String, dynamic> j) => ActiveWorkout(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        routineId: j['routineId'],
        startedAt: DateTime.tryParse(j['startedAt'] ?? '') ?? DateTime.now(),
        exercises: (j['exercises'] as List? ?? [])
            .map((e) => LiveExercise.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      );
}

class WorkoutHistoryItem {
  final String id;
  final String name;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int? totalTimeMs;
  final String? notes;
  final int exerciseCount;
  final int completedSets;

  const WorkoutHistoryItem({
    required this.id,
    required this.name,
    required this.startedAt,
    this.finishedAt,
    this.totalTimeMs,
    this.notes,
    required this.exerciseCount,
    required this.completedSets,
  });

  factory WorkoutHistoryItem.fromJson(Map<String, dynamic> j) => WorkoutHistoryItem(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        startedAt: DateTime.tryParse(j['startedAt'] ?? '') ?? DateTime.now(),
        finishedAt: j['finishedAt'] != null ? DateTime.tryParse(j['finishedAt']) : null,
        totalTimeMs: (j['totalTimeMs'] as num?)?.toInt(),
        notes: j['notes'],
        exerciseCount: (j['_count']?['exercises'] as num?)?.toInt() ?? 0,
        completedSets: (j['completedSets'] as num?)?.toInt() ?? 0,
      );
}

// ── State ─────────────────────────────────────────────────────────────────────

class WorkoutState {
  final bool isLoading;
  final String? error;
  final List<Gym> gyms;
  final List<Planning> plannings;
  final List<WorkoutHistoryItem> history;
  final ActiveWorkout? activeWorkout;
  final bool isResting;
  final int restTimeRemaining;
  final bool initialized;

  const WorkoutState({
    this.isLoading = false,
    this.error,
    this.gyms = const [],
    this.plannings = const [],
    this.history = const [],
    this.activeWorkout,
    this.isResting = false,
    this.restTimeRemaining = 0,
    this.initialized = false,
  });

  WorkoutState copyWith({
    bool? isLoading,
    String? error,
    List<Gym>? gyms,
    List<Planning>? plannings,
    List<WorkoutHistoryItem>? history,
    ActiveWorkout? activeWorkout,
    bool clearWorkout = false,
    bool? isResting,
    int? restTimeRemaining,
    bool? initialized,
  }) =>
      WorkoutState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        gyms: gyms ?? this.gyms,
        plannings: plannings ?? this.plannings,
        history: history ?? this.history,
        activeWorkout: clearWorkout ? null : (activeWorkout ?? this.activeWorkout),
        isResting: isResting ?? this.isResting,
        restTimeRemaining: restTimeRemaining ?? this.restTimeRemaining,
        initialized: initialized ?? this.initialized,
      );

  Planning? get activePlanning => plannings.where((p) => p.isActive).firstOrNull;

  Routine? get todayRoutine {
    final ap = activePlanning;
    if (ap == null) return null;
    final dow = _todayDayIndex();
    return ap.routines.where((r) => r.dayOfWeek == dow).firstOrNull;
  }

  Routine? routineForDate(DateTime date) {
    final ap = activePlanning;
    if (ap == null) return null;
    final dow = _dayIndex(date);
    return ap.routines.where((r) => r.dayOfWeek == dow).firstOrNull;
  }

  static int _todayDayIndex() => _dayIndex(DateTime.now());

  static int _dayIndex(DateTime date) {
    final d = date.weekday; // 1=Mon, 7=Sun
    return d - 1; // 0=Mon, 6=Sun
  }

  int get weekTotal => activePlanning?.routines.length ?? 0;

  int weekProgress() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final monday = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return history
        .where((w) => w.finishedAt != null && w.startedAt.isAfter(monday))
        .length;
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class WorkoutNotifier extends StateNotifier<WorkoutState> {
  WorkoutNotifier() : super(const WorkoutState());

  late final Dio _dio;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ));
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    await fetchAll();
  }

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _dio.get('/api/gyms'),
        _dio.get('/api/plannings'),
        _dio.get('/api/workouts', queryParameters: {'limit': 50}),
      ]);
      state = state.copyWith(
        isLoading: false,
        gyms: (results[0].data as List).map((g) => Gym.fromJson(g as Map<String, dynamic>)).toList(),
        plannings: (results[1].data as List).map((p) => Planning.fromJson(p as Map<String, dynamic>)).toList(),
        history: (results[2].data as List).map((w) => WorkoutHistoryItem.fromJson(w as Map<String, dynamic>)).toList(),
        initialized: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), initialized: true);
    }
  }

  Future<void> fetchHistory() async {
    try {
      final r = await _dio.get('/api/workouts', queryParameters: {'limit': 50});
      state = state.copyWith(
        history: (r.data as List).map((w) => WorkoutHistoryItem.fromJson(w as Map<String, dynamic>)).toList(),
      );
    } catch (_) {}
  }

  // Start a new workout session
  Future<ActiveWorkout?> startWorkout({String? routineId, String? date}) async {
    try {
      final body = <String, dynamic>{
        'name': 'Entrenamiento',
        if (routineId != null) 'routineId': routineId,
        if (date != null) 'date': date,
      };
      final r = await _dio.post('/api/workouts', data: body);
      final workout = ActiveWorkout.fromJson(r.data as Map<String, dynamic>);
      state = state.copyWith(activeWorkout: workout);
      return workout;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Load an existing workout session
  Future<ActiveWorkout?> loadWorkout(String workoutId) async {
    try {
      final r = await _dio.get('/api/workouts/$workoutId');
      final workout = ActiveWorkout.fromJson(r.data as Map<String, dynamic>);
      state = state.copyWith(activeWorkout: workout);
      return workout;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> finishWorkout(String workoutId, {String? notes}) async {
    try {
      await _dio.put('/api/workouts/$workoutId', data: {
        'finishedAt': DateTime.now().toIso8601String(),
        if (notes != null) 'notes': notes,
      });
      state = state.copyWith(clearWorkout: true);
      await fetchHistory();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<WorkoutSet?> updateSet(String workoutId, String exerciseId, String setId, {double? weight, int? reps, bool? isCompleted}) async {
    try {
      final body = <String, dynamic>{
        if (weight != null) 'weight': weight,
        if (reps != null) 'reps': reps,
        if (isCompleted != null) 'isCompleted': isCompleted,
        if (isCompleted == true) 'completedAt': DateTime.now().toIso8601String(),
      };
      final r = await _dio.put('/api/workouts/$workoutId/sets/$setId', data: body);
      // Update local state
      final aw = state.activeWorkout;
      if (aw != null) {
        for (final ex in aw.exercises) {
          final setIdx = ex.sets.indexWhere((s) => s.id == setId);
          if (setIdx != -1) {
            ex.sets[setIdx] = WorkoutSet.fromJson(r.data as Map<String, dynamic>);
            break;
          }
        }
        state = state.copyWith(activeWorkout: aw);
      }
      return WorkoutSet.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<void> addGym({required String name, String? description, String? address, double? lat, double? lng}) async {
    try {
      final r = await _dio.post('/api/gyms', data: {
        'name': name,
        'description': description ?? '',
        'address': address ?? '',
        if (lat != null) 'latitude': lat,
        if (lng != null) 'longitude': lng,
      });
      final gym = Gym.fromJson(r.data as Map<String, dynamic>);
      state = state.copyWith(gyms: [...state.gyms, gym]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addPlanning({required String name}) async {
    try {
      final r = await _dio.post('/api/plannings', data: {'name': name, 'isActive': false});
      final p = Planning.fromJson(r.data as Map<String, dynamic>);
      state = state.copyWith(plannings: [...state.plannings, p]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> setActivePlanning(String planningId) async {
    try {
      await _dio.put('/api/plannings/$planningId', data: {'isActive': true});
      final updated = state.plannings.map((p) => Planning(
            id: p.id,
            name: p.name,
            gymId: p.gymId,
            isActive: p.id == planningId,
            routines: p.routines,
            enabledModules: p.enabledModules,
            nutritionConfig: p.nutritionConfig,
          )).toList();
      state = state.copyWith(plannings: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addRoutine(String planningId, {required String name, required int dayOfWeek}) async {
    try {
      final r = await _dio.post('/api/routines', data: {
        'planningId': planningId,
        'name': name,
        'dayOfWeek': dayOfWeek,
      });
      final routine = Routine.fromJson(r.data as Map<String, dynamic>);
      final updated = state.plannings.map((p) {
        if (p.id != planningId) return p;
        return Planning(
          id: p.id,
          name: p.name,
          gymId: p.gymId,
          isActive: p.isActive,
          routines: [...p.routines, routine],
          enabledModules: p.enabledModules,
          nutritionConfig: p.nutritionConfig,
        );
      }).toList();
      state = state.copyWith(plannings: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setCurrentExercise(int index) {
    final aw = state.activeWorkout;
    if (aw == null) return;
    aw.currentExerciseIndex = index;
    state = state.copyWith(activeWorkout: aw);
  }
}

final workoutProvider = StateNotifierProvider<WorkoutNotifier, WorkoutState>((ref) {
  final notifier = WorkoutNotifier();
  notifier.init();
  return notifier;
});
