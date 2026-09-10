import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/utils/sensor_connection.dart';

void main() {
  final now = DateTime.utc(2026, 9, 10, 12);
  Map<String, dynamic> reading(int seconds, [String status = 'Active']) => {
        'status': status,
        'timestamp': now.subtract(Duration(seconds: seconds)).toIso8601String()
      };
  test('Detects stale readings and reconnects after an update', () {
    expect(SensorConnection(reading(9), now: now).state, 'online');
    expect(SensorConnection(reading(10), now: now).state, 'offline');
    expect(SensorConnection(reading(3600), now: now).state, 'offline');
    expect(SensorConnection(reading(0), now: now).state, 'online');
  });
  test('Value warnings are separate from connectivity', () {
    for (final status in ['Faulty', 'Maintenance', 'Warning', 'Alert']) {
      expect(SensorConnection(reading(5, status), now: now).state, 'online');
    }
    expect(SensorConnection(reading(0, 'Inactive'), now: now).state, 'offline');
  });
  test('Missing/future timestamps never confirm online; edits are not readings',
      () {
    expect(
        SensorConnection(
                {'status': 'Active', r'$updatedAt': now.toIso8601String()},
                now: now)
            .state,
        'unknown');
    expect(SensorConnection({'timestamp': 'bad'}, now: now).state, 'unknown');
    expect(SensorConnection(reading(-120), now: now).state, 'unknown');
  });
  test('Ten-second rule is not overridden by a stale timeout setting', () {
    expect(
        SensorConnection({...reading(10), 'offline_timeout_seconds': 600},
                now: now)
            .state,
        'offline');
    expect(SensorConnection(reading(10), now: now).reason,
        'No reading for 10 seconds');
  });
}
