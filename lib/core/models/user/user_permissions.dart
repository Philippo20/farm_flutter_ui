import 'user_role.dart';

/// Permission definitions for the Farm Estate Management System
/// Each permission represents a specific action or access level
class Permission {
  // Farm Operations
  static const String viewFarms = 'view_farms';
  static const String manageFarms = 'manage_farms';
  static const String generateBatch = 'generate_batch';
  static const String triggerDelivery = 'trigger_delivery';
  static const String monitorFarms = 'monitor_farms';
  
  // Inventory Management
  static const String viewInventory = 'view_inventory';
  static const String manageInventory = 'manage_inventory';
  static const String requestInputs = 'request_inputs';
  static const String confirmInputs = 'confirm_inputs';
  static const String supplyInputs = 'supply_inputs';
  
  // Financial Operations
  static const String viewFinancials = 'view_financials';
  static const String viewFullFinancials = 'view_full_financials';
  static const String manageTransactions = 'manage_transactions';
  static const String approvePayments = 'approve_payments';
  static const String withdrawFunds = 'withdraw_funds';
  static const String deductPayments = 'deduct_payments';
  static const String requestBudget = 'request_budget';
  static const String viewWallet = 'view_wallet';
  
  // Records & Reporting
  static const String createRecords = 'create_records';
  static const String viewRecords = 'view_records';
  static const String viewReports = 'view_reports';
  static const String generateReports = 'generate_reports';
  static const String exportReports = 'export_reports';
  
  // Harvest & Fulfillment
  static const String confirmHarvest = 'confirm_harvest';
  static const String receiveHarvest = 'receive_harvest';
  static const String packageProducts = 'package_products';
  static const String recordPackaging = 'record_packaging';
  static const String trackPackagingMaterials = 'track_packaging_materials';
  
  // Quality Control
  static const String qualityInspection = 'quality_inspection';
  static const String approveQuality = 'approve_quality';
  static const String rejectBatch = 'reject_batch';
  static const String flagIssues = 'flag_issues';
  
  // Sales Operations
  static const String manageSales = 'manage_sales';
  static const String manageOfftakers = 'manage_offtakers';
  static const String addOfftakers = 'add_offtakers';
  static const String trackDelivery = 'track_delivery';
  static const String recordDelivery = 'record_delivery';
  static const String confirmDelivery = 'confirm_delivery';
  static const String viewSalesPerformance = 'view_sales_performance';
  
  // Maintenance & Technical
  static const String raiseTechnicalIssue = 'raise_technical_issue';
  static const String resolveTechnicalIssue = 'resolve_technical_issue';
  static const String scheduleMaintenace = 'schedule_maintenance';
  static const String recordMaintenance = 'record_maintenance';
  static const String viewMaintenanceHistory = 'view_maintenance_history';
  
  // Communication & Collaboration
  static const String chat = 'chat';
  static const String notifications = 'notifications';
  static const String requestApproval = 'request_approval';
  static const String grantApproval = 'grant_approval';
  static const String requestInformation = 'request_information';
  
  // User Management (Admin only)
  static const String manageUsers = 'manage_users';
  static const String assignFarms = 'assign_farms';
  static const String viewAllUsers = 'view_all_users';
  
  // System Configuration (Super Admin only)
  static const String systemConfig = 'system_config';
  static const String viewAuditLogs = 'view_audit_logs';
  static const String manageSystemSettings = 'manage_system_settings';
}

