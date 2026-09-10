/// Routine calibration policy for this application's maintenance workflow.
/// A device-specific API value takes precedence over the type defaults.
bool? sensorRequiresCalibration(Map<String, dynamic> sensor) {
  if (sensor['calibration_required'] is bool)
    return sensor['calibration_required'] as bool;
  final type =
      '${sensor['type'] ?? sensor['sensortype'] ?? sensor['sensor_type'] ?? ''}'
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (['temperature', 'temp'].contains(type)) return false;
  if ([
    'ph',
    'phlevel',
    'ec',
    'eclevel',
    'conductivity',
    'electricalconductivity',
    'tds'
  ].contains(type)) return true;
  return null;
}
