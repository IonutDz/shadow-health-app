class WorkoutSet {
  final String id;
  final int setNumber;
  final double? weight;
  final int? reps;
  final bool isCompleted;
  final String? completedAt;
  final double? rpe;
  final String? notes;
  final int? avgHeartRate;
  final int? maxHeartRate;
  final int? restAvgHeartRate;

  WorkoutSet({
    required this.id,
    required this.setNumber,
    this.weight,
    this.reps,
    required this.isCompleted,
    this.completedAt,
    this.rpe,
    this.notes,
    this.avgHeartRate,
    this.maxHeartRate,
    this.restAvgHeartRate,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
    id: json['id'] as String,
    setNumber: json['setNumber'] as int,
    weight: (json['weight'] as num?)?.toDouble(),
    reps: json['reps'] as int?,
    isCompleted: json['isCompleted'] as bool? ?? false,
    completedAt: json['completedAt'] as String?,
    rpe: (json['rpe'] as num?)?.toDouble(),
    notes: json['notes'] as String?,
    avgHeartRate: json['avgHeartRate'] as int?,
    maxHeartRate: json['maxHeartRate'] as int?,
    restAvgHeartRate: json['restAvgHeartRate'] as int?,
  );

  WorkoutSet copyWith({
    double? weight, int? reps, bool? isCompleted, String? completedAt,
    double? rpe, String? notes, int? avgHeartRate, int? maxHeartRate, int? restAvgHeartRate,
  }) => WorkoutSet(
    id: id, setNumber: setNumber,
    weight: weight ?? this.weight,
    reps: reps ?? this.reps,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt ?? this.completedAt,
    rpe: rpe ?? this.rpe,
    notes: notes ?? this.notes,
    avgHeartRate: avgHeartRate ?? this.avgHeartRate,
    maxHeartRate: maxHeartRate ?? this.maxHeartRate,
    restAvgHeartRate: restAvgHeartRate ?? this.restAvgHeartRate,
  );
}

class WorkoutExercise {
  final String id;
  final String name;
  final String? routineExerciseId;
  final int sortOrder;
  final int restTime;
  final List<WorkoutSet> sets;
  final int? avgHeartRate;
  final int? maxHeartRate;

  WorkoutExercise({
    required this.id,
    required this.name,
    this.routineExerciseId,
    required this.sortOrder,
    required this.restTime,
    required this.sets,
    this.avgHeartRate,
    this.maxHeartRate,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) => WorkoutExercise(
    id: json['id'] as String,
    name: json['name'] as String,
    routineExerciseId: json['routineExerciseId'] as String?,
    sortOrder: json['sortOrder'] as int? ?? 0,
    restTime: json['restTime'] as int? ?? 90,
    sets: (json['sets'] as List<dynamic>? ?? []).map((s) => WorkoutSet.fromJson(s as Map<String, dynamic>)).toList(),
    avgHeartRate: json['avgHeartRate'] as int?,
    maxHeartRate: json['maxHeartRate'] as int?,
  );
}

class WorkoutSession {
  final String id;
  final String name;
  final String? routineId;
  final String startedAt;
  final String? finishedAt;
  final int? totalTimeMs;
  final String? notes;
  final List<WorkoutExercise> exercises;
  final int completedSets;

  WorkoutSession({
    required this.id,
    required this.name,
    this.routineId,
    required this.startedAt,
    this.finishedAt,
    this.totalTimeMs,
    this.notes,
    required this.exercises,
    required this.completedSets,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    id: json['id'] as String,
    name: json['name'] as String,
    routineId: json['routineId'] as String?,
    startedAt: json['startedAt'] as String,
    finishedAt: json['finishedAt'] as String?,
    totalTimeMs: json['totalTimeMs'] as int?,
    notes: json['notes'] as String?,
    exercises: (json['exercises'] as List<dynamic>? ?? []).map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>)).toList(),
    completedSets: json['completedSets'] as int? ?? 0,
  );
}
