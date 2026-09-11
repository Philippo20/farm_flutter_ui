import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
      addTearDown(state.dispose);
      var offline = true;
      final probe = Completer<bool>();
      final controller = TextEditingController(text: 'Unsaved farm name');
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: ApiConnectionHost(
              connection: state,
              child: Scaffold(body: TextField(controller: controller)))));
      unawaited(state.failed(() async => offline ? false : probe.future,
          submission: true));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(find.text('Let’s reconnect'), findsOneWidget);
      offline = false;
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
  testWidgets('Windows focus changes keep the visible app connected',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final state = ApiConnection();
    addTearDown(state.dispose);
    tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(MaterialApp(
        home: ApiConnectionHost(connection: state, child: const SizedBox())));
    final epoch = state.lifecycleEpoch;
    tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(state.foreground, isTrue);
    expect(state.lifecycleEpoch, epoch);
    tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    expect(state.foreground, isFalse);
    tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 2));
    expect(state.foreground, isTrue);
    expect(state.unavailable, isFalse);
    await tester.pumpWidget(const SizedBox());
    debugDefaultTargetPlatformOverride = null;
  });
}
