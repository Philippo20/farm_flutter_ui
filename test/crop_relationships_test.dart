import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/utils/crop_relationships.dart';

void main() {
  test('parent ID takes precedence over names and supports many varieties', () {
    final crops = [
      {
        'plant_type_ID': 'p',
        'crop_name': 'Old name',
        'variety_name': 'Batavia'
      },
      {
        'plant_type_ID': 'p',
        'crop_name': 'Other label',
        'variety_name': 'Lollo Rosso'
      },
      {
        'plant_type_ID': 'other',
        'crop_name': 'Lettuce',
        'variety_name': 'Wrong crop'
      },
    ];
    expect(
        crops
            .where(
                (c) => cropMatchesPlant(c, plantId: 'p', plantName: 'Lettuce'))
            .length,
        2);
  });
  test('legacy matching is exact and ambiguous plant names have no inferred ID',
      () {
    expect(
        cropMatchesPlant({'crop_name': ' LETTUCE '},
            plantId: 'p', plantName: 'Lettuce'),
        true);
    expect(
        cropMatchesPlant({'crop_name': 'Red Lettuce'},
            plantId: 'p', plantName: 'Lettuce'),
        false);
    expect(
        plantIdForName([
          {r'$id': 'p', 'name': 'Lettuce'},
          {r'$id': 'q', 'name': 'Lettuce'}
        ], 'Lettuce'),
        '');
    expect(
        plantIdForName([
          {r'$id': 'p', 'name': 'Lettuce'}
        ], 'Lettuce'),
        'p');
  });
}
