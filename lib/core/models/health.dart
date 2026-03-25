class CardioSession {
  final String id;
  final String type;
  final int? steps;
  final double? distance;
  final int? calories;
  final int? totalMinutes;
  final int? avgHeartRate;
  final int? maxHeartRate;
  final String time;
  final String notes;

  CardioSession({
    required this.id, required this.type, this.steps, this.distance,
    this.calories, this.totalMinutes, this.avgHeartRate, this.maxHeartRate,
    required this.time, required this.notes,
  });

  factory CardioSession.fromJson(Map<String, dynamic> json) => CardioSession(
    id: json['id'] as String,
    type: json['type'] as String,
    steps: json['steps'] as int?,
    distance: (json['distance'] as num?)?.toDouble(),
    calories: json['calories'] as int?,
    totalMinutes: json['totalMinutes'] as int?,
    avgHeartRate: json['avgHeartRate'] as int?,
    maxHeartRate: json['maxHeartRate'] as int?,
    time: json['time'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
  );
}

class SleepLog {
  final String id;
  final String date;
  final String? sleepStart;
  final String? sleepEnd;
  final int totalMinutes;
  final int deepMinutes;
  final int lightMinutes;
  final int remMinutes;
  final int awakeMinutes;
  final int quality;
  final int? avgHeartRate;
  final int? minHeartRate;
  final String notes;

  SleepLog({
    required this.id, required this.date, this.sleepStart, this.sleepEnd,
    required this.totalMinutes, required this.deepMinutes, required this.lightMinutes,
    required this.remMinutes, required this.awakeMinutes, required this.quality,
    this.avgHeartRate, this.minHeartRate, required this.notes,
  });

  factory SleepLog.fromJson(Map<String, dynamic> json) => SleepLog(
    id: json['id'] as String,
    date: json['date'] as String,
    sleepStart: json['sleepStart'] as String?,
    sleepEnd: json['sleepEnd'] as String?,
    totalMinutes: json['totalMinutes'] as int? ?? 0,
    deepMinutes: json['deepMinutes'] as int? ?? 0,
    lightMinutes: json['lightMinutes'] as int? ?? 0,
    remMinutes: json['remMinutes'] as int? ?? 0,
    awakeMinutes: json['awakeMinutes'] as int? ?? 0,
    quality: json['quality'] as int? ?? 0,
    avgHeartRate: json['avgHeartRate'] as int?,
    minHeartRate: json['minHeartRate'] as int?,
    notes: json['notes'] as String? ?? '',
  );
}

class HeartRateEntry {
  final String id;
  final int bpm;
  final String time;
  final String context;

  HeartRateEntry({required this.id, required this.bpm, required this.time, required this.context});

  factory HeartRateEntry.fromJson(Map<String, dynamic> json) => HeartRateEntry(
    id: json['id'] as String,
    bpm: json['bpm'] as int,
    time: json['time'] as String,
    context: json['context'] as String? ?? 'general',
  );
}

class BodyCheck {
  final String id;
  final String date;
  final double? weight;
  final double? bodyFat;
  final String? notes;
  final List<BodyMeasurement> measurements;
  final List<ProgressPhoto> photos;

  BodyCheck({
    required this.id, required this.date, this.weight, this.bodyFat,
    this.notes, required this.measurements, required this.photos,
  });

  factory BodyCheck.fromJson(Map<String, dynamic> json) => BodyCheck(
    id: json['id'] as String,
    date: json['date'] is String ? json['date'] as String : (json['date'] as String),
    weight: (json['weight'] as num?)?.toDouble(),
    bodyFat: (json['bodyFat'] as num?)?.toDouble(),
    notes: json['notes'] as String?,
    measurements: (json['measurements'] as List<dynamic>? ?? [])
        .map((m) => BodyMeasurement.fromJson(m as Map<String, dynamic>)).toList(),
    photos: (json['photos'] as List<dynamic>? ?? [])
        .map((p) => ProgressPhoto.fromJson(p as Map<String, dynamic>)).toList(),
  );
}

class BodyMeasurement {
  final String region;
  final double value;

  BodyMeasurement({required this.region, required this.value});

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) => BodyMeasurement(
    region: json['region'] as String,
    value: (json['value'] as num).toDouble(),
  );
}

class ProgressPhoto {
  final String id;
  final String angle;
  final String imageUrl;

  ProgressPhoto({required this.id, required this.angle, required this.imageUrl});

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) => ProgressPhoto(
    id: json['id'] as String,
    angle: json['angle'] as String,
    imageUrl: json['imageUrl'] as String,
  );
}
