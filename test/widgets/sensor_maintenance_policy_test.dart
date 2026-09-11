import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/utils/sensor_maintenance_policy.dart';

void main() {
  test('Environmental sensor maintenance matches UI and API type names', () {
    for (final type in [
      'Temperature',
      'Humidity',
      'VPD',
      'Light',
      'CO2',
      'Carbon Dioxide',
      'CO₂',
      'Relative Humidity'
    ]) {
      expect(sensorRequiresMaintenance({'sensortype': type}), isFalse,
          reason: type);
    }
  });
  test('Other sensors retain maintenance requirements', () {
    for (final type in ['pH Level', 'EC Level', 'Water level', 'Unknown']) {
      expect(sensorRequiresMaintenance({'sensortype': type}), isTrue,
          reason: type);
    }
    expect(
        sensorRequiresMaintenance(
            {'sensortype': 'humidity', 'calibration_required': true}),
        isFalse);
  });
}
