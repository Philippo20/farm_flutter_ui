import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/services/android_app_updates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/app_updates');
  final source =
      Uri.parse('https://apps.farmestates.farm/downloads/android-release.json');
  final hash = List.filled(64, 'a').join();
  Map<String, dynamic> feed({int build = 12}) => {
        'version': '1.0.0',
        'buildNumber': build,
        'packageName': 'farm.test',
        'sizeBytes': 100,
        'sha256': hash,
        'apkUrl': 'farm-estates.apk',
      };
  Map<String, dynamic> downloadState = {};
  final calls = <String>[];
  String installation = 'opened';
  bool verifyFails = false;
  bool installVerifyFails = false;
  setUp(() {
    downloadState = {'status': 'none'};
    calls.clear();
    installation = 'opened';
    verifyFails = false;
    installVerifyFails = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'installedVersion':
          return {
            'version': '1.0.0',
            'buildNumber': 11,
            'packageName': 'farm.test'
          };
        case 'downloadState':
          return downloadState;
        case 'startDownload':
          return downloadState;
        case 'verifyDownload':
          if (verifyFails) throw PlatformException(code: 'invalid_update');
          return null;
        case 'installDownload':
          if (installVerifyFails)
            throw PlatformException(code: 'invalid_update');
          return installation;
        case 'allowInstallation':
          return null;
        case 'canInstall':
          return true;
      }
      return null;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));
  AndroidAppUpdates service(Map<String, dynamic> data, {int status = 200}) {
    final updates = AndroidAppUpdates(
        channel: channel,
        manifestUrl: source,
        client: MockClient((request) async {
          expect(request.headers['Cache-Control'], 'no-cache');
          return http.Response(jsonEncode(data), status);
        }));
    addTearDown(updates.dispose);
    return updates;
  }

  test('offers only a newer build for the installed package', () async {
    final updates = service(feed());
    expect(await updates.check(), isTrue);
    expect(updates.release!.build, 12);
    expect(updates.release!.url.queryParameters['v'], hash);
    expect(calls, isNot(contains('startDownload')));
    expect(await service(feed(build: 11)).check(), isFalse);
    expect(await service({...feed(), 'packageName': 'another.app'}).check(),
        isFalse);
  });
  test(
      'untrusted origins, bad hashes and non-HTTPS feeds cannot advertise APKs',
      () {
    for (final changes in [
      {'apkUrl': 'https://other.test/downloads/a.apk'},
      {'sha256': 'bad'},
      {'apkUrl': '/private/a.apk'},
      {'sizeBytes': -1},
      {'buildNumber': '12'},
    ]) {
      expect(() => AndroidRelease.parse({...feed(), ...changes}, source),
          throwsFormatException);
    }
    expect(
        () => AndroidRelease.parse(feed(),
            Uri.parse('http://apps.farmestates.farm/downloads/release.json')),
        throwsFormatException);
  });
  test('missing release feed does not break normal app startup', () async {
    final updates = service({}, status: 404);
    expect(await updates.check(), isFalse);
    expect(updates.error, isNull);
    expect(calls, isNot(contains('startDownload')));
  });
  test('restores an Android background download and its progress', () async {
    downloadState = {
      'status': 'running',
      'buildNumber': 12,
      'sha256': hash,
      'receivedBytes': 40,
      'totalBytes': 100
    };
    final updates = service(feed());
    expect(await updates.check(), isTrue);
    expect(updates.phase, AppUpdatePhase.downloading);
    expect(updates.progress, .4);
    expect(calls, isNot(contains('startDownload')));
  });
  test('verified download opens installer only after the user action',
      () async {
    final updates = service(feed());
    await updates.check();
    downloadState = {'status': 'complete'};
    await updates.download();
    expect(updates.phase, AppUpdatePhase.ready);
    expect(calls, contains('verifyDownload'));
    expect(calls, isNot(contains('installDownload')));
    await updates.install();
    expect(updates.phase, AppUpdatePhase.installing);
  });
  test('bad download cannot enter installer; retry preserves release choice',
      () async {
    final updates = service(feed());
    await updates.check();
    verifyFails = true;
    downloadState = {'status': 'complete'};
    await updates.download();
    await updates.install();
    expect(updates.phase, AppUpdatePhase.failed);
    expect(updates.release!.build, 12);
    expect(calls, isNot(contains('installDownload')));
    verifyFails = false;
    await updates.download();
    expect(updates.phase, AppUpdatePhase.ready);
  });
  test('a file changed after download verification requires a new download',
      () async {
    final updates = service(feed());
    await updates.check();
    downloadState = {'status': 'complete'};
    await updates.download();
    installVerifyFails = true;
    await updates.install();
    expect(updates.phase, AppUpdatePhase.failed);
    expect(updates.error, contains('download it again'));
  });

  test('install permission is requested after an install action and resumes it',
      () async {
    final updates = service(feed());
    await updates.check();
    downloadState = {'status': 'complete'};
    await updates.download();
    installation = 'permission';
    await updates.install();
    expect(updates.phase, AppUpdatePhase.permission);
    expect(calls, isNot(contains('allowInstallation')));
    await updates.allowInstallation();
    installation = 'opened';
    await updates.resumed();
    expect(updates.phase, AppUpdatePhase.installing);
    expect(calls, contains('canInstall'));
  });
}
