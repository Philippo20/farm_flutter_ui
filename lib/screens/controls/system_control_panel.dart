import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_farm_data.dart';
import 'widgets/pump_control_card.dart';
import 'widgets/light_control_card.dart';
import 'widgets/climate_control_card.dart';
import 'widgets/ph_control_card.dart';

/// System Control Panel
/// Comprehensive control interface for all farm systems
class SystemControlPanel extends ConsumerStatefulWidget {
  const SystemControlPanel({super.key});

  @override
  ConsumerState<SystemControlPanel> createState() => _SystemControlPanelState();
}

class _SystemControlPanelState extends ConsumerState<SystemControlPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final systemControls = MockFarmData.getSystemControls();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('System Control Panel'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () {
              _showEmergencyStop(context);
            },
            icon: const Icon(Icons.emergency),
            tooltip: 'Emergency Stop',
            color: AppColors.error,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.water_drop), text: 'Pumps'),
            Tab(icon: Icon(Icons.light_mode), text: 'Lights'),
            Tab(icon: Icon(Icons.thermostat), text: 'Climate'),
            Tab(icon: Icon(Icons.science), text: 'pH Control'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pumps Tab
          _buildPumpsTab(systemControls, isDark),
          
          // Lights Tab
          _buildLightsTab(systemControls, isDark),
          
          // Climate Tab
          _buildClimateTab(systemControls, isDark),
          
          // pH Control Tab
          _buildPhControlTab(systemControls, isDark),
        ],
      ),
    );
  }

  Widget _buildPumpsTab(Map<String, dynamic> systemControls, bool isDark) {
    final pumps = systemControls['pumps'] as Map<String, dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pump Controls',
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Manage water circulation and nutrient delivery systems',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          PumpControlCard(
            pumpName: 'Nutrient Pump',
            pumpData: pumps['nutrientPump'],
            onToggle: (value) => _togglePump('nutrientPump', value),
            onSchedule: () => _showScheduleDialog('Nutrient Pump'),
          ),
          const SizedBox(height: AppSpacing.md),
          
          PumpControlCard(
            pumpName: 'Water Pump',
            pumpData: pumps['waterPump'],
            onToggle: (value) => _togglePump('waterPump', value),
            onSchedule: () => _showScheduleDialog('Water Pump'),
          ),
          const SizedBox(height: AppSpacing.md),
          
          PumpControlCard(
            pumpName: 'Circulation Pump',
            pumpData: pumps['circulationPump'],
            onToggle: (value) => _togglePump('circulationPump', value),
            onSchedule: () => _showScheduleDialog('Circulation Pump'),
          ),
        ],
      ),
    );
  }

  Widget _buildLightsTab(Map<String, dynamic> systemControls, bool isDark) {
    final lights = systemControls['lights'] as Map<String, dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lighting Controls',
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Control grow lights and photoperiod settings',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          LightControlCard(
            lightName: 'Grow Lights Rack 1',
            lightData: lights['rack1'],
            onToggle: (value) => _toggleLight('rack1', value),
            onBrightnessChange: (value) => _adjustBrightness('rack1', value),
            onSchedule: () => _showScheduleDialog('Grow Lights Rack 1'),
          ),
          const SizedBox(height: AppSpacing.md),
          
          LightControlCard(
            lightName: 'Grow Lights Rack 2',
            lightData: lights['rack2'],
            onToggle: (value) => _toggleLight('rack2', value),
            onBrightnessChange: (value) => _adjustBrightness('rack2', value),
            onSchedule: () => _showScheduleDialog('Grow Lights Rack 2'),
          ),
        ],
      ),
    );
  }

  Widget _buildClimateTab(Map<String, dynamic> systemControls, bool isDark) {
    final climate = systemControls['climate'] as Map<String, dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Climate Controls',
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Manage temperature, humidity, and ventilation',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          ClimateControlCard(
            systemName: 'HVAC System',
            climateData: climate['hvac'],
            onToggle: (value) => _toggleClimate('hvac', value),
            onModeChange: (mode) => _changeClimateMode('hvac', mode),
            onTempChange: (temp) => _adjustTemperature('hvac', temp),
          ),
          const SizedBox(height: AppSpacing.md),
          
          ClimateControlCard(
            systemName: 'Ventilation',
            climateData: climate['ventilation'],
            onToggle: (value) => _toggleClimate('ventilation', value),
            onModeChange: (mode) => _changeClimateMode('ventilation', mode),
            onTempChange: (temp) => _adjustTemperature('ventilation', temp),
          ),
        ],
      ),
    );
  }

  Widget _buildPhControlTab(Map<String, dynamic> systemControls, bool isDark) {
    final phControl = systemControls['phControl'] as Map<String, dynamic>;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'pH Control System',
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Automatic pH adjustment and monitoring',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          PhControlCard(
            controlName: 'pH Up Relay',
            controlData: phControl['phUp'],
            onToggle: (value) => _togglePhControl('phUp', value),
            onManualDose: () => _manualDose('phUp'),
          ),
          const SizedBox(height: AppSpacing.md),
          
          PhControlCard(
            controlName: 'pH Down Relay',
            controlData: phControl['phDown'],
            onToggle: (value) => _togglePhControl('phDown', value),
            onManualDose: () => _manualDose('phDown'),
          ),
        ],
      ),
    );
  }

  // Control Methods
  void _togglePump(String pumpId, bool value) {
    setState(() {
      // Update pump state
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pump ${value ? "activated" : "deactivated"}'),
        backgroundColor: value ? AppColors.success : AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleLight(String lightId, bool value) {
    setState(() {
      // Update light state
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lights ${value ? "turned on" : "turned off"}'),
        backgroundColor: value ? AppColors.success : AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _adjustBrightness(String lightId, double brightness) {
    setState(() {
      // Update brightness
    });
  }

  void _toggleClimate(String systemId, bool value) {
    setState(() {
      // Update climate system state
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Climate system ${value ? "activated" : "deactivated"}'),
        backgroundColor: value ? AppColors.success : AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _changeClimateMode(String systemId, String mode) {
    setState(() {
      // Update climate mode
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Climate mode changed to $mode'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _adjustTemperature(String systemId, double temp) {
    setState(() {
      // Update temperature setpoint
    });
  }

  void _togglePhControl(String controlId, bool value) {
    setState(() {
      // Update pH control state
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('pH control ${value ? "enabled" : "disabled"}'),
        backgroundColor: value ? AppColors.success : AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _manualDose(String controlId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manual ${controlId == "phUp" ? "pH Up" : "pH Down"} Dose'),
        content: const Text('Are you sure you want to manually dose the solution?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Manual dose initiated'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Dose'),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog(String systemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schedule $systemName'),
        content: const Text('Schedule configuration coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyStop(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Stop'),
          ],
        ),
        content: const Text(
          'This will immediately stop ALL systems. Only use in emergency situations.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('EMERGENCY STOP ACTIVATED'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 5),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('STOP ALL'),
          ),
        ],
      ),
    );
  }
}
