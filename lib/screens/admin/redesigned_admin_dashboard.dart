import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

class RedesignedAdminDashboard extends ConsumerStatefulWidget {
  const RedesignedAdminDashboard({super.key});

  @override
  ConsumerState<RedesignedAdminDashboard> createState() =>
      _RedesignedAdminDashboardState();
}

class _RedesignedAdminDashboardState
    extends ConsumerState<RedesignedAdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedPeriod = 'Today';
  String _selectedFarm = 'All Farms';
  final SuperAdminApiService _api = SuperAdminApiService();
  bool _isLoading = true;
  String? _loadError;

  final List<Map<String, dynamic>> _users = [];
  final List<Map<String, dynamic>> _farmsData = [];
  final List<Map<String, dynamic>> _sensors = [];
  final List<Map<String, dynamic>> _inventory = [];
  final List<Map<String, dynamic>> _deliveries = [];
  final List<Map<String, dynamic>> _audits = [];

  List<String> get _farms {
    final names = _farmsData
        .map((farm) => (farm['name'] ?? farm['farm_name'] ?? '').toString())
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All Farms', ...names];
  }

  final List<_OperationShortcut> _shortcuts = const [
    _OperationShortcut(
      title: 'User Administration',
      description: 'Manage roles, access, and farm team assignments.',
      route: '/users',
      icon: Icons.people_alt_rounded,
      color: AppColors.chartBlue,
    ),
    _OperationShortcut(
      title: 'Farm Operations',
      description: 'Review farm status, managers, locations, and capacity.',
      route: '/farms',
      icon: Icons.agriculture_rounded,
      color: AppColors.primary,
    ),
    _OperationShortcut(
      title: 'Crop Varieties',
      description: 'Review crop varieties and production specifications.',
      route: '/crop-varieties',
      icon: Icons.grass_rounded,
      color: AppColors.success,
    ),
    _OperationShortcut(
      title: 'Sensor Command',
      description: 'Monitor telemetry health and device availability.',
      route: '/sensors',
      icon: Icons.sensors_rounded,
      color: AppColors.chartTeal,
    ),
    _OperationShortcut(
      title: 'Analytics Center',
      description: 'Track production, climate trends, and operational KPIs.',
      route: '/analytics',
      icon: Icons.analytics_rounded,
      color: AppColors.chartPurple,
    ),
    _OperationShortcut(
      title: 'Inventory Control',
      description: 'Audit global stock, farm allocations, and shortages.',
      route: '/inventory-admin',
      icon: Icons.inventory_2_rounded,
      color: AppColors.warning,
    ),
    _OperationShortcut(
      title: 'Delivery Control',
      description: 'Coordinate dispatches, ETAs, and farm fulfillment status.',
      route: '/deliveries-admin',
      icon: Icons.local_shipping_rounded,
      color: AppColors.chartOrange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        _api.getUsers(),
        _api.getFarms(),
        _api.getSensors(),
        _api.getInventory(),
        _api.getFulfillments(),
        _api.getAudits(),
      ]);
      if (!mounted) return;
      setState(() {
        _users
          ..clear()
          ..addAll(results[0]);
        _farmsData
          ..clear()
          ..addAll(results[1]);
        _sensors
          ..clear()
          ..addAll(results[2]);
        _inventory
          ..clear()
          ..addAll(results[3]);
        _deliveries
          ..clear()
          ..addAll(results[4]);
        _audits
          ..clear()
          ..addAll(results[5]);
        if (!_farms.contains(_selectedFarm)) _selectedFarm = 'All Farms';
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

  List<Map<String, dynamic>> get _scopedFarms {
    if (_selectedFarm == 'All Farms') return _farmsData;
    return _farmsData.where((farm) {
      return (farm['name'] ?? farm['farm_name'] ?? '').toString() ==
          _selectedFarm;
    }).toList();
  }

  List<Map<String, dynamic>> get _scopedSensors {
    if (_selectedFarm == 'All Farms') return _sensors;
    return _sensors.where((sensor) {
      return (sensor['farm_name'] ?? '').toString() == _selectedFarm;
    }).toList();
  }

  List<Map<String, dynamic>> get _scopedInventory {
    if (_selectedFarm == 'All Farms') return _inventory;
    final farmIds =
        _scopedFarms.map((farm) => (farm[r'$id'] ?? '').toString()).toSet();
    return _inventory.where((item) {
      return farmIds
              .contains((item['farm_id'] ?? item['farmID'] ?? '').toString()) ||
          (item['farm_name'] ?? '').toString() == _selectedFarm;
    }).toList();
  }

  List<Map<String, dynamic>> get _scopedDeliveries {
    if (_selectedFarm == 'All Farms') return _deliveries;
    return _deliveries.where((item) {
      return (item['farm_name'] ?? '').toString() == _selectedFarm;
    }).toList();
  }

  List<_DashboardMetric> get _metrics {
    final farms = _scopedFarms;
    final activeFarms =
        farms.where((farm) => _status(farm['status']) == 'active').length;
    final pendingFarms =
        farms.where((farm) => _status(farm['status']) == 'pending').length;
    final activeUsers =
        _users.where((user) => _status(user['status']) == 'active').length;
    final sensors = _scopedSensors;
    final onlineSensors = sensors.where(_isSensorOnline).length;
    final criticalSensors = sensors.where((sensor) {
      final status = _status(sensor['status']);
      return status == 'faulty' || status == 'critical';
    }).length;
    final warningSensors = sensors.where((sensor) {
      final status = _status(sensor['status']);
      return status == 'maintenance' || status == 'warning';
    }).length;
    final lowStock = _scopedInventory.where(_isLowStock).length;
    final pendingDeliveries = _scopedDeliveries.where((delivery) {
      final status = _status(delivery['status'] ?? delivery['delivery_status']);
      return status.contains('pending') ||
          status.contains('assigned') ||
          status.contains('in transit') ||
          status.contains('dispatch');
    }).length;
    final delivered = _scopedDeliveries.where((delivery) {
      final status = _status(delivery['status'] ?? delivery['delivery_status']);
      return status.contains('delivered') || status.contains('completed');
    }).length;
    final deliveryTotal = _scopedDeliveries.length;

    return [
      _DashboardMetric(
        title: 'Managed Farms',
        value: '${farms.length}',
        helper: '$activeFarms active, $pendingFarms pending',
        trend: _selectedFarm == 'All Farms' ? 'All estates' : _selectedFarm,
        icon: Icons.agriculture_rounded,
        color: AppColors.primary,
        progress: farms.isEmpty ? 0 : activeFarms / farms.length,
      ),
      _DashboardMetric(
        title: 'Team Members',
        value: '${_users.length}',
        helper: '$activeUsers active users',
        trend:
            '${_users.where((u) => _role(u['role']).contains('manager')).length} managers',
        icon: Icons.groups_2_rounded,
        color: AppColors.chartBlue,
        progress: _users.isEmpty ? 0 : activeUsers / _users.length,
      ),
      _DashboardMetric(
        title: 'Sensor Health',
        value: sensors.isEmpty
            ? '0%'
            : '${((onlineSensors / sensors.length) * 100).round()}%',
        helper: '$onlineSensors of ${sensors.length} reporting',
        trend: '${criticalSensors + warningSensors} need review',
        icon: Icons.sensors_rounded,
        color: AppColors.chartTeal,
        progress: sensors.isEmpty ? 0 : onlineSensors / sensors.length,
      ),
      _DashboardMetric(
        title: 'Open Alerts',
        value: '${criticalSensors + warningSensors + lowStock}',
        helper: '$criticalSensors critical sensors',
        trend: '$lowStock low stock',
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        progress:
            (criticalSensors + warningSensors + lowStock).clamp(0, 10) / 10,
      ),
      _DashboardMetric(
        title: 'Inventory Coverage',
        value: '${_scopedInventory.length}',
        helper: 'Inventory records',
        trend: '$lowStock below reorder',
        icon: Icons.inventory_2_rounded,
        color: AppColors.chartPurple,
        progress: _scopedInventory.isEmpty
            ? 0
            : ((_scopedInventory.length - lowStock) / _scopedInventory.length)
                .clamp(0, 1),
      ),
      _DashboardMetric(
        title: 'Deliveries',
        value: '$deliveryTotal',
        helper: '$delivered completed, $pendingDeliveries active',
        trend: deliveryTotal == 0
            ? 'No deliveries'
            : '${((delivered / deliveryTotal) * 100).round()}% complete',
        icon: Icons.local_shipping_rounded,
        color: AppColors.chartOrange,
        progress: deliveryTotal == 0 ? 0 : delivered / deliveryTotal,
      ),
    ];
  }

  List<_AdminAlert> get _alerts {
    final alerts = <_AdminAlert>[];
    for (final sensor in _scopedSensors) {
      final status = _status(sensor['status']);
      if (status == 'faulty' ||
          status == 'critical' ||
          status == 'maintenance') {
        final isCritical = status == 'faulty' || status == 'critical';
        alerts.add(_AdminAlert(
          title:
              '${_label(sensor['sensortype'])} sensor ${isCritical ? 'critical' : 'needs maintenance'}',
          farm: (sensor['farm_name'] ?? 'Unassigned Farm').toString(),
          severity: isCritical ? 'High' : 'Medium',
          time: _timeAgo(sensor['timestamp']),
          icon: Icons.sensors_rounded,
          color: isCritical ? AppColors.error : AppColors.warning,
        ));
      }
    }
    for (final item in _scopedInventory.where(_isLowStock)) {
      alerts.add(_AdminAlert(
        title:
            '${item['item_name'] ?? item['item_id'] ?? 'Inventory item'} below reorder level',
        farm: (item['farm_name'] ?? item['supplier_name'] ?? 'Inventory')
            .toString(),
        severity: 'Medium',
        time: _timeAgo(item['date_added'] ?? item[r'$updatedAt']),
        icon: Icons.inventory_rounded,
        color: AppColors.warning,
      ));
    }
    alerts.sort((a, b) =>
        _severityRank(b.severity).compareTo(_severityRank(a.severity)));
    return alerts.take(4).toList();
  }

  List<_ActivityItem> get _activities {
    final sorted = [..._audits]..sort((a, b) =>
        (b['timestamp'] ?? b[r'$createdAt'] ?? '')
            .toString()
            .compareTo((a['timestamp'] ?? a[r'$createdAt'] ?? '').toString()));
    return sorted.take(5).map((audit) {
      final collection = (audit['collection_name'] ?? 'Platform').toString();
      final action = (audit['action_type'] ?? 'Update').toString();
      return _ActivityItem(
        title: '$action $collection',
        detail:
            (audit['action_details'] ?? 'Backend activity recorded').toString(),
        time: _timeAgo(audit['timestamp'] ?? audit[r'$createdAt']),
        icon: _activityIcon(collection),
      );
    }).toList();
  }

  List<_FarmPerformance> get _farmPerformance {
    final farms = _scopedFarms.take(6).map((farm) {
      final farmName =
          (farm['name'] ?? farm['farm_name'] ?? 'Unnamed Farm').toString();
      final farmId = (farm[r'$id'] ?? farm['farm_id'] ?? '').toString();
      final sensors = _sensors.where((sensor) {
        return (sensor['farmID'] ?? '').toString() == farmId ||
            (sensor['farm_name'] ?? '').toString() == farmName;
      }).toList();
      final online = sensors.where(_isSensorOnline).length;
      final sensorHealth =
          sensors.isEmpty ? 0 : ((online / sensors.length) * 100).round();
      final status = _status(farm['status']);
      final farmHealth = status == 'active'
          ? (sensors.isEmpty ? 80 : sensorHealth)
          : status == 'pending'
              ? 45
              : 25;
      final alerts = sensors.where((sensor) {
        final sensorStatus = _status(sensor['status']);
        return sensorStatus == 'faulty' ||
            sensorStatus == 'critical' ||
            sensorStatus == 'maintenance';
      }).length;
      final color = farmHealth >= 80
          ? AppColors.success
          : farmHealth >= 55
              ? AppColors.warning
              : AppColors.error;
      return _FarmPerformance(
        name: farmName,
        manager: _userName(farm['ownerID']) == '-'
            ? _userName(farm['caretakerID'])
            : _userName(farm['ownerID']),
        health: farmHealth.clamp(0, 100),
        yieldScore: sensorHealth.clamp(0, 100),
        alerts: alerts,
        status: farmHealth >= 80
            ? 'Healthy'
            : farmHealth >= 55
                ? 'Watch'
                : 'Risk',
        color: color,
      );
    }).toList();
    return farms;
  }

  List<(String, IconData, Color)> get _priorities {
    final sensorIssues =
        _alerts.where((alert) => alert.icon == Icons.sensors_rounded).length;
    final lowStock = _scopedInventory.where(_isLowStock).length;
    final activeDeliveries = _scopedDeliveries.where((delivery) {
      final status = _status(delivery['status'] ?? delivery['delivery_status']);
      return status.contains('pending') || status.contains('in transit');
    }).length;
    return [
      if (sensorIssues > 0)
        (
          'Review $sensorIssues sensor alerts',
          Icons.sensors_rounded,
          AppColors.error
        ),
      if (lowStock > 0)
        (
          'Restock $lowStock low inventory items',
          Icons.inventory_rounded,
          AppColors.warning
        ),
      if (activeDeliveries > 0)
        (
          'Track $activeDeliveries active deliveries',
          Icons.local_shipping_rounded,
          AppColors.info
        ),
      if (sensorIssues == 0 && lowStock == 0 && activeDeliveries == 0)
        (
          'No urgent admin priorities',
          Icons.task_alt_rounded,
          AppColors.success
        ),
    ];
  }

  int get _operationalReadiness {
    final farmScore = _scopedFarms.isEmpty
        ? 0
        : ((_scopedFarms.where((f) => _status(f['status']) == 'active').length /
                    _scopedFarms.length) *
                100)
            .round();
    final sensorScore = _scopedSensors.isEmpty
        ? 0
        : ((_scopedSensors.where(_isSensorOnline).length /
                    _scopedSensors.length) *
                100)
            .round();
    if (_scopedFarms.isEmpty && _scopedSensors.isEmpty) return 0;
    return ((farmScore + sensorScore) / 2).round();
  }

  String _status(dynamic value) =>
      (value ?? '').toString().trim().toLowerCase();

  String _role(dynamic value) => (value ?? '').toString().trim().toLowerCase();

  String _label(dynamic value) {
    final text = (value ?? '').toString().replaceAll('_', ' ').trim();
    if (text.isEmpty) return 'Unknown';
    return text
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _isLowStock(Map<String, dynamic> item) {
    final quantity = _number(item['quantity_available'] ?? item['quantity']);
    final reorder = _number(item['reorder_level']);
    return reorder > 0 && quantity <= reorder;
  }

  bool _isSensorOnline(Map<String, dynamic> sensor) {
    final parsed = DateTime.tryParse((sensor['timestamp'] ?? '').toString());
    if (parsed == null) return false;
    final diff = DateTime.now().difference(parsed.toLocal());
    return diff.inSeconds >= -5 && diff.inSeconds <= 20;
  }

  String _timeAgo(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '-';
    final diff = DateTime.now().difference(parsed.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  int _severityRank(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  IconData _activityIcon(String collection) {
    final text = collection.toLowerCase();
    if (text.contains('user')) return Icons.people_alt_rounded;
    if (text.contains('farm')) return Icons.agriculture_rounded;
    if (text.contains('sensor')) return Icons.sensors_rounded;
    if (text.contains('inventory')) return Icons.inventory_rounded;
    if (text.contains('delivery') || text.contains('fulfillment')) {
      return Icons.local_shipping_rounded;
    }
    return Icons.history_rounded;
  }

  String _userName(dynamic id) {
    final key = (id ?? '').toString();
    if (key.isEmpty || key == 'Unassigned') return '-';
    for (final user in _users) {
      if ((user[r'$id'] ?? user['id'] ?? user['user_id'] ?? '').toString() ==
              key ||
          (user['email'] ?? '').toString() == key) {
        return (user['name'] ?? key).toString();
      }
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final userName = user?.name ?? 'Admin';
    final userEmail = user?.email ?? '';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? AdminDrawer(
              selectedIndex: 0,
              onItemSelected: (_) {},
              userName: userName,
              userEmail: userEmail,
              userRole: 'Administrator',
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail),
      bottomNavigationBar: isMobile
          ? AdminMobileBottomNav(
              selectedIndex: 0,
              onItemSelected: (_) {},
            )
          : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail) {
    return Row(
      children: [
        ModernAdminSidebar(
          selectedIndex: 0,
          onItemSelected: _noopNav,
          userName: userName,
          userEmail: userEmail,
          userRole: 'Administrator',
        ),
        Expanded(
          child: Column(
            children: [
              ModernAdminHeader(
                userName: userName.split(' ').first,
                farms: _farms,
                selectedFarm: _selectedFarm,
                onFarmChanged: (farm) {
                  if (farm != null) setState(() => _selectedFarm = farm);
                },
                onNotificationTap: _showNotifications,
                onProfileTap: _showProfileMenu,
              ),
              Expanded(
                child: _buildContent(isDark, AppSpacing.xl, isMobile: false),
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
        ModernAdminHeader(
          userName: userName.split(' ').first,
          farms: _farms,
          selectedFarm: _selectedFarm,
          onFarmChanged: (farm) {
            if (farm != null) setState(() => _selectedFarm = farm);
          },
          onNotificationTap: _showNotifications,
          onProfileTap: _showProfileMenu,
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: _buildContent(isDark, AppSpacing.md, isMobile: true),
        ),
      ],
    );
  }

  Widget _buildContent(
    bool isDark,
    double padding, {
    required bool isMobile,
  }) {
    if (_isLoading) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: const AdminDataSkeleton(rowCount: 6),
      );
    }

    if (_loadError != null) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: _buildErrorState(isDark),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(isDark, isMobile),
          const SizedBox(height: AppSpacing.lg),
          _buildPeriodFilter(isDark, isMobile),
          SizedBox(height: isMobile ? 0 : AppSpacing.lg),
          Transform.translate(
            offset: Offset(0, isMobile ? -40 : 0),
            transformHitTests: false,
            child: _buildMetricsGrid(isMobile),
          ),
          const SizedBox(height: AppSpacing.xl),
          Transform.translate(
            offset: Offset(0, isMobile ? -40 : 0),
            child: _buildOperationsGrid(isDark, isMobile),
          ),
          const SizedBox(height: AppSpacing.xl),
          Transform.translate(
            offset: Offset(0, isMobile ? -70 : 0),
            child: _buildInsightSection(isDark, isMobile),
          ),
          Transform.translate(
            offset: Offset(0, isMobile ? -70 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                _buildFarmPerformanceSection(isDark, isMobile),
                const SizedBox(height: AppSpacing.xl),
                _buildActivityFeed(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Unable to load admin dashboard',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(bool isDark, bool isMobile) {
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
                  AppColors.primaryDark.withValues(alpha: .85),
                  const Color(0xFF123F2A),
                  AppColors.surfaceDark,
                ]
              : [
                  const Color(0xFFE9F8EA),
                  const Color(0xFFF8FFF3),
                  Colors.white,
                ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: .08)
              : AppColors.primary.withValues(alpha: .16),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? .08 : .12),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          return Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: compact ? 0 : 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScopePill(isDark),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Admin Operations Dashboard',
                      style: AppTypography.h3.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Central view for farm operations, people, sensors, inventory, and delivery execution across $_selectedFarm.',
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: .74)
                            : AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) const SizedBox(width: AppSpacing.xl),
              SizedBox(height: compact ? AppSpacing.lg : 0),
              Expanded(
                flex: compact ? 0 : 2,
                child: _buildHeroPanel(isDark),
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
        color: isDark
            ? Colors.white.withValues(alpha: .08)
            : AppColors.primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: .10)
              : AppColors.primary.withValues(alpha: .16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 17,
            color: isDark ? Colors.white : AppColors.primaryDark,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Administrator Control Layer',
            style: AppTypography.label.copyWith(
              color: isDark ? Colors.white : AppColors.primaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPanel(bool isDark) {
    final criticalItems =
        _alerts.where((alert) => alert.severity == 'High').length;
    final delivered = _scopedDeliveries.where((delivery) {
      final status = _status(delivery['status'] ?? delivery['delivery_status']);
      return status.contains('delivered') || status.contains('completed');
    }).length;
    final deliveryRate = _scopedDeliveries.isEmpty
        ? 0
        : ((delivered / _scopedDeliveries.length) * 100).round();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.white)
            .withValues(alpha: isDark ? .08 : .82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: .10)
              : AppColors.neutral300.withValues(alpha: .72),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroPanelRow(
            isDark,
            Icons.task_alt_rounded,
            'Operational readiness',
            '$_operationalReadiness%',
            AppColors.success,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildHeroPanelRow(
            isDark,
            Icons.priority_high_rounded,
            'Critical items',
            '$criticalItems',
            AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildHeroPanelRow(
            isDark,
            Icons.schedule_rounded,
            'Delivery completion',
            '$deliveryRate%',
            AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPanelRow(
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
            color: color.withValues(alpha: .16),
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
                  ? Colors.white.withValues(alpha: .74)
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodFilter(bool isDark, bool isMobile) {
    const periods = ['Today', 'Week', 'Month', 'Quarter'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final chips = periods.map((period) {
          final selected = _selectedPeriod == period;
          return ChoiceChip(
            label: Text(period),
            selected: selected,
            onSelected: (_) => setState(() => _selectedPeriod = period),
            selectedColor: AppColors.primary.withValues(alpha: .14),
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            side: BorderSide(
              color: selected
                  ? AppColors.primary.withValues(alpha: .55)
                  : (isDark
                      ? Colors.white.withValues(alpha: .10)
                      : AppColors.neutral300),
            ),
            checkmarkColor: AppColors.primary,
            labelStyle: AppTypography.label.copyWith(
              color: selected
                  ? AppColors.primary
                  : (isDark ? Colors.white : AppColors.textSecondary),
              fontWeight: FontWeight.w500,
            ),
          );
        }).toList();

        if (isMobile) {
          final chipWidth =
              (constraints.maxWidth - (AppSpacing.sm * 3)) / periods.length;
          return Row(
            children: chips
                .map(
                  (chip) => SizedBox(width: chipWidth, child: chip),
                )
                .toList(),
          );
        }

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: chips,
        );
      },
    );
  }

  Widget _buildMetricsGrid(bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = isMobile
            ? 2
            : width >= 1200
                ? 3
                : width >= 760
                    ? 2
                    : 1;
        final gridDelegate = isMobile
            ? SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                mainAxisExtent: 174,
              )
            : SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: width < 430 ? 1.35 : 1.72,
              );
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _metrics.length,
          gridDelegate: gridDelegate,
          itemBuilder: (context, index) =>
              _MetricCard(metric: _metrics[index], compact: isMobile),
        );
      },
    );
  }

  Widget _buildOperationsGrid(bool isDark, bool isMobile) {
    return _DashboardSection(
      title: 'Operations Console',
      subtitle: 'Fast access to the admin areas used to run daily operations.',
      trailing: _buildTextButton('System Settings', '/settings'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 1100
              ? 3
              : width >= 720
                  ? 2
                  : 1;
          final gridDelegate = isMobile
              ? const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 5,
                  mainAxisExtent: 117,
                )
              : SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: width < 430 ? 1.38 : 1.9,
                );
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _shortcuts.length,
            gridDelegate: gridDelegate,
            itemBuilder: (context, index) {
              final card = _OperationCard(
                shortcut: _shortcuts[index],
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  _shortcuts[index].route,
                ),
              );
              return isMobile
                  ? Transform.translate(
                      offset: const Offset(0, -50),
                      child: card,
                    )
                  : card;
            },
          );
        },
      ),
    );
  }

  Widget _buildInsightSection(bool isDark, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 900;
        final children = [
          Expanded(
            flex: stacked ? 0 : 3,
            child: _buildAlertPanel(isDark),
          ),
          SizedBox(
              width: stacked ? 0 : AppSpacing.md,
              height: stacked ? AppSpacing.md : 0),
          Expanded(
            flex: stacked ? 0 : 2,
            child: _buildPriorityPanel(isDark),
          ),
        ];

        return stacked
            ? Column(children: children)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children);
      },
    );
  }

  Widget _buildAlertPanel(bool isDark) {
    return _Panel(
      title: 'Operational Alerts',
      subtitle: 'Items that need admin review',
      child: _alerts.isEmpty
          ? _EmptyPanelMessage(
              icon: Icons.task_alt_rounded,
              message: 'No operational alerts from backend records.',
            )
          : Column(
              children: _alerts
                  .map(
                    (alert) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _AlertRow(alert: alert),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildPriorityPanel(bool isDark) {
    return _Panel(
      title: 'Today\'s Priorities',
      subtitle: 'Admin tasks ordered by impact',
      child: Column(
        children: _priorities.map((priority) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: _cardDecoration(context),
            child: Row(
              children: [
                Icon(priority.$2, color: priority.$3, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    priority.$1,
                    style: AppTypography.bodyMedium.copyWith(
                      color: _textColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFarmPerformanceSection(bool isDark, bool isMobile) {
    return _DashboardSection(
      title: 'Farm Performance Snapshot',
      subtitle: 'Live operating score by farm and manager.',
      trailing: _buildTextButton('View Farms', '/farms'),
      child: _farmPerformance.isEmpty
          ? _EmptyPanelMessage(
              icon: Icons.agriculture_rounded,
              message: 'No farms are available from the backend yet.',
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 920 ? 3 : 1;
                final gridDelegate = isMobile
                    ? const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        mainAxisExtent: 200,
                      )
                    : SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio:
                            constraints.maxWidth < 430 ? 1.35 : 1.55,
                      );
                return Transform.translate(
                  offset: Offset(0, isMobile ? -50 : 0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _farmPerformance.length,
                    gridDelegate: gridDelegate,
                    itemBuilder: (context, index) =>
                        _FarmPerformanceCard(farm: _farmPerformance[index]),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildActivityFeed(bool isDark) {
    return _Panel(
      title: 'Recent Admin Activity',
      subtitle: 'Latest changes across users, farms, inventory, and sensors',
      child: _activities.isEmpty
          ? _EmptyPanelMessage(
              icon: Icons.history_rounded,
              message: 'No audit activity has been recorded yet.',
            )
          : Column(
              children: _activities
                  .map(
                    (activity) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ActivityRow(activity: activity),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildTextButton(String label, String route) {
    return TextButton.icon(
      onPressed: () => Navigator.pushReplacementNamed(context, route),
      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
      label: Text(label),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    const items = [
      (Icons.dashboard_rounded, 'Dashboard', '/dashboard'),
      (Icons.people_alt_rounded, 'Users', '/users'),
      (Icons.agriculture_rounded, 'Farms', '/farms'),
      (Icons.sensors_rounded, 'Sensors', '/sensors'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: .08)
                : AppColors.neutral300,
          ),
        ),
      ),
      child: Row(
        children: items.map((item) {
          final selected = item.$2 == 'Dashboard';
          return Expanded(
            child: InkWell(
              onTap: () {
                if (!selected) Navigator.pushReplacementNamed(context, item.$3);
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: .14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.$1,
                      size: 21,
                      color: selected
                          ? AppColors.primary
                          : (isDark
                              ? Colors.white.withValues(alpha: .68)
                              : AppColors.textSecondary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: selected
                            ? AppColors.primary
                            : (isDark
                                ? Colors.white.withValues(alpha: .68)
                                : AppColors.textSecondary),
                        fontWeight:
                            selected ? FontWeight.w500 : FontWeight.w500,
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

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications panel coming soon')),
    );
  }

  void _showProfileMenu() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Admin profile panel coming soon')),
    );
  }
}

void _noopNav(int _) {}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric, this.compact = false});

  final _DashboardMetric metric;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : AppSpacing.lg),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 38 : 46,
                height: compact ? 38 : 46,
                decoration: BoxDecoration(
                  color: metric.color.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Icon(metric.icon,
                    color: metric.color, size: compact ? 20 : 24),
              ),
              const Spacer(),
              Text(
                metric.trend,
                style: AppTypography.caption.copyWith(
                  color: metric.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            metric.value,
            style: (compact ? AppTypography.titleLarge : AppTypography.h3)
                .copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: _mutedTextColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: metric.progress,
              minHeight: 6,
              backgroundColor: metric.color.withValues(alpha: .12),
              valueColor: AlwaysStoppedAnimation(metric.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({required this.shortcut, required this.onTap});

  final _OperationShortcut shortcut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: _cardDecoration(context),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: shortcut.color.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(shortcut.icon, color: shortcut.color, size: 27),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shortcut.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        color: _textColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      shortcut.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: _mutedTextColor(context),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: _mutedTextColor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmPerformanceCard extends StatelessWidget {
  const _FarmPerformanceCard({required this.farm});

  final _FarmPerformance farm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        color: _textColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      farm.manager,
                      style: AppTypography.bodySmall.copyWith(
                        color: _mutedTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: farm.status, color: farm.color),
            ],
          ),
          const Spacer(),
          _ScoreRow(
              label: 'Farm health', value: farm.health, color: farm.color),
          const SizedBox(height: AppSpacing.md),
          _ScoreRow(
            label: 'Yield score',
            value: farm.yieldScore,
            color: AppColors.chartBlue,
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                size: 18,
                color: farm.alerts > 5 ? AppColors.warning : AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${farm.alerts} active alerts',
                style: AppTypography.bodySmall.copyWith(
                  color: _mutedTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert});

  final _AdminAlert alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: alert.color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(alert.icon, color: alert.color, size: 23),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: _textColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${alert.farm} - ${alert.time}',
                  style: AppTypography.bodySmall.copyWith(
                    color: _mutedTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatusBadge(label: alert.severity, color: alert.color),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final _ActivityItem activity;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Icon(activity.icon, color: AppColors.primary, size: 21),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: .08)
                      : AppColors.neutral300,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: AppTypography.bodyMedium.copyWith(
                          color: _textColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activity.detail,
                        style: AppTypography.bodySmall.copyWith(
                          color: _mutedTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  activity.time,
                  style: AppTypography.caption.copyWith(
                    color: _mutedTextColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: _mutedTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$value%',
              style: AppTypography.bodySmall.copyWith(
                color: _textColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 7,
            backgroundColor: color.withValues(alpha: .12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: .24)),
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

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, subtitle: subtitle, trailing: trailing),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _EmptyPanelMessage extends StatelessWidget {
  const _EmptyPanelMessage({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Icon(icon, color: AppColors.success, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: _mutedTextColor(context),
                fontWeight: FontWeight.w500,
              ),
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
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: _textColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: _mutedTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: isDark ? AppColors.surfaceDark : Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: .08)
          : AppColors.neutral300.withValues(alpha: .72),
    ),
    boxShadow: [
      if (!isDark)
        BoxShadow(
          color: Colors.black.withValues(alpha: .045),
          blurRadius: 20,
          offset: const Offset(0, 12),
        ),
    ],
  );
}

Color _textColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : AppColors.textPrimary;
}

Color _mutedTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: .68)
      : AppColors.textSecondary;
}

class _DashboardMetric {
  const _DashboardMetric({
    required this.title,
    required this.value,
    required this.helper,
    required this.trend,
    required this.icon,
    required this.color,
    required this.progress,
  });

  final String title;
  final String value;
  final String helper;
  final String trend;
  final IconData icon;
  final Color color;
  final double progress;
}

class _OperationShortcut {
  const _OperationShortcut({
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final String route;
  final IconData icon;
  final Color color;
}

class _FarmPerformance {
  const _FarmPerformance({
    required this.name,
    required this.manager,
    required this.health,
    required this.yieldScore,
    required this.alerts,
    required this.status,
    required this.color,
  });

  final String name;
  final String manager;
  final int health;
  final int yieldScore;
  final int alerts;
  final String status;
  final Color color;
}

class _AdminAlert {
  const _AdminAlert({
    required this.title,
    required this.farm,
    required this.severity,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String farm;
  final String severity;
  final String time;
  final IconData icon;
  final Color color;
}

class _ActivityItem {
  const _ActivityItem({
    required this.title,
    required this.detail,
    required this.time,
    required this.icon,
  });

  final String title;
  final String detail;
  final String time;
  final IconData icon;
}
