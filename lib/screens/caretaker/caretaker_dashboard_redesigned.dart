import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/caretaker_mobile_bottom_nav.dart';
import '../../core/widgets/caretaker_sidebar.dart';
import '../../core/widgets/caretaker_header.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/weather_time_widget.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../widgets/alert_summary_card.dart';
import '../../widgets/cards/farm/first_row.dart';
import '../../widgets/cards/farm/second_row.dart';
import '../../widgets/cards/farm/third_row.dart';
import '../../widgets/cards/farm/fourth_row.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Caretaker Dashboard – Professional Redesign
class CaretakerDashboardRedesigned extends ConsumerStatefulWidget {
  const CaretakerDashboardRedesigned({super.key});

  @override
  ConsumerState<CaretakerDashboardRedesigned> createState() =>
      _CaretakerDashboardRedesignedState();
}

class _CaretakerDashboardRedesignedState
    extends ConsumerState<CaretakerDashboardRedesigned> {
  final SuperAdminApiService _api = SuperAdminApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedNavIndex = 0;
  WeatherInfo? _weatherInfo;
  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _selectedDashboardTab = 0;
  bool _showAllTasks = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _farms = [];
  List<Map<String, dynamic>> _batches = [];
  List<Map<String, dynamic>> _inventory = [];
  List<Map<String, dynamic>> _sensors = [];
  List<Map<String, dynamic>> _sensorReadings = [];
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _weatherInfo = const WeatherInfo(condition: 'Sunny', temperature: 28.5);
    _loadDashboardData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadDashboardData(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

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

  double _number(dynamic value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  DateTime? _date(dynamic value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) return null;
    return DateTime.tryParse(text);
  }

  String _farmId(Map<String, dynamic> farm) =>
      _value(farm, const [r'$id', 'id', 'farm_id', 'farmID']);

  bool _matchesCurrentCaretaker(Map<String, dynamic> farm) {
    final user = ref.read(authProvider).user;
    if (user == null) return false;
    final caretaker = _value(farm, const ['caretakerID', 'caretaker_id']);
    final caretakerName = _value(farm, const ['caretaker_name']);
    return caretaker == user.id ||
        caretaker == user.email ||
        caretaker == user.name ||
        caretakerName.toLowerCase() == user.name.toLowerCase();
  }

  List<Map<String, dynamic>> get _assignedFarms {
    final farms = _farms.where(_matchesCurrentCaretaker).toList();
    if (farms.isNotEmpty) return farms;
    final user = ref.read(authProvider).user;
    if (user == null) return [];
    return _farms.where((farm) {
      final text = farm.values.join(' ').toLowerCase();
      return text.contains(user.id.toLowerCase()) ||
          text.contains(user.email.toLowerCase()) ||
          text.contains(user.name.toLowerCase());
    }).toList();
  }

  Set<String> get _assignedFarmIds =>
      _assignedFarms.map(_farmId).where((id) => id.isNotEmpty).toSet();

  Set<String> get _assignedFarmNames => _assignedFarms
      .map((farm) => _value(farm, const ['name', 'farm_name']))
      .where((name) => name.isNotEmpty)
      .toSet();

  bool _matchesAssignedFarm(Map<String, dynamic> doc) {
    final farmIds = _assignedFarmIds;
    final farmNames = _assignedFarmNames;
    final id = _value(doc, const ['farmID', 'farm_id', 'farmId']);
    final name = _value(doc, const ['farm_name', 'farm']);
    return (id.isNotEmpty && farmIds.contains(id)) ||
        (name.isNotEmpty && farmNames.contains(name));
  }

  List<Map<String, dynamic>> get _assignedBatches =>
      _batches.where(_matchesAssignedFarm).toList();

  List<Map<String, dynamic>> get _assignedInventory =>
      _inventory.where(_matchesAssignedFarm).toList();

  List<Map<String, dynamic>> get _assignedSensors =>
      _sensors.where(_matchesAssignedFarm).toList();

  List<Map<String, dynamic>> get _assignedTasks {
    final user = ref.read(authProvider).user;
    final directTasks = _tasks.where((task) {
      final directAssignee = _value(task, const [
        'assigned_to_id',
        'assigned_to_email',
        'assigned_to_name',
      ]);
      return user != null &&
          (directAssignee == user.id ||
              directAssignee == user.email ||
              directAssignee == user.name);
    }).toList();
    final farmTasks = _tasks.where(_matchesAssignedFarm).toList();
    final merged = <String, Map<String, dynamic>>{};
    for (final task in [...farmTasks, ...directTasks]) {
      final taskKey = _value(task, const [r'$id', 'id', 'task_id'],
          fallback: '${_value(task, const ['title'])}|${_value(task, const [
                'farm_id',
                'farm_name'
              ])}|${_value(task, const ['due_date'])}');
      merged[taskKey] = task;
    }
    return merged.values.toList();
  }

  List<Map<String, dynamic>> get _assignedSensorReadings =>
      _sensorReadings.where(_matchesAssignedFarm).toList();

  Future<void> _loadDashboardData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else if (mounted) {
      setState(() => _isRefreshing = true);
    }

    try {
      final results = await Future.wait([
        _api.getFarms(),
        _api.getBatches(),
        _api.getInventory(),
        _api.getSensors(),
        _api.getSensorReadingsAll(),
        _api.getFarmTasks(),
      ]);
      if (!mounted) return;
      setState(() {
        _farms = results[0];
        _batches = results[1];
        _inventory = results[2];
        _sensors = results[3];
        _sensorReadings = results[4];
        _tasks = results[5];
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final auth = ref.watch(authProvider);
    final userName = auth.user?.name ?? 'Caretaker';
    final userEmail = auth.user?.email ?? 'caretaker@farmestates.com';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? CaretakerMobileDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
              userName: userName,
              userEmail: userEmail,
            )
          : null,
      body: isMobile
          ? _mobileShell(isDark, userName)
          : _desktopShell(isDark, userName, userEmail),
      floatingActionButton: _selectedDashboardTab == 1 || _showAllTasks
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/record-entry'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(isMobile ? 'Record' : 'New Record',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
      bottomNavigationBar: isMobile
          ? CaretakerMobileBottomNav(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
            )
          : null,
    );
  }

  // ─── desktop shell ────────────────────────────────────────────────────────

  Widget _desktopShell(bool isDark, String userName, String userEmail) {
    return Row(children: [
      CaretakerSidebar(
        selectedIndex: _selectedNavIndex,
        onItemSelected: (i) => setState(() => _selectedNavIndex = i),
        userName: userName,
        userEmail: userEmail,
        userRole: 'Caretaker',
      ),
      Expanded(
        child: Column(children: [
          CaretakerHeader(
              userName: userName,
              weatherInfo: _weatherInfo,
              onNotificationTap: () {}),
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              final narrow = box.maxWidth < 700;
              return SingleChildScrollView(
                padding: EdgeInsets.all(narrow ? 16 : 24),
                child: _dashboardContent(isDark, narrow: narrow),
              );
            }),
          ),
        ]),
      ),
    ]);
  }

  // ─── mobile shell ─────────────────────────────────────────────────────────

  Widget _mobileShell(bool isDark, String userName) {
    return Column(children: [
      CaretakerHeader(
          userName: userName,
          weatherInfo: _weatherInfo,
          onNotificationTap: () {}),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          child: _dashboardContent(isDark, narrow: true),
        ),
      ),
    ]);
  }

  // ─── shared dashboard content ─────────────────────────────────────────────

  Widget _dashboardContent(bool isDark, {required bool narrow}) {
    if (_isLoading) {
      return const AdminDataSkeleton(rowCount: 6);
    }
    if (_errorMessage != null) {
      return _errorState(isDark);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dashboardTabs(isDark, narrow),
        const SizedBox(height: 16),
        if (_selectedDashboardTab == 1)
          _sensorNestedView(isDark, narrow: narrow)
        else if (_showAllTasks)
          _allTasksView(isDark, narrow: narrow)
        else ...[
          _dashboardHeader(isDark, narrow),
          const SizedBox(height: 16),
          Transform.translate(
            offset: Offset(0, narrow ? -66 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kpiSection(isDark),
                const SizedBox(height: 20),
                // ── top: weather + alerts ──
                if (narrow)
                  const WeatherTimeWidget()
                else
                  const SizedBox(
                      width: double.infinity, child: WeatherTimeWidget()),

                const SizedBox(height: 20),

                // ── KPI cards ──
                const SizedBox(height: 24),
                Transform.translate(
                  offset: Offset(0, narrow ? -50 : 0),
                  child: _alertsAndTasks(isDark, narrow),
                ),

                const SizedBox(height: 24),

                // ── quick actions ──
                Transform.translate(
                  offset: Offset(0, narrow ? -50 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(
                          isDark, 'Quick Actions', Icons.grid_view_rounded),
                      const SizedBox(height: 12),
                      Transform.translate(
                        offset: Offset(0, narrow ? -50 : 0),
                        child: _quickActions(isDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _dashboardTabs(bool isDark, bool narrow) {
    final surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inactive = isDark ? Colors.white60 : AppColors.textSecondary;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Row(
            children: [
              _dashboardTab(
                selected: _selectedDashboardTab == 0,
                icon: Icons.auto_awesome_rounded,
                label: 'Recent',
                inactiveColor: inactive,
                onTap: () => setState(() {
                  _selectedDashboardTab = 0;
                  _showAllTasks = false;
                }),
              ),
              _dashboardTab(
                selected: _selectedDashboardTab == 1,
                icon: Icons.sensors_rounded,
                label: narrow ? 'All IoT' : 'All IoT Dashboard',
                inactiveColor: inactive,
                onTap: () => setState(() {
                  _selectedDashboardTab = 1;
                  _showAllTasks = false;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardTab({
    required bool selected,
    required IconData icon,
    required String label,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color:
            selected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 17,
                    color: selected ? AppColors.primary : inactiveColor),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? AppColors.primary : inactiveColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── KPI section ──────────────────────────────────────────────────────────

  Widget _dashboardHeader(bool isDark, bool narrow) {
    final farmCount = _assignedFarms.length;
    final openTasks = _assignedTasks
        .where((task) =>
            _value(task, const ['status']).toLowerCase() != 'completed')
        .length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(narrow ? 16 : 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                const Icon(Icons.agriculture_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farmCount == 0
                      ? 'No assigned farm found'
                      : '$farmCount assigned farm${farmCount == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(
                    fontSize: narrow ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  farmCount == 0
                      ? 'Ask an admin or farm manager to assign a farm to your caretaker account.'
                      : '$openTasks open task${openTasks == 1 ? '' : 's'} across your assigned farms.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_isRefreshing)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _errorState(bool isDark) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 42, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Unable to load dashboard',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _sensorOverviewData() {
    final latest = <String, Map<String, dynamic>>{};
    for (final sensor in _assignedSensors) {
      final type = _normalizeSensorType(_value(sensor, const ['sensortype']));
      if (type.isEmpty) continue;
      latest[type] = sensor;
    }
    for (final reading in _assignedSensorReadings) {
      final type = _normalizeSensorType(_value(reading, const ['sensortype']));
      if (type.isEmpty) continue;
      final currentDate = _date(reading['timestamp']);
      final previousDate = _date(latest[type]?['timestamp']);
      if (!latest.containsKey(type) ||
          (currentDate != null &&
              (previousDate == null || currentDate.isAfter(previousDate)))) {
        latest[type] = reading;
      }
    }

    Map<String, dynamic> reading(String type, double fallback, String unit) {
      final doc = latest[type];
      return {
        'value': doc == null ? fallback : _number(doc['value'], fallback),
        'unit':
            doc == null ? unit : _value(doc, const ['unit'], fallback: unit),
        'hasSensor': doc != null,
      };
    }

    return {
      'temperature': reading('temperature', 0, 'C'),
      'humidity': reading('humidity', 0, '%'),
      'ph': reading('ph', 0, 'pH'),
      'ec': reading('ec', 0, 'mS/cm'),
      'co2': reading('co2', 0, 'ppm'),
      'light': reading('light', 0, 'lux'),
      'waterTemp': reading('water_temperature', 0, 'C'),
      'waterLevel': reading('water_level', 0, '%'),
      'electricityCurrent': reading('electricity_current', 0, 'A'),
      'electricityVoltage': reading('electricity_voltage', 0, 'V'),
      'electricityWattage': reading('electricity_wattage', 0, 'W'),
      'tds': reading('tds', 0, 'ppm'),
    };
  }

  String _normalizeSensorType(String type) {
    final normalized =
        type.toLowerCase().trim().replaceAll('-', '_').replaceAll(' ', '_');
    switch (normalized) {
      case 'temp':
      case 'temperature':
        return 'temperature';
      case 'humidity':
      case 'humid':
        return 'humidity';
      case 'ph':
      case 'ph_level':
        return 'ph';
      case 'ec':
      case 'ec_level':
        return 'ec';
      case 'co2':
      case 'co₂':
      case 'carbon_dioxide':
        return 'co2';
      case 'light':
      case 'lux':
        return 'light';
      case 'water_temp':
      case 'water_temperature':
        return 'water_temperature';
      case 'water':
      case 'water_level':
        return 'water_level';
      case 'electricity_current':
      case 'current':
        return 'electricity_current';
      case 'electricity_voltage':
      case 'voltage':
        return 'electricity_voltage';
      case 'electricity_wattage':
      case 'wattage':
      case 'power':
        return 'electricity_wattage';
      case 'tds':
        return 'tds';
      default:
        return normalized;
    }
  }

  bool _isSensorActive(Map<String, dynamic> sensor) {
    final latest = _latestTelemetryAt(sensor);
    if (latest == null) return false;
    final age = DateTime.now().toUtc().difference(latest.toUtc());
    return age.inSeconds <= 30;
  }

  DateTime? _latestTelemetryAt(Map<String, dynamic> sensor) {
    final serial = _value(sensor, const ['serial_number']);
    final sensorId = _value(sensor, const [r'$id', 'sensor_id', 'id']);
    DateTime? latest = _date(sensor['timestamp']);

    for (final reading in _assignedSensorReadings) {
      final readingSerial = _value(reading, const ['serial_number']);
      final readingSensorId = _value(reading, const ['sensor_id']);
      final matchesSerial = serial.isNotEmpty && readingSerial == serial;
      final matchesSensorId =
          sensorId.isNotEmpty && readingSensorId == sensorId;
      if (!matchesSerial && !matchesSensorId) continue;

      final readingAt = _date(reading['timestamp']);
      if (readingAt != null && (latest == null || readingAt.isAfter(latest))) {
        latest = readingAt;
      }
    }

    return latest;
  }

  Map<String, int> _sensorTypeCounts({bool activeOnly = false}) {
    final counts = <String, int>{};
    for (final sensor in _assignedSensors) {
      if (activeOnly && !_isSensorActive(sensor)) continue;
      final type = _normalizeSensorType(_value(sensor, const ['sensortype']));
      if (type.isEmpty) continue;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  double? _latestSensorValue(String type) {
    final normalizedType = _normalizeSensorType(type);
    DateTime? latestAt;
    double? latestValue;
    for (final reading in _assignedSensorReadings) {
      if (_normalizeSensorType(_value(reading, const ['sensortype'])) !=
          normalizedType) {
        continue;
      }
      final value = _number(reading['value'], double.nan);
      if (value.isNaN) continue;
      final timestamp = _date(reading['timestamp']);
      if (latestValue == null ||
          (timestamp != null &&
              (latestAt == null || timestamp.isAfter(latestAt)))) {
        latestValue = value;
        latestAt = timestamp;
      }
    }
    if (latestValue != null) return latestValue;
    final overview = _sensorOverviewData()[normalizedType];
    if (overview is Map && overview['hasSensor'] == true) {
      return _number(overview['value']);
    }
    return null;
  }

  List<double> _sensorHistoryValues(String type) {
    final normalizedType = _normalizeSensorType(type);
    final readings = _assignedSensorReadings
        .where((reading) =>
            _normalizeSensorType(_value(reading, const ['sensortype'])) ==
            normalizedType)
        .toList()
      ..sort((a, b) {
        final aDate = _date(a['timestamp']);
        final bDate = _date(b['timestamp']);
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return -1;
        if (bDate == null) return 1;
        return aDate.compareTo(bDate);
      });
    return readings
        .map((reading) => _number(reading['value'], double.nan))
        .where((value) => !value.isNaN)
        .toList();
  }

  String _taskId(Map<String, dynamic> task) =>
      _value(task, const [r'$id', 'id', 'task_id']);

  Color _taskStatusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'completed':
        return AppColors.success;
      case 'started':
      case 'in progress':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      case 'not started':
        return AppColors.neutral500;
      default:
        return AppColors.warning;
    }
  }

  String _taskDateLabel(String value) {
    final date = _date(value);
    if (date == null) return value.isEmpty ? 'No due date' : value;
    final local = date.toLocal();
    final month = const [
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
    ][local.month - 1];
    return '$month ${local.day}, ${local.year}';
  }

  Widget _allTasksView(bool isDark, {required bool narrow}) {
    final tasks = [..._assignedTasks]..sort((a, b) =>
        (_date(_value(b, const ['due_date'])) ?? DateTime(9999))
            .compareTo(_date(_value(a, const ['due_date'])) ?? DateTime(9999)));
    final completed = tasks
        .where((task) =>
            _value(task, const ['status']).toLowerCase().trim() == 'completed')
        .length;
    final open = tasks.length - completed;
    final inProgress = tasks.where((task) {
      final status = _value(task, const ['status']).toLowerCase().trim();
      return status == 'started' || status == 'in progress';
    }).length;
    final dueSoon = tasks.where((task) {
      final dueDate = _date(_value(task, const ['due_date']));
      if (dueDate == null) return false;
      final days = dueDate.difference(DateTime.now()).inHours / 24;
      return open > 0 && days >= 0 && days <= 2;
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(narrow ? 16 : 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() => _showAllTasks = false),
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : AppColors.neutral100,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      size: 20,
                      color: isDark ? Colors.white : AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.assignment_rounded,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Assigned Tasks',
                        style: GoogleFonts.inter(
                          fontSize: narrow ? 16 : 19,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        )),
                    const SizedBox(height: 4),
                    Text('$open open • $completed completed',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color:
                              isDark ? Colors.white54 : AppColors.textSecondary,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!narrow) ...[
          Row(
            children: [
              Expanded(
                child: _taskMetricCard(isDark, 'Open tasks', '$open',
                    Icons.pending_actions_rounded, AppColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _taskMetricCard(isDark, 'In progress', '$inProgress',
                    Icons.timelapse_rounded, AppColors.info),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _taskMetricCard(isDark, 'Due soon', '$dueSoon',
                    Icons.event_available_rounded, AppColors.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _taskMetricCard(isDark, 'Completed', '$completed',
                    Icons.check_circle_rounded, AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (tasks.isEmpty)
          _emptyTaskState(isDark)
        else
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(narrow ? 12 : 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 700) {
                  final cardWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 0,
                    children: tasks
                        .map((task) => SizedBox(
                              width: cardWidth,
                              child: _taskTile(task, isDark),
                            ))
                        .toList(),
                  );
                }
                return Column(
                  children:
                      tasks.map((task) => _taskTile(task, isDark)).toList(),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _taskMetricCard(
      bool isDark, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.035) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertsAndTasks(bool isDark, bool narrow) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: const AlertSummaryCard(
                  showRecentAlerts: true,
                  maxRecentAlerts: 3,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _tasksSection(isDark, narrow)),
            ],
          );
        }

        return Column(
          children: [
            const AlertSummaryCard(
              showRecentAlerts: true,
              maxRecentAlerts: 3,
            ),
            const SizedBox(height: 16),
            _tasksSection(isDark, narrow),
          ],
        );
      },
    );
  }

  Widget _tasksSection(bool isDark, bool narrow) {
    final tasks = [..._assignedTasks]..sort((a, b) =>
        (_date(_value(b, const ['due_date'])) ?? DateTime(9999))
            .compareTo(_date(_value(a, const ['due_date'])) ?? DateTime(9999)));
    final open = tasks
        .where((task) =>
            _value(task, const ['status'], fallback: 'Pending').toLowerCase() !=
            'completed')
        .length;
    final surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(narrow ? 14 : 18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.assignment_rounded,
                    color: AppColors.primary, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Assigned Tasks',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tasks.isEmpty
                          ? 'No tasks assigned yet'
                          : '$open open of ${tasks.length} task${tasks.length == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (tasks.isNotEmpty)
                narrow
                    ? IconButton(
                        onPressed: () => setState(() => _showAllTasks = true),
                        tooltip: 'View all tasks',
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      )
                    : TextButton.icon(
                        onPressed: () => setState(() => _showAllTasks = true),
                        icon: const Icon(Icons.open_in_new_rounded, size: 15),
                        label: const Text('View all'),
                      ),
            ],
          ),
          const SizedBox(height: 14),
          if (tasks.isEmpty)
            _emptyTaskState(isDark)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final visibleTasks = tasks.take(3).toList();
                if (constraints.maxWidth >= 700 && visibleTasks.length > 1) {
                  final cardWidth = (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 0,
                    children: visibleTasks
                        .map((task) => SizedBox(
                              width: cardWidth,
                              child: _taskTile(task, isDark),
                            ))
                        .toList(),
                  );
                }
                return Column(
                  children: visibleTasks
                      .map((task) => _taskTile(task, isDark))
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _emptyTaskState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.035) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.checklist_rounded,
              color: isDark ? Colors.white38 : AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Assigned work will appear here when a farm manager creates a task for you.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskTile(Map<String, dynamic> task, bool isDark) {
    final status = _value(task, const ['status'], fallback: 'Pending');
    final statusColor = _taskStatusColor(status);
    final title = _value(task, const ['title'], fallback: 'Untitled task');
    final farm = _value(task, const ['farm_name'], fallback: 'Assigned farm');
    final due = _value(task, const ['due_date']);
    final hasReply = _value(task, const ['caretaker_comment']).isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? Colors.white.withOpacity(0.035) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showCaretakerTaskDialog(task, isDark),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    status.toLowerCase() == 'completed'
                        ? Icons.check_circle_rounded
                        : Icons.assignment_turned_in_rounded,
                    color: statusColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          )),
                      const SizedBox(height: 3),
                      Text(
                        due.isEmpty
                            ? farm
                            : '$farm • Due ${_taskDateLabel(due)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color:
                              isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                      ),
                      if (hasReply) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.reply_rounded,
                                size: 12,
                                color: isDark
                                    ? Colors.white54
                                    : AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text('Reply added',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: isDark
                                      ? Colors.white54
                                      : AppColors.textSecondary,
                                )),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: _taskStatusBadge(status, statusColor),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    color: isDark ? Colors.white38 : AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _taskStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Map<String, dynamic> _caretakerTaskPayload(
    Map<String, dynamic> task, {
    required String status,
    required String caretakerComment,
  }) {
    return {
      'farm_id': _value(task, const ['farm_id']),
      'farm_name': _value(task, const ['farm_name']),
      'title': _value(task, const ['title'], fallback: 'Untitled task'),
      'description': _value(task, const ['description']),
      'manager_comment': _value(task, const ['manager_comment']),
      'caretaker_comment': caretakerComment,
      'assigned_to_id': _value(task, const ['assigned_to_id']),
      'assigned_to_name':
          _value(task, const ['assigned_to_name'], fallback: 'Caretaker'),
      'assigned_by_id': _value(task, const ['assigned_by_id']),
      'assigned_by_name':
          _value(task, const ['assigned_by_name'], fallback: 'Farm Manager'),
      'priority': _value(task, const ['priority'], fallback: 'Medium'),
      'status': status,
      if (_value(task, const ['due_date']).isNotEmpty)
        'due_date': _value(task, const ['due_date']),
    };
  }

  void _showCaretakerTaskDialog(Map<String, dynamic> task, bool isDark) {
    final replyController = TextEditingController(
      text: _value(task, const ['caretaker_comment']),
    );
    const statuses = [
      'Not Started',
      'Started',
      'Pending',
      'In Progress',
      'Completed',
    ];
    final currentStatus = _value(task, const ['status'], fallback: 'Pending');
    var selectedStatus =
        statuses.contains(currentStatus) ? currentStatus : 'Pending';
    var isSaving = false;
    String? errorMessage;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final statusColor = _taskStatusColor(selectedStatus);
          final taskTitle =
              _value(task, const ['title'], fallback: 'Task details');
          final farm =
              _value(task, const ['farm_name'], fallback: 'Assigned farm');
          final assignedBy = _value(task, const ['assigned_by_name'],
              fallback: 'Farm Manager');
          final dueDate = _taskDateLabel(_value(task, const ['due_date']));
          final instructions = _value(task, const ['description'],
              fallback: 'No task instructions were added.');
          final managerComment = _value(task, const ['manager_comment']);

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700, maxHeight: 780),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 28,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 22, 14, 20),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(isDark ? 0.08 : 0.05),
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : AppColors.neutral200,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(Icons.assignment_turned_in_rounded,
                                color: statusColor, size: 25),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('TASK REVIEW',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                      color: statusColor,
                                    )),
                                const SizedBox(height: 5),
                                Text(taskTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    )),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _taskStatusBadge(
                                        selectedStatus, statusColor),
                                    _taskStatusBadge(
                                      _value(task, const ['priority'],
                                          fallback: 'Medium'),
                                      AppColors.info,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close task details',
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final tiles = [
                                  _taskMetaTile('Farm', farm,
                                      Icons.agriculture_rounded, isDark),
                                  _taskMetaTile('Assigned by', assignedBy,
                                      Icons.person_outline_rounded, isDark),
                                  _taskMetaTile('Due date', dueDate,
                                      Icons.event_available_rounded, isDark),
                                  _taskMetaTile('Task ID', _taskId(task),
                                      Icons.tag_rounded, isDark),
                                ];
                                final width = constraints.maxWidth < 520
                                    ? constraints.maxWidth
                                    : (constraints.maxWidth - 12) / 2;
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: tiles
                                      .map((tile) =>
                                          SizedBox(width: width, child: tile))
                                      .toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            _taskDialogSection(
                              isDark: isDark,
                              title: 'Task instructions',
                              subtitle:
                                  'Review the work assigned by your manager.',
                              icon: Icons.notes_rounded,
                              child: Text(instructions,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: isDark
                                        ? Colors.white70
                                        : AppColors.textPrimary,
                                  )),
                            ),
                            if (managerComment.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _taskDialogSection(
                                isDark: isDark,
                                title: 'Manager note',
                                subtitle: 'Additional guidance for this task.',
                                icon: Icons.campaign_outlined,
                                child: Text(managerComment,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: isDark
                                          ? Colors.white70
                                          : AppColors.textPrimary,
                                    )),
                              ),
                            ],
                            const SizedBox(height: 12),
                            _taskDialogSection(
                              isDark: isDark,
                              title: 'Update task',
                              subtitle:
                                  'Change the status and send a progress note.',
                              icon: Icons.edit_note_rounded,
                              child: Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    initialValue:
                                        statuses.contains(selectedStatus)
                                            ? selectedStatus
                                            : 'Pending',
                                    decoration: const InputDecoration(
                                      labelText: 'Status',
                                      prefixIcon: Icon(Icons.flag_outlined),
                                    ),
                                    items: statuses
                                        .map((status) => DropdownMenuItem(
                                              value: status,
                                              child: Text(status),
                                            ))
                                        .toList(),
                                    onChanged: isSaving
                                        ? null
                                        : (value) {
                                            if (value != null) {
                                              setDialogState(
                                                  () => selectedStatus = value);
                                            }
                                          },
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: replyController,
                                    enabled: !isSaving,
                                    minLines: 4,
                                    maxLines: 6,
                                    decoration: const InputDecoration(
                                      labelText: 'Reply or completion note',
                                      hintText:
                                          'Tell the manager what you completed or need help with...',
                                      alignLabelWithHint: true,
                                      prefixIcon: Padding(
                                        padding: EdgeInsets.only(bottom: 66),
                                        child: Icon(Icons.reply_rounded),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (errorMessage != null) ...[
                              const SizedBox(height: 12),
                              _taskDialogError(errorMessage!, isDark),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : AppColors.neutral200,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      setDialogState(() {
                                        isSaving = true;
                                        errorMessage = null;
                                      });
                                      try {
                                        await _api.updateFarmTask(
                                          id: _taskId(task),
                                          data: _caretakerTaskPayload(
                                            task,
                                            status: selectedStatus,
                                            caretakerComment:
                                                replyController.text.trim(),
                                          ),
                                        );
                                        if (!dialogContext.mounted) return;
                                        Navigator.pop(dialogContext);
                                      } catch (error) {
                                        setDialogState(() {
                                          isSaving = false;
                                          errorMessage = error.toString();
                                        });
                                      }
                                    },
                              icon: isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.save_rounded, size: 18),
                              label:
                                  Text(isSaving ? 'Saving...' : 'Save update'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).then((_) {
      replyController.dispose();
      if (mounted) {
        _loadDashboardData(silent: true);
      }
    });
  }

  Widget _taskMetaTile(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.035) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 17,
              color: isDark ? Colors.white54 : AppColors.textSecondary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary)),
                const SizedBox(height: 3),
                Text(value.isEmpty ? 'Not provided' : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskDialogSection({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.035) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color:
                isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 18, color: isDark ? Colors.white60 : AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: isDark
                                ? Colors.white54
                                : AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _taskDialogError(String message, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _sensorNestedView(bool isDark, {required bool narrow}) {
    final sensorCounts = _sensorTypeCounts();
    final activeSensorCounts = _sensorTypeCounts(activeOnly: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _nestedViewHeader(isDark, narrow),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, box) {
          final width = box.maxWidth;
          if (width > 1100) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: FirstRow(isDark: isDark)),
                const SizedBox(width: 14),
                Expanded(
                    child: SecondRow(
                  isDark: isDark,
                  liveTemperature: _latestSensorValue('temperature'),
                  liveTemperatureHistory: _sensorHistoryValues('temperature'),
                  sensorCounts: sensorCounts,
                  activeSensorCounts: activeSensorCounts,
                )),
                const SizedBox(width: 14),
                Expanded(
                    child: ThirdRow(
                  isDark: isDark,
                  sensorCounts: sensorCounts,
                  activeSensorCounts: activeSensorCounts,
                )),
                const SizedBox(width: 14),
                Expanded(child: FourthRow(isDark: isDark)),
              ],
            );
          }
          if (width > 700) {
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                    width: (width - 16) / 2, child: FirstRow(isDark: isDark)),
                SizedBox(
                    width: (width - 16) / 2,
                    child: SecondRow(
                      isDark: isDark,
                      liveTemperature: _latestSensorValue('temperature'),
                      liveTemperatureHistory:
                          _sensorHistoryValues('temperature'),
                      sensorCounts: sensorCounts,
                      activeSensorCounts: activeSensorCounts,
                    )),
                SizedBox(
                    width: (width - 16) / 2,
                    child: ThirdRow(
                      isDark: isDark,
                      sensorCounts: sensorCounts,
                      activeSensorCounts: activeSensorCounts,
                    )),
                SizedBox(
                    width: (width - 16) / 2, child: FourthRow(isDark: isDark)),
              ],
            );
          }
          return Column(
            children: [
              FirstRow(isDark: isDark),
              const SizedBox(height: 16),
              SecondRow(
                isDark: isDark,
                liveTemperature: _latestSensorValue('temperature'),
                liveTemperatureHistory: _sensorHistoryValues('temperature'),
                sensorCounts: sensorCounts,
                activeSensorCounts: activeSensorCounts,
              ),
              const SizedBox(height: 16),
              ThirdRow(
                isDark: isDark,
                sensorCounts: sensorCounts,
                activeSensorCounts: activeSensorCounts,
              ),
              const SizedBox(height: 16),
              FourthRow(isDark: isDark),
            ],
          );
        }),
      ],
    );
  }

  Widget _nestedViewHeader(bool isDark, bool narrow) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(narrow ? 14 : 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => setState(() => _selectedDashboardTab = 0),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : AppColors.neutral100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.sensors_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Sensor Readings',
                  style: GoogleFonts.inter(
                    fontSize: narrow ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Detailed farm monitoring panels for the assigned farm.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
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

  Widget _kpiSection(bool isDark) {
    final tasks = _assignedTasks;
    final completedTasks = tasks
        .where((task) =>
            _value(task, const ['status']).toLowerCase() == 'completed')
        .length;
    final activeSensors = _assignedSensors.where(_isSensorActive).length;
    final harvestWeight = _assignedBatches.fold<double>(
      0,
      (sum, batch) => sum + _number(batch['total_weight_kg']),
    );
    final inputValue = _assignedInventory.fold<double>(
      0,
      (sum, item) =>
          sum + (_number(item['quantity']) * _number(item['unit_cost'], 1)),
    );
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final cols = w > 700 ? 4 : 2;
      final gap = w < 400 ? 8.0 : 10.0;
      final cardW = (w - (cols - 1) * gap) / cols;
      final ratio = cardW < 155 ? 2.2 : (cardW < 200 ? 2.6 : 3.0);

      return GridView.count(
        crossAxisCount: cols,
        childAspectRatio: ratio,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _kpiCard(isDark, 'Tasks', '$completedTasks/${tasks.length}',
              Icons.task_alt_rounded, AppColors.primary,
              sub: tasks.isEmpty ? 'no assigned tasks' : 'completed'),
          _kpiCard(
              isDark,
              'Sensors',
              '$activeSensors/${_assignedSensors.length}',
              Icons.sensors_rounded,
              AppColors.success,
              sub: 'online'),
          _kpiCard(isDark, 'Harvest', '${harvestWeight.toStringAsFixed(1)} kg',
              Icons.agriculture_rounded, AppColors.warning,
              sub: 'recorded'),
          _kpiCard(isDark, 'Inputs', 'GHS ${inputValue.toStringAsFixed(0)}',
              Icons.inventory_2_rounded, AppColors.info,
              sub: 'inventory value'),
        ],
      );
    });
  }

  Widget _kpiCard(
      bool isDark, String title, String value, IconData icon, Color color,
      {String? sub}) {
    return LayoutBuilder(builder: (context, box) {
      final compact = box.maxWidth < 155;

      return Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14, vertical: compact ? 8 : 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(isDark ? 0.15 : 0.12),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                      color: color.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 3)),
                ],
        ),
        child: Row(children: [
          Container(
            padding: EdgeInsets.all(compact ? 6 : 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: compact ? 16 : 18, color: color),
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.inter(
                      fontSize: compact ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(sub ?? title,
                    style: GoogleFonts.inter(
                      fontSize: compact ? 10 : 11,
                      color: isDark ? Colors.white38 : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      );
    });
  }

  // ─── quick actions ────────────────────────────────────────────────────────

  Widget _quickActions(bool isDark) {
    final pendingTasks = _assignedTasks
        .where((task) =>
            _value(task, const ['status']).toLowerCase() != 'completed')
        .length;
    final pendingInputs = _assignedInventory
        .where((item) =>
            _value(item, const ['status'], fallback: 'Active').toLowerCase() ==
            'pending')
        .length;
    final records = _assignedBatches.length;

    final actions = <_QA>[
      _QA(
          'Record Entry',
          Icons.edit_note_rounded,
          AppColors.primary,
          '$pendingTasks pending',
          () => Navigator.pushNamed(context, '/record-entry')),
      _QA(
          'Confirm Inputs',
          Icons.check_circle_outline_rounded,
          AppColors.success,
          '$pendingInputs awaiting',
          () => Navigator.pushNamed(context, '/input-confirmation')),
      _QA('Calendar', Icons.calendar_month_rounded, AppColors.info,
          'View schedule', () => Navigator.pushNamed(context, '/calendar')),
      _QA('Chat', Icons.forum_rounded, AppColors.warning, 'Get help',
          () => Navigator.pushNamed(context, '/chat')),
      _QA(
          'Records',
          Icons.history_rounded,
          const Color(0xFF7E57C2),
          '$records batches',
          () => Navigator.pushNamed(context, '/record-entry')),
      _QA('Settings', Icons.tune_rounded, AppColors.neutral600, 'Preferences',
          () => Navigator.pushNamed(context, '/caretaker_settings')),
    ];

    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final cols =
          w > 1350 ? 6 : (w > 1024 ? 5 : (w > 780 ? 4 : (w > 400 ? 3 : 2)));
      final gap = w < 400 ? 8.0 : 10.0;
      final cardW = (w - (cols - 1) * gap) / cols;
      final isDesktop = w > 780;
      final ratio = isDesktop
          ? (cardW < 170 ? 1.35 : 1.55)
          : (cardW < 120 ? 0.9 : (cardW < 155 ? 1.0 : 1.15));
      return GridView.count(
        crossAxisCount: cols,
        childAspectRatio: ratio,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: actions.map((a) => _actionCard(isDark, a, cardW)).toList(),
      );
    });
  }

  Widget _actionCard(bool isDark, _QA a, double cardW) {
    final compact = cardW < 140;
    final denseDesktop = cardW >= 165;

    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: a.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          padding: EdgeInsets.all(denseDesktop ? 10 : (compact ? 10 : 14)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(denseDesktop ? 8 : (compact ? 10 : 12)),
                decoration: BoxDecoration(
                  color: a.color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  a.icon,
                  size: denseDesktop ? 20 : (compact ? 22 : 26),
                  color: a.color,
                ),
              ),
              SizedBox(height: denseDesktop ? 6 : (compact ? 8 : 10)),
              Text(a.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: denseDesktop ? 12 : (compact ? 12 : 13),
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  )),
              const SizedBox(height: 2),
              Text(a.sub,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: denseDesktop ? 10 : (compact ? 10 : 11),
                    color: isDark ? Colors.white38 : AppColors.textSecondary,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ─── section title ────────────────────────────────────────────────────────

  Widget _sectionTitle(bool isDark, String text, IconData icon) {
    return Row(children: [
      Icon(icon,
          size: 18, color: isDark ? Colors.white54 : AppColors.textSecondary),
      const SizedBox(width: 8),
      Text(text,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: isDark ? Colors.white : AppColors.textPrimary,
          )),
    ]);
  }

  // ─── bottom nav ───────────────────────────────────────────────────────────

  // ignore: unused_element
  Widget _bottomNav(bool isDark) {
    const items = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Home',
        'route': '/caretaker_dashboard'
      },
      {
        'icon': Icons.edit_note_outlined,
        'label': 'Record',
        'route': '/record-entry'
      },
      {
        'icon': Icons.check_circle_outline,
        'label': 'Confirm',
        'route': '/input-confirmation'
      },
      {'icon': Icons.forum_outlined, 'label': 'Chat', 'route': '/chat'},
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Calendar',
        'route': '/calendar'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
            top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06))),
        boxShadow: [
          if (!isDark)
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final m = e.value;
              final sel = i == _selectedNavIndex;
              final c = sel
                  ? AppColors.primary
                  : (isDark ? Colors.white38 : AppColors.textSecondary);

              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (i != _selectedNavIndex) {
                      setState(() => _selectedNavIndex = i);
                      try {
                        Navigator.pushReplacementNamed(
                            context, m['route'] as String);
                      } catch (_) {
                        try {
                          Navigator.pushNamed(context, m['route'] as String);
                        } catch (_) {}
                      }
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(m['icon'] as IconData, size: 22, color: c),
                      const SizedBox(height: 3),
                      Text(m['label'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                            color: c,
                          )),
                      if (sel)
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          width: 16,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
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

// ─── Quick Action model ─────────────────────────────────────────────────────

class _QA {
  final String title;
  final IconData icon;
  final Color color;
  final String sub;
  final VoidCallback onTap;
  const _QA(this.title, this.icon, this.color, this.sub, this.onTap);
}
