import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

const _baseUrl = 'https://shadow-health-api.onrender.com';

// ── Models ──────────────────────────────────────────────────────────────────

class Meal {
  final String id;
  final String name;
  final String type; // desayuno, almuerzo, cena, snack
  final String time;
  final String imageUrl;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String notes;

  const Meal({
    required this.id,
    required this.name,
    required this.type,
    required this.time,
    required this.imageUrl,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    required this.notes,
  });

  factory Meal.fromJson(Map<String, dynamic> j) => Meal(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        type: j['type'] ?? 'desayuno',
        time: j['time'] ?? '',
        imageUrl: j['imageUrl'] ?? '',
        calories: (j['calories'] as num?)?.toDouble(),
        protein: (j['protein'] as num?)?.toDouble(),
        carbs: (j['carbs'] as num?)?.toDouble(),
        fat: (j['fat'] as num?)?.toDouble(),
        notes: j['notes'] ?? '',
      );
}

class HydrationEntry {
  final String id;
  final int amount; // ml
  final String time;

  const HydrationEntry({required this.id, required this.amount, required this.time});

  factory HydrationEntry.fromJson(Map<String, dynamic> j) => HydrationEntry(
        id: j['id'] ?? '',
        amount: (j['amount'] as num?)?.toInt() ?? 250,
        time: j['time'] ?? '',
      );
}

class Supplement {
  final String id;
  final String name;
  final String dosage;
  final String schedule;
  final String frequency;
  bool isActive;

  Supplement({
    required this.id,
    required this.name,
    required this.dosage,
    required this.schedule,
    required this.frequency,
    required this.isActive,
  });

  factory Supplement.fromJson(Map<String, dynamic> j) => Supplement(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        dosage: j['dosage'] ?? '',
        schedule: j['schedule'] ?? 'anytime',
        frequency: j['frequency'] ?? 'diario',
        isActive: j['isActive'] ?? true,
      );
}

class SupplementLog {
  final String supplementId;
  final bool taken;
  final String? takenAt;

  const SupplementLog({
    required this.supplementId,
    required this.taken,
    this.takenAt,
  });

  factory SupplementLog.fromJson(Map<String, dynamic> j) => SupplementLog(
        supplementId: j['supplementId'] ?? '',
        taken: j['taken'] ?? false,
        takenAt: j['takenAt'],
      );
}

// ── State ─────────────────────────────────────────────────────────────────────

class NutritionState {
  final bool isLoading;
  final String? error;
  final List<Meal> meals;
  final List<HydrationEntry> hydrationEntries;
  final double hydrationGoal; // liters
  final List<Supplement> supplements;
  final List<SupplementLog> supplementLogs;

  const NutritionState({
    this.isLoading = false,
    this.error,
    this.meals = const [],
    this.hydrationEntries = const [],
    this.hydrationGoal = 2.5,
    this.supplements = const [],
    this.supplementLogs = const [],
  });

