/// Application Routes
/// Centralized route definitions for the Farm Estate Management System
class AppRoutes {
  // Auth Routes
  static const String login = '/login';
  static const String register = '/register';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  
  // Dashboard Routes
  static const String home = '/';
  static const String superAdminDashboard = '/super-admin';
  static const String adminDashboard = '/admin';
  static const String farmManagerDashboard = '/farm-manager';
  static const String farmOwnerDashboard = '/farm-owner';
  static const String caretakerDashboard = '/caretaker';
  static const String technicianDashboard = '/technician';
  
  // Farm Manager Routes
  static const String batchGeneration = '/farm-manager/batch-generation';
  static const String inventoryManagement = '/farm-manager/inventory';
  static const String deliveryManagement = '/farm-manager/deliveries';
  static const String farmsManagement = '/farm-manager/farms';
  static const String teamManagement = '/farm-manager/team';
  static const String farmManagerSettings = '/farm-manager/settings';
  static const String batchList = '/farm-manager/batches';
  static const String batchDetails = '/farm-manager/batches/:id';
  
  // Farm Owner Routes
  static const String wallet = '/farm-owner/wallet';
  static const String transactions = '/farm-owner/transactions';
  static const String farmPerformance = '/farm-owner/performance';
  static const String walletActions = '/farm-owner/wallet-actions';
  
  // Caretaker Routes
  static const String recordEntry = '/caretaker/record-entry';
  static const String recordsList = '/caretaker/records';
  static const String recordDetails = '/caretaker/records/:id';
  static const String inputRequests = '/caretaker/input-requests';
  static const String tasksList = '/caretaker/tasks';
  
  // Technician Routes
  static const String maintenanceSchedule = '/technician/maintenance';
  static const String maintenanceDetails = '/technician/maintenance/:id';
  static const String issuesList = '/technician/issues';
  static const String issueDetails = '/technician/issues/:id';
  static const String equipmentList = '/technician/equipment';
  
  // Admin Routes
  static const String userManagement = '/admin/users';
  static const String farmManagement = '/admin/farms';
  static const String analytics = '/analytics';
  static const String settings = '/admin/settings';
  
  // Phase 3 Routes
  static const String reports = '/reports';
  static const String search = '/search';
  
  // Common Routes
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String help = '/help';
  static const String about = '/about';
  
  // Route Names (for named navigation)
  static const Map<String, String> routeNames = {
    login: 'Login',
    register: 'Register',
    home: 'Home',
    superAdminDashboard: 'Super Admin Dashboard',
    adminDashboard: 'Admin Dashboard',
    farmManagerDashboard: 'Farm Manager Dashboard',
    farmOwnerDashboard: 'Farm Owner Dashboard',
    caretakerDashboard: 'Caretaker Dashboard',
    technicianDashboard: 'Technician Dashboard',
    teamManagement: 'Team Management',
    batchGeneration: 'Batch Generation',
    inventoryManagement: 'Inventory Management',
    recordEntry: 'Record Entry',
    maintenanceSchedule: 'Maintenance Schedule',
    profile: 'Profile',
    notifications: 'Notifications',
  };
  
  /// Get route name by path
  static String getRouteName(String path) {
    return routeNames[path] ?? 'Unknown';
  }
  
  /// Check if route requires authentication
  static bool requiresAuth(String path) {
    return path != login && path != register && path != forgotPassword;
  }
  
  /// Get dashboard route by user role
  static String getDashboardByRole(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return superAdminDashboard;
      case 'admin':
        return adminDashboard;
      case 'farm_manager':
        return farmManagerDashboard;
      case 'farm_owner':
        return farmOwnerDashboard;
      case 'caretaker':
        return caretakerDashboard;
      case 'technician':
        return technicianDashboard;
      default:
        return home;
    }
  }
}
