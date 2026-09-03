import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/fulfillment_manager_screen_shell.dart';
import '../../providers/auth_provider.dart';
import '../../services/fulfillment_data_service.dart';
import '../../services/superadmin_api_service.dart';

class FulfillmentConfirmHarvestScreen extends ConsumerStatefulWidget {
  const FulfillmentConfirmHarvestScreen({super.key});

  @override
  ConsumerState<FulfillmentConfirmHarvestScreen> createState() =>
      _FulfillmentConfirmHarvestScreenState();
}

class _FulfillmentConfirmHarvestScreenState
    extends ConsumerState<FulfillmentConfirmHarvestScreen> {
  final _api = SuperAdminApiService();
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, String>> _packagingSupervisors = [];
  List<String> _packagingTypes = [];
  bool _isLoading = true;
  String? _loadError;
  double _inboundKg = 0;
  final Set<String> _releasingBatchIds = {};

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final snapshot = await FulfillmentDataService().load();
      final fulfillmentByBatch = <String, Map<String, dynamic>>{};
      for (final fulfillment in snapshot.fulfillments) {
        final batchNumber = _value(fulfillment, ['batch_number']);
        if (batchNumber.isNotEmpty) {
          fulfillmentByBatch[batchNumber.toLowerCase()] = fulfillment;
        }
      }

      final requests = snapshot.batches.where((batch) {
        final batchStatus =
            _value(batch, ['production_status', 'status']).toLowerCase();
        final batchNumber = _value(
          batch,
          ['batch_no', 'batch_number', 'batch_id', r'$id'],
        );
        final fulfillment = fulfillmentByBatch[batchNumber.toLowerCase()];
        final fulfillmentStatus =
            _value(fulfillment ?? const {}, ['status']).toLowerCase();
        return (batchStatus == 'harvested' &&
                (fulfillmentStatus.isEmpty ||
                    fulfillmentStatus == 'received')) ||
            (batchStatus == 'delivered' && fulfillmentStatus == 'received');
      }).map((batch) {
        final batchNumber = _value(
          batch,
          ['batch_no', 'batch_number', 'batch_id', r'$id'],
          fallback: 'Unnumbered batch',
        );
        final fulfillment = fulfillmentByBatch[batchNumber.toLowerCase()];
        final inspected =
            _value(fulfillment ?? const {}, ['status']).toLowerCase() ==
                'received';
        final receivedWeight = _number(fulfillment?['total_weight']);
        final batchWeight = _number(batch['total_weight_kg']);
        return <String, dynamic>{
          'id': _docId(batch),
          'batch': batchNumber,
          'farm': _value(
            batch,
            ['farm_name'],
            fallback: 'Unassigned farm',
          ),
          'crop': _value(
            batch,
            ['plant_name', 'plant_type'],
            fallback: 'Unspecified crop',
          ),
          'variety': _value(batch, ['plant_variety', 'variety_name']),
          'quantity':
              '${_formatNumber(receivedWeight > 0 ? receivedWeight : batchWeight)} kg',
          'eta': _formatDate(batch['end_date']),
          'priority': _value(
            fulfillment ?? const {},
            ['priority'],
            fallback: 'Medium',
          ),
          'status': inspected ? 'Inspection Complete' : 'Awaiting Inspection',
          'dock': inspected ? 'Intake verified' : 'Awaiting inspection',
          'owner': _value(
            batch,
            ['farm_manager_name'],
            fallback: 'Unassigned',
          ),
          'quality': inspected ? 'Checks passed' : 'Review required',
          'packaging': _value(
            fulfillment ?? const {},
            ['packaging_type'],
            fallback: 'Not assigned',
          ),
          'inspected': inspected,
          'batchData': batch,
          'fulfillmentData': fulfillment,
        };
      }).toList();

      final supervisors = <String, Map<String, String>>{};
      for (final user in snapshot.users) {
        final role = _value(user, ['role'])
            .toLowerCase()
            .replaceAll('-', '_')
            .replaceAll(' ', '_');
        if (role != 'packaging_supervisor') continue;
        final id = _value(
          user,
          ['user_id', 'account_id', r'$id', 'email'],
        );
        if (id.isEmpty) continue;
        supervisors[id] = {
          'id': id,
          'name': _value(
            user,
            ['name', 'full_name', 'user_name', 'email'],
            fallback: 'Packaging Supervisor',
          ),
        };
      }
      final packagingTypes = snapshot.packages
          .map((package) => _value(
                package,
                ['package_name', 'packaging_type', 'name'],
              ))
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (!mounted) return;
      setState(() {
        _requests = requests;
        _packagingSupervisors = supervisors.values.toList();
        _packagingTypes = packagingTypes;
        _inboundKg = requests.fold<double>(0, (sum, item) {
          final value = double.tryParse(
                  item['quantity'].toString().replaceAll(' kg', '')) ??
              0;
          return sum + value;
        });
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  static String _value(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return fallback;
  }

  static String _docId(Map<String, dynamic> data) =>
      _value(data, [r'$id', 'batch_id', 'id']);

  static double _number(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  static String _formatNumber(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  static String _formatDate(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return 'Not scheduled';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
  }

  Future<void> _showInspectionModal(Map<String, dynamic> request) async {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final user = ref.read(authProvider).user;
    final form = _HarvestInspectionForm(
      request: request,
      packagingTypes: _packagingTypes,
      supervisors: _packagingSupervisors,
      api: _api,
      inspectorId: user?.id ?? user?.email ?? 'fulfillment_manager',
      inspectorName: user?.name ?? 'Fulfillment Manager',
      mobile: isMobile,
    );
    final saved = isMobile
        ? await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => form,
          )
        : await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => form,
          );
    if (saved != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Harvest inspection saved'),
        backgroundColor: AppColors.success,
      ),
    );
    await _loadRequests();
  }

  Future<void> _releaseRequest(Map<String, dynamic> request) async {
    final batchId = request['id']?.toString() ?? '';
    if (batchId.isEmpty || _releasingBatchIds.contains(batchId)) return;
    final confirmed = await _confirmRelease(request);
    if (confirmed != true || !mounted) return;

    setState(() => _releasingBatchIds.add(batchId));
    try {
      final user = ref.read(authProvider).user;
      await _api.releaseHarvestToPackaging(
        batchId: batchId,
        releasedById: user?.id ?? user?.email ?? 'fulfillment_manager',
        releasedByName: user?.name ?? 'Fulfillment Manager',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${request['batch']} released to packaging'),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadRequests();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _releasingBatchIds.remove(batchId));
      }
    }
  }

  Future<bool?> _confirmRelease(Map<String, dynamic> request) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final content = _ReleaseConfirmation(
      batchNumber: request['batch']?.toString() ?? 'Batch',
      crop: request['crop']?.toString() ?? 'Crop',
      farm: request['farm']?.toString() ?? 'Farm',
      mobile: isMobile,
    );
    if (isMobile) {
      return showModalBottomSheet<bool>(
        context: context,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => content,
      );
    }
    return showDialog<bool>(
      context: context,
      builder: (_) => content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return FulfillmentManagerScreenShell(
      selectedIndex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(isDark, isMobile),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_loadError != null)
            _buildLoadError(isDark)
          else ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _FulfillmentStatCard(
                  title: 'Awaiting inspection',
                  value:
                      '${_requests.where((item) => item['inspected'] != true).length} loads',
                  color: AppColors.warning,
                ),
                _FulfillmentStatCard(
                  title: 'Inspection complete',
                  value:
                      '${_requests.where((item) => item['inspected'] == true).length} loads',
                  color: AppColors.primary,
                ),
                _FulfillmentStatCard(
                  title: 'Inbound volume',
                  value: '${_inboundKg.toStringAsFixed(1)} kg',
                  color: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Harvest Intake Queue',
              style: AppTypography.h5.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_requests.isEmpty)
              _buildEmptyState(isDark)
            else
              _buildRequestGrid(context, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadError(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.error),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Could not load the harvest intake queue.',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _loadRequests,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.task_alt_rounded,
            color: AppColors.success,
            size: 36,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Harvest intake is up to date',
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Newly harvested batches will appear here for inspection.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
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
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm Harvest Intake',
            style: AppTypography.h4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 24 : 28,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Validate incoming batches, assign dock readiness, and release confirmed loads into packaging.',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.88),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestGrid(BuildContext context, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        final crossAxisCount = constraints.maxWidth >= 820 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _requests.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: isMobile ? 600 : 460,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (context, index) {
            return _buildRequestCard(context, isDark, _requests[index]);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    bool isDark,
    Map<String, dynamic> request,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final inspected = request['inspected'] == true;
    final batchId = request['id']?.toString() ?? '';
    final isReleasing = _releasingBatchIds.contains(batchId);
    final priority = request['priority'];
    final priorityColor = priority == 'High'
        ? AppColors.error
        : priority == 'Medium'
            ? AppColors.warning
            : AppColors.success;
    final statusColor = _statusColor(request['status']!);
    final headerSection = isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRequestHeader(
                isDark: isDark,
                request: request,
                compact: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _StatusBadge(
                    label: request['priority']!,
                    color: priorityColor,
                  ),
                  _StatusBadge(
                    label: request['status']!,
                    color: statusColor,
                  ),
                ],
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildRequestHeader(
                  isDark: isDark,
                  request: request,
                  compact: false,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(
                    label: request['priority']!,
                    color: priorityColor,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _StatusBadge(
                    label: request['status']!,
                    color: statusColor,
                  ),
                ],
              ),
            ],
          );
    final metricsSection = isMobile
        ? Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetricBlock(
                      label: 'Inbound Volume',
                      value: request['quantity']!,
                      icon: Icons.scale_outlined,
                      color: AppColors.success,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MetricBlock(
                      label: 'ETA',
                      value: request['eta']!,
                      icon: Icons.schedule_outlined,
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _MetricBlock(
                label: 'Dock Lane',
                value: request['dock']!,
                icon: Icons.local_shipping_outlined,
                color: AppColors.warning,
                isDark: isDark,
                fullWidth: true,
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  label: 'Inbound Volume',
                  value: request['quantity']!,
                  icon: Icons.scale_outlined,
                  color: AppColors.success,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricBlock(
                  label: 'ETA',
                  value: request['eta']!,
                  icon: Icons.schedule_outlined,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricBlock(
                  label: 'Dock Lane',
                  value: request['dock']!,
                  icon: Icons.local_shipping_outlined,
                  color: AppColors.warning,
                  isDark: isDark,
                ),
              ),
            ],
          );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        gradient: LinearGradient(
          colors: [
            isDark ? AppColors.surfaceDark : Colors.white,
            statusColor.withOpacity(isDark ? 0.08 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: statusColor.withOpacity(isDark ? 0.28 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
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
              color: statusColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          headerSection,
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
            child: metricsSection,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _MetaPill(label: 'Packaging Plan', value: request['packaging']!),
              _MetaPill(label: 'Quality Gate', value: request['quality']!),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _statusMessage(request['status']!),
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      isReleasing ? null : () => _showInspectionModal(request),
                  icon: Icon(
                    inspected ? Icons.edit_outlined : Icons.fact_check_outlined,
                    size: 18,
                  ),
                  label: Text(inspected ? 'Review' : 'Inspect'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: inspected && !isReleasing
                      ? () => _releaseRequest(request)
                      : null,
                  icon: isReleasing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(isReleasing
                      ? 'Releasing...'
                      : inspected
                          ? 'Release'
                          : 'Inspect first'),
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
        ],
      ),
    );
  }

  Widget _buildRequestHeader({
    required bool isDark,
    required Map<String, dynamic> request,
    required bool compact,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 46 : 48,
          height: compact ? 46 : 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.18),
                AppColors.primary.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            Icons.agriculture_rounded,
            color: AppColors.primary,
            size: compact ? 22 : 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request['crop']!,
                style: AppTypography.h6.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${request['batch']} | ${request['farm']}',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Raised by ${request['owner']}',
                style: AppTypography.caption.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Awaiting Inspection':
        return AppColors.warning;
      case 'Inspection Complete':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'Awaiting Inspection':
        return 'Record the received quantity, packaging plan, and intake checks before release.';
      case 'Inspection Complete':
        return 'Intake checks are saved. This batch is ready to enter the packaging pipeline.';
      default:
        return 'Review intake details and continue the next fulfillment action.';
    }
  }
}

class _HarvestInspectionForm extends StatefulWidget {
  const _HarvestInspectionForm({
    required this.request,
    required this.packagingTypes,
    required this.supervisors,
    required this.api,
    required this.inspectorId,
    required this.inspectorName,
    required this.mobile,
  });

  final Map<String, dynamic> request;
  final List<String> packagingTypes;
  final List<Map<String, String>> supervisors;
  final SuperAdminApiService api;
  final String inspectorId;
  final String inspectorName;
  final bool mobile;

  @override
  State<_HarvestInspectionForm> createState() => _HarvestInspectionFormState();
}

class _HarvestInspectionFormState extends State<_HarvestInspectionForm> {
  final _formKey = GlobalKey<FormState>();
  late String _heads;
  late String _weight;
  late String _packagingType;
  late String _supervisorId;
  late String _temperature;
  late String _priority;
  late String _notes;
  bool _confirmed = false;
  bool _submitting = false;
  String? _error;

  Map<String, dynamic> get _batch =>
      widget.request['batchData'] as Map<String, dynamic>? ?? const {};

  Map<String, dynamic> get _fulfillment =>
      widget.request['fulfillmentData'] as Map<String, dynamic>? ?? const {};

  @override
  void initState() {
    super.initState();
    _heads = _initialNumber(
      _fulfillment['total_heads'] ?? _batch['total_harvested'],
    );
    _weight = _initialNumber(
      _fulfillment['total_weight'] ?? _batch['total_weight_kg'],
    );
    _packagingType = _text(
      _fulfillment['packaging_type'],
      widget.packagingTypes.isEmpty
          ? 'Pending assignment'
          : widget.packagingTypes.first,
    );
    _supervisorId = _text(
      _fulfillment['packaging_supervisor_id'],
      'Unassigned',
    );
    _temperature = _text(_fulfillment['temperature'], 'N/A');
    _priority = _text(_fulfillment['priority'], 'Medium');
    _notes = _text(_fulfillment['delivery_note'], '');
    _confirmed = widget.request['inspected'] == true;
  }

  static String _text(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text.toLowerCase() == 'null' ? fallback : text;
  }

  static String _initialNumber(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '') ?? 0;
    return number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toStringAsFixed(1);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_confirmed) {
      setState(() => _error =
          'Confirm that the physical intake checks have been completed.');
      return;
    }
    final heads = double.tryParse(_heads.trim()) ?? 0;
    final weight = double.tryParse(_weight.trim()) ?? 0;
    if (heads <= 0 && weight <= 0) {
      setState(
          () => _error = 'Enter the received head count or received weight.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.api.inspectHarvestIntake(
        batchId: widget.request['id']?.toString() ?? '',
        data: {
          'total_heads': heads,
          'total_weight': weight,
          'packaging_supervisor_id': _supervisorId,
          'packaging_type': _packagingType,
          'temperature': _temperature.trim().isEmpty ? 'N/A' : _temperature,
          'priority': _priority,
          'notes': _notes.trim(),
          'inspected_by_id': widget.inspectorId,
          'inspected_by_name': widget.inspectorName,
          'inspection_confirmed': true,
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.toString();
      });
    }
  }

  InputDecoration _decoration(
    String label,
    IconData icon,
    bool isDark, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 19),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    );
  }

  Widget _pair(Widget left, Widget right) {
    if (widget.mobile) {
      return Column(
        children: [
          left,
          const SizedBox(height: AppSpacing.md),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: right),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final packagingOptions = {
      'Pending assignment',
      _packagingType,
      ...widget.packagingTypes,
    }.where((item) => item.isNotEmpty).toList();
    final supervisorOptions = <Map<String, String>>[
      {'id': 'Unassigned', 'name': 'Unassigned'},
      ...widget.supervisors,
    ];
    if (!supervisorOptions.any((item) => item['id'] == _supervisorId)) {
      supervisorOptions.add({
        'id': _supervisorId,
        'name': _supervisorId,
      });
    }

    final surface = Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(20),
        bottom: Radius.circular(widget.mobile ? 0 : 20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.fact_check_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.request['inspected'] == true
                            ? 'Review Harvest Inspection'
                            : 'Inspect Harvest Intake',
                        style: AppTypography.h6.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.request['batch']} | ${widget.request['farm']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color:
                              isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed:
                      _submitting ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : AppColors.neutral200,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.07),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Wrap(
                        spacing: AppSpacing.lg,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _InspectionSummary(
                            label: 'Crop',
                            value: widget.request['variety']
                                        ?.toString()
                                        .isNotEmpty ==
                                    true
                                ? '${widget.request['crop']} | ${widget.request['variety']}'
                                : widget.request['crop']?.toString() ?? '-',
                          ),
                          _InspectionSummary(
                            label: 'Expected harvest',
                            value: widget.request['eta']?.toString() ?? '-',
                          ),
                          _InspectionSummary(
                            label: 'Farm manager',
                            value: widget.request['owner']?.toString() ?? '-',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Received quantity',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _pair(
                      TextFormField(
                        initialValue: _heads,
                        enabled: !_submitting,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _decoration(
                          'Received heads',
                          Icons.numbers_rounded,
                          isDark,
                        ),
                        onChanged: (value) => _heads = value,
                        validator: _nonNegativeValidator,
                      ),
                      TextFormField(
                        initialValue: _weight,
                        enabled: !_submitting,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _decoration(
                          'Received weight (kg)',
                          Icons.scale_outlined,
                          isDark,
                        ),
                        onChanged: (value) => _weight = value,
                        validator: _nonNegativeValidator,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Packaging handoff',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _pair(
                      DropdownButtonFormField<String>(
                        initialValue: _packagingType,
                        isExpanded: true,
                        decoration: _decoration(
                          'Packaging plan',
                          Icons.inventory_2_outlined,
                          isDark,
                        ),
                        items: packagingOptions
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: _submitting
                            ? null
                            : (value) => setState(
                                  () => _packagingType = value!,
                                ),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _supervisorId,
                        isExpanded: true,
                        decoration: _decoration(
                          'Packaging supervisor',
                          Icons.person_outline_rounded,
                          isDark,
                        ),
                        items: supervisorOptions
                            .map((item) => DropdownMenuItem(
                                  value: item['id'],
                                  child: Text(
                                    item['name']!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: _submitting
                            ? null
                            : (value) => setState(
                                  () => _supervisorId = value!,
                                ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _pair(
                      TextFormField(
                        initialValue: _temperature,
                        enabled: !_submitting,
                        decoration: _decoration(
                          'Intake temperature',
                          Icons.thermostat_outlined,
                          isDark,
                          hint: 'e.g. 5 C',
                        ),
                        onChanged: (value) => _temperature = value,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _priority,
                        isExpanded: true,
                        decoration: _decoration(
                          'Priority',
                          Icons.flag_outlined,
                          isDark,
                        ),
                        items: const ['Low', 'Medium', 'High']
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ))
                            .toList(),
                        onChanged: _submitting
                            ? null
                            : (value) => setState(() => _priority = value!),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      initialValue: _notes,
                      enabled: !_submitting,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 1000,
                      decoration: _decoration(
                        'Inspection notes',
                        Icons.notes_rounded,
                        isDark,
                        hint: 'Condition, exceptions, or handling notes',
                      ),
                      onChanged: (value) => _notes = value,
                    ),
                    CheckboxListTile(
                      value: _confirmed,
                      enabled: !_submitting,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        'Physical intake checks completed',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Quantity and condition have been verified at the hub.',
                        style: AppTypography.caption.copyWith(
                          color:
                              isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                      onChanged: (value) =>
                          setState(() => _confirmed = value ?? false),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : AppColors.neutral200,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              widget.mobile ? 20 : 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(_submitting ? 'Saving...' : 'Save inspection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.mobile) {
      final availableHeight = MediaQuery.sizeOf(context).height -
          MediaQuery.viewInsetsOf(context).bottom;
      return SizedBox(
        height: availableHeight * 0.92,
        child: surface,
      );
    }
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: surface,
      ),
    );
  }

  String? _nonNegativeValidator(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null) return 'Enter a valid number';
    if (number < 0) return 'Value cannot be negative';
    return null;
  }
}

class _InspectionSummary extends StatelessWidget {
  const _InspectionSummary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReleaseConfirmation extends StatelessWidget {
  const _ReleaseConfirmation({
    required this.batchNumber,
    required this.crop,
    required this.farm,
    required this.mobile,
  });

  final String batchNumber;
  final String crop;
  final String farm;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.precision_manufacturing_outlined,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Release to Packaging',
                  style: AppTypography.h6.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            batchNumber,
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$crop | $farm',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'This will close harvest intake, mark the batch as delivered to the hub, and place the fulfillment record in Packaging.',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Release'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (mobile) {
      return Material(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SafeArea(top: false, child: content),
      );
    }
    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: content,
      ),
    );
  }
}

class _FulfillmentStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _FulfillmentStatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width =
        MediaQuery.of(context).size.width < 600 ? double.infinity : 210.0;

    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.h5.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetaPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool fullWidth;

  const _MetricBlock({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: fullWidth ? AppSpacing.sm : 0,
        vertical: fullWidth ? AppSpacing.xs : 0,
      ),
      decoration: fullWidth
          ? BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.h6.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: color.withOpacity(0.22),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
