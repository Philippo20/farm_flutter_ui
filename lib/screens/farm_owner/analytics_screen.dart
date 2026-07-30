import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_owner_sidebar.dart';
import '../../core/widgets/farm_owner_header.dart';
import '../../core/widgets/farm_owner_mobile_drawer.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Analytics Screen for Farm Owner
/// View farm performance analytics and insights
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final SuperAdminApiService _api = SuperAdminApiService();
  int _selectedNavIndex = 3;
  String _selectedPeriod = 'Last 30 Days';
  String _selectedCrop = 'All Crops';
  String _selectedInputType = 'All Inputs';
  final Map<String, int?> _touchedPieIndex = {};
  final Map<String, String> _cardFilters = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, dynamic>> _farms = [];
  final List<Map<String, dynamic>> _sales = [];
  final List<Map<String, dynamic>> _batches = [];
  final List<Map<String, dynamic>> _fulfillments = [];
  final List<Map<String, dynamic>> _fundRequests = [];
  final List<Map<String, dynamic>> _sensorReadings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final results = await Future.wait([
        _api.getFarms(),
        _api.getSales(),
        _api.getBatches(),
        _api.getFulfillments(),
        _api.getFundRequests(),
        _api.getSensorReadingsAll(),
      ]);
      if (!mounted) return;
      setState(() {
        _farms
          ..clear()
          ..addAll(results[0]);
        _sales
          ..clear()
          ..addAll(results[1]);
        _batches
          ..clear()
          ..addAll(results[2]);
        _fulfillments
          ..clear()
          ..addAll(results[3]);
        _fundRequests
          ..clear()
          ..addAll(results[4]);
        _sensorReadings
          ..clear()
          ..addAll(results[5]);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted || !showLoading) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  String _docId(Map<String, dynamic> doc) =>
      (doc[r'$id'] ?? doc['id'] ?? doc['farm_id'] ?? doc['farmID'] ?? '')
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

  String _normalise(dynamic value) =>
      value?.toString().trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ??
      '';

  num _numValue(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
  }

  DateTime? _dateValue(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }

  DateTime get _periodStart {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Last 7 Days':
        return now.subtract(const Duration(days: 7));
      case 'Last 3 Months':
        return DateTime(now.year, now.month - 3, now.day);
      case 'Last Year':
        return DateTime(now.year - 1, now.month, now.day);
      case 'Last 30 Days':
      default:
        return now.subtract(const Duration(days: 30));
    }
  }

  bool _isWithinPeriod(DateTime? date) {
    if (date == null) return true;
    return !date.isBefore(_periodStart);
  }

  bool _isOwnerFarm(Map<String, dynamic> farm) {
    final user = ref.read(authProvider).user;
    if (user == null) return true;
    final ownerTokens = {
      _normalise(user.id),
      _normalise(user.email),
      _normalise(user.name),
    }..removeWhere((token) => token.isEmpty);
    final farmTokens = {
      _normalise(_value(farm, ['ownerID', 'owner_id', 'ownerId'])),
      _normalise(_value(farm, ['owner_name', 'ownerName'])),
      _normalise(_value(farm, ['owner_email', 'ownerEmail'])),
    }..removeWhere((token) => token.isEmpty || token == 'unassigned');
    return farmTokens.any(ownerTokens.contains);
  }

  List<Map<String, dynamic>> get _ownerFarms =>
      _farms.where(_isOwnerFarm).toList();

  Set<String> get _ownerFarmIds =>
      _ownerFarms.map(_docId).where((id) => id.isNotEmpty).toSet();

  Set<String> get _ownerFarmNames => _ownerFarms
      .map((farm) => _value(farm, ['name', 'farm_name']))
      .where((name) => name.isNotEmpty)
      .map(_normalise)
      .toSet();

  Set<String> get _ownerBatchIds => _batches
      .where((batch) {
        final farmId = _value(batch, ['farm_id', 'farmID', 'farmId']);
        final farmName = _value(batch, ['farm_name', 'farmName']);
        return (farmId.isNotEmpty && _ownerFarmIds.contains(farmId)) ||
            (farmName.isNotEmpty &&
                _ownerFarmNames.contains(_normalise(farmName)));
      })
      .expand((batch) => [
            _value(batch, ['batch_id']),
            _value(batch, ['batch_no']),
            _value(batch, ['batch_number']),
            _docId(batch),
          ])
      .where((id) => id.isNotEmpty)
      .toSet();

  bool _matchesOwnerFarm(Map<String, dynamic> doc) {
    final farmId = _value(doc, ['farm_id', 'farmID', 'farmId']);
    final farmName = _value(doc, ['farm_name', 'farmName']);
    final batchId = _value(doc, ['batch_id', 'batch_no', 'batch_number']);
    return (farmId.isNotEmpty && _ownerFarmIds.contains(farmId)) ||
        (farmName.isNotEmpty &&
            _ownerFarmNames.contains(_normalise(farmName))) ||
        (batchId.isNotEmpty && _ownerBatchIds.contains(batchId));
  }

  bool _matchesSelectedCrop(Map<String, dynamic> doc) {
    if (_selectedCrop == 'All Crops') return true;
    final crop = _normalise(_value(
      doc,
      ['plant_name', 'plant_type', 'crop_variety', 'plant_variety'],
    ));
    return crop == _normalise(_selectedCrop);
  }

  List<Map<String, dynamic>> get _ownerSales => _sales.where((sale) {
        return _matchesOwnerFarm(sale) &&
            _isWithinPeriod(_dateValue(sale['payment_date'] ??
                sale['delivered_at'] ??
                sale[r'$createdAt']));
      }).toList();

  List<Map<String, dynamic>> get _ownerBatches => _batches.where((batch) {
        return _matchesOwnerFarm(batch) &&
            _matchesSelectedCrop(batch) &&
            _isWithinPeriod(
                _dateValue(batch['created_at'] ?? batch['start_date']));
      }).toList();

  List<Map<String, dynamic>> get _ownerFulfillments =>
      _fulfillments.where((fulfillment) {
        return _matchesOwnerFarm(fulfillment) &&
            _matchesSelectedCrop(fulfillment) &&
            _isWithinPeriod(_dateValue(fulfillment['packaging_date_time'] ??
                fulfillment['received_date_time'] ??
                fulfillment[r'$createdAt']));
      }).toList();

  List<Map<String, dynamic>> get _ownerFundRequests =>
      _fundRequests.where((request) {
        return _matchesOwnerFarm(request) &&
            _isWithinPeriod(
                _dateValue(request['request_date'] ?? request[r'$createdAt']));
      }).toList();

  List<Map<String, dynamic>> get _ownerSensorReadings =>
      _sensorReadings.where((reading) {
        return _matchesOwnerFarm(reading) &&
            _isWithinPeriod(_dateValue(reading['timestamp']));
      }).toList();

  List<String> get _cropFilterItems {
    final crops = <String>{};
    for (final farm in _ownerFarms) {
      final crop = _value(farm, ['plant_type', 'plant_variety']);
      if (crop.isNotEmpty) crops.add(crop);
    }
    for (final batch in _batches.where(_matchesOwnerFarm)) {
      final crop = _value(batch, ['plant_name', 'plant_type']);
      if (crop.isNotEmpty) crops.add(crop);
    }
    final sorted = crops.toList()..sort();
    return ['All Crops', ...sorted];
  }

  String _formatMoney(num value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return 'GHS $whole.${parts.last}';
  }

  String _formatCompactMoney(num value) {
    if (value.abs() >= 1000000) {
      return 'GHS ${(value / 1000000).toStringAsFixed(1)}m';
    }
    if (value.abs() >= 1000) {
      return 'GHS ${(value / 1000).toStringAsFixed(1)}k';
    }
    return _formatMoney(value);
  }

  num get _totalRevenue => _ownerSales.fold<num>(
        0,
        (sum, sale) => sum + _numValue(sale['total_amount'] ?? sale['amount']),
      );

  num get _totalYieldKg {
    final fulfillmentWeight = _ownerFulfillments.fold<num>(
      0,
      (sum, item) => sum + _numValue(item['total_weight']),
    );
    if (fulfillmentWeight > 0) return fulfillmentWeight;
    return _ownerBatches.fold<num>(
      0,
      (sum, batch) => sum + _numValue(batch['total_weight_kg']),
    );
  }

  num get _totalInputCost => _ownerFundRequests.fold<num>(
        0,
        (sum, request) => sum + _numValue(request['amount']),
      );

  num get _profitMargin {
    if (_totalRevenue <= 0) return 0;
    return ((_totalRevenue - _totalInputCost) / _totalRevenue) * 100;
  }

  num get _averageDailyRevenue {
    final days = DateTime.now().difference(_periodStart).inDays.clamp(1, 365);
    return _totalRevenue / days;
  }

  num get _averageYieldLoss {
    if (_ownerFulfillments.isEmpty) return 0;
    return _ownerFulfillments.fold<num>(
          0,
          (sum, item) => sum + _numValue(item['yield_loss_percentage']),
        ) /
        _ownerFulfillments.length;
  }

  List<_ChartSlice> _normalisedSlices(Map<String, num> values) {
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.info,
      AppColors.warning,
      AppColors.error,
    ];
    final entries = values.entries.where((entry) => entry.value > 0).toList();
    if (entries.isEmpty) {
      return const [
        _ChartSlice(color: AppColors.neutral400, value: 100, label: 'No data')
      ];
    }
    final total = entries.fold<num>(0, (sum, entry) => sum + entry.value);
    return entries.asMap().entries.map((entry) {
      return _ChartSlice(
        color: colors[entry.key % colors.length],
        value: (entry.value.value / total) * 100,
        label: entry.value.key,
      );
    }).toList();
  }

  Map<String, num> get _inputUsageValues {
    final values = <String, num>{
      'Seeds': 0,
      'Nutrients': 0,
      'Water': 0,
      'Packaging': 0,
    };
    for (final batch in _ownerBatches) {
      final inputs = _normalise(batch['inputs_supplied']);
      if (_selectedInputType != 'All Inputs' &&
          !inputs.contains(_normalise(_selectedInputType))) {
        continue;
      }
      if (inputs.contains('seed')) values['Seeds'] = values['Seeds']! + 1;
      if (inputs.contains('nutrient') || inputs.contains('fertil')) {
        values['Nutrients'] = values['Nutrients']! + 1;
      }
      if (inputs.contains('water')) values['Water'] = values['Water']! + 1;
    }
    final packagingWeight = _ownerFulfillments.fold<num>(
      0,
      (sum, item) => sum + _numValue(item['packaging_weight']),
    );
    values['Packaging'] = values['Packaging']! + packagingWeight;
    final waterReadings = _ownerSensorReadings
        .where((reading) => _normalise(reading['sensortype']).contains('water'))
        .fold<num>(0, (sum, reading) => sum + _numValue(reading['value']));
    values['Water'] = values['Water']! + waterReadings;
    return values;
  }

  Map<String, num> get _inputCostValues {
    final values = <String, num>{
      'Seeds': 0,
      'Nutrients': 0,
      'Water': 0,
      'Packaging': 0,
      'Other': 0,
    };
    for (final request in _ownerFundRequests) {
      final categoryText = _normalise(
          '${request['category']} ${request['purpose']} ${request['description']}');
      final amount = _numValue(request['amount']);
      if (_selectedInputType != 'All Inputs' &&
          !categoryText.contains(_normalise(_selectedInputType))) {
        continue;
      }
      if (categoryText.contains('seed') || categoryText.contains('input')) {
        values['Seeds'] = values['Seeds']! + amount;
      } else if (categoryText.contains('nutrient') ||
          categoryText.contains('fertil')) {
        values['Nutrients'] = values['Nutrients']! + amount;
      } else if (categoryText.contains('water')) {
        values['Water'] = values['Water']! + amount;
      } else if (categoryText.contains('packag')) {
        values['Packaging'] = values['Packaging']! + amount;
      } else {
        values['Other'] = values['Other']! + amount;
      }
    }
    return values;
  }

  List<_ChartSlice> get _yieldByCropSlices {
    final values = <String, num>{};
    for (final batch in _ownerBatches) {
      final crop =
          _value(batch, ['plant_name', 'plant_type'], fallback: 'Unassigned');
      values[crop] = (values[crop] ?? 0) + _numValue(batch['total_weight_kg']);
    }
    for (final fulfillment in _ownerFulfillments) {
      final crop = _value(fulfillment, ['plant_type'], fallback: 'Unassigned');
      values[crop] =
          (values[crop] ?? 0) + _numValue(fulfillment['total_weight']);
    }
    return _normalisedSlices(values);
  }

  List<_BarChartItem> get _inputCostBars {
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.info,
      AppColors.warning,
      AppColors.error,
    ];
    final entries = _inputCostValues.entries
        .where((entry) => entry.value > 0 || entry.key != 'Other')
        .toList();
    if (entries.every((entry) => entry.value == 0)) {
      return const [
        _BarChartItem(label: 'No data', value: 0, color: AppColors.neutral400)
      ];
    }
    return entries.asMap().entries.map((entry) {
      return _BarChartItem(
        label: entry.value.key,
        value: entry.value.value.toDouble(),
        color: colors[entry.key % colors.length],
      );
    }).toList();
  }

  List<double> get _waterTrendPoints {
    final points = List<double>.filled(7, 0);
    final start = DateTime.now().subtract(const Duration(days: 6));
    for (final reading in _ownerSensorReadings) {
      if (!_normalise(reading['sensortype']).contains('water')) continue;
      final date = _dateValue(reading['timestamp']);
      if (date == null) continue;
      final index = DateTime(date.year, date.month, date.day)
          .difference(DateTime(start.year, start.month, start.day))
          .inDays;
      if (index >= 0 && index < points.length) {
        points[index] += _numValue(reading['value']).toDouble();
      }
    }
    return points.every((point) => point == 0)
        ? List<double>.filled(7, 0)
        : points;
  }

  List<_MonthlyCost> get _monthlyInputCosts {
    final now = DateTime.now();
    final months = List.generate(6, (index) {
      final date = DateTime(now.year, now.month - (5 - index), 1);
      return date;
    });
    const labels = [
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
    return months.map((month) {
      final value = _ownerFundRequests.where((request) {
        final date =
            _dateValue(request['request_date'] ?? request[r'$createdAt']);
        return date != null &&
            date.year == month.year &&
            date.month == month.month;
      }).fold<num>(0, (sum, request) => sum + _numValue(request['amount']));
      return _MonthlyCost(
          month: labels[month.month - 1], value: value.toDouble());
    }).toList();
  }

  List<FlSpot> get _revenueTrendSpots {
    final start = DateTime.now().subtract(const Duration(days: 6));
    final values = List<double>.filled(7, 0);
    for (final sale in _ownerSales) {
      final date = _dateValue(
          sale['payment_date'] ?? sale['delivered_at'] ?? sale[r'$createdAt']);
      if (date == null) continue;
      final index = DateTime(date.year, date.month, date.day)
          .difference(DateTime(start.year, start.month, start.day))
          .inDays;
      if (index >= 0 && index < values.length) {
        values[index] +=
            _numValue(sale['total_amount'] ?? sale['amount']).toDouble();
      }
    }
    return values
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value / 1000))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Farm Owner';
    final userEmail = authState.user?.email ?? 'owner@farmestates.com';
    final userRole = 'Farm Owner';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? FarmOwnerMobileDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (i) => setState(() => _selectedNavIndex = i),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;

    return Row(
      children: [
        FarmOwnerSidebar(
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
              FarmOwnerHeader(
                userName: userName,
                onNotificationTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.all(isTablet ? AppSpacing.md : AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildContent(isDark)],
                  ),
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
        FarmOwnerHeader(
          userName: userName,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildContent(isDark)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    final gap =
        isMobile ? AppSpacing.md : (isTablet ? AppSpacing.md : AppSpacing.lg);
    if (_isLoading) {
      return const AdminDataSkeleton(rowCount: 5, showStats: true);
    }
    if (_errorMessage != null) {
      return _buildErrorState(isDark);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(isDark),
        SizedBox(height: gap),
        _buildFarmDetailsCard(isDark),
        SizedBox(height: gap),
        _buildPerformanceCards(isDark),
        SizedBox(height: gap),
        _buildChartsSection(isDark),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
            size: 42,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Unable to load analytics data',
            style: AppTypography.h6.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _loadAnalyticsData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;

    return Builder(
      builder: (context) {
        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your Farm Analytics',
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 20,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: _buildHeaderDropdown(
                  isDark,
                  value: _selectedPeriod,
                  items: const [
                    'Last 7 Days',
                    'Last 30 Days',
                    'Last 3 Months',
                    'Last Year'
                  ],
                  onChanged: (value) => setState(() => _selectedPeriod = value),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildHeaderDropdown(
                      isDark,
                      value: _selectedCrop,
                      items: _cropFilterItems,
                      onChanged: (value) =>
                          setState(() => _selectedCrop = value),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildHeaderDropdown(
                      isDark,
                      value: _selectedInputType,
                      items: const [
                        'All Inputs',
                        'Seeds',
                        'Nutrients',
                        'Water',
                        'Packaging'
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedInputType = value),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Your Farm Analytics',
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: isTablet ? 22 : 24,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _buildHeaderDropdown(
              isDark,
              value: _selectedPeriod,
              items: const [
                'Last 7 Days',
                'Last 30 Days',
                'Last 3 Months',
                'Last Year'
              ],
              onChanged: (value) => setState(() => _selectedPeriod = value),
              fontSize: isTablet ? 12 : 13,
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildHeaderDropdown(
              isDark,
              value: _selectedCrop,
              items: _cropFilterItems,
              onChanged: (value) => setState(() => _selectedCrop = value),
              fontSize: isTablet ? 12 : 13,
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildHeaderDropdown(
              isDark,
              value: _selectedInputType,
              items: const [
                'All Inputs',
                'Seeds',
                'Nutrients',
                'Water',
                'Packaging'
              ],
              onChanged: (value) => setState(() => _selectedInputType = value),
              fontSize: isTablet ? 12 : 13,
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderDropdown(
    bool isDark, {
    required String? value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    double fontSize = 13,
  }) {
    final safeValue =
        (value != null && items.contains(value)) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
        ),
      ),
      child: DropdownButton<String>(
        value: safeValue,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: fontSize,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) => onChanged(value ?? safeValue),
        underline: const SizedBox(),
        icon: Icon(
          Icons.arrow_drop_down,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textPrimary,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Widget _buildPerformanceCards(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;

    final metrics = [
      {
        'title': 'Total Revenue',
        'value': _formatCompactMoney(_totalRevenue),
        'change': '${_ownerSales.length} sales',
        'isPositive': _totalRevenue >= 0,
        'icon': Icons.trending_up,
        'color': AppColors.success,
      },
      {
        'title': 'Total Yield',
        'value': '${_totalYieldKg.toStringAsFixed(1)} kg',
        'change': '${_ownerBatches.length} batches',
        'isPositive': _totalYieldKg >= 0,
        'icon': Icons.inventory,
        'color': AppColors.info,
      },
      {
        'title': 'Profit Margin',
        'value': '${_profitMargin.toStringAsFixed(1)}%',
        'change': _formatCompactMoney(_totalInputCost),
        'isPositive': _profitMargin >= 0,
        'icon': Icons.percent,
        'color': AppColors.primary,
      },
      {
        'title': 'Avg. Daily Revenue',
        'value': _formatCompactMoney(_averageDailyRevenue),
        'change': '${_averageYieldLoss.toStringAsFixed(1)}% loss',
        'isPositive': _averageYieldLoss <= 10,
        'icon': Icons.show_chart,
        'color': AppColors.warning,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isMobile ? 2 : (isTablet ? 2 : 4);
        final childAspectRatio = isMobile ? 1.3 : (isTablet ? 1.6 : 1.8);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
          mainAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
          children: metrics.map((metric) {
            return Container(
              padding: EdgeInsets.all(isMobile
                  ? AppSpacing.sm
                  : (isTablet ? AppSpacing.sm : AppSpacing.md)),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : AppColors.neutral200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.all(isMobile ? 6 : (isTablet ? 7 : 8)),
                        decoration: BoxDecoration(
                          color: (metric['color'] as Color).withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Icon(
                          metric['icon'] as IconData,
                          color: metric['color'] as Color,
                          size: isMobile ? 18 : (isTablet ? 19 : 20),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (metric['isPositive'] as bool)
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.error.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (metric['isPositive'] as bool)
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: isMobile ? 10 : 12,
                              color: (metric['isPositive'] as bool)
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                metric['change'] as String,
                                style: AppTypography.caption.copyWith(
                                  color: (metric['isPositive'] as bool)
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontSize: isMobile ? 9 : 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? AppSpacing.xs : AppSpacing.sm),
                  Text(
                    metric['value'] as String,
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: isMobile ? 20 : (isTablet ? 22 : 24),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metric['title'] as String,
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? Colors.white.withOpacity(0.6)
                          : AppColors.textSecondary,
                      fontSize: isMobile ? 11 : (isTablet ? 11.5 : 12),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFarmDetailsCard(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;

    final primaryFarm = _ownerFarms.isNotEmpty ? _ownerFarms.first : null;
    final cropSummary = _cropFilterItems.length > 1
        ? _cropFilterItems.skip(1).take(3).join(', ')
        : 'No crop assigned';
    final farmNames = _ownerFarms
        .map((farm) => _value(farm, ['name', 'farm_name']))
        .where((name) => name.isNotEmpty)
        .toList();
    final locations = _ownerFarms
        .map((farm) => _value(farm, ['location']))
        .where((location) => location.isNotEmpty)
        .toSet()
        .toList();
    final details = [
      {
        'label': 'Owned Farms',
        'value': farmNames.isEmpty
            ? 'No linked farms'
            : '${farmNames.length} farm${farmNames.length == 1 ? '' : 's'}'
      },
      {'label': 'Primary Crop', 'value': cropSummary},
      {
        'label': 'Farm Tier',
        'value': primaryFarm == null
            ? 'Not assigned'
            : _value(primaryFarm, ['tier_type'], fallback: 'Not assigned')
      },
      {
        'label': 'Location',
        'value': locations.isEmpty ? 'Not assigned' : locations.join(', ')
      },
    ];

    return Container(
      padding: EdgeInsets.all(isMobile
          ? AppSpacing.md
          : (isTablet ? AppSpacing.lg : AppSpacing.xl)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.agriculture_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Farm Details',
                style: AppTypography.h6.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
          Wrap(
            spacing: isMobile ? AppSpacing.md : AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: details.map((detail) {
              return SizedBox(
                width: isMobile ? double.infinity : 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail['label'] as String,
                      style: AppTypography.caption.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail['value'] as String,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    final revenueSpots = _revenueTrendSpots;
    final maxRevenueY = revenueSpots.fold<double>(
      0,
      (max, spot) => spot.y > max ? spot.y : max,
    );
    final revenueChartMaxY = maxRevenueY <= 0 ? 1.0 : maxRevenueY * 1.2;
    final inputUsageSlices = _normalisedSlices(_inputUsageValues);
    final yieldByCropSlices = _yieldByCropSlices;
    final inputCostBars = _inputCostBars;
    final waterTrendPoints = _waterTrendPoints;
    final monthlyCosts = _monthlyInputCosts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Farm Revenue Trend',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: isMobile ? 18 : (isTablet ? 20 : 22),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: isMobile ? 180 : (isTablet ? 190 : 200),
          padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color:
                  isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
            ),
          ),
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: revenueChartMaxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval:
                    revenueChartMaxY <= 4 ? 1 : revenueChartMaxY / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 4,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        'GHS ${value.toStringAsFixed(0)}k',
                        style: AppTypography.caption.copyWith(
                          color:
                              isDark ? Colors.white54 : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      const labels = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun'
                      ];
                      if (value.toInt() < 0 || value.toInt() >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        labels[value.toInt()],
                        style: AppTypography.caption.copyWith(
                          color:
                              isDark ? Colors.white54 : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 8,
                  tooltipPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  tooltipMargin: 12,
                  getTooltipColor: (touchedSpot) =>
                      isDark ? const Color(0xFF111827) : Colors.white,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        'GHS ${spot.y.toStringAsFixed(1)}k',
                        AppTypography.caption.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: AppColors.success,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 4.5,
                      color: AppColors.success,
                      strokeWidth: 2.5,
                      strokeColor:
                          isDark ? AppColors.surfaceDark : Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.success.withOpacity(0.12),
                  ),
                  spots: revenueSpots,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
        Text(
          'Insights',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: isMobile ? 18 : (isTablet ? 20 : 22),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = isMobile
                ? double.infinity
                : (constraints.maxWidth - AppSpacing.md) / 2;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _buildPieChartCard(
                    isDark,
                    title: 'Input Usage',
                    centerLabel: 'Total',
                    centerValue: _inputUsageValues.values
                        .fold<num>(0, (sum, value) => sum + value)
                        .toStringAsFixed(0),
                    slices: inputUsageSlices,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildPieChartCard(
                    isDark,
                    title: 'Yield by Crop',
                    centerLabel: 'Harvest',
                    centerValue: '${_totalYieldKg.toStringAsFixed(1)} kg',
                    slices: yieldByCropSlices,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildBarChartCard(
                    isDark,
                    title: 'Input Cost by Category',
                    totalLabel: 'Total Cost',
                    totalValue: _formatCompactMoney(_totalInputCost),
                    bars: inputCostBars,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildLineChartCard(
                    isDark,
                    title: 'Water Usage Trend',
                    subtitle: 'Last 7 days',
                    points: waterTrendPoints,
                    lineColor: AppColors.info,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildMonthlyCostCard(
                    isDark,
                    title: 'Monthly Input Cost',
                    values: monthlyCosts,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPieChartCard(
    bool isDark, {
    required String title,
    required String centerLabel,
    required String centerValue,
    required List<_ChartSlice> slices,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    final safeIndex = _touchedPieIndex[title];
    final isValidIndex =
        safeIndex != null && safeIndex >= 0 && safeIndex < slices.length;
    final selectedFilter = _cardFilters[title] ?? 'All';

    return Container(
      padding: EdgeInsets.all(isMobile
          ? AppSpacing.md
          : (isTablet ? AppSpacing.lg : AppSpacing.xl)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              _buildCardFilter(
                isDark,
                title: title,
                value: selectedFilter,
                options: const [
                  'All',
                  'Last 7 days',
                  'Last 30 days',
                  'This season'
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SizedBox(
                width: isMobile ? 120 : 140,
                height: isMobile ? 120 : 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: isMobile ? 28 : 34,
                        sections: slices.asMap().entries.map((entry) {
                          final index = entry.key;
                          final slice = entry.value;
                          final isTouched = isValidIndex && safeIndex == index;
                          return PieChartSectionData(
                            color: slice.color,
                            value: slice.value,
                            showTitle: false,
                            radius: isMobile
                                ? (isTouched ? 30 : 24)
                                : (isTouched ? 34 : 28),
                          );
                        }).toList(),
                        pieTouchData: PieTouchData(
                          enabled: true,
                          touchCallback: (event, response) {
                            final touched = response?.touchedSection;
                            final index = touched?.touchedSectionIndex ?? -1;
                            setState(() {
                              if (index < 0 || index >= slices.length) {
                                _touchedPieIndex[title] = null;
                              } else {
                                _touchedPieIndex[title] = index;
                              }
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                    if (isValidIndex)
                      Align(
                        alignment: Alignment.topRight,
                        child: _buildPieTooltip(
                          slices[safeIndex],
                          isDark,
                        ),
                      ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          centerLabel,
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? Colors.white60
                                : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          centerValue,
                          style: AppTypography.bodyLarge.copyWith(
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: slices.map((slice) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: slice.color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              slice.label,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${slice.value}%',
                            style: AppTypography.bodySmall.copyWith(
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieTooltip(_ChartSlice slice, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(top: 6, right: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '${slice.label}: ${slice.value.toStringAsFixed(0)}%',
        style: AppTypography.caption.copyWith(
          color: isDark ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCardFilter(
    bool isDark, {
    required String title,
    required String value,
    required List<String> options,
  }) {
    return PopupMenuButton<String>(
      tooltip: 'Filter',
      offset: const Offset(0, 38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      onSelected: (selected) {
        setState(() {
          _cardFilters[title] = selected;
        });
      },
      itemBuilder: (context) => options
          .map(
            (option) => PopupMenuItem(
              value: option,
              child: Row(
                children: [
                  Icon(
                    option == value
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 16,
                    color: option == value
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(option),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : AppColors.neutral100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Text(
              value,
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(
    bool isDark, {
    required String title,
    required String totalLabel,
    required String totalValue,
    required List<_BarChartItem> bars,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    final maxValue =
        bars.map((b) => b.value).reduce((a, b) => a > b ? a : b).toDouble();
    final selectedFilter = _cardFilters[title] ?? 'All';

    return Container(
      padding: EdgeInsets.all(isMobile
          ? AppSpacing.md
          : (isTablet ? AppSpacing.lg : AppSpacing.xl)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              _buildCardFilter(
                isDark,
                title: title,
                value: selectedFilter,
                options: const ['All', 'This month', 'Last month', 'YTD'],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                totalLabel,
                style: AppTypography.caption.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                totalValue,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: isMobile ? 160 : 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: maxValue == 0 ? 1 : maxValue * 1.15,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue == 0 ? 1 : maxValue / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: maxValue == 0 ? 1 : maxValue / 4,
                      getTitlesWidget: (value, meta) => Text(
                        'GHS ${value.toStringAsFixed(0)}',
                        style: AppTypography.caption.copyWith(
                          color:
                              isDark ? Colors.white54 : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
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
                                ? Colors.white70
                                : AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    tooltipMargin: 12,
                    getTooltipColor: (group) =>
                        isDark ? const Color(0xFF111827) : Colors.white,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        'GHS ${rod.toY.toStringAsFixed(0)}',
                        AppTypography.caption.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: bars.asMap().entries.map((entry) {
                  final index = entry.key;
                  final bar = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: bar.value,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        color: bar.color,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChartCard(
    bool isDark, {
    required String title,
    required String subtitle,
    required List<double> points,
    required Color lineColor,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    final selectedFilter = _cardFilters[title] ?? 'All';
    final maxPoint = points.isEmpty
        ? 0.0
        : points.reduce((a, b) => a > b ? a : b).toDouble();
    final chartMaxY = maxPoint <= 0 ? 1.0 : maxPoint * 1.2;

    return Container(
      padding: EdgeInsets.all(isMobile
          ? AppSpacing.md
          : (isTablet ? AppSpacing.lg : AppSpacing.xl)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              _buildCardFilter(
                isDark,
                title: title,
                value: selectedFilter,
                options: const ['All', '7 days', '14 days', '30 days'],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: isMobile ? 140 : 160,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: points.isEmpty ? 1 : points.length - 1,
                minY: 0,
                maxY: chartMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMaxY <= 4 ? 1 : chartMaxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 10,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: AppTypography.caption.copyWith(
                          color:
                              isDark ? Colors.white54 : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    tooltipMargin: 12,
                    getTooltipColor: (touchedSpot) =>
                        isDark ? const Color(0xFF111827) : Colors.white,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(0)} L',
                          AppTypography.caption.copyWith(
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4.5,
                        color: lineColor,
                        strokeWidth: 2.5,
                        strokeColor:
                            isDark ? AppColors.surfaceDark : Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withOpacity(0.12),
                    ),
                    spots: points
                        .asMap()
                        .entries
                        .map((entry) =>
                            FlSpot(entry.key.toDouble(), entry.value))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCostCard(
    bool isDark, {
    required String title,
    required List<_MonthlyCost> values,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    final maxValue =
        values.map((v) => v.value).reduce((a, b) => a > b ? a : b).toDouble();
    final selectedFilter = _cardFilters[title] ?? 'All';

    return Container(
      padding: EdgeInsets.all(isMobile
          ? AppSpacing.md
          : (isTablet ? AppSpacing.lg : AppSpacing.xl)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              _buildCardFilter(
                isDark,
                title: title,
                value: selectedFilter,
                options: const ['6 months', 'YTD', '12 months'],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: isMobile ? 140 : 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: maxValue == 0 ? 1 : maxValue * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue == 0 ? 1 : maxValue / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: maxValue == 0 ? 1 : maxValue / 4,
                      getTitlesWidget: (value, meta) => Text(
                        'GHS ${value.toStringAsFixed(0)}',
                        style: AppTypography.caption.copyWith(
                          color:
                              isDark ? Colors.white54 : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= values.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          values[index].month,
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    tooltipMargin: 12,
                    getTooltipColor: (group) =>
                        isDark ? const Color(0xFF111827) : Colors.white,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        'GHS ${rod.toY.toStringAsFixed(0)}',
                        AppTypography.caption.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: values.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: item.value,
                        width: 16,
                        borderRadius: BorderRadius.circular(6),
                        color: AppColors.primary.withOpacity(0.9),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
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
        'route': '/farm-owner'
      },
      {
        'icon': Icons.agriculture_outlined,
        'label': 'Farm',
        'index': 1,
        'route': '/farm-owner/farm'
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'Wallet',
        'index': 2,
        'route': '/farm-owner/digital-wallet'
      },
      {
        'icon': Icons.analytics_outlined,
        'label': 'Analytics',
        'index': 3,
        'route': '/farm-owner/analytics'
      },
      {
        'icon': Icons.assessment_outlined,
        'label': 'Reports',
        'index': 4,
        'route': '/farm-owner/reports'
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
            children: navItems.take(5).map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final isSelected = index == _selectedNavIndex;

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
                          try {
                            Navigator.pushNamed(context, route);
                          } catch (e2) {
                            debugPrint('Navigation error: $e2');
                          }
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

class _ChartSlice {
  final Color color;
  final double value;
  final String label;

  const _ChartSlice({
    required this.color,
    required this.value,
    required this.label,
  });
}

class _BarChartItem {
  final String label;
  final double value;
  final Color color;

  const _BarChartItem({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _MonthlyCost {
  final String month;
  final double value;

  const _MonthlyCost({
    required this.month,
    required this.value,
  });
}
