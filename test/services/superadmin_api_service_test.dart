import 'dart:convert';

import 'package:farmestates_ai_dashbaord/services/superadmin_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _RecordingClient extends http.BaseClient {
  http.BaseRequest? request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request;
    return http.StreamedResponse(
      Stream.value(utf8.encode('{"batch_id":"batch-1"}')),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  test('createBatch sends multipart fields required by FastAPI', () async {
    final client = _RecordingClient();
    final service = SuperAdminApiService(client: client);

    await service.createBatch(data: {
      'batch_no': 'BATCH-1',
      'plant_type_ID': 'plant-type-1',
      'plant_variety': 'Batavia',
      'caretaker_id': 'caretaker-1',
      'start_date': '2026-09-01',
      'end_date': '2026-10-13',
    });

    expect(client.request, isA<http.MultipartRequest>());
    final request = client.request! as http.MultipartRequest;
    expect(request.fields['plant_type_ID'], 'plant-type-1');
    expect(request.fields['plant_variety'], 'Batavia');
    expect(request.fields['caretaker_id'], 'caretaker-1');
    expect(request.fields['start_date'], '2026-09-01');
    expect(request.fields['end_date'], '2026-10-13');
  });

  test('updateBatch sends a partial multipart PUT request', () async {
    final client = _RecordingClient();
    final service = SuperAdminApiService(client: client);

    await service.updateBatch(
      id: 'batch-1',
      data: {
        'plant_variety': 'Batavia',
        'production_status': 'Growing',
        'total_transplanted': 120,
      },
    );

    expect(client.request, isA<http.MultipartRequest>());
    final request = client.request! as http.MultipartRequest;
    expect(request.method, 'PUT');
    expect(request.url.path, '/batches/batch-1');
    expect(request.fields['plant_variety'], 'Batavia');
    expect(request.fields['production_status'], 'Growing');
    expect(request.fields['total_transplanted'], '120');
    expect(request.fields.containsKey('farmID'), isFalse);
  });

  test('createFarmRecord sends caretaker batch progress fields', () async {
    final client = _RecordingClient();
    final service = SuperAdminApiService(client: client);

    await service.createFarmRecord(data: {
      'farm_id': 'farm-1',
      'farm_name': 'Farm One',
      'batch_id': 'batch-1',
      'batch_number': 'BATCH-1',
      'record_type': 'daily_monitoring',
      'record_date': '2026-09-02T08:00:00.000Z',
      'created_by': 'caretaker-1',
      'created_by_name': 'Caretaker One',
      'has_issues': false,
      'issue_severity': 'none',
      'planted_count': 500,
      'transplanted_count': 420,
      'harvested_count': 120,
      'harvest_weight_kg': 47.5,
    });

    expect(client.request, isA<http.Request>());
    final request = client.request! as http.Request;
    expect(request.method, 'POST');
    expect(request.url.path, '/farm-records/info');
    expect(request.bodyFields['batch_id'], 'batch-1');
    expect(request.bodyFields['planted_count'], '500');
    expect(request.bodyFields['transplanted_count'], '420');
    expect(request.bodyFields['harvested_count'], '120');
    expect(request.bodyFields['harvest_weight_kg'], '47.5');
  });

  test('createSale sends the complete pack allocation contract', () async {
    final client = _RecordingClient();
    final service = SuperAdminApiService(client: client);

    await service.createSale({
      'batch_id': 'fulfillment-1',
      'batch_number': 'BATCH-2026-001',
      'fulfillment_id': 'fulfillment-1',
      'buyer_id': 'off-taker-1',
      'off_taker_id': 'off-taker-1',
      'buyer_name': 'Fresh Market',
      'sales_person_id': 'sales-person-1',
      'delivery_agent_id': 'driver-1',
      'delivered_by': 'Sales Manager',
      'delivered_at': '2026-09-05T12:00:00.000',
      'scheduled_for': '2026-09-05T12:00:00.000',
      'quantity_delivered': 30,
      'package_count': 60,
      'pricing_id': 'price-1',
      'price_tier': 'Bulk',
      'unit_price': 15,
      'total_amount': 900,
      'paid': false,
      'payment_mode': 'Bank Transfer',
      'receipt_image': '',
      'receipt_number': '',
      'payment_date': '2026-09-05',
      'created_by': 'sales-manager-1',
      'created_by_role': 'sales_manager',
      'status': 'Pending',
      'delivery_address': 'Accra',
      'delivery_notes': 'Deliver before noon',
    });

    expect(client.request, isA<http.Request>());
    final request = client.request! as http.Request;
    expect(request.method, 'POST');
    expect(request.url.path, '/sales/info');
    expect(request.bodyFields['batch_number'], 'BATCH-2026-001');
    expect(request.bodyFields['fulfillment_id'], 'fulfillment-1');
    expect(request.bodyFields['off_taker_id'], 'off-taker-1');
    expect(request.bodyFields['sales_person_id'], 'sales-person-1');
    expect(request.bodyFields['delivery_agent_id'], 'driver-1');
    expect(request.bodyFields['package_count'], '60');
    expect(request.bodyFields['pricing_id'], 'price-1');
    expect(request.bodyFields['price_tier'], 'Bulk');
    expect(request.bodyFields['unit_price'], '15');
    expect(request.bodyFields['quantity_delivered'], '30');
    expect(request.bodyFields['scheduled_for'], '2026-09-05T12:00:00.000');
    expect(request.bodyFields['delivery_address'], 'Accra');
  });

  test('salesInvoiceUrl targets the printable invoice endpoint', () {
    final service = SuperAdminApiService();

    expect(
      service.salesInvoiceUrl('sale 1').path,
      '/sales/sale%201/invoice',
    );
  });

  test('updateSale targets the selected sales delivery document', () async {
    final client = _RecordingClient();
    final service = SuperAdminApiService(client: client);

    await service.updateSale('sale-1', {
      'batch_id': 'fulfillment-1',
      'package_count': 40,
      'status': 'Delivered',
    });

    expect(client.request, isA<http.Request>());
    final request = client.request! as http.Request;
    expect(request.method, 'PUT');
    expect(request.url.path, '/sales/sale-1');
    expect(request.bodyFields['package_count'], '40');
    expect(request.bodyFields['status'], 'Delivered');
  });
}
