import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/pricing_rate_modal.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/app_dialog.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  final initial = <String, String>{
    'pricing_type': 'hub_purchase',
    'farm_id': 'farm',
    'plant_type': 'Lettuce',
    'crop_variety': 'Batavia',
    'packaging': 'Raw / Unpackaged',
    'unit': 'kg',
    'regular_price': '12',
    'bulk_price': '8',
    'owner_price_tier': 'Bulk',
    'status': 'Active'
  };
  for (final width in [320.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets(
          'pricing modal preserves choice, loading and errors at $width dark=$dark',
          (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final save = Completer<void>();
        var calls = 0;
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light,
                platform: width < 600
                    ? TargetPlatform.android
                    : TargetPlatform.windows),
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => showAppDialog(
                            context: context,
                            builder: (_) => PricingRateModal(
                                initial: initial,
                                farms: const {'farm': 'East'},
                                plants: const ['Lettuce', 'Basil'],
                                varieties: (plant) => plant == 'Basil'
                                    ? ['Genovese']
                                    : ['Batavia'],
                                packages: const [],
                                editing: true,
                                onSave: (values, apply) {
                                  calls++;
                                  expect(values['owner_price_tier'], 'Bulk');
                                  expect(apply, false);
                                  return save.future;
                                })),
                        child: const Text('Open'))))));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet),
            width < 600 ? findsOneWidget : findsNothing);
        expect(find.text('Edit farm purchase price'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Save pricing'));
        await tester.pump();
        expect(find.text('Saving…'), findsOneWidget);
        expect(calls, 1);
        expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNull);
        save.completeError(Exception('Unable to save pricing'));
        await tester.pumpAndSettle();
        await tester
            .ensureVisible(find.textContaining('Unable to save pricing'));
        expect(find.textContaining('Unable to save pricing'), findsOneWidget);
        expect(find.text('8'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  testWidgets('changing plant resets variety and valuation is explicit',
      (tester) async {
    Map<String, String>? submitted;
    bool? apply;
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: Scaffold(
            body: PricingRateModal(
                initial: initial,
                farms: const {'farm': 'East'},
                plants: const ['Lettuce', 'Basil'],
                varieties: (p) => p == 'Basil' ? ['Genovese'] : ['Batavia'],
                packages: const [],
                editing: false,
                onSave: (values, value) async {
                  submitted = values;
                  apply = value;
                }))));
    await tester.tap(find.byKey(const ValueKey('plant_type:Lettuce')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Basil').last);
    await tester.pumpAndSettle();
    expect(find.text('Genovese'), findsOneWidget);
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('Save pricing'));
    await tester.pumpAndSettle();
    expect(submitted?['crop_variety'], 'Genovese');
    expect(apply, true);
  });
}
