import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/theme/app_theme.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/audit_log_card.dart';

void main() {
  for (final width in [260.0, 500.0, 900.0]) {
    for (final dark in [false, true]) {
      testWidgets('audit event fits $width dark=$dark and opens details',
          (tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var opened = 0;
        await tester.pumpWidget(MaterialApp(
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: Scaffold(
                body: SingleChildScrollView(
                    child: AuditLogCard(
                        action:
                            'Updated a greenhouse environmental sensor configuration',
                        category: 'Configuration',
                        severity: 'Warning',
                        user: 'Administrator with a long display name',
                        farm:
                            'North greenhouse propagation and nursery extension',
                        module: 'Sensor management',
                        timestamp: '10 September 2026, 14:36',
                        id: 'event-1234567890-abcdefghij',
                        icon: Icons.settings_outlined,
                        categoryColor: Colors.blue,
                        severityColor: Colors.orange,
                        onDetails: () => opened++)))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('View details'));
        await tester.tap(find.text('View details'));
        expect(opened, 1);
        expect(find.text('Performed by'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
