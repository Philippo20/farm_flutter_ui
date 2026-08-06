import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/quality_assurance_screen_shell.dart';
import '../../services/fulfillment_data_service.dart';
import '../../services/superadmin_api_service.dart';

class QualityInspectionScreen extends StatelessWidget {
  const QualityInspectionScreen({super.key});

  static const _items = [
    {
      'title': 'LTC-24019',
      'subtitle': 'Romaine Lettuce | Dock 02',
      'metric': '420 kg',
      'status': 'Pending',
      'color': AppColors.warning,
    },
    {
      'title': 'TMT-24022',
      'subtitle': 'Cherry Tomato | Line B',
      'metric': '310 kg',
      'status': 'In review',
      'color': AppColors.primary,
    },
    {
      'title': 'BSL-24007',
      'subtitle': 'Sweet Basil | Line C',
      'metric': '96 kg',
      'status': 'Sampled',
      'color': AppColors.success,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _QualityPage(
      selectedIndex: 1,
      title: 'Quality Inspection',
      subtitle:
          'Inspect incoming batches, record quality gates, and flag issues before approval.',
      icon: Icons.search_outlined,
      colors: const [Color(0xFF1D4ED8), Color(0xFF0F766E)],
      kpis: const [
        _KpiData('Pending', '12', 'Items waiting',
            Icons.pending_actions_outlined, AppColors.warning),
        _KpiData('Inspected', '28', 'Today', Icons.fact_check_outlined,
            AppColors.success),
        _KpiData('Pass rate', '95%', '+2% shift trend', Icons.verified_outlined,
            AppColors.primary),
      ],
      sectionTitle: 'Inspection Queue',
      cards: _items,
    );
  }
}

class QualityApproveScreen extends StatelessWidget {
  const QualityApproveScreen({super.key});

  static const _items = [
    {
      'title': 'TMT-24022',
      'subtitle': 'Cherry Tomato | Inspection cleared',
      'metric': '97.1%',
      'status': 'Approve',
      'color': AppColors.success,
    },
    {
      'title': 'LTC-24019',
      'subtitle': 'Romaine Lettuce | Cold chain verified',
      'metric': '96.2%',
      'status': 'Ready',
      'color': AppColors.primary,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _QualityPage(
      selectedIndex: 2,
      title: 'Approve Batches',
      subtitle:
          'Release clean batches to sales or dispatch after quality gates are verified.',
      icon: Icons.check_circle_outline,
      colors: const [Color(0xFF166534), Color(0xFF0F766E)],
      kpis: const [
        _KpiData('Ready', '6', 'Awaiting approval', Icons.check_circle_outline,
            AppColors.success),
        _KpiData('Released', '18', 'Today', Icons.task_alt_outlined,
            AppColors.primary),
        _KpiData('Avg score', '96%', 'Quality score', Icons.workspace_premium,
            AppColors.warning),
      ],
      sectionTitle: 'Approval Queue',
      cards: _items,
    );
  }
}

class QualityRejectScreen extends StatelessWidget {
  const QualityRejectScreen({super.key});

  static const _items = [
    {
      'title': 'BSL-24007',
      'subtitle': 'Sweet Basil | Handling loss above limit',
      'metric': '4.2%',
      'status': 'Review',
      'color': AppColors.warning,
    },
    {
      'title': 'LBL-ROLL',
      'subtitle': 'Barcode labels | Wrong print batch',
      'metric': '3 rolls',
      'status': 'Reject',
      'color': AppColors.error,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _QualityPage(
      selectedIndex: 3,
      title: 'Reject & Hold',
      subtitle:
          'Document rejected batches, hold reasons, corrective actions, and release blockers.',
      icon: Icons.cancel_outlined,
      colors: const [Color(0xFF991B1B), Color(0xFFEA580C)],
      kpis: const [
        _KpiData(
            'Rejected', '3', 'Today', Icons.cancel_outlined, AppColors.error),
        _KpiData('On hold', '5', 'Needs review', Icons.pause_circle_outline,
            AppColors.warning),
        _KpiData('Resolved', '9', 'This week', Icons.task_alt_outlined,
            AppColors.success),
      ],
      sectionTitle: 'Exception Queue',
      cards: _items,
    );
  }
}

class QualityReportsScreen extends StatelessWidget {
  const QualityReportsScreen({super.key});

