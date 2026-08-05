import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

class ModernAnalyticsScreen extends ConsumerStatefulWidget {
  const ModernAnalyticsScreen({super.key, this.isSuperAdmin = false});

  final bool isSuperAdmin;

  @override
  ConsumerState<ModernAnalyticsScreen> createState() =>
      _ModernAnalyticsScreenState();
}

class _ModernAnalyticsScreenState extends ConsumerState<ModernAnalyticsScreen> {
  final SuperAdminApiService _api = SuperAdminApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _farms = [];
  final List<Map<String, dynamic>> _users = [];
  final List<Map<String, dynamic>> _batches = [];
  final List<Map<String, dynamic>> _sales = [];
  final List<Map<String, dynamic>> _sensors = [];
  final List<Map<String, dynamic>> _inventory = [];
  final List<Map<String, dynamic>> _fulfillments = [];

  String _selectedPeriod = 'Last 30 Days';
  String _selectedFarm = 'All Farms';
  bool _isLoading = true;
  String? _loadError;
  int _selectedNavIndex = 13;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        _api.getFarms(),
        _api.getUsers(),
        _api.getBatches(),
        _api.getSales(),
        _api.getSensors(),
        _api.getInventory(),
        _api.getFulfillments(),
      ]);
      if (!mounted) return;
      setState(() {
        _farms
          ..clear()
          ..addAll(results[0]);
        _users
          ..clear()
          ..addAll(results[1]);
        _batches
          ..clear()
          ..addAll(results[2]);
        _sales
          ..clear()
          ..addAll(results[3]);
        _sensors
          ..clear()
          ..addAll(results[4]);
        _inventory
          ..clear()
          ..addAll(results[5]);
        _fulfillments
          ..clear()
          ..addAll(results[6]);
        if (_selectedFarm != 'All Farms' &&
            !_farmNames.contains(_selectedFarm)) {
          _selectedFarm = 'All Farms';
        }
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  List<String> get _farmNames => [
        'All Farms',
        ..._farms
            .map((farm) => _text(farm, ['name', 'farm_name', 'farmName']))
            .where((name) => name.isNotEmpty)
            .toSet(),
      ];

  List<Map<String, dynamic>> get _periodBatches => _batches
      .where((batch) => _withinSelectedPeriod(
            _date(batch, ['actual_harvest_date', 'updated_at', 'created_at']),
          ))
      .toList();

  List<Map<String, dynamic>> get _periodSales => _sales
      .where((sale) => _withinSelectedPeriod(
            _date(sale, ['payment_date', 'delivered_at', 'created_at']),
          ))
      .toList();

  List<_FarmAnalytics> get _farmAnalytics {
    final periodBatches = _periodBatches;
    final periodSales = _periodSales;
    final batchesById = {
      for (final batch in _batches) _id(batch): batch,
    };
    final salesByFarm = <String, List<Map<String, dynamic>>>{};
    final batchesByFarm = <String, List<Map<String, dynamic>>>{};
    final sensorsByFarm = <String, List<Map<String, dynamic>>>{};
    final inventoryByFarm = <String, List<Map<String, dynamic>>>{};

    for (final batch in periodBatches) {
      final farmId = _value(batch, ['farm_id', 'farmId']);
      if (farmId.isNotEmpty) {
        batchesByFarm.putIfAbsent(farmId, () => []).add(batch);
      }
    }
    for (final sale in periodSales) {
      var farmId = _value(sale, ['farm_id', 'farmId']);
      if (farmId.isEmpty) {
        final batchId = _value(sale, ['batch_id', 'batchId']);
        farmId =
            _value(batchesById[batchId] ?? const {}, ['farm_id', 'farmId']);
      }
      if (farmId.isNotEmpty) {
        salesByFarm.putIfAbsent(farmId, () => []).add(sale);
      }
    }
    for (final sensor in _sensors) {
      final farmId = _value(sensor, ['farm_id', 'farmId']);
      if (farmId.isNotEmpty) {
        sensorsByFarm.putIfAbsent(farmId, () => []).add(sensor);
      }
    }
    for (final item in _inventory) {
      final farmId = _value(item, ['farm_id', 'farmId']);
      if (farmId.isNotEmpty) {
        inventoryByFarm.putIfAbsent(farmId, () => []).add(item);
      }
    }

    return _farms.map((farm) {
      final farmId = _id(farm);
      final name =
          _text(farm, ['name', 'farm_name', 'farmName'], fallback: 'Farm');
      final farmBatches = batchesByFarm[farmId] ?? const [];
      final farmSales = salesByFarm[farmId] ?? const [];
      final farmSensors = sensorsByFarm[farmId] ?? const [];
      final farmInventory = inventoryByFarm[farmId] ?? const [];
      final revenue = farmSales.fold<double>(
        0,
        (sum, sale) => sum + _number(sale, ['total_amount', 'amount', 'total']),
      );
      final paidRevenue = farmSales
          .where(
              (sale) => _status(sale, ['payment_status', 'status']) == 'paid')
          .fold<double>(
            0,
            (sum, sale) =>
                sum + _number(sale, ['total_amount', 'amount', 'total']),
          );
      final productionKg = farmBatches.fold<double>(
        0,
        (sum, batch) =>
            sum +
            _number(batch, [
              'total_weight_kg',
              'harvested_weight_kg',
              'actual_yield_kg',
              'quantity_kg',
              'weight_kg',
            ]),
      );
      final expectedHeads = farmBatches.fold<double>(
        0,
        (sum, batch) =>
            sum +
            _number(batch, [
              'total_transplanted',
              'expected_heads',
              'planned_quantity',
            ]),
      );
      final harvestedHeads = farmBatches.fold<double>(
        0,
        (sum, batch) =>
            sum +
            _number(batch, [
              'total_harvested',
              'harvested_heads',
              'actual_quantity',
            ]),
      );
      final completedBatches = farmBatches
          .where((batch) => {
                'completed',
                'harvested',
                'closed',
              }.contains(_status(batch, ['status', 'batch_status'])))
          .length;
      final sensorHealth = _sensorHealth(farmSensors);
      final productionCompletion = farmBatches.isEmpty
          ? 0
          : (completedBatches / farmBatches.length) * 100;
      final paymentCompletion =
          revenue <= 0 ? 0 : (paidRevenue / revenue) * 100;
      final efficiency = ((productionCompletion + paymentCompletion) / 2)
          .clamp(0, 100)
          .round();
      final acres = math.max(
        1,
        _number(farm, ['acreage', 'area_acres', 'size', 'land_size']).round(),
      );
      final yieldPerAcre = (productionKg / acres).clamp(0, 100).round();
      final inventoryValue = farmInventory.fold<double>(
        0,
        (sum, item) =>
            sum +
            (_number(item, ['total_value', 'value']) > 0
                ? _number(item, ['total_value', 'value'])
                : _number(item, ['quantity', 'stock']) *
                    _number(item, ['unit_price', 'price'])),
      );
      final riskScore =
          math.min(100, ((100 - sensorHealth) + (100 - efficiency)) / 2);
      final risk = riskScore >= 45
          ? 'High'
          : riskScore >= 25
              ? 'Watch'
              : 'Low';

      return _FarmAnalytics(
        id: farmId,
        name: name,
        revenue: revenue,
        productionKg: productionKg,
        inventoryValue: inventoryValue,
        efficiency: efficiency,
        yieldPerAcre: yieldPerAcre,
        sensorHealth: sensorHealth,
        batchCount: farmBatches.length,
        salesCount: farmSales.length,
        lossHeads: math.max(0, expectedHeads - harvestedHeads),
        risk: risk,
        color: risk == 'High'
            ? AppColors.error
            : risk == 'Watch'
                ? AppColors.warning
                : AppColors.success,
      );
    }).toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
  }

  List<_FarmAnalytics> get _visibleFarms {
    final analytics = _farmAnalytics;
    if (_selectedFarm == 'All Farms') return analytics;
    return analytics.where((farm) => farm.name == _selectedFarm).toList();
  }

  _AnalyticsTotals get _totals {
    final farms = _visibleFarms;
    if (farms.isEmpty) {
      return const _AnalyticsTotals(
        revenue: 0,
        productionKg: 0,
        inventoryValue: 0,
        efficiency: 0,
        sensorHealth: 0,
        losses: 0,
      );
    }
    return _AnalyticsTotals(
      revenue: farms.fold(0, (sum, farm) => sum + farm.revenue),
      productionKg: farms.fold(0, (sum, farm) => sum + farm.productionKg),
      inventoryValue: farms.fold(0, (sum, farm) => sum + farm.inventoryValue),
      efficiency: (farms.fold<int>(0, (sum, farm) => sum + farm.efficiency) /
              farms.length)
          .round(),
      sensorHealth:
          (farms.fold<int>(0, (sum, farm) => sum + farm.sensorHealth) /
                  farms.length)
              .round(),
      losses: farms.fold(0, (sum, farm) => sum + farm.lossHeads),
    );
  }

  List<FlSpot> get _revenueTrend => _trendFromRecords(
      _periodSales,
      ['payment_date', 'delivered_at', 'created_at'],
      ['total_amount', 'amount', 'total']);

  List<FlSpot> get _productionTrend => _trendFromRecords(
      _periodBatches,
      ['actual_harvest_date', 'updated_at', 'created_at'],
      ['total_weight_kg', 'harvested_weight_kg', 'actual_yield_kg']);

  List<_BarMetric> get _sensorBars {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final sensor in _sensors) {
      final type = _text(sensor, ['type', 'sensor_type', 'metric_type'],
          fallback: 'Other');
      grouped.putIfAbsent(type, () => []).add(sensor);
    }
    if (grouped.isEmpty) {
      return const [_BarMetric('None', 0, AppColors.neutral400)];
    }
    return grouped.entries.take(5).map((entry) {
      final value = _sensorHealth(entry.value).toDouble();
      return _BarMetric(_shortLabel(entry.key), value, _barColor(value));
    }).toList();
  }

  List<_InsightItem> get _insights {
    final farms = _farmAnalytics;
    final topFarm = farms.isEmpty ? null : farms.first;
    final lowSensor = farms.where((farm) => farm.sensorHealth < 85).toList();
    final pendingFulfillments = _fulfillments
        .where((item) => !{'completed', 'delivered', 'cancelled'}
            .contains(_status(item, ['status', 'delivery_status'])))
        .length;

    return [
      _InsightItem(
        title: topFarm == null
            ? 'Revenue analytics needs farm activity'
            : '${topFarm.name} is leading revenue performance',
        detail: topFarm == null
            ? 'Create farms, batches, and sales to unlock live revenue trends.'
            : '${topFarm.name} has ${_money(topFarm.revenue)} in linked sales for the selected dataset.',
        icon: Icons.trending_up_rounded,
        color: AppColors.success,
      ),
      _InsightItem(
        title: lowSensor.isEmpty
            ? 'Sensor network is within operating range'
            : '${lowSensor.length} farm${lowSensor.length == 1 ? '' : 's'} need sensor review',
        detail: lowSensor.isEmpty
            ? 'Current telemetry health is above the operational threshold.'
            : 'Prioritize diagnostics where sensor health is below 85%.',
        icon: Icons.sensors_rounded,
        color: lowSensor.isEmpty ? AppColors.info : AppColors.warning,
      ),
      _InsightItem(
        title: pendingFulfillments == 0
            ? 'Fulfillment queue is clear'
            : '$pendingFulfillments fulfillment records need attention',
        detail: widget.isSuperAdmin
            ? 'Super Admin can inspect global pricing, inventory, deliveries, and audit controls from this page.'
            : 'Admin has operational analytics access; restricted platform controls stay with Super Admin.',
        icon: Icons.assignment_turned_in_rounded,
        color: pendingFulfillments == 0 ? AppColors.success : AppColors.warning,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;
    final user = ref.watch(currentUserProvider);
    final userName =
        user?.name ?? (widget.isSuperAdmin ? 'Super Admin' : 'Admin');
    final userEmail = user?.email ?? 'admin@farmestates.com';
    final firstName = userName.split(' ').first;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: widget.isSuperAdmin && isMobile
          ? SuperAdminDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
              userName: userName,
              userEmail: userEmail,
              userRole: 'Super Administrator',
            )
          : !widget.isSuperAdmin && isMobile
              ? AdminDrawer(
                  selectedIndex: 4,
                  onItemSelected: (_) {},
                  userName: userName,
                  userEmail: userEmail,
                  userRole: 'Administrator',
                )
              : null,
      body: isMobile
          ? _buildMobileLayout(isDark, firstName)
          : _buildDesktopLayout(isDark, firstName, userName, userEmail),
      bottomNavigationBar: widget.isSuperAdmin && isMobile
          ? SuperAdminMobileBottomNav(
              selectedIndex: 13,
              onItemSelected: (_) {},
            )
          : !widget.isSuperAdmin && isMobile
              ? AdminMobileBottomNav(
                  selectedIndex: 4,
                  onItemSelected: (_) {},
                )
              : null,
    );
  }

  Widget _buildDesktopLayout(
    bool isDark,
    String firstName,
    String userName,
    String userEmail,
  ) {
    return Row(
      children: [
        if (widget.isSuperAdmin)
          SuperAdminSidebar(
            selectedIndex: _selectedNavIndex,
            onItemSelected: (index) =>
                setState(() => _selectedNavIndex = index),
            userName: userName,
            userEmail: userEmail,
            userRole: 'Super Administrator',
          )
        else
          ModernAdminSidebar(selectedIndex: 4, onItemSelected: (_) {}),
        Expanded(
          child: Column(
            children: [
              ModernAdminHeader(
                userName: firstName,
                onNotificationTap: () {},
                onProfileTap: () {},
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: _buildBody(isDark, isMobile: false),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark, String firstName) {
    return Column(
      children: [
        ModernAdminHeader(
          userName: firstName,
          onMenuTap: widget.isSuperAdmin
              ? () => _scaffoldKey.currentState?.openDrawer()
              : null,
          onNotificationTap: () {},
          onProfileTap: () {},
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAnalytics,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _buildBody(isDark, isMobile: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(bool isDark, {required bool isMobile}) {
    if (_isLoading) {
      return const AdminDataSkeleton(rowCount: 6);
    }
    if (_loadError != null) {
      return _buildError(isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        _buildScopeControls(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        _buildKpiGrid(isDark),
        const SizedBox(height: AppSpacing.lg),
        _buildPrimaryCharts(isDark),
        const SizedBox(height: AppSpacing.lg),
        if (widget.isSuperAdmin) ...[
          _buildControlPanel(isDark),
          const SizedBox(height: AppSpacing.lg),
        ],
        _buildFarmComparison(isDark),
        const SizedBox(height: AppSpacing.lg),
        _buildInsights(isDark),
      ],
    );
  }

  Widget _buildError(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: _cardDecoration(isDark),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 42),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Analytics data could not be loaded',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _loadError ?? 'Unknown backend error',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.62)
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _loadAnalytics,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(bool isDark, bool isMobile) {
    final totals = _totals;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF102A43),
                  const Color(0xFF123B2F),
                  AppColors.surfaceDark,
                ]
              : [
                  const Color(0xFFEAF4FF),
                  const Color(0xFFF1FFF5),
                  Colors.white,
                ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.primary.withValues(alpha: 0.14),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 820;
          return Flex(
            direction: stacked ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: stacked ? 0 : 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScopePill(isDark),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      widget.isSuperAdmin
                          ? 'Platform Analytics Control Center'
                          : 'Farm Analytics Command Center',
                      style: AppTypography.h3.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.isSuperAdmin
                          ? 'Global analytics across farms, sales, batches, sensors, inventory, fulfillment, and operational controls.'
                          : 'Operational analytics from backend sales, batches, sensors, inventory, and fulfillment records.',
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.72)
                            : AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (!stacked) const SizedBox(width: AppSpacing.xl),
              if (stacked) const SizedBox(height: AppSpacing.lg),
              Expanded(
                flex: stacked ? 0 : 2,
                child: _buildHeroScorecard(isDark, totals),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScopePill(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_rounded,
              size: 17, color: isDark ? Colors.white : AppColors.info),
          const SizedBox(width: AppSpacing.sm),
          Text(
            widget.isSuperAdmin ? '100% platform control' : '90% admin control',
            style: AppTypography.label.copyWith(
              color: isDark ? Colors.white : AppColors.info,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroScorecard(bool isDark, _AnalyticsTotals totals) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : AppColors.neutral300,
        ),
      ),
      child: Column(
        children: [
          _scoreRow(isDark, Icons.payments_rounded, 'Revenue',
              _money(totals.revenue), AppColors.success),
          const SizedBox(height: AppSpacing.md),
          _scoreRow(
              isDark,
              Icons.inventory_2_rounded,
              'Production',
              '${(totals.productionKg / 1000).toStringAsFixed(1)}K kg',
              AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          _scoreRow(isDark, Icons.speed_rounded, 'Efficiency',
              '${totals.efficiency}%', AppColors.warning),
        ],
      ),
    );
  }

  Widget _scoreRow(
    bool isDark,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.72)
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildScopeControls(bool isDark, bool isMobile) {
    final scopeDropdown = _dropdown(
      label: 'Analytics Scope',
      value: _selectedFarm,
      items: _farmNames.isEmpty ? const ['All Farms'] : _farmNames,
      isDark: isDark,
      width: isMobile ? double.infinity : null,
      onChanged: (value) => setState(() => _selectedFarm = value!),
    );
    final periodDropdown = _dropdown(
      label: 'Period',
      value: _selectedPeriod,
      items: const [
        'Last 7 Days',
        'Last 30 Days',
        'Last 90 Days',
        'This Year',
      ],
      isDark: isDark,
      width: isMobile ? double.infinity : null,
      onChanged: (value) => setState(() => _selectedPeriod = value!),
    );
    final scopeChip = _ScopeChip(
      icon: Icons.storage_rounded,
      label: '${_farms.length} farms from backend',
      color: AppColors.info,
    );
    final controlChip = _ScopeChip(
      icon: widget.isSuperAdmin
          ? Icons.admin_panel_settings_rounded
          : Icons.manage_accounts_rounded,
      label: widget.isSuperAdmin
          ? 'Full platform controls'
          : 'Operational controls',
      color: widget.isSuperAdmin ? AppColors.error : AppColors.primary,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                scopeDropdown,
                const SizedBox(height: AppSpacing.md),
                periodDropdown,
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [scopeChip, controlChip],
                ),
              ],
            )
          : Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                scopeDropdown,
                periodDropdown,
                scopeChip,
                controlChip,
              ],
            ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required bool isDark,
    double? width,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    return SizedBox(
      width: width ?? 230,
      child: DropdownButtonFormField<String>(
        initialValue: safeValue,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.neutral50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.neutral300,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiGrid(bool isDark) {
    final totals = _totals;
    final kpis = [
      _AnalyticsKpi(
        label: 'Revenue',
        value: _money(totals.revenue),
        detail: '${_periodSales.length} sales records',
        icon: Icons.payments_rounded,
        color: AppColors.success,
      ),
      _AnalyticsKpi(
        label: 'Production',
        value: '${(totals.productionKg / 1000).toStringAsFixed(1)}K kg',
        detail: '${_periodBatches.length} batches',
        icon: Icons.inventory_2_rounded,
        color: AppColors.primary,
      ),
      _AnalyticsKpi(
        label: 'Inventory Value',
        value: _money(totals.inventoryValue),
        detail: '${_inventory.length} stock records',
        icon: Icons.warehouse_rounded,
        color: AppColors.warning,
      ),
      _AnalyticsKpi(
        label: 'Sensor Health',
        value: '${totals.sensorHealth}%',
        detail: '${_sensors.length} sensors',
        icon: Icons.sensors_rounded,
        color: AppColors.info,
      ),
      _AnalyticsKpi(
        label: 'Loss Heads',
        value: totals.losses.toStringAsFixed(0),
        detail: 'Batch yield variance',
        icon: Icons.trending_down_rounded,
        color: AppColors.error,
      ),
      _AnalyticsKpi(
        label: 'Active Users',
        value: _users
            .where((user) => _status(user, ['status']) == 'active')
            .length
            .toString(),
        detail: '${_users.length} total users',
        icon: Icons.people_alt_rounded,
        color: AppColors.primary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 3
            : constraints.maxWidth >= 680
                ? 2
                : 1;
        final cardWidth =
            (constraints.maxWidth - (AppSpacing.md * (columns - 1))) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: kpis
              .map((kpi) => SizedBox(
                    width: cardWidth,
                    child: _KpiCard(kpi: kpi, isDark: isDark),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildPrimaryCharts(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final children = [
          Expanded(
            flex: wide ? 3 : 0,
            child: _TrendChart(
              title: _selectedFarm == 'All Farms'
                  ? 'Global Revenue vs Production'
                  : 'Farm Revenue vs Production',
              revenueSpots: _revenueTrend,
              productionSpots: _productionTrend,
              isDark: isDark,
            ),
          ),
          SizedBox(
              width: wide ? AppSpacing.md : 0,
              height: wide ? 0 : AppSpacing.md),
          Expanded(
            flex: wide ? 2 : 0,
            child: _SensorReliabilityChart(
              isDark: isDark,
              bars: _sensorBars,
            ),
          ),
        ];

        return wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children)
            : Column(children: children);
      },
    );
  }

  Widget _buildControlPanel(bool isDark) {
    final actions = const [
      _ControlAction('Pricing Control', Icons.price_change_rounded,
          '/superadmin/pricing', AppColors.success),
      _ControlAction('Inventory Control', Icons.inventory_2_rounded,
          '/superadmin/inventory', AppColors.primary),
      _ControlAction('Delivery Control', Icons.local_shipping_rounded,
          '/superadmin/deliveries', AppColors.warning),
      _ControlAction('System Config', Icons.settings_rounded,
          '/superadmin/config', AppColors.info),
      _ControlAction('Audit Logs', Icons.history_rounded, '/superadmin/audit',
          AppColors.error),
      _ControlAction('Backup & Restore', Icons.backup_rounded,
          '/superadmin/backup', AppColors.neutral600),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Super Admin Control Layer',
            subtitle:
                '100% control adds platform configuration, audit, backup, pricing, inventory, and delivery actions.',
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: actions
                .map(
                  (action) => OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, action.route),
                    icon: Icon(action.icon, color: action.color),
                    label: Text(action.label),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      foregroundColor:
                          isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmComparison(bool isDark) {
    final farms = _visibleFarms;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: _selectedFarm == 'All Farms'
                ? 'Farm Performance Comparison'
                : 'Farm Performance Detail',
            subtitle:
                'Revenue, production, inventory value, sensor health, losses, and risk by farm.',
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (farms.isEmpty)
            _emptyState(isDark)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760 ? 2 : 1;
                final cardWidth =
                    (constraints.maxWidth - (AppSpacing.md * (columns - 1))) /
                        columns;
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: farms
                      .map((farm) => SizedBox(
                            width: cardWidth,
                            child: _FarmComparisonCard(
                              farm: farm,
                              isDark: isDark,
                              onSelect: () =>
                                  setState(() => _selectedFarm = farm.name),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.025)
            : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Text(
        'No farms are available in the backend yet.',
        textAlign: TextAlign.center,
        style: AppTypography.bodyMedium.copyWith(
          color: isDark
              ? Colors.white.withValues(alpha: 0.68)
              : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildInsights(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Operational Insights',
            subtitle: 'Live recommendations based on backend analytics.',
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.md),
          ..._insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _InsightRow(insight: insight, isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    const items = [
      _MobileNavItem(Icons.dashboard_outlined, 'Dashboard', '/dashboard'),
      _MobileNavItem(Icons.people_outline, 'Users', '/users'),
      _MobileNavItem(Icons.agriculture_outlined, 'Farms', '/farms'),
      _MobileNavItem(Icons.sensors_outlined, 'Sensors', '/sensors'),
      _MobileNavItem(Icons.analytics_outlined, 'Analytics', '/analytics'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.neutral300,
          ),
        ),
      ),
      child: Row(
        children: items.map((item) {
          final selected = item.label == 'Analytics';
          return Expanded(
            child: InkWell(
              onTap: () {
                if (!selected) {
                  Navigator.pushReplacementNamed(context, item.route);
                }
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 21,
                      color: selected
                          ? AppColors.primary
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.62)
                              : AppColors.textSecondary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        color: selected
                            ? AppColors.primary
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.62)
                                : AppColors.textSecondary),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  int _sensorHealth(List<Map<String, dynamic>> sensors) {
    if (sensors.isEmpty) return 0;
    final online = sensors.where((sensor) => _isOnlineSensor(sensor)).length;
    return ((online / sensors.length) * 100).round();
  }

  bool _isOnlineSensor(Map<String, dynamic> sensor) {
    final status = _status(sensor, ['connection_status', 'status']);
    if (status == 'online' || status == 'active') return true;
    final lastSeen =
        _date(sensor, ['last_seen', 'last_reading_at', 'updated_at']);
    if (lastSeen == null) return false;
    return DateTime.now().difference(lastSeen).inSeconds <= 20;
  }

  bool _withinSelectedPeriod(DateTime? date) {
    if (date == null || _selectedPeriod == 'This Year') {
      if (date == null) return true;
      return date.year == DateTime.now().year;
    }
    return DateTime.now().difference(date).inDays <= _periodDays;
  }

  int get _periodDays {
    switch (_selectedPeriod) {
      case 'Last 7 Days':
        return 7;
      case 'Last 90 Days':
        return 90;
      case 'This Year':
        return 366;
      case 'Last 30 Days':
      default:
        return 30;
    }
  }

  String get _selectedFarmId {
    if (_selectedFarm == 'All Farms') return '';
    final farm = _farms.firstWhere(
      (item) => _text(item, ['name', 'farm_name', 'farmName']) == _selectedFarm,
      orElse: () => const {},
    );
    return _id(farm);
  }

  String _recordFarmId(Map<String, dynamic> record) {
    final directFarmId = _value(record, ['farm_id', 'farmId']);
    if (directFarmId.isNotEmpty) return directFarmId;
    final batchId = _value(record, ['batch_id', 'batchId']);
    if (batchId.isEmpty) return '';
    final batch = _batches.firstWhere(
      (item) => _id(item) == batchId,
      orElse: () => const {},
    );
    return _value(batch, ['farm_id', 'farmId']);
  }

  List<FlSpot> _trendFromRecords(
    List<Map<String, dynamic>> records,
    List<String> dateKeys,
    List<String> valueKeys,
  ) {
    final filtered = records.where((record) {
      if (_selectedFarm == 'All Farms') return true;
      final selectedFarmId = _selectedFarmId;
      return selectedFarmId.isNotEmpty &&
          _recordFarmId(record) == selectedFarmId;
    });
    final buckets = List<double>.filled(6, 0);
    final now = DateTime.now();
    for (final record in filtered) {
      final date = _date(record, dateKeys) ?? now;
      final diff = now.difference(date).inDays;
      final index = 5 - (diff ~/ 7).clamp(0, 5);
      buckets[index] += _number(record, valueKeys);
    }
    final maxValue = buckets.fold<double>(0, math.max);
    if (maxValue <= 0) {
      return List.generate(6, (index) => FlSpot(index.toDouble(), 0));
    }
    return List.generate(
      6,
      (index) => FlSpot(index.toDouble(), (buckets[index] / maxValue) * 100),
    );
  }

  String _money(double value) {
    if (value >= 1000000) return 'GHS ${(value / 1000000).toStringAsFixed(2)}M';
    if (value >= 1000) return 'GHS ${(value / 1000).toStringAsFixed(1)}K';
    return 'GHS ${value.toStringAsFixed(0)}';
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi, required this.isDark});

  final _AnalyticsKpi kpi;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kpi.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(kpi.icon, color: kpi.color, size: 25),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kpi.value,
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  kpi.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.64)
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  kpi.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.50)
                        : AppColors.textSecondary,
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

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.title,
    required this.revenueSpots,
    required this.productionSpots,
    required this.isDark,
  });

  final String title;
  final List<FlSpot> revenueSpots;
  final List<FlSpot> productionSpots;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: title,
            subtitle: 'Six-week normalized trend from backend records.',
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        const labels = [
                          'W-5',
                          'W-4',
                          'W-3',
                          'W-2',
                          'W-1',
                          'Now'
                        ];
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          labels[index],
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.54)
                                : AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _line(AppColors.success, revenueSpots),
                  _line(AppColors.primary, productionSpots),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Wrap(
            spacing: AppSpacing.md,
            children: [
              _Legend(label: 'Revenue Index', color: AppColors.success),
              _Legend(label: 'Production Index', color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  LineChartBarData _line(Color color, List<FlSpot> spots) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      belowBarData:
          BarAreaData(show: true, color: color.withValues(alpha: 0.10)),
    );
  }
}

class _SensorReliabilityChart extends StatelessWidget {
  const _SensorReliabilityChart({required this.isDark, required this.bars});

  final bool isDark;
  final List<_BarMetric> bars;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Sensor Reliability',
            subtitle: 'Live telemetry health grouped by sensor type.',
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: 100,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= bars.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          bars[index].label,
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.54)
                                : AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var i = 0; i < bars.length; i++)
                    _bar(i, bars[i].value, bars[i].color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          width: 24,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [color.withValues(alpha: 0.62), color],
          ),
        ),
      ],
    );
  }
}

class _FarmComparisonCard extends StatelessWidget {
  const _FarmComparisonCard({
    required this.farm,
    required this.isDark,
    required this.onSelect,
  });

  final _FarmAnalytics farm;
  final bool isDark;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(18),
        mouseCursor: SystemMouseCursors.click,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.025)
                : AppColors.neutral50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      farm.name,
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  _ScopeChip(
                    icon: Icons.shield_rounded,
                    label: farm.risk,
                    color: farm.color,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _MetricColumn(
                      label: 'Revenue',
                      value: farm.revenue >= 1000
                          ? 'GHS ${(farm.revenue / 1000).toStringAsFixed(1)}K'
                          : 'GHS ${farm.revenue.toStringAsFixed(0)}',
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _MetricColumn(
                      label: 'Production',
                      value:
                          '${(farm.productionKg / 1000).toStringAsFixed(1)}K kg',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _ProgressLine(
                label: 'Efficiency',
                value: farm.efficiency,
                color: AppColors.warning,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ProgressLine(
                label: 'Sensor health',
                value: farm.sensorHealth,
                color: AppColors.info,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ProgressLine(
                label: 'Yield / acre',
                value: farm.yieldPerAcre,
                color: AppColors.primary,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _ScopeChip(
                    icon: Icons.grain_rounded,
                    label: '${farm.batchCount} batches',
                    color: AppColors.primary,
                  ),
                  _ScopeChip(
                    icon: Icons.receipt_long_rounded,
                    label: '${farm.salesCount} sales',
                    color: AppColors.success,
                  ),
                  _ScopeChip(
                    icon: Icons.trending_down_rounded,
                    label: '${farm.lossHeads.toStringAsFixed(0)} loss heads',
                    color: AppColors.error,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final String label;
  final int value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final progress = (value / 100).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.64)
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$value%',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyLarge.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isDark
                ? Colors.white.withValues(alpha: 0.58)
                : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight, required this.isDark});

  final _InsightItem insight;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.025)
            : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(insight.icon, color: insight.color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  insight.detail,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.62)
                        : AppColors.textSecondary,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: isDark
                ? Colors.white.withValues(alpha: 0.62)
                : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

BoxDecoration _cardDecoration(bool isDark) {
  return BoxDecoration(
    color: isDark ? AppColors.surfaceDark : Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : AppColors.neutral300.withValues(alpha: 0.72),
    ),
    boxShadow: [
      if (!isDark)
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 20,
          offset: const Offset(0, 12),
        ),
    ],
  );
}

Color _barColor(double value) {
  if (value >= 85) return AppColors.success;
  if (value >= 65) return AppColors.warning;
  return AppColors.error;
}

String _shortLabel(String value) {
  final cleaned = value.trim();
  if (cleaned.length <= 6) return cleaned;
  return cleaned.substring(0, 6);
}

String _id(Map<String, dynamic> item) => _value(item, ['id', '\$id', '_id']);

String _value(Map<String, dynamic> item, List<String> keys) {
  for (final key in keys) {
    final value = item[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return '';
}

String _text(
  Map<String, dynamic> item,
  List<String> keys, {
  String fallback = '',
}) {
  final value = _value(item, keys);
  return value.isEmpty ? fallback : value;
}

String _status(Map<String, dynamic> item, List<String> keys) =>
    _value(item, keys).toLowerCase().trim();

double _number(Map<String, dynamic> item, List<String> keys) {
  for (final key in keys) {
    final value = item[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return 0;
}

DateTime? _date(Map<String, dynamic> item, List<String> keys) {
  for (final key in keys) {
    final value = item[key];
    if (value is DateTime) return value;
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

class _AnalyticsTotals {
  const _AnalyticsTotals({
    required this.revenue,
    required this.productionKg,
    required this.inventoryValue,
    required this.efficiency,
    required this.sensorHealth,
    required this.losses,
  });

  final double revenue;
  final double productionKg;
  final double inventoryValue;
  final int efficiency;
  final int sensorHealth;
  final double losses;
}

class _FarmAnalytics {
  const _FarmAnalytics({
    required this.id,
    required this.name,
    required this.revenue,
    required this.productionKg,
    required this.inventoryValue,
    required this.efficiency,
    required this.yieldPerAcre,
    required this.sensorHealth,
    required this.batchCount,
    required this.salesCount,
    required this.lossHeads,
    required this.risk,
    required this.color,
  });

  final String id;
  final String name;
  final double revenue;
  final double productionKg;
  final double inventoryValue;
  final int efficiency;
  final int yieldPerAcre;
  final int sensorHealth;
  final int batchCount;
  final int salesCount;
  final double lossHeads;
  final String risk;
  final Color color;
}

class _AnalyticsKpi {
  const _AnalyticsKpi({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
}

class _InsightItem {
  const _InsightItem({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;
}

class _BarMetric {
  const _BarMetric(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

class _ControlAction {
  const _ControlAction(this.label, this.icon, this.route, this.color);

  final String label;
  final IconData icon;
  final String route;
  final Color color;
}

class _MobileNavItem {
  const _MobileNavItem(this.icon, this.label, this.route);

  final IconData icon;
  final String label;
  final String route;
}
