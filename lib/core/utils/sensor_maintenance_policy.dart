/// Routine maintenance policy for the platform's sensor registration workflow.
bool sensorRequiresMaintenance(Map<String, dynamic> sensor) {
  final type =
      '${sensor['sensortype'] ?? sensor['sensor_type'] ?? sensor['type'] ?? ''}'
          .toLowerCase()
          .replaceAll('₂', '2')
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
  return !const {
    'temperature',
    'temp',
    'humidity',
    'relativehumidity',
    'vpd',
    'vaporpressuredeficit',
    'vapourpressuredeficit',
    'light',
    'lightintensity',
    'co2',
    'carbondioxide'
  }.contains(type);
}
