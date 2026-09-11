import 'package:farmestates_ai_dashbaord/providers/auth_provider.dart';
import 'package:farmestates_ai_dashbaord/services/auth_service.dart';
import 'package:farmestates_ai_dashbaord/models/user_model.dart';
import 'package:farmestates_ai_dashbaord/models/enums.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmestates_ai_dashbaord/core/theme/app_theme.dart';
import 'package:farmestates_ai_dashbaord/screens/caretaker/chat_screen.dart';
import 'package:farmestates_ai_dashbaord/services/messaging_service.dart';

class FakeMessages extends MessagingService {
  int polls = 0;
  bool closed = false;
  Completer<List<Map<String, dynamic>>>? pending;
  @override
  Future<List<Map<String, dynamic>>> conversations() async {
    polls++;
    if (pending != null) return pending!.future;
    return [
      {
        'id': 'peer',
        'name': 'Farm manager',
        'role': 'Farm Manager',
        'unread': 0,
        'lastMessage': 'Hello',
        'updated_at': '2026-09-11T08:00:00Z'
      }
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> messages(String peer) async => [
        {
          'id': 'm1',
          'sender': 'other',
          'text': 'Hello from the farm team',
          'created_at': '2026-09-11T08:00:00Z',
          'read_at': '2026-09-11T08:01:00Z'
        }
      ];
  @override
  void dispose() {
    closed = true;
    super.dispose();
  }
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });
  for (final width in [900.0, 1440.0]) {
    for (final caretaker in [false, true]) {
      testWidgets(
          'Windows chat lays out and stops polling after closing at $width caretaker=$caretaker',
          (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = FakeMessages();
        await tester.pumpWidget(ProviderScope(
            overrides: caretaker
                ? [
                    authProvider.overrideWith((ref) {
                      final notifier = AuthNotifier(AuthService());
                      notifier.state = AuthState(
                          user: UserModel(
                              id: 'user',
                              name: 'Caretaker Test',
                              email: 'caretaker@example.test',
                              role: UserRole.caretaker,
                              address: '',
                              createdAt: DateTime(2026),
                              updatedAt: DateTime(2026)),
                          isAuthenticated: true);
                      return notifier;
                    })
                  ]
                : [],
            child: MaterialApp(
                theme: AppTheme.lightTheme
                    .copyWith(platform: TargetPlatform.windows),
                home: ChatScreen(messagingService: api))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Farm manager'));
        await tester.pumpAndSettle();
        expect(find.text('Hello from the farm team'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 15));
        final polls = api.polls;
        await tester.pump(const Duration(seconds: 10));
        expect(api.polls, polls);
        expect(api.closed, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('in-flight refresh can finish after chat is disposed',
      (tester) async {
    final api = FakeMessages()
      ..pending = Completer<List<Map<String, dynamic>>>();
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: ChatScreen(messagingService: api))));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    api.pending!.complete([]);
    await tester.pump(const Duration(seconds: 10));
    expect(api.closed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
