import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/mobile_navigation_bar.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('Five destinations fit a narrow screen, dark=$dark',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var tapped = -1;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
        home: MediaQuery(
          data: const MediaQueryData(
              size: Size(320, 640),
              padding: EdgeInsets.only(bottom: 24),
              textScaler: TextScaler.linear(2)),
          child: Scaffold(
              bottomNavigationBar: MobileNavigationBar(children: [
            for (var index = 0; index < 5; index++)
              MobileNavigationDestination(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Destination $index',
                  selected: index == 0,
                  onTap: () => tapped = index),
          ])),
        ),
      ));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Destination 3'));
      expect(tapped, 3);
      expect(tester.getSize(find.byType(InkWell).first).height,
          greaterThanOrEqualTo(48));
      final bottom = tester.getBottomLeft(find.byType(InkWell).first).dy;
      expect(bottom, lessThanOrEqualTo(616));
    });
  }
}
