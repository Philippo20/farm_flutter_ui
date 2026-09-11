import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/utils/stable_sensor_order.dart';

void main() {
  test('New readings and API order do not move existing cards', () {
    final previous = [
      {'id': 'a', 'value': 1},
      {'id': 'b', 'value': 2}
    ];
    final updated = stableSensorOrder(previous, [
      {'id': 'b', 'value': 9, 'timestamp': 'latest'},
      {'id': 'a', 'value': 3}
    ]);
    expect(updated.map((s) => s['id']), ['a', 'b']);
    expect(updated.map((s) => s['value']), [3, 9]);
    expect(previous.first['value'], 1);
  });
  test('Append new devices and remove deleted devices', () {
    final updated = stableSensorOrder([
      {'id': 'a'},
      {'id': 'b'}
    ], [
      {'id': 'c'},
      {'id': 'b'}
    ]);
    expect(updated.map((s) => s['id']), ['b', 'c']);
  });
  test('Document identity remains stable when serial or names change', () {
    final updated = stableSensorOrder([
      {r'$id': 'a', 'serial_number': 'old'},
      {r'$id': 'b'}
    ], [
      {r'$id': 'b'},
      {r'$id': 'a', 'serial_number': 'new'}
    ]);
    expect(updated.first['serial_number'], 'new');
  });
}
