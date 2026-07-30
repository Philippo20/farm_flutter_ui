import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_owner_sidebar.dart';
import '../../core/widgets/farm_owner_header.dart';
import '../../core/widgets/farm_owner_mobile_drawer.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Farm Overview for Farm Owner
/// Monitoring, issues, assigned team, and batch progress
class FarmOverviewScreen extends ConsumerStatefulWidget {
  const FarmOverviewScreen({super.key});

  @override
  ConsumerState<FarmOverviewScreen> createState() => _FarmOverviewScreenState();
}

class _FarmOverviewScreenState extends ConsumerState<FarmOverviewScreen> {
  final SuperAdminApiService _api = SuperAdminApiService();
  int _selectedNavIndex = 1;
  int _selectedTab = 0;
  String _selectedReadingDateFilter = 'Today';
  String _selectedReadingTimeFilter = '24H';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, dynamic>> _farms = [];
  final List<Map<String, dynamic>> _users = [];
  final List<Map<String, dynamic>> _batches = [];
  final List<Map<String, dynamic>> _sensors = [];
  final List<Map<String, dynamic>> _sales = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadFarmData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadFarmData(showLoading: false),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFarmData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final results = await Future.wait([
        _api.getFarms(),
        _api.getUsers(),
        _api.getBatches(),
        _api.getSensors(),
        _api.getSales(),
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
        _sensors
          ..clear()
          ..addAll(results[3]);
        _sales
          ..clear()
          ..addAll(results[4]);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      if (!showLoading) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  String _docId(Map<String, dynamic> doc) =>
      (doc[r'$id'] ?? doc['id'] ?? doc['farm_id'] ?? '').toString();

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

  bool _isOwnerFarm(Map<String, dynamic> farm) {
    final user = ref.read(authProvider).user;
    if (user == null) return true;
    final ownerTokens = {
      _normalise(user.id),
      _normalise(user.email),
      _normalise(user.name),
    }..removeWhere((token) => token.isEmpty);
    final farmOwnerTokens = {
      _normalise(_value(farm, ['ownerID', 'owner_id', 'ownerId'])),
      _normalise(_value(farm, ['owner_name', 'ownerName'])),
      _normalise(_value(farm, ['owner_email', 'ownerEmail'])),
    }..removeWhere((token) => token.isEmpty || token == 'unassigned');
    return farmOwnerTokens.any(ownerTokens.contains);
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

  bool _matchesOwnerFarm(Map<String, dynamic> doc) {
    final farmId = _value(doc, ['farm_id', 'farmID', 'farmId']);
    final farmName = _value(doc, ['farm_name', 'farmName']);
    return (farmId.isNotEmpty && _ownerFarmIds.contains(farmId)) ||
        (farmName.isNotEmpty && _ownerFarmNames.contains(_normalise(farmName)));
  }

  List<Map<String, dynamic>> get _ownerBatches =>
      _batches.where(_matchesOwnerFarm).toList();

  List<Map<String, dynamic>> get _ownerSensors =>
      _sensors.where(_matchesOwnerFarm).toList();

  List<Map<String, dynamic>> get _ownerSales =>
      _sales.where(_matchesOwnerFarm).toList();

  String _formatCompact(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }

  String _relativeTime(DateTime? date) {
    if (date == null) return 'Recently';
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  List<Map<String, dynamic>> get _ownerSensorDashboardItems {
    return _ownerSensors.map((sensor) {
      final label = _sensorLabel(sensor);
      final unit = _value(sensor, ['unit', 'measurement_unit']);
      final rawValue = sensor['last_value'] ??
          sensor['current_value'] ??
          sensor['value'] ??
          sensor['reading'];
      final numericValue = _numValue(rawValue);
      final hasNumericValue =
          rawValue != null && rawValue.toString().trim().isNotEmpty;
      final displayValue = hasNumericValue
          ? '${numericValue.toStringAsFixed(numericValue % 1 == 0 ? 0 : 1)}${unit.isEmpty ? '' : ' $unit'}'
          : _value(sensor, ['status'], fallback: 'No reading');
      final status = _value(sensor, ['status'], fallback: 'Unknown');

      return {
        'category': _sensorCategory(label),
        'label': label,
        'value': displayValue,
        'status': status,
        'updated_at':
            sensor['updated_at'] ?? sensor['last_seen'] ?? sensor['timestamp'],
        'numeric_value': numericValue,
        'icon': _sensorIcon(label),
        'color': _sensorColor(label, status),
        'percent': _sensorPercent(label, numericValue),
        'trend': _sensorTrend(numericValue),
        'unit': unit,
      };
    }).toList()
      ..sort((a, b) => '${a['category']}${a['label']}'
          .compareTo('${b['category']}${b['label']}'));
  }

  String _sensorLabel(Map<String, dynamic> sensor) {
    final name = _value(
        sensor,
        [
          'sensor_name',
          'name',
          'sensor_type',
          'type',
          'serial_number',
        ],
        fallback: 'Sensor');
    final unit = _value(sensor, ['unit', 'measurement_unit']);
    if (unit.isEmpty || name.toLowerCase().contains(unit.toLowerCase())) {
      return name;
    }
    return '$name ($unit)';
  }

  String _sensorCategory(String label) {
    final text = label.toLowerCase();
    if (text.contains('temp') || text.contains('humid')) {
      return 'Room Temp/Humidity';
    }
    if (text.contains('ph') ||
        text.contains('ec') ||
        text.contains('water') ||
        text.contains('light') ||
        text.contains('moisture')) {
      return 'Water & Nutrients';
    }
    if (text.contains('volt') ||
        text.contains('current') ||
        text.contains('energy') ||
        text.contains('power')) {
      return 'Energy';
    }
    return 'Air Quality';
  }

  IconData _sensorIcon(String label) {
    final text = label.toLowerCase();
    if (text.contains('temp')) return Icons.thermostat;
    if (text.contains('humid')) return Icons.water;
    if (text.contains('ph')) return Icons.opacity;
    if (text.contains('ec')) return Icons.science;
    if (text.contains('water')) return Icons.water_drop;
    if (text.contains('light')) return Icons.light_mode;
    if (text.contains('volt')) return Icons.electric_bolt;
    if (text.contains('current') || text.contains('energy')) return Icons.bolt;
    return Icons.sensors;
  }

  Color _sensorColor(String label, String status) {
    final state = status.toLowerCase();
    if (state.contains('offline') || state.contains('alert')) {
      return AppColors.error;
    }
    final category = _sensorCategory(label);
    switch (category) {
      case 'Water & Nutrients':
        return AppColors.primary;
      case 'Room Temp/Humidity':
        return AppColors.warning;
      case 'Energy':
        return AppColors.info;
      default:
        return AppColors.success;
    }
  }

  bool _isSensorOnline(String status) {
    final state = status.toLowerCase();
    if (state.contains('offline') ||
        state.contains('inactive') ||
        state.contains('disabled')) {
      return false;
    }
    if (state.contains('online') ||
        state.contains('active') ||
        state.contains('connected')) {
      return true;
    }
    return state.isNotEmpty;
  }

  double _sensorPercent(String label, num value) {
    final text = label.toLowerCase();
    if (text.contains('ph')) return (value / 14).clamp(0, 1).toDouble();
    if (text.contains('humid') || text.contains('%')) {
      return (value / 100).clamp(0, 1).toDouble();
    }
    if (text.contains('temp')) return (value / 45).clamp(0, 1).toDouble();
    if (text.contains('volt')) return (value / 300).clamp(0, 1).toDouble();
    if (text.contains('current')) return (value / 30).clamp(0, 1).toDouble();
    if (text.contains('co2')) return (value / 1200).clamp(0, 1).toDouble();
    return (value / 1000).clamp(0, 1).toDouble();
  }

  List<double> _sensorTrend(num value) {
    final base = value.toDouble();
    if (base == 0) return [0, 0, 0, 0, 0, 0];
    return [
      base * 0.92,
      base * 0.96,
      base * 0.98,
      base * 1.02,
      base * 0.99,
      base,
    ];
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
          onItemSelected: (index) => setState(() => _selectedNavIndex = index),
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
                  child: _buildContent(isDark, isTablet),
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
            child: _buildContent(isDark, true),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark, bool isTabletOrMobile) {
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
        SizedBox(height: isTabletOrMobile ? AppSpacing.md : AppSpacing.lg),
        _buildMonitoringCards(isDark),
        SizedBox(height: isTabletOrMobile ? AppSpacing.md : AppSpacing.lg),
        _buildTabBar(isDark),
        SizedBox(height: isTabletOrMobile ? AppSpacing.md : AppSpacing.lg),
        if (_selectedTab == 0) ...[
          _buildOverviewTab(isDark, isTabletOrMobile),
        ] else ...[
          _buildIotDashboard(isDark, isTabletOrMobile),
        ],
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 42),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Unable to load farm data',
            style: AppTypography.h6.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: _loadFarmData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Farm Overview',
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_ownerFarms.length} owned farms - ${_ownerBatches.length} batches - ${_ownerSensors.length} sensors',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loadFarmData,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildMonitoringCards(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;

    final harvested = _ownerBatches.fold<num>(
      0,
      (sum, batch) => sum + _numValue(batch['total_harvested']),
    );
    final transplanted = _ownerBatches.fold<num>(
      0,
      (sum, batch) => sum + _numValue(batch['total_transplanted']),
    );
    final revenue = _ownerSales.fold<num>(
      0,
      (sum, sale) =>
          sum + _numValue(sale['total_amount'] ?? sale['amount'] ?? 0),
    );
    final onlineSensors = _ownerSensors
        .where((sensor) => _value(sensor, ['status']).toLowerCase() == 'online')
        .length;
    final activeFarms = _ownerFarms
        .where((farm) => _value(farm, ['status']).toLowerCase() == 'active')
        .length;

    final metrics = [
      {
        'title': 'Current Yield',
        'value': '${_formatCompact(harvested)} heads',
        'change': '${_ownerBatches.length} batches',
        'icon': Icons.inventory,
        'color': AppColors.success
      },
      {
        'title': 'Transplanted',
        'value': '${_formatCompact(transplanted)} heads',
        'change': harvested > 0 && transplanted > 0
            ? '${((harvested / transplanted) * 100).clamp(0, 100).toStringAsFixed(0)}% yield'
            : 'No harvest',
        'icon': Icons.eco_rounded,
        'color': AppColors.info
      },
      {
        'title': 'Revenue',
        'value': 'GHS ${_formatCompact(revenue)}',
        'change': '${_ownerSales.length} sales',
        'icon': Icons.trending_up_rounded,
        'color': AppColors.primary
      },
      {
        'title': 'Farm Health',
        'value': '$activeFarms/${_ownerFarms.length}',
        'change': '$onlineSensors sensors online',
        'icon': Icons.sensors,
        'color': AppColors.warning
      },
    ];

    final crossAxisCount = isMobile ? 2 : (isTablet ? 2 : 4);
    final childAspectRatio = isMobile ? 1.25 : (isTablet ? 1.6 : 1.8);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      children: metrics.map((metric) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (metric['color'] as Color).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      metric['icon'] as IconData,
                      size: 18,
                      color: metric['color'] as Color,
                    ),
                  ),
                  Text(
                    metric['change'] as String,
                    style: AppTypography.caption.copyWith(
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                metric['value'] as String,
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metric['title'] as String,
                style: AppTypography.caption.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTabBar(bool isDark) {
    final tabs = ['Overview', 'IoT Dashboard'];
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: isMobile ? double.infinity : null,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedTab == index;
            final tabButton = InkWell(
              onTap: () => setState(() => _selectedTab = index),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white.withOpacity(0.12) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: AppTypography.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white70 : AppColors.textSecondary),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );

            if (isMobile) {
              return Expanded(child: tabButton);
            }

            return SizedBox(
              width: index == 0 ? 118 : 154,
              child: tabButton,
            );
          }),
        ),
      ),
    );
  }

  Widget _buildIotDashboard(bool isDark, bool isTabletOrMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final sensors = _ownerSensorDashboardItems;

    const categoryOrder = [
      'Air Quality',
      'Room Temp/Humidity',
      'Water & Nutrients',
      'Energy',
    ];
    final categorySensorsCrossAxisCount = isMobile ? 1 : 2;
    final categorySensorsAspectRatio = isMobile ? 1.95 : 1.4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIotLiveHeader(isDark, sensors, isMobile),
        SizedBox(height: isTabletOrMobile ? AppSpacing.md : AppSpacing.lg),
        if (sensors.isEmpty)
          _buildNoSensorState(isDark)
        else if (isMobile)
          ...categoryOrder.map((category) {
            final categorySensors = sensors
                .where((sensor) => sensor['category'] == category)
                .toList();
            if (categorySensors.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _buildIotCategorySection(
                isDark: isDark,
                title: category,
                sensors: categorySensors,
                crossAxisCount: categorySensorsCrossAxisCount,
                childAspectRatio: categorySensorsAspectRatio,
                isMobile: isMobile,
              ),
            );
          })
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final sectionWidth = (constraints.maxWidth - AppSpacing.md) / 2;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: categoryOrder.map((category) {
                  final categorySensors = sensors
                      .where((sensor) => sensor['category'] == category)
                      .toList();
                  if (categorySensors.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return SizedBox(
                    width: sectionWidth,
                    child: _buildIotCategorySection(
                      isDark: isDark,
                      title: category,
                      sensors: categorySensors,
                      crossAxisCount: categorySensorsCrossAxisCount,
                      childAspectRatio: categorySensorsAspectRatio,
                      isMobile: isMobile,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        if (sensors.isNotEmpty) ...[
          SizedBox(height: isTabletOrMobile ? AppSpacing.md : AppSpacing.lg),
          _buildDetailedSensorReadingsSection(
            isDark: isDark,
            sensors: sensors,
            isMobile: isMobile,
          ),
        ],
      ],
    );
  }

  Widget _buildNoSensorState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.sensors_off_rounded,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            'No sensors linked',
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sensor readings will appear here after devices are assigned to your farms.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIotLiveHeader(
    bool isDark,
    List<Map<String, dynamic>> sensors,
    bool isMobile,
  ) {
    final onlineCount = sensors
        .where((sensor) => _isSensorOnline(sensor['status']?.toString() ?? ''))
        .length;
    final alertCount = sensors.where((sensor) {
      final statusInfo = _resolveSensorStatus(
        sensor['label'] as String,
        sensor['percent'] as double,
        backendStatus: sensor['status']?.toString() ?? '',
      );
      return statusInfo.isAlert;
    }).length;
    final latest = sensors
        .map((sensor) => _dateValue(sensor['updated_at']))
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (latest, date) =>
              latest == null || date.isAfter(latest) ? date : latest,
        );

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.sensors_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IoT Dashboard',
                style: AppTypography.h6.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sensors.isEmpty
                    ? 'Waiting for sensor assignments'
                    : 'Live readings refresh every 15 seconds',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final metrics = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: isMobile ? WrapAlignment.start : WrapAlignment.end,
      children: [
        _buildIotHeaderMetric(
          isDark: isDark,
          label: 'Online',
          value: '$onlineCount/${sensors.length}',
          color: AppColors.success,
          icon: Icons.wifi_tethering_rounded,
        ),
        _buildIotHeaderMetric(
          isDark: isDark,
          label: 'Alerts',
          value: '$alertCount',
          color: alertCount == 0 ? AppColors.success : AppColors.warning,
          icon: Icons.notifications_active_rounded,
        ),
        _buildIotHeaderMetric(
          isDark: isDark,
          label: 'Updated',
          value: latest == null ? 'Now' : _relativeTime(latest),
          color: AppColors.info,
          icon: Icons.update_rounded,
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: AppSpacing.md),
                metrics,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: header),
                const SizedBox(width: AppSpacing.md),
                metrics,
              ],
            ),
    );
  }

  Widget _buildIotHeaderMetric({
    required bool isDark,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 7),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: Text(
              value,
              key: ValueKey('$label-$value'),
              style: AppTypography.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedSensorReadingsSection({
    required bool isDark,
    required List<Map<String, dynamic>> sensors,
    required bool isMobile,
  }) {
    final now = DateTime.now();
    final updatedAt = _formatReadingTimestamp(now);
    final crossAxisCount = isMobile ? 1 : 2;
    final chartCardAspectRatio = isMobile ? 1.55 : 1.68;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Sensor Readings',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Updated $updatedAt',
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Today', 'Yesterday', 'Last 7 Days'].map((filter) {
              final isSelected = _selectedReadingDateFilter == filter;
              return _buildReadingFilterChip(
                label: filter,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () =>
                    setState(() => _selectedReadingDateFilter = filter),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['1H', '6H', '24H', '7D'].map((filter) {
              final isSelected = _selectedReadingTimeFilter == filter;
              return _buildReadingFilterChip(
                label: filter,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () =>
                    setState(() => _selectedReadingTimeFilter = filter),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            childAspectRatio: chartCardAspectRatio,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            children: sensors.map((sensor) {
              final trend = (sensor['trend'] as List)
                  .map((e) => (e as num).toDouble())
                  .toList();
              final filteredTrend =
                  _pointsForTimeFilter(trend, _selectedReadingTimeFilter);
              final statusInfo = _resolveSensorStatus(
                sensor['label'] as String,
                sensor['percent'] as double,
                backendStatus: sensor['status']?.toString() ?? '',
              );

              return AnimatedContainer(
                key: ValueKey('${sensor['label']}-${sensor['value']}'),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: statusInfo.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sensor['label'] as String,
                            style: AppTypography.bodyMedium.copyWith(
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, -0.2),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            sensor['value'] as String,
                            key: ValueKey(
                                '${sensor['label']}-${sensor['value']}-detail'),
                            style: AppTypography.bodyMedium.copyWith(
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusInfo.label,
                      style: AppTypography.caption.copyWith(
                        color: statusInfo.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        child: _buildRealtimeChart(
                          isDark,
                          filteredTrend,
                          sensor['color'] as Color,
                          key: ValueKey(
                              '${sensor['label']}-${filteredTrend.join(',')}'),
                          unit: sensor['unit'] as String,
                          height: null,
                        ),
                      ),
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

  Widget _buildReadingFilterChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : (isDark
                  ? Colors.white.withOpacity(0.03)
                  : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.5)
                : (isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white70 : AppColors.textSecondary),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  List<double> _pointsForTimeFilter(List<double> points, String filter) {
    if (points.length <= 2) return points;
    switch (filter) {
      case '1H':
        return points.skip(points.length > 3 ? points.length - 3 : 0).toList();
      case '6H':
        return points.skip(points.length > 4 ? points.length - 4 : 0).toList();
      case '24H':
        return points;
      case '7D':
        return points;
      default:
        return points;
    }
  }

  String _formatReadingTimestamp(DateTime timestamp) {
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
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year} - $hour:$minute';
  }

  Widget _buildIotCategorySection({
    required bool isDark,
    required String title,
    required List<Map<String, dynamic>> sensors,
    required int crossAxisCount,
    required double childAspectRatio,
    required bool isMobile,
  }) {
    final voltageSensor = sensors.cast<Map<String, dynamic>?>().firstWhere(
          (sensor) => sensor?['label'] == 'Voltage (V)',
          orElse: () => null,
        );
    final currentSensor = sensors.cast<Map<String, dynamic>?>().firstWhere(
          (sensor) => sensor?['label'] == 'Current (A)',
          orElse: () => null,
        );

    final normalSensors = sensors
        .where((sensor) =>
            sensor['label'] != 'Voltage (V)' &&
            sensor['label'] != 'Current (A)')
        .toList();

    final sensorCards = <Widget>[
      ...normalSensors
          .map((sensor) => _buildIotSensorCard(isDark, sensor, isMobile)),
      if (voltageSensor != null && currentSensor != null)
        _buildDoubleReadingCard(
          isDark: isDark,
          voltageSensor: voltageSensor,
          currentSensor: currentSensor,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${sensors.length}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: GridView.count(
            key: ValueKey('$title-${sensorCards.length}'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            children: sensorCards,
          ),
        ),
      ],
    );
  }

  Widget _buildIotSensorCard(
    bool isDark,
    Map<String, dynamic> sensor,
    bool isMobile,
  ) {
    final statusInfo = _resolveSensorStatus(
      sensor['label'] as String,
      sensor['percent'] as double,
      backendStatus: sensor['status']?.toString() ?? '',
    );

    return AnimatedContainer(
      key: ValueKey('${sensor['label']}-${sensor['value']}'),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusInfo.isAlert
              ? statusInfo.color.withOpacity(0.35)
              : (isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0)),
        ),
        boxShadow: statusInfo.isAlert
            ? [
                BoxShadow(
                  color: statusInfo.color.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (sensor['color'] as Color).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        sensor['icon'] as IconData,
                        size: 18,
                        color: sensor['color'] as Color,
                      ),
                    ),
                    _buildMiniGauge(
                      isDark,
                      sensor['percent'] as double,
                      statusInfo.color,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.18),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    sensor['value'] as String,
                    key: ValueKey('${sensor['label']}-${sensor['value']}'),
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sensor['label'] as String,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusInfo.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        statusInfo.label,
                        style: AppTypography.caption.copyWith(
                          color:
                              isDark ? Colors.white60 : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (statusInfo.isAlert) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusInfo.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Alert',
                          style: AppTypography.caption.copyWith(
                            color: statusInfo.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: SizedBox(
              height: isMobile ? 60 : 48,
              width: double.infinity,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: _buildRealtimeChart(
                  isDark,
                  (sensor['trend'] as List)
                      .map((e) => (e as num).toDouble())
                      .toList(),
                  sensor['color'] as Color,
                  key: ValueKey(
                      '${sensor['label']}-${(sensor['trend'] as List).join(',')}'),
                  unit: sensor['unit'] as String,
                  height: null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoubleReadingCard({
    required bool isDark,
    required Map<String, dynamic> voltageSensor,
    required Map<String, dynamic> currentSensor,
  }) {
    final voltageStatus = _resolveSensorStatus(
      voltageSensor['label'] as String,
      voltageSensor['percent'] as double,
      backendStatus: voltageSensor['status']?.toString() ?? '',
    );
    final currentStatus = _resolveSensorStatus(
      currentSensor['label'] as String,
      currentSensor['percent'] as double,
      backendStatus: currentSensor['status']?.toString() ?? '',
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: voltageStatus.isAlert || currentStatus.isAlert
              ? AppColors.warning.withOpacity(0.35)
              : (isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
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
                  child: const Icon(Icons.electric_bolt,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  'Electrical Double Reading',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDualMetricChip(
                    isDark: isDark,
                    color: voltageSensor['color'] as Color,
                    label: voltageSensor['label'] as String,
                    value: voltageSensor['value'] as String,
                    status: voltageStatus,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDualMetricChip(
                    isDark: isDark,
                    color: currentSensor['color'] as Color,
                    label: currentSensor['label'] as String,
                    value: currentSensor['value'] as String,
                    status: currentStatus,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: _buildDualRealtimeChart(
                isDark,
                voltageSensor,
                currentSensor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDualMetricChip({
    required bool isDark,
    required Color color,
    required String label,
    required String value,
    required _SensorStatus status,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: status.color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _buildDualRealtimeChart(
    bool isDark,
    Map<String, dynamic> voltageSensor,
    Map<String, dynamic> currentSensor,
  ) {
    final voltageRaw = (voltageSensor['trend'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    final currentRaw = (currentSensor['trend'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    if (voltageRaw.isEmpty || currentRaw.isEmpty) {
      return const SizedBox.shrink();
    }

    final pointCount = voltageRaw.length < currentRaw.length
        ? voltageRaw.length
        : currentRaw.length;
    final voltageValues = voltageRaw.take(pointCount).toList();
    final currentValues = currentRaw.take(pointCount).toList();

    final vMin = voltageValues.reduce((a, b) => a < b ? a : b);
    final vMax = voltageValues.reduce((a, b) => a > b ? a : b);
    final iMin = currentValues.reduce((a, b) => a < b ? a : b);
    final iMax = currentValues.reduce((a, b) => a > b ? a : b);
    final vRange = (vMax - vMin) == 0 ? 1.0 : (vMax - vMin);
    final iRange = (iMax - iMin) == 0 ? 1.0 : (iMax - iMin);

    final voltageNorm = voltageValues
        .asMap()
        .entries
        .map((entry) =>
            FlSpot(entry.key.toDouble(), ((entry.value - vMin) / vRange) * 100))
        .toList();
    final currentNorm = currentValues
        .asMap()
        .entries
        .map((entry) =>
            FlSpot(entry.key.toDouble(), ((entry.value - iMin) / iRange) * 100))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (pointCount - 1).toDouble(),
          minY: -8,
          maxY: 108,
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: 6,
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tooltipMargin: 6,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF111827) : Colors.white,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final idx = spot.x.toInt();
                  final isVoltage = (spot.barIndex == 0);
                  final value =
                      isVoltage ? voltageValues[idx] : currentValues[idx];
                  final unit = isVoltage ? 'V' : 'A';
                  final label = isVoltage ? 'Voltage' : 'Current';
                  final c = isVoltage
                      ? (voltageSensor['color'] as Color)
                      : (currentSensor['color'] as Color);
                  return LineTooltipItem(
                    '$label: ${value.toStringAsFixed(1)} $unit',
                    AppTypography.caption.copyWith(
                      color: c,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              preventCurveOverShooting: true,
              color: voltageSensor['color'] as Color,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 2.4,
                  color: voltageSensor['color'] as Color,
                  strokeWidth: 1.3,
                  strokeColor: isDark ? AppColors.surfaceDark : Colors.white,
                ),
              ),
              belowBarData: BarAreaData(show: false),
              spots: voltageNorm,
            ),
            LineChartBarData(
              isCurved: true,
              preventCurveOverShooting: true,
              color: currentSensor['color'] as Color,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 2.4,
                  color: currentSensor['color'] as Color,
                  strokeWidth: 1.3,
                  strokeColor: isDark ? AppColors.surfaceDark : Colors.white,
                ),
              ),
              belowBarData: BarAreaData(show: false),
              spots: currentNorm,
            ),
          ],
        ),
      ),
    );
  }

  _SensorStatus _resolveSensorStatus(
    String label,
    double percent, {
    String backendStatus = '',
  }) {
    final backend = backendStatus.toLowerCase();
    if (backend.contains('offline') || backend.contains('inactive')) {
      return const _SensorStatus(
        label: 'Offline',
        color: AppColors.error,
        isAlert: true,
      );
    }

    const thresholds = {
      'EC': {'min': 0.55, 'max': 0.8},
      'pH': {'min': 0.6, 'max': 0.85},
      'Temp': {'min': 0.5, 'max': 0.75},
      'Humidity': {'min': 0.55, 'max': 0.8},
      'Air Quality': {'min': 0.7, 'max': 0.9},
      'CO2': {'min': 0.5, 'max': 0.75},
      'Light': {'min': 0.6, 'max': 0.85},
      'Water Level': {'min': 0.6, 'max': 0.85},
    };

    final t = thresholds[label] ?? const {'min': 0.6, 'max': 0.85};
    final min = ((t['min'] as num?) ?? 0.6).toDouble();
    final max = ((t['max'] as num?) ?? 0.85).toDouble();
    if (percent < min) {
      return const _SensorStatus(
          label: 'Low', color: AppColors.warning, isAlert: true);
    }
    if (percent > max) {
      return const _SensorStatus(
          label: 'High', color: AppColors.warning, isAlert: true);
    }
    return const _SensorStatus(
        label: 'Optimal', color: AppColors.success, isAlert: false);
  }

  Widget _buildMiniGauge(bool isDark, double percent, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: percent.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, animatedPercent, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: animatedPercent,
                strokeWidth: 4,
                backgroundColor:
                    isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '${(animatedPercent * 100).toStringAsFixed(0)}%',
              style: AppTypography.caption.copyWith(
                fontSize: 9,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRealtimeChart(
    bool isDark,
    List<double> points,
    Color color, {
    Key? key,
    String unit = '',
    double? height = 40,
  }) {
    if (points.isEmpty) return const SizedBox.shrink();
    final min = points.reduce((a, b) => a < b ? a : b);
    final max = points.reduce((a, b) => a > b ? a : b);
    final range = (max - min) == 0 ? 1.0 : (max - min);
    final yPadding = range * 0.18;

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: points.length - 1,
            minY: min - yPadding,
            maxY: max + yPadding,
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipRoundedRadius: 6,
                tooltipPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tooltipMargin: 6,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipColor: (spot) =>
                    isDark ? const Color(0xFF111827) : Colors.white,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final value = spot.y.toStringAsFixed(2);
                    final suffix = unit.isNotEmpty ? ' $unit' : '';
                    return LineTooltipItem(
                      '$value$suffix',
                      AppTypography.caption.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                preventCurveOverShooting: true,
                color: color,
                barWidth: 2,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 2.5,
                    color: color,
                    strokeWidth: 1.5,
                    strokeColor: isDark ? AppColors.surfaceDark : Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withOpacity(0.12),
                ),
                spots: points
                    .asMap()
                    .entries
                    .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(bool isDark, bool isTabletOrMobile) {
    if (isTabletOrMobile) {
      return Column(
        children: [
          _buildPortfolioSummaryCard(isDark),
          const SizedBox(height: AppSpacing.md),
          _buildAssignments(isDark, true),
          const SizedBox(height: AppSpacing.md),
          _buildTechnicalIssues(isDark, true),
          const SizedBox(height: AppSpacing.md),
          _buildBatches(isDark, true),
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _buildPortfolioSummaryCard(isDark),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 4,
              child: _buildAssignments(isDark, false),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildTechnicalIssues(isDark, false)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildBatches(isDark, false)),
          ],
        ),
      ],
    );
  }

  Widget _buildPortfolioSummaryCard(bool isDark) {
    final farmNames = _ownerFarms
        .map((farm) => _value(farm, ['name', 'farm_name']))
        .where((name) => name.isNotEmpty)
        .take(3)
        .toList();
    final activeFarms = _ownerFarms
        .where((farm) => _value(farm, ['status']).toLowerCase() == 'active')
        .length;
    final activeBatches = _ownerBatches
        .where((batch) =>
            !_normalise(_value(batch, ['production_status']))
                .contains('completed') &&
            !_normalise(_value(batch, ['production_status']))
                .contains('delivered'))
        .length;
    final issueCount = _ownerBatches
        .where((batch) =>
            _value(batch, ['technical_issues']).trim().isNotEmpty &&
            _normalise(_value(batch, ['technical_issues'])) != 'none')
        .length;
    final latestBatchDate = _ownerBatches
        .map((batch) => _dateValue(batch['updated_at'] ?? batch['created_at']))
        .whereType<DateTime>()
        .fold<DateTime?>(
          null,
          (latest, date) =>
              latest == null || date.isAfter(latest) ? date : latest,
        );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.agriculture_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Farm Portfolio',
                      style: AppTypography.h6.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      farmNames.isEmpty
                          ? 'No owned farms are linked to this account yet.'
                          : farmNames.join(', '),
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildOverviewPill(
                label: '$activeFarms active',
                color: AppColors.success,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildPortfolioMetric(
                isDark: isDark,
                icon: Icons.storefront_rounded,
                label: 'Owned farms',
                value: '${_ownerFarms.length}',
                color: AppColors.primary,
              ),
              _buildPortfolioMetric(
                isDark: isDark,
                icon: Icons.timeline_rounded,
                label: 'Active batches',
                value: '$activeBatches',
                color: AppColors.info,
              ),
              _buildPortfolioMetric(
                isDark: isDark,
                icon: Icons.report_problem_rounded,
                label: 'Open issues',
                value: '$issueCount',
                color: issueCount == 0 ? AppColors.success : AppColors.warning,
              ),
              _buildPortfolioMetric(
                isDark: isDark,
                icon: Icons.update_rounded,
                label: 'Latest update',
                value: _relativeTime(latestBatchDate),
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioMetric({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 158,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewPill({
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(999),
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

  Widget _buildAssignments(bool isDark, bool isTabletOrMobile) {
    final manager = _assignedUser(['farm_manager_id', 'farmManagerId']);
    final caretaker = _assignedUser(['caretakerID', 'caretaker_id']);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Assigned Team',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              _buildOverviewPill(
                label: '${_ownerFarms.length} farms',
                color: AppColors.info,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildAssigneeCard(
            isDark,
            'Farm Manager',
            manager == null
                ? 'Unassigned'
                : _value(manager, ['name'], fallback: 'Farm Manager'),
            manager == null
                ? 'Assign from farm management'
                : _value(manager, ['email'], fallback: 'Assigned user'),
            Icons.manage_accounts_rounded,
            onMessage: manager == null
                ? null
                : () => _openMessageCenter(
                      role: 'Farm Manager',
                      recipient: manager,
                    ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildAssigneeCard(
            isDark,
            'Caretaker',
            caretaker == null
                ? 'Unassigned'
                : _value(caretaker, ['name'], fallback: 'Caretaker'),
            caretaker == null
                ? 'Assign from farm management'
                : _value(caretaker, ['email'], fallback: 'Assigned user'),
            Icons.handyman_rounded,
            onMessage: caretaker == null
                ? null
                : () => _openMessageCenter(
                      role: 'Caretaker',
                      recipient: caretaker,
                    ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _assignedUser(List<String> farmKeys) {
    for (final farm in _ownerFarms) {
      final assigned = _value(farm, farmKeys);
      if (assigned.isEmpty || _normalise(assigned) == 'unassigned') continue;
      for (final user in _users) {
        final tokens = {
          _docId(user),
          _value(user, ['id']),
          _value(user, ['name']),
          _value(user, ['email']),
        }.map(_normalise).where((token) => token.isNotEmpty).toSet();
        if (tokens.contains(_normalise(assigned))) return user;
      }
      return {'name': assigned, 'email': 'Assigned user'};
    }
    return null;
  }

  Widget _buildAssigneeCard(
      bool isDark, String title, String name, String detail, IconData icon,
      {VoidCallback? onMessage}) {
    final isAssigned = name.toLowerCase() != 'unassigned';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (isAssigned ? AppColors.primary : AppColors.warning)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isAssigned ? AppColors.primary : AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: isAssigned ? 'Message $name' : 'No assignee to message',
            onPressed: onMessage,
            icon: Icon(
              Icons.message_rounded,
              color: onMessage == null
                  ? (isDark ? Colors.white24 : AppColors.textSecondary)
                  : AppColors.primary,
              size: 19,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: (isAssigned ? AppColors.success : AppColors.warning)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isAssigned ? 'Assigned' : 'Open',
              style: AppTypography.caption.copyWith(
                color: isAssigned ? AppColors.success : AppColors.warning,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelHeader({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required String count,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.h6.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _buildOverviewPill(label: count, color: color, isDark: isDark),
      ],
    );
  }

  void _openMessageCenter({
    required String role,
    required Map<String, dynamic> recipient,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;
    final messageController = TextEditingController();
    final subjectController = TextEditingController(text: 'Farm update');
    String selectedTopic = 'Operations';

    Widget content(StateSetter setModalState) {
      final recipientName = _value(recipient, ['name'], fallback: role);
      final recipientEmail =
          _value(recipient, ['email'], fallback: 'Assigned user');
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.forum_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Message Center',
                        style: AppTypography.h6.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$role - $recipientName',
                        style: AppTypography.caption.copyWith(
                          color:
                              isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.03)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withOpacity(0.14),
                    child: Text(
                      recipientName.isEmpty
                          ? 'U'
                          : recipientName.characters.first.toUpperCase(),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipientName,
                          style: AppTypography.bodyMedium.copyWith(
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          recipientEmail,
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? Colors.white60
                                : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildOverviewPill(
                    label: role,
                    color: AppColors.info,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Operations', 'Issue', 'Batch', 'Finance']
                  .map(
                    (topic) => _buildReadingFilterChip(
                      label: topic,
                      isSelected: selectedTopic == topic,
                      isDark: isDark,
                      onTap: () => setModalState(() => selectedTopic = topic),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: subjectController,
              decoration: InputDecoration(
                labelText: 'Subject',
                prefixIcon: const Icon(Icons.subject_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: messageController,
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'Message',
                hintText: 'Write a message for $recipientName...',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 72),
                  child: Icon(Icons.edit_note_rounded),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final body = messageController.text.trim();
                      if (body.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enter a message before sending.'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Message sent to $recipientName about $selectedTopic.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (isMobile) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => StatefulBuilder(builder: (_, setModalState) {
          return SingleChildScrollView(child: content(setModalState));
        }),
      ).whenComplete(() {
        messageController.dispose();
        subjectController.dispose();
      });
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: StatefulBuilder(builder: (_, setModalState) {
            return SingleChildScrollView(child: content(setModalState));
          }),
        ),
      ),
    ).whenComplete(() {
      messageController.dispose();
      subjectController.dispose();
    });
  }

  Widget _buildTechnicalIssues(bool isDark, bool isTabletOrMobile) {
    final issues = _ownerBatches
        .where((batch) =>
            _value(batch, ['technical_issues']).trim().isNotEmpty &&
            _normalise(_value(batch, ['technical_issues'])) != 'none')
        .toList();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(
            isDark: isDark,
            icon: Icons.construction_rounded,
            title: 'Technical Issues',
            subtitle: 'Current exceptions reported from production batches',
            count: '${issues.length}',
            color: issues.isEmpty ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.md),
          if (issues.isEmpty)
            _buildEmptyPanelMessage(
              isDark: isDark,
              icon: Icons.verified_rounded,
              message: 'No technical issues reported for your farms.',
            )
          else
            ...issues.map(
              (issue) => _buildIssueRow(issue, isDark, isTabletOrMobile),
            ),
        ],
      ),
    );
  }

  Widget _buildIssueRow(
      Map<String, dynamic> issue, bool isDark, bool isTabletOrMobile) {
    final status =
        _value(issue, ['production_status'], fallback: 'In Progress');
    final statusColor = _statusColor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.report_problem_rounded,
              color: statusColor,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _value(issue, ['technical_issues'],
                      fallback: 'Technical issue reported'),
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_value(issue, [
                        'farm_name'
                      ], fallback: 'Owned farm')} - ${_relativeTime(_dateValue(issue['updated_at'] ?? issue['created_at']))}',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: AppTypography.caption.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatches(bool isDark, bool isTabletOrMobile) {
    final batches = _ownerBatches;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelHeader(
            isDark: isDark,
            icon: Icons.stacked_line_chart_rounded,
            title: 'Batch Progress',
            subtitle: 'Latest crop movement and harvest progress',
            count: '${batches.length}',
            color: AppColors.info,
          ),
          const SizedBox(height: AppSpacing.md),
          if (batches.isEmpty)
            _buildEmptyPanelMessage(
              isDark: isDark,
              icon: Icons.inventory_2_rounded,
              message: 'No batches found for your farms yet.',
            )
          else
            ...batches.take(6).map((batch) => _buildBatchRow(batch, isDark)),
        ],
      ),
    );
  }

  Widget _buildEmptyPanelMessage({
    required bool isDark,
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.success, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchRow(Map<String, dynamic> batch, bool isDark) {
    final transplanted = _numValue(batch['total_transplanted']);
    final harvested = _numValue(batch['total_harvested']);
    final progress = transplanted <= 0
        ? _batchProgressFromStatus(_value(batch, ['production_status']))
        : (harvested / transplanted).clamp(0.0, 1.0).toDouble();
    final status =
        _value(batch, ['production_status'], fallback: 'In Progress');
    final statusColor = status == 'Completed' || status == 'Delivered'
        ? AppColors.success
        : status == 'Growing'
            ? AppColors.info
            : AppColors.warning;
    final progressPercent = (progress * 100).clamp(0, 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.spa_rounded,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${_value(batch, ['batch_code', 'batch_id'], fallback: 'Batch')} - ${_value(batch, [
                        'plant_type',
                        'crop',
                        'crop_variety'
                      ], fallback: 'Crop')}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$progressPercent%',
                style: AppTypography.caption.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_formatCompact(harvested)} harvested - ${_formatCompact(transplanted)} planted',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: AppTypography.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'solved':
      case 'completed':
      case 'delivered':
        return AppColors.success;
      case 'in progress':
      case 'growing':
        return AppColors.info;
      case 'damaged':
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  double _batchProgressFromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'planted':
        return 0.2;
      case 'growing':
        return 0.45;
      case 'harvested':
        return 0.75;
      case 'delivered':
      case 'completed':
        return 1.0;
      default:
        return 0.1;
    }
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

class _SensorStatus {
  final String label;
  final Color color;
  final bool isAlert;

  const _SensorStatus({
    required this.label,
    required this.color,
    required this.isAlert,
  });
}
