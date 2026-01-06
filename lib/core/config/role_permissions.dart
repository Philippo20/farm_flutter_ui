/// Role-Based Permissions Configuration
/// Defines what each role can access and do in the system

enum Permission {
  // Farm Management
  viewFarms,
  editFarms,
  deleteFarms,
  assignFarms,
  
  // Inventory Management
  viewInventory,
  editInventory,
  requestInventory,
  confirmInventory,
  
  // Batch Management
  generateBatch,
  viewBatch,
  editBatch,
  triggerDelivery,
  
  // Financial
  viewAllFinancials,
  viewOwnFinancials,
  viewAssignedFinancials,
  viewInputTransactions,
  deductPayment,
  withdrawFunds,
  requestFunds,
  confirmTransactions,
  
  // Records & Monitoring
  takeRecords,
  viewRecords,
  editRecords,
  uploadImages,
  
  // Maintenance & Technical
  recordIssues,
  viewIssues,
  solveIssues,
  scheduleMaintenance,
  viewMaintenance,
  
  // Harvest & Fulfillment
  confirmHarvest,
  recordPackaging,
  inspectQuality,
  approveForSales,
  trackPackagingMaterials,
  
  // Sales
  manageSales,
  viewSales,
  manageOffTakers,
  recordDelivery,
  trackDeliveryStatus,
  viewSalesPerformance,
  
  // Reports & Analytics
  generateReports,
  viewAnalytics,
  exportReports,
  
  // Communication
  chat,
  sendNotifications,
  receiveNotifications,
  
  // User Management
  viewUsers,
  editUsers,
  deleteUsers,
  
  // System
  systemConfiguration,
  viewLogs,
  backupRestore,
}

class RolePermissions {
  /// Farm Manager Permissions
  static const farmManager = [
    // Inventory
    Permission.viewInventory,
    Permission.editInventory,
    Permission.confirmInventory,
    
    // Farm Monitoring
    Permission.viewFarms,
    Permission.editFarms,
    
    // Batch
    Permission.generateBatch,
    Permission.viewBatch,
    Permission.triggerDelivery,
    
    // Financial (assigned farms only)
    Permission.viewAssignedFinancials,
    Permission.deductPayment,
    Permission.requestFunds,
    
    // Records
    Permission.takeRecords,
    Permission.viewRecords,
    Permission.uploadImages,
    
    // Reports
    Permission.generateReports,
    
    // Communication
    Permission.receiveNotifications,
    Permission.sendNotifications,
  ];

  /// Farm Owner Permissions
  static const farmOwner = [
    // Farm Monitoring
    Permission.viewFarms,
    
    // Financial (full access to own farms)
    Permission.viewOwnFinancials,
    Permission.withdrawFunds,
    
    // Reports
    Permission.generateReports,
    Permission.viewAnalytics,
    Permission.exportReports,
    
    // Communication
    Permission.chat,
    Permission.receiveNotifications,
    
    // Records (view only)
    Permission.viewRecords,
    Permission.viewIssues,
  ];

  /// Caretaker Permissions
  static const caretaker = [
    // Farm Monitoring
    Permission.viewFarms,
    
    // Records
    Permission.takeRecords,
    Permission.viewRecords,
    Permission.uploadImages,
    Permission.confirmInventory,
    
    // Financial (limited - inputs only)
    Permission.viewInputTransactions,
    
    // Technical
    Permission.recordIssues,
    
    // Communication
    Permission.chat,
    Permission.receiveNotifications,
  ];

  /// Technician Permissions
  static const technician = [
    // Maintenance
    Permission.recordIssues,
    Permission.viewIssues,
    Permission.solveIssues,
    Permission.scheduleMaintenance,
    Permission.viewMaintenance,
    Permission.uploadImages,
    
    // Inventory (request only)
    Permission.requestInventory,
    
    // Communication
    Permission.receiveNotifications,
  ];

  /// Fulfillment Manager Permissions
  static const fulfillmentManager = [
    // Harvest
    Permission.confirmHarvest,
    Permission.viewBatch,
    
    // Packaging
    Permission.recordPackaging,
    Permission.trackPackagingMaterials,
    
    // Records
    Permission.viewRecords,
    Permission.uploadImages,
    
    // Reports
    Permission.generateReports,
    
    // Communication
    Permission.receiveNotifications,
    Permission.sendNotifications,
  ];

  /// Packaging Supervisor Permissions
  static const packagingSupervisor = [
    // Packaging
    Permission.recordPackaging,
    Permission.uploadImages,
    
    // Records
    Permission.viewRecords,
    
    // Communication
    Permission.receiveNotifications,
  ];

