import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/widgets/responsive_metric_grid.dart';

void main() {
  testWidgets('compact metrics accommodate large text without inherited gaps',
      (tester) async {
    for (final width in [320.0, 390.0, 599.0]) {
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: MediaQueryData(
            size: Size(width, 800),
            padding: const EdgeInsets.only(top: 48, bottom: 34),
            textScaler: TextScaler.linear(2)),
        child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
                width: width,
                child: SingleChildScrollView(
                    child: ResponsiveMetricGrid(
                  useContentHeight: true,
                  crossAxisCount: 2,
                  childAspectRatio: 3.4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: List.generate(
                      4,
                      (index) => Container(
                            key: ValueKey(index),
                            padding: const EdgeInsets.all(16),
                            child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.payments),
                                  Text('GHS 123,456.00'),
                                  Text('Pending farm requests'),
                                ]),
                          )),
                )))),
      )));
      expect(tester.takeException(), isNull, reason: 'viewport $width');
      final first = tester.getRect(find.byKey(const ValueKey(0)));
      final third = tester.getRect(find.byKey(const ValueKey(2)));
      expect(first.top, 0);
      expect(third.top - first.bottom, 8);
    }
  });
}
