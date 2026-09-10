import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AuditLogCard extends StatelessWidget {
  const AuditLogCard(
      {super.key,
      required this.action,
      required this.category,
      required this.severity,
      required this.user,
      required this.farm,
      required this.module,
      required this.timestamp,
      required this.id,
      required this.icon,
      required this.categoryColor,
      required this.severityColor,
      required this.onDetails});
  final String action, category, severity, user, farm, module, timestamp, id;
  final IconData icon;
  final Color categoryColor, severityColor;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? Colors.white : AppColors.textPrimary;
    final secondary = dark ? Colors.white70 : AppColors.textSecondary;
    Widget badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: AppTypography.caption.copyWith(
                color: color, fontWeight: AppTypography.labelWeight)));
    Widget field(String label, String value) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTypography.label.copyWith(color: secondary)),
          const SizedBox(height: 4),
          Text(value,
              style: AppTypography.bodySmall.copyWith(color: foreground)),
        ]);
    return Material(
        color: dark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
                color: dark ? Colors.white10 : AppColors.neutral200)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onDetails,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: categoryColor.withValues(alpha: .1),
                                    borderRadius: BorderRadius.circular(10)),
                                child:
                                    Icon(icon, size: 18, color: categoryColor)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(action,
                                    style: AppTypography.titleSmall
                                        .copyWith(color: foreground))),
                            const SizedBox(width: 6),
                            Icon(Icons.chevron_right_rounded,
                                color: secondary, size: 18),
                          ]),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 6, children: [
                        badge(category, categoryColor),
                        badge(severity, severityColor)
                      ]),
                      const SizedBox(height: 14),
                      LayoutBuilder(builder: (context, constraints) {
                        final width = constraints.maxWidth >= 240
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;
                        return Wrap(spacing: 12, runSpacing: 12, children: [
                          SizedBox(
                              width: width, child: field('Performed by', user)),
                          SizedBox(
                              width: width, child: field('Farm / scope', farm)),
                          SizedBox(
                              width: width, child: field('Module', module)),
                          SizedBox(
                              width: width, child: field('Time', timestamp)),
                        ]);
                      }),
                      const SizedBox(height: 14),
                      Divider(
                          height: 1,
                          color: dark ? Colors.white10 : AppColors.neutral200),
                      const SizedBox(height: 10),
                      Text('Event ID: ' + id,
                          style:
                              AppTypography.caption.copyWith(color: secondary)),
                      Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                              onPressed: onDetails,
                              icon: const Icon(Icons.visibility_outlined,
                                  size: 16),
                              label: Text('View details',
                                  style: AppTypography.font(
                                      fontSize: AppTypography.actionSize,
                                      fontWeight: AppTypography.labelWeight)))),
                    ]))));
  }
}
