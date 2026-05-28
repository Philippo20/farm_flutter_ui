import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../core/widgets/superadmin_sidebar.dart';

class ModernSensorsScreen extends ConsumerStatefulWidget {
  const ModernSensorsScreen({super.key, this.isSuperAdmin = false});

  final bool isSuperAdmin;

  @override
  ConsumerState<ModernSensorsScreen> createState() =>
      _ModernSensorsScreenState();
}

class _ModernSensorsScreenState extends ConsumerState<ModernSensorsScreen> {
  String _selectedFarm = 'All Farms';
  String _selectedStatus = 'All';
  String _selectedType = 'All Types';

  final List<_IotSensor> _sensors = const [
    _IotSensor(
      id: 'IOT-TMP-001',
      name: 'Greenhouse Climate Node A1',
      type: 'Temperature',
      farm: 'Northern Estate',
      zone: 'Greenhouse 1',
      reading: '22.4',
      unit: 'C',
      status: 'Online',
      health: 98,
      battery: 85,
      signal: -54,
      firmware: 'v3.8.1',
      gateway: 'GW-NOR-01',
      protocol: 'LoRaWAN',
      lastSeen: '42 sec ago',
      rangeLabel: '18 - 28 C',
      trend: '+0.8 C',
      icon: Icons.thermostat_rounded,
      color: AppColors.chartOrange,
    ),
    _IotSensor(
      id: 'IOT-HUM-014',
      name: 'Canopy Humidity Probe B2',
      type: 'Humidity',
      farm: 'Northern Estate',
      zone: 'Field 2',
      reading: '65',
      unit: '% RH',
      status: 'Online',
      health: 96,
      battery: 92,
      signal: -49,
      firmware: 'v3.8.1',
      gateway: 'GW-NOR-02',
      protocol: 'LoRaWAN',
      lastSeen: '1 min ago',
      rangeLabel: '55 - 75% RH',
      trend: '-2%',
      icon: Icons.water_drop_rounded,
      color: AppColors.chartBlue,
    ),
    _IotSensor(
      id: 'IOT-PH-031',
      name: 'Hydroponic pH Inline Sensor',
      type: 'pH Level',
      farm: 'Southern Estate',
      zone: 'Hydroponic Bay',
      reading: '6.2',
      unit: 'pH',
      status: 'Warning',
      health: 74,
      battery: 45,
      signal: -72,
      firmware: 'v3.7.9',
      gateway: 'GW-SOU-01',
      protocol: 'MQTT',
      lastSeen: '2 min ago',
      rangeLabel: '5.8 - 6.4 pH',
      trend: '+0.3 pH',
      icon: Icons.science_rounded,
      color: AppColors.chartPurple,
    ),
    _IotSensor(
      id: 'IOT-CO2-008',
      name: 'Storage CO2 Air Quality Node',
      type: 'CO2',
      farm: 'Eastern Farm',
      zone: 'Cold Storage',
      reading: '810',
      unit: 'ppm',
      status: 'Online',
      health: 91,
      battery: 78,
      signal: -61,
      firmware: 'v3.8.0',
      gateway: 'GW-EAS-01',
      protocol: 'Wi-Fi',
      lastSeen: '3 min ago',
      rangeLabel: '650 - 950 ppm',
      trend: '+32 ppm',
      icon: Icons.air_rounded,
      color: AppColors.chartTeal,
    ),
    _IotSensor(
      id: 'IOT-SM-056',
      name: 'Soil Moisture Stake E5',
      type: 'Moisture',
      farm: 'Western Farm',
      zone: 'Field 5',
      reading: '27',
      unit: '% VWC',
      status: 'Critical',
      health: 58,
      battery: 15,
      signal: -86,
      firmware: 'v3.6.4',
      gateway: 'GW-WES-02',
      protocol: 'LoRaWAN',
      lastSeen: '18 sec ago',
      rangeLabel: '35 - 55% VWC',
      trend: '-11%',
      icon: Icons.grass_rounded,
      color: AppColors.primary,
    ),
    _IotSensor(
      id: 'IOT-WL-022',
      name: 'Reservoir Level Ultrasonic Node',
      type: 'Water Level',
      farm: 'Northern Estate',
      zone: 'Tank A',
      reading: '75',
      unit: 'cm',
      status: 'Online',
      health: 89,
      battery: 68,
      signal: -64,
      firmware: 'v3.8.1',
      gateway: 'GW-NOR-03',
      protocol: 'NB-IoT',
      lastSeen: '58 sec ago',
      rangeLabel: '60 - 100 cm',
      trend: '-4 cm',
      icon: Icons.water_rounded,
      color: AppColors.info,
    ),
  ];

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile ? _buildMobileLayout(isDark) : _buildDesktopLayout(isDark),
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    return Row(
      children: [
        widget.isSuperAdmin
            ? SuperAdminSidebar(
                selectedIndex: 11,
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
                onProfileTap: () {},
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
    return Column(
      children: [
        ModernAdminHeader(
          userName: widget.isSuperAdmin ? 'Super Admin' : 'Admin',
          onNotificationTap: () {},
          onProfileTap: () {},
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        _buildHealthStrip(isDark),
        const SizedBox(height: AppSpacing.lg),
        _buildFilters(isDark),
        const SizedBox(height: AppSpacing.lg),
        _buildFleetGrid(isDark),
      ],
    );
  }

  Widget _buildHero(bool isDark, bool isMobile) {
    final online = _sensors.where((sensor) => sensor.status == 'Online').length;
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
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Real-time farm telemetry, device health, gateway connectivity, and sensor diagnostics across all estates.',
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
              fontWeight: FontWeight.w600,
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
            value: '5 / 5',
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthStrip(bool isDark) {
    final warning =
        _sensors.where((sensor) => sensor.status == 'Warning').length;
    final critical =
        _sensors.where((sensor) => sensor.status == 'Critical').length;
    final avgHealth =
        (_sensors.fold<int>(0, (sum, s) => sum + s.health) / _sensors.length)
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
        final columns = constraints.maxWidth >= 1000
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
              child: _FleetStatCard(stat: stat, isDark: isDark),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFilters(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildDropdown(
            label: 'Farm',
            value: _selectedFarm,
            items: const [
              'All Farms',
              'Northern Estate',
              'Southern Estate',
              'Eastern Farm',
              'Western Farm',
            ],
            isDark: isDark,
            onChanged: (value) => setState(() => _selectedFarm = value!),
          ),
          _buildDropdown(
            label: 'Status',
            value: _selectedStatus,
            items: const ['All', 'Online', 'Warning', 'Critical'],
            isDark: isDark,
            onChanged: (value) => setState(() => _selectedStatus = value!),
          ),
          _buildDropdown(
            label: 'Sensor Type',
            value: _selectedType,
            items: const [
              'All Types',
              'Temperature',
              'Humidity',
              'pH Level',
              'CO2',
              'Moisture',
              'Water Level',
            ],
            isDark: isDark,
            onChanged: (value) => setState(() => _selectedType = value!),
          ),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _selectedFarm = 'All Farms';
                _selectedStatus = 'All';
                _selectedType = 'All Types';
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reset'),
          ),
          FilledButton.icon(
            onPressed: () => _showAddSensorDialog(isDark),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Register Device'),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 210,
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
                fontWeight: FontWeight.w700,
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
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${sensors.length} devices',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
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
                        fontSize: 10,
                        color: selected
                            ? AppColors.primary
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.62)
                                : AppColors.textSecondary),
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Device registration workflow coming soon')),
    );
  }

  void _showSensorSettings(_IotSensor sensor, bool isDark) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening settings for ${sensor.id}')),
    );
  }