  static const _items = [
    {
      'title': 'Inspection Summary',
      'subtitle': 'Pass rates, sampled batches, and inspection volume',
      'metric': '95%',
      'status': 'Ready',
      'color': AppColors.success,
    },
    {
      'title': 'Rejection Analysis',
      'subtitle': 'Root causes, crop patterns, and line exceptions',
      'metric': '5%',
      'status': 'Review',
      'color': AppColors.warning,
    },
    {
      'title': 'Compliance Export',
      'subtitle': 'Audit-ready QA records and sign-off history',
      'metric': 'PDF',
      'status': 'Export',
      'color': AppColors.primary,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _QualityPage(
      selectedIndex: 4,
      title: 'Quality Reports',
      subtitle:
          'Review quality outcomes, rejection drivers, compliance exports, and approval trends.',
      icon: Icons.assessment_outlined,
      colors: const [Color(0xFF334155), Color(0xFF1D4ED8)],
      kpis: const [
        _KpiData('Reports', '8', 'Ready', Icons.assessment_outlined,
            AppColors.primary),
        _KpiData('Exports', '3', 'Scheduled', Icons.file_download_outlined,
            AppColors.success),
        _KpiData('Findings', '2', 'Need action', Icons.report_problem_outlined,
            AppColors.warning),
      ],
      sectionTitle: 'Report Library',
      cards: _items,
    );
  }
}

class QualitySettingsScreen extends StatefulWidget {
  const QualitySettingsScreen({super.key});

