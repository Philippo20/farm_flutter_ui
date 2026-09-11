import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/screens/admin/traceability_console_screen.dart';

void main() {
  for (final width in [320.0, 800.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('traceability content cards $width dark=$dark',
          (tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var edits = 0;
        var reviews = 0;
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light),
            home: MediaQuery(
                data: MediaQueryData(
                    size: Size(width, 900), textScaler: TextScaler.linear(1.4)),
                child: Scaffold(
                    body: SingleChildScrollView(
                        child: Align(
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                                width: width < 600 ? width : 350,
                                child: Column(children: [
                                  TraceabilityPromotionCard(promotion: const {
                                    'title':
                                        'Fresh produce from our partner farms',
                                    'message':
                                        'Discover seasonal produce and learn more about where your food is grown.',
                                    'status': 'active'
                                  }, onEdit: () => edits++),
                                  TraceabilityFeedbackCard(feedback: const {
                                    'message':
                                        'Please review the packaging and production date for this product.',
                                    'feedback_type': 'issue',
                                    'batch_number':
                                        'FARM-2026-09-LONG-BATCH-REFERENCE',
                                    'rating': 4,
                                    'city': 'Accra',
                                    'region': 'Greater Accra',
                                    'country': 'Ghana'
                                  }, onTap: () => reviews++),
                                  const TraceabilityActivityCard(event: {
                                    'city': 'Accra',
                                    'region': 'Greater Accra',
                                    'country': 'Ghana',
                                    'device_type': 'mobile',
                                    'browser': 'Chrome',
                                    'operating_system': 'Android',
                                    'timezone': 'Africa/Accra',
                                    'isp': 'Example internet provider',
                                    'occurred_at': '2026-09-11T12:00:00Z'
                                  }),
                                ]))))))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Delete'), findsNothing);
        await tester.ensureVisible(find.text('Edit promotion'));
        await tester.tap(find.text('Edit promotion'));
        expect(edits, 1);
        await tester.ensureVisible(find.text('Review details'));
        await tester.tap(find.text('Review details'));
        expect(reviews, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
