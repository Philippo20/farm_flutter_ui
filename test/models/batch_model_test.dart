import 'package:farmestates_ai_dashbaord/core/models/batch/batch_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BatchModel preserves crop variety through JSON mapping', () {
    final batch = BatchModel.fromJson({
      'id': 'batch-1',
      'batchNumber': 'FARM-20260901-20261013',
      'farmId': 'farm-1',
      'farmName': 'Farm One',
      'farmManagerId': 'manager-1',
      'farmManagerName': 'Manager',
      'plantType': 'Lettuce',
      'plant_variety': 'Batavia',
      'startDate': '2026-09-01',
      'endDate': '2026-10-13',
      'plantMaturityDays': 42,
      'createdAt': '2026-09-01T08:00:00Z',
    });

    expect(batch.plantVariety, 'Batavia');
    expect(batch.toJson()['plantVariety'], 'Batavia');
    expect(batch.copyWith(plantVariety: 'Romaine').plantVariety, 'Romaine');
  });
}
