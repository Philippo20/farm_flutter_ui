import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Grow Room Monitoring App - Typography System
/// Poppins for Titles (Bold, SemiBold) | Roboto for Body Text (Regular)
class AppTypography {
  // ========== TITLES (Poppins) ==========
  
  /// AppBar, Section Titles - Poppins Bold 22px
  static TextStyle get title => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.3,
      );
  
  /// Large Titles - Poppins Bold 28px
  static TextStyle get titleLarge => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        height: 1.2,
      );
  
  /// Medium Titles - Poppins SemiBold 20px
  static TextStyle get titleMedium => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );
  
  /// Small Titles - Poppins SemiBold 18px
  static TextStyle get titleSmall => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );
  
  // ========== SENSOR VALUES (Poppins) ==========
  
  /// Big sensor numbers - Poppins SemiBold 24px
  static TextStyle get sensorValue => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
      );
  
  /// Large sensor numbers - Poppins SemiBold 32px
  static TextStyle get sensorValueLarge => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
      );
  
  /// Small sensor numbers - Poppins SemiBold 18px
  static TextStyle get sensorValueSmall => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );
  
  // ========== BODY TEXT (Roboto) ==========
  
  /// Standard body text - Roboto Regular 16px
  static TextStyle get body => GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.5,
      );
  
  /// Large body text - Roboto Regular 18px
  static TextStyle get bodyLarge => GoogleFonts.roboto(
        fontSize: 18,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.5,
      );
  
  /// Medium body text - Roboto Regular 16px
  static TextStyle get bodyMedium => GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.5,
      );
  
  /// Small body text - Roboto Regular 14px
  static TextStyle get bodySmall => GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
        height: 1.5,
      );
  
  // ========== LABELS & CAPTIONS ==========
  
  /// Button labels - Roboto Medium 14px
  static TextStyle get button => GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textOnPrimary,
        height: 1.4,
        letterSpacing: 0.5,
      );
  
  /// Form labels - Roboto Medium 14px
  static TextStyle get label => GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
      );
  
  /// Small labels - Roboto Medium 12px
  static TextStyle get labelSmall => GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
      );
  
  /// Caption text - Roboto Regular 12px
  static TextStyle get caption => GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        height: 1.3,
      );
  
  /// Overline text - Roboto Medium 10px
  static TextStyle get overline => GoogleFonts.roboto(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.6,
        letterSpacing: 1.5,
      );
  
  // ========== SPECIALIZED STYLES ==========
  
  /// Sensor unit labels (°C, %, ppm, etc.)
  static TextStyle get sensorUnit => GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
        height: 1.4,
      );
  
  /// Alert message text
  static TextStyle get alertText => GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.5,
      );
  
  /// Status badge text
  static TextStyle get statusBadge => GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.5,
      );
  
  /// Chart axis labels
  static TextStyle get chartLabel => GoogleFonts.roboto(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
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
    return style.copyWith(fontSize: size);
  }
  
  // ========== BACKWARD COMPATIBILITY ALIASES ==========
  
  /// Legacy h1-h6 aliases for existing code
  static TextStyle get h1 => titleLarge.copyWith(fontSize: 48);
  static TextStyle get h2 => titleLarge.copyWith(fontSize: 40);
  static TextStyle get h3 => titleLarge.copyWith(fontSize: 32);
  static TextStyle get h4 => titleMedium.copyWith(fontSize: 28);
  static TextStyle get h5 => titleMedium.copyWith(fontSize: 24);
  static TextStyle get h6 => titleSmall.copyWith(fontSize: 20);
  
  /// Legacy label alias
  static TextStyle get labelLarge => label.copyWith(fontSize: 14);
}
