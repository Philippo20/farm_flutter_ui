import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/quality_assurance_screen_shell.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

enum QualityWorkflowStage { inspection, approval, rejected }

class QualityWorkflowScreen extends ConsumerStatefulWidget {
  const QualityWorkflowScreen({super.key, required this.stage});

  final QualityWorkflowStage stage;

  @override
  ConsumerState<QualityWorkflowScreen> createState() =>
      _QualityWorkflowScreenState();
}

class _QualityWorkflowScreenState extends ConsumerState<QualityWorkflowScreen> {
  final _api = SuperAdminApiService();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _records = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshView);
    _load();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshView)
      ..dispose();
    super.dispose();
  }

  void _refreshView() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final records = await _api.getFulfillments();
      if (!mounted) return;
      setState(() {
        _records = records;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('SuperAdminApiException: ', '');
        _loading = false;
      });
    }
  }

  String _text(Map<String, dynamic> record, String key,
      [String fallback = '']) {
    final value = record[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  String _qualityStatus(Map<String, dynamic> record) {
    return _text(record, 'quality_status', 'Pending Inspection');
  }

  List<Map<String, dynamic>> get _visibleRecords {
    final query = _searchController.text.trim().toLowerCase();
    return _records.where((record) {
      final fulfillmentStatus = _text(record, 'status').toLowerCase();
      final qualityStatus = _qualityStatus(record).toLowerCase();
      final belongsToStage = switch (widget.stage) {
        QualityWorkflowStage.inspection => fulfillmentStatus == 'packaged' &&
            (qualityStatus == 'pending inspection' ||
                qualityStatus == 'rejected'),
        QualityWorkflowStage.approval => qualityStatus == 'inspected',
        QualityWorkflowStage.rejected => qualityStatus == 'rejected',
      };
      if (!belongsToStage) return false;
      if (query.isEmpty) return true;
      return [
        record['batch_number'],
        record['farm_name'],
        record['plant_type'],
        record['quality_grade'],
      ].any((value) => '$value'.toLowerCase().contains(query));
    }).toList()
      ..sort((a, b) => _sortDate(b).compareTo(_sortDate(a)));
  }

  DateTime _sortDate(Map<String, dynamic> record) {
    return DateTime.tryParse(_text(record, 'quality_inspected_at')) ??
        DateTime.tryParse(_text(record, r'$updatedAt')) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  int get _pendingCount => _records
      .where((record) =>
          _text(record, 'status').toLowerCase() == 'packaged' &&
          _qualityStatus(record).toLowerCase() == 'pending inspection')
      .length;

  int get _inspectedCount => _records
      .where((record) => _qualityStatus(record).toLowerCase() == 'inspected')
      .length;

  int get _approvedCount => _records
      .where((record) => _qualityStatus(record).toLowerCase() == 'approved')
      .length;

  int get _rejectedCount => _records
      .where((record) => _qualityStatus(record).toLowerCase() == 'rejected')
      .length;

  Future<void> _openRecord(Map<String, dynamic> record) async {
    final user = ref.read(authProvider).user;
    final form = widget.stage == QualityWorkflowStage.approval
        ? _QualityDecisionForm(
            record: record,
            api: _api,
            userId: user?.id ?? 'quality-officer',
            userName: user?.name ?? 'Quality Assurance',
          )
        : _QualityInspectionForm(
            record: record,
            api: _api,
            userId: user?.id ?? 'quality-officer',
            userName: user?.name ?? 'Quality Assurance',
          );
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final changed = isMobile
        ? await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => form,
          )
        : await showDialog<bool>(context: context, builder: (_) => form);
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final config = _StageConfig.forStage(widget.stage);
    return QualityAssuranceScreenShell(
      selectedIndex: config.selectedIndex,
      child: _loading
          ? const AdminDataSkeleton(rowCount: 4)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WorkflowHero(config: config, onRefresh: _load),
                const SizedBox(height: AppSpacing.lg),
                _KpiStrip(
                  pending: _pendingCount,
                  inspected: _inspectedCount,
                  approved: _approvedCount,
                  rejected: _rejectedCount,
                ),
                const SizedBox(height: AppSpacing.lg),
                _QueueToolbar(
                  title: config.sectionTitle,
                  count: _visibleRecords.length,
                  controller: _searchController,
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _InlineMessage(message: _error!, error: true),
                ],
                const SizedBox(height: AppSpacing.md),
                if (_visibleRecords.isEmpty)
                  _EmptyQueue(config: config)
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900 ? 2 : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _visibleRecords.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: 238,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                        ),
                        itemBuilder: (_, index) => _WorkflowCard(
                          record: _visibleRecords[index],
                          config: config,
                          onTap: () => _openRecord(_visibleRecords[index]),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

class _StageConfig {
  const _StageConfig({
    required this.selectedIndex,
    required this.title,
    required this.subtitle,
    required this.sectionTitle,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.actionLabel,
    required this.icon,
    required this.color,
  });

  final int selectedIndex;
  final String title;
  final String subtitle;
  final String sectionTitle;
  final String emptyTitle;
  final String emptyMessage;
  final String actionLabel;
  final IconData icon;
  final Color color;

  static _StageConfig forStage(QualityWorkflowStage stage) {
    return switch (stage) {
      QualityWorkflowStage.inspection => const _StageConfig(
          selectedIndex: 1,
          title: 'Quality Inspection',
          subtitle:
              'Verify packaged batches against operational quality gates before release.',
          sectionTitle: 'Inspection queue',
          emptyTitle: 'No batches awaiting inspection',
          emptyMessage:
              'Batches appear here after the packaging supervisor completes packaging.',
          actionLabel: 'Inspect batch',
          icon: Icons.fact_check_outlined,
          color: Color(0xFF1D4ED8),
        ),
      QualityWorkflowStage.approval => const _StageConfig(
          selectedIndex: 2,
          title: 'Approval Control',
          subtitle:
              'Review recorded findings and release compliant batches to the sales pipeline.',
          sectionTitle: 'Ready for decision',
          emptyTitle: 'No inspections awaiting approval',
          emptyMessage:
              'Completed inspections appear here until they are approved or rejected.',
          actionLabel: 'Review decision',
          icon: Icons.verified_outlined,
          color: Color(0xFF15803D),
        ),
      QualityWorkflowStage.rejected => const _StageConfig(
          selectedIndex: 3,
          title: 'Quality Holds',
          subtitle:
              'Track rejected batches, corrective-action reasons, and reinspection readiness.',
          sectionTitle: 'Rejected batches',
          emptyTitle: 'No batches on quality hold',
          emptyMessage: 'Rejected batches and their reasons will appear here.',
          actionLabel: 'Reinspect batch',
          icon: Icons.gpp_bad_outlined,
          color: AppColors.error,
        ),
    };
  }
}

class _WorkflowHero extends StatelessWidget {
  const _WorkflowHero({required this.config, required this.onRefresh});

  final _StageConfig config;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: config.color.withValues(alpha: .18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconTile(icon: config.icon, color: config.color, size: 52),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: AppTypography.h4.copyWith(
                    fontSize: mobile ? 23 : 28,
                    fontWeight: FontWeight.w600,
                    color: dark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  config.subtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: dark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh quality records',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({
    required this.pending,
    required this.inspected,
    required this.approved,
    required this.rejected,
  });

  final int pending;
  final int inspected;
  final int approved;
  final int rejected;

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('Pending', pending, Icons.pending_actions_outlined, AppColors.warning),
      ('Inspected', inspected, Icons.fact_check_outlined, AppColors.primary),
      ('Approved', approved, Icons.verified_outlined, AppColors.success),
      ('On hold', rejected, Icons.pause_circle_outline, AppColors.error),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth < 600 ? 2 : 4;
      final width =
          (constraints.maxWidth - (columns - 1) * AppSpacing.sm) / columns;
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: entries
            .map((entry) => SizedBox(
                  width: width,
                  child: _MiniKpi(
                    label: entry.$1,
                    value: entry.$2,
                    icon: entry.$3,
                    color: entry.$4,
                  ),
                ))
            .toList(),
      );
    });
  }
}

