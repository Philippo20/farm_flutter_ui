import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_routes.dart';
import '../providers/enhanced_auth_provider.dart';

// Import screens
// Auth Screens
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';

// Dashboard Screens
import '../../screens/superadmin/superadmin_dashboard.dart';
import '../../screens/farm_manager/farm_manager_dashboard_redesigned.dart';
import '../../screens/farm_owner/farm_owner_dashboard_redesigned.dart';
import '../../screens/caretaker/caretaker_dashboard.dart';
import '../../screens/technician/technician_dashboard.dart';

// Farm Manager Screens
import '../../screens/farm_manager/batch_generation_screen.dart';
import '../../screens/farm_manager/inventory_management_screen.dart';
import '../../screens/farm_manager/fund_request_screen.dart';
import '../../screens/farm_manager/reports_screen.dart' as farm_manager;
import '../../screens/farm_manager/team_management_screen.dart';

// Farm Owner Screens
import '../../screens/farm_owner/digital_wallet_screen.dart';
import '../../screens/farm_owner/wallet_actions_screen.dart';
import '../../screens/farm_owner/analytics_screen.dart';
import '../../screens/farm_owner/reports_screen.dart' as farm_owner;
import '../../screens/farm_owner/settings_screen.dart';

// Caretaker Screens
import '../../screens/caretaker/record_entry_screen.dart';

// Technician Screens
import '../../screens/technician/maintenance_schedule_screen.dart';
import '../../screens/technician/sensor_management_screen.dart';

// Alert Screens
import '../../screens/alerts/alert_management_screen.dart';

// Control Screens
import '../../screens/controls/system_control_panel.dart';

// Admin Screens
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/modern_sensors_screen.dart';
import '../../screens/admin/manage_users_screen.dart';
import '../../screens/admin/settings_screen.dart';

// Super Admin Screens
import '../../screens/superadmin/user_management_screen.dart';
import '../../screens/superadmin/farm_management_screen.dart';
import '../../screens/superadmin/system_config_screen.dart';
import '../../screens/superadmin/audit_logs_screen.dart';
import '../../screens/superadmin/backup_restore_screen.dart';

// Note: Common screens (profile, alerts, farms, sensors) to be created later

// Phase 3 Screens
import '../../screens/analytics/analytics_dashboard.dart';
import '../../screens/analytics/sensor_history_screen.dart';
import '../../screens/analytics/alert_trends_screen.dart';
import '../../screens/reports/reports_screen.dart';
import '../../screens/search/global_search_screen.dart';

