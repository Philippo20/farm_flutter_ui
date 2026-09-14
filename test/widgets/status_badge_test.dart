import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/status_badge.dart';
import 'package:farmestates_ai_dashbaord/core/models/batch/batch_model.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('All statuses fit a narrow card at text scale $scale',
        (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      for (final status in BatchStatus.values) {
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Center(
              child: SizedBox(width: 72.9, child: StatusBadge(status: status))),
        ))));
        expect(tester.takeException(), isNull, reason: status.name);
        expect(find.byTooltip(status.name), findsOneWidget);
      }
    });
  }
  testWidgets('Badge still shrink-wraps inside an unconstrained row',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: Row(children: [
      StatusBadge(status: BatchStatus.qualityChecked),
    ]))));
    expect(tester.takeException(), isNull);
    expect(find.text('qualityChecked'), findsOneWidget);
  });
}
