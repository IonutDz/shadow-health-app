class Meal {
  final String id;
  final String name;
  final String type; // desayuno, almuerzo, cena, snack
  final String time; // HH:mm
  final String? imageUrl;
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String? notes;

  Meal({
    required this.id, required this.name, required this.type,
    required this.time, this.imageUrl, this.calories, this.protein,
    this.carbs, this.fat, this.notes,
  });

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String? ?? 'almuerzo',
    time: json['time'] as String,
    imageUrl: json['imageUrl'] as String?,
    calories: json['calories'] as int?,
    protein: (json['protein'] as num?)?.toDouble(),
    carbs: (json['carbs'] as num?)?.toDouble(),
    fat: (json['fat'] as num?)?.toDouble(),
    notes: json['notes'] as String?,
  );
}

class HydrationEntry {
  final String id;
  final int amount; // ml
  final String time; // HH:mm

  HydrationEntry({required this.id, required this.amount, required this.time});

  factory HydrationEntry.fromJson(Map<String, dynamic> json) => HydrationEntry(
    id: json['id'] as String,
    amount: json['amount'] as int,
    time: json['time'] as String,
  );
}

class Supplement {
  final String id;
  final String name;
  final String? dosage;
  final String? schedule;
  final String frequency;
  final bool isActive;

  Supplement({
    required this.id, required this.name, this.dosage,
    this.schedule, required this.frequency, required this.isActive,
  });

  factory Supplement.fromJson(Map<String, dynamic> json) => Supplement(
    id: json['id'] as String,
    name: json['name'] as String,
    dosage: json['dosage'] as String?,
    schedule: json['schedule'] as String?,
    frequency: json['frequency'] as String? ?? 'mensual',
    isActive: json['isActive'] as bool? ?? true,
  );
}

class SupplementLog {
  final String supplementId;
  final bool taken;
  final String? takenAt;

  SupplementLog({required this.supplementId, required this.taken, this.takenAt});

  factory SupplementLog.fromJson(Map<String, dynamic> json) => SupplementLog(
    supplementId: json['supplementId'] as String,
    taken: json['taken'] as bool? ?? false,
    takenAt: json['takenAt'] as String?,
  );
}