  @override
  State<QualitySettingsScreen> createState() => _QualitySettingsScreenState();
}

class _QualitySettingsScreenState extends State<QualitySettingsScreen> {
  final _api = SuperAdminApiService();
  bool _dualApproval = true;
  bool _inspectionAlerts = true;
  bool _autoExport = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final config = await _api.getSystemConfig();
      if (!mounted) return;
      setState(() {
        _dualApproval = config['qa_require_dual_approval'] as bool? ?? true;
        _inspectionAlerts = config['qa_inspection_alerts'] as bool? ?? true;
        _autoExport = config['qa_auto_export_reports'] as bool? ?? false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load quality settings from the backend.';
      });
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final previous = {
      'qa_require_dual_approval': _dualApproval,
      'qa_inspection_alerts': _inspectionAlerts,
      'qa_auto_export_reports': _autoExport,
    };
    setState(() {
      if (key == 'qa_require_dual_approval') _dualApproval = value;
      if (key == 'qa_inspection_alerts') _inspectionAlerts = value;
      if (key == 'qa_auto_export_reports') _autoExport = value;
      _error = null;
    });
    try {
      await _api.updateSystemConfig({key: value, 'updated_by': 'quality_officer'});
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dualApproval = previous['qa_require_dual_approval']!;
        _inspectionAlerts = previous['qa_inspection_alerts']!;
        _autoExport = previous['qa_auto_export_reports']!;
        _error = 'Could not save the quality setting. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return QualityAssuranceScreenShell(
      selectedIndex: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Hero(
            title: 'Quality Settings',
            subtitle:
                'Manage QA thresholds, approval policies, inspection alerts, and compliance preferences.',
            icon: Icons.settings_outlined,
            colors: [Color(0xFF334155), Color(0xFF475569)],
          ),
          SizedBox(height: AppSpacing.lg),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _SettingsPanel(
              dualApproval: _dualApproval,
              inspectionAlerts: _inspectionAlerts,
              autoExport: _autoExport,
              onChanged: _updateSetting,
            ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _QualityPage extends StatelessWidget {
  static final _dataFuture = FulfillmentDataService().load();
  final int selectedIndex;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final List<_KpiData> kpis;
  final String sectionTitle;
  final List<Map<String, Object>> cards;

  const _QualityPage({
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

    return QualityAssuranceScreenShell(
      selectedIndex: selectedIndex,
      child: FutureBuilder<FulfillmentSnapshot>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Text(
              'Unable to load quality records from the backend.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            );
          }

          final backendCards = _backendCards(snapshot.data!);
          final backendKpis = _backendKpis(snapshot.data!);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Hero(title: title, subtitle: subtitle, icon: icon, colors: colors),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: backendKpis.map((kpi) => _KpiCard(data: kpi)).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                sectionTitle,
                style: AppTypography.h5.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ResponsiveGrid(
                itemCount: backendCards.length,
                itemBuilder: (index) => _QualityCard(item: backendCards[index]),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, Object>> _backendCards(FulfillmentSnapshot snapshot) {
    String value(Map<String, dynamic> item, List<String> keys,
        [String fallback = '']) {
      for (final key in keys) {
        final result = item[key]?.toString().trim() ?? '';
        if (result.isNotEmpty) return result;
      }
      return fallback;
    }

    bool hasStatus(Map<String, dynamic> item, List<String> terms) {
      final status = value(item, ['status', 'delivery_status']).toLowerCase();
      return terms.any(status.contains);
    }

    final records = snapshot.fulfillments.where((item) {
      if (selectedIndex == 1) {
        return !hasStatus(item, ['approve', 'release', 'reject', 'hold']);
      }
      if (selectedIndex == 2) return hasStatus(item, ['approve', 'release', 'packaged']);
      if (selectedIndex == 3) {
        return hasStatus(item, ['reject', 'hold']) ||
            (double.tryParse(item['packaging_waste_weight']?.toString() ?? '') ?? 0) > 0;
      }
      return true;
    }).toList();

    return records.map((item) {
      final status = value(item, ['status', 'delivery_status'], 'Pending');
      final rejected = hasStatus(item, ['reject', 'hold']);
      return <String, Object>{
        'title': value(item, ['batch_number', 'batch_id'], 'Unassigned batch'),
        'subtitle': '${value(item, ['plant_type', 'crop'], 'Unassigned crop')} | QA backend record',
        'metric': value(item, ['total_weight', 'total_packaged_weight'], '0'),
        'status': status,
        'color': rejected ? AppColors.error : AppColors.success,
      };
    }).toList();
  }

  List<_KpiData> _backendKpis(FulfillmentSnapshot snapshot) {
    final records = snapshot.fulfillments;
    bool hasStatus(Map<String, dynamic> item, List<String> terms) {
      final status = '${item['status'] ?? item['delivery_status'] ?? ''}'.toLowerCase();
      return terms.any(status.contains);
    }

    final approved = records.where((item) => hasStatus(item, ['approve', 'release', 'packaged'])).length;
    final rejected = records.where((item) => hasStatus(item, ['reject', 'hold'])).length;
    if (selectedIndex == 1) {
      final pending = records.length - approved - rejected;
      return [
        _KpiData('Pending', '$pending', 'Items waiting', Icons.pending_actions_outlined, AppColors.warning),
        _KpiData('Inspected', '${records.length}', 'Backend records', Icons.fact_check_outlined, AppColors.success),
        _KpiData('Pass rate', '${records.isEmpty ? 0 : (approved / records.length * 100).toStringAsFixed(0)}%', 'Approval ratio', Icons.verified_outlined, AppColors.primary),
      ];
    }
    if (selectedIndex == 2) {
      return [
        _KpiData('Ready', '$approved', 'Awaiting approval', Icons.check_circle_outline, AppColors.success),
        _KpiData('Released', '$approved', 'Backend status', Icons.task_alt_outlined, AppColors.primary),
        _KpiData('Avg score', '${records.isEmpty ? 0 : (approved / records.length * 100).toStringAsFixed(0)}%', 'Quality ratio', Icons.workspace_premium, AppColors.warning),
      ];
    }
    return [
      _KpiData('Rejected', '$rejected', 'Backend records', Icons.cancel_outlined, AppColors.error),
      _KpiData('On hold', '$rejected', 'Needs review', Icons.pause_circle_outline, AppColors.warning),
      _KpiData('Resolved', '0', 'No resolution field', Icons.task_alt_outlined, AppColors.success),
    ];
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
            mainAxisExtent: isMobile ? 300 : 260,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (context, index) => itemBuilder(index),
        );
      },
    );
  }
}

class _QualityCard extends StatelessWidget {
  final Map<String, Object> item;

  const _QualityCard({required this.item});

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
              _IconBox(icon: Icons.verified_outlined, color: color),
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
                        fontWeight: FontWeight.w600,
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
            color: color,
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
        border: Border.all(color: data.color.withOpacity(isDark ? 0.26 : 0.16)),
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
                    fontWeight: FontWeight.w600,
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
  final bool dualApproval;
  final bool inspectionAlerts;
  final bool autoExport;
  final Future<void> Function(String key, bool value) onChanged;

  const _SettingsPanel({
    required this.dualApproval,
    required this.inspectionAlerts,
    required this.autoExport,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SettingRow(
          title: 'Require dual approval',
          subtitle: 'Escalate high-risk batches for supervisor sign-off.',
          icon: Icons.verified_user_outlined,
          enabled: dualApproval,
          onChanged: (value) => onChanged('qa_require_dual_approval', value),
        ),
        _SettingRow(
          title: 'Inspection alerts',
          subtitle: 'Notify QA when pending inspections exceed SLA.',
          icon: Icons.notifications_active_outlined,
          enabled: inspectionAlerts,
          onChanged: (value) => onChanged('qa_inspection_alerts', value),
        ),
        _SettingRow(
          title: 'Auto-export reports',
          subtitle: 'Generate daily QA reports at shift close.',
          icon: Icons.file_download_outlined,
          enabled: autoExport,
          onChanged: (value) => onChanged('qa_auto_export_reports', value),
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
  final ValueChanged<bool> onChanged;

  const _SettingRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onChanged,
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                _MutedText(subtitle),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
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
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
