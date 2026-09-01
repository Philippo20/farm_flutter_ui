import 'package:farmestates_ai_dashbaord/models/crop_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> cropJson({
  Object? durationValue = 1,
  String durationUnit = 'months',
}) {
  return {
    r'$id': 'crop-1',
    'crop_name': 'Tomato',
    'variety_name': 'Roma',
    'plant_duration_value': durationValue,
    'plant_duration_unit': durationUnit,
    'harvesting_weight': 1,
    'company': 'Farm Estates',
    'sprouting_ratio': 90,
    'ec_level_min': 1,
    'ec_level_max': 2,
    'ph_level_min': 5.5,
    'ph_level_max': 6.5,
    'temp_min': 18,
    'temp_max': 28,
    'humidity_min': 50,
    'humidity_max': 80,
    'created_by': 'user-1',
  };
}

void main() {
  test('uses calendar months and clamps the day at month end', () {
    final crop = CropModel.fromJson(cropJson());

    expect(
      crop.getEstimatedHarvestDate(DateTime(2026, 1, 31)),
      DateTime(2026, 2, 28),
    );
  });

  test('serializes structured day durations', () {
    final crop = CropModel.fromJson(
      cropJson(durationValue: 42, durationUnit: 'days'),
    );

    expect(crop.plantDuration, 42);
    expect(crop.plantDurationUnit, 'days');
    expect(crop.toJson()['plant_duration_value'], 42);
    expect(crop.toJson()['plant_duration_unit'], 'days');
  });
}