/// Role-based permission configuration
/// Defines what each role can and cannot do
class RolePermissions {
  static final Map<UserRole, List<String>> _permissions = {
    // Super Admin - Full system access
    UserRole.superAdmin: [
      Permission.viewFarms,
      Permission.manageFarms,
      Permission.viewInventory,
      Permission.manageInventory,
      Permission.viewFullFinancials,
      Permission.manageTransactions,
      Permission.approvePayments,
      Permission.viewReports,
      Permission.generateReports,
      Permission.exportReports,
      Permission.manageUsers,
      Permission.assignFarms,
      Permission.viewAllUsers,
      Permission.systemConfig,
      Permission.viewAuditLogs,
      Permission.manageSystemSettings,
    ],
    
    // Farm Manager - Farm operations, inventory, batch management
    UserRole.farmManager: [
      Permission.viewFarms,
      Permission.manageFarms,
      Permission.monitorFarms,
      Permission.viewInventory,
      Permission.manageInventory,
      Permission.supplyInputs,
      Permission.generateBatch,
      Permission.triggerDelivery,
      Permission.viewFinancials,
      Permission.deductPayments,
      Permission.requestBudget,
      Permission.createRecords,
      Permission.viewRecords,
      Permission.viewReports,
      Permission.generateReports,
      Permission.exportReports,
      Permission.confirmHarvest,
      Permission.requestApproval,
      Permission.grantApproval,
      Permission.notifications,
      Permission.assignFarms,
    ],
    
    // Farm Owner - Monitoring and financial access
    UserRole.farmOwner: [
      Permission.viewFarms,
      Permission.monitorFarms,
      Permission.viewFinancials,
      Permission.viewWallet,
      Permission.withdrawFunds,
      Permission.viewRecords,
      Permission.viewReports,
      Permission.generateReports,
      Permission.exportReports,
      Permission.chat,
      Permission.notifications,
      Permission.requestInformation,
      Permission.requestApproval,
    ],
    
    // Caretaker - Daily operations and record keeping
    UserRole.caretaker: [
      Permission.viewFarms,
      Permission.monitorFarms,
      Permission.createRecords,
      Permission.viewRecords,
      Permission.confirmInputs,
      Permission.viewFinancials, // Limited to inputs received
      Permission.chat,
      Permission.notifications,
      Permission.raiseTechnicalIssue,
      Permission.requestInputs,
      Permission.requestInformation,
    ],
    
    // Technician - Maintenance and technical support
    UserRole.technician: [
      Permission.viewFarms,
      Permission.resolveTechnicalIssue,
      Permission.scheduleMaintenace,
      Permission.recordMaintenance,
      Permission.viewMaintenanceHistory,
      Permission.createRecords,
      Permission.viewRecords,
      Permission.requestInputs,
      Permission.requestApproval,
      Permission.notifications,
    ],
    
    // Fulfillment Manager - Harvest and packaging oversight
    UserRole.fulfillmentManager: [
      Permission.confirmHarvest,
      Permission.receiveHarvest,
      Permission.packageProducts,
      Permission.viewInventory,
      Permission.manageInventory,
      Permission.trackPackagingMaterials,
      Permission.createRecords,
      Permission.viewRecords,
      Permission.viewReports,
      Permission.generateReports,
      Permission.exportReports,
      Permission.qualityInspection,
      Permission.grantApproval,
      Permission.notifications,
    ],
    
    // Packaging Supervisor - Packaging operations
    UserRole.packagingSupervisor: [
      Permission.packageProducts,
      Permission.recordPackaging,
      Permission.createRecords,
      Permission.viewRecords,
      Permission.viewInventory,
      Permission.trackPackagingMaterials,
      Permission.notifications,
    ],
    
    // Quality Assurance - Quality control and inspections
    UserRole.qualityAssurance: [
      Permission.qualityInspection,
      Permission.approveQuality,
      Permission.rejectBatch,
      Permission.flagIssues,
      Permission.createRecords,
      Permission.viewRecords,
      Permission.viewReports,
      Permission.generateReports,
      Permission.exportReports,
      Permission.grantApproval,
      Permission.notifications,
    ],
    
    // Sales Manager - Sales operations and offtaker management
    UserRole.salesManager: [
      Permission.manageSales,
      Permission.manageOfftakers,
      Permission.confirmDelivery,
      Permission.viewFinancials,
      Permission.viewSalesPerformance,
      Permission.createRecords,
      Permission.viewRecords,
      Permission.viewReports,
      Permission.generateReports,
      Permission.exportReports,
      Permission.grantApproval,
      Permission.notifications,
    ],
    
    // Sales Personnel - Deliveries and offtaker relations
    UserRole.salesPersonnel: [
      Permission.trackDelivery,
      Permission.recordDelivery,
      Permission.addOfftakers,
      Permission.createRecords,
      Permission.viewRecords,
      Permission.viewReports,
      Permission.generateReports,
      Permission.requestApproval,
      Permission.notifications,
    ],
    
    // Accountant - Financial operations and reconciliation
    UserRole.accountant: [
      Permission.viewFullFinancials,
      Permission.manageTransactions,
      Permission.approvePayments,
      Permission.viewRecords,
      Permission.viewReports,
      Permission.generateReports,
      Permission.exportReports,
      Permission.grantApproval,
      Permission.requestApproval,
      Permission.notifications,
    ],
  };

  /// Check if a role has a specific permission
  static bool hasPermission(UserRole role, String permission) {
    return _permissions[role]?.contains(permission) ?? false;
  }

  /// Get all permissions for a role
  static List<String> getPermissions(UserRole role) {
    return _permissions[role] ?? [];
  }

  /// Check if a role has any of the given permissions
  static bool hasAnyPermission(UserRole role, List<String> permissions) {
    final rolePermissions = _permissions[role] ?? [];
    return permissions.any((permission) => rolePermissions.contains(permission));
  }

  /// Check if a role has all of the given permissions
  static bool hasAllPermissions(UserRole role, List<String> permissions) {
    final rolePermissions = _permissions[role] ?? [];
    return permissions.every((permission) => rolePermissions.contains(permission));
  }

  /// Get permission count for a role
  static int getPermissionCount(UserRole role) {
    return _permissions[role]?.length ?? 0;
  }

  /// Get roles that have a specific permission
  static List<UserRole> getRolesWithPermission(String permission) {
    return _permissions.entries
        .where((entry) => entry.value.contains(permission))
        .map((entry) => entry.key)
        .toList();
  }
}
