import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmestates_ai_dashbaord/models/typography_preferences.dart';
import 'package:farmestates_ai_dashbaord/models/user_model.dart';
import 'package:farmestates_ai_dashbaord/models/enums.dart';
import 'package:farmestates_ai_dashbaord/providers/auth_provider.dart';
import 'package:farmestates_ai_dashbaord/services/personal_appearance_service.dart';
import 'package:farmestates_ai_dashbaord/core/providers/personal_appearance_provider.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/personal_typography_card.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/personal_typography_host.dart';

class TestAuth extends StateNotifier<AuthState> implements AuthNotifier {
  TestAuth(String id) : super(AuthState(user: user(id), isAuthenticated: true));
  static UserModel user(String id) => UserModel(
      id: id,
      name: id,
      email: '$id@example.com',
      role: UserRole.technician,
      address: '',
      createdAt: DateTime(2026));
  void account(String? id) => state = id == null
      ? AuthState()
      : AuthState(user: user(id), isAuthenticated: true);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AppearanceFake extends Fake implements PersonalAppearanceService {
  AppearanceFake(this.value);
  TypographyPreferences value;
  Completer<TypographyPreferences>? loading;
  bool fail = false;
  @override
  Future<TypographyPreferences> load() async => loading?.future ?? value;
  @override
  Future<TypographyPreferences> save(TypographyPreferences next) async {
    if (fail) throw Exception('Could not save sizes');
    return value = next;
  }

  @override
  void dispose() {}
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });
  test('Categories remain independent and preserve OS accessibility scaling',
      () {
    const sizes = TypographyPreferences(
        headings: 1.3, titles: 1.2, body: 1.1, labels: .9);
    const scaler = PersonalTextScaler(sizes, TextScaler.linear(1.5));
    expect(scaler.scale(24), closeTo(46.8, .001));
    expect(scaler.scale(18), closeTo(32.4, .001));
    expect(scaler.scale(14), closeTo(23.1, .001));
    expect(scaler.scale(12), closeTo(16.2, .001));
    expect(TypographyPreferences.fromJson({'body': 90, 'headings': 'bad'}),
        TypographyPreferences.defaults);
  });

  for (final width in [320.0, 1200.0]) {
    for (final dark in [false, true]) {
      testWidgets(
          'Preview is local until saved, retains failed edits at $width dark=$dark',
          (tester) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        TypographyPreferences? saved;
        var count = 0;
        final submit = Completer<void>();
        await tester.pumpWidget(MaterialApp(
            theme: (dark ? ThemeData.dark() : ThemeData.light()).copyWith(
                platform: width == 320
                    ? TargetPlatform.android
                    : TargetPlatform.windows),
            home: Scaffold(
                body: Builder(
                    builder: (context) => TextButton(
                        onPressed: () => showPersonalTypographyModal(context,
                                initial: TypographyPreferences.defaults,
                                onSave: (value) async {
                              count++;
                              saved = value;
                              await submit.future;
                            }),
                        child: const Text('Adjust'))))));
        await tester.tap(find.text('Adjust'));
        await tester.pumpAndSettle();
        final slider =
            tester.widget<Slider>(find.byKey(const ValueKey('font-headings')));
        slider.onChanged!(1.35);
        await tester.pumpAndSettle();
        expect(saved, isNull);
        final previewContext = tester.element(find.text('Your dashboard'));
        expect(MediaQuery.textScalerOf(previewContext).scale(24),
            closeTo(32.4, .001));
        expect(
            MediaQuery.textScalerOf(
                    tester.element(find.text('Personal text sizes')))
                .scale(24),
            24);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Save sizes'));
        await tester.pump();
        expect(find.text('Saving…'), findsOneWidget);
        expect(saved!.headings, 1.35);
        expect(count, 1);
        expect(
            tester
                .widget<Slider>(find.byKey(const ValueKey('font-headings')))
                .onChanged,
            isNull);
        submit.completeError(Exception('Backend unavailable'));
        await tester.pumpAndSettle();
        expect(find.text('Backend unavailable'), findsOneWidget);
        expect(
            tester
                .widget<Slider>(find.byKey(const ValueKey('font-headings')))
                .value,
            1.35);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Your dashboard'), findsNothing);
      });
    }
  }

  testWidgets(
      'Saved preferences follow the account; logout resets all routes and dialogs',
      (tester) async {
    final auth = TestAuth('a');
    final services = {
      'a': AppearanceFake(const TypographyPreferences(body: 1.25)),
      'b': AppearanceFake(const TypographyPreferences(body: .9))
    };
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => auth),
          personalAppearanceServiceProvider
              .overrideWith((ref, id) => services[id]!),
        ],
        child: MaterialApp(
            builder: (_, child) => PersonalTypographyHost(child: child!),
            home: const Scaffold(body: Text('Body', key: ValueKey('body'))))));
    await tester.pumpAndSettle();
    double scaled() => MediaQuery.textScalerOf(
            tester.element(find.byKey(const ValueKey('body'))))
        .scale(14);
    expect(scaled(), 17.5);
    auth.account('b');
    await tester.pumpAndSettle();
    expect(scaled(), closeTo(12.6, .001));
    auth.account(null);
    await tester.pumpAndSettle();
    expect(scaled(), 14);
    auth.account('a');
    await tester.pumpAndSettle();
    expect(scaled(), 17.5);
    await tester.pumpWidget(const SizedBox());
  });

  test('A late sync cannot overwrite a successful save', () async {
    final service = AppearanceFake(TypographyPreferences.defaults)
      ..loading = Completer();
    final notifier = PersonalAppearanceNotifier('a', service);
    await Future<void>.delayed(Duration.zero);
    await notifier.save(const TypographyPreferences(body: 1.3));
    service.loading!.complete(TypographyPreferences.defaults);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.value.body, 1.3);
    notifier.dispose();
  });
}
