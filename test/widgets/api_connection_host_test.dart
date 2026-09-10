import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/api_connection_host.dart';
import 'package:farmestates_ai_dashbaord/services/api_connection.dart';

void main() {
  for (final width in [320.0, 1440.0]) {
    testWidgets('connection recovery preserves the screen at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = ApiConnection();
      final probe = Completer<bool>();
      final controller = TextEditingController(text: 'Unsaved farm name');
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: ApiConnectionHost(
              connection: state,
              child: Scaffold(body: TextField(controller: controller)))));
      unawaited(state.failed(() => probe.future, submission: true));
      await tester.pump();
      expect(find.text('Let’s reconnect'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(find.text('Connecting…'), findsOneWidget);
      expect(tester.takeException(), isNull);
      probe.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Let’s reconnect'), findsNothing);
      expect(controller.text, 'Unsaved farm name');
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
  }
}
