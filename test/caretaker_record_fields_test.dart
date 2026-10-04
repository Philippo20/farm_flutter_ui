import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/utils/caretaker_record_fields.dart';

void main() {
  test('Watering preserves both sources and other types exclude them', () {
    final water = {
      'water_temperature': 24.5,
      'water_bought_litres': 120.5,
      'water_bought_amount': 60,
      'ac_water_litres': 8
    };
    expect(filterCaretakerRecordFields('watering', water), water);
    expect(filterCaretakerRecordFields('daily_monitoring', water),
        {'water_temperature': 24.5});
    expect(filterCaretakerRecordFields('feeding', water), isEmpty);
  });
  test('Daily monitoring excludes all batch progress totals', () {
    const progress = {
      'planted_count',
      'plant_count',
      'transplanted_count',
      'harvested_count',
      'harvest_weight_kg'
    };
    expect(caretakerRecordFields('daily_monitoring').intersection(progress),
        isEmpty);
    expect(
        filterCaretakerRecordFields('daily_monitoring', {
          for (final field in progress) field: 100,
          'temperature': 27,
          'growth_stage': 'Vegetative',
          'observations': 'Healthy crop',
        }),
        {
          'temperature': 27,
          'growth_stage': 'Vegetative',
          'observations': 'Healthy crop',
        });
  });
  test('Harvest and transplant collect only their own production totals', () {
    expect(caretakerRecordFields('harvesting'),
        containsAll(['harvested_count', 'harvest_weight_kg']));
    expect(caretakerRecordFields('harvesting'),
        isNot(contains('transplanted_count')));
    expect(
        caretakerRecordFields('transplanting'), contains('transplanted_count'));
    expect(caretakerRecordFields('transplanting'),
        isNot(contains('harvested_count')));
  });
  test('Changing type excludes previously entered hidden values from request',
      () {
    final filtered = filterCaretakerRecordFields('feeding', {
      'temperature': 27,
      'harvested_count': 90,
      'planted_count': 100,
      'ph': 6.5,
      'ec': 1.2,
      'notes': 'Fed plants',
      'batch_id': 'b1'
    });
    expect(filtered,
        {'ph': 6.5, 'ec': 1.2, 'notes': 'Fed plants', 'batch_id': 'b1'});
  });
  test('Cleaning collects no unrelated readings or production counters', () {
    expect(caretakerRecordFields('cleaning'), isEmpty);
    expect(
        filterCaretakerRecordFields('cleaning', {
          'plant_health': 'Healthy',
          'harvest_weight_kg': 0,
          'observations': 'Cleaned',
          'has_issues': false
        }),
        {'observations': 'Cleaned', 'has_issues': false});
  });
}