  void _showSensorDetails(_IotSensor sensor, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: sensor.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(sensor.icon, color: sensor.color, size: 28),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sensor.name,
                            style: AppTypography.titleMedium.copyWith(
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${sensor.id} • ${sensor.gateway}',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.62)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    _DetailTile('Reading', '${sensor.reading} ${sensor.unit}',
                        sensor.icon, sensor.color, isDark),
                    _DetailTile(
                        'Health',
                        '${sensor.health}%',
                        Icons.health_and_safety_rounded,
                        AppColors.success,
                        isDark),
                    _DetailTile(
                        'Battery',
                        '${sensor.battery}%',
                        Icons.battery_charging_full_rounded,
                        _batteryColor(sensor),
                        isDark),
                    _DetailTile(
                        'Signal',
                        '${sensor.signal} dBm',
                        Icons.network_cell_rounded,
                        _signalColor(sensor),
                        isDark),
                    _DetailTile('Protocol', sensor.protocol,
                        Icons.settings_input_antenna, AppColors.info, isDark),
                    _DetailTile(
                        'Firmware',
                        sensor.firmware,
                        Icons.system_update_alt_rounded,
                        AppColors.chartPurple,
                        isDark),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _InfoLine('Farm', sensor.farm, isDark),
                _InfoLine('Zone', sensor.zone, isDark),
                _InfoLine('Safe range', sensor.rangeLabel, isDark),
                _InfoLine('Last telemetry', sensor.lastSeen, isDark),
              ],
            ),
          ),
        ),
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
  });

  final _IotSensor sensor;
  final bool isDark;
  final VoidCallback onDetails;
  final VoidCallback onSettings;

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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${sensor.id} • ${sensor.protocol}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.62)
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: sensor.status, color: statusColor),
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
                  fontWeight: FontWeight.w700,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _TrendPill(sensor.trend, sensor.trend.startsWith('-'), isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Target range: ${sensor.rangeLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.60)
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
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
                  '${sensor.farm} • ${sensor.zone}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.64)
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
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
                    fontWeight: FontWeight.w600,
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
            ],
          ),
        ],
      ),
    );
  }
}

class _FleetStatCard extends StatelessWidget {
  const _FleetStatCard({required this.stat, required this.isDark});

  final _FleetStat stat;
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
              color: stat.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(stat.icon, color: stat.color, size: 25),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
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
                    fontWeight: FontWeight.w700,
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
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
                fontWeight: FontWeight.w700,
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
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$value%',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
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

class _DetailTile extends StatelessWidget {
  const _DetailTile(this.label, this.value, this.icon, this.color, this.isDark);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.56)
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value, this.isDark);

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.56)
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
    required this.rangeLabel,
    required this.trend,
    required this.icon,
    required this.color,
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
  final String rangeLabel;
  final String trend;
  final IconData icon;
  final Color color;
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
