import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/theme/app_theme.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/delivery_kpi_grid.dart';

void main() {
  for (final width in [320.0, 600.0, 1440.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('delivery KPIs fit at $width with text scale $scale',
          (tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
            theme: AppTheme.darkTheme,
            home: MediaQuery(
                data: MediaQueryData(
                    size: Size(width, 900),
                    textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                    body: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: DeliveryKpiGrid(
                            mobile: width < 600,
                            total: 1234567,
                            pending: 1024,
                            inTransit: 98,
                            delivered: 256))))));
        await tester.pumpAndSettle();
        expect(find.text('Pending Approval'), findsOneWidget);
        expect(find.text('Delivered'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