  NutritionState copyWith({
    bool? isLoading,
    String? error,
    List<Meal>? meals,
    List<HydrationEntry>? hydrationEntries,
    double? hydrationGoal,
    List<Supplement>? supplements,
    List<SupplementLog>? supplementLogs,
  }) =>
      NutritionState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        meals: meals ?? this.meals,
        hydrationEntries: hydrationEntries ?? this.hydrationEntries,
        hydrationGoal: hydrationGoal ?? this.hydrationGoal,
        supplements: supplements ?? this.supplements,
        supplementLogs: supplementLogs ?? this.supplementLogs,
      );

  double get totalCalories => meals.fold(0, (sum, m) => sum + (m.calories ?? 0));
  double get totalProtein => meals.fold(0, (sum, m) => sum + (m.protein ?? 0));
  double get totalCarbs => meals.fold(0, (sum, m) => sum + (m.carbs ?? 0));
  double get totalFat => meals.fold(0, (sum, m) => sum + (m.fat ?? 0));

  double get waterLiters => hydrationEntries.fold(0, (sum, h) => sum + h.amount) / 1000.0;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class NutritionNotifier extends StateNotifier<NutritionState> {
  NutritionNotifier() : super(const NutritionState());

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

  String _todayIso() => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true);
    final today = _todayIso();
    try {
      final results = await Future.wait([
        _dio.get('/api/meals', queryParameters: {'date': today}),
        _dio.get('/api/hydration', queryParameters: {'date': today}),
        _dio.get('/api/supplements'),
        _dio.get('/api/supplement-logs', queryParameters: {'date': today}),
      ]);
      state = state.copyWith(
        isLoading: false,
        meals: (results[0].data as List).map((m) => Meal.fromJson(m as Map<String, dynamic>)).toList(),
        hydrationEntries: (results[1].data as List).map((h) => HydrationEntry.fromJson(h as Map<String, dynamic>)).toList(),
        supplements: (results[2].data as List).map((s) => Supplement.fromJson(s as Map<String, dynamic>)).toList(),
        supplementLogs: (results[3].data as List).map((l) => SupplementLog.fromJson(l as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addMeal({
    required String name,
    required String type,
    required String time,
    String imageUrl = '',
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String notes = '',
  }) async {
    try {
      final r = await _dio.post('/api/meals', data: {
        'name': name,
        'type': type,
        'time': time,
        'imageUrl': imageUrl,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'notes': notes,
        'date': _todayIso(),
      });
      final meal = Meal.fromJson(r.data as Map<String, dynamic>);
      state = state.copyWith(meals: [...state.meals, meal]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> removeMeal(String id) async {
    try {
      await _dio.delete('/api/meals/$id');
      state = state.copyWith(meals: state.meals.where((m) => m.id != id).toList());
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addWater({int amount = 250}) async {
    try {
      final r = await _dio.post('/api/hydration', data: {
        'amount': amount,
        'time': _timeNow(),
        'date': _todayIso(),
      });
      final entry = HydrationEntry.fromJson(r.data as Map<String, dynamic>);
      state = state.copyWith(hydrationEntries: [...state.hydrationEntries, entry]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeLastWater() async {
    if (state.hydrationEntries.isEmpty) return;
    final last = state.hydrationEntries.last;
    try {
      await _dio.delete('/api/hydration/${last.id}');
      state = state.copyWith(
        hydrationEntries: state.hydrationEntries.where((h) => h.id != last.id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> addSupplement({required String name, required String dosage, required String schedule, String frequency = 'diario'}) async {
    try {
      final r = await _dio.post('/api/supplements', data: {
        'name': name,
        'dosage': dosage,
        'schedule': schedule,
        'frequency': frequency,
        'isActive': true,
      });
      final sup = Supplement.fromJson(r.data as Map<String, dynamic>);
      state = state.copyWith(supplements: [...state.supplements, sup]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> toggleSupplement(String supplementId) async {
    try {
      final log = state.supplementLogs.where((l) => l.supplementId == supplementId).firstOrNull;
      if (log?.taken == true) {
        // Can't untake easily, just reload
      } else {
        final r = await _dio.post('/api/supplements/$supplementId/log', data: {
          'taken': true,
          'takenAt': _timeNow(),
          'date': _todayIso(),
        });
        final newLog = SupplementLog.fromJson(r.data as Map<String, dynamic>);
        final updatedLogs = [
          ...state.supplementLogs.where((l) => l.supplementId != supplementId),
          newLog,
        ];
        state = state.copyWith(supplementLogs: updatedLogs);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  String _timeNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

final nutritionProvider = StateNotifierProvider<NutritionNotifier, NutritionState>((ref) {
  final notifier = NutritionNotifier();
  notifier.init();
  return notifier;
});

// Labels
const supplementScheduleLabels = {
  'morning': 'Por la mañana',
  'pre-workout': 'Pre-entreno',
  'post-workout': 'Post-entreno',
  'night': 'Por la noche',
  'anytime': 'En cualquier momento',
  'with-breakfast': 'Con el desayuno',
  'with-lunch': 'Con el almuerzo',
  'with-dinner': 'Con la cena',
  'with-snack': 'Con el snack',
};

const supplementPresets = [
  {'name': 'Whey Protein', 'dosage': '30g (1 scoop)', 'schedule': 'post-workout', 'category': 'proteina'},
  {'name': 'Caseina', 'dosage': '30g', 'schedule': 'night', 'category': 'proteina'},
  {'name': 'Creatina Monohidrato', 'dosage': '5g', 'schedule': 'anytime', 'category': 'creatina'},
  {'name': 'Vitamina D3', 'dosage': '2000 UI', 'schedule': 'with-breakfast', 'category': 'vitaminas'},
  {'name': 'Omega 3', 'dosage': '1000mg', 'schedule': 'with-lunch', 'category': 'vitaminas'},
  {'name': 'Multivitaminico', 'dosage': '1 comprimido', 'schedule': 'with-breakfast', 'category': 'vitaminas'},
  {'name': 'Magnesio', 'dosage': '400mg', 'schedule': 'night', 'category': 'vitaminas'},
  {'name': 'BCAA', 'dosage': '5g', 'schedule': 'pre-workout', 'category': 'aminoacidos'},
  {'name': 'Glutamina', 'dosage': '5g', 'schedule': 'post-workout', 'category': 'aminoacidos'},
  {'name': 'Beta-Alanina', 'dosage': '3.2g', 'schedule': 'pre-workout', 'category': 'aminoacidos'},
  {'name': 'Cafeina', 'dosage': '200mg', 'schedule': 'pre-workout', 'category': 'otros'},
  {'name': 'Ashwagandha', 'dosage': '600mg', 'schedule': 'night', 'category': 'otros'},
];
