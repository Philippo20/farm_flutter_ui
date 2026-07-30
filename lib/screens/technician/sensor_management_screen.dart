import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/technician_header.dart';
import '../../core/widgets/technician_mobile_bottom_nav.dart';
import '../../core/widgets/technician_sidebar.dart';
import 'package:intl/intl.dart';
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
  String _selectedFarmId = 'All';
  final SuperAdminApiService _api = SuperAdminApiService();
  Timer? _refreshTimer;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _backendSensors = [];
  List<Map<String, dynamic>> _farms = [];

  @override
  void initState() {
    super.initState();
    _loadSensorData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadSensorData(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSensorData({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.getSensors(),
        _api.getFarms(),
        _api.getUsers(),
      ]);
      if (!mounted) return;
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
        _errorMessage = error.toString();
      });
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
      final normalizedStatus =
          status == 'online' || status == 'active' || status == 'operational'
              ? 'normal'
              : status == 'warning'
                  ? 'warning'
                  : status == 'alert'
                      ? 'alert'
                      : 'offline';
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
      final last = DateTime.tryParse(
              _value(sensor, ['last_seen_at', 'updated_at', r'$updatedAt'])) ??
          DateTime.now();
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
        'name':
            _value(sensor, ['name', 'sensor_name', 'serial_number'], 'Sensor'),
        'type': type,
        'status': normalizedStatus,
        'color': color,
        'icon': Icons.sensors,
        'value': value,
        'unit': _value(sensor, ['unit', 'measurement_unit']),
        'location': farmName,
        'farmId': farmId,
        'farmName': farmName,
        'lastReading': last,
        'lastCalibrated': DateTime.tryParse(
                _value(sensor, ['last_maintenance_date', 'created_at'])) ??
            last,
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
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
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
          ? SafeArea(
              top: false,
              child: TechnicianMobileBottomNav(
                selectedIndex: _selectedNavIndex,
                onItemSelected: (index) =>
                    setState(() => _selectedNavIndex = index),
              ))
          : null,
    );
  }

  Widget _buildLoadingShell(
      bool isDark, bool isMobile, String userName, String userEmail) {
    final content = const Center(child: AdminDataSkeleton(rowCount: 5));
    if (isMobile) {
      return Column(children: [
        TechnicianHeader(userName: userName, onNotificationTap: () {}),
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
        TechnicianHeader(userName: userName, onNotificationTap: () {}),
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
        TechnicianHeader(userName: userName, onNotificationTap: () {}),
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
        TechnicianHeader(userName: userName, onNotificationTap: () {}),
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
              TechnicianHeader(userName: userName, onNotificationTap: () {}),
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
        TechnicianHeader(userName: userName, onNotificationTap: () {}),
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
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: isMobile ? 18 : 20,
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
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                            fontSize: isMobile ? 15 : 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '${sensors.where((s) => s['status'] == 'normal').length} Active',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 13 : 14,
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
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                      mainAxisExtent: isMobile ? 330 : (isTablet ? 368 : 356),
                      crossAxisSpacing:
                          isMobile ? AppSpacing.sm : AppSpacing.md,
                      mainAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildSensorCard(
                          filteredSensors[index],
                          isDark,
                          isMobile: isMobile,
                          isTablet: isTablet,
                        );
                      },
                      childCount: filteredSensors.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPanel(bool isDark, bool isMobile) {
    final searchTextStyle = TextStyle(
      color: isDark ? Colors.white : AppColors.textPrimary,
      fontSize: isMobile ? 13 : 14,
    );

    final activeFilterCount = [
      if (_selectedType != 'All') _selectedType,
      if (_selectedStatus != 'All') _selectedStatus,
      if (_selectedFarmId != 'All') _selectedFarmId,
      if (_searchQuery.trim().isNotEmpty) 'Search',
    ].length;

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.05),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Sensors',
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Refine the sensor list by name, device type, or operating status.',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (activeFilterCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(isDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '$activeFilterCount active',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
          Text(
            'Search',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: searchTextStyle,
            decoration: InputDecoration(
              hintText: 'Search sensors by name',
              hintStyle: TextStyle(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                fontSize: isMobile ? 13 : 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () => setState(() => _searchQuery = ''),
                      icon: Icon(
                        Icons.close_rounded,
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                        size: 18,
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: isDark ? Colors.white10 : AppColors.neutral200,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: isDark ? Colors.white10 : AppColors.neutral200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: AppColors.primary.withOpacity(0.55),
                  width: 1.2,
                ),
              ),
              filled: true,
              fillColor:
                  isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: isMobile ? 14 : 16,
              ),
            ),
          ),
          SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
          isMobile
              ? Column(
                  children: [
                    _buildFilterDropdown(
                      'Farm',
                      _selectedFarmId,
                      [
                        'All',
                        ..._farms
                            .map((farm) => _value(farm, ['id', r'$id']))
                            .where((id) => id.isNotEmpty),
                      ],
                      (value) =>
                          setState(() => _selectedFarmId = value ?? 'All'),
                      isDark,
                      isMobile: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildFilterDropdown(
                      'Sensor Type',
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
                      (value) => setState(() => _selectedType = value!),
                      isDark,
                      isMobile: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildFilterDropdown(
                      'Status',
                      _selectedStatus,
                      ['All', 'normal', 'warning', 'alert', 'offline'],
                      (value) => setState(() => _selectedStatus = value!),
                      isDark,
                      isMobile: true,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(
                        'Farm',
                        _selectedFarmId,
                        [
                          'All',
                          ..._farms
                              .map((farm) => _value(farm, ['id', r'$id']))
                              .where((id) => id.isNotEmpty),
                        ],
                        (value) =>
                            setState(() => _selectedFarmId = value ?? 'All'),
                        isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildFilterDropdown(
                        'Sensor Type',
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
                        (value) => setState(() => _selectedType = value!),
                        isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildFilterDropdown(
                        'Status',
                        _selectedStatus,
                        ['All', 'normal', 'warning', 'alert', 'offline'],
                        (value) => setState(() => _selectedStatus = value!),
                        isDark,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(Map<String, dynamic> sensor, bool isDark,
      {bool isMobile = false, bool isTablet = false}) {
    final color = sensor['color'] as Color;
    final status = sensor['status'] as String;
    final statusColor = _sensorStatusColor(status);
    final lastCalibrated = sensor['lastCalibrated'] as DateTime;
    final daysSinceCalibration =
        DateTime.now().difference(lastCalibrated).inDays;
    final verticalGap = isMobile ? 6.0 : AppSpacing.sm;
    final sectionGap = isMobile ? 8.0 : AppSpacing.md;

    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
        ),
      ),
      child: InkWell(
        onTap: () => _showSensorDetails(sensor, isDark),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 9 : (isTablet ? 10 : 12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isMobile ? 38 : 48,
                    height: isMobile ? 38 : 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(isDark ? 0.34 : 0.22),
                          color.withOpacity(isDark ? 0.14 : 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: color.withOpacity(isDark ? 0.35 : 0.18),
                      ),
                    ),
                    child: Icon(
                      sensor['icon'] as IconData,
                      color: color,
                      size: isMobile ? 18 : 22,
                    ),
                  ),
                  SizedBox(width: isMobile ? 10 : AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sensor['name'],
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                            fontSize: isMobile ? 12 : 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isMobile ? 3 : 4),
                        if (isMobile)
                          Row(
                            children: [
                              _buildMetaChip(
                                sensor['id'] as String,
                                isDark,
                                isMobile: true,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _formatSensorType(sensor['type'] as String),
                                  style: AppTypography.caption.copyWith(
                                    color: isDark
                                        ? Colors.white60
                                        : AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        else
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildMetaChip(
                                sensor['id'] as String,
                                isDark,
                                isMobile: isMobile,
                              ),
                              _buildMetaChip(
                                _formatSensorType(sensor['type'] as String),
                                isDark,
                                isMobile: isMobile,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status, isDark,
                      isMobile: isMobile, isTablet: isTablet),
                ],
              ),
              SizedBox(height: sectionGap),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 9 : 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            color.withOpacity(0.20),
                            AppColors.backgroundDark,
                          ]
                        : [
                            color.withOpacity(0.10),
                            Colors.white,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: color.withOpacity(isDark ? 0.28 : 0.16),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor.withOpacity(0.45),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Current reading',
                                style: AppTypography.caption.copyWith(
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isMobile ? 9 : 11,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: verticalGap - 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  '${sensor['value']}',
                                  style: AppTypography.h4.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: color,
                                    fontSize:
                                        isMobile ? 20 : (isTablet ? 24 : 26),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  sensor['unit'],
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: color.withOpacity(0.82),
                                    fontSize: isMobile ? 10 : 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: AppSpacing.md),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 10,
                          vertical: isMobile ? 6 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(isDark ? 0.16 : 0.03),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Text(
                          'LIVE',
                          style: AppTypography.caption.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: sectionGap),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: isMobile ? 11 : 14,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      sensor['location'],
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                        fontSize: isMobile ? 9 : 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: sectionGap),
              Row(
                children: [
                  Expanded(
                    child: _buildTelemetryTile(
                      'Calibrated',
                      '${daysSinceCalibration}d',
                      Icons.tune_rounded,
                      daysSinceCalibration < 14
                          ? AppColors.success
                          : daysSinceCalibration < 21
                              ? AppColors.warning
                              : AppColors.error,
                      isDark,
                      isMobile: isMobile,
                    ),
                  ),
                ],
              ),
              SizedBox(height: sectionGap),
              Container(
                padding: EdgeInsets.only(top: isMobile ? 6 : AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withOpacity(0.06),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (isMobile) ...[
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => _showSensorDetails(sensor, isDark),
                          icon: const Icon(Icons.memory_rounded, size: 14),
                          label: const Text(
                            'Inspect',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: FilledButton.styleFrom(
                            foregroundColor:
                                isDark ? Colors.white : AppColors.textPrimary,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.08)
                                : AppColors.neutral100,
                            padding: const EdgeInsets.symmetric(
                              vertical: 7,
                              horizontal: AppSpacing.xs,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      SizedBox(
                        width: 42,
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () => _calibrateSensor(sensor),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: color,
                            side: BorderSide(color: color.withOpacity(0.7)),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                          ),
                          child: const Icon(Icons.tune, size: 16),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _calibrateSensor(sensor),
                          icon: const Icon(Icons.tune, size: 16),
                          label: const Text(
                            'Calibrate',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: color,
                            side: BorderSide(color: color.withOpacity(0.7)),
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 7 : 8,
                              horizontal:
                                  isMobile ? AppSpacing.xs : AppSpacing.sm,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => _showSensorDetails(sensor, isDark),
                          icon: Icon(Icons.memory_rounded,
                              size: isMobile ? 14 : 16),
                          label: Text(
                            'Inspect',
                            style: TextStyle(fontSize: isMobile ? 11 : 12),
                          ),
                          style: FilledButton.styleFrom(
                            foregroundColor:
                                isDark ? Colors.white : AppColors.textPrimary,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.08)
                                : AppColors.neutral100,
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 7 : 8,
                              horizontal:
                                  isMobile ? AppSpacing.xs : AppSpacing.sm,
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
          ),
        ),
      ),
    );
  }

  Color _sensorStatusColor(String status) {
    switch (status) {
      case 'normal':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'alert':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _formatSensorType(String type) {
    if (type.isEmpty) return type;
    return '${type[0].toUpperCase()}${type.substring(1)}';
  }

  Widget _buildMetaChip(String text, bool isDark, {bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 7 : 9,
        vertical: isMobile ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: isDark ? Colors.white70 : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: isMobile ? 9 : 11,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark,
      {bool isMobile = false, bool isTablet = false}) {
    final color = _sensorStatusColor(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 7 : (isTablet ? 8 : 9),
        vertical: isMobile ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: isMobile ? 7 : 9,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTelemetryTile(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark, {
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 7 : 10,
        vertical: isMobile ? 5 : 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isMobile ? 11 : 14, color: color),
          SizedBox(height: isMobile ? 3 : 5),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: isMobile ? 10 : 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
              fontSize: isMobile ? 9 : 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

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
            fontWeight: FontWeight.w600,
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
                        fontSize: isMobile ? 12 : 13,
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
              fontSize: isMobile ? 12 : 13,
            ),
            dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          ),
        ),
      ],
    );
  }

  void _showSensorDetails(Map<String, dynamic> sensor, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final accent = sensor['color'] as Color? ?? Colors.teal;
    final statusColor = _sensorStatusColor(sensor['status'] as String);
    final lastCalibrated = sensor['lastCalibrated'] as DateTime;
    final daysSinceCalibration =
        DateTime.now().difference(lastCalibrated).inDays;
    final isCalibrationDue = daysSinceCalibration >= 14;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isDark ? Colors.white10 : AppColors.neutral200,
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSensorModalHeader(
                    sensor: sensor,
                    accent: accent,
                    statusColor: statusColor,
                    isDark: isDark,
                    isMobile: isMobile,
                    isCalibrationDue: isCalibrationDue,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(
                        isMobile ? AppSpacing.md : AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : accent.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: accent.withOpacity(isDark ? 0.22 : 0.14),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: isMobile ? 44 : 52,
                          height: isMobile ? 44 : 52,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(isDark ? 0.22 : 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Icon(
                            sensor['icon'] as IconData,
                            color: accent,
                            size: isMobile ? 22 : 26,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Reading',
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${sensor['value']} ${sensor['unit']}',
                                style: AppTypography.h4.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Last calibrated ${DateFormat('MMM dd, yyyy').format(lastCalibrated)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSensorInfoGrid(
                    isDark,
                    [
                      _SensorDetailField('Sensor ID', sensor['id'] as String),
                      _SensorDetailField(
                          'Type', _formatSensorType(sensor['type'] as String)),
                      _SensorDetailField(
                          'Location', sensor['location'] as String),
                      _SensorDetailField(
                          'Status', (sensor['status'] as String).toUpperCase()),
                      _SensorDetailField(
                          'Calibration Age', '$daysSinceCalibration days ago'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
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
                      children: [
                        Text(
                          'Technician Notes',
                          style: AppTypography.bodyMedium.copyWith(
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _buildSensorRecommendation(
                            status: sensor['status'] as String,
                            isCalibrationDue: isCalibrationDue,
                          ),
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => Navigator.pop(context),
                          style: FilledButton.styleFrom(
                            foregroundColor:
                                isDark ? Colors.white : AppColors.textPrimary,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.08)
                                : AppColors.neutral100,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _calibrateSensor(sensor);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(Icons.tune, size: isMobile ? 16 : 18),
                          label: Text(
                            'Calibrate',
                            style: TextStyle(fontSize: isMobile ? 13 : 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSensorModalHeader({
    required Map<String, dynamic> sensor,
    required Color accent,
    required Color statusColor,
    required bool isDark,
    required bool isMobile,
    required bool isCalibrationDue,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [accent.withOpacity(0.20), AppColors.backgroundDark]
              : [accent.withOpacity(0.10), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: accent.withOpacity(isDark ? 0.28 : 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isMobile ? 46 : 52,
                height: isMobile ? 46 : 52,
                decoration: BoxDecoration(
                  color: accent.withOpacity(isDark ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  sensor['icon'] as IconData,
                  color: accent,
                  size: isMobile ? 22 : 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensor['name'] as String,
                      style: AppTypography.h5.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 18 : 20,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${sensor['id']} | ${sensor['location']}',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white70 : AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _buildSensorDetailBadge(
                (sensor['status'] as String).toUpperCase(),
                statusColor,
                isDark,
              ),
              _buildSensorDetailBadge(
                _formatSensorType(sensor['type'] as String),
                accent,
                isDark,
              ),
              _buildSensorDetailBadge(
                isCalibrationDue ? 'Calibration Due' : 'Calibrated',
                isCalibrationDue ? AppColors.warning : AppColors.success,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorDetailBadge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.24)),
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

  Widget _buildSensorInfoGrid(bool isDark, List<_SensorDetailField> fields) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: fields
          .map(
            (field) => SizedBox(
              width: 184,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
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
                  children: [
                    Text(
                      field.label,
                      style: AppTypography.caption.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      field.value,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  String _buildSensorRecommendation({
    required String status,
    required bool isCalibrationDue,
  }) {
    if (status == 'alert') {
      return 'Sensor is reporting an alert state. Inspect the probe installation, verify live readings against field conditions, and recalibrate before returning it to production monitoring.';
    }
    if (isCalibrationDue) {
      return 'Calibration window has expired. Schedule service now to keep telemetry accurate and avoid drift in automated decisions.';
    }
    if (status == 'warning') {
      return 'Sensor is stable but needs attention. Review the recent readings for drift and perform a spot-check on the mounting position and environment.';
    }
    return 'Sensor is operating within expected thresholds. Continue routine monitoring and keep the current calibration interval.';
  }

  void _calibrateSensor(Map<String, dynamic> sensor) {
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(
          'Add New Sensor',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        content: Text(
          'Sensor addition feature coming soon!',
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            fontSize: isMobile ? 13 : 14,
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
              style: TextStyle(fontSize: isMobile ? 13 : 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorDetailField {
  const _SensorDetailField(this.label, this.value);

  final String label;
  final String value;
}