class _MiniKpi extends StatelessWidget {
  const _MiniKpi(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 96,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: dark ? Colors.white10 : AppColors.neutral200),
      ),
      child: Row(children: [
        _IconTile(icon: icon, color: color, size: 38),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value',
                style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.w600,
                    color: dark ? Colors.white : AppColors.textPrimary)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                    color: dark ? Colors.white70 : AppColors.textSecondary)),
          ],
        )),
      ]),
    );
  }
}

class _QueueToolbar extends StatelessWidget {
  const _QueueToolbar(
      {required this.title, required this.count, required this.controller});

  final String title;
  final int count;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final titleWidget = Row(children: [
      Expanded(
          child: Text(title,
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w600))),
      _CountBadge(count: count),
    ]);
    final search = SizedBox(
      width: mobile ? double.infinity : 320,
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'Search batch, farm or crop',
          prefixIcon: Icon(Icons.search_rounded),
          isDense: true,
        ),
      ),
    );
    return mobile
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            titleWidget,
            const SizedBox(height: AppSpacing.sm),
            search
          ])
        : Row(children: [
            Expanded(child: titleWidget),
            const SizedBox(width: AppSpacing.md),
            search
          ]);
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard(
      {required this.record, required this.config, required this.onTap});

  final Map<String, dynamic> record;
  final _StageConfig config;
  final VoidCallback onTap;

  String value(String key, [String fallback = 'Not set']) {
    final text = record[key]?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final score = double.tryParse('${record['quality_score'] ?? 0}') ?? 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: dark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border:
                Border.all(color: dark ? Colors.white10 : AppColors.neutral200),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _IconTile(icon: config.icon, color: config.color, size: 44),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(value('batch_number', 'Unassigned batch'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h6
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(
                        '${value('plant_type', 'Crop')} | ${value('farm_name', 'Unassigned farm')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                            color: dark
                                ? Colors.white70
                                : AppColors.textSecondary)),
                  ])),
              _StatusChip(
                  label: value('quality_status', 'Pending Inspection'),
                  color: config.color),
            ]),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              Expanded(
                  child: _CardMetric(
                      label: 'Packaged weight',
                      value: '${value('total_packaged_weight', '0')} kg')),
              Expanded(
                  child: _CardMetric(
                      label: 'QA score',
                      value: score == 0
                          ? 'Not scored'
                          : '${score.toStringAsFixed(0)}%')),
              Expanded(
                  child: _CardMetric(
                      label: 'Grade',
                      value: value('quality_grade', 'Pending'))),
            ]),
            const Spacer(),
            Row(children: [
              Expanded(
                  child: Text(
                      value('quality_rejection_reason',
                          'Open the record to review and update quality data.'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                          color: dark
                              ? Colors.white60
                              : AppColors.textSecondary))),
              const SizedBox(width: AppSpacing.sm),
              TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(config.actionLabel)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _QualityInspectionForm extends StatefulWidget {
  const _QualityInspectionForm(
      {required this.record,
      required this.api,
      required this.userId,
      required this.userName});

  final Map<String, dynamic> record;
  final SuperAdminApiService api;
  final String userId;
  final String userName;

  @override
  State<_QualityInspectionForm> createState() => _QualityInspectionFormState();
}

class _QualityInspectionFormState extends State<_QualityInspectionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _notes;
  late Map<String, bool> _checks;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _notes =
        TextEditingController(text: '${widget.record['quality_notes'] ?? ''}');
    Map<String, dynamic> saved = const {};
    try {
      final decoded = jsonDecode('${widget.record['quality_checks'] ?? '{}'}');
      if (decoded is Map<String, dynamic>) saved = decoded;
    } catch (_) {}
    _checks = {
      'appearance': saved['appearance'] == true,
      'package_integrity': saved['package_integrity'] == true,
      'label_traceability': saved['label_traceability'] == true,
      'weight_compliance': saved['weight_compliance'] == true,
      'temperature_compliance': saved['temperature_compliance'] == true,
    };
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  int get _score => _checks.values.where((value) => value).length * 20;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_checks.values.any((value) => !value) && _notes.text.trim().isEmpty) {
      setState(() => _error = 'Add notes explaining each failed quality gate.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.recordQualityInspection(
        fulfillmentId: '${widget.record[r'$id']}',
        data: {
          'appearance_passed': _checks['appearance'],
          'package_integrity_passed': _checks['package_integrity'],
          'label_traceability_passed': _checks['label_traceability'],
          'weight_compliance_passed': _checks['weight_compliance'],
          'temperature_compliance_passed': _checks['temperature_compliance'],
          'notes': _notes.text.trim(),
          'inspected_by_id': widget.userId,
          'inspected_by_name': widget.userName,
        },
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              error.toString().replaceFirst('SuperAdminApiException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _WorkflowModalFrame(
      icon: Icons.fact_check_outlined,
      title: 'Inspect ${widget.record['batch_number'] ?? 'batch'}',
      subtitle:
          '${widget.record['plant_type'] ?? 'Crop'} | ${widget.record['farm_name'] ?? 'Farm'}',
      saving: _saving,
      primaryLabel: 'Save inspection',
      onPrimary: _submit,
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _InspectionSummary(record: widget.record, score: _score),
          const SizedBox(height: AppSpacing.lg),
          const _QaModalLabel('Quality Gates'),
          const SizedBox(height: 6),
          ...[
            (
              'appearance',
              'Visual appearance',
              'Color, freshness and physical condition'
            ),
            (
              'package_integrity',
              'Package integrity',
              'Seal, container and contamination check'
            ),
            (
              'label_traceability',
              'Label and traceability',
              'Batch code and product label verified'
            ),
            (
              'weight_compliance',
              'Weight compliance',
              'Recorded package weight is within tolerance'
            ),
            (
              'temperature_compliance',
              'Temperature compliance',
              'Product temperature is within the safe range'
            ),
          ].map((gate) => _GateTile(
                title: gate.$2,
                subtitle: gate.$3,
                value: _checks[gate.$1]!,
                onChanged: (value) => setState(() => _checks[gate.$1] = value),
              )),
          const SizedBox(height: AppSpacing.md),
          _QaModalTextField(
            label: 'Inspection Notes',
            hint: 'Record observations, variances, or corrective guidance',
            icon: Icons.notes_rounded,
            controller: _notes,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _InlineMessage(message: _error!, error: true)
          ],
        ]),
      ),
    );
  }
}

