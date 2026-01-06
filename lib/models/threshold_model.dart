/// Threshold Model
/// Represents sensor thresholds for a farm
class ThresholdModel {
  final String id;
  final String farmId;
  final double temperatureMax;
  final double temperatureMin;
  final double phMin;
  final double phMax;
  final double ecMax;
  final double? humidityMax;
  final double? humidityMin;
  final double? co2Min;
  final double? co2Max;
  final double? lightMin;
  final double? lightMax;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ThresholdModel({
    required this.id,
    required this.farmId,
    required this.temperatureMax,
    required this.temperatureMin,
    required this.phMin,
    required this.phMax,
    required this.ecMax,
    this.humidityMax,
    this.humidityMin,
    this.co2Min,
    this.co2Max,
    this.lightMin,
    this.lightMax,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create ThresholdModel from JSON
  factory ThresholdModel.fromJson(Map<String, dynamic> json) {
    return ThresholdModel(
      id: json['id'] as String? ?? json['\$id'] as String,
      farmId: json['farmID'] as String,
      temperatureMax: (json['temperature_max'] as num).toDouble(),
      temperatureMin: (json['temperature_min'] as num).toDouble(),
      phMin: (json['ph_min'] as num).toDouble(),
      phMax: (json['ph_max'] as num).toDouble(),
      ecMax: (json['ec_max'] as num).toDouble(),
      humidityMax: json['humidity_max'] != null
          ? (json['humidity_max'] as num).toDouble()
          : null,
      humidityMin: json['humidity_min'] != null
          ? (json['humidity_min'] as num).toDouble()
          : null,
      co2Min: json['co2_min'] != null ? (json['co2_min'] as num).toDouble() : null,
      co2Max: json['co2_max'] != null ? (json['co2_max'] as num).toDouble() : null,
      lightMin:
          json['light_min'] != null ? (json['light_min'] as num).toDouble() : null,
      lightMax:
          json['light_max'] != null ? (json['light_max'] as num).toDouble() : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert ThresholdModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmID': farmId,
      'temperature_max': temperatureMax,
      'temperature_min': temperatureMin,
      'ph_min': phMin,
      'ph_max': phMax,
      'ec_max': ecMax,
      if (humidityMax != null) 'humidity_max': humidityMax,
      if (humidityMin != null) 'humidity_min': humidityMin,
      if (co2Min != null) 'co2_min': co2Min,
      if (co2Max != null) 'co2_max': co2Max,
      if (lightMin != null) 'light_min': lightMin,
      if (lightMax != null) 'light_max': lightMax,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  ThresholdModel copyWith({
    String? id,
    String? farmId,
    double? temperatureMax,
    double? temperatureMin,
    double? phMin,
    double? phMax,
    double? ecMax,
    double? humidityMax,
    double? humidityMin,
    double? co2Min,
    double? co2Max,
    double? lightMin,
    double? lightMax,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ThresholdModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      temperatureMax: temperatureMax ?? this.temperatureMax,
      temperatureMin: temperatureMin ?? this.temperatureMin,
      phMin: phMin ?? this.phMin,
      phMax: phMax ?? this.phMax,
      ecMax: ecMax ?? this.ecMax,
      humidityMax: humidityMax ?? this.humidityMax,
      humidityMin: humidityMin ?? this.humidityMin,
      co2Min: co2Min ?? this.co2Min,
      co2Max: co2Max ?? this.co2Max,
      lightMin: lightMin ?? this.lightMin,
      lightMax: lightMax ?? this.lightMax,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if a value is within threshold range
  bool isWithinRange(String sensorType, double value) {
    switch (sensorType.toLowerCase()) {
      case 'temperature':
        return value >= temperatureMin && value <= temperatureMax;
      case 'ph':
        return value >= phMin && value <= phMax;
      case 'ec':
        return value <= ecMax;
      case 'humidity':
        if (humidityMin != null && humidityMax != null) {
          return value >= humidityMin! && value <= humidityMax!;
        }
        return true;
      case 'co2':
        if (co2Min != null && co2Max != null) {
          return value >= co2Min! && value <= co2Max!;
        }
        return true;
      case 'light':
        if (lightMin != null && lightMax != null) {
          return value >= lightMin! && value <= lightMax!;
        }
        return true;
      default:
        return true;
    }
  }

  @override
  String toString() {
    return 'ThresholdModel(farmId: $farmId, temp: $temperatureMin-$temperatureMax°C, pH: $phMin-$phMax)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThresholdModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
