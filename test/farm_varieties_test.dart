import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/utils/farm_varieties.dart';

void main() {
  final crops = [
    {r'$id': 'a', 'plant_type_ID': 'p', 'variety_name': 'Batavia'},
    {r'$id': 'b', 'plant_type_ID': 'p', 'variety_name': 'Lollo Rosso'},
    {r'$id': 'other', 'plant_type_ID': 'p', 'variety_name': 'Green'},
    {r'$id': 'tomato', 'plant_type_ID': 't', 'variety_name': 'Roma'},
  ];
  test('batch choices use only farm-assigned varieties and retain current names', () {
    final farm = {'crop_variety_ids': ['a', 'b'], 'plant_varieties': ['Old Batavia', 'Lollo Rosso']};
    expect(assignedFarmVarieties(farm, crops, plantId: 'p', plantName: 'Lettuce').map((c) => c[r'$id']), ['a', 'b']);
    expect(assignedFarmVarieties(farm, crops, plantId: 't', plantName: 'Tomato'), isEmpty);
    expect(farmVarietySummary(farm, crops), 'Batavia, Lollo Rosso');
  });
  test('legacy farms keep their single assignment rather than all catalog varieties', () {
    expect(assignedFarmVarieties({'plant_variety': 'Batavia'}, crops, plantId: 'p', plantName: 'Lettuce').length, 1);
    expect(farmVarietySummary({'plant_variety': 'Batavia'}), 'Batavia');
  });
}
