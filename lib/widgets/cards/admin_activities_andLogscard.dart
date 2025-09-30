import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';

class ActivitiesAndLogsCard extends StatelessWidget {
  final bool isDark;
  
  const ActivitiesAndLogsCard({super.key, required this.isDark});

  @override
  @override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenWidth < 850;

  return Padding(
    padding: const EdgeInsets.only(top: 16),
    child: isSmallScreen
        ? Column(
            children: [
              _TodayActivitiesCard(isDark: isDark),
              const SizedBox(height: 16),
              _SystemLogsCard(isDark: isDark),
            ],
          )
        : IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch, // key for equal height
              children: [
                Expanded(
                  flex: 5,
                  child: _TodayActivitiesCard(isDark: isDark),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: _SystemLogsCard(isDark: isDark),
                ),
              ],
            ),
          ),
  );
}

}

class _TodayActivitiesCard extends StatelessWidget {
  final bool isDark;
  
  const _TodayActivitiesCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final secondaryTextColor = isDark 
        ? AppColors.darkText.withOpacity(0.7) 
        : AppColors.text.withOpacity(0.7);

    // Sample activities data
    final activities = [
      Activity('Irrigation started', '08:30 AM', Icons.water_drop, const Color(0xFF2196F3)),
      Activity('Temperature alert', '10:15 AM', Icons.warning_amber, const Color(0xFFFFC107)),
      Activity('Harvest completed', '01:45 PM', Icons.agriculture, const Color(0xFF4CAF50)),
      Activity('System update', '03:20 PM', Icons.system_update, const Color(0xFF9C27B0)),
      Activity('New device connected', '05:50 PM', Icons.device_hub, const Color(0xFF607D8B)),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Activities",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Recent system activities and events",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: activities.map((activity) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: activity.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        activity.icon,
                        color: activity.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity.time,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: secondaryTextColor,
                    ),
                  ],
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  "View All Activities",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemLogsCard extends StatelessWidget {
  final bool isDark;
  
  const _SystemLogsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF20232C) : AppColors.card;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final secondaryTextColor = isDark 
        ? AppColors.darkText.withOpacity(0.7) 
        : AppColors.text.withOpacity(0.7);
    final logColor = isDark 
        ? Colors.white.withOpacity(0.1) 
        : Colors.black.withOpacity(0.05);

    // Sample logs data
    final logs = [
      LogEntry('INFO', 'System check completed', '10 seconds ago'),
      LogEntry('WARNING', 'Temperature threshold exceeded', '2 minutes ago'),
      LogEntry('DEBUG', 'Sensor calibration in progress', '5 minutes ago'),
      LogEntry('INFO', 'New device synchronized', '12 minutes ago'),
      LogEntry('ERROR', 'Irrigation valve timeout', '25 minutes ago'),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "System Logs",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.1) 
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Live",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Recent system events and notifications",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: logs.map((log) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: logColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getLogColor(log.level, isDark),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          log.level,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.message,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              log.time,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  "View All Logs",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLogColor(String level, bool isDark) {
    switch (level) {
      case 'ERROR':
        return Colors.red[400]!;
      case 'WARNING':
        return Colors.orange[400]!;
      case 'INFO':
        return isDark ? Colors.blue[400]! : Colors.blue[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}

// Data models
class Activity {
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  Activity(this.title, this.time, this.icon, this.color);
}

class LogEntry {
  final String level;
  final String message;
  final String time;

  LogEntry(this.level, this.message, this.time);
}