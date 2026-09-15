import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/utils/registered_sensor_readings.dart';

void main() {
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
