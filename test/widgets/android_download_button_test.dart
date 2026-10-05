import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/android_download_button.dart';
void main() {
  test('Shown on every browser and native desktops only', () {
    for (final platform in TargetPlatform.values) {
      expect(showAndroidDownload(web: true, platform: platform), isTrue);
      expect(showAndroidDownload(web: false, platform: platform), [TargetPlatform.windows, TargetPlatform.macOS, TargetPlatform.linux].contains(platform));
    }
  });
  test('Download URL is stable when viewing nested web routes', () {
    expect(androidApkUri(web: true, browserBase: Uri.parse('https://example.com/farm-manager/batch-generation')).toString(), 'https://example.com/downloads/farm-estates.apk');
  });
  testWidgets('Native Android hides icon and Windows shows it', (tester) async {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AndroidDownloadButton())));
    expect(find.byTooltip('Download Android APK'), findsNothing);
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AndroidDownloadButton())));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AndroidDownloadButton(key: UniqueKey()))));
    expect(find.byTooltip('Download Android APK'), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
