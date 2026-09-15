import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/utils/registered_sensor_readings.dart';

void main() {
    test('Server receipt time takes precedence over a delayed device clock', () {
    final sensor = {'id': 's1', 'value': 21, 'timestamp': '2026-09-15T09:00:00Z'};
    final readings = [{'sensor_id': 's1', 'value': 21, 'timestamp': '2026-09-15T09:00:00Z', r'$createdAt': '2026-09-15T12:00:00Z'}];
    expect(registeredSensorOnline(sensor, readings, now: DateTime.utc(2026,9,15,12,0,10)), isTrue);
    expect(registeredSensorOnline(sensor, readings, now: DateTime.utc(2026,9,15,12,0,16)), isFalse);
  });

  test('Live chart excludes long gaps without modifying historical readings', () {
    final rows = [
      {'value': 21, 'timestamp': '2026-09-15T09:00:00Z'},
      {'value': 25, 'timestamp': '2026-09-15T09:00:05Z'},
      {'value': 27, 'timestamp': '2026-09-15T10:00:00Z'},
      {'value': 28, 'timestamp': '2026-09-15T10:00:05Z'},
    ];
    expect(latestSensorActivity(rows).map(registeredReadingValue), [27, 28]);
    expect(rows.length, 4);
  });
  test('Single recent reading does not invent a connecting line', () {
    expect(latestSensorActivity([
      {'value': 21, 'timestamp': '2026-09-15T09:00:00Z'},
      {'value': 27, 'timestamp': '2026-09-15T10:00:00Z'},
    ]).length, 1);
  });
  test('Online uses newest matched reading and exact fifteen second boundary', () {
    final now = DateTime.utc(2026, 9, 15, 12);
  final sensor = {'id': 's1', 'serial_number': 'T1', 'value': 20, 'timestamp': '2026-09-15T10:00:00Z'};
    Map<String, dynamic> row(Duration age) => {'sensor_id': 's1', 'value': 21, 'timestamp': now.subtract(age).toIso8601String()};
    expect(registeredSensorOnline(sensor, [row(const Duration(seconds: 5))], now: now), isTrue);
    expect(registeredSensorOnline(sensor, [row(const Duration(seconds: 15))], now: now), isTrue);
    expect(registeredSensorOnline(sensor, [row(const Duration(milliseconds: 15001))], now: now), isFalse);
    expect(registeredSensorOnline(sensor, [{'sensor_id': 'other', 'value': 21, 'timestamp': now.toIso8601String()}], now: now), isFalse);
  });
  final sensor = {'id': 'one', 'serial_number': 'T1', 'unit': 'C'};
  test('Only registered identity matches and history is ordered', () {
    final rows = readingsForRegisteredSensor(sensor, [
      {'sensor_id': 'other', 'value': 99, 'timestamp': '2026-09-15T10:00:00Z'},
      {'sensor_id': 'one', 'value': 24, 'timestamp': '2026-09-15T10:01:00Z'},
      {'serial_number': 'T1', 'value': 21, 'timestamp': '2026-09-15T10:00:00Z'},
      {
        'sensor_id': 'other',
        'serial_number': 'T1',
        'value': 88,
        'timestamp': '2026-09-15T10:02:00Z'
      },
    ]);
    expect(rows.map(registeredReadingValue), [21, 24]);
  });
  test('Missing data creates no samples; incompatible units are excluded', () {
    expect(readingsForRegisteredSensor(sensor, []), isEmpty);
    expect(
        readingsForRegisteredSensor(sensor, [
          {
            'sensor_id': 'one',
            'value': 90,
            'unit': 'F',
            'timestamp': '2026-09-15T10:00:00Z'
          }
        ]),
        isEmpty);
  });
}
