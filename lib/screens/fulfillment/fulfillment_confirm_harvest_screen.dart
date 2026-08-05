import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/fulfillment_manager_screen_shell.dart';
import '../../services/fulfillment_data_service.dart';

class FulfillmentConfirmHarvestScreen extends StatefulWidget {
  const FulfillmentConfirmHarvestScreen({super.key});

  @override
  State<FulfillmentConfirmHarvestScreen> createState() =>
      _FulfillmentConfirmHarvestScreenState();
}

class _FulfillmentConfirmHarvestScreenState
    extends State<FulfillmentConfirmHarvestScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  double _inboundKg = 0;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final snapshot = await FulfillmentDataService().load();
      final requests = snapshot.batches
          .where((batch) {
            final status = batch['production_status']?.toString().toLowerCase();
            return status == 'harvested' || status == 'delivered';
          })
          .map((batch) => <String, dynamic>{
                'batch': batch['batch_no'] ??
                    batch['batch_id'] ??
                    'Unnumbered batch',
                'farm': batch['farm_name'] ?? 'Unassigned farm',
                'crop': batch['plant_name'] ?? 'Unspecified crop',
                'quantity': '${batch['total_weight_kg'] ?? 0} kg',
                'eta': batch['end_date'] ?? 'Not scheduled',
                'priority': 'Medium',
                'status': batch['delivery_status'] ?? 'Awaiting intake',
                'dock': 'Unassigned',
                'owner': batch['farm_manager_name'] ?? 'Unassigned',
                'quality': 'Review required',
                'packaging': 'Not assigned',
              })
          .toList();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _inboundKg = requests.fold<double>(0, (sum, item) {
          final value = double.tryParse(
                  item['quantity'].toString().replaceAll(' kg', '')) ??
              0;
          return sum + value;
        });
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
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
          else ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
            children: [
              _FulfillmentStatCard(
                title: 'Pending',
                value: '${_requests.length} loads',
                  color: AppColors.warning,
                ),
              _FulfillmentStatCard(
                title: 'Due before noon',
                value: 'Not recorded',
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
            _buildRequestGrid(context, isDark),
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
                  onPressed: () {},
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: const Text('Inspect'),
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
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Release'),
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
      case 'Awaiting Dock':
        return AppColors.warning;
      case 'Inspection Ready':
        return AppColors.success;
      case 'Arrival Scheduled':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'Awaiting Dock':
        return 'Dock team needs to receive and verify the incoming harvest before packaging release.';
      case 'Inspection Ready':
        return 'Intake checks are complete. This load can be released to the assigned packaging line.';
      case 'Arrival Scheduled':
        return 'Load is scheduled and dock resources should remain reserved until arrival is confirmed.';
      default:
        return 'Review intake details and continue the next fulfillment action.';
    }
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
