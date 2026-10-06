import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/models/enums.dart';
import 'package:farmestates_ai_dashbaord/models/user_model.dart';
import 'package:farmestates_ai_dashbaord/providers/auth_provider.dart';
import 'package:farmestates_ai_dashbaord/services/auth_service.dart';
import 'package:farmestates_ai_dashbaord/services/superadmin_api_service.dart';
import 'package:farmestates_ai_dashbaord/screens/caretaker/record_entry_screen.dart';

class RecordAuth extends Fake implements AuthService {
  @override
  final currentUser = UserModel(
      id: 'u',
      name: 'Caretaker',
      email: 'user@example.com',
      role: UserRole.caretaker,
      address: '',
      createdAt: DateTime(2026));
  @override
  bool get isLoggedIn => true;
  @override
  Future<void> initialize() async {}
}

class RecordApi extends Fake implements SuperAdminApiService {
  Map<String, dynamic>? saved;
  @override
  Future<List<Map<String, dynamic>>> getFarms() async => [
        {
          r'$id': 'f',
          'name': 'Farm',
          'caretaker_ids': ['u']
        }
      ];
  @override
  Future<List<Map<String, dynamic>>> getBatches() async => [
        {
          r'$id': 'b',
          'batch_no': 'B-1',
          'farmID': 'f',
          'start_date': DateTime.now()
              .subtract(const Duration(days: 8))
              .toIso8601String(),
          'production_plan': {
            'stages': [
              {'name': 'Sprouting', 'days': 7},
              {'name': 'Leaf Development', 'days': 14}
            ]
          }
        }
      ];
  @override
  Future<List<Map<String, dynamic>>> getPlantTypes() async => [];
  @override
  Future<List<Map<String, dynamic>>> getFarmTasks() async => [];
  @override
  Future<List<Map<String, dynamic>>> getFulfillments() async => [];
  @override
  Future<Map<String, dynamic>> createFarmRecord(
      {required Map<String, dynamic> data}) async {
    saved = data;
    return {'record': data};
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  for (final width in [390.0, 1200.0]) {
    testWidgets(
        'pH and EC retain their own values through entry, review and save at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = RecordApi();
      final container = ProviderContainer(
          overrides: [authServiceProvider.overrideWithValue(RecordAuth())]);
      addTearDown(container.dispose);
      container.read(authProvider);
      await tester.pump();
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: RecordEntryScreen(api: api), routes: {
            '/caretaker_dashboard': (_) => const Scaffold(body: Text('Saved'))
          })));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Leaf Development'), findsWidgets);
      expect(find.text('Batch Progress'), findsNothing);
      Finder field(String label) => find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label);
      final ph = field('pH (0–14)');
      final ec = field('EC (mS/cm)');
      await tester.ensureVisible(ph);
      await tester.enterText(ph, '6.2');
      await tester.ensureVisible(ec);
      await tester.enterText(ec, '1.5');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('6.2'), findsOneWidget);
      expect(find.text('1.5'), findsOneWidget);
      await tester.ensureVisible(find.text('Submit Record'));
      await tester.tap(find.text('Submit Record'));
      await tester.pumpAndSettle();
      expect(api.saved?['ph'], '6.2');
      expect(api.saved?['ec'], '1.5');
      expect(api.saved?['growth_stage'], 'Leaf Development');
      expect(tester.takeException(), isNull);
    });
  }
}
