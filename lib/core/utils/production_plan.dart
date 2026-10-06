import 'dart:convert';

Map<String, dynamic> productionPlan(Object? value) {
  try {
    final decoded = value is String ? jsonDecode(value) : value;
    return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
  } catch (_) {
    return {};
  }
}

List<Map<String, dynamic>> productionStages(Object? value) =>
    (productionPlan(value)['stages'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

int productionDays(Object? value) => productionStages(value)
    .fold(0, (sum, stage) => sum + ((stage['days'] as num?)?.toInt() ?? 0));

({int value, String unit}) productionDuration(Object? value) {
  final days = productionDays(value);
  if (days > 0) return (value: days, unit: 'days');
  final plan = productionPlan(value);
  return (
    value: (plan['maturity_value'] as num? ?? 0).toInt(),
    unit: '${plan['maturity_unit'] ?? 'days'}'
  );
}

DateTime productionHarvest(Object? value, DateTime start) {
  final duration = productionDuration(value);
  if (duration.unit == 'months') {
    final month = DateTime(start.year, start.month + duration.value, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    return DateTime(month.year, month.month, start.day.clamp(1, lastDay));
  }
  return calendarAdd(
      start, duration.value * (duration.unit == 'weeks' ? 7 : 1));
}

DateTime calendarAdd(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

List<Map<String, dynamic>> productionSchedule(Object? value, DateTime start) {
  var cursor = start;
  return productionStages(value).map((stage) {
    final end = calendarAdd(cursor, (stage['days'] as num).toInt());
    final item = {...stage, 'start': cursor, 'end': end};
    cursor = end;
    return item;
  }).toList();
}

class RecordGrowthStage {
  const RecordGrowthStage(
      {this.name, required this.message, this.invalidDate = false});
  final String? name;
  final String message;
  final bool invalidDate;
}

RecordGrowthStage recordGrowthStage(
    Object? planValue, Object? startValue, DateTime recordDate) {
  final raw = startValue?.toString() ?? '';
  final start = DateTime.tryParse(raw);
  if (start == null)
    return const RecordGrowthStage(
        message: 'Set a valid batch start date to calculate its stage.',
        invalidDate: true);
  // UTC calendar dates avoid daylight-saving changes affecting elapsed day counts.
  final first = DateTime.utc(start.year, start.month, start.day);
  final day = DateTime.utc(recordDate.year, recordDate.month, recordDate.day);
  final elapsed = day.difference(first).inDays;
  if (elapsed < 0)
    return const RecordGrowthStage(
        message: 'The record date is before this batch starts.',
        invalidDate: true);
  final rawStages = productionPlan(planValue)['stages'];
  if (rawStages is! List || rawStages.isEmpty)
    return const RecordGrowthStage(
        message:
            'No custom growth stages are configured. Ask an admin to configure the plant type growth plan.');
  var boundary = 0;
  String? lastName;
  for (final rawStage in rawStages) {
    if (rawStage is! Map ||
        rawStage['name'] is! String ||
        (rawStage['name'] as String).trim().isEmpty ||
        rawStage['days'] is! int ||
        (rawStage['days'] as int) <= 0) {
      return const RecordGrowthStage(
          message:
              'The growth plan has an invalid stage duration. Ask an admin to correct it.');
    }
    lastName = (rawStage['name'] as String).trim();
    boundary += rawStage['days'] as int;
    if (elapsed < boundary)
      return RecordGrowthStage(
          name: lastName,
          message:
              'Day ${elapsed + 1} of this batch. Calculated for the selected record date.');
  }
  return RecordGrowthStage(
      name: lastName,
      message:
          'Day ${elapsed + 1}. The planned cycle has ended; the final stage remains until production is completed.');
}
