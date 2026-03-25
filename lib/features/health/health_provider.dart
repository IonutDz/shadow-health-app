import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

const _baseUrl = 'https://shadow-health-api.onrender.com';

class CardioSession {
  final String id;
  final String type; // walking, running, cycling, free
  final int? steps;
  final int? distance; // meters
  final int? calories;
  final int? totalMinutes;
  final int? avgHeartRate;
  final int? maxHeartRate;
  final String time;
  final String notes;

  const CardioSession({
    required this.id,
    required this.type,
    this.steps,
    this.distance,
    this.calories,
    this.totalMinutes,
    this.avgHeartRate,
    this.maxHeartRate,
    required this.time,
    required this.notes,
  });

  factory CardioSession.fromJson(Map<String, dynamic> j) => CardioSession(
        id: j['id'] ?? '',
        type: j['type'] ?? 'walking',
        steps: (j['steps'] as num?)?.toInt(),
        distance: (j['distance'] as num?)?.toInt(),
        calories: (j['calories'] as num?)?.toInt(),
        totalMinutes: (j['totalMinutes'] as num?)?.toInt(),
        avgHeartRate: (j['avgHeartRate'] as num?)?.toInt(),
        maxHeartRate: (j['maxHeartRate'] as num?)?.toInt(),
        time: j['time'] ?? '',
        notes: j['notes'] ?? '',
      );
}

class HeartRateEntry {
  final String id;
  final int bpm;
  final String time;
  final String context; // workout, rest, cardio, general

  const HeartRateEntry({
    required this.id,
    required this.bpm,
    required this.time,
    required this.context,
  });

  factory HeartRateEntry.fromJson(Map<String, dynamic> j) => HeartRateEntry(
        id: j['id'] ?? '',
        bpm: (j['bpm'] as num?)?.toInt() ?? 0,
        time: j['time'] ?? '',
        context: j['context'] ?? 'general',
      );
}

class SleepLog {
  final String id;
  final String date;
  final String sleepStart;
  final String sleepEnd;
  final int totalMinutes;
  final int deepMinutes;
  final int lightMinutes;
  final int remMinutes;
  final int awakeMinutes;
  final int quality;
  final int? avgHeartRate;
  final int? minHeartRate;
  final String notes;

  const SleepLog({
    required this.id,
    required this.date,
    required this.sleepStart,
    required this.sleepEnd,
    required this.totalMinutes,
    required this.deepMinutes,
    required this.lightMinutes,
    required this.remMinutes,
    required this.awakeMinutes,
    required this.quality,
    this.avgHeartRate,
    this.minHeartRate,
    required this.notes,
  });

  factory SleepLog.fromJson(Map<String, dynamic> j) => SleepLog(
        id: j['id'] ?? '',
        date: j['date'] ?? '',
        sleepStart: j['sleepStart'] ?? '23:00',
        sleepEnd: j['sleepEnd'] ?? '07:00',
        totalMinutes: (j['totalMinutes'] as num?)?.toInt() ?? 0,
        deepMinutes: (j['deepMinutes'] as num?)?.toInt() ?? 0,
        lightMinutes: (j['lightMinutes'] as num?)?.toInt() ?? 0,
        remMinutes: (j['remMinutes'] as num?)?.toInt() ?? 0,
        awakeMinutes: (j['awakeMinutes'] as num?)?.toInt() ?? 0,
        quality: (j['quality'] as num?)?.toInt() ?? 5,
        avgHeartRate: (j['avgHeartRate'] as num?)?.toInt(),
        minHeartRate: (j['minHeartRate'] as num?)?.toInt(),
        notes: j['notes'] ?? '',
      );

