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
