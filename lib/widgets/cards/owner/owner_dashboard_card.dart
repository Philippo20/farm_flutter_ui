import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../../constants/colors.dart';

class OwnerDashboardCard extends StatelessWidget {
  final bool isDark;
  final String ownerName;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final VoidCallback? onSelectRange;
  final String segmentValue;
  final List<String> segmentOptions;
  final ValueChanged<String?> onSegmentChanged;
  final String weatherState;
  final double temperature;

  const OwnerDashboardCard({
    super.key,
    required this.isDark,
    required this.ownerName,
    this.rangeStart,
    this.rangeEnd,
    this.onSelectRange,
    required this.segmentValue,
    required this.segmentOptions,
    required this.onSegmentChanged,
    required this.weatherState,
    required this.temperature,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final today = _formatFullDate(DateTime.now());
    final rangeString = rangeStart != null && rangeEnd != null
        ? "${_shortDate(rangeStart!)} - ${_shortDate(rangeEnd!)}"
        : "Date Range";
    final GlobalKey filterPillKey = GlobalKey();

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 750;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      child: Card(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: isWide
              ? const EdgeInsets.symmetric(horizontal: 34, vertical: 26)
              : const EdgeInsets.all(20),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: Welcome, date, weather
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Hello Mr, $ownerName 👋",
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Today's date is, $today",
                          style: GoogleFonts.inter(
                            color: textColor.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        WeatherInfoWidget(
                          weatherState: weatherState,
                          temperature: temperature,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Right: Filters
                    Row(
                      children: [
                        _FilterPill(
                          key: filterPillKey,
                          label: rangeString,
                          onTap: onSelectRange,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 14),
                        _SegmentPill(
                          value: segmentValue,
                          options: segmentOptions,
                          onChanged: onSegmentChanged,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back, $ownerName 👋",
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      today,
                      style: GoogleFonts.inter(
                        color: textColor.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    WeatherInfoWidget(
                      weatherState: weatherState,
                      temperature: temperature,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _FilterPill(
                      label: rangeString,
                      onTap: onSelectRange,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _SegmentPill(
                      value: segmentValue,
                      options: segmentOptions,
                      onChanged: onSegmentChanged,
                      isDark: isDark,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _formatFullDate(DateTime dt) {
    final weekDay = [
      "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
    ][dt.weekday % 7];
    final month = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ][dt.month - 1];
    return "$weekDay, $month ${dt.day}, ${dt.year}";
  }

  String _shortDate(DateTime dt) {
    final month = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ][dt.month - 1];
    return "${dt.day} $month";
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isDark;

  const _FilterPill({
    Key? key,
    required this.label,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF2A2D3A) : const Color(0xFFF8F9FC);
    final textColor = isDark ? AppColors.darkText : AppColors.text;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                color: textColor.withOpacity(0.9),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentPill extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  const _SegmentPill({
    required this.value,
    required this.options,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF2A2D3A) : const Color(0xFFF8F9FC);
    final textColor = isDark ? AppColors.darkText : AppColors.text;

    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 20),
          items: options
              .map((opt) => DropdownMenuItem<String>(
                    value: opt,
                    child: Text(
                      opt,
                      style: GoogleFonts.inter(
                        color: textColor.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: bgColor,
        ),
      ),
    );
  }
}

class WeatherInfoWidget extends StatelessWidget {
  final String weatherState; // e.g. "Sunny", "Cloudy", "Rainy"
  final double temperature; // e.g. 30.5
  final bool isDark;

  const WeatherInfoWidget({
    super.key,
    required this.weatherState,
    required this.temperature,
    required this.isDark,
  });

  String _getAnimationAsset(String state) {
    switch (state.toLowerCase()) {
      case 'rain':
        return 'assets/weather/rain.json';
      case 'clouds':
        return 'assets/weather/cloudy.json';
      case 'clear':
      default:
        return 'assets/weather/sunny.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 34,
          width: 34,
          child: Lottie.asset(_getAnimationAsset(weatherState)),
        ),
        const SizedBox(width: 8),
        Text(
          "${temperature.toStringAsFixed(1)}°C",
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          weatherState,
          style: GoogleFonts.inter(
            color: textColor.withOpacity(0.9),
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