class _QualityDecisionForm extends StatefulWidget {
  const _QualityDecisionForm(
      {required this.record,
      required this.api,
      required this.userId,
      required this.userName});

  final Map<String, dynamic> record;
  final SuperAdminApiService api;
  final String userId;
  final String userName;

  @override
  State<_QualityDecisionForm> createState() => _QualityDecisionFormState();
}

class _QualityDecisionFormState extends State<_QualityDecisionForm> {
  final _reason = TextEditingController();
  String _decision = 'Approve';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_decision == 'Reject' && _reason.text.trim().isEmpty) {
      setState(() => _error =
          'Enter the rejection reason before placing this batch on hold.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.recordQualityDecision(
        fulfillmentId: '${widget.record[r'$id']}',
        data: {
          'decision': _decision,
          'reason': _reason.text.trim(),
          'decided_by_id': widget.userId,
          'decided_by_name': widget.userName,
        },
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              error.toString().replaceFirst('SuperAdminApiException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final score =
        double.tryParse('${widget.record['quality_score'] ?? 0}') ?? 0;
    return _WorkflowModalFrame(
      icon: Icons.verified_outlined,
      title: 'Quality decision',
      subtitle:
          '${widget.record['batch_number'] ?? 'Batch'} | ${widget.record['plant_type'] ?? 'Crop'}',
      saving: _saving,
      primaryLabel:
          _decision == 'Approve' ? 'Approve and release' : 'Reject batch',
      onPrimary: _submit,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _InspectionSummary(record: widget.record, score: score.round()),
        const SizedBox(height: AppSpacing.lg),
        _ReadOnlyFindings(record: widget.record),
        const SizedBox(height: AppSpacing.lg),
        const _QaModalLabel('Decision'),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
                value: 'Approve',
                label: Text('Approve'),
                icon: Icon(Icons.check_circle_outline)),
            ButtonSegment(
                value: 'Reject',
                label: Text('Reject'),
                icon: Icon(Icons.cancel_outlined)),
          ],
          selected: {_decision},
          onSelectionChanged: _saving
              ? null
              : (values) => setState(() {
                    _decision = values.first;
                    _error = null;
                  }),
        ),
        if (_decision == 'Reject') ...[
          const SizedBox(height: 12),
          _QaModalTextField(
            label: 'Rejection Reason',
            hint: 'Describe the issue and required corrective action',
            icon: Icons.report_problem_outlined,
            controller: _reason,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _InlineMessage(message: _error!, error: true)
        ],
      ]),
    );
  }
}

