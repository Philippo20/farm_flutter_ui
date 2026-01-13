
/// Route Guard
/// Handles route-level access control based on user roles
class RouteGuard {
  /// Map of routes to allowed roles (simplified approach)
  static final Map<String, List<String>> _routeRoles = {
    // Super Admin routes
    '/superadmin_dashboard': ['super_admin'],
    '/superadmin/users': ['super_admin'],
    '/superadmin/farms': ['super_admin'],
    '/superadmin/plants': ['super_admin'],
    '/superadmin/packaging': ['super_admin'],
    '/superadmin/pricing': ['super_admin'],
    '/superadmin/audit': ['super_admin'],
    '/superadmin/config': ['super_admin'],
    '/superadmin/backup': ['super_admin'],
    
    // Admin routes
    '/dashboard': ['admin'],
    '/users': ['admin'],
    '/farms': ['admin'],
    '/sensors': ['admin'],
    '/analytics': ['admin'],
    '/settings': ['admin'],
    
    // Farm Manager routes
    '/farm-manager': ['farm_manager'],
    '/inventory': ['farm_manager'],
    '/batch-generation': ['farm_manager'],
    '/fund-request': ['farm_manager'],
    
    // Farm Owner routes
    '/owner_dashboard': ['farm_owner'],
    '/wallet': ['farm_owner'],
    '/withdraw': ['farm_owner'],
    '/owner-analytics': ['farm_owner'],
    
    // Caretaker routes
    '/caretaker_dashboard': ['caretaker'],
    '/record-entry': ['caretaker'],
    '/input-confirmation': ['caretaker'],
    '/caretaker-chat': ['caretaker'],
    
    // Technician routes
    '/technician_dashboard': ['technician'],
    '/report-issue': ['technician'],
    '/maintenance': ['technician'],
    '/request-items': ['technician'],
    
    // Fulfillment routes
    '/fulfillment_dashboard': ['fulfillment_manager'],
    '/confirm-harvest': ['fulfillment_manager'],
    '/materials-inventory': ['fulfillment_manager'],
    '/yield-loss': ['fulfillment_manager'],
    
    // Packaging routes
    '/packaging_dashboard': ['packaging_supervisor'],
    '/package-record': ['packaging_supervisor'],
    '/waste-tracking': ['packaging_supervisor'],
    
    // Quality routes
    '/quality_dashboard': ['quality_assurance'],
    '/quality-inspection': ['quality_assurance'],
    '/reject-batch': ['quality_assurance'],
    '/approve-sales': ['quality_assurance'],
    
    // Sales Manager routes
    '/sales_dashboard': ['sales_manager'],
    '/offtaker-management': ['sales_manager'],
    '/sales-performance': ['sales_manager'],
    
    // Sales Personnel routes
    '/sales_personnel_dashboard': ['sales_personnel'],
    '/record-delivery': ['sales_personnel'],
    '/pipeline': ['sales_personnel'],
    
    // Accountant routes
    '/accountant_dashboard': ['accountant'],
    '/confirm-transaction': ['accountant'],
    '/reconcile': ['accountant'],
    '/financial-reports': ['accountant'],
  };

  /// Check if a user role can access a specific route
  static bool canAccess(String route, String userRole) {
    // Public routes (no authentication required)
    if (route == '/login' || route == '/signup') {
      return true;
    }

    // Get allowed roles for route
    final allowedRoles = _routeRoles[route];
    
    // If route has no specific roles, allow access
    if (allowedRoles == null || allowedRoles.isEmpty) {
      return true;
    }

    // Check if user's role is in allowed roles
    return allowedRoles.contains(userRole);
  }

  /// Get redirect route for unauthorized access
  static String getRedirectRoute(String userRole) {
    // Map roles to their dashboard routes
    final dashboardRoutes = {
      'super_admin': '/superadmin_dashboard',
      'admin': '/dashboard',
      'farm_manager': '/farm-manager',
      'farm_owner': '/owner_dashboard',
      'caretaker': '/caretaker_dashboard',
      'technician': '/technician_dashboard',
      'fulfillment_manager': '/fulfillment_dashboard',
      'packaging_supervisor': '/packaging_dashboard',
      'quality_assurance': '/quality_dashboard',
      'sales_manager': '/sales_dashboard',
      'sales_personnel': '/sales_personnel_dashboard',
      'accountant': '/accountant_dashboard',
    };

    return dashboardRoutes[userRole] ?? '/login';
  }

  /// Check if route requires authentication
  static bool requiresAuth(String route) {
    return route != '/login' && route != '/signup';
  }

  /// Get user-accessible routes
  static List<String> getAccessibleRoutes(String userRole) {
    final accessibleRoutes = <String>[];

    _routeRoles.forEach((route, allowedRoles) {
      if (allowedRoles.contains(userRole)) {
        accessibleRoutes.add(route);
      }
    });

    // Add public routes
    accessibleRoutes.addAll(['/login', '/signup']);

    return accessibleRoutes;
  }

  /// Validate route transition
  static RouteValidationResult validateRoute({
    required String route,
    required String? userRole,
    required bool isAuthenticated,
  }) {
    // Check authentication
    if (requiresAuth(route) && !isAuthenticated) {
      return RouteValidationResult(
        isValid: false,
        redirectTo: '/login',
        message: 'Authentication required',
      );
    }

    // Check authorization
    if (userRole != null && !canAccess(route, userRole)) {
      return RouteValidationResult(
        isValid: false,
        redirectTo: getRedirectRoute(userRole),
        message: 'You do not have permission to access this page',
      );
    }

    return RouteValidationResult(isValid: true);
  }
}

/// Route validation result
class RouteValidationResult {
  final bool isValid;
  final String? redirectTo;
  final String? message;

  RouteValidationResult({
    required this.isValid,
    this.redirectTo,
    this.message,
  });
}
