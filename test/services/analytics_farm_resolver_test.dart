import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/services/analytics_farm_resolver.dart';

void main() {
  final resolver = AnalyticsFarmResolver(
    farms: [
      {r'$id': 'farm-a', 'name': 'North Farm'},
      {r'$id': 'farm-b', 'name': 'South Farm'},
    ],
    batches: [
      {
        r'$id': 'batch-doc',
        'batch_number': 'BATCH-001',
        'farm_name': 'North Farm'
      },
      {r'$id': 'batch-two', 'batch_no': 'BATCH-002', 'farm_id': 'farm-b'},
    ],
    fulfillments: [
      {r'$id': 'fulfillment-doc', 'batch_number': 'BATCH-001'}
    ],
  );
  test('attributes revenue by batch number and fulfillment reference', () {
    final sales = [
      {'batch_id': 'BATCH-001', 'total_amount': 1500},
      {'fulfillment_id': 'fulfillment-doc', 'total_amount': 250},
      {'batch_id': 'batch-two', 'total_amount': 500},
      {'farmId': 'farm-b', 'total_amount': 100},
    ];
    final totals = <String, num>{};
    for (final sale in sales) {
      final id = resolver.resolve(sale);
      totals[id] = (totals[id] ?? 0) + (sale['total_amount'] as num);
    }
    expect(totals, {'farm-a': 1750, 'farm-b': 600});
  });
  test('supports legacy names, whitespace and relationship IDs', () {
    expect(resolver.resolve({'batch_number': ' batch-001 '}), 'farm-a');
    expect(
        resolver.resolve({
          'farm_id': {r'$id': 'farm-b'}
        }),
        'farm-b');
    expect(resolver.resolve({'farm_name': 'south farm'}), 'farm-b');
    expect(resolver.resolve({'batch_id': 'unknown'}), '');
  });
  test('does not assign ambiguous names to an arbitrary farm', () {
    final ambiguous = AnalyticsFarmResolver(farms: [
      {r'$id': '1', 'name': 'Shared'},
      {r'$id': '2', 'name': 'Shared'}
    ], batches: [], fulfillments: []);
    expect(ambiguous.resolve({'farm_name': 'Shared'}), '');
    expect(ambiguous.resolve({'farm_id': '2', 'farm_name': 'Shared'}), '2');
  });
}
