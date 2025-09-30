// Define app colors here
import 'package:flutter/material.dart';

class AppColors {
  // Light mode
  static const Color primary = Color(0xFF4CAF50);
  static const Color secondary = Color(0xFF8BC34A);
  static const Color background = Color(0xFFF5F5F5);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF212121);
  static const Color warning = Color(0xFFFFA726);
  static const Color danger = Color(0xFFF44336);

  // Dark mode
  static const Color darkBackground = Color(0xFF151515);
  static const Color darkCard = Color(0xFF232323);
  static const Color darkText = Color(0xFFECECEC);

  // Gradients
  static Gradient get primaryGradient => AppColorsExtension.primaryGradient;
  static Gradient get greenGradient => AppColorsExtension.greenGradient;
  static Gradient get orangeGradient => AppColorsExtension.orangeGradient;
}

// -- Example AppColors gradients (add to your AppColors/constants file) --
extension AppColorsExtension on AppColors {
  static Gradient get primaryGradient => const LinearGradient(
    colors: [Color(0xFF665EE8), Color(0xFF62D7F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Gradient get greenGradient => const LinearGradient(
    colors: [Color(0xFF3CC978), Color(0xFF92F2D7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Gradient get orangeGradient => const LinearGradient(
    colors: [Color(0xFFFFB547), Color(0xFFFFB84D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
