import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/services/local_alerts_native.dart';

void main() {
  const channel = MethodChannel('farmestates/message_notifications');
  for (final granted in [false, true]) {
    testWidgets('reports the Android permission choice granted=$granted',
        (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
          (call) async {
        expect(call.method, 'requestPermission');
        return granted;
      });
      expect(await LocalAlerts().requestPermission(), granted);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }
  testWidgets('a permission platform error safely reports disabled',
      (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel, (_) async => throw PlatformException(code: 'unavailable'));
    expect(await LocalAlerts().requestPermission(), false);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
