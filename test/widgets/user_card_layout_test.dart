import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/user_card_layout.dart';

void main() {
  for (final width in [320.0, 700.0, 1100.0]) {
    testWidgets('User cards fit and wrap at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
        child: UserCardLayout(children: [
          for (var i = 0; i < 4; i++) Container(key: ValueKey(i), height: 200, color: Colors.green),
        ]),
      ))));
      expect(tester.takeException(), isNull);
      final first = tester.getRect(find.byKey(const ValueKey(0)));
      final second = tester.getRect(find.byKey(const ValueKey(1)));
      expect(first.width, lessThanOrEqualTo(width));
      if (width == 320) {
        expect(second.top, first.bottom + 12);
      } else {
        expect(second.top, first.top);
        expect(second.left, first.right + 12);
      }
    });
  }
}
