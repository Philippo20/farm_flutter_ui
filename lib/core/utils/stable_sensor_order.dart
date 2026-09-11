/// Keep existing devices in place while replacing their telemetry with fresh data.
/// Newly registered devices are appended; removed devices leave the list.
List<Map<String, dynamic>> stableSensorOrder(
  List<Map<String, dynamic>> previous,
  List<Map<String, dynamic>> incoming,
) {
  String identity(Map<String, dynamic> sensor) =>
      '${sensor[r'$id'] ?? sensor['id'] ?? sensor['serial_number'] ?? ''}';
  final remaining = <String, Map<String, dynamic>>{};
  final unidentified = <Map<String, dynamic>>[];
  for (final sensor in incoming) {
    final id = identity(sensor);
    if (id.isEmpty) {
      unidentified.add(sensor);
    } else {
      remaining[id] = sensor;
    }
  }
  final ordered = <Map<String, dynamic>>[];
  for (final sensor in previous) {
    final updated = remaining.remove(identity(sensor));
    if (updated != null) ordered.add(updated);
  }
  return [...ordered, ...remaining.values, ...unidentified];
}
