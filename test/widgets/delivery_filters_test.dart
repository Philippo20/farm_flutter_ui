import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/delivery_filters.dart';

void main() {
  for (final width in [320.0, 400.0, 800.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('filters at $width dark=$dark', (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = TextEditingController();
        var farm = 'All Farms', status = 'All';
        await tester.pumpWidget(MaterialApp(
          theme: dark ? ThemeData.dark() : ThemeData.light(),
          home: Scaffold(body: SingleChildScrollView(child: StatefulBuilder(
            builder: (context, update) => DeliveryFilters(
              searchController: controller,
              farms: const ['All Farms', 'Northern production farm with a long name'],
              farm: farm, status: status, resultCount: 12,
              onSearchChanged: (_) => update(() {}),
              onFarmChanged: (value) => update(() => farm = value),
              onStatusChanged: (value) => update(() => status = value),
              onReset: () => update(() {controller.clear(); farm = 'All Farms'; status = 'All';}),
            ),
          ))),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.enterText(find.byType(TextField), 'Tomato');
        await tester.pump();
        expect(find.text('Reset'), findsOneWidget);
        await tester.tap(find.text('All statuses'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delivered').last);
        await tester.pumpAndSettle();
        expect(status, 'Delivered');
        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();
        expect(controller.text, isEmpty);
        expect(status, 'All');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      });
    }
  }
}
