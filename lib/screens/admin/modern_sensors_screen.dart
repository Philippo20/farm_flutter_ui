import '../../core/widgets/sensor_form_dialog.dart';
import '../../core/widgets/device_telemetry_details_modal.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../core/widgets/farm_manager_header.dart';
import '../../core/widgets/farm_manager_mobile_drawer.dart';
import '../../core/widgets/farm_manager_sidebar.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

class ModernSensorsScreen extends ConsumerStatefulWidget {
  const ModernSensorsScreen({
    super.key,
    this.isSuperAdmin = false,
    this.isFarmManager = false,
  });

  final bool isSuperAdmin;
  final bool isFarmManager;

  @override
  ConsumerState<ModernSensorsScreen> createState() =>
      _ModernSensorsScreenState();
}

class _ModernSensorsScreenState extends ConsumerState<ModernSensorsScreen> {
  String _selectedFarm = 'All Farms';
  String _selectedStatus = 'All';
  String _selectedType = 'All Types';
  final SuperAdminApiService _api = SuperAdminApiService();
  final List<Map<String, dynamic>> _sensorDocuments = [];
  final List<Map<String, dynamic>> _farmDocuments = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoadingSensors = true;
  String? _sensorError;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadSensors();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadSensors(showLoading: false),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSensors({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoadingSensors = true;
        _sensorError = null;
      });
    }

    try {
      final results = await Future.wait([
        _api.getSensors(),
        _api.getFarms(),
      ]);
      if (!mounted) return;
      final farms = widget.isFarmManager
          ? results[1].where(_isAssignedToCurrentManager).toList()
          : results[1];
      final sensors = widget.isFarmManager
          ? results[0]
              .where((sensor) => _matchesAnyFarm(sensor, farms))
              .toList()
          : results[0];
      setState(() {
        _sensorDocuments
          ..clear()
          ..addAll(sensors);
        _farmDocuments
          ..clear()
          ..addAll(farms);
        final farmOptions = _farmOptions();
        if (!farmOptions.contains(_selectedFarm)) _selectedFarm = 'All Farms';
        final statuses = _statusOptions();
        if (!statuses.contains(_selectedStatus)) _selectedStatus = 'All';
        final types = _typeOptions();
        if (!types.contains(_selectedType)) _selectedType = 'All Types';
        _isLoadingSensors = false;
      });
    } catch (error) {
      if (!mounted) return;
      if (!showLoading) return;
      setState(() {
        _sensorDocuments.clear();
        _farmDocuments.clear();
        _isLoadingSensors = false;
        _sensorError = error.toString();
      });
    }
  }

  String _docId(Map<String, dynamic> doc) =>
      (doc[r'$id'] ?? doc['id'] ?? doc['farm_id'] ?? '').toString();

  String _value(Map<String, dynamic> doc, List<String> keys) {
    for (final key in keys) {
      final value = doc[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  bool _isAssignedToCurrentManager(Map<String, dynamic> farm) {
    final user = ref.read(authProvider).user;
    if (user == null) return true;
    final managerId = _value(farm, ['farm_manager_id', 'farmManagerId']);
    final managerName = _value(farm, ['farm_manager_name', 'farmManagerName']);
    return managerId == user.id ||
        managerId == user.email ||
        managerName.toLowerCase() == user.name.toLowerCase();
  }

  bool _matchesAnyFarm(
    Map<String, dynamic> sensor,
    List<Map<String, dynamic>> farms,
  ) {
    if (farms.isEmpty) return false;
    final farmIds = farms.map(_docId).where((id) => id.isNotEmpty).toSet();
    final farmNames = farms
        .map((farm) => _value(farm, ['name', 'farm_name']))
        .where((name) => name.isNotEmpty)
        .toSet();
    final sensorFarmId = _value(sensor, ['farmID', 'farm_id', 'farmId']);
    final sensorFarmName = _value(sensor, ['farm_name', 'farmName']);
    return farmIds.contains(sensorFarmId) || farmNames.contains(sensorFarmName);
  }

  List<_IotSensor> get _sensors {
    final sensors = _sensorDocuments.map(_mapSensorDocument).toList();
    sensors.sort((a, b) {
      final aTime = a.lastTelemetryAt;
      final bTime = b.lastTelemetryAt;
      if (aTime == null && bTime == null) return a.name.compareTo(b.name);
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return sensors;
  }

  List<_IotSensor> get _filteredSensors {
    return _sensors.where((sensor) {
      if (_selectedFarm != 'All Farms' && sensor.farm != _selectedFarm) {
        return false;
      }
      if (_selectedStatus != 'All' && sensor.status != _selectedStatus) {
        return false;
      }
      if (_selectedType != 'All Types' && sensor.type != _selectedType) {
        return false;
      }
      return true;
    }).toList();
  }

  _IotSensor _mapSensorDocument(Map<String, dynamic> doc) {
    final type = _typeLabel(doc['sensortype']);
    final status = _statusLabel(doc['status']);
    final value = _toDouble(doc['value']);
    final serialNumber =
        (doc['serial_number'] ?? doc[r'$id'] ?? 'Sensor').toString();
    final lastTelemetryAt = _dateTimeOrNull(doc['timestamp']);
    return _IotSensor(
      id: serialNumber,
      name: _sensorName(type, doc),
      type: type,
      farm: (doc['farm_name'] ?? 'Unassigned Farm').toString(),
      zone: (doc['location'] ?? 'Unassigned Zone').toString(),
      reading: value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1),
      unit: (doc['unit'] ?? _unitForType(type)).toString(),
      status: status,
      health: _healthForStatus(status),
      battery: _toInt(doc['battery_level'] ?? doc['battery'] ?? 100),
      signal: _toInt(doc['signal_strength'] ?? doc['signal'] ?? -58),
      firmware:
          (doc['firmware'] ?? doc['model_number'] ?? 'Not set').toString(),
      gateway: (doc['gateway']?.toString().trim().isNotEmpty ?? false)
          ? doc['gateway'].toString()
          : 'Not assigned',
      protocol: (doc['protocol'] ?? 'IoT').toString(),
      lastSeen: _timeAgo(doc['timestamp']),
      lastTelemetryAt: lastTelemetryAt,
      isOnline: _isRecentlyOnline(lastTelemetryAt),
      rangeLabel: _rangeLabelForSensor(doc, type),
      warningLabel: _warningLabelForSensor(doc),
      trend: '0 ${doc['unit'] ?? _unitForType(type)}',
      icon: _iconForType(type),
      color: _colorForType(type),
      raw: Map<String, dynamic>.from(doc),
    );
  }

  List<String> _farmOptions() {
    final farms = <String>{
      ..._farmDocuments.map((farm) {
        return (farm['name'] ?? farm['farm_name'] ?? '').toString().trim();
      }),
      ..._sensorDocuments.map((sensor) {
        return (sensor['farm_name'] ?? '').toString().trim();
      }),
    }..removeWhere((farm) => farm.isEmpty);
    final sorted = farms.toList()..sort();
    return ['All Farms', ...sorted];
  }

  String get _gatewaySummary {
    final gateways = _sensorDocuments
        .map((sensor) => (sensor['gateway'] ?? '').toString().trim())
        .where((gateway) => gateway.isNotEmpty)
        .toSet();
    if (gateways.isEmpty) return 'Not configured';
    return '${gateways.length} configured';
  }

  List<String> _statusOptions() {
    final statuses = _sensors.map((sensor) => sensor.status).toSet().toList()
      ..sort();
    return ['All', ...statuses];
  }

  List<String> _typeOptions() {
    final types = _sensors.map((sensor) => sensor.type).toSet().toList()
      ..sort();
    return ['All Types', ...types];
  }

  String _typeLabel(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    switch (raw.toLowerCase()) {
      case 'vpd':
        return 'VPD';
      case 'temperature':
        return 'Temperature';
      case 'humidity':
        return 'Humidity';
      case 'carbon dioxide':
      case 'co2':
        return 'CO2';
      case 'light':
        return 'Light';
      case 'ph level':
        return 'pH Level';
      case 'ec level':
        return 'EC Level';
      case 'water level':
        return 'Water Level';
      case 'electricity_current':
        return 'Current';
      case 'electricity_voltage':
        return 'Voltage';
      case 'electricity_wattage':
        return 'Wattage';
      default:
        return raw.isEmpty ? 'Sensor' : raw;
    }
  }

  String _backendType(String type) {
    switch (type) {
      case 'Temperature':
        return 'temperature';
      case 'Humidity':
        return 'humidity';
      case 'CO2':
        return 'Carbon Dioxide';
      case 'Light':
        return 'light';
      case 'pH Level':
        return 'pH Level';
      case 'EC Level':
        return 'EC Level';
      case 'Water Level':
        return 'Water level';
      case 'Current':
        return 'electricity_current';
      case 'Voltage':
        return 'electricity_voltage';
      case 'Wattage':
        return 'electricity_wattage';
      default:
        return type;
    }
  }

  String _statusLabel(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.toLowerCase() == 'faulty') return 'Critical';
    if (raw.toLowerCase() == 'maintenance') return 'Warning';
    if (raw.toLowerCase() == 'inactive') return 'Inactive';
    return raw.isEmpty ? 'Active' : raw;
  }

  String _backendStatus(String status) {
    if (status == 'Critical') return 'Faulty';
    if (status == 'Warning') return 'Maintenance';
    return status;
  }

  String _sensorName(String type, Map<String, dynamic> doc) {
    final model = (doc['model_number'] ?? '').toString().trim();
    if (model.isNotEmpty) return '$type Sensor $model';
    return '$type Sensor';
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _healthForStatus(String status) {
    switch (status) {
      case 'Active':
        return 96;
      case 'Warning':
        return 72;
      case 'Critical':
        return 42;
      case 'Inactive':
        return 0;
      default:
        return 80;
    }
  }

  String _unitForType(String type) {
    switch (type) {
      case 'VPD':
        return 'psi';
      case 'Temperature':
        return 'C';
      case 'Humidity':
        return '%';
      case 'CO2':
        return 'ppm';
      case 'Light':
        return 'lux';
      case 'pH Level':
        return 'pH';
      case 'EC Level':
        return 'mS/cm';
      case 'Water Level':
        return 'cm';
      case 'Current':
        return 'A';
      case 'Voltage':
        return 'V';
      case 'Wattage':
        return 'W';
      default:
        return '';
    }
  }

  String _rangeForType(String type) {
    switch (type) {
      case 'Temperature':
        return '18 - 28 C';
      case 'Humidity':
        return '55 - 75%';
      case 'CO2':
        return '650 - 950 ppm';
      case 'pH Level':
        return '5.8 - 6.4 pH';
      case 'EC Level':
        return '1.2 - 2.4 mS/cm';
      case 'Water Level':
        return '60 - 100 cm';
      default:
        return 'Configured in device';
    }
  }

  String _rangeLabelForSensor(Map<String, dynamic> doc, String type) {
    final min = doc['range_min'];
    final max = doc['range_max'];
    final unit = (doc['unit'] ?? _unitForType(type)).toString();
    if (_hasValue(min) && _hasValue(max)) {
      return '${_numberLabel(min)} - ${_numberLabel(max)} $unit';
    }
    return _rangeForType(type);
  }

  String _warningLabelForSensor(Map<String, dynamic> doc) {
    final low = doc['warning_min'];
    final high = doc['warning_max'];
    final unit = (doc['unit'] ?? '').toString();
    if (_hasValue(low) && _hasValue(high)) {
      return '${_numberLabel(low)} - ${_numberLabel(high)} $unit';
    }
    return 'Not configured';
  }

  bool _hasValue(dynamic value) {
    return value != null && value.toString().trim().isNotEmpty;
  }

  String _numberLabel(dynamic value) {
    final number = _toDouble(value);
    return number.toStringAsFixed(number.truncateToDouble() == number ? 0 : 1);
  }

  (double, double, double, double) _defaultLimitsForType(String type) {
    switch (type) {
      case 'Temperature':
        return (18, 28, 15, 32);
      case 'Humidity':
        return (55, 75, 45, 85);
      case 'CO2':
        return (650, 950, 450, 1200);
      case 'Light':
        return (20000, 65000, 10000, 80000);
      case 'pH Level':
        return (5.8, 6.4, 5.5, 6.8);
      case 'EC Level':
        return (1.2, 2.4, 0.8, 3.0);
      case 'Water Level':
        return (60, 100, 35, 120);
      case 'Current':
        return (0.2, 8, 0, 10);
      case 'Voltage':
        return (210, 240, 190, 255);
      case 'Wattage':
        return (50, 1800, 0, 2200);
      default:
        return (0, 100, 0, 100);
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Temperature':
        return Icons.thermostat_rounded;
      case 'Humidity':
        return Icons.water_drop_rounded;
      case 'CO2':
        return Icons.air_rounded;
      case 'Light':
        return Icons.wb_sunny_rounded;
      case 'pH Level':
      case 'EC Level':
        return Icons.science_rounded;
      case 'Water Level':
        return Icons.water_rounded;
      case 'Current':
      case 'Voltage':
      case 'Wattage':
        return Icons.electrical_services_rounded;
      default:
        return Icons.sensors_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'Temperature':
        return AppColors.chartOrange;
      case 'Humidity':
        return AppColors.chartBlue;
      case 'CO2':
        return AppColors.chartTeal;
      case 'Light':
        return AppColors.warning;
      case 'pH Level':
      case 'EC Level':
        return AppColors.chartPurple;
      case 'Water Level':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  String _timeAgo(dynamic value) {
    final parsed = _dateTimeOrNull(value);
    if (parsed == null) return 'Not recorded';
    final difference = DateTime.now().difference(parsed.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hr ago';
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }

  DateTime? _dateTimeOrNull(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed?.toLocal();
  }

  bool _isRecentlyOnline(DateTime? timestamp) {
    if (timestamp == null) return false;
    final difference = DateTime.now().difference(timestamp);
    return difference.inSeconds >= -5 && difference.inSeconds <= 20;
  }

  Color _readingDiagnosticColor(_IotSensor sensor) {
    final value = _toDouble(sensor.raw['value'] ?? sensor.reading);
    final warningMin = _toDoubleOrNull(sensor.raw['warning_min']);
    final warningMax = _toDoubleOrNull(sensor.raw['warning_max']);
    final rangeMin = _toDoubleOrNull(sensor.raw['range_min']);
    final rangeMax = _toDoubleOrNull(sensor.raw['range_max']);
    if (warningMin != null && value < warningMin) return AppColors.error;
    if (warningMax != null && value > warningMax) return AppColors.error;
    if (rangeMin != null && value < rangeMin) return AppColors.warning;
    if (rangeMax != null && value > rangeMax) return AppColors.warning;
    return AppColors.success;
  }

  String _readingDiagnosticLabel(_IotSensor sensor) {
    final color = _readingDiagnosticColor(sensor);
    if (color == AppColors.error) return 'Outside warning limit';
    if (color == AppColors.warning) return 'Outside normal range';
    return 'Within normal range';
  }

  double? _toDoubleOrNull(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _maintenanceLabel(_IotSensor sensor) {
    final frequency =
        (sensor.raw['maintenance_frequency'] ?? '').toString().trim();
    final lastDate =
        (sensor.raw['last_maintenance_date'] ?? '').toString().split('T').first;
    if (frequency.isEmpty && lastDate.isEmpty) return 'Not configured';
    if (lastDate.isEmpty) return frequency;
    if (frequency.isEmpty) return 'Last serviced $lastDate';
    return '$frequency - last serviced $lastDate';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Farm Manager';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: widget.isFarmManager && isMobile
          ? FarmManagerMobileDrawer(
              selectedIndex: 8,
              onItemSelected: (_) {},
              userName: userName,
            )
          : widget.isSuperAdmin && isMobile
              ? SuperAdminDrawer(
                  selectedIndex: 12,
                  onItemSelected: (_) {},
                  userName: userName,
                  userEmail: ref.read(authProvider).user?.email ??
                      'superadmin@farmestates.com',
                  userRole: 'Super Administrator',
                )
              : !widget.isSuperAdmin && isMobile
                  ? AdminDrawer(
                      selectedIndex: 3,
                      onItemSelected: (_) {},
                      userName: userName,
                      userEmail: ref.read(authProvider).user?.email ?? '',
                      userRole: 'Administrator',
                    )
                  : null,
      body: isMobile ? _buildMobileLayout(isDark) : _buildDesktopLayout(isDark),
      bottomNavigationBar: widget.isSuperAdmin && isMobile
          ? SuperAdminMobileBottomNav(
              selectedIndex: 12,
              onItemSelected: (_) {},
            )
          : widget.isFarmManager && isMobile
              ? FarmManagerMobileBottomNav(
                  selectedIndex: 8,
                  onItemSelected: (_) {},
                )
              : (isMobile
                  ? AdminMobileBottomNav(
                      selectedIndex: 3,
                      onItemSelected: (_) {},
                    )
                  : null),
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    if (widget.isFarmManager) {
      final authState = ref.watch(authProvider);
      return Row(
        children: [
          FarmManagerSidebar(
            selectedIndex: 8,
            onItemSelected: (_) {},
            userName: authState.user?.name ?? 'Farm Manager',
            userEmail: authState.user?.email ?? '',
            userRole: 'Farm Manager',
          ),
          Expanded(
            child: Column(
              children: [
                FarmManagerHeader(
                  userName: authState.user?.name ?? 'Farm Manager',
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

    return Row(
      children: [
        widget.isSuperAdmin
            ? SuperAdminSidebar(
                selectedIndex: 12,
                onItemSelected: (_) {},
                userName: 'Super Admin',
                userEmail: 'superadmin@farmestates.com',
                userRole: 'Super Administrator',
              )
            : ModernAdminSidebar(selectedIndex: 3, onItemSelected: (_) {}),
        Expanded(
          child: Column(
            children: [
              ModernAdminHeader(
                userName: widget.isSuperAdmin ? 'Super Admin' : 'Admin',
                onNotificationTap: () {},
                onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
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

  Widget _buildMobileLayout(bool isDark) {
    if (widget.isFarmManager) {
      final authState = ref.watch(authProvider);
      return Column(
        children: [
          FarmManagerHeader(
            userName: authState.user?.name ?? 'Farm Manager',
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

    return Column(
      children: [
        ModernAdminHeader(
          userName: widget.isSuperAdmin ? 'Super Admin' : 'Admin',
          onNotificationTap: () {},
          onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
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
    if (_isLoadingSensors) {
      return const AdminDataSkeleton(rowCount: 5);
    }

    if (_sensorError != null) {
      return _buildErrorState(isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        _buildHealthStrip(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        _buildFilters(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        _buildFleetGrid(isDark),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: _cardDecoration(isDark),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Unable to load sensors',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: AppTypography.bodyWeight,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _sensorError!,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _loadSensors,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(bool isDark, bool isMobile) {
    final online = _sensors.where((sensor) => sensor.isOnline).length;
    final critical =
        _sensors.where((sensor) => sensor.status == 'Critical').length;

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
                  const Color(0xFF062E2E),
                  const Color(0xFF0B3B30),
                  AppColors.surfaceDark,
                ]
              : [
                  const Color(0xFFE8FAF7),
                  const Color(0xFFF4FFF4),
                  Colors.white,
                ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.primary.withValues(alpha: 0.14),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.10),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          return Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: compact ? 0 : 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLivePill(isDark),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'IoT Sensor Fleet',
                      style: AppTypography.h3.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: AppTypography.bodyWeight,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.isFarmManager
                          ? 'Real-time telemetry, device health, gateway connectivity, and diagnostics for your assigned farms.'
                          : 'Real-time farm telemetry, device health, gateway connectivity, and sensor diagnostics across all estates.',
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
              if (!compact) const SizedBox(width: AppSpacing.xl),
              if (compact) const SizedBox(height: AppSpacing.lg),
              Expanded(
                flex: compact ? 0 : 2,
                child: _buildNetworkSummary(isDark, online, critical),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLivePill(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Live telemetry stream',
            style: AppTypography.label.copyWith(
              color: isDark ? Colors.white : AppColors.primaryDark,
              fontWeight: AppTypography.bodyWeight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSummary(bool isDark, int online, int critical) {
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
          _buildNetworkRow(
            isDark,
            icon: Icons.hub_rounded,
            label: 'Connected gateways',
            value: _gatewaySummary,
            color: AppColors.info,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildNetworkRow(
            isDark,
            icon: Icons.sensors_rounded,
            label: 'Online devices',
            value: '$online / ${_sensors.length}',
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildNetworkRow(
            isDark,
            icon: Icons.priority_high_rounded,
            label: 'Critical devices',
            value: '$critical',
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkRow(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
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
              fontWeight: AppTypography.bodyWeight,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: AppTypography.bodyWeight,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthStrip(bool isDark, bool isMobile) {
    final warning =
        _sensors.where((sensor) => sensor.status == 'Warning').length;
    final critical =
        _sensors.where((sensor) => sensor.status == 'Critical').length;
    final avgHealth = _sensors.isEmpty
        ? 0
        : (_sensors.fold<int>(0, (sum, s) => sum + s.health) / _sensors.length)
            .round();
    final lowBattery = _sensors.where((sensor) => sensor.battery < 25).length;

    final stats = [
      _FleetStat('Fleet Health', '$avgHealth%', Icons.health_and_safety_rounded,
          AppColors.success),
      _FleetStat('Warning', '$warning', Icons.warning_amber_rounded,
          AppColors.warning),
      _FleetStat('Critical', '$critical', Icons.error_rounded, AppColors.error),
      _FleetStat('Low Battery', '$lowBattery', Icons.battery_alert_rounded,
          AppColors.chartOrange),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = isMobile
            ? 2
            : constraints.maxWidth >= 1000
                ? 4
                : constraints.maxWidth >= 620
                    ? 2
                    : 1;
        final cardWidth =
            (constraints.maxWidth - (AppSpacing.md * (columns - 1))) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: stats.map((stat) {
            return SizedBox(
              width: cardWidth,
              height: isMobile ? 76 : null,
              child: _FleetStatCard(
                stat: stat,
                isDark: isDark,
                isMobile: isMobile,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFilters(bool isDark, bool isMobile) {
    final resetButton = OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _selectedFarm = 'All Farms';
          _selectedStatus = 'All';
          _selectedType = 'All Types';
        });
      },
      icon: const Icon(Icons.refresh_rounded, size: 18),
      label: const Text('Reset'),
    );
    final registerButton = FilledButton.icon(
      onPressed: () => _showAddSensorDialog(isDark),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Register Device'),
    );

    final farmDropdown = _buildDropdown(
      label: 'Farm',
      value: _selectedFarm,
      items: _farmOptions(),
      isDark: isDark,
      width: isMobile ? double.infinity : null,
      onChanged: (value) => setState(() => _selectedFarm = value!),
    );
    final statusDropdown = _buildDropdown(
      label: 'Status',
      value: _selectedStatus,
      items: _statusOptions(),
      isDark: isDark,
      width: isMobile ? double.infinity : null,
      onChanged: (value) => setState(() => _selectedStatus = value!),
    );
    final typeDropdown = _buildDropdown(
      label: 'Sensor Type',
      value: _selectedType,
      items: _typeOptions(),
      isDark: isDark,
      width: isMobile ? double.infinity : null,
      onChanged: (value) => setState(() => _selectedType = value!),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: registerButton),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: resetButton),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                farmDropdown,
                const SizedBox(height: AppSpacing.md),
                statusDropdown,
                const SizedBox(height: AppSpacing.md),
                typeDropdown,
              ],
            )
          : Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                farmDropdown,
                statusDropdown,
                typeDropdown,
                resetButton,
                registerButton,
              ],
            ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required bool isDark,
    double? width,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: width ?? 210,
      child: DropdownButtonFormField<String>(
        initialValue: value,
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
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.neutral300,
            ),
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

  Widget _buildFleetGrid(bool isDark) {
    final sensors = _filteredSensors;

    if (sensors.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: _cardDecoration(isDark),
        child: Column(
          children: [
            Icon(
              Icons.sensors_off_rounded,
              size: 52,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.28)
                  : AppColors.textSecondary.withValues(alpha: 0.45),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No IoT devices match these filters',
              style: AppTypography.bodyLarge.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontWeight: AppTypography.bodyWeight,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Device Telemetry',
                style: AppTypography.h5.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: AppTypography.bodyWeight,
                ),
              ),
            ),
            Text(
              '${sensors.length} devices',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                fontWeight: AppTypography.bodyWeight,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1220
                ? 3
                : constraints.maxWidth >= 820
                    ? 2
                    : 1;
            final cardWidth =
                (constraints.maxWidth - (AppSpacing.md * (columns - 1))) /
                    columns;

            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: sensors.map((sensor) {
                return SizedBox(
                  width: cardWidth,
                  child: _SensorDeviceCard(
                    sensor: sensor,
                    isDark: isDark,
                    onDetails: () => _showSensorDetails(sensor, isDark),
                    onSettings: () => _showSensorSettings(sensor, isDark),
                    onDelete: widget.isSuperAdmin
                        ? () => _showDeleteSensorDialog(sensor, isDark)
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = widget.isSuperAdmin
        ? const [
            _MobileNavItem(Icons.dashboard_outlined, Icons.dashboard_rounded,
                'Dashboard', '/superadmin_dashboard'),
            _MobileNavItem(Icons.people_outline, Icons.people_rounded, 'Users',
                '/superadmin/users'),
            _MobileNavItem(Icons.agriculture_outlined,
                Icons.agriculture_rounded, 'Farms', '/superadmin/farms'),
            _MobileNavItem(Icons.sensors_outlined, Icons.sensors_rounded,
                'Sensors', '/superadmin/sensors'),
            _MobileNavItem(Icons.settings_outlined, Icons.settings_rounded,
                'Config', '/superadmin/config'),
          ]
        : const [
            _MobileNavItem(Icons.dashboard_outlined, Icons.dashboard_rounded,
                'Dashboard', '/dashboard'),
            _MobileNavItem(
                Icons.people_outline, Icons.people_rounded, 'Users', '/users'),
            _MobileNavItem(Icons.agriculture_outlined,
                Icons.agriculture_rounded, 'Farms', '/farms'),
            _MobileNavItem(Icons.sensors_outlined, Icons.sensors_rounded,
                'Sensors', '/sensors'),
            _MobileNavItem(Icons.analytics_outlined, Icons.analytics_rounded,
                'Analytics', '/analytics'),
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
        children: navItems.map((item) {
          final selected = item.label == 'Sensors';
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
                      selected ? item.activeIcon : item.icon,
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
                        fontSize: AppTypography.microSize,
                        color: selected
                            ? AppColors.primary
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.62)
                                : AppColors.textSecondary),
                        fontWeight:
                            selected ? AppTypography.bodyWeight : AppTypography.bodyWeight,
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

  void _showAddSensorDialog(bool isDark) {
    _showSensorForm(isDark);
  }

  void _showSensorSettings(_IotSensor sensor, bool isDark) {
    _showSensorForm(isDark, sensor: sensor);
  }

  void _copySerialNumber(String serialNumber) {
    Clipboard.setData(ClipboardData(text: serialNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Serial number $serialNumber copied'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteSensor(_IotSensor sensor) async {
    try {
      await _api.deleteSensor(sensor.raw[r'$id']?.toString() ?? sensor.id);
      if (!mounted) return;
      await _loadSensors(showLoading: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${sensor.name} deleted'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDeleteSensorDialog(_IotSensor sensor, bool isDark) {
    bool isDeleting = false;
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    Widget buildContent(
      BuildContext modalContext,
      StateSetter setModalState,
    ) {
      if (isAndroid) {
        final bottomPadding = MediaQuery.of(modalContext).padding.bottom;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg + bottomPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.neutral300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Delete Sensor?',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(
                  fontSize: AppTypography.headingSize,
                  fontWeight: AppTypography.headingWeight,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'This will remove ${sensor.name} (${sensor.id}) from the backend. Live readings from this device will be rejected until it is registered again.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isDeleting
                          ? null
                          : () => Navigator.of(modalContext).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.white70 : AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isDeleting
                          ? null
                          : () async {
                              setModalState(() => isDeleting = true);
                              await _deleteSensor(sensor);
                              if (modalContext.mounted) {
                                Navigator.of(modalContext).pop();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }

      return Container(
        width: isAndroid ? double.infinity : 460,
        padding: EdgeInsets.all(isAndroid ? AppSpacing.lg : AppSpacing.xl),
        decoration: isAndroid
            ? BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusXl),
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Delete Sensor?',
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: AppTypography.labelWeight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'This will remove ${sensor.name} (${sensor.id}) from the backend. Live readings from this device will be rejected until it is registered again.',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () => Navigator.of(modalContext).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setModalState(() => isDeleting = true);
                          await _deleteSensor(sensor);
                          if (modalContext.mounted) {
                            Navigator.of(modalContext).pop();
                          }
                        },
                  icon: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                  label: Text(isDeleting ? 'Deleting...' : 'Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (isAndroid) {
      showAppBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black54,
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setModalState) =>
              buildContent(context, setModalState),
        ),
      );
    } else {
      showAppDialog<void>(
        context: context,
        barrierDismissible: !isDeleting,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setModalState) => AppDialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: buildContent(dialogContext, setModalState),
          ),
        ),
      );
    }
  }

  Future<void> _showSensorForm(bool isDark, {_IotSensor? sensor}) async {
    final formKey = GlobalKey<FormState>();
    final errorKey = GlobalKey();
    final isEditing = sensor != null;
    final farmOptions =
        _farmOptions().where((farm) => farm != 'All Farms').toList();
    String selectedFarm =
        sensor?.farm ?? (farmOptions.isNotEmpty ? farmOptions.first : '');
    String selectedType = sensor?.type ?? 'Temperature';
    String selectedStatus =
        sensor == null ? 'Active' : _backendStatus(sensor.status);
    bool alertsEnabled = sensor?.raw['alerts_enabled'] == true;
    bool isSaving = false;
    String? modalError;
    final defaultLimits = _defaultLimitsForType(selectedType);

    final modelController = TextEditingController(
      text: sensor?.raw['model_number']?.toString() ?? '',
    );
    final serialController = TextEditingController(
      text: sensor?.raw['serial_number']?.toString() ?? sensor?.id ?? '',
    );
    final locationController = TextEditingController(text: sensor?.zone ?? '');
    final valueController = TextEditingController(text: sensor?.reading ?? '');
    final unitController = TextEditingController(
      text: sensor?.unit ?? _unitForType(selectedType),
    );
    final rangeMinController = TextEditingController(
      text: sensor?.raw['range_min']?.toString() ??
          (selectedType == 'VPD' ? '' : '${defaultLimits.$1}'),
    );
    final rangeMaxController = TextEditingController(
      text: sensor?.raw['range_max']?.toString() ??
          (selectedType == 'VPD' ? '' : '${defaultLimits.$2}'),
    );
    final warningMinController = TextEditingController(
      text: sensor?.raw['warning_min']?.toString() ??
          (selectedType == 'VPD' ? '' : '${defaultLimits.$3}'),
    );
    final warningMaxController = TextEditingController(
      text: sensor?.raw['warning_max']?.toString() ??
          (selectedType == 'VPD' ? '' : '${defaultLimits.$4}'),
    );
    final maintenanceController = TextEditingController(
      text: sensor?.raw['maintenance_frequency']?.toString() ?? 'Monthly',
    );
    final lastMaintenanceController = TextEditingController(
      text: (sensor?.raw['last_maintenance_date']?.toString() ??
              DateTime.now().toIso8601String())
          .split('T')
          .first,
    );

    await showAppDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> save() async {
              if (isSaving || !(formKey.currentState?.validate() ?? false))
                return;
              final farm =
                  _farmDocuments.cast<Map<String, dynamic>?>().firstWhere(
                (item) {
                  final name =
                      (item?['name'] ?? item?['farm_name'] ?? '').toString();
                  return name == selectedFarm;
                },
                orElse: () => null,
              );
              setModalState(() {
                isSaving = true;
                modalError = null;
              });
              try {
                final data = {
                  'farmID': (farm?[r'$id'] ?? farm?['farm_id'] ?? selectedFarm)
                      .toString(),
                  'farm_name': selectedFarm,
                  'sensortype': _backendType(selectedType),
                  'model_number': modelController.text.trim(),
                  'location': locationController.text.trim(),
                  'value': valueController.text.trim(),
                  'status': selectedStatus,
                  'unit': unitController.text.trim(),
                  'alerts_enabled': alertsEnabled.toString(),
                  'maintenance_frequency': maintenanceController.text.trim(),
                  'timestamp': DateTime.now().toIso8601String(),
                  'last_maintenance_date':
                      lastMaintenanceController.text.trim(),
                };
                if (rangeMinController.text.trim().isNotEmpty) {
                  data['range_min'] = rangeMinController.text.trim();
                }
                if (rangeMaxController.text.trim().isNotEmpty) {
                  data['range_max'] = rangeMaxController.text.trim();
                }
                if (warningMinController.text.trim().isNotEmpty) {
                  data['warning_min'] = warningMinController.text.trim();
                }
                if (warningMaxController.text.trim().isNotEmpty) {
                  data['warning_max'] = warningMaxController.text.trim();
                }
                if (isEditing) {
                  data['serial_number'] = serialController.text.trim();
                  await _api.updateSensor(
                    id: (sensor.raw[r'$id'] ?? sensor.id).toString(),
                    data: data,
                  );
                } else {
                  await _api.createSensor(data: data);
                }
                if (!mounted || !dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                await _loadSensors();
              } catch (error) {
                if (!dialogContext.mounted) return;
                setModalState(() {
                  modalError = error.toString();
                  isSaving = false;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final errorContext = errorKey.currentContext;
                  if (errorContext != null) {
                    Scrollable.ensureVisible(errorContext,
                        duration: const Duration(milliseconds: 200));
                  }
                });
              }
            }

            return SensorFormDialog(
              editing: isEditing,
              saving: isSaving,
              onSave: save,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dialogDropdown(
                      label: 'Farm',
                      value: selectedFarm.isEmpty ? null : selectedFarm,
                      items: farmOptions,
                      isDark: isDark,
                      validator: (value) =>
                          value == null ? 'Select a farm first' : null,
                      onChanged: isSaving
                          ? null
                          : (value) =>
                              setModalState(() => selectedFarm = value!),
                    ),
                    const SizedBox(height: 14),
                    SensorFormRow(
                      children: [
                        Expanded(
                          child: _dialogDropdown(
                            label: 'Sensor Type',
                            value: selectedType,
                            items: const [
                              'Temperature',
                              'Humidity',
                              'CO2',
                              'Light',
                              'pH Level',
                              'EC Level',
                              'Water Level',
                              'Current',
                              'Voltage',
                              'Wattage',
                              'VPD',
                            ],
                            isDark: isDark,
                            onChanged: isSaving
                                ? null
                                : (value) {
                                    setModalState(() {
                                      selectedType = value!;
                                      unitController.text =
                                          _unitForType(selectedType);
                                      final limits = _defaultLimitsForType(
                                        selectedType,
                                      );
                                      rangeMinController.text =
                                          selectedType == 'VPD'
                                              ? ''
                                              : '${limits.$1}';
                                      rangeMaxController.text =
                                          selectedType == 'VPD'
                                              ? ''
                                              : '${limits.$2}';
                                      warningMinController.text =
                                          selectedType == 'VPD'
                                              ? ''
                                              : '${limits.$3}';
                                      warningMaxController.text =
                                          selectedType == 'VPD'
                                              ? ''
                                              : '${limits.$4}';
                                    });
                                  },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dialogDropdown(
                            label: 'Status',
                            value: selectedStatus,
                            items: const [
                              'Active',
                              'Inactive',
                              'Faulty',
                              'Maintenance',
                            ],
                            isDark: isDark,
                            onChanged: isSaving
                                ? null
                                : (value) => setModalState(
                                      () => selectedStatus = value!,
                                    ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SensorFormSectionHeader(
                      title: 'Range Settings',
                      subtitle:
                          'Set normal operating limits and wider warning limits for alerts.',
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SensorFormRow(
                      children: [
                        Expanded(
                          child: _dialogField(
                            controller: rangeMinController,
                            label: 'Normal Min',
                            isDark: isDark,
                            enabled: !isSaving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) => _rangeValidator(
                              value: value,
                              normalMinText: value,
                              normalMaxText: rangeMaxController.text,
                              warningMinText: warningMinController.text,
                              warningMaxText: warningMaxController.text,
                              isMinimum: true,
                              requiredField: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dialogField(
                            controller: rangeMaxController,
                            label: 'Normal Max',
                            isDark: isDark,
                            enabled: !isSaving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) => _rangeValidator(
                              value: value,
                              normalMinText: rangeMinController.text,
                              normalMaxText: value,
                              warningMinText: warningMinController.text,
                              warningMaxText: warningMaxController.text,
                              isMinimum: false,
                              requiredField: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SensorFormRow(
                      children: [
                        Expanded(
                          child: _dialogField(
                            controller: warningMinController,
                            label: 'Warning Low',
                            isDark: isDark,
                            enabled: !isSaving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) => _rangeValidator(
                              value: value,
                              normalMinText: rangeMinController.text,
                              normalMaxText: rangeMaxController.text,
                              warningMinText: value,
                              warningMaxText: warningMaxController.text,
                              isMinimum: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dialogField(
                            controller: warningMaxController,
                            label: 'Warning High',
                            isDark: isDark,
                            enabled: !isSaving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) => _rangeValidator(
                              value: value,
                              normalMinText: rangeMinController.text,
                              normalMaxText: rangeMaxController.text,
                              warningMinText: warningMinController.text,
                              warningMaxText: value,
                              isMinimum: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SensorFormRow(
                      stackOnMobile: true,
                      children: [
                        Expanded(
                          child: _dialogField(
                            controller: modelController,
                            label: 'Model Number',
                            isDark: isDark,
                            enabled: !isSaving,
                            validator: _requiredValidator,
                          ),
                        ),
                        if (isEditing) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _dialogField(
                                    controller: serialController,
                                    label: 'Serial Number',
                                    isDark: isDark,
                                    enabled: false,
                                    validator: _requiredValidator,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: IconButton(
                                    tooltip: 'Copy serial number',
                                    onPressed: () => _copySerialNumber(
                                      serialController.text.trim(),
                                    ),
                                    icon: const Icon(
                                      Icons.copy_rounded,
                                      size: 18,
                                    ),
                                    color: AppColors.info,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!isEditing) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Serial number will be generated automatically from the selected farm name, for example FARM-NAME-001.',
                        style: AppTypography.caption.copyWith(
                          color:
                              isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _dialogField(
                      controller: locationController,
                      label: 'Location / Zone',
                      isDark: isDark,
                      enabled: !isSaving,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 14),
                    SensorFormRow(
                      children: [
                        Expanded(
                          child: _dialogField(
                            controller: valueController,
                            label: 'Current Reading',
                            isDark: isDark,
                            enabled: !isSaving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              if (_requiredValidator(value) != null) {
                                return _requiredValidator(value);
                              }
                              return double.tryParse(value!.trim()) == null
                                  ? 'Enter a number'
                                  : null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dialogField(
                            controller: unitController,
                            label: selectedType == 'VPD'
                                ? 'Unit (kPa / psi)'
                                : 'Unit',
                            isDark: isDark,
                            enabled: !isSaving,
                            validator: _requiredValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SensorFormRow(
                      children: [
                        Expanded(
                          child: _dialogField(
                            controller: maintenanceController,
                            label: 'Maintenance Frequency',
                            isDark: isDark,
                            enabled: !isSaving,
                            validator: _requiredValidator,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dialogField(
                            controller: lastMaintenanceController,
                            label: 'Last Maintenance Date',
                            isDark: isDark,
                            enabled: !isSaving,
                            validator: _requiredValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile.adaptive(
                      value: alertsEnabled,
                      onChanged: isSaving
                          ? null
                          : (value) =>
                              setModalState(() => alertsEnabled = value),
                      title: const Text('Alerts enabled'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (modalError != null) ...[
                      Container(
                        key: errorKey,
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.10),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Text(
                          modalError!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    for (final controller in [
      modelController,
      serialController,
      locationController,
      valueController,
      unitController,
      rangeMinController,
      rangeMaxController,
      warningMinController,
      warningMaxController,
      maintenanceController,
      lastMaintenanceController
    ]) {
      controller.dispose();
    }
  }

  String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  String? _rangeValidator({
    required String? value,
    required String? normalMinText,
    required String? normalMaxText,
    required String? warningMinText,
    required String? warningMaxText,
    required bool isMinimum,
    bool requiredField = false,
  }) {
    if (requiredField && (value == null || value.trim().isEmpty)) {
      return 'Required';
    }

    double? parse(String? text) {
      if (text == null || text.trim().isEmpty) return null;
      return double.tryParse(text.trim());
    }

    final normalMin = parse(normalMinText);
    final normalMax = parse(normalMaxText);
    final warningMin = parse(warningMinText);
    final warningMax = parse(warningMaxText);
    final current = parse(value);

    if (value != null && value.trim().isNotEmpty && current == null) {
      return 'Enter a number';
    }
    if (normalMin != null && normalMax != null && normalMin >= normalMax) {
      return isMinimum ? 'Must be below max' : 'Must be above min';
    }
    if (warningMin != null && normalMin != null && warningMin > normalMin) {
      return 'Should be <= normal min';
    }
    if (warningMax != null && normalMax != null && warningMax < normalMax) {
      return 'Should be >= normal max';
    }
    if (warningMin != null && warningMax != null && warningMin >= warningMax) {
      return isMinimum ? 'Must be below high' : 'Must be above low';
    }
    return null;
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return _sensorFieldLabel(
        label,
        isDark,
        TextFormField(
          style: AppTypography.font(
              fontSize: AppTypography.captionSize,
              color: isDark ? Colors.white : AppColors.textPrimary),
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          decoration: _dialogInputDecoration(label, isDark),
        ));
  }

  Widget _dialogDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required bool isDark,
    required ValueChanged<String?>? onChanged,
    String? Function(String?)? validator,
  }) {
    return _sensorFieldLabel(
        label,
        isDark,
        DropdownButtonFormField<String>(
          isExpanded: true,
          style: AppTypography.font(
              fontSize: AppTypography.captionSize,
              color: isDark ? Colors.white : AppColors.textPrimary),
          initialValue: items.contains(value) ? value : null,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
          validator: validator,
          decoration: _dialogInputDecoration(label, isDark),
        ));
  }

  Widget _sensorFieldLabel(String label, bool dark, Widget field) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: AppTypography.font(
                fontSize: AppTypography.fieldLabelSize,
                fontWeight: AppTypography.headingWeight,
                color: dark ? Colors.white70 : AppColors.textSecondary)),
        const SizedBox(height: 6),
        field,
      ]);

  InputDecoration _dialogInputDecoration(String label, bool isDark) {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      prefixIcon: const Icon(Icons.sensors_outlined, size: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 36),
      errorMaxLines: 3,
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      filled: true,
      fillColor:
          isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.neutral50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : AppColors.neutral300,
        ),
      ),
    );
  }

  void _showSensorDetails(_IotSensor initial, bool isDark) {
    showAppDialog<void>(
      context: context,
      builder: (_) => DeviceTelemetryDetailsModal(currentDetails: () {
        final matches = _sensors.where((sensor) => sensor.id == initial.id);
        final sensor = matches.isEmpty ? initial : matches.first;
        return DeviceTelemetryDetails(
          name: sensor.name,
          serial: sensor.id,
          reading: sensor.reading + ' ' + sensor.unit,
          readingStatus: _readingDiagnosticLabel(sensor),
          color: _readingDiagnosticColor(sensor),
          location: {
            'Farm': sensor.farm,
            'Zone': sensor.zone,
            'Online state': sensor.isOnline ? 'Online' : 'Offline',
            'Last telemetry': sensor.lastSeen,
          },
          configuration: {
            'Normal range': sensor.rangeLabel,
            'Warning limits': sensor.warningLabel,
            'Model / firmware': sensor.firmware,
            'Maintenance': _maintenanceLabel(sensor),
            'Alerts':
                sensor.raw['alerts_enabled'] == true ? 'Enabled' : 'Disabled',
            'Protocol': sensor.protocol,
          },
          sensor: {...sensor.raw, 'unit': sensor.unit},
        );
      }),
    );
  }
}

class _SensorFormSectionHeader extends StatelessWidget {
  const _SensorFormSectionHeader({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.info,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: AppTypography.bodyWeight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
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

class _SensorDeviceCard extends StatelessWidget {
  const _SensorDeviceCard({
    required this.sensor,
    required this.isDark,
    required this.onDetails,
    required this.onSettings,
    this.onDelete,
  });

  final _IotSensor sensor;
  final bool isDark;
  final VoidCallback onDetails;
  final VoidCallback onSettings;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(sensor);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: sensor.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(sensor.icon, color: sensor.color, size: 27),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: AppTypography.bodyWeight,
                      ),
                    ),
                    Text(
                      '${sensor.protocol} - ${sensor.firmware}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.62)
                            : AppColors.textSecondary,
                        fontWeight: AppTypography.bodyWeight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            sensor.id,
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.54)
                                  : AppColors.textSecondary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: sensor.id),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Serial number ${sensor.id} copied'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          child: const Padding(
                            padding: EdgeInsets.all(3),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 15,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(
                    label: sensor.isOnline ? 'Online' : 'Offline',
                    color: sensor.isOnline
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  _StatusBadge(label: sensor.status, color: statusColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                sensor.reading,
                style: AppTypography.h3.copyWith(
                  color: sensor.color,
                  fontWeight: AppTypography.bodyWeight,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  sensor.unit,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.62)
                        : AppColors.textSecondary,
                    fontWeight: AppTypography.bodyWeight,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _TrendPill(sensor.trend, sensor.trend.startsWith('-'), isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Normal range: ${sensor.rangeLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.60)
                  : AppColors.textSecondary,
              fontWeight: AppTypography.bodyWeight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Warning limits: ${sensor.warningLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.52)
                  : AppColors.textSecondary,
              fontWeight: AppTypography.bodyWeight,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _HealthBar(
            label: 'Device health',
            value: sensor.health,
            color: statusColor,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _TelemetryChip(
                  icon: Icons.battery_charging_full_rounded,
                  label: '${sensor.battery}%',
                  color: _batteryColor(sensor),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TelemetryChip(
                  icon: Icons.network_cell_rounded,
                  label: '${sensor.signal} dBm',
                  color: _signalColor(sensor),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.place_rounded,
                size: 16,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.58)
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${sensor.farm} - ${sensor.zone}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.64)
                        : AppColors.textSecondary,
                    fontWeight: AppTypography.bodyWeight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Last seen ${sensor.lastSeen}',
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.52)
                        : AppColors.textSecondary,
                    fontWeight: AppTypography.bodyWeight,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDetails,
                tooltip: 'Diagnostics',
                icon: const Icon(Icons.visibility_outlined),
                color: AppColors.info,
              ),
              IconButton(
                onPressed: onSettings,
                tooltip: 'Settings',
                icon: const Icon(Icons.tune_rounded),
                color: AppColors.primary,
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Delete sensor',
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.error,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FleetStatCard extends StatelessWidget {
  const _FleetStatCard({
    required this.stat,
    required this.isDark,
    required this.isMobile,
  });

  final _FleetStat stat;
  final bool isDark;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: Row(
        children: [
          Container(
            width: isMobile ? 40 : 48,
            height: isMobile ? 40 : 48,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(stat.icon, color: stat.color, size: isMobile ? 21 : 25),
          ),
          SizedBox(width: isMobile ? 8 : AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: AppTypography.bodyWeight,
                  ),
                ),
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.62)
                        : AppColors.textSecondary,
                    fontWeight: AppTypography.bodyWeight,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppTypography.fieldLabelSize,
          fontWeight: AppTypography.bodyWeight,
        ),
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill(this.label, this.isDown, this.isDark);

  final String label;
  final bool isDown;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDown ? AppColors.warning : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDown ? Icons.trending_down_rounded : Icons.trending_up_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: AppTypography.fieldLabelSize,
              fontWeight: AppTypography.bodyWeight,
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryChip extends StatelessWidget {
  const _TelemetryChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: AppTypography.bodyWeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  const _HealthBar({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.62)
                      : AppColors.textSecondary,
                  fontWeight: AppTypography.bodyWeight,
                ),
              ),
            ),
            Text(
              '$value%',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: AppTypography.bodyWeight,
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
            backgroundColor: color.withValues(alpha: 0.13),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
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

Color _statusColor(_IotSensor sensor) {
  switch (sensor.status) {
    case 'Active':
    case 'Online':
      return AppColors.success;
    case 'Warning':
      return AppColors.warning;
    case 'Critical':
      return AppColors.error;
    default:
      return AppColors.textSecondary;
  }
}

Color _batteryColor(_IotSensor sensor) {
  if (sensor.battery >= 60) return AppColors.success;
  if (sensor.battery >= 25) return AppColors.warning;
  return AppColors.error;
}

Color _signalColor(_IotSensor sensor) {
  if (sensor.signal >= -60) return AppColors.success;
  if (sensor.signal >= -78) return AppColors.warning;
  return AppColors.error;
}

class _IotSensor {
  const _IotSensor({
    required this.id,
    required this.name,
    required this.type,
    required this.farm,
    required this.zone,
    required this.reading,
    required this.unit,
    required this.status,
    required this.health,
    required this.battery,
    required this.signal,
    required this.firmware,
    required this.gateway,
    required this.protocol,
    required this.lastSeen,
    required this.lastTelemetryAt,
    required this.isOnline,
    required this.rangeLabel,
    required this.warningLabel,
    required this.trend,
    required this.icon,
    required this.color,
    this.raw = const {},
  });

  final String id;
  final String name;
  final String type;
  final String farm;
  final String zone;
  final String reading;
  final String unit;
  final String status;
  final int health;
  final int battery;
  final int signal;
  final String firmware;
  final String gateway;
  final String protocol;
  final String lastSeen;
  final DateTime? lastTelemetryAt;
  final bool isOnline;
  final String rangeLabel;
  final String warningLabel;
  final String trend;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> raw;
}

class _FleetStat {
  const _FleetStat(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _MobileNavItem {
  const _MobileNavItem(this.icon, this.activeIcon, this.label, this.route);

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
}
