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
