import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/utils/caretaker_record_fields.dart';

void main() {
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
