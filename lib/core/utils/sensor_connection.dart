/// Connectivity is inferred from reading freshness, independently of value alerts.
class SensorConnection {
  SensorConnection(Map<String, dynamic> sensor, {DateTime? now}) {
    final rawTime =
        sensor['timestamp'] ?? sensor['last_seen_at'] ?? sensor['lastReading'];
    lastSeen = rawTime is DateTime ? rawTime : DateTime.tryParse('$rawTime');
    timeout = const Duration(seconds: 10);
    final rawStatus =
        '${sensor['reported_status'] ?? sensor['status'] ?? ''}'.toLowerCase();
    final age =
        lastSeen == null ? null : (now ?? DateTime.now()).difference(lastSeen!);
    if (['offline', 'inactive', 'disconnected', 'disabled']
        .contains(rawStatus)) {
      state = 'offline';
      reason = 'Sensor reported offline';
    } else if (age == null || age < const Duration(minutes: -1)) {
      state = 'unknown';
      reason = 'No valid reading timestamp';
    } else if (age >= timeout) {
      state = 'offline';
      reason = 'No reading for 10 seconds';
    } else {
      state = 'online';
      reason = 'Recent sensor update received';
    }
  }
  DateTime? lastSeen;
  late Duration timeout;
  late String state, reason;
}