class _WorkflowModalFrame extends StatelessWidget {
  const _WorkflowModalFrame(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.saving,
      required this.primaryLabel,
      required this.onPrimary,
      required this.child});

  final IconData icon;
  final String title;
  final String subtitle;
  final bool saving;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final content = Container(
      constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * (mobile ? .94 : .9)),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.vertical(
            top: const Radius.circular(16),
            bottom: Radius.circular(mobile ? 0 : 16)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (mobile) ...[
          const SizedBox(height: 10),
          Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                  color: dark ? Colors.white24 : AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2))),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: .75),
                ]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: AppTypography.bodyLarge
                          .copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                          fontSize: 12,
                          color:
                              dark ? Colors.white38 : AppColors.textSecondary)),
                ])),
            IconButton(
                tooltip: 'Close',
                onPressed: saving ? null : () => Navigator.pop(context, false),
                icon: const Icon(Icons.close_rounded, size: 18)),
          ]),
        ),
        Flexible(
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: child)),
        Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, mobile ? 24 : 24),
          child: Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed:
                        saving ? null : () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44)),
                    child: const Text('Cancel'))),
            const SizedBox(width: 8),
            Expanded(
                child: ElevatedButton.icon(
              onPressed: saving ? null : onPrimary,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded, size: 16),
              label: Text(saving ? 'Saving...' : primaryLabel),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            )),
          ]),
        ),
      ]),
    );
    return mobile
        ? content
        : Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: content);
  }
}

