import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmestates_ai_dashbaord/models/enums.dart';
import 'package:farmestates_ai_dashbaord/models/user_model.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/notification_center.dart';
import 'package:farmestates_ai_dashbaord/core/models/notification/notification_model.dart';
import 'package:farmestates_ai_dashbaord/core/models/notification/notification_destination.dart';
import 'package:farmestates_ai_dashbaord/core/providers/notification_provider.dart';

class OfflineInbox extends NotificationNotifier {
  OfflineInbox(List<NotificationModel> items) {
    state = items;
  }
  @override
  Future<void> refreshFromBackend({String? recipientId}) async {}
  @override
  void markAsRead(String id, {String? recipientId}) {
    state = [
      for (final item in state)
        item.id == id ? item.copyWith(isRead: true) : item
    ];
  }
}

NotificationModel notice(String kind, {String? message, String? url}) =>
    NotificationModel(
        id: kind,
        title: 'Update $kind',
        message: message ?? 'Please review this update.',
        type: NotificationType.fromString(kind),
        createdAt: DateTime(2026, 10, 6, 13, 30),
        actionUrl: url,
        metadata: {'sourceType': kind});

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  test('destinations respect roles, ignore external URLs and all routes exist',
      () {
    expect(
        notificationDestination(notice('account_review'), UserRole.caretaker),
        isNull);
    expect(
        notificationDestination(
            notice('system', url: '/superadmin/config'), UserRole.caretaker),
        isNull);
    expect(
        notificationDestination(
            notice('unknown', url: 'https://example.com'), UserRole.admin),
        isNull);
    expect(notificationDestination(notice('financial'), UserRole.accountant),
        isNull);
    expect(
        notificationDestination(notice('fund_request'), UserRole.accountant)
            ?.route,
        '/accountant/approvals');
    final main = File('lib/main.dart').readAsStringSync();
    for (final role in UserRole.values) {
      for (final kind in [
        'task',
        'maintenance',
        'batch',
        'harvest',
        'issue',
        'inventory',
        'delivery',
        'sales',
        'fund_request',
        'withdrawal',
        'account_review',
        'sensor_alert',
        'inventory_alert'
      ]) {
        final destination = notificationDestination(notice(kind), role);
        if (destination != null) {
          expect(main, contains("'${destination.route}':"));
        }
      }
    }
  });

  for (final size in [
    const Size(320, 640),
    const Size(800, 360),
    const Size(1440, 900)
  ]) {
    for (final dark in [false, true]) {
      testWidgets('Full message scrolls with fixed footer at $size dark=$dark',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final full =
            '${List.filled(70, 'The complete farm update remains readable.').join(' ')} END OF MESSAGE';
        final container = ProviderContainer(overrides: [
          notificationViewerProvider.overrideWith((ref) => null),
          notificationProvider.overrideWith(
              (ref) => OfflineInbox([notice('system', message: full)])),
        ]);
        addTearDown(container.dispose);
        await tester.pumpWidget(UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData(
                  brightness: dark ? Brightness.dark : Brightness.light),
              home: const Scaffold(
                  body: Center(child: NotificationDialog(loadOnOpen: false))),
            )));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Read message'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Read message'));
        await tester.pumpAndSettle();
        final text = tester.widget<SelectableText>(
            find.byKey(const ValueKey('full-notification-message')));
        expect(text.data, full);
        expect(text.maxLines, isNull);
        final footer =
            tester.getRect(find.widgetWithText(FilledButton, 'Done'));
        await tester.drag(
            find.byType(SingleChildScrollView), const Offset(0, -1600));
        await tester.pumpAndSettle();
        expect(
            tester.getRect(find.widgetWithText(FilledButton, 'Done')), footer);
        expect(container.read(notificationProvider).single.isRead, true);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Back'));
        await tester.pumpAndSettle();
        expect(find.text('Read message'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('Action closes the sheet before opening the correct screen',
      (tester) async {
    final user = UserModel(
        id: 'caretaker',
        name: 'Test',
        email: 'test@example.com',
        role: UserRole.caretaker,
        address: '',
        createdAt: DateTime(2026));
    final container = ProviderContainer(overrides: [
      notificationViewerProvider.overrideWith((ref) => user),
      notificationProvider
          .overrideWith((ref) => OfflineInbox([notice('task')])),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          routes: {
            '/calendar': (_) =>
                const Scaffold(body: Text('Task calendar destination'))
          },
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () => showNotificationDialog(context),
                      child: const Text('Open inbox')))),
        )));
    await tester.tap(find.text('Open inbox'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read message'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('full-notification-message')),
        findsOneWidget);
    await tester.tap(find.text('View calendar'));
    await tester.pumpAndSettle();
    expect(find.text('Task calendar destination'), findsOneWidget);
    expect(find.byType(NotificationDialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
