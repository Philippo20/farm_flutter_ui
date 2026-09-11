import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/theme/app_theme.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/app_dialog.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/desktop_account_dialog.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/adaptive_profile_menu.dart';
import 'package:farmestates_ai_dashbaord/providers/auth_provider.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final width in [800.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('account dialog $width dark=$dark handles long identity',
          (tester) async {
        tester.view.physicalSize = Size(width, 650);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        String? selection;
        await tester.pumpWidget(MaterialApp(
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        child: const Text('Open'),
                        onPressed: () async {
                          selection = await showAppDialog<String>(
                              context: context,
                              builder: (_) => const DesktopAccountDialog(
                                      name:
                                          'Administrator with a long account display name',
                                      email:
                                          'long.account.address@farmestates.example',
                                      role: 'Super Administrator',
                                      items: [
                                        PopupMenuItem(
                                            value: 'profile',
                                            child: Text('Profile')),
                                        PopupMenuItem(
                                            value: 'settings',
                                            child: Text('Settings')),
                                        PopupMenuItem(
                                            value: 'team_messages',
                                            child: Text('Messages')),
                                        PopupMenuItem(
                                            value: 'logout',
                                            child: Text('Logout'))
                                      ]));
                        })))));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Your account'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final footer = tester.getTopLeft(find.text('Log out'));
        await tester.drag(
            find.byType(SingleChildScrollView).first, const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('Log out')), footer);
        await tester.tap(find.text('Log out'));
        await tester.pumpAndSettle();
        expect(selection, 'logout');
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('desktop profile trigger retains existing selection callbacks',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? selected;
    await tester.pumpWidget(ProviderScope(
        overrides: [currentUserProvider.overrideWith((ref) => null)],
        child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
                body: AdaptiveProfilePopupMenuButton(
                    itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'profile', child: Text('Profile'))
                        ],
                    onSelected: (value) => selected = value,
                    child: const Text('Account trigger'))))));
    await tester.tap(find.text('Account trigger'));
    await tester.pumpAndSettle();
    expect(find.byType(DesktopAccountDialog), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Log out'), findsNothing);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(selected, 'profile');
    expect(tester.takeException(), isNull);
  });
}
