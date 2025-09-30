import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';

class AdminUserStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final String change;
  final bool isPositive;
  final bool isDark;


 
  const AdminUserStatCard({
    super.key,
    required this.title,
    required this.change,
    required this.isPositive,
    required this.value,
    required this.icon,
    this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = iconColor ?? AppColors.primary;
    final secondaryTextColor = isDark
        ? AppColors.darkText.withOpacity(0.7)
        : AppColors.text.withOpacity(0.7);

    // Example gradient: tweak as desired!
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        accentColor.withOpacity(isDark ? 0.30 : 0.20),
        accentColor.withOpacity(isDark ? 0.09 : 0.08),
        isDark ? Colors.black.withOpacity(0.18) : Colors.white.withOpacity(0.11),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.17 : 0.09),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon & More Button
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: accentColor,
                  ),
                ),
                Spacer(),
                // More icon (three dots)
                Icon(isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 15, color: isPositive ? Colors.green : Colors.red),
                    const SizedBox(width: 4),
                Text(
                     change,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Value and Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Small bottom bar/accent
            Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: accentColor.withOpacity(0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
