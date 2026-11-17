import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/services/superadmin_api_service.dart';

void main() {
  test('farm summaries load records beyond the first 100', () async {
    final offsets = <int>[];
    final api = SuperAdminApiService(client: MockClient((request) async {
      final offset = int.parse(request.url.queryParameters['offset']!);
      offsets.add(offset);
      return http.Response(
          jsonEncode({
            'users': List.generate(
                offset == 0 ? 100 : 2,
                (i) =>
                    {r'$id': 'record-${offset + i}', 'historical_import': true})
          }),
          200);
    }));
    final records = await api.getFarmRecords();
    expect(records.length, 102);
    expect(records.last[r'$id'], 'record-101');
    expect(offsets, [0, 100]);
  });

  test('later-page failures never return a misleading partial summary',
      () async {
    final api = SuperAdminApiService(client: MockClient((request) async {
      if (request.url.queryParameters['offset'] == '100')
        return http.Response('Unavailable', 503);
      return http.Response(
          jsonEncode({
            'users': List.generate(100, (i) => {r'$id': '$i'})
          }),
          200);
    }));
    await expectLater(
        api.getFarmRecords(), throwsA(isA<SuperAdminApiException>()));
  });
}
