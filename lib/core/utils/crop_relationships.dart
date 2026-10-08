String plantNameKey(Object? value) =>
    '${value ?? ''}'.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String cropPlantId(Map<String, dynamic> crop) =>
    '${crop['plant_type_ID'] ?? crop['plantTypeId'] ?? ''}'.trim();

bool cropMatchesPlant(Map<String, dynamic> crop,
    {required String plantId, required String plantName}) {
  final linked = cropPlantId(crop);
  if (linked.isNotEmpty) return plantId.isNotEmpty && linked == plantId;
  final legacyName = crop['crop_name'] ??
      crop['plant_type'] ??
      crop['plant_name'] ??
      crop['plantType'];
  return plantNameKey(legacyName).isNotEmpty &&
      plantNameKey(legacyName) == plantNameKey(plantName);
}

String plantIdForName(Iterable<Map<String, dynamic>> plants, String name) {
  final matches = plants
      .where((p) =>
          p['is_category'] != true &&
          p['isCategory'] != true &&
          plantNameKey(p['name'] ?? p['plant_name']) == plantNameKey(name))
      .toList();
  return matches.length == 1
      ? '${matches.single[r'$id'] ?? matches.single['id'] ?? ''}'
      : '';
}