class _QaModalLabel extends StatelessWidget {
  const _QaModalLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: AppTypography.bodySmall.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: dark ? Colors.white54 : AppColors.textSecondary,
      ),
    );
  }
}

class _QaModalTextField extends StatelessWidget {
  const _QaModalTextField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = dark
        ? Colors.white.withValues(alpha: .06)
        : Colors.black.withValues(alpha: .06);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QaModalLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          maxLength: 1000,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 12,
            color: dark ? Colors.white : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodySmall.copyWith(
              fontSize: 12,
              color: dark ? Colors.white24 : AppColors.textSecondary,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(bottom: 54),
              child: Icon(icon,
                  size: 16,
                  color: dark ? Colors.white24 : AppColors.textSecondary),
            ),
            filled: true,
            fillColor: dark
                ? Colors.white.withValues(alpha: .04)
                : AppColors.neutral50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _InspectionSummary extends StatelessWidget {
  const _InspectionSummary({required this.record, required this.score});

  final Map<String, dynamic> record;
  final int score;

  @override
  Widget build(BuildContext context) {
    final values = [
      ('Packaged', '${record['total_packaged_weight'] ?? 0} kg'),
      ('Package', '${record['packaging_type'] ?? 'Not set'}'),
      ('Temperature', '${record['temperature'] ?? 'N/A'}'),
      ('Score', '$score%'),
    ];
    return LayoutBuilder(builder: (_, constraints) {
      final width = (constraints.maxWidth - AppSpacing.sm) / 2;
      return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: values
              .map((item) => SizedBox(
                  width: width,
                  child: _SummaryCell(label: item.$1, value: item.$2)))
              .toList());
    });
  }
}

