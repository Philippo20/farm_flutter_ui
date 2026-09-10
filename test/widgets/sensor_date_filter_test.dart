import 'dart:convert';
import 'package:farmestates_ai_dashbaord/core/widgets/sensor_date_range_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/services/superadmin_api_service.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/sensor_reading_history.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  test('API sends UTC dates and pagination offset', () async {
    final api = SuperAdminApiService(client: MockClient((request) async {
      expect(request.url.path, '/sensors/TEMP-1/readings');
      expect(request.url.queryParameters['start'], '2025-01-01T00:00:00.000Z');
      expect(request.url.queryParameters['end'], '2025-01-03T00:00:00.000Z');
      expect(request.url.queryParameters['offset'], '500');
      return http.Response(jsonEncode({'users': []}), 200);
    }));
    await api.getSensorReadingsForPeriod('TEMP-1',
        start: DateTime.utc(2025), end: DateTime.utc(2025, 1, 3), offset: 500);
  });
  testWidgets(
      'Selected end date includes the whole day and clear restores results',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: SensorReadingHistory(
                    serialNumber: 'TEMP-1',
                    loadReadings: (_) async => [
                          for (final date in [
                            DateTime(2025, 1, 1),
                            DateTime(2025, 1, 2, 23, 59),
                            DateTime(2025, 1, 3)
                          ])
                            {
                              'timestamp': date.toIso8601String(),
                              'value': 25,
                              'unit': 'C'
                            }
                        ])))));
    await tester.pumpAndSettle();
    expect(tester.widget<BarChart>(find.byType(BarChart)).data.barGroups.length,
        3);
    await tester.tap(find.text('Select date range'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(SensorDateRangeModal)))
        .pop(DateTimeRange(start: DateTime(2025), end: DateTime(2025, 1, 2)));
    await tester.pumpAndSettle();
    expect(tester.widget<BarChart>(find.byType(BarChart)).data.barGroups.length,
        2);
    await tester.tap(find.text('Clear dates'));
    await tester.pumpAndSettle();
    expect(tester.widget<BarChart>(find.byType(BarChart)).data.barGroups.length,
        3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
