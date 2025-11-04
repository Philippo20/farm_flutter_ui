/// User Role Definitions for Farm Estate Management System
/// Each role has distinct responsibilities and access levels

enum UserRole {
  /// Tier 1: System Control
  superAdmin('Super Admin', 'SUPER_ADMIN', 1),
  
  /// Tier 2: Operations Management
  farmManager('Farm Manager', 'FARM_MANAGER', 2),
  fulfillmentManager('Fulfillment Manager', 'FULFILLMENT_MANAGER', 2),
  salesManager('Sales Manager', 'SALES_MANAGER', 2),
  accountant('Accountant', 'ACCOUNTANT', 2),
  
  /// Tier 3: Farm Operations
  farmOwner('Farm Owner', 'FARM_OWNER', 3),
  caretaker('Caretaker', 'CARETAKER', 3),
  technician('Technician', 'TECHNICIAN', 3),
  
  /// Tier 4: Fulfillment & Sales
  packagingSupervisor('Packaging Supervisor', 'PACKAGING_SUPERVISOR', 4),
  qualityAssurance('Quality Assurance Officer', 'QUALITY_ASSURANCE', 4),
  salesPersonnel('Sales Personnel', 'SALES_PERSONNEL', 4);

  final String displayName;
  final String code;
  final int tier;

  const UserRole(this.displayName, this.code, this.tier);

  /// Get role from string code
  static UserRole? fromCode(String code) {
    try {
      return UserRole.values.firstWhere((role) => role.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Get role from display name
  static UserRole? fromDisplayName(String name) {
    try {
      return UserRole.values.firstWhere((role) => role.displayName == name);
    } catch (e) {
      return null;
    }
  }

  /// Check if role is management level (Tier 2)
  bool get isManagement => tier == 2;

  /// Check if role is operational level (Tier 3)
  bool get isOperational => tier == 3;

  /// Check if role is support level (Tier 4)
  bool get isSupport => tier == 4;

  /// Check if role is system admin
  bool get isSystemAdmin => this == UserRole.superAdmin;

  /// Get role description
  String get description {
    switch (this) {
      case UserRole.superAdmin:
        return 'Full system access and configuration';
      case UserRole.farmManager:
        return 'Manages farm operations, inventory, and batch production';
      case UserRole.fulfillmentManager:
        return 'Oversees harvest confirmation and packaging operations';
      case UserRole.salesManager:
        return 'Manages sales, offtakers, and revenue tracking';
      case UserRole.accountant:
        return 'Handles financial transactions and reporting';
      case UserRole.farmOwner:
        return 'Monitors farm performance and financials';
      case UserRole.caretaker:
        return 'Records farm activities and manages daily operations';
      case UserRole.technician:
        return 'Handles maintenance and technical issues';
      case UserRole.packagingSupervisor:
        return 'Supervises packaging operations and waste tracking';
      case UserRole.qualityAssurance:
        return 'Ensures product quality standards and inspections';
      case UserRole.salesPersonnel:
        return 'Manages deliveries and offtaker relationships';
    }
  }

  /// Get role color for UI
  String get colorHex {
    switch (this) {
      case UserRole.superAdmin:
        return '#9C27B0'; // Purple
      case UserRole.farmManager:
        return '#4CAF50'; // Green
      case UserRole.fulfillmentManager:
        return '#FF9800'; // Orange
      case UserRole.salesManager:
        return '#2196F3'; // Blue
      case UserRole.accountant:
        return '#F44336'; // Red
      case UserRole.farmOwner:
        return '#009688'; // Teal
      case UserRole.caretaker:
        return '#8BC34A'; // Light Green
      case UserRole.technician:
        return '#607D8B'; // Blue Grey
      case UserRole.packagingSupervisor:
        return '#FF5722'; // Deep Orange
      case UserRole.qualityAssurance:
        return '#3F51B5'; // Indigo
      case UserRole.salesPersonnel:
        return '#00BCD4'; // Cyan
    }
  }

  /// Get dashboard route for role
  String get dashboardRoute {
    switch (this) {
      case UserRole.superAdmin:
        return '/superadmin_dashboard';
      case UserRole.farmManager:
        return '/farm_manager_dashboard';
      case UserRole.fulfillmentManager:
        return '/fulfillment_manager_dashboard';
      case UserRole.salesManager:
        return '/sales_manager_dashboard';
      case UserRole.accountant:
        return '/accountant_dashboard';
      case UserRole.farmOwner:
        return '/owner_dashboard';
      case UserRole.caretaker:
        return '/caretaker_dashboard';
      case UserRole.technician:
        return '/technician_dashboard';
      case UserRole.packagingSupervisor:
        return '/packaging_supervisor_dashboard';
      case UserRole.qualityAssurance:
        return '/quality_assurance_dashboard';
      case UserRole.salesPersonnel:
        return '/sales_personnel_dashboard';
    }
  }
}