  /// Quality Assurance Permissions
  static const qualityAssurance = [
    // Quality
    Permission.inspectQuality,
    Permission.approveForSales,
    Permission.uploadImages,
    
    // Records
    Permission.viewRecords,
    
    // Reports
    Permission.generateReports,
    
    // Communication
    Permission.receiveNotifications,
    Permission.sendNotifications,
  ];

  /// Sales Manager Permissions
  static const salesManager = [
    // Sales
    Permission.manageSales,
    Permission.viewSales,
    Permission.manageOffTakers,
    Permission.viewSalesPerformance,
    
    // Batch
    Permission.viewBatch,
    
    // Financial
    Permission.viewAllFinancials,
    
    // Reports
    Permission.generateReports,
    
    // Communication
    Permission.receiveNotifications,
    Permission.sendNotifications,
  ];

  /// Sales Personnel Permissions
  static const salesPersonnel = [
    // Sales
    Permission.recordDelivery,
    Permission.trackDeliveryStatus,
    Permission.manageOffTakers,
    Permission.uploadImages,
    
    // Financial (own sales only)
    Permission.viewOwnFinancials,
    
    // Reports
    Permission.generateReports,
    
    // Communication
    Permission.receiveNotifications,
  ];

  /// Accountant Permissions
  static const accountant = [
    // Financial (full access)
    Permission.viewAllFinancials,
    Permission.confirmTransactions,
    
    // Reports
    Permission.generateReports,
    Permission.viewAnalytics,
    Permission.exportReports,
    
    // Communication
    Permission.receiveNotifications,
  ];

  /// Admin Permissions
  static const admin = [
    // Users
    Permission.viewUsers,
    Permission.editUsers,
    Permission.deleteUsers,
    
    // Farms
    Permission.viewFarms,
    Permission.editFarms,
    Permission.deleteFarms,
    Permission.assignFarms,
    
    // System
    Permission.systemConfiguration,
    Permission.viewLogs,
    
    // All other permissions
    ...farmManager,
    ...farmOwner,
  ];

  /// Super Admin Permissions (all permissions)
  static const superAdmin = Permission.values;

  /// Get permissions for a role
  static List<Permission> getPermissions(String role) {
    switch (role.toLowerCase()) {
      case 'farm_manager':
        return farmManager;
      case 'farm_owner':
        return farmOwner;
      case 'caretaker':
        return caretaker;
      case 'technician':
        return technician;
      case 'fulfillment_manager':
        return fulfillmentManager;
      case 'packaging_supervisor':
        return packagingSupervisor;
      case 'quality_assurance':
        return qualityAssurance;
      case 'sales_manager':
        return salesManager;
      case 'sales_personnel':
        return salesPersonnel;
      case 'accountant':
        return accountant;
      case 'admin':
        return admin;
      case 'super_admin':
        return superAdmin;
      default:
        return [];
    }
  }

  /// Check if role has permission
  static bool hasPermission(String role, Permission permission) {
    final permissions = getPermissions(role);
    return permissions.contains(permission);
  }

  /// Check if role has any of the permissions
  static bool hasAnyPermission(String role, List<Permission> permissions) {
    final rolePermissions = getPermissions(role);
    return permissions.any((p) => rolePermissions.contains(p));
  }

  /// Check if role has all permissions
  static bool hasAllPermissions(String role, List<Permission> permissions) {
    final rolePermissions = getPermissions(role);
    return permissions.every((p) => rolePermissions.contains(p));
  }
}

/// Dashboard Features Configuration
class DashboardFeatures {
  final String title;
  final List<DashboardSection> sections;

  const DashboardFeatures({
    required this.title,
    required this.sections,
  });
}

class DashboardSection {
  final String title;
  final String icon;
  final String route;
  final List<Permission> requiredPermissions;

  const DashboardSection({
    required this.title,
    required this.icon,
    required this.route,
    required this.requiredPermissions,
  });
}

/// Role-specific dashboard configurations
class RoleDashboards {
  /// Farm Manager Dashboard
  static const farmManager = DashboardFeatures(
    title: 'Farm Manager Dashboard',
    sections: [
      DashboardSection(
        title: 'Inventory Management',
        icon: 'inventory',
        route: '/farm-manager/inventory',
        requiredPermissions: [Permission.editInventory],
      ),
      DashboardSection(
        title: 'Farm Monitoring',
        icon: 'dashboard',
        route: '/farm-manager/monitoring',
        requiredPermissions: [Permission.viewFarms],
      ),
      DashboardSection(
        title: 'Batch Generation',
        icon: 'qr_code',
        route: '/farm-manager/batch-generation',
        requiredPermissions: [Permission.generateBatch],
      ),
      DashboardSection(
        title: 'Financial Progress',
        icon: 'account_balance',
        route: '/farm-manager/financials',
        requiredPermissions: [Permission.viewAssignedFinancials],
      ),
      DashboardSection(
        title: 'Harvest Delivery',
        icon: 'local_shipping',
        route: '/farm-manager/delivery',
        requiredPermissions: [Permission.triggerDelivery],
      ),
      DashboardSection(
        title: 'Reports',
        icon: 'assessment',
        route: '/farm-manager/reports',
        requiredPermissions: [Permission.generateReports],
      ),
      DashboardSection(
        title: 'Requests & Confirmations',
        icon: 'check_circle',
        route: '/farm-manager/requests',
        requiredPermissions: [Permission.confirmInventory],
      ),
    ],
  );

