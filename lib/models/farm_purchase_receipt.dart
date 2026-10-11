import 'dart:convert';

/// A farm purchase is earned at accepted intake, independently of hub sales.
Map<String, dynamic>? farmPurchaseReceipt(Map<String, dynamic> fulfillment) {
  String text(dynamic value) => '${value ?? ''}'.trim();
  final delivery = text(fulfillment['delivery_status']).toLowerCase();
  final stage = text(fulfillment['status']).toLowerCase();
  if (['cancelled', 'rejected', 'on hold'].contains(delivery) ||
      !(delivery == 'delivered' ||
          ['packaging', 'packaged', 'sent to sales', 'completed']
              .contains(stage))) {
    return null;
  }
  var purchase = <String, dynamic>{};
  try {
    final decoded = jsonDecode(text(fulfillment['farm_purchase']));
    if (decoded is Map<String, dynamic>) purchase = decoded;
  } catch (_) {/* Legacy receipts await an explicit admin valuation. */}
  final valued = purchase['currency'] == 'GHS' &&
      ['Regular', 'Bulk'].contains(purchase['price_tier']) &&
      ['kg', 'g', 'head', 'heads'].contains(purchase['unit']) &&
      purchase['unit_price'] is num &&
      (purchase['unit_price'] as num).isFinite &&
      (purchase['unit_price'] as num) > 0 &&
      purchase['quantity'] is num &&
      (purchase['quantity'] as num).isFinite &&
      (purchase['quantity'] as num) > 0 &&
      purchase['total_amount'] is num &&
      (purchase['total_amount'] as num).isFinite &&
      (purchase['total_amount'] as num) >= 0;
  final date = fulfillment['received_date_time'] ?? fulfillment[r'$createdAt'];
  return {
    ...fulfillment,
    ...purchase,
    'total_amount': valued ? purchase['total_amount'] : 0,
    'price_tier': valued ? purchase['price_tier'] : 'Awaiting pricing',
    'unit_price': valued ? purchase['unit_price'] : 0,
    'quantity_delivered':
        valued ? purchase['quantity'] : fulfillment['total_weight'],
    'unit': valued ? purchase['unit'] : 'kg',
    'status': valued ? 'Earned' : 'Awaiting pricing',
    'payment_status': valued ? 'Earned' : 'Awaiting pricing',
    'payment_date': date,
    'created_at': date,
    r'$createdAt': date,
    'buyer_name': 'Farm Estates Hub',
    'is_valued': valued,
  };
}

List<Map<String, dynamic>> farmPurchaseReceipts(
    List<Map<String, dynamic>> fulfillments) {
  final receipts = <String, Map<String, dynamic>>{};
  for (final fulfillment in fulfillments) {
    final receipt = farmPurchaseReceipt(fulfillment);
    if (receipt == null) continue;
    final batch = '${receipt['batch_number'] ?? ''}'.trim().toLowerCase();
    final key = batch.isEmpty ? '${receipt[r'$id'] ?? receipts.length}' : batch;
    final previous = receipts[key];
    // One intake per batch. Older builds could accidentally create duplicates
    // during inspection; a saved valuation takes precedence over an unpriced row.
    if (previous == null ||
        previous['is_valued'] != true && receipt['is_valued'] == true) {
      receipts[key] = receipt;
    }
  }
  return receipts.values.toList();
}
