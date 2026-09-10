import '../../core/utils/sensor_connection.dart';
import '../../core/utils/sensor_calibration_policy.dart';
import '../../core/widgets/sensor_inspect_modal.dart';
import '../../core/widgets/sensor_overview_card.dart';
import '../../core/widgets/app_dialog.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/technician_header.dart';
import '../../core/widgets/technician_mobile_bottom_nav.dart';
import '../../core/widgets/technician_sidebar.dart';
import '../../core/widgets/role_mobile_navigation.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../services/superadmin_api_service.dart';

/// Sensor Management Screen for Technicians
/// Allows viewing, calibrating, and managing all farm sensors
class SensorManagementScreen extends ConsumerStatefulWidget {
  const SensorManagementScreen({super.key});

  @override
  ConsumerState<SensorManagementScreen> createState() =>
      _SensorManagementScreenState();
}

class _SensorManagementScreenState
    extends ConsumerState<SensorManagementScreen> {
  int _selectedNavIndex = 1;
  String _selectedType = 'All';
  String _selectedStatus = 'All';
  String _searchQuery = '';
  int _searchReset = 0;
  String _selectedFarmId = 'All';
  final SuperAdminApiService _api = SuperAdminApiService();
  Timer? _refreshTimer;
  Timer? _connectionTimer;
  bool _fetching = false;
  DateTime? _contextUpdated;
  List<Map<String, dynamic>> _cachedFarms = [];
  List<Map<String, dynamic>> _cachedUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _backendSensors = [];
  List<Map<String, dynamic>> _farms = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _connectionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _loadSensorData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _loadSensorData(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _connectionTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSensorData({bool silent = false}) async {
    if (_fetching) return;
    _fetching = true;
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final refreshContext = !silent ||
          _contextUpdated == null ||
          DateTime.now().difference(_contextUpdated!).inSeconds >= 30;
      final results = await Future.wait([
        _api.getSensors(),
        refreshContext ? _api.getFarms() : Future.value(_cachedFarms),
        refreshContext ? _api.getUsers() : Future.value(_cachedUsers),
      ]);
      if (!mounted) return;
      if (refreshContext) {
        _cachedFarms = results[1];
        _cachedUsers = results[2];
        _contextUpdated = DateTime.now();
      }
      final user = ref.read(currentUserProvider);
      Map<String, dynamic>? userRecord;
      for (final item in results[2]) {
        if (_value(item, ['id', r'$id']) == user?.id ||
            _value(item, ['email']) == user?.email) {
          userRecord = item;
          break;
        }
      }
      final assignedFarmIds = <String>{};
      final assignedValues = userRecord?['assignedFarmIds'] ??
          userRecord?['assigned_farm_ids'] ??
          userRecord?['assigned_farms'];
      if (assignedValues is List) {
        assignedFarmIds.addAll(assignedValues.map((value) => value.toString()));
      }
      if (assignedFarmIds.isEmpty && user?.farmId != null) {
        assignedFarmIds.add(user!.farmId!);
      }
      bool assigned(Map<String, dynamic> item) {
        final farmId = _value(item, ['farm_id', 'farmId', 'farmID']);
        return assignedFarmIds.isEmpty ||
            farmId.isEmpty ||
            assignedFarmIds.contains(farmId);
      }

      setState(() {
        _backendSensors = results[0].where(assigned).toList();
        _farms = results[1].where((farm) {
          final id = _value(farm, ['id', r'$id']);
          return assignedFarmIds.isEmpty || assignedFarmIds.contains(id);
        }).toList();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (!silent || _backendSensors.isEmpty)
          _errorMessage = error.toString();
      });
    } finally {
      _fetching = false;
    }
  }

  String _value(Map<String, dynamic> data, List<String> keys,
      [String fallback = '']) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty)
        return value.toString();
    }
    return fallback;
  }

  List<Map<String, dynamic>> _mappedSensors() {
    return _backendSensors.map((sensor) {
      final status = _value(sensor, ['status'], 'offline').toLowerCase();
      final connection = SensorConnection(sensor);
      final normalizedStatus = connection.state != 'online'
          ? connection.state
          : status == 'online' || status == 'active' || status == 'operational'
              ? 'normal'
              : (status == 'warning' || status == 'maintenance')
                  ? 'warning'
                  : (status == 'alert' || status == 'faulty')
                      ? 'alert'
                      : 'normal';
      final type = _value(sensor,
              ['sensor_type', 'sensortype', 'type', 'category'], 'sensor')
          .toLowerCase();
      final value = sensor['latest_value'] ??
          sensor['value'] ??
          sensor['reading'] ??
          '--';
      final farmId = _value(sensor, ['farm_id', 'farmId', 'farmID']);
      final farm = _farms.cast<Map<String, dynamic>?>().firstWhere(
            (item) => item != null && _value(item, ['id', r'$id']) == farmId,
            orElse: () => null,
          );
      final farmName = farm == null
          ? _value(sensor, ['farm_name'], 'Assigned farm')
          : _value(farm, ['name', 'farm_name'], 'Assigned farm');
      final last =
          DateTime.tryParse(_value(sensor, ['timestamp', 'last_seen_at']));
      final color = normalizedStatus == 'normal'
          ? AppColors.success
          : normalizedStatus == 'warning'
              ? AppColors.warning
              : normalizedStatus == 'alert'
                  ? AppColors.error
                  : AppColors.textSecondary;
      return {
        'id': _value(
            sensor, ['serial_number', 'serialNumber', 'id', r'$id'], 'Sensor'),
        'serialNumber': _value(sensor, ['serial_number', 'serialNumber']),
        'calibration_required': sensorRequiresCalibration(sensor),
        'name':
            _value(sensor, ['name', 'sensor_name', 'serial_number'], 'Sensor'),
        'type': type,
        'status': normalizedStatus,
        'reported_status': status,
        'timestamp': sensor['timestamp'] ?? sensor['last_seen_at'],
        'offline_timeout_seconds': sensor['offline_timeout_seconds'],
        'connection': connection.state,
        'connection_reason': connection.reason,
        'color': color,
        'icon': Icons.sensors,
        'value': value,
        'unit': _value(sensor, ['unit', 'measurement_unit']),
        'location': farmName,
        'farmId': farmId,
        'farmName': farmName,
        'range_min': sensor['range_min'],
        'range_max': sensor['range_max'],
        'warning_min': sensor['warning_min'],
        'warning_max': sensor['warning_max'],
        'lastReading': last,
        'lastCalibrated': DateTime.tryParse(_value(sensor, [
          'last_calibrated_at',
          'last_calibration_date',
          'last_maintenance_date'
        ])),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Technician';
    final userEmail = authState.user?.email ?? 'technician@farmestates.com';
    final sensors = _mappedSensors();

    // Filter sensors
    final filteredSensors = sensors.where((sensor) {
      if (_selectedFarmId != 'All' && sensor['farmId'] != _selectedFarmId) {
        return false;
      }
      if (_selectedType != 'All' && sensor['type'] != _selectedType)
        return false;
      if (_selectedStatus != 'All' && sensor['status'] != _selectedStatus)
        return false;
      if (_searchQuery.isNotEmpty &&
          !sensor['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? RoleMobileDrawer(
              userName: userName,
              userEmail: authState.user?.email ?? 'technician@farmestates.com',
              userRole: 'Technician',
              selectedIndex: _selectedNavIndex,
              onItemSelected: (_) {},
              items: technicianNavigationItems,
            )
          : null,
      body: _isLoading
          ? _buildLoadingShell(isDark, isMobile, userName, userEmail)
          : _errorMessage != null
              ? _buildErrorShell(isDark, isMobile, userName, userEmail)
              : isMobile
                  ? _buildMobileLayout(
                      isDark, userName, isTablet, sensors, filteredSensors)
                  : _buildDesktopLayout(
                      isDark,
                      userName,
                      userEmail,
                      isTablet,
                      sensors,
                      filteredSensors,
                    ),
      bottomNavigationBar: isMobile
          ? TechnicianMobileBottomNav(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
            )
          : null,
    );
  }

  Widget _buildLoadingShell(
      bool isDark, bool isMobile, String userName, String userEmail) {
    final content = const Center(child: AdminDataSkeleton(rowCount: 5));
    if (isMobile) {
      return Column(children: [
        TechnicianHeader(
          userName: userName,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(child: content),
      ]);
    }
    return Row(children: [
      TechnicianSidebar(
        selectedIndex: _selectedNavIndex,
        onItemSelected: (index) => setState(() => _selectedNavIndex = index),
        userName: userName,
        userEmail: userEmail,
        userRole: 'Technician',
      ),
      Expanded(
          child: Column(children: [
        TechnicianHeader(
          userName: userName,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(child: content),
      ])),
    ]);
  }

  Widget _buildErrorShell(
      bool isDark, bool isMobile, String userName, String userEmail) {
    final content = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off_outlined, size: 42),
      const SizedBox(height: AppSpacing.md),
      Text('Unable to load sensors', style: AppTypography.h6),
      const SizedBox(height: AppSpacing.sm),
      Text(_errorMessage ?? 'Please try again.'),
      const SizedBox(height: AppSpacing.md),
      ElevatedButton.icon(
          onPressed: _loadSensorData,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again')),
    ]));
    if (isMobile) {
      return Column(children: [
        TechnicianHeader(
          userName: userName,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(child: content),
      ]);
    }
    return Row(children: [
      TechnicianSidebar(
        selectedIndex: _selectedNavIndex,
        onItemSelected: (index) => setState(() => _selectedNavIndex = index),
        userName: userName,
        userEmail: userEmail,
        userRole: 'Technician',
      ),
      Expanded(
          child: Column(children: [
        TechnicianHeader(
          userName: userName,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(child: content),
      ])),
    ]);
  }

  Widget _buildDesktopLayout(
    bool isDark,
    String userName,
    String userEmail,
    bool isTablet,
    List<dynamic> sensors,
    List<dynamic> filteredSensors,
  ) {
    return Row(
      children: [
        TechnicianSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) => setState(() => _selectedNavIndex = index),
          userName: userName,
          userEmail: userEmail,
          userRole: 'Technician',
        ),
        Expanded(
          child: Column(
            children: [
              TechnicianHeader(
                userName: userName,
                onNotificationTap: () {},
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              Expanded(
                  child: _buildPageBody(
                      isDark, false, isTablet, sensors, filteredSensors)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    bool isDark,
    String userName,
    bool isTablet,
    List<dynamic> sensors,
    List<dynamic> filteredSensors,
  ) {
    return Column(
      children: [
        TechnicianHeader(
          userName: userName,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
            child: _buildPageBody(
                isDark, true, isTablet, sensors, filteredSensors)),
      ],
    );
  }

  Widget _buildPageBody(
    bool isDark,
    bool isMobile,
    bool isTablet,
    List<dynamic> sensors,
    List<dynamic> filteredSensors,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(
            isMobile ? AppSpacing.md : AppSpacing.lg,
            isMobile ? AppSpacing.md : AppSpacing.lg,
            isMobile ? AppSpacing.md : AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Sensor Management',
                  style: AppTypography.h5.copyWith(
                    fontWeight: AppTypography.headingWeight,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: isMobile ? AppTypography.sectionTitleSize : AppTypography.headingSize,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadSensorData,
                tooltip: 'Refresh Sensors',
              ),
            ],
          ),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? AppSpacing.md : AppSpacing.lg,
                    AppSpacing.xs,
                    isMobile ? AppSpacing.md : AppSpacing.lg,
                    0,
                  ),
                  child: _buildFilterPanel(isDark, isMobile),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? AppSpacing.md : AppSpacing.lg,
                    AppSpacing.md,
                    isMobile ? AppSpacing.md : AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${filteredSensors.length} Sensors',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: AppTypography.headingWeight,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                            fontSize: isMobile ? AppTypography.cardTitleSize : AppTypography.cardTitleSize,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '${sensors.where((s) => s['connection'] == 'online').length} Online',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.success,
                            fontWeight: AppTypography.headingWeight,
                            fontSize: isMobile ? AppTypography.actionSize : AppTypography.bodySize,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (filteredSensors.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? AppSpacing.md : AppSpacing.lg,
                      AppSpacing.sm,
                      isMobile ? AppSpacing.md : AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(
                          color: isDark ? Colors.white10 : AppColors.neutral200,
                        ),
                      ),
                      child: Text(
                        'No sensors match the current filters.',
                        style: AppTypography.bodyMedium.copyWith(
                          color:
                              isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? AppSpacing.md : AppSpacing.lg,
                    AppSpacing.sm,
                    isMobile ? AppSpacing.md : AppSpacing.lg,
                    isMobile ? AppSpacing.md : AppSpacing.lg,
                  ),
                  sliver: SliverLayoutBuilder(builder: (context, constraints) {
                    final columns = constraints.crossAxisExtent < 620
                        ? 1
                        : constraints.crossAxisExtent < 1020
                            ? 2
                            : 3;
                    final rows = (filteredSensors.length / columns).ceil();
                    return SliverList(
                        delegate: SliverChildBuilderDelegate(
                            (context, row) => Padding(
                                padding: EdgeInsets.only(
                                    bottom: row == rows - 1 ? 0 : 12),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (var column = 0;
                                          column < columns;
                                          column++) ...[
                                        if (column > 0)
                                          const SizedBox(width: 12),
                                        Expanded(
                                            child: row * columns + column <
                                                    filteredSensors.length
                                                ? _buildSensorCard(
                                                    filteredSensors[
                                                        row * columns + column],
                                                    isDark)
                                                : const SizedBox()),
                                      ],
                                    ])),
                            childCount: rows));
                  }),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPanel(bool isDark, bool isMobile) {
    final active = _selectedType != 'All' ||
        _selectedStatus != 'All' ||
        _selectedFarmId != 'All' ||
        _searchQuery.isNotEmpty;
    Widget farm() => _buildFilterDropdown(
        'Farm',
        _selectedFarmId,
        [
          'All',
          ..._farms
              .map((farm) => _value(farm, ['id', r'$id']))
              .where((id) => id.isNotEmpty)
              .toSet()
        ],
        (value) => setState(() => _selectedFarmId = value ?? 'All'),
        isDark,
        isMobile: isMobile);
    Widget type() => _buildFilterDropdown(
        'Type',
        _selectedType,
        [
          'All',
          'temperature',
          'humidity',
          'ph',
          'ec',
          'tds',
          'co2',
          'distance'
        ],
        (value) => setState(() => _selectedType = value ?? 'All'),
        isDark,
        isMobile: isMobile);
    Widget status() => _buildFilterDropdown(
        'Status',
        _selectedStatus,
        ['All', 'normal', 'warning', 'alert', 'offline', 'unknown'],
        (value) => setState(() => _selectedStatus = value ?? 'All'),
        isDark,
        isMobile: isMobile);
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? Colors.white10 : AppColors.neutral200)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextFormField(
              key: ValueKey(_searchReset),
              initialValue: _searchQuery,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(fontSize: AppTypography.actionSize),
              decoration: InputDecoration(
                  hintText: 'Search sensors',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: .04)
                      : AppColors.neutral50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none))),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < 540)
              return Column(children: [
                farm(),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: type()),
                  const SizedBox(width: 10),
                  Expanded(child: status())
                ])
              ]);
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: farm()),
              const SizedBox(width: 10),
              Expanded(child: type()),
              const SizedBox(width: 10),
              Expanded(child: status())
            ]);
          }),
          if (active)
            Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                    onPressed: () => setState(() {
                          _selectedFarmId = 'All';
                          _selectedType = 'All';
                          _selectedStatus = 'All';
                          _searchQuery = '';
                          _searchReset++;
                        }),
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                    label: const Text('Clear filters'))),
        ]));
  }

  Widget _buildSensorCard(Map<String, dynamic> sensor, bool isDark) =>
      SensorOverviewCard(
          sensor: sensor,
          onInspect: () => _showSensorDetails(sensor, isDark),
          onCalibrate: () => _calibrateSensor(sensor));

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
    bool isDark, {
    bool isMobile = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            fontWeight: AppTypography.headingWeight,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.sm : AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color:
                isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isDark ? Colors.white10 : AppColors.neutral200,
            ),
          ),
          child: DropdownButton<String>(
            value: value,
            items: items
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      _farms.any((farm) => _value(farm, ['id', r'$id']) == item)
                          ? _value(
                              _farms.firstWhere((farm) =>
                                  _value(farm, ['id', r'$id']) == item),
                              ['name', 'farm_name'],
                              item)
                          : item,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: isMobile ? AppTypography.captionSize : AppTypography.actionSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              size: isMobile ? 20 : 24,
            ),
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: isMobile ? AppTypography.captionSize : AppTypography.actionSize,
            ),
            dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _showSensorDetails(
      Map<String, dynamic> sensor, bool isDark) async {
    final calibrate = await showAppDialog<bool>(
      context: context,
      builder: (_) => SensorInspectModal(
          sensor: sensor,
          currentSensor: () => mounted
              ? _mappedSensors().firstWhere(
                  (item) => item['id'] == sensor['id'],
                  orElse: () => sensor)
              : sensor),
    );
    if (calibrate == true && mounted) _calibrateSensor(sensor);
  }

  void _calibrateSensor(Map<String, dynamic> sensor) {
    if (sensorRequiresCalibration(sensor) != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calibrating ${sensor['name']}...'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showAddSensorDialog(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showAppDialog(
      context: context,
      builder: (context) => AppAlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(
          'Add New Sensor',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: isMobile ? AppTypography.sectionTitleSize : AppTypography.headingSize,
          ),
        ),
        content: Text(
          'Sensor addition feature coming soon!',
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            fontSize: isMobile ? AppTypography.actionSize : AppTypography.bodySize,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Add',
              style: TextStyle(fontSize: isMobile ? AppTypography.actionSize : AppTypography.bodySize),
            ),
          ),
        ],
      ),
    );
  }
}
