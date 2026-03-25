class RoutineExercise {
  final String id;
  final String name;
  final String? machineId;
  final int defaultSets;
  final int? defaultReps;
  final double? defaultWeight;
  final int defaultRestTime;
  final int sortOrder;
  final String? notes;

  RoutineExercise({
    required this.id, required this.name, this.machineId,
    required this.defaultSets, this.defaultReps, this.defaultWeight,
    required this.defaultRestTime, required this.sortOrder, this.notes,
  });

  factory RoutineExercise.fromJson(Map<String, dynamic> json) => RoutineExercise(
    id: json['id'] as String,
    name: json['name'] as String,
    machineId: json['machineId'] as String?,
    defaultSets: json['defaultSets'] as int? ?? 4,
    defaultReps: json['defaultReps'] as int?,
    defaultWeight: (json['defaultWeight'] as num?)?.toDouble(),
    defaultRestTime: json['defaultRestTime'] as int? ?? 90,
    sortOrder: json['sortOrder'] as int? ?? 0,
    notes: json['notes'] as String?,
  );
}

class Routine {
  final String id;
  final String name;
  final int dayOfWeek;
  final int weekNumber;
  final int sortOrder;
  final List<RoutineExercise> exercises;

  Routine({
    required this.id, required this.name, required this.dayOfWeek,
    required this.weekNumber, required this.sortOrder, required this.exercises,
  });

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
    id: json['id'] as String,
    name: json['name'] as String,
    dayOfWeek: json['dayOfWeek'] as int? ?? 0,
    weekNumber: json['weekNumber'] as int? ?? 1,
    sortOrder: json['sortOrder'] as int? ?? 0,
    exercises: (json['exercises'] as List<dynamic>? ?? [])
        .map((e) => RoutineExercise.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

class Planning {
  final String id;
  final String name;
  final bool isActive;
  final int weekCount;
  final String? gymId;
  final List<Routine> routines;
  final Map<String, bool> enabledModules;
  final Map<String, dynamic> nutritionConfig;

  Planning({
    required this.id, required this.name, required this.isActive,
    required this.weekCount, this.gymId, required this.routines,
    required this.enabledModules, required this.nutritionConfig,
  });

  factory Planning.fromJson(Map<String, dynamic> json) => Planning(
    id: json['id'] as String,
    name: json['name'] as String,
    isActive: json['isActive'] as bool? ?? false,
    weekCount: json['weekCount'] as int? ?? 1,
    gymId: json['gymId'] as String?,
    routines: (json['routines'] as List<dynamic>? ?? [])
        .map((r) => Routine.fromJson(r as Map<String, dynamic>)).toList(),
    enabledModules: (json['enabledModules'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, v as bool? ?? true),
    ),
    nutritionConfig: json['nutritionConfig'] as Map<String, dynamic>? ?? {},
  );
}
