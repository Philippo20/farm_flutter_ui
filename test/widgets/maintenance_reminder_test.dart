import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/maintenance_reminder_host.dart';
import 'package:farmestates_ai_dashbaord/core/providers/maintenance_reminders_provider.dart';
import 'package:farmestates_ai_dashbaord/services/device_maintenance_api.dart';
import 'package:farmestates_ai_dashbaord/providers/auth_provider.dart';
import 'package:farmestates_ai_dashbaord/models/typography_preferences.dart';
import 'personal_typography_test.dart' show TestAuth;

class ReminderFake extends MaintenanceRemindersNotifier {
  ReminderFake() : super('a', DeviceMaintenanceApi());
  @override
  Future<void> refresh() async {}
  void showItems(List<Map<String, dynamic>> items) => state = items;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  final items = [
    {
      'title': 'Air conditioner: cleaning',
      'due_date': '2026-10-08',
      'overdue': true
    }
  ];
  testWidgets(
      'Warning persists across routes, clears on completion, and preserves navigation state',
      (tester) async {
    final notifier = ReminderFake();
    final auth = TestAuth('a');
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => auth),
          maintenanceRemindersProvider.overrideWith((ref, user) => notifier),
        ],
        child: MaterialApp(
            navigatorKey: navigator,
            builder: (_, child) =>
                MaintenanceReminderHost(navigatorKey: navigator, child: child!),
            routes: {
              '/maintenance': (_) =>
                  const Scaffold(body: Text('Maintenance page'))
            },
            home: Scaffold(
                body: TextField(key: const ValueKey('retained-input'))))));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('retained-input')), 'Draft kept');
    notifier.showItems(items);
    await tester.pumpAndSettle();
    expect(find.text('1 overdue maintenance task'), findsOneWidget);
    expect(find.text('Draft kept'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-maintenance')));
    await tester.pumpAndSettle();
    expect(find.text('Maintenance page'), findsOneWidget);
    expect(find.text('1 overdue maintenance task'), findsOneWidget);
    notifier.showItems([]);
    await tester.pumpAndSettle();
    expect(find.text('1 overdue maintenance task'), findsNothing);
    expect(find.text('Maintenance page'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('Draft kept'), findsOneWidget);
    notifier.showItems(items);
    await tester.pumpAndSettle();
    auth.account(null);
    await tester.pumpAndSettle();
    expect(find.text('1 overdue maintenance task'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final width in [320.0, 1200.0]) {
    for (final dark in [false, true]) {
      testWidgets(
          'Warning wraps at large personal text sizes $width dark=$dark',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
            theme: dark ? ThemeData.dark() : ThemeData.light(),
            home: MediaQuery(
                data: MediaQueryData(
                    size: Size(width, 800),
                    textScaler: const PersonalTextScaler(
                        TypographyPreferences(
                            headings: 1.35,
                            titles: 1.35,
                            body: 1.35,
                            labels: 1.35),
                        TextScaler.linear(1.3))),
                child: Scaffold(
                    body: Align(
                        alignment: Alignment.topCenter,
                        child: MaintenanceWarningBanner(
                            items: items, onOpen: () {}))))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
