import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/app_dialog.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/delivery_details_modal.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final width in [320.0, 1200.0]) {
    testWidgets('Delivery details wraps long values at $width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(platform: TargetPlatform.windows),
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => showAppDialog<void>(
                          context: context,
                          builder: (_) => const DeliveryDetailsModal(
                                  reference:
                                      'delivery-very-long-reference-12345678901234567890',
                                  status: 'Pending approval',
                                  statusColor: Colors.orange,
                                  priority: 'High',
                                  sections: [
                                    DeliveryDetailSection(
                                        'Route', Icons.route, [
                                      (
                                        'Farm',
                                        'A very long farm name that must wrap across multiple lines'
                                      ),
                                      (
                                        'Destination',
                                        'Fulfillment center with a long address'
                                      )
                                    ]),
                                    DeliveryDetailSection(
                                        'Transport', Icons.local_shipping, [
                                      ('Driver', 'Assigned driver'),
                                      ('Vehicle', 'Vehicle registration')
                                    ])
                                  ])),
                      child: const Text('Open'))))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Delivery details'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(tester.getRect(find.text('Close')).bottom, lessThan(800));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });
  }
}
