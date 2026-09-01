/// Crop Model
/// Represents a crop type with its growing requirements
class CropModel {
  final String id;
  final String cropName;
  final String? cropImage;
  final String varietyName;
  final int plantDuration;
  final String plantDurationUnit;
  final double harvestingWeight;
  final String company;
  final double sproutingRatio;
  final double ecLevelMin;
  final double ecLevelMax;
  final double phLevelMin;
  final double phLevelMax;
  final double tempMin;
  final double tempMax;
  final double humidityMin;
  final double humidityMax;
  final double? lightHoursMin;
  final double? lightHoursMax;
  final double? co2LevelMin;
  final double? co2LevelMax;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CropModel({
    required this.id,
    required this.cropName,
    this.cropImage,
    required this.varietyName,
    required this.plantDuration,
    this.plantDurationUnit = 'days',
    required this.harvestingWeight,
    required this.company,
    required this.sproutingRatio,
    required this.ecLevelMin,
    required this.ecLevelMax,
    required this.phLevelMin,
    required this.phLevelMax,
    required this.tempMin,
    required this.tempMax,
    required this.humidityMin,
    required this.humidityMax,
    this.lightHoursMin,
    this.lightHoursMax,
    this.co2LevelMin,
    this.co2LevelMax,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create CropModel from JSON
  factory CropModel.fromJson(Map<String, dynamic> json) {
    final duration = _durationFromJson(json);
    return CropModel(
      id: json['id'] as String? ?? json['\$id'] as String,
      cropName: json['crop_name'] as String,
      cropImage: json['crop_image'] as String?,
      varietyName: json['variety_name'] as String,
      plantDuration: duration.value,
      plantDurationUnit: duration.unit,
      harvestingWeight: (json['harvesting_weight'] as num).toDouble(),
      company: json['company'] as String,
      sproutingRatio: (json['sprouting_ratio'] as num).toDouble(),
      ecLevelMin: (json['ec_level_min'] as num).toDouble(),
      ecLevelMax: (json['ec_level_max'] as num).toDouble(),
      phLevelMin: (json['ph_level_min'] as num).toDouble(),
      phLevelMax: (json['ph_level_max'] as num).toDouble(),
      tempMin: (json['temp_min'] as num).toDouble(),
      tempMax: (json['temp_max'] as num).toDouble(),
      humidityMin: (json['humidity_min'] as num).toDouble(),
      humidityMax: (json['humidity_max'] as num).toDouble(),
      lightHoursMin: json['light_hours_min'] != null
          ? (json['light_hours_min'] as num).toDouble()
          : null,
      lightHoursMax: json['light_hours_max'] != null
          ? (json['light_hours_max'] as num).toDouble()
          : null,
      co2LevelMin: json['co2_level_min'] != null
          ? (json['co2_level_min'] as num).toDouble()
          : null,
      co2LevelMax: json['co2_level_max'] != null
          ? (json['co2_level_max'] as num).toDouble()
          : null,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert CropModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crop_name': cropName,
      if (cropImage != null) 'crop_image': cropImage,
      'variety_name': varietyName,
      'plant_duration_value': plantDuration,
      'plant_duration_unit': plantDurationUnit,
      'harvesting_weight': harvestingWeight,
      'company': company,
      'sprouting_ratio': sproutingRatio,
      'ec_level_min': ecLevelMin,
      'ec_level_max': ecLevelMax,
      'ph_level_min': phLevelMin,
      'ph_level_max': phLevelMax,
      'temp_min': tempMin,
      'temp_max': tempMax,
      'humidity_min': humidityMin,
      'humidity_max': humidityMax,
      if (lightHoursMin != null) 'light_hours_min': lightHoursMin,
      if (lightHoursMax != null) 'light_hours_max': lightHoursMax,
      if (co2LevelMin != null) 'co2_level_min': co2LevelMin,
      if (co2LevelMax != null) 'co2_level_max': co2LevelMax,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  CropModel copyWith({
    String? id,
    String? cropName,
    String? cropImage,
    String? varietyName,
    int? plantDuration,
    String? plantDurationUnit,
    double? harvestingWeight,
    String? company,
    double? sproutingRatio,
    double? ecLevelMin,
    double? ecLevelMax,
    double? phLevelMin,
    double? phLevelMax,
    double? tempMin,
    double? tempMax,
    double? humidityMin,
    double? humidityMax,
    double? lightHoursMin,
    double? lightHoursMax,
    double? co2LevelMin,
    double? co2LevelMax,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CropModel(
      id: id ?? this.id,
      cropName: cropName ?? this.cropName,
      cropImage: cropImage ?? this.cropImage,
      varietyName: varietyName ?? this.varietyName,
      plantDuration: plantDuration ?? this.plantDuration,
      plantDurationUnit: plantDurationUnit ?? this.plantDurationUnit,
      harvestingWeight: harvestingWeight ?? this.harvestingWeight,
      company: company ?? this.company,
      sproutingRatio: sproutingRatio ?? this.sproutingRatio,
      ecLevelMin: ecLevelMin ?? this.ecLevelMin,
      ecLevelMax: ecLevelMax ?? this.ecLevelMax,
      phLevelMin: phLevelMin ?? this.phLevelMin,
      phLevelMax: phLevelMax ?? this.phLevelMax,
      tempMin: tempMin ?? this.tempMin,
      tempMax: tempMax ?? this.tempMax,
      humidityMin: humidityMin ?? this.humidityMin,
      humidityMax: humidityMax ?? this.humidityMax,
      lightHoursMin: lightHoursMin ?? this.lightHoursMin,
      lightHoursMax: lightHoursMax ?? this.lightHoursMax,
      co2LevelMin: co2LevelMin ?? this.co2LevelMin,
      co2LevelMax: co2LevelMax ?? this.co2LevelMax,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get full crop name with variety
  String get fullName => '$cropName - $varietyName';

  /// Get estimated harvest date from planting date
  DateTime getEstimatedHarvestDate(DateTime plantingDate) {
    if (plantDurationUnit != 'months') {
      return plantingDate.add(Duration(days: plantDuration));
    }
    final targetMonth = DateTime(
      plantingDate.year,
      plantingDate.month + plantDuration,
      1,
    );
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    final day = plantingDate.day > lastDay ? lastDay : plantingDate.day;
    return DateTime(targetMonth.year, targetMonth.month, day);
  }

  /// Check if sensor value is within optimal range
  bool isOptimalValue(String sensorType, double value) {
    switch (sensorType.toLowerCase()) {
      case 'temperature':
        return value >= tempMin && value <= tempMax;
      case 'humidity':
        return value >= humidityMin && value <= humidityMax;
      case 'ph':
        return value >= phLevelMin && value <= phLevelMax;
      case 'ec':
        return value >= ecLevelMin && value <= ecLevelMax;
      case 'co2':
        if (co2LevelMin != null && co2LevelMax != null) {
          return value >= co2LevelMin! && value <= co2LevelMax!;
        }
        return true;
      default:
        return true;
    }
  }

  @override
  String toString() {
    return 'CropModel(name: $fullName, duration: $plantDuration $plantDurationUnit, company: $company)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CropModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

({int value, String unit}) _durationFromJson(Map<String, dynamic> json) {
  final rawValue = json['plant_duration_value'];
  final parsedValue = rawValue is num
      ? rawValue.toInt()
      : int.tryParse(rawValue?.toString() ?? '');
  final unit = (json['plant_duration_unit'] ?? '').toString().toLowerCase();
  if (parsedValue != null &&
      parsedValue > 0 &&
      (unit == 'days' || unit == 'months')) {
    return (value: parsedValue, unit: unit);
  }
  return (value: 0, unit: 'days');
}