  /// Farm Owner Dashboard
  static const farmOwner = DashboardFeatures(
    title: 'Farm Owner Dashboard',
    sections: [
      DashboardSection(
        title: 'Farm Monitoring',
        icon: 'agriculture',
        route: '/owner/monitoring',
        requiredPermissions: [Permission.viewFarms],
      ),
      DashboardSection(
        title: 'Digital Wallet',
        icon: 'account_balance_wallet',
        route: '/owner/wallet',
        requiredPermissions: [Permission.viewOwnFinancials],
      ),
      DashboardSection(
        title: 'Caretaker Activities',
        icon: 'person',
        route: '/owner/caretaker-activities',
        requiredPermissions: [Permission.viewRecords],
      ),
      DashboardSection(
        title: 'Analytics',
        icon: 'trending_up',
        route: '/owner/analytics',
        requiredPermissions: [Permission.viewAnalytics],
      ),
      DashboardSection(
        title: 'Reports',
        icon: 'description',
        route: '/owner/reports',
        requiredPermissions: [Permission.generateReports],
      ),
      DashboardSection(
        title: 'Alerts',
        icon: 'notifications_active',
        route: '/owner/alerts',
        requiredPermissions: [Permission.receiveNotifications],
      ),
    ],
  );

  /// Caretaker Dashboard
  static const caretaker = DashboardFeatures(
    title: 'Caretaker Dashboard',
    sections: [
      DashboardSection(
        title: 'Farm Monitoring',
        icon: 'visibility',
        route: '/caretaker/monitoring',
        requiredPermissions: [Permission.viewFarms],
      ),
      DashboardSection(
        title: 'Record Entry',
        icon: 'edit_note',
        route: '/caretaker/record-entry',
        requiredPermissions: [Permission.takeRecords],
      ),
      DashboardSection(
        title: 'Log Dashboard',
        icon: 'event_note',
        route: '/caretaker/logs',
        requiredPermissions: [Permission.viewRecords],
      ),
      DashboardSection(
        title: 'Input Transactions',
        icon: 'receipt',
        route: '/caretaker/transactions',
        requiredPermissions: [Permission.viewInputTransactions],
      ),
      DashboardSection(
        title: 'Chat with Owner',
        icon: 'chat',
        route: '/caretaker/chat',
        requiredPermissions: [Permission.chat],
      ),
      DashboardSection(
        title: 'Raise Issues',
        icon: 'report_problem',
        route: '/caretaker/issues',
        requiredPermissions: [Permission.recordIssues],
      ),
      DashboardSection(
        title: 'Calendar',
        icon: 'calendar_today',
        route: '/caretaker/calendar',
        requiredPermissions: [Permission.receiveNotifications],
      ),
    ],
  );

  /// Technician Dashboard
  static const technician = DashboardFeatures(
    title: 'Technician Dashboard',
    sections: [
      DashboardSection(
        title: 'Issues & Solutions',
        icon: 'build',
        route: '/technician/issues',
        requiredPermissions: [Permission.solveIssues],
      ),
      DashboardSection(
        title: 'Maintenance Schedule',
        icon: 'schedule',
        route: '/technician/maintenance',
        requiredPermissions: [Permission.scheduleMaintenance],
      ),
      DashboardSection(
        title: 'Request Items',
        icon: 'shopping_cart',
        route: '/technician/requests',
        requiredPermissions: [Permission.requestInventory],
      ),
      DashboardSection(
        title: 'Asset Checklist',
        icon: 'checklist',
        route: '/technician/checklist',
        requiredPermissions: [Permission.viewMaintenance],
      ),
    ],
  );

  /// Get dashboard configuration for role
  static DashboardFeatures? getForRole(String role) {
    switch (role.toLowerCase()) {
      case 'farm_manager':
        return farmManager;
      case 'farm_owner':
        return farmOwner;
      case 'caretaker':
        return caretaker;
      case 'technician':
        return technician;
      default:
        return null;
    }
  }
}
