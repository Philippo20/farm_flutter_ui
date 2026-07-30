import 'package:farmestates_ai_dashbaord/screens/farm_manager/batch_generation_screen.dart';
import 'package:farmestates_ai_dashbaord/screens/farm_manager/delivery_management_screen.dart';
import 'package:farmestates_ai_dashbaord/screens/farm_manager/farms_screen.dart';
import 'package:farmestates_ai_dashbaord/screens/farm_manager/farm_manager_settings_screen.dart';
import 'package:farmestates_ai_dashbaord/screens/farm_manager/fund_request_screen.dart';
import 'package:farmestates_ai_dashbaord/screens/farm_manager/inventory_management_screen.dart';
import 'package:farmestates_ai_dashbaord/screens/farm_manager/reports_screen.dart';
import 'package:farmestates_ai_dashbaord/screens/farm_manager/team_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'screens/admin/redesigned_admin_dashboard.dart';
import 'screens/admin/modern_users_screen.dart';
import 'screens/admin/modern_farms_screen.dart';
import 'screens/admin/modern_sensors_screen.dart';
import 'screens/admin/modern_analytics_screen.dart';
import 'screens/admin/modern_settings_screen.dart';
import 'screens/admin/admin_inventory_overview_screen.dart';
import 'screens/admin/admin_delivery_control_screen.dart';
import 'screens/auth/modern_login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/owner/farm_screen.dart';
import 'screens/owner/farm_settings_screen.dart';
import 'screens/caretaker/caretaker_farm_screen.dart';
import 'screens/caretaker/care_taker_settings.dart';
import 'screens/caretaker/caretaker_dashboard_new.dart';
import 'screens/caretaker/caretaker_dashboard_redesigned.dart';
import 'screens/caretaker/record_entry_screen.dart';
import 'screens/caretaker/input_confirmation_screen.dart';
import 'screens/caretaker/chat_screen.dart';
import 'screens/caretaker/calendar_screen.dart';
import 'screens/farm_manager/farm_manager_dashboard_redesigned.dart';
import 'screens/farm_owner/farm_owner_dashboard_new.dart';
import 'screens/farm_owner/farm_owner_dashboard_redesigned.dart';
import 'screens/farm_owner/farm_overview_screen.dart';
import 'screens/farm_owner/digital_wallet_screen.dart';
import 'screens/farm_owner/wallet_actions_screen.dart';
import 'screens/farm_owner/analytics_screen.dart';
import 'screens/farm_owner/reports_screen.dart' as farm_owner;
import 'screens/farm_owner/settings_screen.dart';
import 'screens/technician/technician_dashboard_redesigned.dart';
import 'screens/technician/sensor_management_screen.dart';
import 'screens/technician/maintenance_schedule_screen.dart';
import 'screens/technician/repair_history_screen.dart';
import 'screens/technician/technician_settings_screen.dart';
import 'screens/fulfillment/fulfillment_manager_dashboard.dart';
import 'screens/fulfillment/fulfillment_manager_dashboard_redesigned.dart';
import 'screens/fulfillment/fulfillment_confirm_harvest_screen.dart';
import 'screens/fulfillment/fulfillment_packaging_screen.dart';
import 'screens/fulfillment/fulfillment_yield_calculator_screen.dart';
import 'screens/fulfillment/fulfillment_materials_screen.dart';
import 'screens/fulfillment/fulfillment_reports_screen.dart';
import 'screens/fulfillment/fulfillment_settings_screen.dart';
import 'screens/packaging/packaging_supervisor_dashboard.dart';
import 'screens/packaging/packaging_supervisor_dashboard_redesigned.dart';
import 'screens/packaging/package_recording_screen.dart';
import 'screens/quality/quality_assurance_dashboard.dart';
import 'screens/quality/quality_assurance_dashboard_redesigned.dart';
import 'screens/quality/quality_assurance_nav_screens.dart';
import 'screens/sales/sales_manager_dashboard.dart';
import 'screens/sales/sales_manager_dashboard_redesigned.dart';
import 'screens/sales/sales_manager_nav_screens.dart';
import 'screens/sales/sales_personnel_dashboard.dart';
import 'screens/sales/sales_personnel_dashboard_redesigned.dart';
import 'screens/sales/sales_personnel_nav_screens.dart';
import 'screens/accountant/accountant_dashboard.dart';
import 'screens/accountant/accountant_dashboard_redesigned.dart';
import 'screens/accountant/accountant_nav_screens.dart';
import 'screens/superadmin/superadmin_dashboard.dart';
import 'screens/superadmin/user_management_screen.dart';
import 'screens/superadmin/farm_management_screen.dart';
import 'screens/superadmin/plant_management_screen.dart';
import 'screens/superadmin/packaging_screen.dart';
import 'screens/superadmin/pricing_management_screen.dart';
import 'screens/superadmin/audit_logs_screen.dart';
import 'screens/superadmin/system_config_screen.dart';
import 'screens/superadmin/backup_restore_screen.dart';
import 'screens/superadmin/superadmin_inventory_overview_screen.dart';
import 'screens/superadmin/superadmin_delivery_control_screen.dart';
import 'screens/shared/crop_varieties_screen.dart';

