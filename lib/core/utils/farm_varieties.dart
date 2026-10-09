import 'crop_relationships.dart';

List<String> farmVarietyIds(Map<String, dynamic> farm) {
  final values = farm['crop_variety_ids'];
  return values is List
      ? values.whereType<String>().where((id) => id.isNotEmpty).toSet().toList()
      : [];
}

List<Map<String, dynamic>> assignedFarmVarieties(
    Map<String, dynamic> farm, Iterable<Map<String, dynamic>> catalog,
    {required String plantId, required String plantName}) {
  final matching = catalog.where(
      (c) => cropMatchesPlant(c, plantId: plantId, plantName: plantName));
  final ids = farmVarietyIds(farm);
  if (ids.isNotEmpty)
    return matching
        .where((c) => ids.contains('${c[r'$id'] ?? c['id']}'))
        .toList();
  final legacy = farm['plantVariety'] ?? farm['plant_variety'];
  return matching
      .where((c) =>
          plantNameKey(c['variety_name'] ?? c['variety']) ==
          plantNameKey(legacy))
      .toList();
}

String farmVarietySummary(Map<String, dynamic> farm,
    [Iterable<Map<String, dynamic>> catalog = const []]) {
  final ids = farmVarietyIds(farm);
  final saved = farm['plant_varieties'];
  if (ids.isNotEmpty) {
    final names = {
      for (final crop in catalog)
        '${crop[r'$id'] ?? crop['id']}':
            '${crop['variety_name'] ?? crop['variety'] ?? ''}'
    };
    return [
      for (var i = 0; i < ids.length; i++)
        names[ids[i]]?.isNotEmpty == true
            ? names[ids[i]]!
            : saved is List && i < saved.length
                ? '${saved[i]}'
                : 'Unavailable variety'
    ].join(', ');
  }
  return saved is List && saved.isNotEmpty
      ? saved.join(', ')
      : '${farm['plantVariety'] ?? farm['plant_variety'] ?? ''}';
}
