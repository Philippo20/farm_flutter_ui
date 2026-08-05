import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/fulfillment_manager_screen_shell.dart';
import '../../services/fulfillment_data_service.dart';

class FulfillmentReportsScreen extends StatefulWidget {
  const FulfillmentReportsScreen({super.key});

  @override
  State<FulfillmentReportsScreen> createState() =>
      _FulfillmentReportsScreenState();
}

class _FulfillmentReportsScreenState extends State<FulfillmentReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _exports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final snapshot = await FulfillmentDataService().load();
      final records = snapshot.fulfillments;
      final inventory = snapshot.inventory;
      final received = records.fold<double>(
          0, (sum, item) => sum + _number(item['total_weight']));
      final packaged = records.fold<double>(
          0, (sum, item) => sum + _number(item['total_packaged_weight']));
      final waste = records.fold<double>(
          0, (sum, item) => sum + _number(item['packaging_waste_weight']));
      final lowStock = inventory
          .where((item) =>
              _number(item['quantity'] ?? item['stock']) <=
              _number(item['reorder_level'] ?? item['minimum_stock']))
          .length;
      final reports = [
        _report(
            'Daily Intake',
            'Inbound weight from fulfillment records',
            '${received.toStringAsFixed(1)} kg',
            'Backend data',
            Icons.move_to_inbox_outlined,
            AppColors.primary),
        _report(
            'Packaging Throughput',
            'Packaged output recorded by the hub',
            '${packaged.toStringAsFixed(1)} kg',
            '${records.length} records',
            Icons.precision_manufacturing_outlined,
            AppColors.success),
        _report(
            'Yield Variance',
            'Waste and recovery from packaging records',
            '${waste.toStringAsFixed(1)} kg',
            'Recorded waste',
            Icons.analytics_outlined,
            AppColors.warning),
        _report(
            'Materials Risk',
            'Inventory items below their thresholds',
            '$lowStock risk',
            '${inventory.length} tracked items',
            Icons.inventory_2_outlined,
            AppColors.error),
      ];
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _exports = [];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  static double _number(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  Map<String, dynamic> _report(String title, String subtitle, String metric,
          String trend, IconData icon, Color color) =>
      {
        'title': title,
        'subtitle': subtitle,
        'metric': metric,
        'trend': trend,
        'status': 'Live',
        'icon': icon,
        'color': color,
      };

  /* Backend-derived reports replace the former demo collections.
  static const _reports = [
    {
      'title': 'Daily Intake',
      'subtitle':
          'Inbound loads, received weight, dock timing, and acceptance status.',
      'metric': '826 kg',
      'trend': '+12% vs yesterday',
      'status': 'Ready',
      'icon': Icons.move_to_inbox_outlined,
      'color': AppColors.primary,
    },
    {
      'title': 'Packaging Throughput',
      'subtitle':
          'Line output, pack velocity, active batches, and cycle-time variance.',
      'metric': '526/hr',
      'trend': '3 active lines',
      'status': 'Live',
      'icon': Icons.precision_manufacturing_outlined,
      'color': AppColors.success,
    },
    {
      'title': 'Yield Variance',
      'subtitle':
          'Waste, shrinkage, sellable recovery, and crop-level loss trends.',
      'metric': '3.5%',
      'trend': '29 kg waste',
      'status': 'Review',
      'icon': Icons.analytics_outlined,
      'color': AppColors.warning,
    },
    {
      'title': 'Materials Risk',
      'subtitle':
          'Packaging inventory coverage, low-stock items, and reorder exposure.',
      'metric': '1 risk',
      'trend': 'Labels below threshold',
      'status': 'Action',
      'icon': Icons.inventory_2_outlined,
      'color': AppColors.error,
    },
  ];

  static const _exports = [
    {
      'name': 'Morning operations pack',
      'owner': 'Fulfillment Manager',
      'format': 'PDF',
      'time': '08:00 AM',
      'status': 'Generated',
      'color': AppColors.success,
    },
    {
      'name': 'Packaging line report',
      'owner': 'Operations Lead',
      'format': 'CSV',
      'time': '12:00 PM',
      'status': 'Scheduled',
      'color': AppColors.primary,
    },
    {
      'name': 'Yield exception digest',
      'owner': 'Quality Team',
      'format': 'PDF',
      'time': '04:30 PM',
      'status': 'Pending',
      'color': AppColors.warning,
    },
  ];
  */

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final exceptions = _reports.where((item) => item['status'] == 'Action').length;

    return FulfillmentManagerScreenShell(
      selectedIndex: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(isDark, isMobile),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
            children: [
              _ReportKpi(
                title: 'Reports ready',
                value: '${_reports.length}',
                subtitle: 'Backend-derived reports',
                  icon: Icons.fact_check_outlined,
                  color: AppColors.primary,
                ),
              _ReportKpi(
                title: 'Export queue',
                value: '${_exports.length}',
                subtitle: 'Backend export records',
                  icon: Icons.file_download_outlined,
                  color: AppColors.success,
                ),
              _ReportKpi(
                title: 'Exceptions',
                value: '$exceptions',
                subtitle: 'Backend risk records',
                  icon: Icons.report_problem_outlined,
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Operational Reports',
              style: AppTypography.h5.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildReportsGrid(context, isDark),
            const SizedBox(height: AppSpacing.xl),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 980;
                if (!twoColumns) {
                  return Column(
                    children: [
                      _buildExportsPanel(isDark),
                      const SizedBox(height: AppSpacing.md),
                      _buildInsightsPanel(isDark),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildExportsPanel(isDark)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _buildInsightsPanel(isDark)),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHero(bool isDark, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(isDark ? 0.22 : 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fulfillment Reports',
            style: AppTypography.h4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 24 : 28,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Review intake, packaging, yield, and materials performance from one reporting surface.',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.88),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsGrid(BuildContext context, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        final columns = constraints.maxWidth >= 820 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _reports.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: isMobile ? 340 : 300,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (context, index) {
            return _ReportCard(report: _reports[index], isDark: isDark);
          },
        );
      },
    );
  }

  Widget _buildExportsPanel(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _panelDecoration(isDark, AppColors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            icon: Icons.file_download_outlined,
            title: 'Export Schedule',
            subtitle: 'Automated report packages for operations teams.',
            color: AppColors.primary,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.md),
          ..._exports.map((export) => _ExportRow(export: export)),
        ],
      ),
    );
  }

  Widget _buildInsightsPanel(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _panelDecoration(isDark, AppColors.success),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            icon: Icons.insights_outlined,
            title: 'Manager Insights',
            subtitle: 'Current signals from fulfillment operations.',
            color: AppColors.success,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.md),
          const _InsightRow(
            title: 'Strongest area',
            value: 'Packaging throughput is stable across 3 lines.',
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _InsightRow(
            title: 'Watch item',
            value: 'Barcode labels are below safe coverage.',
            color: AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _InsightRow(
            title: 'Next action',
            value: 'Review yield exceptions before dispatch close.',
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration(bool isDark, Color color) {
    return BoxDecoration(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      border: Border.all(color: color.withOpacity(isDark ? 0.24 : 0.16)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.14 : 0.04),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

class _ReportKpi extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ReportKpi({
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.h5.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
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

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final bool isDark;

  const _ReportCard({
    required this.report,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = report['color']! as Color;

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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(report['icon']! as IconData, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report['title']! as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h6.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report['subtitle']! as String,
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
              _StatusBadge(label: report['status']! as String, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isDark ? Colors.white10 : AppColors.neutral200,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ReportMetric(
                    label: 'Primary metric',
                    value: report['metric']! as String,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ReportMetric(
                    label: 'Signal',
                    value: report['trend']! as String,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.open_in_new_outlined, size: 18),
              label: const Text('Open Report'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _ReportMetric({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isDark ? Colors.white60 : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;

  const _PanelTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExportRow extends StatelessWidget {
  final Map<String, dynamic> export;

  const _ExportRow({required this.export});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = export['color']! as Color;

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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(Icons.description_outlined, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  export['name']! as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${export['owner']} | ${export['format']} | ${export['time']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatusBadge(label: export['status']! as String, color: color),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _InsightRow({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
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
