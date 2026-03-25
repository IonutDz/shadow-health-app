import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

const _baseUrl = 'https://shadow-health-api.onrender.com';

class BodyMeasurement {
  final String region;
  final double value;
  final String label;

  const BodyMeasurement({required this.region, required this.value, required this.label});

  factory BodyMeasurement.fromJson(Map<String, dynamic> j) => BodyMeasurement(
        region: j['region'] ?? '',
        value: (j['value'] as num?)?.toDouble() ?? 0,
        label: j['label'] ?? j['region'] ?? '',
      );

  Map<String, dynamic> toJson() => {'region': region, 'value': value, 'label': label};
}

class ProgressPhoto {
  final String id;
  final String angle;
  final String imageUrl;
  final String date;

  const ProgressPhoto({
    required this.id,
    required this.angle,
    required this.imageUrl,
    required this.date,
  });

  factory ProgressPhoto.fromJson(Map<String, dynamic> j) => ProgressPhoto(
        id: j['id'] ?? '',
        angle: j['angle'] ?? 'front',
        imageUrl: j['imageUrl'] ?? '',
        date: j['date'] ?? '',
      );
}

class BodyCheck {
  final String id;
  final String date;
  final double? weight;
  final double? bodyFat;
  final List<BodyMeasurement> measurements;
  final List<ProgressPhoto> photos;
  final String notes;

  const BodyCheck({
    required this.id,
    required this.date,
    this.weight,
    this.bodyFat,
    required this.measurements,
    required this.photos,
    required this.notes,
  });

  factory BodyCheck.fromJson(Map<String, dynamic> j) => BodyCheck(
        id: j['id'] ?? '',
        date: j['date'] ?? '',
        weight: (j['weight'] as num?)?.toDouble(),
        bodyFat: (j['bodyFat'] as num?)?.toDouble(),
        measurements: (j['measurements'] as List? ?? [])
            .map((m) => BodyMeasurement.fromJson(m as Map<String, dynamic>))
            .toList(),
        photos: (j['photos'] as List? ?? [])
            .map((p) => ProgressPhoto.fromJson(p as Map<String, dynamic>))
            .toList(),
        notes: j['notes'] ?? '',
      );
}

class BodyState {
  final bool isLoading;
  final String? error;
  final List<BodyCheck> bodyChecks;

  const BodyState({
    this.isLoading = false,
    this.error,
    this.bodyChecks = const [],
  });

  BodyState copyWith({bool? isLoading, String? error, List<BodyCheck>? bodyChecks}) => BodyState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        bodyChecks: bodyChecks ?? this.bodyChecks,
      );

  BodyCheck? get latestCheck => bodyChecks.isNotEmpty ? bodyChecks.first : null;
  BodyCheck? get previousCheck => bodyChecks.length > 1 ? bodyChecks[1] : null;

  List<Map<String, dynamic>> get weightHistory => bodyChecks.reversed
      .where((c) => c.weight != null)
      .map((c) => {'date': c.date, 'value': c.weight!})
      .toList();

  List<Map<String, dynamic>> get bodyFatHistory => bodyChecks.reversed
      .where((c) => c.bodyFat != null)
      .map((c) => {'date': c.date, 'value': c.bodyFat!})
      .toList();

  double? get weightDiff {
    if (latestCheck?.weight == null || previousCheck?.weight == null) return null;
    return double.parse((latestCheck!.weight! - previousCheck!.weight!).toStringAsFixed(1));
  }

  double? get bodyFatDiff {
    if (latestCheck?.bodyFat == null || previousCheck?.bodyFat == null) return null;
    return double.parse((latestCheck!.bodyFat! - previousCheck!.bodyFat!).toStringAsFixed(1));
  }
}

class BodyNotifier extends StateNotifier<BodyState> {
  BodyNotifier() : super(const BodyState());

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
    await fetchBodyChecks();
  }

  Future<void> fetchBodyChecks() async {
    state = state.copyWith(isLoading: true);
    try {
      final r = await _dio.get('/api/body-checks');
      state = state.copyWith(
        isLoading: false,
        bodyChecks: (r.data as List).map((c) => BodyCheck.fromJson(c as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addBodyCheck({
    required String date,
    double? weight,
    double? bodyFat,
    List<Map<String, dynamic>>? measurements,
    String notes = '',
  }) async {
    try {
      final r = await _dio.post('/api/body-checks', data: {
        'date': date,
        if (weight != null) 'weight': weight,
        if (bodyFat != null) 'bodyFat': bodyFat,
        if (measurements != null) 'measurements': measurements,
        'notes': notes,
      });
      final check = BodyCheck.fromJson(r.data as Map<String, dynamic>);
      state = state.copyWith(bodyChecks: [check, ...state.bodyChecks]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> deleteBodyCheck(String id) async {
    try {
      await _dio.delete('/api/body-checks/$id');
      state = state.copyWith(bodyChecks: state.bodyChecks.where((c) => c.id != id).toList());
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final bodyProvider = StateNotifierProvider<BodyNotifier, BodyState>((ref) {
  final notifier = BodyNotifier();
  notifier.init();
  return notifier;
});

// Measurement regions definition
const measurementRegions = [
  {'region': 'shoulders', 'label': 'Hombros'},
  {'region': 'neck', 'label': 'Cuello'},
  {'region': 'chest', 'label': 'Pecho'},
  {'region': 'left_arm', 'label': 'Brazo Izq'},
  {'region': 'right_arm', 'label': 'Brazo Der'},
  {'region': 'waist', 'label': 'Cintura'},
  {'region': 'hips', 'label': 'Cadera'},
  {'region': 'left_leg', 'label': 'Pierna Izq'},
  {'region': 'right_leg', 'label': 'Pierna Der'},
];
