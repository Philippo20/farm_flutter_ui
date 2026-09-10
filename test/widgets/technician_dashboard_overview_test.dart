import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/technician_dashboard_overview.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('Dark text palette overrides light typography colors',
      (tester) async {
    for (final style in [
      AppTheme.darkTheme.textTheme.bodyLarge,
      AppTheme.darkTheme.textTheme.bodyMedium,
      AppTheme.darkTheme.textTheme.bodySmall,
      AppTheme.darkTheme.textTheme.displayLarge,
      AppTheme.darkTheme.textTheme.headlineSmall,
      AppTheme.darkTheme.textTheme.titleLarge,
      AppTheme.darkTheme.textTheme.labelLarge
    ]) {
      expect(style!.color, Colors.white);
    }
  });
  for (final width in [320.0, 800.0, 1440.0]) {
    testWidgets('Technician overview at $width fits data and navigates',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        theme: width == 800 ? AppTheme.darkTheme : AppTheme.lightTheme,
        routes: {
          '/sensor-management': (_) =>
              const Scaffold(body: Text('Sensor destination'))
        },
        home: Scaffold(
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: TechnicianDashboardOverview(
                  sensors: [
                    {
                      'status': 'Active',
                      'timestamp': DateTime.now().toIso8601String()
                    },
                    {'status': 'Inactive'}
                  ],
                  alerts: [
                    {'resolved': false},
                    {'resolved': true}
                  ],
                  tasks: [
                    {
                      'title': 'Replace the damaged greenhouse pump inlet seal',
                      'farm_name':
                          'Northern greenhouse and propagation extension',
                      'status': 'In Progress',
                      'due_date': '2026-09-10'
                    },
                    {'title': 'Finished task', 'status': 'Completed'},
                  ],
                ))),
      ));
      await tester.pumpAndSettle();
      expect(find.text('1 of 2 sensors online'), findsOneWidget);
      expect(find.text('1 open alerts need review'), findsOneWidget);
      expect(find.text('Finished task'), findsNothing);
      expect(find.text('Replace the damaged greenhouse pump inlet seal'),
          findsOneWidget);
      if (width == 800) {
        for (final label in [
          'Technical overview',
          'Sensor connectivity',
          'Upcoming work',
          'Workspace',
          'Replace the damaged greenhouse pump inlet seal'
        ]) {
          final element = tester.element(find.text(label));
          final text = tester.widget<Text>(find.text(label));
          final color =
              text.style?.color ?? DefaultTextStyle.of(element).style.color;
          expect(color, Colors.white, reason: label);
        }
      }
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('View sensors'));
      await tester.tap(find.text('View sensors'));
      await tester.pumpAndSettle();
      expect(find.text('Sensor destination'), findsOneWidget);
    });
  }
  testWidgets('Empty overview has no invented work or online percentage',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: TechnicianDashboardOverview(
                    sensors: [], tasks: [], alerts: [])))));
    expect(find.text('No sensors available'), findsOneWidget);
    expect(find.text('No open maintenance tasks.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
