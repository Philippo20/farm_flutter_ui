import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../services/superadmin_api_service.dart';

class OverallDeliveryControlModule extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isMobile;
  final bool allowCreateDelivery;

  const OverallDeliveryControlModule({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isMobile,
    this.allowCreateDelivery = false,
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
  final SuperAdminApiService _api = SuperAdminApiService();

  final List<String> _farms = ['All Farms'];
  final List<Map<String, dynamic>> _farmDocuments = [];
  final List<Map<String, dynamic>> _batchDocuments = [];
  final List<Map<String, dynamic>> _userDocuments = [];
  final List<_DeliveryRecord> _deliveries = [];
  final List<_DeliveryActivity> _activities = [];
  bool _isLoadingDeliveries = true;
  String? _deliveryError;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    setState(() {
      _isLoadingDeliveries = true;
      _deliveryError = null;
    });
    try {
      final results = await Future.wait([
        _api.getFulfillments(),
        _api.getFarms(),
        _api.getBatches(),
        _api.getUsers(),
        _api.getAudits(),
      ]);
      if (!mounted) return;
      final fulfillments = results[0];
      final farmsResponse = results[1];
      final batches = results[2];
      final users = results[3];
      final audits = results[4];
      final deliveries = fulfillments.map(_mapFulfillmentDocument).toList();
      final farms = {
        ...farmsResponse.map(_farmNameFromDocument),
        ...deliveries.map((delivery) => delivery.farm),
      }.where((farm) => farm.trim().isNotEmpty).toList()
        ..sort();
      final activities = audits
          .where((audit) => _auditIsDeliveryRelated(audit))
          .map(_mapAuditDocument)
          .toList();
      final nextSelectedFarm =
          farms.contains(_selectedFarm) ? _selectedFarm : 'All Farms';
      setState(() {
        _deliveries
          ..clear()
          ..addAll(deliveries);
        _activities
          ..clear()
          ..addAll(activities);
        _farmDocuments
          ..clear()
          ..addAll(farmsResponse);
        _batchDocuments
          ..clear()
          ..addAll(batches);
        _userDocuments
          ..clear()
          ..addAll(users);
        _farms
          ..clear()
          ..add('All Farms')
          ..addAll(farms);
        _selectedFarm = nextSelectedFarm;
        _isLoadingDeliveries = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _deliveries.clear();
        _activities.clear();
        _farmDocuments.clear();
        _batchDocuments.clear();
        _userDocuments.clear();
        _farms
          ..clear()
          ..add('All Farms');
        _isLoadingDeliveries = false;
        _deliveryError = error.toString();
      });
    }
  }

  _DeliveryRecord _mapFulfillmentDocument(Map<String, dynamic> doc) {
    return _DeliveryRecord(
      id: (doc[r'$id'] ?? doc['fulfillment_id'] ?? '').toString(),
      farm: (doc['farm_name'] ?? 'Unassigned Farm').toString(),
      destination: (doc['destination'] ??
              (doc['sent_to_sales'] == true ? 'Sales Hub' : 'Fulfillment'))
          .toString(),
      crop: (doc['plant_type'] ?? 'Crop').toString(),
      quantity: _toInt(doc['total_heads'] ?? doc['total_weight']),
      unit: doc['total_heads'] != null ? 'heads' : 'kg',
      status: _deliveryStatus(doc['delivery_status'] ?? doc['status']),
      priority: _deliveryPriority(doc['priority']),
      driver: (doc['driver_name'] ?? 'Unassigned').toString(),
      vehicle: (doc['vehicle'] ?? 'Pending').toString(),
      scheduledAt: _dateLabel(doc['packaging_date_time']),
      eta: (doc['eta']?.toString().trim().isNotEmpty ?? false)
          ? doc['eta'].toString()
          : _dateLabel(doc['sent_to_sales_date_time']),
      raw: Map<String, dynamic>.from(doc),
    );
  }

  String _farmNameFromDocument(Map<String, dynamic> farm) {
    return (farm['name'] ?? farm['farm_name'] ?? 'Unassigned Farm').toString();
  }

  String _documentId(Map<String, dynamic> doc) {
    return (doc[r'$id'] ?? doc['id'] ?? '').toString();
  }

  Map<String, dynamic>? _farmByName(String farmName) {
    for (final farm in _farmDocuments) {
      if (_farmNameFromDocument(farm) == farmName) return farm;
    }
    return null;
  }

  List<String> _plantOptionsForFarm(String farmName) {
    final values = <String>{};
    final farm = _farmByName(farmName);
    if (farm != null) {
      for (final key in ['plant_type', 'plant_variety']) {
        final raw = farm[key]?.toString() ?? '';
        for (final item in raw.split(',')) {
          final value = item.trim();
          if (value.isNotEmpty && value.toLowerCase() != 'none') {
            values.add(value);
          }
        }
      }
    }
    for (final batch in _batchDocuments.where((batch) {
      return _batchMatchesFarm(batch, farmName);
    })) {
      final plant = (batch['plant_name'] ?? '').toString().trim();
      if (plant.isNotEmpty) values.add(plant);
    }
    return values.toList()..sort();
  }

  bool _batchMatchesFarm(Map<String, dynamic> batch, String farmName) {
    final farm = _farmByName(farmName);
    final farmId = farm == null ? '' : _documentId(farm);
    final batchFarmId = (batch['farmID'] ?? batch['farm_id'] ?? '').toString();
    final batchFarmName = (batch['farm_name'] ?? '').toString();
    return batchFarmName == farmName ||
        (farmId.isNotEmpty && batchFarmId == farmId);
  }

  bool _batchMatchesPlant(Map<String, dynamic> batch, String plant) {
    final target = plant.toLowerCase();
    return (batch['plant_name'] ?? '').toString().toLowerCase() == target ||
        (batch['plant_type_ID'] ?? '').toString().toLowerCase() == target;
  }

  bool _batchIsAvailableForDelivery(Map<String, dynamic> batch) {
    final production =
        (batch['production_status'] ?? '').toString().toLowerCase();
    final delivery = (batch['delivery_status'] ?? '').toString().toLowerCase();
    final batchNo = (batch['batch_no'] ?? '').toString();
    final alreadyInDelivery = _deliveries.any((deliveryRecord) {
      return (deliveryRecord.raw['batch_number'] ?? '').toString() == batchNo &&
          deliveryRecord.status != _DeliveryStatus.cancelled &&
          deliveryRecord.status != _DeliveryStatus.delivered;
    });
    if (alreadyInDelivery) return false;
    final harvested = production.contains('harvested') ||
        production.contains('delivered') ||
        production.contains('completed') ||
        _toInt(batch['total_harvested']) > 0 ||
        _toDouble(batch['total_weight_kg']) > 0;
    final notCompletedDelivery =
        !delivery.contains('delivered') && !delivery.contains('completed');
    return harvested && notCompletedDelivery && batchNo.trim().isNotEmpty;
  }

  List<Map<String, dynamic>> _batchOptionsForFarmAndPlant(
    String farmName,
    String plant,
  ) {
    return _batchDocuments.where((batch) {
      return _batchMatchesFarm(batch, farmName) &&
          _batchMatchesPlant(batch, plant) &&
          _batchIsAvailableForDelivery(batch);
    }).toList()
      ..sort((a, b) => (a['batch_no'] ?? '')
          .toString()
          .compareTo((b['batch_no'] ?? '').toString()));
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _batchLabel(Map<String, dynamic> batch) {
    final batchNo = (batch['batch_no'] ?? 'Batch').toString();
    final weight = _toDouble(batch['total_weight_kg']);
    final heads = _toInt(batch['total_harvested']);
    if (weight > 0) return '$batchNo - ${weight.toStringAsFixed(1)} kg';
    if (heads > 0) return '$batchNo - $heads heads';
    return batchNo;
  }

  bool _isActiveDriverUser(Map<String, dynamic> user) {
    final role = (user['role'] ?? '').toString().toLowerCase();
    final department = (user['department'] ?? '').toString().toLowerCase();
    final status = (user['status'] ?? 'Active').toString().toLowerCase();
    final driverTagged = role == 'driver' ||
        role.contains('driver') ||
        department.contains('driver') ||
        department.contains('logistics') ||
        department.contains('delivery') ||
        department.contains('transport');
    return driverTagged && status == 'active';
  }

  List<Map<String, dynamic>> _driverUsers() {
    return _userDocuments.where(_isActiveDriverUser).toList()
      ..sort((a, b) =>
          (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
  }

  String _userId(Map<String, dynamic> user) {
    return (user[r'$id'] ?? user['user_id'] ?? user['id'] ?? '').toString();
  }

  String _driverLabel(Map<String, dynamic> user) {
    final name = (user['name'] ?? 'Driver').toString();
    final phone = (user['phone'] ?? '').toString();
    return phone.trim().isEmpty ? name : '$name - $phone';
  }

  Map<String, dynamic>? _driverById(String id) {
    for (final user in _driverUsers()) {
      if (_userId(user) == id) return user;
    }
    return null;
  }

  List<String> _vehicleOptionsForDriver(Map<String, dynamic>? driver) {
    final values = <String>{};
    if (driver != null) {
      for (final key in [
        'vehicle',
        'vehicle_number',
        'vehicle_no',
        'assigned_vehicle',
        'driver_vehicle',
        'plate_number',
      ]) {
        final value = (driver[key] ?? '').toString().trim();
        if (value.isNotEmpty) values.add(value);
      }
    }
    if (values.isEmpty) values.add('Pending assignment');
    return values.toList()..sort();
  }

  _DeliveryStatus _deliveryStatus(dynamic value) {
    final text = value?.toString().toLowerCase() ?? '';
    if (text.contains('completed')) return _DeliveryStatus.delivered;
    if (text.contains('delivered')) return _DeliveryStatus.delivered;
    if (text.contains('cancel')) return _DeliveryStatus.cancelled;
    if (text.contains('reject')) return _DeliveryStatus.cancelled;
    if (text.contains('hold')) return _DeliveryStatus.onHold;
    if (text.contains('transit')) return _DeliveryStatus.inTransit;
    if (text.contains('scheduled')) return _DeliveryStatus.scheduled;
    if (text.contains('sent')) return _DeliveryStatus.inTransit;
    if (text.contains('packaged')) return _DeliveryStatus.scheduled;
    if (text.contains('packaging')) return _DeliveryStatus.onHold;
    return _DeliveryStatus.pendingApproval;
  }

  _DeliveryPriority _deliveryPriority(dynamic value) {
    final text = value?.toString().toLowerCase() ?? '';
    if (text.contains('high')) return _DeliveryPriority.high;
    if (text.contains('low')) return _DeliveryPriority.low;
    return _DeliveryPriority.medium;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _dateLabel(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.length >= 16) return text.substring(0, 16).replaceFirst('T', ' ');
    return text.isEmpty ? '-' : text;
  }

  String? _dateOnly(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.trim().isEmpty) return null;
    return text.split('T').first.split(' ').first;
  }

  String _todayDate() => DateTime.now().toIso8601String().split('T').first;

  bool _auditIsDeliveryRelated(Map<String, dynamic> audit) {
    final collection =
        (audit['collection_name'] ?? '').toString().toLowerCase();
    final details = (audit['action_details'] ?? '').toString().toLowerCase();
    return collection.contains('fulfillment') ||
        collection.contains('delivery') ||
        details.contains('fulfillment') ||
        details.contains('delivery');
  }

  _DeliveryActivity _mapAuditDocument(Map<String, dynamic> audit) {
    final action = (audit['action_type'] ?? 'Info').toString();
    return _DeliveryActivity(
      id: (audit[r'$id'] ?? audit['audit_id'] ?? '').toString(),
      deliveryId: (audit['collection_name'] ?? 'Fulfillment').toString(),
      farm: 'All Farms',
      message: (audit['action_details'] ?? action).toString(),
      actor: (audit['performed_by_id'] ?? 'System').toString(),
      timestamp: DateTime.tryParse((audit['timestamp'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      type: action.toLowerCase().contains('delete') ||
              action.toLowerCase().contains('reject') ||
              action.toLowerCase().contains('cancel')
          ? _ActivityType.error
          : action.toLowerCase().contains('update')
              ? _ActivityType.warning
              : _ActivityType.success,
    );
  }

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
        if (_deliveryError != null) ...[
          _buildSyncStatus(isDark),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (_isLoadingDeliveries)
          const AdminDataSkeleton(rowCount: 5)
        else ...[
          _buildStats(isDark, _deliveries),
          const SizedBox(height: AppSpacing.lg),
          _buildFarmDeliveryOverview(isDark),
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
      ],
    );
  }

  Widget _buildSyncStatus(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _deliveryError ?? 'Unable to load delivery records.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _loadDeliveries,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final activeDeliveries = _deliveries
        .where((record) =>
            record.status != _DeliveryStatus.delivered &&
            record.status != _DeliveryStatus.cancelled)
        .length;
    final farmsCovered =
        _deliveries.map((record) => record.farm).toSet().length;

    return Container(
      padding: EdgeInsets.all(widget.isMobile ? AppSpacing.lg : AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.info.withOpacity(0.28),
                  AppColors.surfaceDark,
                  AppColors.backgroundDark,
                ]
              : [
                  AppColors.info.withOpacity(0.12),
                  Colors.white,
                  AppColors.neutral50,
                ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.info.withOpacity(0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.06),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: widget.isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCopy(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildHeroMetrics(isDark, activeDeliveries, farmsCovered),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildHeaderCopy(isDark)),
                const SizedBox(width: AppSpacing.xl),
                _buildHeroMetrics(isDark, activeDeliveries, farmsCovered),
              ],
            ),
    );
  }

  Widget _buildHeaderCopy(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.info.withOpacity(0.2)),
          ),
          child: const Icon(
            Icons.local_shipping_rounded,
            color: AppColors.info,
            size: 28,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: AppTypography.bodyMedium.copyWith(
                  height: 1.45,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              if (widget.allowCreateDelivery) ...[
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isLoadingDeliveries ? null : _showCreateDeliveryModal,
                    icon: const Icon(Icons.add_road_rounded, size: 18),
                    label: const Text('Create Delivery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroMetrics(
      bool isDark, int activeDeliveries, int farmsCovered) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _heroMetric(
          isDark: isDark,
          label: 'Active deliveries',
          value: '$activeDeliveries',
          icon: Icons.route_rounded,
          color: AppColors.info,
        ),
        _heroMetric(
          isDark: isDark,
          label: 'Farms covered',
          value: '$farmsCovered',
          icon: Icons.agriculture_rounded,
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _heroMetric({
    required bool isDark,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: widget.isMobile ? double.infinity : 170,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
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

  Widget _buildStats(bool isDark, List<_DeliveryRecord> records) {
    final total = records.length;
    final pendingApproval = records
        .where((record) => record.status == _DeliveryStatus.pendingApproval)
        .length;
    final inTransit = records
        .where((record) => record.status == _DeliveryStatus.inTransit)
        .length;
    final delivered = records
        .where((record) => record.status == _DeliveryStatus.delivered)
        .length;

    final cards = [
      _StatData(
          'Deliveries', '$total', Icons.local_shipping, AppColors.primary),
      _StatData('Pending Approval', '$pendingApproval', Icons.approval,
          AppColors.warning),
      _StatData('In Transit', '$inTransit', Icons.route, AppColors.info),
      _StatData(
          'Delivered', '$delivered', Icons.check_circle, AppColors.success),
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
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color:
                      isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: card.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(card.icon, color: card.color, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.value,
                          style: AppTypography.h6.copyWith(
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card.label,
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? Colors.white60
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
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

  Widget _buildFarmDeliveryOverview(bool isDark) {
    final summaries = _farmSummaries();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.agriculture_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Farm Delivery Operations',
                      style: AppTypography.h6.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select a farm to inspect delivery load, pending approvals, active routes, and completed drops.',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.isMobile)
                TextButton.icon(
                  onPressed: () => setState(() => _selectedFarm = 'All Farms'),
                  icon: const Icon(Icons.public_rounded, size: 18),
                  label: const Text('Global View'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = widget.isMobile ? 1 : (width > 1000 ? 4 : 2);
              final gap = AppSpacing.md;
              final cardWidth = columns == 1
                  ? width
                  : (width - (gap * (columns - 1))) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: summaries
                    .map(
                      (summary) => SizedBox(
                        width: cardWidth,
                        child: _buildFarmDeliveryCard(summary, isDark),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFarmDeliveryCard(_FarmDeliverySummary summary, bool isDark) {
    final isSelected = _selectedFarm == summary.farm;
    final riskColor = summary.onHold > 0
        ? AppColors.error
        : summary.pendingApproval > 0
            ? AppColors.warning
            : AppColors.success;

    return InkWell(
      onTap: () => setState(() => _selectedFarm = summary.farm),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.info.withOpacity(isDark ? 0.2 : 0.09)
              : (isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected
                ? AppColors.info.withOpacity(0.55)
                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.farm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected
                      ? AppColors.info
                      : (isDark ? Colors.white38 : AppColors.textSecondary),
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                    child: _farmMetric(isDark, 'Total', '${summary.total}',
                        AppColors.primary)),
                Expanded(
                    child: _farmMetric(
                        isDark, 'Active', '${summary.active}', AppColors.info)),
                Expanded(
                    child: _farmMetric(isDark, 'Done', '${summary.delivered}',
                        AppColors.success)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: riskColor),
                  const SizedBox(width: 6),
                  Text(
                    summary.onHold > 0
                        ? '${summary.onHold} on hold'
                        : summary.pendingApproval > 0
                            ? '${summary.pendingApproval} approval pending'
                            : 'Operations normal',
                    style: AppTypography.caption.copyWith(
                      color: riskColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _farmMetric(bool isDark, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isDark ? Colors.white54 : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedFarm == 'All Farms'
                      ? 'Global Delivery Records'
                      : '$_selectedFarm Delivery Records',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              if (_selectedFarm != 'All Farms')
                TextButton.icon(
                  onPressed: () => setState(() => _selectedFarm = 'All Farms'),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Clear Farm'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
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
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : AppColors.neutral100,
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
        hintStyle:
            TextStyle(color: isDark ? Colors.white38 : AppColors.textSecondary),
        prefixIcon: Icon(Icons.search,
            color: isDark ? Colors.white54 : AppColors.textSecondary),
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide:
              BorderSide(color: isDark ? Colors.white12 : AppColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide:
              BorderSide(color: isDark ? Colors.white12 : AppColors.neutral200),
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
        border:
            Border.all(color: isDark ? Colors.white12 : AppColors.neutral200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFarm,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down,
              color: isDark ? Colors.white54 : AppColors.textSecondary),
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          style:
              TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabItem(
              isDark: isDark,
              label: 'Control',
              icon: Icons.local_shipping_rounded,
              index: 0,
            ),
            const SizedBox(width: 4),
            _buildTabItem(
              isDark: isDark,
              label: 'Logs',
              icon: Icons.history_rounded,
              index: 1,
            ),
          ],
        ),
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
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? AppColors.primary
                  : (isDark ? Colors.white70 : AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? AppColors.primary
                      : (isDark ? Colors.white70 : AppColors.textSecondary),
                ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Control Center',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...records.map((record) => _buildDeliveryCard(isDark, record)),
        ],
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
                child: const Icon(Icons.local_shipping,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${record.id}  |  ${record.farm}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${record.crop}  |  ${record.quantity} ${record.unit}  |  ${record.destination}',
                      style: AppTypography.caption.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
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
          onPressed: () => _openActionModal(
              action: _DeliveryAction.putOnHold, record: record),
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
        onPressed: () => _openActionModal(
            action: _DeliveryAction.viewDetails, record: record),
      ),
    );
    actions.add(
      _actionButton(
        isDark: isDark,
        label: 'Delete',
        icon: Icons.delete_outline_rounded,
        color: AppColors.error,
        onPressed: () =>
            _openActionModal(action: _DeliveryAction.delete, record: record),
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
            fontWeight: FontWeight.w500,
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
      case _DeliveryAction.delete:
        _showDeleteDeliveryModal(record);
        break;
    }
  }

  void _showCreateDeliveryModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quantityController = TextEditingController();
    final unitController = TextEditingController(text: 'kg');
    final destinationController = TextEditingController(text: 'Sales Hub');
    final scheduledController = TextEditingController(text: _todayDate());
    final etaController = TextEditingController(text: _todayDate());
    final noteController = TextEditingController();
    final driverOptions = _driverUsers();
    String selectedDriverId =
        driverOptions.isNotEmpty ? _userId(driverOptions.first) : '';
    var vehicleOptions =
        _vehicleOptionsForDriver(_driverById(selectedDriverId));
    String selectedVehicle =
        vehicleOptions.isNotEmpty ? vehicleOptions.first : 'Pending assignment';
    final availableFarms = _farms.where((farm) => farm != 'All Farms').toList()
      ..sort();
    String selectedFarm =
        availableFarms.isNotEmpty ? availableFarms.first : 'Unassigned Farm';
    var plantOptions = _plantOptionsForFarm(selectedFarm);
    String selectedPlant = plantOptions.isNotEmpty ? plantOptions.first : '';
    var batchOptions = _batchOptionsForFarmAndPlant(
      selectedFarm,
      selectedPlant,
    );
    String selectedBatchNo = batchOptions.isNotEmpty
        ? (batchOptions.first['batch_no'] ?? '').toString()
        : '';
    String selectedPriority = 'Medium';
    bool isSaving = false;
    String? formError;

    Map<String, dynamic>? selectedBatchByNo() {
      for (final batch in batchOptions) {
        if ((batch['batch_no'] ?? '').toString() == selectedBatchNo) {
          return batch;
        }
      }
      return null;
    }

    void applySelectedBatchToFields() {
      final selectedBatch = selectedBatchByNo();
      if (selectedBatch == null) {
        quantityController.clear();
        unitController.text = 'kg';
        scheduledController.text = _todayDate();
        return;
      }
      final weight = _toDouble(selectedBatch['total_weight_kg']);
      final heads = _toInt(selectedBatch['total_harvested']);
      if (weight > 0) {
        quantityController.text = weight.toStringAsFixed(1);
        unitController.text = 'kg';
      } else {
        quantityController.text = heads.toString();
        unitController.text = 'heads';
      }
      scheduledController.text =
          _dateOnly(selectedBatch['actual_harvest_date']) ?? _todayDate();
    }

    applySelectedBatchToFields();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720),
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
                  title: 'Create Delivery',
                  subtitle: 'Create a delivery control record in Appwrite',
                  color: AppColors.info,
                  icon: Icons.add_road_rounded,
                  onClose: isSaving
                      ? () {}
                      : () => Navigator.of(dialogContext).pop(),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        if (formError != null) ...[
                          _modalError(isDark, formError!),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        DropdownButtonFormField<String>(
                          key: ValueKey('delivery-farm-$selectedFarm'),
                          initialValue: selectedFarm,
                          dropdownColor:
                              isDark ? AppColors.surfaceDark : Colors.white,
                          decoration: _inputDecoration(isDark, 'Farm'),
                          items: [
                            if (availableFarms.isEmpty)
                              const DropdownMenuItem(
                                value: 'Unassigned Farm',
                                child: Text('Unassigned Farm'),
                              ),
                            ...availableFarms.map(
                              (farm) => DropdownMenuItem(
                                value: farm,
                                child: Text(farm),
                              ),
                            ),
                          ],
                          onChanged: isSaving
                              ? null
                              : (value) => setDialogState(() {
                                    selectedFarm = value ?? 'Unassigned Farm';
                                    plantOptions =
                                        _plantOptionsForFarm(selectedFarm);
                                    selectedPlant = plantOptions.isNotEmpty
                                        ? plantOptions.first
                                        : '';
                                    batchOptions = _batchOptionsForFarmAndPlant(
                                      selectedFarm,
                                      selectedPlant,
                                    );
                                    selectedBatchNo = batchOptions.isNotEmpty
                                        ? (batchOptions.first['batch_no'] ?? '')
                                            .toString()
                                        : '';
                                    formError = null;
                                    applySelectedBatchToFields();
                                  }),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                              'delivery-plant-$selectedFarm-$selectedPlant'),
                          initialValue:
                              selectedPlant.isEmpty ? null : selectedPlant,
                          dropdownColor:
                              isDark ? AppColors.surfaceDark : Colors.white,
                          decoration:
                              _inputDecoration(isDark, 'Product Produced'),
                          items: plantOptions
                              .map(
                                (plant) => DropdownMenuItem(
                                  value: plant,
                                  child: Text(plant),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) => setDialogState(() {
                                    selectedPlant = value ?? '';
                                    batchOptions = _batchOptionsForFarmAndPlant(
                                      selectedFarm,
                                      selectedPlant,
                                    );
                                    selectedBatchNo = batchOptions.isNotEmpty
                                        ? (batchOptions.first['batch_no'] ?? '')
                                            .toString()
                                        : '';
                                    formError = null;
                                    applySelectedBatchToFields();
                                  }),
                        ),
                        if (plantOptions.isEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          _modalHint(
                            isDark,
                            'This farm has no product configured yet. Add plant data to the farm before creating a delivery.',
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                              'delivery-batch-$selectedFarm-$selectedPlant-$selectedBatchNo'),
                          initialValue:
                              selectedBatchNo.isEmpty ? null : selectedBatchNo,
                          dropdownColor:
                              isDark ? AppColors.surfaceDark : Colors.white,
                          decoration: _inputDecoration(
                              isDark, 'Available Batch at Hub'),
                          items: batchOptions
                              .map(
                                (batch) => DropdownMenuItem(
                                  value: (batch['batch_no'] ?? '').toString(),
                                  child: Text(_batchLabel(batch)),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) => setDialogState(() {
                                    selectedBatchNo = value ?? '';
                                    formError = null;
                                    applySelectedBatchToFields();
                                  }),
                        ),
                        if (batchOptions.isEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          _modalHint(
                            isDark,
                            'No harvested, undelivered batch is available for this farm and product.',
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                isDark: isDark,
                                controller: quantityController,
                                label: 'Quantity',
                                keyboardType: TextInputType.number,
                                readOnly: true,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _textField(
                                isDark: isDark,
                                controller: unitController,
                                label: 'Unit',
                                readOnly: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _textField(
                          isDark: isDark,
                          controller: destinationController,
                          label: 'Destination',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          key: ValueKey('delivery-driver-$selectedDriverId'),
                          initialValue: selectedDriverId.isEmpty
                              ? null
                              : selectedDriverId,
                          dropdownColor:
                              isDark ? AppColors.surfaceDark : Colors.white,
                          decoration: _inputDecoration(isDark, 'Driver'),
                          items: driverOptions
                              .map(
                                (driver) => DropdownMenuItem(
                                  value: _userId(driver),
                                  child: Text(_driverLabel(driver)),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) => setDialogState(() {
                                    selectedDriverId = value ?? '';
                                    vehicleOptions = _vehicleOptionsForDriver(
                                      _driverById(selectedDriverId),
                                    );
                                    selectedVehicle = vehicleOptions.isNotEmpty
                                        ? vehicleOptions.first
                                        : 'Pending assignment';
                                    formError = null;
                                  }),
                        ),
                        if (driverOptions.isEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          _modalHint(
                            isDark,
                            'No active driver users found. Create an active Driver user before assigning delivery.',
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                              'delivery-vehicle-$selectedDriverId-$selectedVehicle'),
                          initialValue: selectedVehicle,
                          dropdownColor:
                              isDark ? AppColors.surfaceDark : Colors.white,
                          decoration: _inputDecoration(isDark, 'Vehicle'),
                          items: vehicleOptions
                              .map(
                                (vehicle) => DropdownMenuItem(
                                  value: vehicle,
                                  child: Text(vehicle),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) => setDialogState(() {
                                    selectedVehicle =
                                        value ?? 'Pending assignment';
                                    formError = null;
                                  }),
                        ),
                        if (selectedVehicle == 'Pending assignment') ...[
                          const SizedBox(height: AppSpacing.xs),
                          _modalHint(
                            isDark,
                            'This driver has no vehicle saved on the user record yet.',
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                isDark: isDark,
                                controller: scheduledController,
                                label: 'Scheduled Date',
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _textField(
                                isDark: isDark,
                                controller: etaController,
                                label: 'ETA',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          initialValue: selectedPriority,
                          dropdownColor:
                              isDark ? AppColors.surfaceDark : Colors.white,
                          decoration: _inputDecoration(isDark, 'Priority'),
                          items: ['High', 'Medium', 'Low']
                              .map(
                                (priority) => DropdownMenuItem(
                                  value: priority,
                                  child: Text(priority),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) => setDialogState(
                                    () => selectedPriority = value ?? 'Medium',
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _textField(
                          isDark: isDark,
                          controller: noteController,
                          label: 'Delivery Note',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                _modalActions(
                  isDark: isDark,
                  cancelLabel: 'Cancel',
                  confirmLabel: isSaving ? 'Creating...' : 'Create Delivery',
                  confirmColor: AppColors.info,
                  onCancel: isSaving
                      ? () {}
                      : () => Navigator.of(dialogContext).pop(),
                  onConfirm: isSaving
                      ? () {}
                      : () async {
                          final unit = unitController.text.trim();
                          final quantity =
                              double.tryParse(quantityController.text.trim());
                          final selectedBatch = selectedBatchByNo();
                          if (selectedFarm == 'Unassigned Farm' ||
                              selectedPlant.isEmpty ||
                              selectedBatch == null ||
                              selectedDriverId.isEmpty ||
                              unit.isEmpty) {
                            setDialogState(() => formError =
                                'Select a farm, product, available hub batch, and active driver before creating a delivery.');
                            return;
                          }
                          if (quantity == null || quantity <= 0) {
                            setDialogState(() => formError =
                                'Quantity must be a valid number greater than zero.');
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            formError = null;
                          });
                          final navigator = Navigator.of(dialogContext);
                          final messenger = ScaffoldMessenger.of(context);
                          final isHeads = unit.toLowerCase().contains('head');
                          final selectedDriver = _driverById(selectedDriverId);
                          try {
                            await _api.createFulfillment(
                              data: {
                                'batch_number': selectedBatchNo,
                                'farm_manager_id':
                                    selectedBatch['farm_manager_id'] ??
                                        'superadmin',
                                'farm_name': selectedFarm,
                                'plant_type': selectedPlant,
                                'total_heads': isHeads ? quantity : 0,
                                'total_weight': isHeads ? 0 : quantity,
                                'harvest_received_images':
                                    selectedBatch['harvest_images'] ?? '',
                                'packaging_supervisor_id':
                                    selectedBatch['created_by'] ?? 'superadmin',
                                'packaging_type': 'Delivery',
                                'packaging_weight': 0,
                                'total_packaged_weight': isHeads ? 0 : quantity,
                                'packaging_waste_type': 'None',
                                'packaging_waste_weight': 0,
                                'packaging_images': '',
                                'yield_loss_percentage': 0,
                                'received_date_time': _dateOnly(
                                        selectedBatch['actual_harvest_date']) ??
                                    _todayDate(),
                                'packaging_date_time':
                                    scheduledController.text.trim(),
                                'sent_to_sales': false,
                                'sent_to_sales_date_time':
                                    etaController.text.trim(),
                                'status': 'Packaged',
                                'delivery_status': 'Scheduled',
                                'driver_name':
                                    (selectedDriver?['name'] ?? 'Unassigned')
                                        .toString(),
                                'vehicle': selectedVehicle,
                                'destination':
                                    destinationController.text.trim(),
                                'eta': etaController.text.trim(),
                                'priority': selectedPriority,
                                'delivery_note': noteController.text.trim(),
                              },
                            );
                            if (!mounted) return;
                            navigator.pop();
                            await _loadDeliveries();
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Delivery created for $selectedBatchNo'),
                              ),
                            );
                          } catch (error) {
                            if (!mounted) return;
                            setDialogState(() {
                              isSaving = false;
                              formError = error.toString();
                            });
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _backendFulfillmentStatus(_DeliveryStatus status) {
    switch (status) {
      case _DeliveryStatus.scheduled:
        return 'Packaged';
      case _DeliveryStatus.inTransit:
        return 'Sent to Sales';
      case _DeliveryStatus.delivered:
        return 'Completed';
      case _DeliveryStatus.onHold:
        return 'Packaging';
      case _DeliveryStatus.pendingApproval:
      case _DeliveryStatus.cancelled:
        return 'Received';
    }
  }

  Future<void> _updateDelivery({
    required _DeliveryRecord record,
    required _DeliveryStatus status,
    String? driver,
    String? vehicle,
    String? eta,
    String? note,
  }) async {
    final data = Map<String, dynamic>.from(record.raw);
    data['delivery_status'] = status.label;
    data['status'] = _backendFulfillmentStatus(status);
    data['driver_name'] = driver ?? record.driver;
    data['vehicle'] = vehicle ?? record.vehicle;
    data['eta'] = eta ?? record.eta;
    data['priority'] = record.priority.label;
    data['destination'] = record.destination;
    if (note != null) data['delivery_note'] = note;
    data['sent_to_sales'] = status == _DeliveryStatus.inTransit ||
        status == _DeliveryStatus.delivered;
    if (status == _DeliveryStatus.inTransit ||
        status == _DeliveryStatus.delivered) {
      data['sent_to_sales_date_time'] =
          DateTime.now().toIso8601String().split('T').first;
    }

    await _api.updateFulfillment(id: record.id, data: data);
    await _loadDeliveries();
  }

  _DeliveryStatus _statusForAction(_DeliveryAction action) {
    switch (action) {
      case _DeliveryAction.approve:
        return _DeliveryStatus.scheduled;
      case _DeliveryAction.reject:
      case _DeliveryAction.cancel:
        return _DeliveryStatus.cancelled;
      case _DeliveryAction.putOnHold:
        return _DeliveryStatus.onHold;
      case _DeliveryAction.assignDriver:
        return _DeliveryStatus.scheduled;
      case _DeliveryAction.viewDetails:
      case _DeliveryAction.delete:
        return _DeliveryStatus.pendingApproval;
    }
  }

  void _showDeleteDeliveryModal(_DeliveryRecord record) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isDeleting = false;
    String? formError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
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
                  title: 'Delete Delivery',
                  subtitle: '${record.id} | ${record.farm}',
                  color: AppColors.error,
                  icon: Icons.delete_outline_rounded,
                  onClose: isDeleting
                      ? () {}
                      : () => Navigator.of(dialogContext).pop(),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (formError != null) ...[
                        _modalError(isDark, formError!),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Text(
                        'This will remove the delivery record from the backend. Audit history will remain available.',
                        style: AppTypography.bodyMedium.copyWith(
                          color:
                              isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _detailRow(isDark, 'Crop',
                          '${record.crop} (${record.quantity} ${record.unit})'),
                      _detailRow(isDark, 'Destination', record.destination),
                      _detailRow(isDark, 'Status', record.status.label),
                    ],
                  ),
                ),
                _modalActions(
                  isDark: isDark,
                  cancelLabel: 'Cancel',
                  confirmLabel: isDeleting ? 'Deleting...' : 'Delete',
                  confirmColor: AppColors.error,
                  onCancel: isDeleting
                      ? () {}
                      : () => Navigator.of(dialogContext).pop(),
                  onConfirm: isDeleting
                      ? () {}
                      : () async {
                          setDialogState(() {
                            isDeleting = true;
                            formError = null;
                          });
                          final navigator = Navigator.of(dialogContext);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await _api.deleteFulfillment(record.id);
                            if (!mounted) return;
                            navigator.pop();
                            await _loadDeliveries();
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Delivery ${record.id} removed from backend'),
                              ),
                            );
                          } catch (error) {
                            if (!mounted) return;
                            setDialogState(() {
                              isDeleting = false;
                              formError = error.toString();
                            });
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    bool isSaving = false;
    String? formError;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
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
                  onClose: isSaving
                      ? () {}
                      : () => Navigator.of(dialogContext).pop(),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (formError != null) ...[
                          _modalError(isDark, formError!),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        Text(
                          prompt,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
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
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : AppColors.neutral200,
                            ),
                          ),
                          child: CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            title: Text(
                              'Notify farm manager',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            value: notifyFarmManager,
                            onChanged: (value) {
                              setDialogState(
                                  () => notifyFarmManager = value ?? true);
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
                  confirmLabel: isSaving ? 'Saving...' : confirmLabel,
                  confirmColor: confirmColor,
                  onCancel: isSaving
                      ? () {}
                      : () => Navigator.of(dialogContext).pop(),
                  onConfirm: isSaving
                      ? () {}
                      : () async {
                          setDialogState(() {
                            isSaving = true;
                            formError = null;
                          });
                          final navigator = Navigator.of(dialogContext);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await _updateDelivery(
                              record: record,
                              status: _statusForAction(
                                confirmLabel == 'Reject'
                                    ? _DeliveryAction.reject
                                    : confirmLabel == 'Cancel Delivery'
                                        ? _DeliveryAction.cancel
                                        : confirmLabel == 'Hold Delivery'
                                            ? _DeliveryAction.putOnHold
                                            : _DeliveryAction.approve,
                              ),
                              note: reasonController.text.trim(),
                            );
                            if (!mounted) return;
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$confirmLabel completed for ${record.id}'
                                  '${notifyFarmManager ? ' (manager notified)' : ''}',
                                ),
                              ),
                            );
                          } catch (error) {
                            if (!mounted) return;
                            setDialogState(() {
                              isSaving = false;
                              formError = error.toString();
                            });
                          }
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
    final etaController = TextEditingController(text: record.eta);
    final driverOptions = _driverUsers();
    String selectedDriverId = '';
    for (final driver in driverOptions) {
      if ((driver['name'] ?? '').toString() == record.driver) {
        selectedDriverId = _userId(driver);
        break;
      }
    }
    if (selectedDriverId.isEmpty && driverOptions.isNotEmpty) {
      selectedDriverId = _userId(driverOptions.first);
    }
    var vehicleOptions =
        _vehicleOptionsForDriver(_driverById(selectedDriverId));
    String selectedVehicle = vehicleOptions.contains(record.vehicle)
        ? record.vehicle
        : vehicleOptions.isNotEmpty
            ? vehicleOptions.first
            : 'Pending assignment';
    bool isSaving = false;
    String? formError;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
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
                  onClose: isSaving
                      ? () {}
                      : () => Navigator.of(dialogContext).pop(),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        if (formError != null) ...[
                          _modalError(isDark, formError!),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        DropdownButtonFormField<String>(
                          key: ValueKey('assign-driver-$selectedDriverId'),
                          initialValue: selectedDriverId.isEmpty
                              ? null
                              : selectedDriverId,
                          dropdownColor:
                              isDark ? AppColors.surfaceDark : Colors.white,
                          decoration: _inputDecoration(isDark, 'Driver'),
                          items: driverOptions
                              .map(
                                (driver) => DropdownMenuItem(
                                  value: _userId(driver),
                                  child: Text(_driverLabel(driver)),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) => setDialogState(() {
                                    selectedDriverId = value ?? '';
                                    vehicleOptions = _vehicleOptionsForDriver(
                                      _driverById(selectedDriverId),
                                    );
                                    selectedVehicle = vehicleOptions.isNotEmpty
                                        ? vehicleOptions.first
                                        : 'Pending assignment';
                                    formError = null;
                                  }),
                        ),
                        if (driverOptions.isEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          _modalHint(
                            isDark,
                            'No active driver users found. Create an active Driver user before assigning delivery.',
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                              'assign-vehicle-$selectedDriverId-$selectedVehicle'),
                          initialValue: selectedVehicle,
                          dropdownColor:
                              isDark ? AppColors.surfaceDark : Colors.white,
                          decoration: _inputDecoration(isDark, 'Vehicle'),
                          items: vehicleOptions
                              .map(
                                (vehicle) => DropdownMenuItem(
                                  value: vehicle,
                                  child: Text(vehicle),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) => setDialogState(() {
                                    selectedVehicle =
                                        value ?? 'Pending assignment';
                                    formError = null;
                                  }),
                        ),
                        if (selectedVehicle == 'Pending assignment') ...[
                          const SizedBox(height: AppSpacing.xs),
                          _modalHint(
                            isDark,
                            'This driver has no vehicle saved on the user record yet.',
                          ),
                        ],
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
                  confirmLabel: isSaving ? 'Assigning...' : 'Assign',
                  confirmColor: AppColors.primary,
                  onCancel: isSaving
                      ? () {}
                      : () => Navigator.of(dialogContext).pop(),
                  onConfirm: isSaving
                      ? () {}
                      : () async {
                          final selectedDriver = _driverById(selectedDriverId);
                          if (selectedDriver == null ||
                              selectedVehicle.trim().isEmpty) {
                            setDialogState(() =>
                                formError = 'Driver and vehicle are required.');
                            return;
                          }
                          setDialogState(() {
                            isSaving = true;
                            formError = null;
                          });
                          final navigator = Navigator.of(dialogContext);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await _updateDelivery(
                              record: record,
                              status: _DeliveryStatus.scheduled,
                              driver: (selectedDriver['name'] ?? 'Unassigned')
                                  .toString(),
                              vehicle: selectedVehicle,
                              eta: etaController.text.trim(),
                            );
                            if (!mounted) return;
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Driver assigned for ${record.id}')),
                            );
                          } catch (error) {
                            if (!mounted) return;
                            setDialogState(() {
                              isSaving = false;
                              formError = error.toString();
                            });
                          }
                        },
                ),
              ],
            ),
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
        insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
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
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : AppColors.neutral50,
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
                        _detailRow(isDark, 'Crop',
                            '${record.crop} (${record.quantity} ${record.unit})'),
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
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: _inputDecoration(isDark, label),
    );
  }

  InputDecoration _inputDecoration(bool isDark, String label) {
    return InputDecoration(
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
    );
  }

  Widget _modalError(bool isDark, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.22)),
      ),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? Colors.white70 : AppColors.error,
        ),
      ),
    );
  }

  Widget _modalHint(bool isDark, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.warning),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
        ],
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
                    fontWeight: FontWeight.w600,
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
              style: const TextStyle(fontWeight: FontWeight.w500),
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
          fontWeight: FontWeight.w500,
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
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: activities
            .map((activity) => _buildActivityRow(isDark, activity))
            .toList(),
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
                    fontWeight: FontWeight.w500,
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
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 36,
              color: isDark ? Colors.white54 : AppColors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
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
    final sorted = [..._activities]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
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

  List<_FarmDeliverySummary> _farmSummaries() {
    final farms = _deliveries.map((record) => record.farm).toSet().toList()
      ..sort();
    return farms.map((farm) {
      final records =
          _deliveries.where((record) => record.farm == farm).toList();
      return _FarmDeliverySummary(
        farm: farm,
        total: records.length,
        active: records
            .where((record) =>
                record.status != _DeliveryStatus.delivered &&
                record.status != _DeliveryStatus.cancelled)
            .length,
        pendingApproval: records
            .where((record) => record.status == _DeliveryStatus.pendingApproval)
            .length,
        onHold: records
            .where((record) => record.status == _DeliveryStatus.onHold)
            .length,
        delivered: records
            .where((record) => record.status == _DeliveryStatus.delivered)
            .length,
      );
    }).toList();
  }
}

class _FarmDeliverySummary {
  final String farm;
  final int total;
  final int active;
  final int pendingApproval;
  final int onHold;
  final int delivered;

  const _FarmDeliverySummary({
    required this.farm,
    required this.total,
    required this.active,
    required this.pendingApproval,
    required this.onHold,
    required this.delivered,
  });
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
  final Map<String, dynamic> raw;

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
    required this.raw,
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
  delete,
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
