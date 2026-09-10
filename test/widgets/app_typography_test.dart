import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/theme/app_theme.dart';
import 'package:farmestates_ai_dashbaord/core/theme/app_typography.dart';

void main() {
  testWidgets('every material text role uses Inter in both themes',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      final t = theme.textTheme;
      for (final style in [
        t.displayLarge,
        t.displayMedium,
        t.displaySmall,
        t.headlineLarge,
        t.headlineMedium,
        t.headlineSmall,
        t.titleLarge,
        t.titleMedium,
        t.titleSmall,
        t.bodyLarge,
        t.bodyMedium,
        t.bodySmall,
        t.labelLarge,
        t.labelMedium,
        t.labelSmall
      ]) {
        expect(style, isNotNull);
        expect(style!.fontFamily, startsWith('Inter'));
        expect(
            style.fontWeight!.index, lessThanOrEqualTo(FontWeight.w600.index));
        if (theme.brightness == Brightness.dark)
          expect(style.color, Colors.white);
      }
    }
    expect(AppTypography.bodyMedium.fontWeight, FontWeight.w400);
    expect(AppTypography.label.fontWeight, FontWeight.w500);
    expect(AppTypography.title.fontWeight, FontWeight.w600);
    expect(AppTypography.bodyMedium.color, isNull);
    expect(AppTypography.bodyMedium.fontSize, AppTypography.bodySize);
    expect(AppTypography.titleLarge.fontSize, AppTypography.pageTitleSize);
    expect(AppTypography.titleSmall.fontSize, AppTypography.cardTitleSize);
    expect(AppTypography.label.fontSize, AppTypography.fieldLabelSize);
    expect(AppTypography.resolveSize(11.5), AppTypography.captionSize);
    expect(AppTypography.resolveSize(48), AppTypography.displaySize);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: Text('Inherits the shared font'))));
    expect(tester.takeException(), isNull);
  });
}
