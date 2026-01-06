/// Demo Accounts Configuration
/// One-click login accounts for all user roles
class DemoAccount {
  final String email;
  final String password;
  final String role;
  final String displayName;
  final String description;
  final String dashboardRoute;

  const DemoAccount({
    required this.email,
    required this.password,
    required this.role,
    required this.displayName,
    required this.description,
    required this.dashboardRoute,
  });
}

/// All demo accounts available in the system
class DemoAccounts {
  // Super Admin - Full system access
  static const superAdmin = DemoAccount(
    email: 'superadmin@farmestates.com',
    password: 'super123',
    role: 'super_admin',
    displayName: 'Super Admin',
    description: 'Full system access',
    dashboardRoute: '/superadmin_dashboard',
  );

  // Admin - System management
  static const admin = DemoAccount(
    email: 'admin@farmestates.com',
    password: 'admin123',
    role: 'admin',
    displayName: 'Admin',
    description: 'System management',
    dashboardRoute: '/dashboard',
  );

  // Farm Manager - Inventory, monitoring, batch generation
  static const farmManager = DemoAccount(
    email: 'manager@farmestates.com',
    password: 'manager123',
    role: 'farm_manager',
    displayName: 'Farm Manager',
    description: 'Inventory & farm monitoring',
    dashboardRoute: '/farm-manager', // NEW DASHBOARD
  );

  // Farm Owner - Financial & yield monitoring
  static const farmOwner = DemoAccount(
    email: 'owner@farmestates.com',
    password: 'owner123',
    role: 'farm_owner',
    displayName: 'Farm Owner',
    description: 'Financial & yield monitoring',
    dashboardRoute: '/owner_dashboard', // NEW DASHBOARD
  );

  // Caretaker - Daily farm operations & records
  static const caretaker = DemoAccount(
    email: 'caretaker@farmestates.com',
    password: 'care123',
    role: 'caretaker',
    displayName: 'Caretaker',
    description: 'Daily operations & records',
    dashboardRoute: '/caretaker_dashboard', // NEW DASHBOARD
  );

  // Technician - Maintenance & technical issues
  static const technician = DemoAccount(
    email: 'technician@farmestates.com',
    password: 'tech123',
    role: 'technician',
    displayName: 'Technician',
    description: 'Maintenance & repairs',
    dashboardRoute: '/technician_dashboard', // NEW DASHBOARD
  );

  // Fulfillment Manager - Harvest receiving & packaging coordination
  static const fulfillmentManager = DemoAccount(
    email: 'fulfillment@farmestates.com',
    password: 'fulfill123',
    role: 'fulfillment_manager',
    displayName: 'Fulfillment Manager',
    description: 'Harvest & packaging coordination',
    dashboardRoute: '/fulfillment_dashboard',
  );

  // Packaging Supervisor - Packaging operations & waste tracking
  static const packagingSupervisor = DemoAccount(
    email: 'packaging@farmestates.com',
    password: 'pack123',
    role: 'packaging_supervisor',
    displayName: 'Packaging Supervisor',
    description: 'Packaging & waste tracking',
    dashboardRoute: '/packaging_dashboard',
  );

  // Quality Assurance - Quality inspection & approval
  static const qualityAssurance = DemoAccount(
    email: 'quality@farmestates.com',
    password: 'quality123',
    role: 'quality_assurance',
    displayName: 'Quality Assurance',
    description: 'Quality inspection & approval',
    dashboardRoute: '/quality_dashboard',
  );

  // Sales Manager - Sales tracking & off-taker management
  static const salesManager = DemoAccount(
    email: 'sales@farmestates.com',
    password: 'sales123',
    role: 'sales_manager',
    displayName: 'Sales Manager',
    description: 'Sales & off-taker management',
    dashboardRoute: '/sales_dashboard',
  );

  // Sales Personnel - Product delivery & new off-takers
  static const salesPersonnel = DemoAccount(
    email: 'salesperson@farmestates.com',
    password: 'seller123',
    role: 'sales_personnel',
    displayName: 'Sales Personnel',
    description: 'Product delivery & sales',
    dashboardRoute: '/sales_personnel_dashboard',
  );

  // Accountant - Financial transactions & reporting
  static const accountant = DemoAccount(
    email: 'accountant@farmestates.com',
    password: 'account123',
    role: 'accountant',
    displayName: 'Accountant',
    description: 'Financial transactions & reports',
    dashboardRoute: '/accountant_dashboard',
  );

  /// Get all demo accounts as a list
  static List<DemoAccount> get all => [
        superAdmin,
        admin,
        farmManager,
        farmOwner,
        caretaker,
        technician,
        fulfillmentManager,
        packagingSupervisor,
        qualityAssurance,
        salesManager,
        salesPersonnel,
        accountant,
      ];

  /// Get demo account by role
  static DemoAccount? getByRole(String role) {
    try {
      return all.firstWhere((account) => account.role == role);
    } catch (e) {
      return null;
    }
  }

  /// Get demo account by email
  static DemoAccount? getByEmail(String email) {
    try {
      return all.firstWhere((account) => account.email == email);
    } catch (e) {
      return null;
    }
  }

  /// Validate demo account credentials
  static bool validate(String email, String password) {
    final account = getByEmail(email);
    return account != null && account.password == password;
  }
}