/// Router Provider
/// Provides the GoRouter instance with all route configurations
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(enhancedAuthProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;

      // Redirect to login if not authenticated
      if (!isLoggedIn && !isLoggingIn) {
        return AppRoutes.login;
      }

      // Redirect to dashboard if already logged in and trying to access login
      if (isLoggedIn && isLoggingIn) {
        final user = authState.user;
        if (user != null) {
          return AppRoutes.getDashboardByRole(user.role.name);
        }
      }

      return null; // No redirect needed
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const ModernLoginScreen(),
      ),

      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // Dashboard Routes
      GoRoute(
        path: AppRoutes.superAdminDashboard,
        name: 'super-admin-dashboard',
        builder: (context, state) => const SuperAdminDashboard(),
      ),

      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'admin-dashboard',
        builder: (context, state) => const ModernAdminDashboardScreen(),
      ),

      GoRoute(
        path: AppRoutes.farmManagerDashboard,
        name: 'farm-manager-dashboard',
        builder: (context, state) => const FarmManagerDashboardRedesigned(),
        routes: [
          GoRoute(
            path: 'batch-generation',
            name: 'batch-generation',
            builder: (context, state) => const BatchGenerationScreen(),
          ),
          GoRoute(
            path: 'inventory',
            name: 'inventory-management',
            builder: (context, state) => const InventoryManagementScreen(),
          ),
          GoRoute(
            path: 'fund-request',
            name: 'fund-request',
            builder: (context, state) => const FundRequestScreen(),
          ),
          GoRoute(
            path: 'reports',
            name: 'reports',
            builder: (context, state) => const farm_manager.ReportsScreen(),
          ),
          GoRoute(
            path: 'team',
            name: 'team',
            builder: (context, state) => const TeamManagementScreen(),
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.farmOwnerDashboard,
        name: 'farm-owner-dashboard',
        builder: (context, state) => const FarmOwnerDashboardRedesigned(),
        routes: [
          GoRoute(
            path: 'digital-wallet',
            name: 'digital-wallet',
            builder: (context, state) => const DigitalWalletScreen(),
          ),
          GoRoute(
            path: 'wallet-actions',
            name: 'wallet-actions',
            builder: (context, state) => const WalletActionsScreen(),
          ),
          GoRoute(
            path: 'analytics',
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: 'reports',
            name: 'reports',
            builder: (context, state) => const farm_owner.ReportsScreen(),
          ),
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.caretakerDashboard,
        name: 'caretaker-dashboard',
        builder: (context, state) => const CaretakerDashboard(),
        routes: [
          GoRoute(
            path: 'record-entry',
            name: 'record-entry',
            builder: (context, state) => const RecordEntryScreen(),
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.technicianDashboard,
        name: 'technician-dashboard',
        builder: (context, state) => const TechnicianDashboard(),
        routes: [
          GoRoute(
            path: 'maintenance',
            name: 'maintenance-schedule',
            builder: (context, state) => const MaintenanceScheduleScreen(),
          ),
          GoRoute(
            path: 'sensor-management',
            name: 'sensor-management',
            builder: (context, state) => const SensorManagementScreen(),
          ),
        ],
      ),

      // Admin Feature Routes
      GoRoute(
        path: AppRoutes.userManagement,
        name: 'user-management',
        builder: (context, state) => const UsersScreen(),
      ),

      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const FarmSettingsScreen(),
      ),

      // Super Admin Feature Routes
      GoRoute(
        path: '/super-admin/users',
        name: 'super-admin-users',
        builder: (context, state) => const UserManagementScreen(),
      ),

      GoRoute(
        path: '/super-admin/farms',
        name: 'super-admin-farms',
        builder: (context, state) => const FarmManagementScreen(),
      ),

      GoRoute(
        path: '/super-admin/config',
        name: 'system-config',
        builder: (context, state) => const SystemConfigScreen(),
      ),

      GoRoute(
        path: '/super-admin/audit',
        name: 'audit-logs',
        builder: (context, state) => const AuditLogsScreen(),
      ),

      GoRoute(
        path: '/super-admin/backup',
        name: 'backup-restore',
        builder: (context, state) => const BackupRestoreScreen(),
      ),

      GoRoute(
        path: '/super-admin/sensors',
        name: 'super-admin-sensors',
        builder: (context, state) =>
            const ModernSensorsScreen(isSuperAdmin: true),
      ),

      // Alert Routes
      GoRoute(
        path: '/alerts',
        name: 'alerts',
        builder: (context, state) => const AlertManagementScreen(),
      ),

      // Control Routes
      GoRoute(
        path: '/controls',
        name: 'controls',
        builder: (context, state) => const SystemControlPanel(),
      ),

      // Common Routes (to be implemented)
      // TODO: Create ProfileScreen, FarmListScreen, SensorListScreen

      // Phase 3 Routes - Analytics, Reports, Search
      GoRoute(
        path: AppRoutes.analytics,
        name: 'analytics',
        builder: (context, state) => const AnalyticsDashboard(),
        routes: [
          GoRoute(
            path: 'sensor-history',
            name: 'sensor-history',
            builder: (context, state) => const SensorHistoryScreen(),
          ),
          GoRoute(
            path: 'alert-trends',
            name: 'alert-trends',
            builder: (context, state) => const AlertTrendsScreen(),
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.reports,
        name: 'reports',
        builder: (context, state) => const ReportsScreen(),
      ),

      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        builder: (context, state) => const GlobalSearchScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Navigation Helper Extension
extension NavigationHelper on BuildContext {
  /// Navigate to batch generation screen
  void goToBatchGeneration() {
    go('${AppRoutes.farmManagerDashboard}/batch-generation');
  }

  /// Navigate to inventory management screen
  void goToInventoryManagement() {
    go('${AppRoutes.farmManagerDashboard}/inventory');
  }

  /// Navigate to record entry screen
  void goToRecordEntry() {
    go('${AppRoutes.caretakerDashboard}/record-entry');
  }

  /// Navigate to maintenance schedule screen
  void goToMaintenanceSchedule() {
    go('${AppRoutes.technicianDashboard}/maintenance');
  }

  /// Navigate to analytics dashboard
  void goToAnalytics() {
    go(AppRoutes.analytics);
  }

  /// Navigate to reports screen
  void goToReports() {
    go(AppRoutes.reports);
  }

  /// Navigate to search screen
  void goToSearch() {
    go(AppRoutes.search);
  }

  /// Navigate to alerts screen
  void goToAlerts() {
    go('/alerts');
  }

  /// Navigate to controls screen
  void goToControls() {
    go('/controls');
  }

  /// Navigate to sensor history screen
  void goToSensorHistory() {
    go('${AppRoutes.analytics}/sensor-history');
  }

  /// Navigate to alert trends screen
  void goToAlertTrends() {
    go('${AppRoutes.analytics}/alert-trends');
  }

  /// Navigate to sensor management screen
  void goToSensorManagement() {
    go('${AppRoutes.technicianDashboard}/sensor-management');
  }

  /// Navigate to dashboard based on user role
  void goToDashboard(String role) {
    go(AppRoutes.getDashboardByRole(role));
  }

  /// Go back or to dashboard if no previous route
  void goBackOrDashboard(String role) {
    if (canPop()) {
      pop();
    } else {
      goToDashboard(role);
    }
  }
}
