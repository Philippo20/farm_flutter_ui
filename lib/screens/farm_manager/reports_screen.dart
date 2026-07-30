import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_manager_sidebar.dart';
import '../../core/widgets/farm_manager_header.dart';
import '../../core/widgets/farm_manager_mobile_drawer.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Reports Screen for Farm Manager
/// View comprehensive farm reports and analytics
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final SuperAdminApiService _api = SuperAdminApiService();
  int _selectedNavIndex = 6;
  String _selectedPeriod = 'Last 30 Days';
  String _selectedFarm = 'All Farms';
  String _selectedReportType = 'Production';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, dynamic>> _farms = [];
  final List<Map<String, dynamic>> _batches = [];
  final List<Map<String, dynamic>> _inventory = [];
  final List<Map<String, dynamic>> _fulfillments = [];
  final List<Map<String, dynamic>> _sales = [];
  final List<Map<String, dynamic>> _fundRequests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  String _docId(Map<String, dynamic> doc) =>
      (doc[r'$id'] ?? doc['id'] ?? doc['farmID'] ?? doc['farm_id'] ?? '')
          .toString();

  String _value(Map<String, dynamic> doc, List<String> keys,
      {String fallback = ''}) {
    for (final key in keys) {
      final value = doc[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  double _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _dateValue(Map<String, dynamic> doc, List<String> keys) {
    for (final key in keys) {
      final value = doc[key];
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  DateTime get _periodStart {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Last 7 Days':
        return now.subtract(const Duration(days: 7));
      case 'Last 90 Days':
        return now.subtract(const Duration(days: 90));
      case 'This Year':
        return DateTime(now.year);
      case 'Last 30 Days':
      default:
        return now.subtract(const Duration(days: 30));
    }
  }

  bool _withinPeriod(Map<String, dynamic> doc, List<String> dateKeys) {
    final date = _dateValue(doc, dateKeys);
    if (date == null) return true;
    return !date.isBefore(_periodStart);
  }

  bool _belongsToCurrentManager(Map<String, dynamic> doc) {
    final user = ref.read(authProvider).user;
    if (user == null) return true;
    final manager = _value(doc, [
      'farm_manager_id',
      'farmManagerId',
      'created_by',
      'requested_by_id',
    ]);
    return manager.isEmpty ||
        manager == user.id ||
        manager == user.email ||
        manager == user.name;
  }

  List<String> get _farmOptions {
    final names = _farms
        .map((farm) => _value(farm, ['name', 'farm_name'], fallback: 'Farm'))
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All Farms', ...names];
  }

  bool _matchesSelectedFarm(Map<String, dynamic> doc) {
    if (_selectedFarm == 'All Farms') return true;
    final farmName = _value(doc, ['farm_name', 'name']);
    final farmId = _value(doc, ['farmID', 'farm_id', 'farmId']);
    return farmName == _selectedFarm ||
        _farms.any((farm) =>
            _value(farm, ['name', 'farm_name']) == _selectedFarm &&
            _docId(farm) == farmId);
  }

  bool _batchMatchesFarm(
      Map<String, dynamic> batch, Map<String, dynamic> farm) {
    final farmName = _value(farm, ['name', 'farm_name']);
    final farmId = _docId(farm);
    return _value(batch, ['farm_name']) == farmName ||
        _value(batch, ['farmID', 'farm_id', 'farmId']) == farmId;
  }

  List<Map<String, dynamic>> get _visibleBatches => _batches
      .where(_belongsToCurrentManager)
      .where(_matchesSelectedFarm)
      .where((item) => _withinPeriod(item, ['created_at', 'start_date']))
      .toList();

  List<Map<String, dynamic>> get _visibleInventory => _inventory
      .where(_matchesSelectedFarm)
      .where((item) => _withinPeriod(item, ['date_added']))
      .toList();

  List<Map<String, dynamic>> get _visibleFulfillments => _fulfillments
      .where(_belongsToCurrentManager)
      .where(_matchesSelectedFarm)
      .where((item) => _withinPeriod(item, [
            'scheduled_date',
            'packaging_date_time',
            'received_date_time',
          ]))
      .toList();

  Set<String> get _visibleBatchRefs => _visibleBatches
      .expand((batch) => [
            _docId(batch),
            _value(batch, ['batch_id']),
            _value(batch, ['batch_no', 'batch_number']),
          ])
      .where((item) => item.trim().isNotEmpty)
      .toSet();

  List<Map<String, dynamic>> get _visibleSales => _sales.where((sale) {
        if (!_withinPeriod(sale, ['delivered_at', 'payment_date'])) {
          return false;
        }
        if (_selectedFarm == 'All Farms') return true;
        final batchRef = _value(sale, ['batch_id', 'batch_number']);
        return _visibleBatchRefs.contains(batchRef);
      }).toList();

  List<Map<String, dynamic>> get _visibleFundRequests => _fundRequests
      .where(_belongsToCurrentManager)
      .where(_matchesSelectedFarm)
      .where((item) => _withinPeriod(item, ['request_date', 'updated_at']))
      .toList();

  double get _totalProductionKg => _visibleBatches.fold<double>(
        0,
        (total, item) => total + _doubleValue(item['total_weight_kg']),
      );

  double get _totalRevenue => _visibleSales.fold<double>(
        0,
        (total, item) => total + _doubleValue(item['total_amount']),
      );

  int get _activeBatchCount => _visibleBatches.where((batch) {
        final status =
            _value(batch, ['production_status', 'status']).toLowerCase();
        return status != 'completed' &&
            status != 'delivered' &&
            status != 'harvested';
      }).length;

  double get _efficiency {
    final seeds = _visibleBatches.fold<double>(
      0,
      (total, item) => total + _doubleValue(item['total_seeds_nursed']),
    );
    final harvested = _visibleBatches.fold<double>(
      0,
      (total, item) => total + _doubleValue(item['total_harvested']),
    );
    if (seeds <= 0) return 0;
    return (harvested / seeds * 100).clamp(0, 100);
  }

  String _compactNumber(double value, {String suffix = ''}) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M$suffix';
    }
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K$suffix';
    return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}$suffix';
  }

  List<Map<String, dynamic>> get _summaryStats => [
        {
          'title': 'Total Production',
          'value': _compactNumber(_totalProductionKg, suffix: ' kg'),
          'change': '${_visibleBatches.length} batches',
          'color': AppColors.primary,
          'icon': Icons.inventory,
        },
        {
          'title': 'Revenue',
          'value': 'GHS ${_compactNumber(_totalRevenue)}',
          'change':
              '${_visibleSales.length} sales, ${_visibleFundRequests.length} requests',
          'color': AppColors.success,
          'icon': Icons.attach_money,
        },
        {
          'title': 'Active Batches',
          'value': '$_activeBatchCount',
          'change': '${_visibleFulfillments.length} deliveries',
          'color': AppColors.info,
          'icon': Icons.grid_view,
        },
        {
          'title': 'Efficiency',
          'value': '${_efficiency.toStringAsFixed(1)}%',
          'change': '${_visibleInventory.length} inventory items',
          'color': AppColors.warning,
          'icon': Icons.trending_up,
        },
      ];

  List<FlSpot> get _productionSpots {
    final buckets = List<double>.filled(6, 0);
    final now = DateTime.now();
    for (final batch in _visibleBatches) {
      final date = _dateValue(
              batch, ['actual_harvest_date', 'created_at', 'start_date']) ??
          now;
      final monthOffset = (now.year - date.year) * 12 + now.month - date.month;
      final index = 5 - monthOffset;
      if (index >= 0 && index < buckets.length) {
        buckets[index] += _doubleValue(batch['total_weight_kg']) / 1000;
      }
    }
    return List.generate(
        6, (index) => FlSpot(index.toDouble(), buckets[index]));
  }

  List<String> get _productionLabels {
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
      'Dec'
    ];
    final now = DateTime.now();
    return List.generate(6, (index) {
      final month = DateTime(now.year, now.month - (5 - index));
      return months[month.month - 1];
    });
  }

  List<Map<String, dynamic>> get _farmReportRows {
    final sourceFarms = _selectedFarm == 'All Farms'
        ? _farms
        : _farms
            .where(
                (farm) => _value(farm, ['name', 'farm_name']) == _selectedFarm)
            .toList();
    return sourceFarms.map((farm) {
      final batches = _visibleBatches
          .where((batch) => _batchMatchesFarm(batch, farm))
          .toList();
      final batchRefs = batches
          .expand((batch) => [
                _docId(batch),
                _value(batch, ['batch_id']),
                _value(batch, ['batch_no', 'batch_number']),
              ])
          .where((item) => item.trim().isNotEmpty)
          .toSet();
      final sales = _visibleSales
          .where((sale) =>
              batchRefs.contains(_value(sale, ['batch_id', 'batch_number'])))
          .toList();
      final production = batches.fold<double>(
        0,
        (total, item) => total + _doubleValue(item['total_weight_kg']),
      );
      final revenue = sales.fold<double>(
        0,
        (total, item) => total + _doubleValue(item['total_amount']),
      );
      final seeds = batches.fold<double>(
        0,
        (total, item) => total + _doubleValue(item['total_seeds_nursed']),
      );
      final harvested = batches.fold<double>(
        0,
        (total, item) => total + _doubleValue(item['total_harvested']),
      );
      final efficiency =
          seeds <= 0 ? 0 : (harvested / seeds * 100).clamp(0, 100);
      final status = efficiency >= 90
          ? 'Excellent'
          : efficiency >= 75
              ? 'Good'
              : 'Fair';
      return {
        'farm': _value(farm, ['name', 'farm_name'], fallback: 'Farm'),
        'production': _compactNumber(production, suffix: ' kg'),
        'revenue': 'GHS ${_compactNumber(revenue)}',
        'efficiency': '${efficiency.toStringAsFixed(1)}%',
        'status': status,
      };
    }).toList();
  }

  List<Map<String, dynamic>> get _distributionRows {
    final rows = (_selectedFarm == 'All Farms'
            ? _farms
            : _farms
                .where((farm) =>
                    _value(farm, ['name', 'farm_name']) == _selectedFarm)
                .toList())
        .map((farm) {
          final production = _visibleBatches
              .where((batch) => _batchMatchesFarm(batch, farm))
              .fold<double>(
                0,
                (total, item) => total + _doubleValue(item['total_weight_kg']),
              );
          return {
            'label': _value(farm, ['name', 'farm_name'], fallback: 'Farm'),
            'value': production,
          };
        })
        .where((row) => (row['value'] as double) > 0)
        .toList();
    if (rows.isEmpty) {
      return [
        {'label': 'No production', 'value': 1.0}
      ];
    }
    return rows.take(4).toList();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _api.getFarms(),
        _api.getBatches(),
        _api.getInventory(),
        _api.getFulfillments(),
        _api.getSales(),
        _api.getFundRequests(),
      ]);
      if (!mounted) return;
      setState(() {
        _farms
          ..clear()
          ..addAll(results[0].where(_belongsToCurrentManager));
        _batches
          ..clear()
          ..addAll(results[1]);
        _inventory
          ..clear()
          ..addAll(results[2]);
        _fulfillments
          ..clear()
          ..addAll(results[3]);
        _sales
          ..clear()
          ..addAll(results[4]);
        _fundRequests
          ..clear()
          ..addAll(results[5]);
        if (!_farmOptions.contains(_selectedFarm)) {
          _selectedFarm = 'All Farms';
        }
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Farm Manager';
    final userEmail = authState.user?.email ?? 'manager@farmestates.com';
    final userRole = 'Farm Manager';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? FarmManagerMobileDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
              userName: userName,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      bottomNavigationBar: isMobile
          ? SafeArea(top: false, child: _buildBottomNavigation(isDark))
          : null,
    );
  }

  Widget _buildDesktopLayout(
      bool isDark, String userName, String userEmail, String userRole) {
    return Row(
      children: [
        FarmManagerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) {
            setState(() => _selectedNavIndex = index);
          },
          userName: userName,
          userEmail: userEmail,
          userRole: userRole,
        ),
        Expanded(
          child: Column(
            children: [
              FarmManagerHeader(
                userName: userName,
                onNotificationTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: _buildContent(isDark, isMobile: false),
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
        FarmManagerHeader(
          userName: userName,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildContent(isDark, isMobile: true),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark, {required bool isMobile}) {
    if (_isLoading) {
      return const AdminDataSkeleton(rowCount: 6);
    }
    if (_errorMessage != null) {
      return _buildErrorState(isDark);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isMobile ? _buildMobileHeader(isDark) : _buildHeader(isDark),
        SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.xl),
        if (isMobile) ...[
          _buildMobileActionButtons(isDark),
          const SizedBox(height: AppSpacing.lg),
        ],
        _buildFilters(isDark),
        SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
        _buildSummaryCards(isDark),
        SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
        _buildChartsSection(isDark),
        SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
        _buildReportTable(isDark),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 42, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Unable to load reports',
              style: AppTypography.h6.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadReportData,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Farm Reports',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Analytics and performance metrics',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showExportDialog(context, isDark),
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showPrintDialog(context, isDark),
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Print', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showScheduleReportDialog(context, isDark),
            icon: const Icon(Icons.schedule, size: 16),
            label: const Text('Schedule', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Farm Reports',
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Comprehensive analytics and performance metrics',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _showScheduleReportDialog(context, isDark),
              icon: const Icon(Icons.schedule, size: 18),
              label: const Text('Schedule'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: () => _showExportDialog(context, isDark),
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: () => _showPrintDialog(context, isDark),
              icon: const Icon(Icons.print, size: 18),
              label: const Text('Print'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  side: BorderSide(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withOpacity(0.08)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: isMobile
          ? Column(
              children: [
                _buildFilterDropdown(
                    'Period',
                    _selectedPeriod,
                    [
                      'Last 7 Days',
                      'Last 30 Days',
                      'Last 90 Days',
                      'This Year'
                    ],
                    (v) => setState(() => _selectedPeriod = v!),
                    isDark),
                const SizedBox(height: AppSpacing.sm),
                _buildFilterDropdown('Farm', _selectedFarm, _farmOptions,
                    (v) => setState(() => _selectedFarm = v!), isDark),
                const SizedBox(height: AppSpacing.sm),
                _buildFilterDropdown(
                    'Report Type',
                    _selectedReportType,
                    ['Production', 'Financial', 'Inventory', 'Performance'],
                    (v) => setState(() => _selectedReportType = v!),
                    isDark),
              ],
            )
          : Row(
              children: [
                Expanded(
                    child: _buildFilterDropdown(
                        'Period',
                        _selectedPeriod,
                        [
                          'Last 7 Days',
                          'Last 30 Days',
                          'Last 90 Days',
                          'This Year'
                        ],
                        (v) => setState(() => _selectedPeriod = v!),
                        isDark)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: _buildFilterDropdown(
                        'Farm',
                        _selectedFarm,
                        _farmOptions,
                        (v) => setState(() => _selectedFarm = v!),
                        isDark)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: _buildFilterDropdown(
                        'Report Type',
                        _selectedReportType,
                        ['Production', 'Financial', 'Inventory', 'Performance'],
                        (v) => setState(() => _selectedReportType = v!),
                        isDark)),
              ],
            ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> items,
      Function(String?) onChanged, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : AppColors.neutral100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
                color:
                    isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
          ),
          child: DropdownButton<String>(
            value: value,
            items: items
                .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item,
                        style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary))))
                .toList(),
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down,
                color: isDark ? Colors.white54 : AppColors.textSecondary),
            dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: isMobile ? 2.5 : 3.0,
          children: _summaryStats
              .map((stat) => _buildSummaryCard(
                    stat['title'] as String,
                    stat['value'] as String,
                    stat['change'] as String,
                    stat['color'] as Color,
                    stat['icon'] as IconData,
                    isDark,
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, String change,
      Color color, IconData icon, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Card(
      elevation: 0,
      color: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isDark ? 0.15 : 0.9),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: color, size: isMobile ? 18 : 22),
            ),
            SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 9 : 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: AppTypography.h6.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: isMobile ? 14 : 18,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 4 : 6, vertical: isMobile ? 2 : 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isDark ? 0.15 : 0.9),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_upward,
                      size: isMobile ? 8 : 10, color: AppColors.success),
                  SizedBox(width: isMobile ? 1 : 2),
                  Text(change,
                      style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 8 : 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildProductionChart(isDark, isMobile)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _buildDistributionChart(isDark, isMobile)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildProductionChart(isDark, isMobile),
              const SizedBox(height: AppSpacing.md),
              _buildDistributionChart(isDark, isMobile),
            ],
          );
        }
      },
    );
  }

  Widget _buildProductionChart(bool isDark, bool isMobile) {
    final spots = _productionSpots;
    final labels = _productionLabels;
    final maxValue = spots.fold<double>(
      1,
      (max, spot) => spot.y > max ? spot.y : max,
    );

    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Production Trend',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: isMobile ? 14 : 18,
              ),
            ),
            SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
            SizedBox(
              height: isMobile ? 180 : 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withOpacity(0.05),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: isMobile ? 34 : 44,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toStringAsFixed(1)}K',
                          style: TextStyle(
                              fontSize: isMobile ? 9 : 10,
                              color: isDark
                                  ? Colors.white60
                                  : AppColors.textSecondary),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: isMobile ? 25 : 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < labels.length) {
                            return Text(
                              labels[index],
                              style: TextStyle(
                                  fontSize: isMobile ? 9 : 10,
                                  color: isDark
                                      ? Colors.white60
                                      : AppColors.textSecondary),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withOpacity(0.1)),
                    ),
                  ],
                  minY: 0,
                  maxY: maxValue <= 0 ? 1 : maxValue * 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionChart(bool isDark, bool isMobile) {
    final rows = _distributionRows;
    final total = rows.fold<double>(
      0,
      (sum, row) => sum + (row['value'] as double),
    );
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.info,
      AppColors.warning,
    ];

    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farm Distribution',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: isMobile ? 14 : 18,
              ),
            ),
            SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
            SizedBox(
              height: isMobile ? 180 : 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: isMobile ? 30 : 40,
                  sections: rows.asMap().entries.map((entry) {
                    final value = entry.value['value'] as double;
                    final percent = total <= 0 ? 0 : (value / total * 100);
                    return PieChartSectionData(
                      value: value,
                      title: '${percent.toStringAsFixed(0)}%',
                      color: colors[entry.key % colors.length],
                      radius: isMobile ? 40 : 60,
                      titleStyle: TextStyle(
                        fontSize: isMobile ? 10 : 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: rows.asMap().entries.map((entry) {
                return _buildLegendItem(
                  entry.value['label'].toString(),
                  colors[entry.key % colors.length],
                  isDark,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white70 : AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildReportTable(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final reports = _farmReportRows;

    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Farm Performance Summary',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: isMobile ? 14 : 18,
                  ),
                ),
                if (!isMobile)
                  TextButton.icon(
                    onPressed: _loadReportData,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                  ),
              ],
            ),
            SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
            if (reports.isEmpty)
              _buildEmptyState(isDark)
            else if (isMobile)
              Column(
                children: reports
                    .map((r) => _buildMobileReportCard(r, isDark))
                    .toList(),
              )
            else
              Table(
                border: TableBorder.all(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.08)),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.03)
                            : AppColors.neutral50),
                    children: [
                      _buildTableCell('Farm', true, isDark),
                      _buildTableCell('Production', true, isDark),
                      _buildTableCell('Revenue', true, isDark),
                      _buildTableCell('Efficiency', true, isDark),
                      _buildTableCell('Status', true, isDark),
                      _buildTableCell('Actions', true, isDark),
                    ],
                  ),
                  ...reports.map((r) => TableRow(
                        children: [
                          _buildTableCell(r['farm']!, false, isDark),
                          _buildTableCell(r['production']!, false, isDark),
                          _buildTableCell(r['revenue']!, false, isDark),
                          _buildTableCell(r['efficiency']!, false, isDark),
                          _buildTableCell(r['status']!, false, isDark,
                              isStatus: true),
                          _buildTableActions(r, isDark),
                        ],
                      )),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(Icons.assessment_outlined,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
              size: 34),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No report data for this filter',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try another period or farm.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileReportCard(Map<String, dynamic> report, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(report['farm']!,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : AppColors.textPrimary)),
              ),
              _buildStatusBadge(report['status']!, isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildMobileReportStat(
                    'Production', report['production']!, isDark),
              ),
              Expanded(
                child: _buildMobileReportStat(
                    'Revenue', report['revenue']!, isDark),
              ),
              Expanded(
                child: _buildMobileReportStat(
                    'Efficiency', report['efficiency']!, isDark),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('Details', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileReportStat(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white54 : AppColors.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    final statusColor = status == 'Excellent'
        ? AppColors.success
        : status == 'Good'
            ? AppColors.info
            : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        status,
        style: TextStyle(
            color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTableCell(String text, bool isHeader, bool isDark,
      {bool isStatus = false}) {
    if (isStatus) {
      final statusColor = text == 'Excellent'
          ? AppColors.success
          : text == 'Good'
              ? AppColors.info
              : AppColors.warning;
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            text,
            style: TextStyle(
                color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 12 : 13,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTableActions(Map<String, dynamic> report, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.visibility, size: 18),
            tooltip: 'View Details',
            color: AppColors.info,
          ),
          IconButton(
            onPressed: () => _showExportDialog(context, isDark),
            icon: const Icon(Icons.download, size: 18),
            tooltip: 'Export',
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ============= DIALOGS =============

  void _showExportDialog(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    String selectedFormat = 'PDF';
    bool includeCharts = true;
    bool includeTable = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl,
              vertical: AppSpacing.xl),
          child: Container(
            width: isMobile ? double.infinity : 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8)
                    ]),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd)),
                        child: const Icon(Icons.download,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Export Report',
                                style: AppTypography.h6.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            Text('Download farm analytics',
                                style: AppTypography.bodySmall
                                    .copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Export Format',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                              child: _buildExportFormatOption(
                                  'PDF',
                                  Icons.picture_as_pdf,
                                  selectedFormat == 'PDF',
                                  isDark,
                                  () => setDialogState(
                                      () => selectedFormat = 'PDF'))),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                              child: _buildExportFormatOption(
                                  'Excel',
                                  Icons.table_chart,
                                  selectedFormat == 'Excel',
                                  isDark,
                                  () => setDialogState(
                                      () => selectedFormat = 'Excel'))),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                              child: _buildExportFormatOption(
                                  'CSV',
                                  Icons.description,
                                  selectedFormat == 'CSV',
                                  isDark,
                                  () => setDialogState(
                                      () => selectedFormat = 'CSV'))),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Include in Export',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.sm),
                      _buildExportCheckbox(
                          'Charts & Graphs',
                          includeCharts,
                          (v) => setDialogState(() => includeCharts = v!),
                          isDark),
                      _buildExportCheckbox(
                          'Data Tables',
                          includeTable,
                          (v) => setDialogState(() => includeTable = v!),
                          isDark),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                              color: AppColors.info.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: AppColors.info, size: 18),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                                child: Text(
                                    'Export will include data for: $_selectedPeriod, $_selectedFarm',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white70
                                            : AppColors.textSecondary))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.03)
                        : AppColors.neutral50,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md)),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text('Report exported as $selectedFormat')
                                ]),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.download, size: 18),
                          label: Text('Export $selectedFormat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportFormatOption(String format, IconData icon, bool isSelected,
      bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : (isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? Colors.white10 : AppColors.neutral200)),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white54 : AppColors.textSecondary),
                size: 24),
            const SizedBox(height: 4),
            Text(format,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? Colors.white : AppColors.textPrimary))),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCheckbox(
      String label, bool value, Function(bool?) onChanged, bool isDark) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(label,
          style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : AppColors.textPrimary)),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeColor: AppColors.primary,
    );
  }

  void _showPrintDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Row(
          children: [
            Icon(Icons.print, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text('Print Report',
                style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary)),
          ],
        ),
        content: Text(
          'This will send the current report to your default printer.\n\nPeriod: $_selectedPeriod\nFarm: $_selectedFarm\nReport Type: $_selectedReportType',
          style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text('Report sent to printer')
                  ]),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Print'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showScheduleReportDialog(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    String frequency = 'Weekly';
    String deliveryMethod = 'Email';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl,
              vertical: AppSpacing.xl),
          child: Container(
            width: isMobile ? double.infinity : 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.info,
                      AppColors.info.withOpacity(0.8)
                    ]),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd)),
                        child: const Icon(Icons.schedule,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Schedule Report',
                                style: AppTypography.h6.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            Text('Automate report delivery',
                                style: AppTypography.bodySmall
                                    .copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Frequency',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: ['Daily', 'Weekly', 'Monthly']
                            .map((f) => ChoiceChip(
                                  label: Text(f),
                                  selected: frequency == f,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setDialogState(() => frequency = f);
                                    }
                                  },
                                  selectedColor:
                                      AppColors.info.withOpacity(0.2),
                                  labelStyle: TextStyle(
                                      color: frequency == f
                                          ? AppColors.info
                                          : (isDark
                                              ? Colors.white70
                                              : AppColors.textSecondary)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Delivery Method',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: ['Email', 'Dashboard', 'Both']
                            .map((m) => ChoiceChip(
                                  label: Text(m),
                                  selected: deliveryMethod == m,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setDialogState(() => deliveryMethod = m);
                                    }
                                  },
                                  selectedColor:
                                      AppColors.info.withOpacity(0.2),
                                  labelStyle: TextStyle(
                                      color: deliveryMethod == m
                                          ? AppColors.info
                                          : (isDark
                                              ? Colors.white70
                                              : AppColors.textSecondary)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : AppColors.neutral50,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Report Settings',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary)),
                            const SizedBox(height: AppSpacing.sm),
                            _buildScheduleInfoRow(
                                'Report Type', _selectedReportType, isDark),
                            _buildScheduleInfoRow(
                                'Farm', _selectedFarm, isDark),
                            _buildScheduleInfoRow(
                                'Period', _selectedPeriod, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.03)
                        : AppColors.neutral50,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md)),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                      'Report scheduled: $frequency via $deliveryMethod')
                                ]),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.schedule, size: 18),
                          label: const Text('Schedule'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.info,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/farm-manager'
      },
      {
        'icon': Icons.agriculture_outlined,
        'label': 'Farms',
        'index': 1,
        'route': '/farm-manager/farms'
      },
      {
        'icon': Icons.inventory_2_outlined,
        'label': 'Inventory',
        'index': 2,
        'route': '/farm-manager/inventory'
      },
      {
        'icon': Icons.local_shipping_outlined,
        'label': 'Deliveries',
        'index': 3,
        'route': '/farm-manager/deliveries'
      },
      {
        'icon': Icons.assessment_outlined,
        'label': 'Reports',
        'index': 4,
        'route': '/farm-manager/reports'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final isSelected = index == 4; // Reports is active

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_selectedNavIndex != index) {
                        setState(() => _selectedNavIndex = index);
                        try {
                          Navigator.pushReplacementNamed(context, route);
                        } catch (e) {
                          debugPrint('Navigation error: $e');
                        }
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 24,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : AppColors.textSecondary),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
