import '../../core/widgets/technician_dashboard_overview.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/technician_mobile_bottom_nav.dart';
import '../../core/widgets/technician_sidebar.dart';
import '../../core/widgets/role_mobile_navigation.dart';
import '../../core/widgets/technician_header.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../services/superadmin_api_service.dart';

/// Technician Dashboard - Redesigned
/// Maintenance and technical support
class TechnicianDashboardRedesigned extends ConsumerStatefulWidget {
  const TechnicianDashboardRedesigned({super.key});

  @override
  ConsumerState<TechnicianDashboardRedesigned> createState() =>
      _TechnicianDashboardRedesignedState();
}

class _TechnicianDashboardRedesignedState
    extends ConsumerState<TechnicianDashboardRedesigned> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedNavIndex = 0;
  WeatherInfo? _weatherInfo;
  final SuperAdminApiService _api = SuperAdminApiService();
  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _fetching = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _sensors = [];

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadDashboardData({bool silent = false}) async {
    if (_fetching) return;
    _fetching = true;
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      final results = await Future.wait([
        _api.getAlerts(),
        user == null
            ? Future.value(<Map<String, dynamic>>[])
            : _api.getTechnicianRepairHistory(user.id),
        _api.getSensors(),
      ]);
      if (!mounted) return;
      final farmIds = user?.farmId == null ? <String>{} : {user!.farmId!};
      final userId = user?.id ?? '';
      bool belongsToTechnician(Map<String, dynamic> item) {
        final assignedTo = _value(item, ['assigned_to_id', 'technician_id']);
        final farmId = _value(item, ['farm_id', 'farmId', 'farmID']);
        if (assignedTo.isNotEmpty) return assignedTo == userId;
        if (farmIds.isNotEmpty && farmId.isNotEmpty) {
          return farmIds.contains(farmId);
        }
        return true;
      }

      setState(() {
        _alerts = results[0].where(belongsToTechnician).toList();
        _tasks = results[1].where(belongsToTechnician).toList();
        _sensors = results[2].where(belongsToTechnician).toList();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (!silent) _errorMessage = error.toString();
      });
    } finally {
      _fetching = false;
    }
  }

  String _value(Map<String, dynamic> data, List<String> keys,
      [String fallback = '']) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Technician';
    final userEmail = authState.user?.email ?? 'technician@farmestates.com';
    final userRole = 'Technician';

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? RoleMobileDrawer(
              userName: userName,
              userEmail: userEmail,
              userRole: userRole,
              selectedIndex: _selectedNavIndex,
              onItemSelected: (_) {},
              items: technicianNavigationItems,
            )
          : null,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      floatingActionButton: !isMobile
          ? FloatingActionButton.extended(
              onPressed: () {},
              backgroundColor: AppColors.error,
              icon: const Icon(Icons.add),
              label: const Text('Report Issue'),
            )
          : null,
      bottomNavigationBar: isMobile
          ? TechnicianMobileBottomNav(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
            )
          : null,
    );
  }

  Widget _buildDesktopLayout(
      bool isDark, String userName, String userEmail, String userRole) {
    return Row(
      children: [
        // Sidebar
        TechnicianSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) {
            setState(() {
              _selectedNavIndex = index;
            });
          },
          userName: userName,
          userEmail: userEmail,
          userRole: userRole,
        ),

        // Main Content
        Expanded(
          child: Column(
            children: [
              // Header
              TechnicianHeader(
                userName: userName,
                weatherInfo: _weatherInfo,
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                onNotificationTap: () {
                  // Handle notifications
                },
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _isLoading
                      ? const Center(child: AdminDataSkeleton(rowCount: 5))
                      : _errorMessage != null
                          ? _buildErrorState(isDark)
                          : TechnicianDashboardOverview(
                              sensors: _sensors,
                              tasks: _tasks,
                              alerts: _alerts),
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
        TechnicianHeader(
          userName: userName,
          weatherInfo: _weatherInfo,
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          onNotificationTap: () {
            // Handle notifications
          },
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _isLoading
                ? const Center(child: AdminDataSkeleton(rowCount: 5))
                : _errorMessage != null
                    ? _buildErrorState(isDark)
                    : TechnicianDashboardOverview(
                        sensors: _sensors, tasks: _tasks, alerts: _alerts),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 42,
                color: isDark ? Colors.white54 : AppColors.textSecondary),
            const SizedBox(height: 8),
            Text('Unable to load technician dashboard',
                style: AppTypography.h6.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Text(_errorMessage ?? 'Please try again.',
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