  String get formattedDuration {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

class Device {
  final String id;
  final String name;
  final String type;
  final bool isActive;

  const Device({
    required this.id,
    required this.name,
    required this.type,
    required this.isActive,
  });

  factory Device.fromJson(Map<String, dynamic> j) => Device(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        type: j['type'] ?? 'smartwatch',
        isActive: j['isActive'] ?? false,
      );
}

class HealthState {
  final bool isLoading;
  final String? error;
  final List<CardioSession> cardioSessions;
  final List<HeartRateEntry> heartRateEntries;
  final List<SleepLog> sleepLogs;
  final List<Device> devices;
  final int stepsGoal;

  const HealthState({
    this.isLoading = false,
    this.error,
    this.cardioSessions = const [],
    this.heartRateEntries = const [],
    this.sleepLogs = const [],
    this.devices = const [],
    this.stepsGoal = 10000,
  });

  HealthState copyWith({
    bool? isLoading,
    String? error,
    List<CardioSession>? cardioSessions,
    List<HeartRateEntry>? heartRateEntries,
    List<SleepLog>? sleepLogs,
    List<Device>? devices,
    int? stepsGoal,
  }) =>
      HealthState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        cardioSessions: cardioSessions ?? this.cardioSessions,
        heartRateEntries: heartRateEntries ?? this.heartRateEntries,
        sleepLogs: sleepLogs ?? this.sleepLogs,
        devices: devices ?? this.devices,
        stepsGoal: stepsGoal ?? this.stepsGoal,
      );

  int get todaySteps => cardioSessions.fold(0, (sum, s) => sum + (s.steps ?? 0));
  int get stepsProgress => stepsGoal == 0 ? 0 : (todaySteps * 100 ~/ stepsGoal).clamp(0, 100);

  int get todayCardioCalories => cardioSessions.fold(0, (sum, s) => sum + (s.calories ?? 0));
  int get todayCardioMinutes => cardioSessions.fold(0, (sum, s) => sum + (s.totalMinutes ?? 0));

  SleepLog? get latestSleep => sleepLogs.isNotEmpty ? sleepLogs.first : null;
  String get sleepHoursFormatted {
    if (latestSleep == null) return '--';
    return latestSleep!.formattedDuration;
  }

  int get currentHeartRate => heartRateEntries.isNotEmpty ? heartRateEntries.last.bpm : 0;
  int get restingHeartRate {
    final restEntries = heartRateEntries.where((e) => e.context == 'rest');
    if (restEntries.isEmpty) return 0;
    return (restEntries.fold(0, (s, e) => s + e.bpm) / restEntries.length).round();
  }

  int get minHeartRate {
    if (heartRateEntries.isEmpty) return 0;
    return heartRateEntries.map((e) => e.bpm).reduce((a, b) => a < b ? a : b);
  }

  int get maxHeartRate {
    if (heartRateEntries.isEmpty) return 0;
    return heartRateEntries.map((e) => e.bpm).reduce((a, b) => a > b ? a : b);
  }
}

class HealthNotifier extends StateNotifier<HealthState> {
  HealthNotifier() : super(const HealthState());

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
        _dio.get('/api/cardio', queryParameters: {'date': today}),
        _dio.get('/api/heart-rate', queryParameters: {'date': today}),
        _dio.get('/api/sleep', queryParameters: {'limit': 14}),
        _dio.get('/api/devices'),
      ]);
      state = state.copyWith(
        isLoading: false,
        cardioSessions: (results[0].data as List).map((c) => CardioSession.fromJson(c as Map<String, dynamic>)).toList(),
        heartRateEntries: (results[1].data as List).map((h) => HeartRateEntry.fromJson(h as Map<String, dynamic>)).toList(),
        sleepLogs: (results[2].data as List).map((s) => SleepLog.fromJson(s as Map<String, dynamic>)).toList(),
        devices: (results[3].data as List).map((d) => Device.fromJson(d as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addCardioSession({
    required String type,
    int? steps,
    int? distance,
    int? calories,
    int? totalMinutes,
    int? avgHeartRate,
    int? maxHeartRate,
    String? time,
    String notes = '',
  }) async {
    try {
      final r = await _dio.post('/api/cardio', data: {
        'type': type,
        if (steps != null) 'steps': steps,
        if (distance != null) 'distance': distance,
        if (calories != null) 'calories': calories,
        if (totalMinutes != null) 'totalMinutes': totalMinutes,
        if (avgHeartRate != null) 'avgHeartRate': avgHeartRate,
        if (maxHeartRate != null) 'maxHeartRate': maxHeartRate,
        'time': time ?? _timeNow(),
        'notes': notes,
        'date': _todayIso(),
      });
      final session = CardioSession.fromJson(r.data as Map<String, dynamic>);
      state = state.copyWith(cardioSessions: [...state.cardioSessions, session]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> addHeartRate({required int bpm, String context = 'general'}) async {
    try {
      final r = await _dio.post('/api/heart-rate', data: {
        'bpm': bpm,
        'context': context,
        'time': _timeNow(),
        'date': _todayIso(),
      });
      final entry = HeartRateEntry.fromJson(r.data as Map<String, dynamic>);
      state = state.copyWith(heartRateEntries: [...state.heartRateEntries, entry]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> addSleepLog({
    required String date,
    required String sleepStart,
    required String sleepEnd,
    required int deepMinutes,
    required int lightMinutes,
    required int remMinutes,
    required int awakeMinutes,
    required int quality,
    int? avgHeartRate,
    int? minHeartRate,
    String notes = '',
  }) async {
    try {
      final total = deepMinutes + lightMinutes + remMinutes + awakeMinutes;
      final r = await _dio.post('/api/sleep', data: {
        'date': date,
        'sleepStart': sleepStart,
        'sleepEnd': sleepEnd,
        'totalMinutes': total,
        'deepMinutes': deepMinutes,
        'lightMinutes': lightMinutes,
        'remMinutes': remMinutes,
        'awakeMinutes': awakeMinutes,
        'quality': quality,
        if (avgHeartRate != null) 'avgHeartRate': avgHeartRate,
        if (minHeartRate != null) 'minHeartRate': minHeartRate,
        'notes': notes,
      });
      final log = SleepLog.fromJson(r.data as Map<String, dynamic>);
      state = state.copyWith(sleepLogs: [log, ...state.sleepLogs]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> addDevice({required String name, required String type}) async {
    try {
      final r = await _dio.post('/api/devices', data: {
        'name': name,
        'type': type,
        'isActive': false,
      });
      final device = Device.fromJson(r.data as Map<String, dynamic>);
      state = state.copyWith(devices: [...state.devices, device]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> removeCardioSession(String id) async {
    try {
      await _dio.delete('/api/cardio/$id');
      state = state.copyWith(cardioSessions: state.cardioSessions.where((c) => c.id != id).toList());
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  String _timeNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

final healthProvider = StateNotifierProvider<HealthNotifier, HealthState>((ref) {
  final notifier = HealthNotifier();
  notifier.init();
  return notifier;
});
