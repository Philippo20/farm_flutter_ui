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
      'plant_variety': 'Batavia',
      'start_date': '2026-09-01',
      'end_date': '2026-10-13',
    });

    expect(client.request, isA<http.MultipartRequest>());
    final request = client.request! as http.MultipartRequest;
    expect(request.fields['plant_variety'], 'Batavia');
    expect(request.fields['start_date'], '2026-09-01');
    expect(request.fields['end_date'], '2026-10-13');
  });
}