class _ReadOnlyFindings extends StatelessWidget {
  const _ReadOnlyFindings({required this.record});
  final Map<String, dynamic> record;

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> checks = const {};
    try {
      final decoded = jsonDecode('${record['quality_checks'] ?? '{}'}');
      if (decoded is Map<String, dynamic>) checks = decoded;
    } catch (_) {}
    final findings = [
      ('Appearance', checks['appearance'] == true),
      ('Package integrity', checks['package_integrity'] == true),
      ('Label and traceability', checks['label_traceability'] == true),
      ('Weight compliance', checks['weight_compliance'] == true),
      ('Temperature compliance', checks['temperature_compliance'] == true),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Inspection findings',
          style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: AppSpacing.sm),
      ...findings.map((finding) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Icon(
                  finding.$2
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: finding.$2 ? AppColors.success : AppColors.error,
                  size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: Text(finding.$1, style: AppTypography.bodyMedium)),
              Text(finding.$2 ? 'Passed' : 'Failed',
                  style: AppTypography.bodySmall.copyWith(
                      color: finding.$2 ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600)),
            ]),
          )),
      if ('${record['quality_notes'] ?? ''}'.trim().isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        _InlineMessage(message: '${record['quality_notes']}', error: false),
      ],
    ]);
  }
}

class _GateTile extends StatelessWidget {
  const _GateTile(
      {required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: value
            ? AppColors.success.withValues(alpha: .08)
            : (dark
                ? Colors.white.withValues(alpha: .04)
                : AppColors.neutral50),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          value: value,
          onChanged: onChanged,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          title: Text(title,
              style: AppTypography.bodySmall
                  .copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle,
              style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  color: dark ? Colors.white70 : AppColors.textSecondary)),
          secondary: Icon(
              value ? Icons.check_circle_outline : Icons.radio_button_unchecked,
              color: value ? AppColors.success : AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 74,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
          color:
              dark ? Colors.white.withValues(alpha: .04) : AppColors.neutral50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: .06)
                : Colors.black.withValues(alpha: .06),
          )),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: AppTypography.bodySmall.copyWith(
                    color: dark ? Colors.white60 : AppColors.textSecondary)),
            const SizedBox(height: 3),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
          ]),
    );
  }
}

class _CardMetric extends StatelessWidget {
  const _CardMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 3),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      ]);
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: AppTypography.bodySmall
                .copyWith(color: color, fontWeight: FontWeight.w600)),
      );
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(20)),
        child: Text('$count',
            style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w600)),
      );
}

class _IconTile extends StatelessWidget {
  const _IconTile(
      {required this.icon, required this.color, required this.size});
  final IconData icon;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        child: Icon(icon, color: color, size: size * .5),
      );
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.error});
  final String message;
  final bool error;
  @override
  Widget build(BuildContext context) {
    final color = error ? AppColors.error : AppColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withValues(alpha: .18))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(error ? Icons.error_outline : Icons.notes_rounded,
            color: color, size: 19),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: Text(message,
                style: AppTypography.bodySmall.copyWith(color: color))),
      ]),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue({required this.config});
  final _StageConfig config;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(vertical: 48, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceDark
                : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10
                    : AppColors.neutral200)),
        child: Column(children: [
          _IconTile(icon: config.icon, color: config.color, size: 56),
          const SizedBox(height: AppSpacing.md),
          Text(config.emptyTitle,
              textAlign: TextAlign.center,
              style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(config.emptyMessage,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ]),
      );
}
