/// Inclusive good range for historical readings, using current sensor settings.
class SensorThresholds {
  SensorThresholds(Map<String, dynamic> sensor, String readingUnit)
      : minimum = _number(sensor['range_min']),
        maximum = _number(sensor['range_max']),
        matchingUnit = '${sensor['unit'] ?? ''}'.trim() == readingUnit.trim();
  final double? minimum, maximum;
  final bool matchingUnit;
  static double? _number(dynamic raw) {
    final value = double.tryParse('$raw');
    return value != null && value.isFinite ? value : null;
  }

  bool get valid =>
      matchingUnit &&
      minimum != null &&
      maximum != null &&
      minimum! <= maximum!;
  bool get hasNormal => valid;
  String classify(double value) {
    if (!valid || !value.isFinite) return 'Unrated';
    return value >= minimum! && value <= maximum! ? 'Good' : 'Bad';
  }

  String get normalLabel =>
      valid ? 'Good: $minimum – $maximum' : 'Good range not configured';
}
