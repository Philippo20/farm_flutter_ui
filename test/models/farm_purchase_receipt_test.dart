import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/models/farm_purchase_receipt.dart';

void main() {
  final receipt = <String, dynamic>{
    r'$id': 'receipt',
    'batch_number': 'B-1',
    'delivery_status': 'Delivered',
    'status': 'Received',
    'farm_name': 'East',
    'total_weight': 10,
    'received_date_time': '2026-10-11T10:00:00Z'
  };
  final snapshot = <String, dynamic>{
    'currency': 'GHS',
    'price_tier': 'Bulk',
    'unit': 'kg',
    'quantity': 10,
    'unit_price': 8,
    'total_amount': 80,
    'farm_id': 'farm'
  };
  test('uses saved farm purchase rate, quantity and acceptance date', () {
    final data = farmPurchaseReceipt({
      ...receipt,
      'farm_purchase': jsonEncode(snapshot),
      'amount': 999,
      'paid': true
    })!;
    expect(data['total_amount'], 80);
    expect(data['price_tier'], 'Bulk');
    expect(data['payment_status'], 'Earned');
    expect(data['payment_date'], '2026-10-11T10:00:00Z');
    expect(data['farm_id'], 'farm');
  });
  test('legacy or invalid receipt is explicitly awaiting pricing', () {
    for (final value in [
      '',
      'malformed',
      jsonEncode({...snapshot, 'unit_price': -1}),
      jsonEncode({...snapshot, 'quantity': 0}),
      jsonEncode({...snapshot, 'currency': 'USD'})
    ]) {
      final data = farmPurchaseReceipt({...receipt, 'farm_purchase': value})!;
      expect(data['total_amount'], 0);
      expect(data['is_valued'], false);
      expect(data['status'], 'Awaiting pricing');
    }
  });
  test('pending, rejected, cancelled deliveries cannot earn revenue', () {
    for (final status in [
      'Pending Approval',
      'Cancelled',
      'Rejected',
      'On Hold'
    ]) {
      expect(
          farmPurchaseReceipt({...receipt, 'delivery_status': status}), isNull);
    }
  });
  test('legacy duplicate intake rows count once and prefer saved valuation',
      () {
    final rows = farmPurchaseReceipts([
      receipt,
      {...receipt, r'$id': 'duplicate', 'farm_purchase': jsonEncode(snapshot)},
      {...receipt, r'$id': 'third'}
    ]);
    expect(rows.length, 1);
    expect(rows.single['total_amount'], 80);
  });
}
