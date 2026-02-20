import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class OverallDeliveryControlModule extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isMobile;

  const OverallDeliveryControlModule({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isMobile,
  });

  @override
  State<OverallDeliveryControlModule> createState() =>
      _OverallDeliveryControlModuleState();
}

class _OverallDeliveryControlModuleState
    extends State<OverallDeliveryControlModule> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm');
  String _selectedFarm = 'All Farms';
  String _selectedStatus = 'All';
  int _selectedTab = 0;

  final List<String> _farms = const [
    'All Farms',
    'Green Valley Farm',
    'Sunny Acres',
    'Harvest Moon Farm',
    'Golden Fields',
  ];

  final List<_DeliveryRecord> _deliveries = const [
    _DeliveryRecord(
      id: 'DEL-001',
      farm: 'Green Valley Farm',
      destination: 'Fresh Mart Supermarket',
      crop: 'Lettuce',
      quantity: 500,
      unit: 'heads',
      status: _DeliveryStatus.inTransit,
      priority: _DeliveryPriority.high,
      driver: 'Adebayo Okonkwo',
      vehicle: 'Toyota Dyna LG-234-ABC',
      scheduledAt: '2026-02-17 09:30',
      eta: '2026-02-17 14:30',
    ),
    _DeliveryRecord(
      id: 'DEL-002',
      farm: 'Sunny Acres',
      destination: 'Shoprite Ikeja',
      crop: 'Spinach',
      quantity: 300,
      unit: 'heads',
      status: _DeliveryStatus.delivered,
      priority: _DeliveryPriority.medium,
      driver: 'Chinedu Eze',
      vehicle: 'Hyundai H100 LG-567-DEF',
      scheduledAt: '2026-02-16 08:00',
      eta: '2026-02-16 11:00',
    ),
    _DeliveryRecord(
      id: 'DEL-003',
      farm: 'Harvest Moon Farm',
      destination: 'Jara Foods Distribution',
      crop: 'Tomatoes',
      quantity: 1000,
      unit: 'kg',
      status: _DeliveryStatus.scheduled,
      priority: _DeliveryPriority.high,
      driver: 'Unassigned',
      vehicle: 'Pending',
      scheduledAt: '2026-02-18 07:30',
      eta: '2026-02-18 10:00',
    ),
    _DeliveryRecord(
      id: 'DEL-004',
      farm: 'Golden Fields',
      destination: 'Spar Lekki',
      crop: 'Cabbage',
      quantity: 200,
      unit: 'heads',
      status: _DeliveryStatus.pendingApproval,
      priority: _DeliveryPriority.medium,
      driver: 'Unassigned',
      vehicle: 'Pending',
      scheduledAt: '2026-02-17 16:00',
      eta: '2026-02-17 19:00',
    ),
    _DeliveryRecord(
      id: 'DEL-005',
      farm: 'Green Valley Farm',
      destination: 'Hubmart Stores',
      crop: 'Lettuce',
      quantity: 750,
      unit: 'heads',
      status: _DeliveryStatus.onHold,
      priority: _DeliveryPriority.high,
      driver: 'N/A',
      vehicle: 'N/A',
      scheduledAt: '2026-02-17 11:30',
      eta: '2026-02-17 15:00',
    ),
  ];

  final List<_DeliveryActivity> _activities = [
    _DeliveryActivity(
      id: 'ACT-5001',
      deliveryId: 'DEL-004',
      farm: 'Golden Fields',
      message: 'Delivery submitted for approval',
      actor: 'Farm Manager - Esi Boateng',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 25)),
      type: _ActivityType.info,
    ),
    _DeliveryActivity(
      id: 'ACT-5002',
      deliveryId: 'DEL-001',
      farm: 'Green Valley Farm',
      message: 'Driver check-in completed at dispatch point',
      actor: 'Logistics - Kojo Asare',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 10)),
      type: _ActivityType.success,
    ),
    _DeliveryActivity(
      id: 'ACT-5003',
      deliveryId: 'DEL-005',
      farm: 'Green Valley Farm',
      message: 'Delivery moved to hold due to cold chain alert',
      actor: 'Admin - Acquaye',
      timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 35)),
      type: _ActivityType.warning,
    ),
    _DeliveryActivity(
      id: 'ACT-5004',
      deliveryId: 'DEL-002',
      farm: 'Sunny Acres',
      message: 'Proof of delivery uploaded and verified',
      actor: 'Quality Team - Nana Ofori',
      timestamp: DateTime.now().subtract(const Duration(hours: 6, minutes: 50)),
      type: _ActivityType.success,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredDeliveries = _filteredDeliveries();
    final filteredActivities = _filteredActivities();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(isDark),
        const SizedBox(height: AppSpacing.lg),
        _buildStats(isDark, filteredDeliveries),
        const SizedBox(height: AppSpacing.lg),
        _buildFilters(isDark),
        const SizedBox(height: AppSpacing.lg),
        _buildTabs(isDark),
        const SizedBox(height: AppSpacing.md),
        if (_selectedTab == 0)
          _buildDeliveryControlList(isDark, filteredDeliveries)
        else
          _buildActivityLog(isDark, filteredActivities),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: AppTypography.h4.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.subtitle,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(bool isDark, List<_DeliveryRecord> records) {
    final total = records.length;
    final pendingApproval =
        records.where((record) => record.status == _DeliveryStatus.pendingApproval).length;
    final inTransit =
        records.where((record) => record.status == _DeliveryStatus.inTransit).length;
    final delivered =
        records.where((record) => record.status == _DeliveryStatus.delivered).length;

    final cards = [
      _StatData('Deliveries', '$total', Icons.local_shipping, AppColors.primary),
      _StatData('Pending Approval', '$pendingApproval', Icons.approval, AppColors.warning),
      _StatData('In Transit', '$inTransit', Icons.route, AppColors.info),
      _StatData('Delivered', '$delivered', Icons.check_circle, AppColors.success),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = widget.isMobile ? 2 : (width > 1100 ? 4 : 2);
        final ratio = widget.isMobile ? 2.1 : (crossAxisCount == 4 ? 2.3 : 2.6);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: ratio,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: card.color.withOpacity(isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: card.color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: card.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(card.icon, color: card.color, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.value,
                          style: AppTypography.h6.copyWith(
                            color: card.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          card.label,
                          style: AppTypography.caption.copyWith(
                            color: card.color.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          if (widget.isMobile)
            Column(
              children: [
                _buildSearchField(isDark),
                const SizedBox(height: AppSpacing.sm),
                _buildFarmDropdown(isDark),
              ],
            )
          else
            Row(
              children: [
                Expanded(flex: 2, child: _buildSearchField(isDark)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _buildFarmDropdown(isDark)),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                'All',
                'Pending Approval',
                'Scheduled',
                'In Transit',
                'Delivered',
                'On Hold',
                'Cancelled',
              ].map((status) {
                final selected = _selectedStatus == status;
                return ChoiceChip(
                  label: Text(status),
                  selected: selected,
                  onSelected: (value) {
                    if (value) {
                      setState(() => _selectedStatus = status);
                    }
                  },
                  selectedColor: AppColors.primary.withOpacity(0.18),
                  backgroundColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral100,
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color: selected
                        ? AppColors.primary
                        : (isDark ? Colors.white70 : AppColors.textSecondary),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search delivery ID, destination, crop, driver...',
        hintStyle: TextStyle(color: isDark ? Colors.white38 : AppColors.textSecondary),
        prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : AppColors.textSecondary),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildFarmDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: isDark ? Colors.white12 : AppColors.neutral200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFarm,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white54 : AppColors.textSecondary),
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
          items: _farms
              .map((farm) => DropdownMenuItem<String>(
                    value: farm,
                    child: Text(farm),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedFarm = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          _buildTabItem(
            isDark: isDark,
            label: 'Control Center',
            icon: Icons.local_shipping_rounded,
            index: 0,
          ),
          _buildTabItem(
            isDark: isDark,
            label: 'Activity Logs',
            icon: Icons.history_rounded,
            index: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required bool isDark,
    required String label,
    required IconData icon,
    required int index,
  }) {
    final selected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? AppColors.primary
                    : (isDark ? Colors.white70 : AppColors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.primary
                      : (isDark ? Colors.white70 : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryControlList(bool isDark, List<_DeliveryRecord> records) {
    if (records.isEmpty) {
      return _buildEmptyState(
        isDark: isDark,
        icon: Icons.local_shipping_outlined,
        title: 'No deliveries found',
        subtitle: 'Try changing farm, status, or search filters.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: records.map((record) => _buildDeliveryCard(isDark, record)).toList(),
      ),
    );
  }

  Widget _buildDeliveryCard(bool isDark, _DeliveryRecord record) {
    final statusColor = _statusColor(record.status);
    final priorityColor = _priorityColor(record.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.local_shipping, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${record.id}  |  ${record.farm}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${record.crop}  |  ${record.quantity} ${record.unit}  |  ${record.destination}',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _pill(record.status.label, statusColor),
                  const SizedBox(height: 4),
                  _pill(record.priority.label, priorityColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Driver: ${record.driver}  |  Vehicle: ${record.vehicle}',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Scheduled: ${record.scheduledAt}  |  ETA: ${record.eta}',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _buildActionsFor(record, isDark),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionsFor(_DeliveryRecord record, bool isDark) {
    final actions = <Widget>[];

    if (record.status == _DeliveryStatus.pendingApproval) {
      actions.add(
        _actionButton(
          isDark: isDark,
          label: 'Approve',
          icon: Icons.check_circle,
          color: AppColors.success,
          onPressed: () =>
              _openActionModal(action: _DeliveryAction.approve, record: record),
        ),
      );
      actions.add(
        _actionButton(
          isDark: isDark,
          label: 'Reject',
          icon: Icons.cancel,
          color: AppColors.error,
          onPressed: () =>
              _openActionModal(action: _DeliveryAction.reject, record: record),
        ),
      );
    }

    if (record.status == _DeliveryStatus.scheduled ||
        record.status == _DeliveryStatus.pendingApproval) {
      actions.add(
        _actionButton(
          isDark: isDark,
          label: 'Assign Driver',
          icon: Icons.person_add,
          color: AppColors.primary,
          onPressed: () => _openActionModal(
            action: _DeliveryAction.assignDriver,
            record: record,
          ),
        ),
      );
    }

    if (record.status == _DeliveryStatus.scheduled ||
        record.status == _DeliveryStatus.inTransit) {
      actions.add(
        _actionButton(
          isDark: isDark,
          label: 'Put On Hold',
          icon: Icons.pause_circle,
          color: AppColors.warning,
          onPressed: () =>
              _openActionModal(action: _DeliveryAction.putOnHold, record: record),
        ),
      );
    }

    if (record.status != _DeliveryStatus.delivered &&
        record.status != _DeliveryStatus.cancelled) {
      actions.add(
        _actionButton(
          isDark: isDark,
          label: 'Cancel',
          icon: Icons.block,
          color: AppColors.error,
          onPressed: () =>
              _openActionModal(action: _DeliveryAction.cancel, record: record),
        ),
      );
    }

    actions.add(
      _actionButton(
        isDark: isDark,
        label: 'View Details',
        icon: Icons.visibility,
        color: AppColors.info,
        onPressed: () =>
            _openActionModal(action: _DeliveryAction.viewDetails, record: record),
      ),
    );
    return actions;
  }

  Widget _actionButton({
    required bool isDark,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.zero,
        ),
      ),
    );
  }

  void _openActionModal({
    required _DeliveryAction action,
    required _DeliveryRecord record,
  }) {
    switch (action) {
      case _DeliveryAction.approve:
        _showDecisionModal(
          record: record,
          title: 'Approve Delivery',
          confirmLabel: 'Approve',
          confirmColor: AppColors.success,
          prompt: 'Confirm and approve this delivery request?',
        );
        break;
      case _DeliveryAction.reject:
        _showDecisionModal(
          record: record,
          title: 'Reject Delivery',
          confirmLabel: 'Reject',
          confirmColor: AppColors.error,
          prompt: 'Reject this delivery request and send feedback?',
        );
        break;
      case _DeliveryAction.assignDriver:
        _showAssignDriverModal(record);
        break;
      case _DeliveryAction.putOnHold:
        _showDecisionModal(
          record: record,
          title: 'Put Delivery On Hold',
          confirmLabel: 'Hold Delivery',
          confirmColor: AppColors.warning,
          prompt: 'Pause this delivery until issue is resolved?',
        );
        break;
      case _DeliveryAction.cancel:
        _showDecisionModal(
          record: record,
          title: 'Cancel Delivery',
          confirmLabel: 'Cancel Delivery',
          confirmColor: AppColors.error,
          prompt: 'Cancel this delivery operation?',
        );
        break;
      case _DeliveryAction.viewDetails:
        _showDeliveryDetailsModal(record);
        break;
    }
  }

  void _showDecisionModal({
    required _DeliveryRecord record,
    required String title,
    required String confirmLabel,
    required Color confirmColor,
    required String prompt,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reasonController = TextEditingController();
    bool notifyFarmManager = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 620),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _modalHeader(
                  isDark: isDark,
                  title: title,
                  subtitle: '${record.id} | ${record.farm}',
                  color: confirmColor,
                  icon: Icons.assignment_turned_in_rounded,
                  onClose: () => Navigator.of(dialogContext).pop(),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prompt,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _textField(
                          isDark: isDark,
                          controller: reasonController,
                          label: 'Reason / Notes',
                          maxLines: 4,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.04)
                                : AppColors.neutral50,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: isDark ? Colors.white10 : AppColors.neutral200,
                            ),
                          ),
                          child: CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            title: Text(
                              'Notify farm manager',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? Colors.white70 : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            value: notifyFarmManager,
                            onChanged: (value) {
                              setDialogState(() => notifyFarmManager = value ?? true);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _modalActions(
                  isDark: isDark,
                  cancelLabel: 'Close',
                  confirmLabel: confirmLabel,
                  confirmColor: confirmColor,
                  onCancel: () => Navigator.of(dialogContext).pop(),
                  onConfirm: () {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$confirmLabel completed for ${record.id}'
                          '${notifyFarmManager ? ' (manager notified)' : ''}',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAssignDriverModal(_DeliveryRecord record) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final driverController = TextEditingController(text: record.driver);
    final vehicleController = TextEditingController(text: record.vehicle);
    final etaController = TextEditingController(text: record.eta);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _modalHeader(
                isDark: isDark,
                title: 'Assign Driver',
                subtitle: '${record.id} | ${record.destination}',
                color: AppColors.primary,
                icon: Icons.person_add_alt_1_rounded,
                onClose: () => Navigator.of(dialogContext).pop(),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      _textField(
                        isDark: isDark,
                        controller: driverController,
                        label: 'Driver Name',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _textField(
                        isDark: isDark,
                        controller: vehicleController,
                        label: 'Vehicle',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _textField(
                        isDark: isDark,
                        controller: etaController,
                        label: 'ETA (YYYY-MM-DD HH:mm)',
                      ),
                    ],
                  ),
                ),
              ),
              _modalActions(
                isDark: isDark,
                cancelLabel: 'Close',
                confirmLabel: 'Assign',
                confirmColor: AppColors.primary,
                onCancel: () => Navigator.of(dialogContext).pop(),
                onConfirm: () {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Driver assigned for ${record.id}')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeliveryDetailsModal(_DeliveryRecord record) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _modalHeader(
                isDark: isDark,
                title: 'Delivery Details',
                subtitle: '${record.id} | ${record.farm}',
                color: AppColors.info,
                icon: Icons.receipt_long_rounded,
                onClose: () => Navigator.of(dialogContext).pop(),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isDark ? Colors.white10 : AppColors.neutral200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _detailRow(isDark, 'Delivery ID', record.id),
                        _detailRow(isDark, 'Farm', record.farm),
                        _detailRow(isDark, 'Destination', record.destination),
                        _detailRow(
                            isDark, 'Crop', '${record.crop} (${record.quantity} ${record.unit})'),
                        _detailRow(isDark, 'Status', record.status.label),
                        _detailRow(isDark, 'Priority', record.priority.label),
                        _detailRow(isDark, 'Driver', record.driver),
                        _detailRow(isDark, 'Vehicle', record.vehicle),
                        _detailRow(isDark, 'Scheduled At', record.scheduledAt),
                        _detailRow(isDark, 'ETA', record.eta),
                      ],
                    ),
                  ),
                ),
              ),
              _modalActions(
                isDark: isDark,
                cancelLabel: 'Close',
                confirmLabel: 'Close',
                confirmColor: AppColors.primary,
                onCancel: () => Navigator.of(dialogContext).pop(),
                onConfirm: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white60 : AppColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : AppColors.neutral200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _modalHeader({
    required bool isDark,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onClose,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h6.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _modalActions({
    required bool isDark,
    required String cancelLabel,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                side: BorderSide(
                  color: isDark ? Colors.white24 : AppColors.neutral300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(
                cancelLabel,
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(confirmLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: RichText(
        text: TextSpan(
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActivityLog(bool isDark, List<_DeliveryActivity> activities) {
    if (activities.isEmpty) {
      return _buildEmptyState(
        isDark: isDark,
        icon: Icons.history_toggle_off,
        title: 'No delivery logs',
        subtitle: 'No activity records match current filters.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: activities.map((activity) => _buildActivityRow(isDark, activity)).toList(),
      ),
    );
  }

  Widget _buildActivityRow(bool isDark, _DeliveryActivity activity) {
    final color = _activityColor(activity.type);
    final icon = _activityIcon(activity.type);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activity.deliveryId}  |  ${activity.farm}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.message,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${activity.actor}  |  ${_dateFormat.format(activity.timestamp)}',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: isDark ? Colors.white54 : AppColors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _statusColor(_DeliveryStatus status) {
    switch (status) {
      case _DeliveryStatus.pendingApproval:
        return AppColors.warning;
      case _DeliveryStatus.scheduled:
        return AppColors.primary;
      case _DeliveryStatus.inTransit:
        return AppColors.info;
      case _DeliveryStatus.delivered:
        return AppColors.success;
      case _DeliveryStatus.onHold:
        return Colors.orange;
      case _DeliveryStatus.cancelled:
        return AppColors.error;
    }
  }

  Color _priorityColor(_DeliveryPriority priority) {
    switch (priority) {
      case _DeliveryPriority.high:
        return AppColors.error;
      case _DeliveryPriority.medium:
        return AppColors.warning;
      case _DeliveryPriority.low:
        return AppColors.success;
    }
  }

  Color _activityColor(_ActivityType type) {
    switch (type) {
      case _ActivityType.success:
        return AppColors.success;
      case _ActivityType.warning:
        return AppColors.warning;
      case _ActivityType.error:
        return AppColors.error;
      case _ActivityType.info:
        return AppColors.info;
    }
  }

  IconData _activityIcon(_ActivityType type) {
    switch (type) {
      case _ActivityType.success:
        return Icons.check_circle;
      case _ActivityType.warning:
        return Icons.warning;
      case _ActivityType.error:
        return Icons.error;
      case _ActivityType.info:
        return Icons.info;
    }
  }

  List<_DeliveryRecord> _filteredDeliveries() {
    final query = _searchController.text.trim().toLowerCase();
    return _deliveries.where((record) {
      if (_selectedFarm != 'All Farms' && record.farm != _selectedFarm) {
        return false;
      }
      if (_selectedStatus != 'All' && record.status.label != _selectedStatus) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return record.id.toLowerCase().contains(query) ||
          record.destination.toLowerCase().contains(query) ||
          record.crop.toLowerCase().contains(query) ||
          record.driver.toLowerCase().contains(query);
    }).toList();
  }

  List<_DeliveryActivity> _filteredActivities() {
    final query = _searchController.text.trim().toLowerCase();
    final sorted = [..._activities]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.where((activity) {
      if (_selectedFarm != 'All Farms' && activity.farm != _selectedFarm) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return activity.deliveryId.toLowerCase().contains(query) ||
          activity.message.toLowerCase().contains(query) ||
          activity.actor.toLowerCase().contains(query);
    }).toList();
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatData(this.label, this.value, this.icon, this.color);
}

enum _DeliveryStatus {
  pendingApproval('Pending Approval'),
  scheduled('Scheduled'),
  inTransit('In Transit'),
  delivered('Delivered'),
  onHold('On Hold'),
  cancelled('Cancelled');

  final String label;
  const _DeliveryStatus(this.label);
}

enum _DeliveryPriority {
  high('High'),
  medium('Medium'),
  low('Low');

  final String label;
  const _DeliveryPriority(this.label);
}

class _DeliveryRecord {
  final String id;
  final String farm;
  final String destination;
  final String crop;
  final int quantity;
  final String unit;
  final _DeliveryStatus status;
  final _DeliveryPriority priority;
  final String driver;
  final String vehicle;
  final String scheduledAt;
  final String eta;

  const _DeliveryRecord({
    required this.id,
    required this.farm,
    required this.destination,
    required this.crop,
    required this.quantity,
    required this.unit,
    required this.status,
    required this.priority,
    required this.driver,
    required this.vehicle,
    required this.scheduledAt,
    required this.eta,
  });
}

enum _ActivityType { success, warning, error, info }

enum _DeliveryAction {
  approve,
  reject,
  assignDriver,
  putOnHold,
  cancel,
  viewDetails,
}

class _DeliveryActivity {
  final String id;
  final String deliveryId;
  final String farm;
  final String message;
  final String actor;
  final DateTime timestamp;
  final _ActivityType type;

  const _DeliveryActivity({
    required this.id,
    required this.deliveryId,
    required this.farm,
    required this.message,
    required this.actor,
    required this.timestamp,
    required this.type,
  });
}
