import 'package:farmestates_ai_dashbaord/screens/farm_manager/batch_generation_screen.dart';
import 'package:farmestates_ai_dashbaord/screens/farm_manager/fund_request_screen.dart';
import 'package:farmestates_ai_dashbaord/screens/farm_manager/inventory_management_screen.dart';
import 'package:farmestates_ai_dashbaord/screens/farm_manager/reports_screen.dart';
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
import 'screens/farm_owner/digital_wallet_screen.dart';
import 'screens/farm_owner/analytics_screen.dart';
import 'screens/farm_owner/withdraw_funds_screen.dart';
import 'screens/farm_owner/reports_screen.dart' as farm_owner;
import 'screens/farm_owner/settings_screen.dart';
import 'screens/technician/technician_dashboard_new.dart';
import 'screens/technician/technician_dashboard_redesigned.dart';
import 'screens/fulfillment/fulfillment_manager_dashboard.dart';
import 'screens/fulfillment/fulfillment_manager_dashboard_redesigned.dart';
import 'screens/packaging/packaging_supervisor_dashboard.dart';
import 'screens/packaging/packaging_supervisor_dashboard_redesigned.dart';
import 'screens/quality/quality_assurance_dashboard.dart';
import 'screens/quality/quality_assurance_dashboard_redesigned.dart';
import 'screens/sales/sales_manager_dashboard.dart';
import 'screens/sales/sales_manager_dashboard_redesigned.dart';
import 'screens/sales/sales_personnel_dashboard.dart';
import 'screens/sales/sales_personnel_dashboard_redesigned.dart';
import 'screens/accountant/accountant_dashboard.dart';
import 'screens/accountant/accountant_dashboard_redesigned.dart';
import 'screens/superadmin/superadmin_dashboard.dart';
import 'screens/superadmin/user_management_screen.dart';
import 'screens/superadmin/farm_management_screen.dart';
import 'screens/superadmin/plant_management_screen.dart';
import 'screens/superadmin/packaging_screen.dart';
import 'screens/superadmin/pricing_management_screen.dart';
import 'screens/superadmin/audit_logs_screen.dart';
import 'screens/superadmin/system_config_screen.dart';
import 'screens/superadmin/backup_restore_screen.dart';

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
        '/superadmin/audit': (context) => const AuditLogsScreen(),
        '/superadmin/config': (context) => const SystemConfigScreen(),
        '/superadmin/backup': (context) => const BackupRestoreScreen(),

        // Admin
        '/dashboard': (context) => const RedesignedAdminDashboard(),
        '/users': (context) => const ModernUsersScreen(),
        '/farms': (context) => const ModernFarmsScreen(),
        '/sensors': (context) => const ModernSensorsScreen(),
        '/analytics': (context) => const ModernAnalyticsScreen(),
        '/settings': (context) => const ModernSettingsScreen(),

        // Farm Manager (NEW - REDESIGNED)
        '/farm-manager': (context) => const FarmManagerDashboardRedesigned(),
        '/farm-manager/inventory': (context) => const InventoryManagementScreen(),
        '/farm-manager/batch-generation': (context) => const BatchGenerationScreen(),
        '/farm-manager/fund-request': (context) => const FundRequestScreen(),
        '/farm-manager/reports': (context) => const ReportsScreen(),
        // Farm Owner (NEW - REDESIGNED)
        '/farm-owner': (context) => const FarmOwnerDashboardRedesigned(),
        '/farm-owner/digital-wallet': (context) => const DigitalWalletScreen(),
        '/farm-owner/analytics': (context) => const AnalyticsScreen(),
        '/farm-owner/withdraw-funds': (context) => const WithdrawFundsScreen(),
        '/farm-owner/reports': (context) => const farm_owner.ReportsScreen(),
        '/farm-owner/settings': (context) => const SettingsScreen(),
        '/owner_dashboard': (context) => const FarmOwnerDashboardRedesigned(),
        '/owner_farm': (context) => ownerFarmsScreen(),
        '/owner_settings': (context) => OwnerFarmsSettingsScreen(),

        // Caretaker (NEW - REDESIGNED)
        '/caretaker_dashboard': (context) => const CaretakerDashboardRedesigned(),
        '/record-entry': (context) => const RecordEntryScreen(),
        '/input-confirmation': (context) => const InputConfirmationScreen(),
        '/chat': (context) => const ChatScreen(),
        '/calendar': (context) => const CalendarScreen(),
        '/farm': (context) => CaretakerFarmScreen(),
        '/caretaker_settings': (context) => CareTakerSettingsScreen(),

        // Technician (NEW - REDESIGNED)
        '/technician_dashboard': (context) => const TechnicianDashboardRedesigned(),

        // Fulfillment Chain (PHASE 3 - REDESIGNED)
        '/fulfillment_dashboard': (context) => const FulfillmentManagerDashboardRedesigned(),
        '/packaging_dashboard': (context) => const PackagingSupervisorDashboardRedesigned(),
        '/quality_dashboard': (context) => const QualityAssuranceDashboardRedesigned(),

        // Sales & Finance (PHASE 4 - REDESIGNED)
        '/sales_dashboard': (context) => const SalesManagerDashboardRedesigned(),
        '/sales_personnel_dashboard': (context) => const SalesPersonnelDashboardRedesigned(),
        '/accountant_dashboard': (context) => const AccountantDashboardRedesigned(),
        /*
        '/alerts': (context) => AlertsScreen(),
        '/analytics': (context) => AnalyticsScreen(),
       
        */
      },
    );
  }
}
