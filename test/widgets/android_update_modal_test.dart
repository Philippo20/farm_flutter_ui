import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/android_update_host.dart';
import 'package:farmestates_ai_dashbaord/services/android_app_updates.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final dark in [false, true]) {
    testWidgets(
        'update progress stays usable on a narrow Android sheet, dark=$dark',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final updates = AndroidAppUpdates();
      addTearDown(updates.dispose);
      updates.release = AndroidRelease(
          build: 12,
          version: '1.0.0',
          packageName: 'farm.test',
          url: Uri.parse('https://apps.farmestates.farm/downloads/a.apk'),
          sha256: List.filled(64, 'a').join(),
          bytes: 80 * 1024 * 1024,
          notes:
              'Linked batch records, crop plant links and improvements to your farm workspace.');
      updates.currentVersion = '1.0.0 (11)';
      updates.phase = AppUpdatePhase.downloading;
      updates.progress = .4;
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(
              platform: TargetPlatform.android,
              brightness: dark ? Brightness.dark : Brightness.light),
          home: Scaffold(body: AndroidUpdateModal(updates: updates))));
      await tester.pump();
      expect(find.text('Downloading 40%'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
