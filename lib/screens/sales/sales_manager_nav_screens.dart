import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sales_manager_screen_shell.dart';

class SalesOffTakersScreen extends StatelessWidget {
  const SalesOffTakersScreen({super.key});

  static const _cards = [
    {
      'title': 'FreshMart Retail',
      'subtitle': 'Retail chain | Accra North',
      'metric': 'GHS 42.5K',
      'status': 'Active',
      'color': AppColors.success,
    },
    {
      'title': 'Green Basket',
      'subtitle': 'Wholesale buyer | Tema',
      'metric': 'GHS 31.2K',
      'status': 'Renewal',
      'color': AppColors.warning,
    },
    {
      'title': 'KitchenPro Foods',
      'subtitle': 'Food service | East Legon',
      'metric': 'GHS 18.7K',
      'status': 'New',
      'color': AppColors.primary,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _SalesPage(
      selectedIndex: 1,
      title: 'Off-Taker Management',
      subtitle:
          'Manage buyer accounts, relationship status, contract value, and next sales actions.',
      icon: Icons.people_outlined,
      colors: const [Color(0xFF1D4ED8), Color(0xFF0F766E)],
      kpis: const [
        _KpiData('Active buyers', '12', '4 priority accounts',
            Icons.people_outlined, AppColors.primary),
        _KpiData('Pipeline value', 'GHS 92K', 'Open contract value',
            Icons.account_balance_wallet_outlined, AppColors.success),
        _KpiData('Renewals', '3', 'Due this month',
            Icons.autorenew_outlined, AppColors.warning),
      ],
      sectionTitle: 'Buyer Accounts',
      cards: _cards,
    );
  }
}

class SalesPerformanceScreen extends StatelessWidget {
  const SalesPerformanceScreen({super.key});

  static const _cards = [
    {
      'title': 'Romaine Lettuce',
      'subtitle': 'Top moving crop this week',
      'metric': 'GHS 48K',
      'status': '+18%',
      'color': AppColors.success,
    },
    {
      'title': 'Cherry Tomato',
      'subtitle': 'Strong wholesale demand',
      'metric': 'GHS 36K',
      'status': '+11%',
      'color': AppColors.primary,
    },
    {
      'title': 'Sweet Basil',
      'subtitle': 'Below forecast due to yield holds',
      'metric': 'GHS 9K',
      'status': 'Watch',
      'color': AppColors.warning,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _SalesPage(
      selectedIndex: 2,
      title: 'Sales Performance',
      subtitle:
          'Track revenue momentum, target attainment, top crops, and buyer conversion.',
      icon: Icons.trending_up_outlined,
      colors: const [Color(0xFF166534), Color(0xFF0F766E)],
      kpis: const [
        _KpiData('Revenue', 'GHS 125K', '+18% this week',
            Icons.payments_outlined, AppColors.success),
        _KpiData('Target hit', '87%', 'Monthly progress',
            Icons.track_changes_outlined, AppColors.primary),
        _KpiData('Open deals', '9', '3 closing soon',
            Icons.handshake_outlined, AppColors.warning),
      ],
      sectionTitle: 'Performance Drivers',
      cards: _cards,
    );
  }
}

class SalesDeliveriesScreen extends StatelessWidget {
  const SalesDeliveriesScreen({super.key});

  static const _cards = [
    {
      'title': 'FreshMart Retail',
      'subtitle': 'Romaine Lettuce | 420 kg',
      'metric': 'Today 2 PM',
      'status': 'Scheduled',
      'color': AppColors.primary,
    },
    {
      'title': 'Green Basket',
      'subtitle': 'Cherry Tomato | 310 kg',
      'metric': 'Tomorrow',
      'status': 'Pending',
      'color': AppColors.warning,
    },
    {
      'title': 'KitchenPro Foods',
      'subtitle': 'Sweet Basil | 96 kg',
      'metric': 'Delivered',
      'status': 'Complete',
      'color': AppColors.success,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _SalesPage(
      selectedIndex: 3,
      title: 'Sales Deliveries',
      subtitle:
          'Coordinate delivery commitments, dispatch timing, order status, and buyer handoff.',
      icon: Icons.local_shipping_outlined,
      colors: const [Color(0xFF334155), Color(0xFF1D4ED8)],
      kpis: const [
        _KpiData('Pending', '5', 'Awaiting dispatch',
            Icons.local_shipping_outlined, AppColors.warning),
        _KpiData('Delivered', '18', 'This week',
            Icons.task_alt_outlined, AppColors.success),
        _KpiData('On time', '94%', 'Delivery SLA',
            Icons.schedule_outlined, AppColors.primary),
      ],
      sectionTitle: 'Delivery Commitments',
      cards: _cards,
    );
  }
}

class SalesFinancialScreen extends StatelessWidget {
  const SalesFinancialScreen({super.key});

