import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Shared Inter typography: semibold headings, medium labels, regular body.
class AppTypography {
  static const microSize = 10.0;
  static const fieldLabelSize = 11.0;
  static const captionSize = 12.0;
  static const actionSize = 13.0;
  static const bodySize = 14.0;
  static const cardTitleSize = 16.0;
  static const sectionTitleSize = 18.0;
  static const headingSize = 20.0;
  static const pageTitleSize = 24.0;
  static const metricSize = 28.0;
  static const displaySize = 32.0;

  /// Quantize custom responsive text to the shared scale before Flutter applies
  /// the user's accessibility text scaling.
  static double? resolveSize(double? size) {
    if (size == null) return null;
    const scale = [
      microSize,
      fieldLabelSize,
      captionSize,
      actionSize,
      bodySize,
      cardTitleSize,
      sectionTitleSize,
      headingSize,
      pageTitleSize,
      metricSize,
      displaySize
    ];
    return scale.reduce((a, b) => (a - size).abs() < (b - size).abs() ? a : b);
  }

  static const headingWeight = FontWeight.w600;
  static const labelWeight = FontWeight.w500;
  static const bodyWeight = FontWeight.w400;

  /// One font factory for shared tokens and custom screen text.
  static final font = GoogleFonts.inter;

  static TextTheme get textTheme => TextTheme(
        displayLarge: h1,
        displayMedium: h2,
        displaySmall: h3,
        headlineLarge: h4,
        headlineMedium: h5,
        headlineSmall: h6,
        titleLarge: titleMedium,
        titleMedium: font(
            fontSize: AppTypography.cardTitleSize, fontWeight: headingWeight),
        titleSmall:
            font(fontSize: AppTypography.bodySize, fontWeight: labelWeight),
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelSmall,
        labelSmall: caption,
      );

  // ========== TITLES (Inter) ==========

  static TextStyle get title => font(
        fontSize: AppTypography.headingSize,
        fontWeight: headingWeight,
        height: 1.3,
      );

  static TextStyle get titleLarge => font(
        fontSize: AppTypography.pageTitleSize,
        fontWeight: headingWeight,
        height: 1.2,
      );

  static TextStyle get titleMedium => font(
        fontSize: AppTypography.sectionTitleSize,
        fontWeight: headingWeight,
        height: 1.3,
      );

  static TextStyle get titleSmall => font(
        fontSize: AppTypography.cardTitleSize,
        fontWeight: headingWeight,
        height: 1.4,
      );

  // ========== SENSOR VALUES (Inter) ==========

  static TextStyle get sensorValue => font(
        fontSize: AppTypography.pageTitleSize,
        fontWeight: headingWeight,
        height: 1.2,
      );

  static TextStyle get sensorValueLarge => font(
        fontSize: AppTypography.displaySize,
        fontWeight: headingWeight,
        height: 1.2,
      );

  static TextStyle get sensorValueSmall => font(
        fontSize: AppTypography.headingSize,
        fontWeight: headingWeight,
        height: 1.3,
      );

  // ========== BODY TEXT (Inter) ==========

  static TextStyle get body => font(
        fontSize: AppTypography.bodySize,
        fontWeight: bodyWeight,
        height: 1.5,
      );

  static TextStyle get bodyLarge => font(
        fontSize: AppTypography.cardTitleSize,
        fontWeight: bodyWeight,
        height: 1.5,
      );

  static TextStyle get bodyMedium => font(
        fontSize: AppTypography.bodySize,
        fontWeight: bodyWeight,
        height: 1.5,
      );

  static TextStyle get bodySmall => font(
        fontSize: AppTypography.captionSize,
        fontWeight: bodyWeight,
        height: 1.5,
      );

  // ========== LABELS & CAPTIONS ==========

  static TextStyle get button => font(
        fontSize: AppTypography.actionSize,
        fontWeight: labelWeight,
        color: AppColors.textOnPrimary,
        height: 1.4,
        letterSpacing: 0.5,
      );

  static TextStyle get label => font(
        fontSize: AppTypography.fieldLabelSize,
        fontWeight: labelWeight,
        height: 1.4,
      );

  static TextStyle get labelSmall => font(
        fontSize: AppTypography.captionSize,
        fontWeight: labelWeight,
        height: 1.4,
      );

  static TextStyle get caption => font(
        fontSize: AppTypography.captionSize,
        fontWeight: bodyWeight,
        height: 1.3,
      );

  static TextStyle get overline => font(
        fontSize: AppTypography.microSize,
        fontWeight: labelWeight,
        height: 1.6,
        letterSpacing: 1.5,
      );

  // ========== SPECIALIZED STYLES ==========

  /// Sensor unit labels (°C, %, ppm, etc.)
  static TextStyle get sensorUnit => font(
        fontSize: AppTypography.captionSize,
        fontWeight: bodyWeight,
        height: 1.4,
      );

  /// Alert message text
  static TextStyle get alertText => font(
        fontSize: AppTypography.bodySize,
        fontWeight: labelWeight,
        height: 1.5,
      );

  /// Status badge text
  static TextStyle get statusBadge => font(
        fontSize: AppTypography.fieldLabelSize,
        fontWeight: headingWeight,
        height: 1.2,
        letterSpacing: 0.5,
      );

  /// Chart axis labels
  static TextStyle get chartLabel => font(
        fontSize: AppTypography.fieldLabelSize,
        fontWeight: bodyWeight,
        height: 1.3,
      );

  // ========== HELPER METHODS ==========

  /// Apply color to any text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply weight to any text style
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Apply size to any text style
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: AppTypography.resolveSize(size));
  }

  // ========== BACKWARD COMPATIBILITY ALIASES ==========

  /// Legacy h1-h6 aliases for existing code
  static TextStyle get h1 =>
      titleLarge.copyWith(fontSize: AppTypography.displaySize);
  static TextStyle get h2 =>
      titleLarge.copyWith(fontSize: AppTypography.metricSize);
  static TextStyle get h3 =>
      titleLarge.copyWith(fontSize: AppTypography.pageTitleSize);
  static TextStyle get h4 =>
      titleMedium.copyWith(fontSize: AppTypography.headingSize);
  static TextStyle get h5 =>
      titleMedium.copyWith(fontSize: AppTypography.sectionTitleSize);
  static TextStyle get h6 =>
      titleSmall.copyWith(fontSize: AppTypography.cardTitleSize);

  /// Legacy label alias
  static TextStyle get labelLarge =>
      label.copyWith(fontSize: AppTypography.actionSize);
}
