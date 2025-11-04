import 'package:flutter/material.dart';
import '../models/user/user_role.dart';
import '../widgets/permission_gate.dart';

/// Dashboard Factory
/// Routes users to their role-specific dashboard
/// Ensures complete separation between roles
class DashboardFactory {
  /// Get dashboard widget for a specific role
  static Widget getDashboard(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return _lazyLoad('/superadmin_dashboard');
        
      case UserRole.farmManager:
        return _lazyLoad('/farm_manager_dashboard');
        
      case UserRole.farmOwner:
        return _lazyLoad('/owner_dashboard');
        
      case UserRole.caretaker:
        return _lazyLoad('/caretaker_dashboard');
        
      case UserRole.technician:
        return _lazyLoad('/technician_dashboard');
        
      case UserRole.fulfillmentManager:
        return _lazyLoad('/fulfillment_manager_dashboard');
        
      case UserRole.packagingSupervisor:
        return _lazyLoad('/packaging_supervisor_dashboard');
        
      case UserRole.qualityAssurance:
        return _lazyLoad('/quality_assurance_dashboard');
        
      case UserRole.salesManager:
        return _lazyLoad('/sales_manager_dashboard');
        
      case UserRole.salesPersonnel:
        return _lazyLoad('/sales_personnel_dashboard');
        
      case UserRole.accountant:
        return _lazyLoad('/accountant_dashboard');
    }
  }

  /// Get dashboard route for a specific role
  static String getDashboardRoute(UserRole role) {
    return role.dashboardRoute;
  }

  /// Navigate to role-specific dashboard
  static void navigateToDashboard(BuildContext context, UserRole role) {
    Navigator.pushReplacementNamed(context, getDashboardRoute(role));
  }

  /// Lazy load dashboard (placeholder for now)
  static Widget _lazyLoad(String route) {
    return Builder(
      builder: (context) {
        // Navigate to the route
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, route);
        });
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  /// Check if user can access a specific route
  static bool canAccessRoute(UserRole role, String route) {
    // Super Admin can access everything
    if (role == UserRole.superAdmin) {
      return true;
    }

    // Check if route belongs to user's role
    final userDashboard = getDashboardRoute(role);
    
    // Extract base route (e.g., /farm_manager from /farm_manager/inventory)
    final routeBase = route.split('/').take(2).join('/');
    final dashboardBase = userDashboard.split('/').take(2).join('/');
    
    return routeBase == dashboardBase;
  }

  /// Get all available routes for a role
  static List<String> getAvailableRoutes(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return [
          '/superadmin_dashboard',
          '/superadmin/users',
          '/superadmin/farms',
          '/superadmin/plants',
          '/superadmin/packaging',
          '/superadmin/pricing',
          '/superadmin/audit',
          '/superadmin/config',
          '/superadmin/backup',
        ];
        
      case UserRole.farmManager:
        return [
          '/farm_manager_dashboard',
          '/farm_manager/farms',
          '/farm_manager/inventory',
          '/farm_manager/batches',
          '/farm_manager/reports',
          '/farm_manager/approvals',
        ];
        
      case UserRole.farmOwner:
        return [
          '/owner_dashboard',
          '/owner/farms',
          '/owner/financials',
          '/owner/wallet',
          '/owner/reports',
        ];
        
      case UserRole.caretaker:
        return [
          '/caretaker_dashboard',
          '/caretaker/farms',
          '/caretaker/records',
          '/caretaker/chat',
        ];
        
      case UserRole.technician:
        return [
          '/technician_dashboard',
          '/technician/issues',
          '/technician/maintenance',
          '/technician/schedule',
        ];
        
      case UserRole.fulfillmentManager:
        return [
          '/fulfillment_manager_dashboard',
          '/fulfillment/harvest',
          '/fulfillment/packaging',
          '/fulfillment/inventory',
          '/fulfillment/reports',
        ];
        
      case UserRole.packagingSupervisor:
        return [
          '/packaging_supervisor_dashboard',
          '/packaging/operations',
          '/packaging/waste',
          '/packaging/materials',
        ];
        
      case UserRole.qualityAssurance:
        return [
          '/quality_assurance_dashboard',
          '/quality/inspections',
          '/quality/reports',
          '/quality/approvals',
        ];
        
      case UserRole.salesManager:
        return [
          '/sales_manager_dashboard',
          '/sales/offtakers',
          '/sales/batches',
          '/sales/performance',
          '/sales/reports',
        ];
        
      case UserRole.salesPersonnel:
        return [
          '/sales_personnel_dashboard',
          '/sales_personnel/deliveries',
          '/sales_personnel/offtakers',
          '/sales_personnel/reports',
        ];
        
      case UserRole.accountant:
        return [
          '/accountant_dashboard',
          '/accountant/transactions',
          '/accountant/reconciliation',
          '/accountant/reports',
        ];
    }
  }
}

/// Route Guard
/// Protects routes based on user role
class RouteGuard {
  /// Check if user can access route
  static bool canAccess(UserRole? role, String route) {
    if (role == null) return false;
    
    // Login route is accessible to all
    if (route == '/login') return true;
    
    return DashboardFactory.canAccessRoute(role, route);
  }

  /// Get redirect route if access denied
  static String getRedirectRoute(UserRole? role) {
    if (role == null) return '/login';
    return DashboardFactory.getDashboardRoute(role);
  }
}

/// Protected Route Widget
/// Wraps a route with role-based access control
class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final List<UserRole>? allowedRoles;
  final String? requiredPermission;

  const ProtectedRoute({
    super.key,
    required this.child,
    this.allowedRoles,
    this.requiredPermission,
  });

  @override
  Widget build(BuildContext context) {
    if (requiredPermission != null) {
      return PermissionGate(
        permission: requiredPermission!,
        child: child,
        fallback: const UnauthorizedScreen(),
        showFallback: true,
      );
    }

    if (allowedRoles != null) {
      return RoleGate(
        allowedRoles: allowedRoles!.map((r) => r.code).toList(),
        child: child,
        fallback: const UnauthorizedScreen(),
        showFallback: true,
      );
    }

    return child;
  }
}