  static const _cards = [
    {
      'title': 'Collected Revenue',
      'subtitle': 'Cash received from confirmed orders',
      'metric': 'GHS 88K',
      'status': 'Collected',
      'color': AppColors.success,
    },
    {
      'title': 'Outstanding',
      'subtitle': 'Invoices awaiting payment',
      'metric': 'GHS 37K',
      'status': 'Due',
      'color': AppColors.warning,
    },
    {
      'title': 'Commission Pool',
      'subtitle': 'Sales team payout forecast',
      'metric': 'GHS 9.4K',
      'status': 'Forecast',
      'color': AppColors.primary,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _SalesPage(
      selectedIndex: 4,
      title: 'Sales Financials',
      subtitle:
          'Monitor revenue, receivables, buyer balances, commission exposure, and collection risk.',
      icon: Icons.account_balance_wallet_outlined,
      colors: const [Color(0xFF7C2D12), Color(0xFFEA580C)],
      kpis: const [
        _KpiData('Revenue', 'GHS 125K', 'This month',
            Icons.payments_outlined, AppColors.success),
        _KpiData('Receivables', 'GHS 37K', 'Open invoices',
            Icons.receipt_long_outlined, AppColors.warning),
        _KpiData('Commission', 'GHS 9.4K', 'Forecast payout',
            Icons.account_balance_outlined, AppColors.primary),
      ],
      sectionTitle: 'Financial Overview',
      cards: _cards,
    );
  }
}

class SalesReportsScreen extends StatelessWidget {
  const SalesReportsScreen({super.key});

  static const _cards = [
    {
      'title': 'Revenue Report',
      'subtitle': 'Sales by buyer, crop, and week',
      'metric': 'Ready',
      'status': 'PDF',
      'color': AppColors.primary,
    },
    {
      'title': 'Buyer Performance',
      'subtitle': 'Off-taker ranking and retention',
      'metric': '12 buyers',
      'status': 'Live',
      'color': AppColors.success,
    },
    {
      'title': 'Delivery SLA',
      'subtitle': 'On-time rate and exception analysis',
      'metric': '94%',
      'status': 'Review',
      'color': AppColors.warning,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _SalesPage(
      selectedIndex: 5,
      title: 'Sales Reports',
      subtitle:
          'Review sales analytics, buyer performance, delivery reliability, and export-ready summaries.',
      icon: Icons.assessment_outlined,
      colors: const [Color(0xFF1E3A8A), Color(0xFF0F766E)],
      kpis: const [
        _KpiData('Reports', '7', 'Ready now',
            Icons.assessment_outlined, AppColors.primary),
        _KpiData('Exports', '4', 'Scheduled',
            Icons.file_download_outlined, AppColors.success),
        _KpiData('Findings', '3', 'Need review',
            Icons.report_problem_outlined, AppColors.warning),
      ],
      sectionTitle: 'Report Library',
      cards: _cards,
    );
  }
}

class SalesManagerSettingsScreen extends StatelessWidget {
  const SalesManagerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SalesManagerScreenShell(
      selectedIndex: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Hero(
            title: 'Sales Settings',
            subtitle:
                'Manage buyer alerts, approval limits, revenue targets, and delivery notification rules.',
            icon: Icons.settings_outlined,
            colors: [Color(0xFF334155), Color(0xFF475569)],
          ),
          SizedBox(height: AppSpacing.lg),
          _SettingsPanel(),
        ],
      ),
    );
  }
}

class _SalesPage extends StatelessWidget {
  final int selectedIndex;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final List<_KpiData> kpis;
  final String sectionTitle;
  final List<Map<String, Object>> cards;

  const _SalesPage({
    required this.selectedIndex,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.kpis,
    required this.sectionTitle,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SalesManagerScreenShell(
      selectedIndex: selectedIndex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Hero(title: title, subtitle: subtitle, icon: icon, colors: colors),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: kpis.map((kpi) => _KpiCard(data: kpi)).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            sectionTitle,
            style: AppTypography.h5.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ResponsiveGrid(
            itemCount: cards.length,
            itemBuilder: (index) => _SalesCard(item: cards[index]),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  const _Hero({
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
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
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
                    fontWeight: FontWeight.w800,
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
  final Widget Function(int index) itemBuilder;

  const _ResponsiveGrid({
    required this.itemCount,
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
            mainAxisExtent: isMobile ? 310 : 260,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (context, index) => itemBuilder(index),
        );
      },
    );
  }
}

class _SalesCard extends StatelessWidget {
  final Map<String, Object> item;

  const _SalesCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = item['color']! as Color;

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
          Row(
            children: [
              _IconBox(icon: Icons.business_center_outlined, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']! as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h6.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['subtitle']! as String,
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
              _StatusBadge(label: item['status']! as String, color: color),
            ],
          ),
          const Spacer(),
          _MetricPill(
            label: 'Metric',
            value: item['metric']! as String,
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiData(this.title, this.value, this.subtitle, this.icon, this.color);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;

  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width =
        MediaQuery.of(context).size.width < 600 ? double.infinity : 230.0;

    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border:
            Border.all(color: data.color.withOpacity(isDark ? 0.26 : 0.16)),
      ),
      child: Row(
        children: [
          _IconBox(icon: data.icon, color: data.color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MutedText(data.title),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  style: AppTypography.h5.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                _MutedText(data.subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SettingRow(
          title: 'Buyer renewal alerts',
          subtitle: 'Notify when off-taker contracts are nearing renewal.',
          icon: Icons.notifications_active_outlined,
          enabled: true,
        ),
        _SettingRow(
          title: 'Revenue approval threshold',
          subtitle: 'Require manager review for large credit sales.',
          icon: Icons.verified_user_outlined,
          enabled: true,
        ),
        _SettingRow(
          title: 'Auto-export sales reports',
          subtitle: 'Generate sales summaries at close of day.',
          icon: Icons.file_download_outlined,
          enabled: false,
        ),
      ],
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
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                _MutedText(subtitle),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: (_) {}),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
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
          _MutedText(label),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
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
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  final String text;

  const _MutedText(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.caption.copyWith(
        color: isDark ? Colors.white60 : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
