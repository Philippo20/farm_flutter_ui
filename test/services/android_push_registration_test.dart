import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/services/android_push_registration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<MethodCall> native;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    native = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AndroidPushRegistration.channel,
            (call) async {
      native.add(call);
      if (call.method == 'pushToken') return 'token-test';
      if (call.method == 'pushDelivered') return ['message:m1', 'n1'];
      return null;
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AndroidPushRegistration.channel, null);
  });
  test('bind uses JWT, renewals are bounded, logout clears native and server',
      () async {
    final calls = <http.Request>[];
    final push = AndroidPushRegistration(
        jwt: () => 'jwt-alice',
        client: MockClient((r) async {
          calls.add(r);
          return http.Response('{}', 200);
        }));
    push.bind('alice');
    await push.sync();
    await push.sync();
    expect(calls.length, 1);
    expect(calls.single.headers['Authorization'], 'Bearer jwt-alice');
    expect(jsonDecode(calls.single.body), {'token': 'token-test'});
    expect(await push.delivered(), {'message:m1', 'n1'});
    push.bind(null);
    await Future<void>.delayed(Duration.zero);
    expect(native.last.arguments, {'recipientId': ''});
    expect(calls.last.method, 'DELETE');
    push.dispose();
  });
  test('late registration after logout is removed before another account binds',
      () async {
    final post = Completer<http.Response>();
    final calls = <String>[];
    final push = AndroidPushRegistration(
        jwt: () => 'jwt',
        client: MockClient((r) async {
          calls.add(r.method);
          return r.method == 'POST' ? post.future : http.Response('{}', 200);
        }));
    push.bind('alice');
    final pending = push.sync();
    await Future<void>.delayed(Duration.zero);
    push.bind(null);
    post.complete(http.Response('{}', 200));
    await pending;
    expect(calls, ['POST', 'DELETE']);
    push.dispose();
  });
  test('desktop never registers an Android token', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final push = AndroidPushRegistration(
        client: MockClient((_) async => throw StateError('must not run')));
    push.bind('alice');
    await push.sync();
    expect(native, isEmpty);
    push.dispose();
  });
}
