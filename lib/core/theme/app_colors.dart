import 'package:flutter/material.dart';

/// Grow Room Monitoring App - Color System
/// Based on fresh farming green theme with professional status indicators
class AppColors {
  // ========== PRIMARY COLORS ==========
  /// Main green for buttons, AppBar, primary actions
  static const Color primary = Color(0xFF4CAF50); // Fresh farming green
  static const Color primaryLight = Color(0xFF80E27E);
  static const Color primaryDark = Color(0xFF087F23);
  
  // ========== SECONDARY COLORS ==========
  /// Light green for highlights and active states
  static const Color secondary = Color(0xFF8BC34A); // Soothing highlight green
  static const Color secondaryLight = Color(0xFFBEF67A);
  static const Color secondaryDark = Color(0xFF5A9216);
  
  // ========== STATUS COLORS ==========
  /// Sensor status indicators
  static const Color statusGood = Color(0xFF4CAF50); // Green - All OK
  static const Color statusWarning = Color(0xFFFFA726); // Orange - Attention needed
  static const Color statusDanger = Color(0xFFF44336); // Red - Critical issue
  static const Color statusInfo = Color(0xFF29B6F6); // Blue - Information
  
  // ========== SEMANTIC COLORS ==========
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF29B6F6);
  
  // ========== NEUTRAL COLORS ==========
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5); // Light grey background
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121); // Dark grey text
  
  // ========== BACKGROUND COLORS ==========
  static const Color backgroundLight = Color(0xFFF5F5F5); // Clean neutral background
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF); // White card background
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // ========== TEXT COLORS ==========
  static const Color textPrimary = Color(0xFF212121); // Professional dark grey
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnDark = Colors.white;
  
  // ========== SENSOR-SPECIFIC COLORS ==========
  /// Temperature
  static const Color temperatureHot = Color(0xFFF44336);
  static const Color temperatureNormal = Color(0xFF4CAF50);
  static const Color temperatureCold = Color(0xFF2196F3);
  
  /// Humidity
  static const Color humidityHigh = Color(0xFF2196F3);
  static const Color humidityNormal = Color(0xFF4CAF50);
  static const Color humidityLow = Color(0xFFFFA726);
  
  /// pH Level
  static const Color phAcidic = Color(0xFFFFA726);
  static const Color phNeutral = Color(0xFF4CAF50);
  static const Color phAlkaline = Color(0xFF9C27B0);
  
  /// EC Level
  static const Color ecHigh = Color(0xFFF44336);
  static const Color ecNormal = Color(0xFF4CAF50);
  static const Color ecLow = Color(0xFFFFA726);
  
  /// Light Intensity
  static const Color lightBright = Color(0xFFFFEB3B);
  static const Color lightNormal = Color(0xFF4CAF50);
  static const Color lightDim = Color(0xFF757575);
  
  // ========== CHART COLORS ==========
  static const Color chartBlue = Color(0xFF2196F3);
  static const Color chartGreen = Color(0xFF4CAF50);
  static const Color chartOrange = Color(0xFFFF9800);
  static const Color chartPurple = Color(0xFF9C27B0);
  static const Color chartRed = Color(0xFFF44336);
  static const Color chartYellow = Color(0xFFFFEB3B);
  static const Color chartTeal = Color(0xFF009688);
  static const Color chartPink = Color(0xFFE91E63);
  
  // ========== GRADIENT COLORS ==========
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFF44336), Color(0xFFE91E63)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFFA726), Color(0xFFFFB74D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ========== DARK MODE COLORS ==========
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkText = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFBDBDBD);
  
  // ========== LEGACY SUPPORT ==========
  /// For backward compatibility with existing code
  static const Color card = surfaceLight;
  static const Color text = textPrimary;
  static const Color background = backgroundLight;
}
