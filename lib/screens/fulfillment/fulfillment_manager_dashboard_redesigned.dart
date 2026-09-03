import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/fulfillment_manager_header.dart';
import '../../core/widgets/fulfillment_manager_sidebar.dart';
import '../../core/widgets/role_mobile_navigation.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../providers/auth_provider.dart';
import '../../services/fulfillment_data_service.dart';

/// Fulfillment Manager Dashboard - Redesigned
/// Command center for intake, packaging, yield, materials, and reporting.
class FulfillmentManagerDashboardRedesigned extends ConsumerStatefulWidget {
  const FulfillmentManagerDashboardRedesigned({super.key});

  @override
  ConsumerState<FulfillmentManagerDashboardRedesigned> createState() =>
      _FulfillmentManagerDashboardRedesignedState();
}

class _FulfillmentManagerDashboardRedesignedState
    extends ConsumerState<FulfillmentManagerDashboardRedesigned> {
  int _selectedNavIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  WeatherInfo? _weatherInfo;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  int _pendingProductionCount = 0;
  int _pendingIntake = 0;
  double _receivedTodayKg = 0;
  double _yieldLossKg = 0;
  double _materialCoverage = 0;
  List<Map<String, dynamic>> _pendingProductionBatches = [];

  List<Map<String, dynamic>> _pipeline = [];

  List<Map<String, dynamic>> _activity = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadData(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final snapshot = await FulfillmentDataService().load();
      final fulfillments = snapshot.fulfillments;
      final pendingProduction = _buildPendingProduction(snapshot.batches);
      final harvestedBatches = snapshot.batches.where(_isHarvested).toList();
      final inventory = snapshot.inventory;
      final today = DateTime.now();
      double receivedToday = 0;
      double wasteToday = 0;
      for (final item in fulfillments) {
        final received = DateTime.tryParse(
          item['received_date_time']?.toString() ?? '',
        );
        if (received != null &&
            received.year == today.year &&
            received.month == today.month &&
            received.day == today.day) {
          receivedToday += _number(item['total_weight']);
          wasteToday += _number(item['packaging_waste_weight']);
        }
      }
      final tracked = inventory.where((item) {
        final quantity = _number(item['quantity'] ?? item['stock']);
        return quantity > 0;
      }).length;
      final lowStock = inventory.where((item) {
        final quantity = _number(item['quantity'] ?? item['stock']);
        final reorder = _number(item['reorder_level'] ?? item['minimum_stock']);
        return quantity <= reorder;
      }).length;
      if (!mounted) return;
      setState(() {
        _pendingProductionBatches = pendingProduction;
        _pendingProductionCount = pendingProduction.length;
        _pendingIntake = harvestedBatches.length;
        _receivedTodayKg = receivedToday;
        _yieldLossKg = wasteToday;
        _materialCoverage = inventory.isEmpty
            ? 0
            : ((tracked - lowStock) / inventory.length * 100).clamp(0, 100);
        _pipeline = _buildPipeline(
          fulfillments,
          snapshot.batches,
          inventory,
        );
        _activity = _buildActivity(fulfillments);
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.toString();
          _pipeline = [];
          _activity = [];
        });
      }
    } finally {
      _isRefreshing = false;
    }
  }

  static double _number(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _value(
    Map<String, dynamic> item,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return fallback;
  }

  static DateTime? _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }

  static bool _isHarvested(Map<String, dynamic> batch) {
    return _value(batch, ['production_status', 'status']).toLowerCase() ==
        'harvested';
  }

  List<Map<String, dynamic>> _buildPendingProduction(
    List<Map<String, dynamic>> batches,
  ) {
    const terminalStatuses = {
      'harvested',
      'delivered',
      'completed',
      'cancelled',
      'canceled',
    };
    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);

    final pending = batches.where((batch) {
      final status = _value(
        batch,
        ['production_status', 'status'],
        fallback: 'Planted',
      ).toLowerCase();
      return !terminalStatuses.contains(status);
    }).map((batch) {
      final item = Map<String, dynamic>.from(batch);
      final endDate = _date(batch['end_date']);
      final daysToHarvest = endDate?.difference(currentDate).inDays;
      final harvested = _number(batch['total_harvested']);
      final transplanted = _number(batch['total_transplanted']);
      final rawStatus = _value(
        batch,
        ['production_status', 'status'],
        fallback: 'Planted',
      );

      item['_current_state'] =
          harvested > 0 && (transplanted <= 0 || harvested < transplanted)
              ? 'Partially harvested'
              : _titleCase(rawStatus);
      item['_end_date'] = endDate;
      item['_days_to_harvest'] = daysToHarvest;
      item['_urgency'] = daysToHarvest == null
          ? 4
          : daysToHarvest < 0
              ? 0
              : daysToHarvest <= 7
                  ? 1
                  : rawStatus.toLowerCase() == 'growing'
                      ? 2
                      : 3;
      return item;
    }).toList();

    pending.sort((a, b) {
      final urgency = (a['_urgency'] as int).compareTo(b['_urgency'] as int);
      if (urgency != 0) return urgency;
      final aDate = a['_end_date'] as DateTime?;
      final bDate = b['_end_date'] as DateTime?;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return pending;
  }

  static String _titleCase(String value) {
    final normalized = value.trim().replaceAll('_', ' ');
    if (normalized.isEmpty) return 'Planted';
    return normalized
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  List<Map<String, dynamic>> _buildPipeline(
    List<Map<String, dynamic>> fulfillments,
    List<Map<String, dynamic>> batches,
    List<Map<String, dynamic>> inventory,
  ) {
    final harvestedBatches = batches.where(_isHarvested).toList();
    final harvestedWeight = harvestedBatches.fold<double>(
      0,
      (total, batch) => total + _number(batch['total_weight_kg']),
    );
    final harvestMetric = harvestedWeight > 0
        ? '${harvestedWeight.toStringAsFixed(1)} kg'
        : '${harvestedBatches.length} batches';
    final packaging = fulfillments.where((item) {
      final status = item['status']?.toString().toLowerCase();
      return status == 'packaging';
    }).length;
    final packaged = fulfillments.where((item) {
      final status = item['status']?.toString().toLowerCase();
      return status == 'packaged' ||
          status == 'sent to sales' ||
          status == 'completed';
    }).length;
    final lowStock = inventory
        .where((item) =>
            _number(item['quantity'] ?? item['stock']) <=
            _number(item['reorder_level'] ?? item['minimum_stock']))
        .length;
    return [
      {
        ..._pipelineTemplate('Harvest Intake', Icons.fact_check_outlined,
            AppColors.warning, '/fulfillment-confirm'),
        'subtitle': harvestedBatches.isEmpty
            ? 'No harvested batches awaiting hub intake'
            : '${harvestedBatches.length} harvested batch${harvestedBatches.length == 1 ? '' : 'es'} ready for hub intake',
        'metric': harvestMetric,
        'status': harvestedBatches.isEmpty
            ? 'Up to date'
            : '${harvestedBatches.length} ready',
      },
      {
        ..._pipelineTemplate(
            'Packaging Lines',
            Icons.precision_manufacturing_outlined,
            AppColors.success,
            '/fulfillment-packaging'),
        'subtitle': '$packaging active fulfillment records',
        'metric': '$packaging active'
      },
      {
        ..._pipelineTemplate('Yield Control', Icons.analytics_outlined,
            AppColors.primary, '/fulfillment-yield'),
        'subtitle': '$packaged completed or packaged records',
        'metric': '$packaged records'
      },
      {
        ..._pipelineTemplate('Materials', Icons.inventory_2_outlined,
            AppColors.error, '/fulfillment-materials'),
        'subtitle': '${inventory.length} tracked stock items',
        'metric': '$lowStock at risk'
      },
    ];
  }

  Map<String, dynamic> _pipelineTemplate(
          String title, IconData icon, Color color, String route) =>
      {
        'title': title,
        'subtitle': '',
        'metric': '0',
        'status': '',
        'route': route,
        'icon': icon,
        'color': color,
      };

  List<Map<String, dynamic>> _buildActivity(
      List<Map<String, dynamic>> records) {
    return records
        .take(3)
        .map((item) => {
              'title':
                  '${item['batch_number'] ?? 'Fulfillment record'} updated',
              'subtitle':
                  '${item['farm_name'] ?? 'Farm'} • ${item['status'] ?? 'Unknown status'}',
              'time': item['packaging_date_time'] ??
                  item['received_date_time'] ??
                  '',
              'color': AppColors.primary,
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Fulfillment Manager';
    final userEmail = authState.user?.email ?? 'fulfillment@farmestates.com';

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? RoleMobileDrawer(
              userName: userName,
              userEmail: userEmail,
              userRole: 'Fulfillment Manager',
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) {
                setState(() => _selectedNavIndex = index);
              },
              items: fulfillmentNavigationItems,
            )
          : null,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail),
      floatingActionButton: !isMobile
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(
                context,
                '/fulfillment-confirm',
              ),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('Confirm Harvest'),
            )
          : null,
      bottomNavigationBar: isMobile
          ? RoleMobileBottomNav(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) {
                setState(() => _selectedNavIndex = index);
              },
              items: fulfillmentNavigationItems,
              defaultDynamicItem: fulfillmentNavigationItems[4],
            )
          : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail) {
    return Row(
      children: [
        FulfillmentManagerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) {
            setState(() => _selectedNavIndex = index);
          },
          userName: userName,
          userEmail: userEmail,
          userRole: 'Fulfillment Manager',
        ),
        Expanded(
          child: Column(
            children: [
              FulfillmentManagerHeader(
                userName: userName,
                weatherInfo: _weatherInfo,
                onNotificationTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _buildDashboardContent(isDark, false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark, String userName) {
    return Column(
      children: [
        FulfillmentManagerHeader(
          userName: userName,
          weatherInfo: _weatherInfo,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              96,
            ),
            child: _buildDashboardContent(isDark, true),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent(bool isDark, bool isMobile) {
    if (_isLoading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: CircularProgressIndicator(),
      ));
    }
    if (_errorMessage != null) {
      return Text('Unable to load fulfillment data. Pull to retry.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.error));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _FulfillmentKpi(
              title: 'Pending production',
              value: '$_pendingProductionCount',
              subtitle: 'Batches awaiting harvest',
              icon: Icons.pending_actions_outlined,
              color: AppColors.warning,
            ),
            _FulfillmentKpi(
              title: 'Received today',
              value: '${_receivedTodayKg.toStringAsFixed(1)} kg',
              subtitle: 'From backend intake records',
              icon: Icons.move_to_inbox_outlined,
              color: AppColors.success,
            ),
            _FulfillmentKpi(
              title: 'Yield loss',
              value: '${_yieldLossKg.toStringAsFixed(1)} kg',
              subtitle: 'Recorded packaging waste',
              icon: Icons.trending_down_outlined,
              color: AppColors.error,
            ),
            _FulfillmentKpi(
              title: 'Material coverage',
              value: '${_materialCoverage.toStringAsFixed(0)}%',
              subtitle: 'Based on tracked stock',
              icon: Icons.inventory_2_outlined,
              color: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildPendingProductionPanel(),
        const SizedBox(height: AppSpacing.xl),
        _buildMainGrid(isDark),
      ],
    );
  }

  Widget _buildHero(bool isDark, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(isDark ? 0.22 : 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fulfillment Command Center',
                      style: AppTypography.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 24 : 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Control harvest intake, packaging flow, yield recovery, materials, and operational reporting.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.88),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _HeroChip(
                  label: '$_pendingProductionCount awaiting harvest',
                  icon: Icons.warehouse_outlined),
              _HeroChip(
                  label: '${_activity.length} recent records',
                  icon: Icons.assessment_outlined),
              _HeroChip(
                  label:
                      '${_pipeline.isEmpty ? 0 : _pipeline.length} live workflow areas',
                  icon: Icons.warning_amber_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainGrid(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 980;

        if (!twoColumns) {
          return Column(
            children: [
              _buildPipelinePanel(),
              const SizedBox(height: AppSpacing.md),
              _buildActionPanel(),
              const SizedBox(height: AppSpacing.md),
              _buildActivityPanel(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildPipelinePanel()),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildActionPanel(),
                  const SizedBox(height: AppSpacing.md),
                  _buildActivityPanel(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPendingProductionPanel() {
    return _DashboardPanel(
      title: 'Production Awaiting Harvest',
      subtitle:
          'Live farm batches ordered by harvest urgency and current state.',
      icon: Icons.agriculture_outlined,
      color: AppColors.warning,
      child: _pendingProductionBatches.isEmpty
          ? const _ProductionEmptyState()
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760 ? 2 : 1;
                final cardWidth = columns == 2
                    ? (constraints.maxWidth - AppSpacing.md) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: _pendingProductionBatches
                      .map(
                        (batch) => SizedBox(
                          width: cardWidth,
                          child: _ProductionBatchCard(batch: batch),
                        ),
                      )
                      .toList(),
                );
              },
            ),
    );
  }

  Widget _buildPipelinePanel() {
    return _DashboardPanel(
      title: 'Fulfillment Pipeline',
      subtitle: 'Current operational health across the chain.',
      icon: Icons.account_tree_outlined,
      color: AppColors.primary,
      child: _ResponsiveGrid(
        itemCount: _pipeline.length,
        itemBuilder: (index) => _PipelineCard(item: _pipeline[index]),
      ),
    );
  }

  Widget _buildActionPanel() {
    return _DashboardPanel(
      title: 'Priority Actions',
      subtitle: 'Fast paths for daily fulfillment work.',
      icon: Icons.bolt_outlined,
      color: AppColors.warning,
      child: Column(
        children: [
          _ActionTile(
            title: 'Confirm harvest intake',
            subtitle: 'Review $_pendingIntake pending loads',
            icon: Icons.fact_check_outlined,
            color: AppColors.warning,
            route: '/fulfillment-confirm',
          ),
          SizedBox(height: AppSpacing.sm),
          _ActionTile(
            title: 'Coordinate packaging',
            subtitle: 'Open backend packaging records',
            icon: Icons.precision_manufacturing_outlined,
            color: AppColors.success,
            route: '/fulfillment-packaging',
          ),
          SizedBox(height: AppSpacing.sm),
          _ActionTile(
            title: 'Open reports',
            subtitle: 'Review exceptions and exports',
            icon: Icons.assessment_outlined,
            color: AppColors.primary,
            route: '/fulfillment-reports',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPanel() {
    return _DashboardPanel(
      title: 'Fulfillment Activity',
      subtitle: 'Recent chain events and exceptions.',
      icon: Icons.history_outlined,
      color: AppColors.success,
      child: Column(
        children: _activity
            .map((activity) => _ActivityRow(activity: activity))
            .toList(),
      ),
    );
  }
}

class _ProductionBatchCard extends StatelessWidget {
  const _ProductionBatchCard({required this.batch});

  final Map<String, dynamic> batch;

  String _value(List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final value = batch[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return fallback;
  }

  String _quantity(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '') ?? 0;
    return number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toStringAsFixed(1);
  }

  Color _stateColor(String state) {
    final normalized = state.toLowerCase();
    if (normalized.contains('partial')) return AppColors.warning;
    if (normalized.contains('growing')) return AppColors.success;
    return AppColors.info;
  }

  String _scheduleLabel(int? days) {
    if (days == null) return 'Date not set';
    if (days < 0) {
      final overdue = days.abs();
      return '$overdue day${overdue == 1 ? '' : 's'} overdue';
    }
    if (days == 0) return 'Due today';
    return 'Due in $days day${days == 1 ? '' : 's'}';
  }

  Color _scheduleColor(int? days) {
    if (days == null) return AppColors.neutral600;
    if (days < 0) return AppColors.error;
    if (days <= 7) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = batch['_current_state']?.toString() ?? 'Planted';
    final stateColor = _stateColor(state);
    final endDate = batch['_end_date'] as DateTime?;
    final days = batch['_days_to_harvest'] as int?;
    final scheduleColor = _scheduleColor(days);
    final batchNumber = _value(
      ['batch_no', 'batch_number', 'batch_id', r'$id'],
      fallback: 'Unnumbered batch',
    );
    final crop = _value(
      ['plant_name', 'plant_type', 'crop_name'],
      fallback: 'Crop not recorded',
    );
    final variety = _value(
      ['plant_variety', 'variety_name', 'crop_variety'],
    );
    final issue = _value(['technical_issues', 'issue_notes']);

    return Container(
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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBox(icon: Icons.grass_outlined, color: stateColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batchNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      variety.isEmpty ? crop : '$crop | $variety',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusBadge(label: state, color: stateColor),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                Icons.agriculture_outlined,
                size: 17,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  _value(['farm_name'], fallback: 'Farm not assigned'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: scheduleColor.withOpacity(isDark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Icon(Icons.event_outlined, size: 18, color: scheduleColor),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected harvest',
                        style: AppTypography.caption.copyWith(
                          color:
                              isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        endDate == null
                            ? 'Not scheduled'
                            : DateFormat('dd MMM yyyy').format(endDate),
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(
                  label: _scheduleLabel(days),
                  color: scheduleColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ProductionMetric(
                  label: 'Nursed',
                  value: _quantity(batch['total_seeds_nursed']),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _ProductionMetric(
                  label: 'Transplanted',
                  value: _quantity(batch['total_transplanted']),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _ProductionMetric(
                  label: 'Harvested',
                  value: _quantity(batch['total_harvested']),
                ),
              ),
            ],
          ),
          if (issue.isNotEmpty && issue.toLowerCase() != 'none') ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(isDark ? 0.14 : 0.07),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.report_problem_outlined,
                    size: 17,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      issue,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: isDark ? Colors.white70 : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductionMetric extends StatelessWidget {
  const _ProductionMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductionEmptyState extends StatelessWidget {
  const _ProductionEmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.task_alt_outlined,
            color: AppColors.success,
            size: 30,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No batches are awaiting harvest',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'New planted or growing batches will appear here automatically.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FulfillmentKpi extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _FulfillmentKpi({
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
        MediaQuery.of(context).size.width < 600 ? double.infinity : 230.0;

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
                _MutedText(title),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.h5.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                _MutedText(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  const _DashboardPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(icon: icon, color: color),
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
                    _MutedText(subtitle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
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
        final columns = constraints.maxWidth >= 760 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 230,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (context, index) => itemBuilder(index),
        );
      },
    );
  }
}

class _PipelineCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _PipelineCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = item['color']! as Color;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, item['route']! as String),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: color.withOpacity(isDark ? 0.28 : 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBox(icon: item['icon']! as IconData, color: color),
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
            Row(
              children: [
                Expanded(
                  child: _MetricBlock(
                    label: 'Current metric',
                    value: item['metric']! as String,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
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
            _IconBox(icon: icon, color: color),
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
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = activity['color']! as Color;

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
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title']! as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                _MutedText(activity['subtitle']! as String),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _MutedText(activity['time']! as String),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final String label;
  final String value;

  const _MetricBlock({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
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

class _HeroChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeroChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white,
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

  const _IconBox({
    required this.icon,
    required this.color,
  });

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
