import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/screens/technician/repair_history_screen.dart';
import 'package:farmestates_ai_dashbaord/services/superadmin_api_service.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });
  test('Repair API paginates and excludes other assignees', () async {
    var calls = 0;
    final api = SuperAdminApiService(client: MockClient((request) async {
      expect(request.url.queryParameters['assigned_to_id'], 'tech-1');
      expect(request.url.queryParameters['offset'], (calls * 100).toString());
      calls++;
      return http.Response(
          jsonEncode({
            'users': calls == 1
                ? List.generate(
                    100,
                    (i) => {
                          'assigned_to_id': i == 0 ? 'other' : 'tech-1',
                          'title': 'Task $i'
                        })
                : [
                    {'assigned_to_id': 'tech-1', 'title': 'Final task'}
                  ]
          }),
          200);
    }));
    final rows = await api.getTechnicianRepairHistory('tech-1');
    expect(calls, 2);
    expect(rows.length, 100);
    expect(rows.last['title'], 'Final task');
    expect(await api.getTechnicianRepairHistory(''), isEmpty);
    expect(calls, 2);
  });
  for (final width in [320.0, 1440.0]) {
    testWidgets('Repair history $width shows actual task fields and filters',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
              home: RepairHistoryScreen(
                  loadRecords: () async => [
                        {
                          'title': 'Pump inspection',
                          'description':
                              'Replace the damaged inlet seal and verify pressure',
                          'farm_name': 'Northern greenhouse extension',
                          'status': 'Completed',
                          'task_id': 'FT-123',
                          'assigned_to_name':
                              'Assigned technician with a long name',
                          'priority': 'High',
                          'manager_comment': 'Check seal',
                          'updated_at': '2026-09-10T12:00:00Z'
                        },
                        {
                          'title': 'Fan service',
                          'status': 'In Progress',
                          'farm_name': 'West farm'
                        }
                      ]))));
      await tester.pumpAndSettle();
      expect(find.text('Pump inspection'), findsOneWidget);
      expect(find.text('Fan service'), findsOneWidget);
      expect(find.text('GHS 420'), findsNothing);
      await tester.enterText(find.byType(TextField), 'Pump');
      await tester.pumpAndSettle();
      expect(find.text('Fan service'), findsNothing);
      expect(find.text('Pump inspection'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('Backend failure offers retry without invented empty counts',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
            home: RepairHistoryScreen(
                loadRecords: () async => throw Exception('unavailable')))));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Records'), findsNothing);
    expect(find.text('Irrigation Pump A2'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
