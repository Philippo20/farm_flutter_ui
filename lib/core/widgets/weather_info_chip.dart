import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';

class WeatherInfo {
  final String condition;
  final double temperature;

  const WeatherInfo({
    required this.condition,
    required this.temperature,
  });
}

class WeatherInfoChip extends StatelessWidget {
  final String condition;
  final double temperature;
  final bool isDark;

  const WeatherInfoChip({
    super.key,
    required this.condition,
    required this.temperature,
    required this.isDark,
  });

  IconData _iconForCondition() {
    final normalized = condition.toLowerCase();
    if (normalized.contains('rain')) return Icons.umbrella_outlined;
    if (normalized.contains('cloud')) return Icons.cloud_outlined;
    if (normalized.contains('storm')) return Icons.thunderstorm_outlined;
    if (normalized.contains('snow')) return Icons.ac_unit_outlined;
    return Icons.wb_sunny_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = isDark
        ? AppColors.primary.withOpacity(0.15)
        : AppColors.primary.withOpacity(0.08);
    final textColor =
        isDark ? Colors.white : AppColors.darkBackground.withOpacity(0.8);

    return Container(
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _iconForCondition(),
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${temperature.toStringAsFixed(1)}°C',
            style: GoogleFonts.poppins(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            condition,
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
