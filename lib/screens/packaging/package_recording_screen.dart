import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/packaging_supervisor_screen_shell.dart';

class PackageRecordingScreen extends StatelessWidget {
  const PackageRecordingScreen({super.key});

  static const _lines = [
    {
      'line': 'Line A',
      'batch': 'LTC-24019',
      'crop': 'Romaine Lettuce',
      'target': '840 packs',
      'completed': '638 packs',
      'operator': 'Kwame T.',
      'status': 'Recording',
      'color': AppColors.primary,
    },
    {
      'line': 'Line B',
      'batch': 'TMT-24022',
      'crop': 'Cherry Tomato',
      'target': '310 packs',
      'completed': '149 packs',
      'operator': 'Esi M.',
      'status': 'Staging',
      'color': AppColors.warning,
    },
    {
      'line': 'Line C',
      'batch': 'BSL-24007',
      'crop': 'Sweet Basil',
      'target': '1,530 sleeves',
      'completed': '1,392 sleeves',
      'operator': 'Ama K.',
      'status': 'Finalizing',
      'color': AppColors.success,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PackagingSupervisorScreenShell(
      selectedIndex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroPanel(
            title: 'Package Recording',
            subtitle:
                'Capture completed packs, active batch movement, and operator accountability by line.',
            icon: Icons.inventory_2_outlined,
            colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: const [
              _KpiCard(
                title: 'Recorded today',
                value: '2,179',
                subtitle: 'Packages confirmed',
                icon: Icons.fact_check_outlined,
                color: AppColors.primary,
              ),
              _KpiCard(
                title: 'Active lines',
                value: '3',
                subtitle: 'All supervised',
                icon: Icons.precision_manufacturing_outlined,
                color: AppColors.success,
              ),
              _KpiCard(
                title: 'Pending entry',
                value: '2',
                subtitle: 'Need supervisor review',
                icon: Icons.edit_note_outlined,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Line Recording Queue',
            style: AppTypography.h5.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ResponsiveGrid(
            itemCount: _lines.length,
            mobileExtent: 360,
            desktopExtent: 310,
            itemBuilder: (index) => _LineCard(item: _lines[index]),
          ),
        ],
      ),
    );
  }
}

class WasteTrackingScreen extends StatelessWidget {
  const WasteTrackingScreen({super.key});

  static const _waste = [
    {
      'source': 'Trimming loss',
      'batch': 'LTC-24019',
      'amount': '16 kg',
      'reason': 'Outer leaves removed',
      'severity': 'Normal',
      'color': AppColors.success,
    },
    {
      'source': 'Damaged clamshells',
      'batch': 'TMT-24022',
      'amount': '42 units',
      'reason': 'Seal failure on Line B',
      'severity': 'Review',
      'color': AppColors.warning,
    },
    {
      'source': 'Label mismatch',
      'batch': 'BSL-24007',
      'amount': '3 rolls',
      'reason': 'Wrong print batch',
      'severity': 'Critical',
      'color': AppColors.error,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PackagingSupervisorScreenShell(
      selectedIndex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroPanel(
            title: 'Waste Tracking',
            subtitle:
                'Monitor packaging waste, isolate loss reasons, and escalate preventable issues quickly.',
            icon: Icons.delete_sweep_outlined,
            colors: [Color(0xFF991B1B), Color(0xFFEA580C)],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: const [
              _KpiCard(
                title: 'Waste rate',
                value: '2.3%',
                subtitle: 'Below 3% target',
                icon: Icons.trending_down_outlined,
                color: AppColors.success,
              ),
              _KpiCard(
                title: 'Open issues',
                value: '2',
                subtitle: 'Need line follow-up',
                icon: Icons.report_problem_outlined,
                color: AppColors.warning,
              ),
              _KpiCard(
                title: 'Critical',
                value: '1',
                subtitle: 'Label mismatch',
                icon: Icons.priority_high_outlined,
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Waste Events',
            style: AppTypography.h5.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ResponsiveGrid(
            itemCount: _waste.length,
            mobileExtent: 330,
            desktopExtent: 280,
            itemBuilder: (index) => _WasteCard(item: _waste[index]),
          ),
        ],
      ),
    );
  }
}

class PackagingProgressScreen extends StatelessWidget {
  const PackagingProgressScreen({super.key});

  static const _progress = [
    {
      'line': 'Line A',
      'batch': 'LTC-24019',
      'progress': '76%',
      'eta': '24 min',
      'throughput': '184 packs/hr',
      'status': 'On pace',
      'color': AppColors.success,
    },
    {
      'line': 'Line B',
      'batch': 'TMT-24022',
      'progress': '48%',
      'eta': '42 min',
      'throughput': '126 packs/hr',
      'status': 'Watch',
      'color': AppColors.warning,
    },
    {
      'line': 'Line C',
      'batch': 'BSL-24007',
      'progress': '91%',
      'eta': '11 min',
      'throughput': '216 sleeves/hr',
      'status': 'Closing',
      'color': AppColors.primary,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PackagingSupervisorScreenShell(
      selectedIndex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroPanel(
            title: 'Packaging Progress',
            subtitle:
                'Track line completion, estimated finish times, and throughput variance in real time.',
            icon: Icons.trending_up_outlined,
            colors: [Color(0xFF1D4ED8), Color(0xFF0F766E)],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: const [
              _KpiCard(
                title: 'Average progress',
                value: '72%',
                subtitle: 'Across active lines',
                icon: Icons.pie_chart_outline,
                color: AppColors.primary,
              ),
              _KpiCard(
                title: 'Output rate',
                value: '526/hr',
                subtitle: 'Current velocity',
                icon: Icons.speed_outlined,
                color: AppColors.success,
              ),
              _KpiCard(
                title: 'Line watch',
                value: '1',
                subtitle: 'Line B below pace',
                icon: Icons.visibility_outlined,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Line Progress',
            style: AppTypography.h5.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ResponsiveGrid(
            itemCount: _progress.length,
            mobileExtent: 330,
            desktopExtent: 280,
            itemBuilder: (index) => _ProgressCard(item: _progress[index]),
          ),
        ],
      ),
    );
  }
}

class PackagingSupervisorSettingsScreen extends StatelessWidget {
  const PackagingSupervisorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PackagingSupervisorScreenShell(
      selectedIndex: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroPanel(
            title: 'Packaging Settings',
            subtitle:
                'Manage supervisor preferences, line thresholds, notifications, and package approval rules.',
            icon: Icons.settings_outlined,
            colors: [Color(0xFF334155), Color(0xFF475569)],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsPanel(isDark: isDark),
        ],
      ),
    );
  }
}

class PackagingReportsScreen extends StatelessWidget {
  const PackagingReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PackagingProgressScreen();
  }
}

class _HeroPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  const _HeroPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 46 : 54,
            height: isMobile ? 46 : 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: Colors.white, size: isMobile ? 24 : 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 24 : 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  final int itemCount;
  final double mobileExtent;
  final double desktopExtent;
  final Widget Function(int index) itemBuilder;

  const _ResponsiveGrid({
    required this.itemCount,
    required this.mobileExtent,
    required this.desktopExtent,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        final columns = constraints.maxWidth >= 820 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: isMobile ? mobileExtent : desktopExtent,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (context, index) => itemBuilder(index),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width =
        MediaQuery.of(context).size.width < 600 ? double.infinity : 240.0;

    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(isDark ? 0.26 : 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _IconBox(icon: icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SmallText(title),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.h5.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                _SmallText(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  final Map<String, Object> item;

  const _LineCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return _OperationalCard(
      color: item['color']! as Color,
      icon: Icons.inventory_2_outlined,
      title: item['line']! as String,
      subtitle: '${item['crop']} | ${item['batch']}',
      status: item['status']! as String,
      metrics: [
        _MetricData('Target', item['target']! as String),
        _MetricData('Completed', item['completed']! as String),
        _MetricData('Operator', item['operator']! as String),
      ],
    );
  }
}

class _WasteCard extends StatelessWidget {
  final Map<String, Object> item;

  const _WasteCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return _OperationalCard(
      color: item['color']! as Color,
      icon: Icons.delete_sweep_outlined,
      title: item['source']! as String,
      subtitle: item['reason']! as String,
      status: item['severity']! as String,
      metrics: [
        _MetricData('Batch', item['batch']! as String),
        _MetricData('Amount', item['amount']! as String),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final Map<String, Object> item;

  const _ProgressCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return _OperationalCard(
      color: item['color']! as Color,
      icon: Icons.trending_up_outlined,
      title: item['line']! as String,
      subtitle: item['batch']! as String,
      status: item['status']! as String,
      metrics: [
        _MetricData('Progress', item['progress']! as String),
        _MetricData('ETA', item['eta']! as String),
        _MetricData('Throughput', item['throughput']! as String),
      ],
    );
  }
}

class _OperationalCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final List<_MetricData> metrics;

  const _OperationalCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        gradient: LinearGradient(
          colors: [
            isDark ? AppColors.surfaceDark : Colors.white,
            color.withOpacity(isDark ? 0.08 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(isDark ? 0.28 : 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBox(icon: icon, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h6.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: status, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: metrics
                .map((metric) => _MetricPill(metric: metric, color: color))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  final bool isDark;

  const _SettingsPanel({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.14 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: const [
          _SettingRow(
            title: 'Require supervisor approval',
            subtitle: 'Hold package records before final dispatch posting.',
            icon: Icons.verified_user_outlined,
            enabled: true,
          ),
          _SettingRow(
            title: 'Waste escalation alerts',
            subtitle: 'Notify when waste events exceed line threshold.',
            icon: Icons.notifications_active_outlined,
            enabled: true,
          ),
          _SettingRow(
            title: 'Auto-close completed batches',
            subtitle: 'Close batches when target packaging count is reached.',
            icon: Icons.task_alt_outlined,
            enabled: false,
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;

  const _SettingRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          _IconBox(icon: icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: (_) {}),
        ],
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;

  const _MetricData(this.label, this.value);
}

class _MetricPill extends StatelessWidget {
  final _MetricData metric;
  final Color color;

  const _MetricPill({required this.metric, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SmallText(metric.label),
          const SizedBox(height: 4),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _SmallText extends StatelessWidget {
  final String text;

  const _SmallText(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.caption.copyWith(
        color: isDark ? Colors.white60 : AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 136),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
