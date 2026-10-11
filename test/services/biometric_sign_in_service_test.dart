import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/services/biometric_sign_in_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('farmestates/biometric_signin');
  const service = BiometricSignInService();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('non-Android platforms never invoke biometric storage or prompts',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    messenger.setMockMethodCallHandler(
        channel, (_) async => fail('Unexpected native call'));
    expect((await service.status()).available, isFalse);
    expect(await service.enable('email', 'password'), isFalse);
    expect(await service.unlock(), isNull);
    await service.disable();
  });

  test('Android status and credential retrieval use the native secure channel',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'status':
          return {
            'available': true,
            'enabled': true,
            'email': 'user@example.com'
          };
        case 'enable':
          expect(call.arguments,
              {'email': 'user@example.com', 'password': 'secret'});
          return true;
        case 'credentials':
          return {'email': 'user@example.com', 'password': 'secret'};
        case 'disable':
          return null;
      }
      fail('Unknown method');
    });
    final status = await service.status();
    expect(status.available && status.enabled, isTrue);
    expect(status.email, 'user@example.com');
    expect(await service.enable('user@example.com', 'secret'), isTrue);
    expect((await service.unlock())?.password, 'secret');
    await service.disable();
    expect(calls, ['status', 'enable', 'credentials', 'disable']);
  });

  test('native cancellation is distinct from an invalid secret', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    expect(await service.unlock(), isNull);
    messenger.setMockMethodCallHandler(
        channel, (_) async => {'email': '', 'password': ''});
    await expectLater(service.unlock(), throwsA(isA<PlatformException>()));
  });
}
