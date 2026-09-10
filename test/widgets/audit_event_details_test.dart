import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/theme/app_theme.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/app_dialog.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/audit_data_table.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/audit_event_details_modal.dart';

void main() {
  test('decodes nested JSON, arrays, raw text and false/empty/null values', () {
    final fields = decodeAuditFields(jsonEncode({
      'farm': {'active': false},
      'counts': [0, null],
      'empty': ''
    }));
    expect(fields['["farm"]["active"]'], false);
    expect(fields['["counts"][0]'], 0);
    expect(fields.containsKey('["counts"][1]'), isTrue);
    expect(fields['["empty"]'], '');
    expect(decodeAuditFields('Unstructured audit note')['Data'],
        'Unstructured audit note');
    expect(decodeAuditFields('"123"')['Data'], '123');
    expect(
        decodeAuditFields(jsonEncode(jsonEncode({'name': 'Farm'})))['["name"]'],
        'Farm');
    expect(decodeAuditFields(''), isEmpty);
  });
  for (final width in [320.0, 1440.0]) {
    for (final mode in ['both', 'new', 'previous']) {
      testWidgets('audit details $mode snapshots at $width', (tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
            theme: AppTheme.darkTheme,
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        child: const Text('Open'),
                        onPressed: () => showAppDialog<void>(
                            context: context,
                            builder: (_) => AuditEventDetailsModal(
                                  id: 'event-long-identifier-123456789',
                                  action: 'Updated greenhouse configuration',
                                  details: const {
                                    'User': 'Administrator with a long name',
                                    'Farm': 'North greenhouse'
                                  },
                                  copyText: 'Original event',
                                  previous: mode == 'new'
                                      ? ''
                                      : '{"active":false,"removed":"old","nested":{"value":0}}',
                                  current: mode == 'previous'
                                      ? ''
                                      : '{"active":true,"added":"new","nested":{"value":25}}',
                                )))))));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.byType(Table), findsOneWidget);
        expect(
            find.text(mode == 'both'
                ? 'Changes'
                : mode == 'new'
                    ? 'Event data'
                    : 'Previous data'),
            findsOneWidget);
        expect(tester.takeException(), isNull);
        if (mode == 'both') expect(find.text('Not present'), findsNWidgets(2));
        final position = tester.getTopLeft(find.text('Copy event'));
        await tester.drag(
            find.byType(SingleChildScrollView).first, const Offset(0, -700));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('Copy event')), position);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