/// Main entry point for Farm Estates ADOM application
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded successfully');
  } catch (e) {
    print('⚠️ Warning: Could not load .env file: $e');
    print('   The app will use default/fallback values');
  }

  // Run app with Riverpod state management
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Room Dashboard',
      debugShowCheckedModeBanner: false,
      //home: AdminDashboardScreen(),
      initialRoute: '/login',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routes: {
        // Auth
        '/login': (context) => const ModernLoginScreen(),
        '/signup': (context) => const SignupScreen(),

        // Super Admin
        '/superadmin_dashboard': (context) => const SuperAdminDashboard(),
        '/superadmin/users': (context) => const UserManagementScreen(),
        '/superadmin/farms': (context) => const FarmManagementScreen(),
        '/superadmin/plants': (context) => const PlantManagementScreen(),
        '/superadmin/packaging': (context) => const PackagingScreen(),
        '/superadmin/pricing': (context) => const PricingManagementScreen(),
        '/superadmin/sensors': (context) =>
            const ModernSensorsScreen(isSuperAdmin: true),
        '/superadmin/audit': (context) => const AuditLogsScreen(),
        '/superadmin/config': (context) => const SystemConfigScreen(),
        '/superadmin/backup': (context) => const BackupRestoreScreen(),
        '/superadmin/inventory': (context) =>
            const SuperAdminInventoryOverviewScreen(),
        '/superadmin/deliveries': (context) =>
            const SuperAdminDeliveryControlScreen(),
        '/superadmin/crop-varieties': (context) =>
            const CropVarietiesScreen(isSuperAdmin: true),
        '/superadmin/analytics': (context) =>
            const ModernAnalyticsScreen(isSuperAdmin: true),

        // Admin
        '/dashboard': (context) => const RedesignedAdminDashboard(),
        '/users': (context) => const ModernUsersScreen(),
        '/farms': (context) => const ModernFarmsScreen(),
        '/sensors': (context) => const ModernSensorsScreen(),
        '/analytics': (context) => const ModernAnalyticsScreen(),
        '/settings': (context) => const ModernSettingsScreen(),
        '/inventory-admin': (context) => const AdminInventoryOverviewScreen(),
        '/deliveries-admin': (context) => const AdminDeliveryControlScreen(),
        '/crop-varieties': (context) =>
            const CropVarietiesScreen(isSuperAdmin: false),

        // Farm Manager (NEW - REDESIGNED)
        '/farm-manager': (context) => const FarmManagerDashboardRedesigned(),
        '/farm-manager/inventory': (context) =>
            const InventoryManagementScreen(),
        '/farm-manager/batch-generation': (context) =>
            const BatchGenerationScreen(),
        '/farm-manager/fund-request': (context) => const FundRequestScreen(),
        '/farm-manager/deliveries': (context) =>
            const DeliveryManagementScreen(),
        '/farm-manager/farms': (context) => const FarmsScreen(),
        '/farm-manager/settings': (context) =>
            const FarmManagerSettingsScreen(),
        '/farm-manager/reports': (context) => const ReportsScreen(),
        '/farm-manager/team': (context) => const TeamManagementScreen(),
        '/farm-manager/sensors': (context) =>
            const ModernSensorsScreen(isFarmManager: true),
        // Farm Owner (NEW - REDESIGNED)
        '/farm-owner': (context) => const FarmOwnerDashboardRedesigned(),
        '/farm-owner/farm': (context) => const FarmOverviewScreen(),
        '/farm-owner/digital-wallet': (context) => const DigitalWalletScreen(),
        '/farm-owner/wallet-actions': (context) => const WalletActionsScreen(),
        '/farm-owner/analytics': (context) => const AnalyticsScreen(),
        '/farm-owner/reports': (context) => const farm_owner.ReportsScreen(),
        '/farm-owner/settings': (context) => const SettingsScreen(),
        '/owner_dashboard': (context) => const FarmOwnerDashboardRedesigned(),
        '/owner_farm': (context) => ownerFarmsScreen(),
        '/owner_settings': (context) => OwnerFarmsSettingsScreen(),

        // Caretaker (NEW - REDESIGNED)
        '/caretaker_dashboard': (context) =>
            const CaretakerDashboardRedesigned(),
        '/record-entry': (context) => const RecordEntryScreen(),
        '/input-confirmation': (context) => const InputConfirmationScreen(),
        '/chat': (context) => const ChatScreen(),
        '/calendar': (context) => const CalendarScreen(),
        '/farm': (context) => CaretakerFarmScreen(),
        '/caretaker_settings': (context) => CareTakerSettingsScreen(),

        // Technician (NEW - REDESIGNED)
        '/technician_dashboard': (context) =>
            const TechnicianDashboardRedesigned(),
        '/technician-dashboard': (context) =>
            const TechnicianDashboardRedesigned(),
        '/sensor-management': (context) => const SensorManagementScreen(),
        '/maintenance-schedule': (context) => const MaintenanceScheduleScreen(),
        '/maintenance': (context) => const MaintenanceScheduleScreen(),
        '/repair-history': (context) => const RepairHistoryScreen(),
        '/technician-settings': (context) => const TechnicianSettingsScreen(),

        // Fulfillment Chain (PHASE 3 - REDESIGNED)
        '/fulfillment-manager-dashboard': (context) =>
            const FulfillmentManagerDashboardRedesigned(),
        '/fulfillment_dashboard': (context) =>
            const FulfillmentManagerDashboardRedesigned(),
        '/fulfillment-confirm': (context) =>
            const FulfillmentConfirmHarvestScreen(),
        '/confirm-harvest': (context) =>
            const FulfillmentConfirmHarvestScreen(),
        '/fulfillment-packaging': (context) =>
            const FulfillmentPackagingScreen(),
        '/coordinate-packaging': (context) =>
            const FulfillmentPackagingScreen(),
        '/fulfillment-yield': (context) =>
            const FulfillmentYieldCalculatorScreen(),
        '/yield-calculator': (context) =>
            const FulfillmentYieldCalculatorScreen(),
        '/fulfillment-materials': (context) =>
            const FulfillmentMaterialsScreen(),
        '/materials': (context) => const FulfillmentMaterialsScreen(),
        '/fulfillment-reports': (context) => const FulfillmentReportsScreen(),
        '/fulfillment-settings': (context) => const FulfillmentSettingsScreen(),
        '/packaging_dashboard': (context) =>
            const PackagingSupervisorDashboardRedesigned(),
        '/packaging-supervisor-dashboard': (context) =>
            const PackagingSupervisorDashboardRedesigned(),
        '/package-recording': (context) => const PackageRecordingScreen(),
        '/record-package': (context) => const PackageRecordingScreen(),
        '/package-record': (context) => const PackageRecordingScreen(),
        '/waste-tracking': (context) => const WasteTrackingScreen(),
        '/track-waste': (context) => const WasteTrackingScreen(),
        '/progress': (context) => const PackagingProgressScreen(),
        '/packaging-reports': (context) => const PackagingReportsScreen(),
        '/packaging-settings': (context) =>
            const PackagingSupervisorSettingsScreen(),
        '/quality_dashboard': (context) =>
            const QualityAssuranceDashboardRedesigned(),
        '/quality-assurance-dashboard': (context) =>
            const QualityAssuranceDashboardRedesigned(),
        '/quality-inspection': (context) => const QualityInspectionScreen(),
        '/inspection': (context) => const QualityInspectionScreen(),
        '/inspect-items': (context) => const QualityInspectionScreen(),
        '/quality-approve': (context) => const QualityApproveScreen(),
        '/approve': (context) => const QualityApproveScreen(),
        '/approve-items': (context) => const QualityApproveScreen(),
        '/approve-sales': (context) => const QualityApproveScreen(),
        '/quality-reject': (context) => const QualityRejectScreen(),
        '/reject': (context) => const QualityRejectScreen(),
        '/reject-items': (context) => const QualityRejectScreen(),
        '/reject-batch': (context) => const QualityRejectScreen(),
        '/quality-reports': (context) => const QualityReportsScreen(),
        '/quality-settings': (context) => const QualitySettingsScreen(),

        // Sales & Finance (PHASE 4 - REDESIGNED)
        '/sales_dashboard': (context) =>
            const SalesManagerDashboardRedesigned(),
        '/sales-manager-dashboard': (context) =>
            const SalesManagerDashboardRedesigned(),
        '/sales-off-takers': (context) => const SalesOffTakersScreen(),
        '/off-takers': (context) => const SalesOffTakersScreen(),
        '/offtaker-management': (context) => const SalesOffTakersScreen(),
        '/sales-performance': (context) => const SalesPerformanceScreen(),
        '/performance': (context) => const SalesPerformanceScreen(),
        '/sales-deliveries': (context) => const SalesDeliveriesScreen(),
        '/deliveries': (context) => const SalesDeliveriesScreen(),
        '/sales-financial': (context) => const SalesFinancialScreen(),
        '/financial': (context) => const SalesFinancialScreen(),
        '/sales-reports': (context) => const SalesReportsScreen(),
        '/sales-settings': (context) => const SalesManagerSettingsScreen(),
        '/sales_personnel_dashboard': (context) =>
            const SalesPersonnelDashboardRedesigned(),
        '/sales-personnel-dashboard': (context) =>
            const SalesPersonnelDashboardRedesigned(),
        '/sales-personnel-record-delivery': (context) =>
            const SalesPersonnelRecordDeliveryScreen(),
        '/record-delivery': (context) =>
            const SalesPersonnelRecordDeliveryScreen(),
        '/sales-personnel/record-delivery': (context) =>
            const SalesPersonnelRecordDeliveryScreen(),
        '/sales-personnel/record': (context) =>
            const SalesPersonnelRecordDeliveryScreen(),
        '/sales-personnel-delivery-status': (context) =>
            const SalesPersonnelRecordDeliveryScreen(),
        '/sales-personnel/status': (context) =>
            const SalesPersonnelRecordDeliveryScreen(),
        '/sales-personnel-pipeline': (context) =>
            const SalesPersonnelPipelineScreen(),
        '/sales-personnel/pipeline': (context) =>
            const SalesPersonnelPipelineScreen(),
        '/sales-personnel-sales': (context) =>
            const SalesPersonnelMySalesScreen(),
        '/my-sales': (context) => const SalesPersonnelMySalesScreen(),
        '/sales-personnel-expenses': (context) =>
            const SalesPersonnelExpensesScreen(),
        '/sales-personnel/expenses': (context) =>
            const SalesPersonnelExpensesScreen(),
        '/sales-personnel-reports': (context) =>
            const SalesPersonnelReportsScreen(),
        '/sales-personnel/reports': (context) =>
            const SalesPersonnelReportsScreen(),
        '/sales-personnel-settings': (context) =>
            const SalesPersonnelSettingsScreen(),
        '/sales-personnel/sync': (context) =>
            const SalesPersonnelExpensesScreen(),
        '/accountant_dashboard': (context) =>
            const AccountantDashboardRedesigned(),
        '/accountant-dashboard': (context) =>
            const AccountantDashboardRedesigned(),
        '/accountant-transactions': (context) =>
            const AccountantTransactionsScreen(),
        '/transactions': (context) => const AccountantTransactionsScreen(),
        '/accountant/transactions': (context) =>
            const AccountantTransactionsScreen(),
        '/accountant/confirm': (context) =>
            const AccountantTransactionsScreen(),
        '/accountant-reconciliation': (context) =>
            const AccountantReconciliationScreen(),
        '/reconciliation': (context) => const AccountantReconciliationScreen(),
        '/accountant/reconcile': (context) =>
            const AccountantReconciliationScreen(),
        '/accountant-approvals': (context) => const AccountantApprovalsScreen(),
        '/approvals': (context) => const AccountantApprovalsScreen(),
        '/accountant/approvals': (context) => const AccountantApprovalsScreen(),
        '/accountant-reports': (context) => const AccountantReportsScreen(),
        '/accountant/reports': (context) => const AccountantReportsScreen(),
        '/accountant/filters': (context) => const AccountantReportsScreen(),
        '/accountant/export': (context) => const AccountantReportsScreen(),
        '/accountant-settings': (context) => const AccountantSettingsScreen(),
        '/accountant/expenses': (context) =>
            const AccountantTransactionsScreen(),
        /*
        '/alerts': (context) => AlertsScreen(),
        '/analytics': (context) => AnalyticsScreen(),
       
        */
      },
    );
  }
}
