import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/admin_maintenance_shell.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/modern_admin_sidebar.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/superadmin_sidebar.dart';
import 'package:farmestates_ai_dashbaord/models/user_model.dart';
import 'package:farmestates_ai_dashbaord/models/enums.dart';
import 'package:farmestates_ai_dashbaord/providers/auth_provider.dart';
import 'package:farmestates_ai_dashbaord/screens/technician/maintenance_schedule_screen.dart';
import 'package:farmestates_ai_dashbaord/screens/technician/repair_history_screen.dart';
import 'package:farmestates_ai_dashbaord/services/device_maintenance_api.dart';
import 'package:farmestates_ai_dashbaord/services/superadmin_api_service.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });
  test('administrator repair query paginates without an assignee filter',
      () async {
    var calls = 0;
    final api = SuperAdminApiService(client: MockClient((request) async {
      expect(
          request.url.queryParameters.containsKey('assigned_to_id'), isFalse);
      expect(request.url.queryParameters['offset'], '${calls * 100}');
      calls++;
      return http.Response(
          jsonEncode({
            'users': List.generate(
                calls == 1 ? 100 : 2,
                (i) => {
                      'title': 'Repair $calls-$i',
                      'assigned_to_id': 'technician-$i'
                    })
          }),
          200);
    }));
    expect((await api.getRepairHistory()).length, 102);
    expect(calls, 2);
  });

  for (final access in [
    MaintenanceAccess.admin,
    MaintenanceAccess.superAdmin
  ]) {
    for (final width in [320.0, 1440.0]) {
      testWidgets('$access maintenance and history at $width', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final role = access == MaintenanceAccess.admin
            ? UserRole.admin
            : UserRole.superAdmin;
        final user = UserModel(
            id: 'admin-1',
            name: 'Administrator',
            email: 'admin@example.com',
            role: role,
            address: '',
            farmId: 'farm-1',
            createdAt: DateTime(2026));
        final deviceApi = DeviceMaintenanceApi(
            client: MockClient((_) async => http.Response(
                jsonEncode({
                  'tasks': [],
                  'devices': [],
                  'history': [
                    {
                      'type': 'cleaning',
                      'device_name': 'Air conditioner',
                      'serial_number': 'AC-001',
                      'completed_on': '2026-10-01',
                      'performed_by_name': 'Another technician',
                      'farm_name': 'East farm',
                      'work_performed': 'Cleaned the filters',
                    }
                  ]
                }),
                200)));
        final tasks = [
          {
            'title': 'Repair greenhouse pump',
            'farm_id': 'farm-2',
            'farm_name': 'West farm',
            'assigned_to_id': 'tech-2',
            'assigned_to_name': 'Other technician',
            'status': 'Completed',
            'due_date': '2026-10-01',
            'updated_at': '2026-10-01'
          }
        ];
        Widget app(Widget screen) => ProviderScope(
              overrides: [currentUserProvider.overrideWithValue(user)],
              child: MaterialApp(
                theme: ThemeData(
                    brightness:
                        width < 768 ? Brightness.light : Brightness.dark,
                    platform: width < 768
                        ? TargetPlatform.android
                        : TargetPlatform.windows),
                home: screen,
                onGenerateRoute: (settings) => MaterialPageRoute(
                    settings: settings,
                    builder: (_) => Scaffold(body: Text(settings.name!))),
              ),
            );
        await tester.pumpWidget(app(MaintenanceScheduleScreen(
            access: access,
            deviceApi: deviceApi,
            loadData: () async => [
                  tasks,
                  [
                    {
                      'message': 'Inspect the west farm sensor',
                      'farm_id': 'farm-2',
                      'status': 'Reported',
                      'severity': 'High',
                    }
                  ]
                ])));
        await tester.pumpAndSettle();
        expect(find.text('Device maintenance'), findsOneWidget);
        await tester.tap(find.text('Farm tasks'));
        await tester.pumpAndSettle();
        expect(find.text('Repair greenhouse pump'), findsOneWidget);
        await tester
            .tap(find.text(width < 768 ? 'Issues' : 'Technical Issues'));
        await tester.pumpAndSettle();
        expect(find.text('Inspect the west farm sensor'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Both navigation surfaces expose the history destination.
        if (width < 768) {
          tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
          await tester.pumpAndSettle();
        }
        final historyLink = width < 768
            ? find.descendant(
                of: find.byType(Drawer), matching: find.text('Repair History'))
            : find.text('Repair History');
        if (width < 768) {
          await tester.scrollUntilVisible(historyLink, 250,
              scrollable: find
                  .descendant(
                      of: find.byType(Drawer),
                      matching: find.byType(Scrollable))
                  .first);
        }
        await tester.ensureVisible(historyLink);
        await tester.tap(historyLink);
        await tester.pumpAndSettle();
        final prefix =
            access == MaintenanceAccess.admin ? '/admin' : '/superadmin';
        expect(find.text('$prefix/repair-history'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());

        final api = SuperAdminApiService(client: MockClient((request) async {
          expect(request.url.path, '/farm-tasks');
          expect(request.url.queryParameters.containsKey('assigned_to_id'),
              isFalse);
          return http.Response(jsonEncode({'users': tasks}), 200);
        }));
        await tester.pumpWidget(app(RepairHistoryScreen(
            access: access, api: api, deviceApi: deviceApi)));
        await tester.pumpAndSettle();
        expect(find.text('Repair greenhouse pump'), findsOneWidget);
        expect(find.text('cleaning · Air conditioner'), findsOneWidget);
        expect(find.text('Maintenance and repair records across all farms'),
            findsOneWidget);
        if (width >= 768) {
          expect(
              find.byType(access == MaintenanceAccess.admin
                  ? ModernAdminSidebar
                  : SuperAdminSidebar),
              findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        deviceApi.dispose();
      });
    }
  }
}
