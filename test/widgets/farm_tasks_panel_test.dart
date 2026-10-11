import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/farm_tasks_panel.dart';
import 'package:farmestates_ai_dashbaord/models/enums.dart';
import 'package:farmestates_ai_dashbaord/models/user_model.dart';
import 'package:farmestates_ai_dashbaord/providers/auth_provider.dart';
import 'package:farmestates_ai_dashbaord/services/superadmin_api_service.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });
  final task = <String, dynamic>{
    r'$id': 'task',
    'title': 'Inspect pump',
    'farm_id': 'farm',
    'assigned_to_name': 'Technician',
    'description': 'Check water pump',
    'status': 'Pending'
  };
  for (final role in [
    UserRole.admin,
    UserRole.superAdmin,
    UserRole.farmManager,
    UserRole.technician,
    UserRole.caretaker
  ]) {
    testWidgets('farm tasks deletion access for $role', (tester) async {
      final user = UserModel(
          id: 'actor',
          name: 'Actor',
          email: 'actor@test.com',
          role: role,
          address: '',
          createdAt: DateTime(2026));
      final api = SuperAdminApiService(
          client: MockClient((_) async => http.Response(
              jsonEncode({
                'users': [
                  task,
                  {
                    ...task,
                    r'$id': 'other',
                    'title': 'Other farm task',
                    'farm_id': 'other'
                  }
                ]
              }),
              200)));
      await tester.pumpWidget(ProviderScope(
          overrides: [currentUserProvider.overrideWithValue(user)],
          child: MaterialApp(
              home: Scaffold(body: FarmTasksPanel(farmId: 'farm', api: api)))));
      await tester.pumpAndSettle();
      final admin = role == UserRole.admin || role == UserRole.superAdmin;
      expect(
          find.byTooltip('Delete task'), admin ? findsOneWidget : findsNothing);
      expect(find.text('Other farm task'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  for (final width in [320.0, 1440.0]) {
    testWidgets(
        'delete waits for backend and keeps errors inside modal at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final response = Completer<http.Response>();
      var calls = 0;
      final api = SuperAdminApiService(client: MockClient((request) {
        expect(request.method, 'DELETE');
        expect(request.headers.containsKey('Authorization'), true);
        calls++;
        return response.future;
      }));
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(
              platform: width < 600
                  ? TargetPlatform.android
                  : TargetPlatform.windows),
          home: Scaffold(body: TaskDeleteModal(task: task, api: api))));
      await tester.tap(find.widgetWithText(FilledButton, 'Delete task'));
      await tester.pump();
      expect(find.text('Deleting…'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull);
      expect(calls, 1);
      response.complete(http.Response(
          '{"detail":"Only administrators can delete farm tasks."}', 403));
      await tester.pumpAndSettle();
      expect(find.text('Only administrators can delete farm tasks.'),
          findsOneWidget);
      expect(find.text('Inspect pump'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  test('task lists paginate to include all farm tasks', () async {
    var calls = 0;
    final api = SuperAdminApiService(client: MockClient((request) async {
      expect(request.url.queryParameters['offset'], '${calls * 100}');
      calls++;
      return http.Response(
          jsonEncode({
            'users': List.generate(
                calls == 1 ? 100 : 2, (i) => {...task, r'$id': '$calls-$i'})
          }),
          200);
    }));
    expect((await api.getFarmTasks()).length, 102);
  });
}
