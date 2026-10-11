import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:farmestates_ai_dashbaord/models/enums.dart';
import 'package:farmestates_ai_dashbaord/models/typography_preferences.dart';
import 'package:farmestates_ai_dashbaord/models/user_model.dart';
import 'package:farmestates_ai_dashbaord/providers/auth_provider.dart';
import 'package:farmestates_ai_dashbaord/services/personal_appearance_service.dart';
import 'package:farmestates_ai_dashbaord/core/providers/personal_appearance_provider.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/personal_typography_host.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/personal_date_picker.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/app_dialog.dart';
import 'package:farmestates_ai_dashbaord/widgets/gauge_widget.dart';
import 'package:farmestates_ai_dashbaord/screens/caretaker/widgets/sensor_overview_panel.dart';

const _preferences = TypographyPreferences(
    headings: 1.35, titles: 1.25, body: 1.15, labels: .85);
const _scaler = PersonalTextScaler(_preferences, TextScaler.linear(1.2));

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth()
      : super(AuthState(
            user: UserModel(
                id: 'font-user',
                name: 'Test',
                email: 'test@example.com',
                role: UserRole.admin,
                address: '',
                createdAt: DateTime(2026))));
  void role(UserRole role) =>
      state = AuthState(user: state.user!.copyWith(role: role));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Appearance extends Fake implements PersonalAppearanceService {
  @override
  Future<TypographyPreferences> load() async => _preferences;
  @override
  void dispose() {}
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });
  for (final width in [320.0, 1200.0]) {
    testWidgets(
        'all roles inherit actual text, input and overlay sizes at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = _Auth();
      await tester.pumpWidget(ProviderScope(
          overrides: [
            authProvider.overrideWith((_) => auth),
            personalAppearanceServiceProvider
                .overrideWith((ref, id) => _Appearance()),
          ],
          child: MaterialApp(
            theme: ThemeData(
                platform: width < 600
                    ? TargetPlatform.android
                    : TargetPlatform.windows,
                tooltipTheme:
                    const TooltipThemeData(textStyle: TextStyle(fontSize: 12))),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.2)),
                child: PersonalTypographyHost(child: child!)),
            home: Builder(
                builder: (context) => Scaffold(
                        body: ListView(children: [
                      for (final size in [24.0, 18.0, 14.0, 12.0])
                        Text('Size $size', style: TextStyle(fontSize: size)),
                      const Text.rich(TextSpan(
                          text: 'Mixed details',
                          style: TextStyle(fontSize: 12),
                          children: [
                            TextSpan(
                                text: ' Title', style: TextStyle(fontSize: 18))
                          ])),
                      const TextField(
                          style: TextStyle(fontSize: 14),
                          decoration: InputDecoration(hintText: 'Input hint')),
                      DropdownButtonFormField<String>(
                          initialValue: 'Value',
                          items: const [
                            DropdownMenuItem(
                                value: 'Value',
                                child: Text('Value',
                                    style: TextStyle(fontSize: 13)))
                          ],
                          onChanged: (_) {}),
                      Tooltip(
                          message: 'Full tooltip',
                          child: TextButton(
                              onPressed: () {},
                              child: const Text('Tooltip target'))),
                      TextButton(
                          onPressed: () => showAppDialog<void>(
                              context: context,
                              builder: (context) => AppDialog(
                                  child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Modal title',
                                                style: TextStyle(fontSize: 16)),
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child:
                                                    const Text('Close modal')),
                                          ])))),
                          child: const Text('Open modal')),
                      TextButton(
                          onPressed: () => ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                                  content: Text('Saved message',
                                      style: TextStyle(fontSize: 14)))),
                          child: const Text('Show message')),
                    ]))),
          )));
      await tester.pumpAndSettle();
      void expectSize(String text, double size) {
        final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
        expect(paragraph.textScaler.scale(size),
            closeTo(_scaler.scale(size), .001),
            reason: text);
      }

      for (final role in UserRole.values) {
        auth.role(role);
        await tester.pumpAndSettle();
        for (final size in [24.0, 18.0, 14.0, 12.0]) {
          expectSize('Size $size', size);
        }
        final input = tester
            .state<EditableTextState>(find.byType(EditableText))
            .renderEditable;
        expect(input.textScaler.scale(14), closeTo(_scaler.scale(14), .001));
        expectSize('Value', 13);
      }
      final mixed = tester
          .renderObject<RenderParagraph>(find.text('Mixed details Title'));
      expect(mixed.textScaler.scale(12), closeTo(_scaler.scale(12), .001));
      expect(mixed.textScaler.scale(18), closeTo(_scaler.scale(18), .001));
      await tester.longPress(find.text('Tooltip target'));
      await tester.pump(const Duration(seconds: 1));
      expectSize('Full tooltip', 12);
      await tester.tap(find.text('Open modal'));
      await tester.pumpAndSettle();
      expectSize('Modal title', 16);
      await tester.tap(find.text('Close modal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show message'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expectSize('Saved message', 14);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('date picker applies each category exactly once to painted text',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(textScaler: _scaler),
            child: PersonalDatePicker(
                picker: SfDateRangePicker(
              headerStyle: const DateRangePickerHeaderStyle(
                  textStyle: TextStyle(fontSize: 18)),
              monthCellStyle: const DateRangePickerMonthCellStyle(
                  textStyle: TextStyle(fontSize: 14)),
              selectionTextStyle: const TextStyle(fontSize: 14),
              initialDisplayDate: DateTime(2026, 10, 1),
            )))));
    await tester.pumpAndSettle();
    final picker =
        tester.widget<SfDateRangePicker>(find.byType(SfDateRangePicker));
    expect(picker.headerStyle.textStyle!.fontSize,
        closeTo(_scaler.scale(18), .001));
    expect(picker.monthCellStyle.textStyle!.fontSize,
        closeTo(_scaler.scale(14), .001));
    expect(
        picker.selectionTextStyle!.fontSize, closeTo(_scaler.scale(14), .001));
    expect(picker.monthViewSettings.viewHeaderStyle.textStyle!.fontSize,
        closeTo(_scaler.scale(14), .001));
    expect(
        MediaQuery.textScalerOf(tester.element(find.byType(SfDateRangePicker)))
            .scale(14),
        14);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'custom painted gauge follows scaling and repaints when it changes',
      (tester) async {
    Widget gauge(TextScaler scaler) => MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(textScaler: scaler),
            child: const Center(
                child: GaugeWidget(
                    value: 25,
                    minValue: 0,
                    maxValue: 100,
                    unit: 'C',
                    label: 'Temperature'))));
    await tester.pumpWidget(gauge(TextScaler.noScaling));
    final finder = find.byWidgetPredicate((widget) =>
        widget is CustomPaint &&
        widget.painter.runtimeType.toString() == '_GaugePainter');
    final old = tester.widget<CustomPaint>(finder).painter!;
    await tester.pumpWidget(gauge(_scaler));
    final updated = tester.widget<CustomPaint>(finder).painter!;
    final dynamic painter = updated;
    expect(painter.textScaler.scale(12.0), closeTo(_scaler.scale(12), .001));
    expect(updated.shouldRepaint(old), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sensor cards retain larger text at narrow mobile width',
      (tester) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const large = PersonalTextScaler(
        TypographyPreferences(
            headings: 1.35, titles: 1.35, body: 1.35, labels: 1.35),
        TextScaler.linear(1.2));
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data:
                const MediaQueryData(textScaler: large, size: Size(320, 1000)),
            child: const Scaffold(
                body: SingleChildScrollView(
                    child: SensorOverviewPanel(sensorData: {
              'temperature': {'hasSensor': true, 'value': 25.5},
              'humidity': {'hasSensor': true, 'value': 65.0},
            }))))));
    await tester.pumpAndSettle();
    expect(find.byType(FittedBox), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
