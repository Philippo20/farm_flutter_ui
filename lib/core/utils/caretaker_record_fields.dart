/// Fields collected for each caretaker workflow. Common notes/issues remain available.
Set<String> caretakerRecordFields(String type) => switch (type) {
      'daily_monitoring' => {
          'planted_count',
          'plant_count',
          'plant_health',
          'growth_stage',
          'temperature',
          'humidity',
          'ph',
          'ec',
          'light_intensity'
        },
      'transplanting' => {'transplanted_count', 'plant_health', 'growth_stage'},
      'harvesting' => {'harvested_count', 'harvest_weight_kg', 'plant_health'},
      'watering' || 'feeding' => {'ph', 'ec', 'plant_health'},
      'pruning' || 'pest_control' => {'plant_health'},
      _ => <String>{},
    };

Map<String, dynamic> filterCaretakerRecordFields(
    String type, Map<String, dynamic> data) {
  const controlled = {
    'planted_count',
    'plant_count',
    'transplanted_count',
    'harvested_count',
    'harvest_weight_kg',
    'plant_health',
    'growth_stage',
    'temperature',
    'humidity',
    'ph',
    'ec',
    'light_intensity'
  };
  final allowed = caretakerRecordFields(type);
  return Map.fromEntries(data.entries
      .where((e) => !controlled.contains(e.key) || allowed.contains(e.key)));
}
