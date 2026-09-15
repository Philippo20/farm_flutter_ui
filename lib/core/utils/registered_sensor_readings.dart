String sensorText(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    final text = row[key]?.toString().trim() ?? '';
    if (text.isNotEmpty && text != 'null') return text;
  }
  return '';
}

String registeredSensorType(Map<String, dynamic> sensor) {
  final raw = sensorText(sensor, ['sensortype', 'sensor_type', 'type'])
      .toLowerCase()
      .replaceAll(' ', '_')
      .replaceAll('-', '_');
  return const {
        'temp': 'temperature',
        'humid': 'humidity',
        'water_temp': 'water_temperature'
      }[raw] ??
      raw;
}

double? registeredReadingValue(Map<String, dynamic> row) {
  final value = double.tryParse(
      sensorText(row, ['value', 'last_value', 'current_value', 'reading']));
  return value != null && value.isFinite ? value : null;
}

DateTime? registeredReadingTime(Map<String, dynamic> row) => DateTime.tryParse(
    sensorText(row, ['timestamp', 'last_reading_at', 'last_seen']))?.toUtc();

/// Match by registered identity, never by sensor type or farm alone.
List<Map<String, dynamic>> readingsForRegisteredSensor(
    Map<String, dynamic> sensor, List<Map<String, dynamic>> readings) {
  final id = sensorText(sensor, [r'$id', 'sensor_id', 'id']);
  final serial = sensorText(sensor, ['serial_number']);
  final unit = sensorText(sensor, ['unit', 'measurement_unit']);
  final matched = readings.where((row) {
    final rowId = sensorText(row, ['sensor_id']);
    final rowSerial = sensorText(row, ['serial_number']);
    final matches = rowId.isNotEmpty && id.isNotEmpty
        ? rowId == id
        : serial.isNotEmpty && rowSerial == serial;
    final rowUnit = sensorText(row, ['unit', 'measurement_unit']);
    return matches &&
        registeredReadingValue(row) != null &&
        registeredReadingTime(row) != null &&
        (rowUnit.isEmpty || unit.isEmpty || unit == rowUnit);
  }).toList()
    ..sort((a, b) =>
        registeredReadingTime(a)!.compareTo(registeredReadingTime(b)!));
  final snapshotAt = registeredReadingTime(sensor);
  if (registeredReadingValue(sensor) != null &&
      snapshotAt != null &&
      (matched.isEmpty ||
          snapshotAt.isAfter(registeredReadingTime(matched.last)!)))
    matched.add(sensor);
  return matched;
}

/// A compact live chart shows the newest continuous activity, not a line
/// interpolated across outages. History remains untouched in the source list.
List<Map<String, dynamic>> latestSensorActivity(List<Map<String, dynamic>> rows) {
  final byTime = <int, Map<String, dynamic>>{};
  for (final row in rows) {
    final at = registeredReadingTime(row);
    if (at != null && registeredReadingValue(row) != null) byTime[at.millisecondsSinceEpoch] = row;
  }
  final stamps = byTime.keys.toList()..sort();
  if (stamps.isEmpty) return [];
  var start = stamps.length - 1;
  while (start > 0 && stamps[start] - stamps[start - 1] <= 60000 && stamps.last - stamps[start - 1] <= 15 * 60000) {
    start--;
  }
  return [for (final stamp in stamps.skip(start)) byTime[stamp]!];
}

/// Stable pairs within one sensor type; callers keep types separate.
List<List<Map<String, dynamic>>> registeredSensorPairs(List<Map<String, dynamic>> sensors) {
  final ordered = [...sensors]..sort((a,b) => sensorText(a, ['serial_number', r'$id', 'sensor_id', 'id']).compareTo(sensorText(b, ['serial_number', r'$id', 'sensor_id', 'id'])));
  return [for (var i = 0; i < ordered.length; i += 2) ordered.sublist(i, i + 2 > ordered.length ? ordered.length : i + 2)];
}

DateTime? latestRegisteredSensorTimestamp(Map<String, dynamic> sensor, List<Map<String, dynamic>> readings) {
  final id = sensorText(sensor, [r'$id', 'sensor_id', 'id']);
  final serial = sensorText(sensor, ['serial_number']);
  DateTime? latest;
  for (final row in readings) {
    final rowId = sensorText(row, ['sensor_id']);
    final matches = rowId.isNotEmpty && id.isNotEmpty ? rowId == id : serial.isNotEmpty && sensorText(row, ['serial_number']) == serial;
    if (!matches || registeredReadingValue(row) == null) continue;
    final timestamp = DateTime.tryParse(sensorText(row, [r'$createdAt']))?.toUtc() ?? registeredReadingTime(row);
    if (timestamp != null && (latest == null || timestamp.isAfter(latest))) latest = timestamp;
  }
  return latest ?? (registeredReadingValue(sensor) == null ? null : registeredReadingTime(sensor));
}

bool registeredSensorOnline(Map<String, dynamic> sensor, List<Map<String, dynamic>> readings, {DateTime? now}) {
  final latest = latestRegisteredSensorTimestamp(sensor, readings);
  if (latest == null) return false;
  final age = (now ?? DateTime.now()).toUtc().difference(latest);
  return !age.isNegative && age <= const Duration(seconds: 15);
}
