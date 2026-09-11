/// Resolves backend sales, batch and fulfillment references to a farm ID.
/// Ambiguous names are deliberately left unassigned instead of double counting.
class AnalyticsFarmResolver {
  AnalyticsFarmResolver(
      {required List<Map<String, dynamic>> farms,
      required List<Map<String, dynamic>> batches,
      required List<Map<String, dynamic>> fulfillments}) {
    for (final farm in farms) {
      final id = documentId(farm);
      if (id.isEmpty) continue;
      for (final key in [
        r'$id',
        'id',
        '_id',
        'farm_id',
        'farmID',
        'farmId',
        'name',
        'farm_name',
        'farmName'
      ]) {
        _add(_farms, farm[key], id);
      }
    }
    for (final batch in batches) {
      final farm = _directFarm(batch);
      if (farm.isEmpty) continue;
      for (final key in [
        r'$id',
        'id',
        '_id',
        'batch_id',
        'batchId',
        'batch_no',
        'batch_number'
      ]) {
        _add(_batches, batch[key], farm);
      }
    }
    for (final fulfillment in fulfillments) {
      final farm = resolve(fulfillment);
      if (farm.isEmpty) continue;
      for (final key in [r'$id', 'id', '_id', 'fulfillment_id']) {
        _add(_fulfillments, fulfillment[key], farm);
      }
    }
  }
  final _farms = <String, Set<String>>{};
  final _batches = <String, Set<String>>{};
  final _fulfillments = <String, Set<String>>{};

  static String documentId(Map<String, dynamic> record) {
    for (final key in ['id', r'$id', '_id']) {
      final value = record[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String _token(dynamic value) {
    if (value is Map) value = value[r'$id'] ?? value['id'];
    return value?.toString().trim().toLowerCase() ?? '';
  }

  void _add(Map<String, Set<String>> index, dynamic value, String id) {
    final token = _token(value);
    if (token.isNotEmpty) index.putIfAbsent(token, () => {}).add(id);
  }

  String _lookup(Map<String, Set<String>> index, Map<String, dynamic> record,
      List<String> keys) {
    final matches = <String>{};
    for (final key in keys) {
      matches.addAll(index[_token(record[key])] ?? {});
    }
    return matches.length == 1 ? matches.single : '';
  }

  String _directFarm(Map<String, dynamic> record) {
    final byId = _lookup(_farms, record, ['farm_id', 'farmID', 'farmId']);
    return byId.isNotEmpty
        ? byId
        : _lookup(_farms, record, ['farm_name', 'farmName']);
  }

  String resolve(Map<String, dynamic> record) {
    final direct = _directFarm(record);
    if (direct.isNotEmpty) return direct;
    final batch = _lookup(
        _batches, record, ['batch_id', 'batchId', 'batch_no', 'batch_number']);
    if (batch.isNotEmpty) return batch;
    return _lookup(_fulfillments, record, ['fulfillment_id', 'fulfillmentId']);
  }
}
