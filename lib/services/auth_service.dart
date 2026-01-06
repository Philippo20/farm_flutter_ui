import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/enums.dart';
import '../core/config/demo_accounts.dart';

/// Authentication Service
/// Handles user authentication, session management, and role-based access
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Session keys
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserRole = 'user_role';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyLoginTime = 'login_time';

  // Current user's dashboard route (set during login)
  String? _dashboardRoute;

  UserModel? _currentUser;

  /// Get current logged-in user
  UserModel? get currentUser => _currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Check if current user is admin
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Check if current user is owner
  bool get isOwner => _currentUser?.isOwner ?? false;

  /// Check if current user is caretaker
  bool get isCaretaker => _currentUser?.isCaretaker ?? false;

  /// Initialize auth service and restore session
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

      if (isLoggedIn) {
        // Restore user session
        final userId = prefs.getString(_keyUserId);
        final userName = prefs.getString(_keyUserName);
        final userEmail = prefs.getString(_keyUserEmail);
        final userRole = prefs.getString(_keyUserRole);

        if (userId != null && userName != null && userEmail != null && userRole != null) {
          _currentUser = UserModel(
            id: userId,
            name: userName,
            email: userEmail,
            role: UserRole.fromString(userRole),
            address: '',
            createdAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      print('Error initializing auth service: $e');
    }
  }

  /// Login with email and password
  Future<AuthResult> login(String email, String password) async {
    try {
      // Normalize email
      final normalizedEmail = email.toLowerCase().trim();

      // Check demo accounts
      final demoAccount = DemoAccounts.getByEmail(normalizedEmail);
      
      if (demoAccount == null) {
        return AuthResult(
          success: false,
          message: 'Invalid email or password',
        );
      }

      // Verify password
      if (demoAccount.password != password) {
        return AuthResult(
          success: false,
          message: 'Invalid email or password',
        );
      }

      // Store dashboard route
      _dashboardRoute = demoAccount.dashboardRoute;

      // Create user model (use role from demo account)
      _currentUser = UserModel(
        id: demoAccount.role,
        name: demoAccount.displayName,
        email: demoAccount.email,
        role: _mapRoleStringToEnum(demoAccount.role),
        address: 'Farm Estates',
        farmId: 'F001',
        createdAt: DateTime.now(),
      );

      // Save session
      await _saveSession();

      // Log login activity
      await _logActivity('User logged in', _currentUser!);

      return AuthResult(
        success: true,
        message: 'Login successful',
        user: _currentUser,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An error occurred during login: $e',
      );
    }
  }

  /// Map role string to UserRole enum
  UserRole _mapRoleStringToEnum(String role) {
    switch (role) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'farm_owner':
      case 'owner':
        return UserRole.owner;
      case 'caretaker':
        return UserRole.caretaker;
      default:
        // For new roles not in enum, default to caretaker
        return UserRole.caretaker;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      // Log logout activity
      if (_currentUser != null) {
        await _logActivity('User logged out', _currentUser!);
      }

      // Clear session
      await _clearSession();

      // Clear current user
      _currentUser = null;
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  /// Save user session to SharedPreferences
  Future<void> _saveSession() async {
    if (_currentUser == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserId, _currentUser!.id);
      await prefs.setString(_keyUserName, _currentUser!.name);
      await prefs.setString(_keyUserEmail, _currentUser!.email);
      await prefs.setString(_keyUserRole, _currentUser!.role.name);
      await prefs.setString(_keyLoginTime, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  /// Clear user session from SharedPreferences
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIsLoggedIn);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserRole);
      await prefs.remove(_keyLoginTime);
    } catch (e) {
      print('Error clearing session: $e');
    }
  }

  /// Log user activity (for audit trail)
  Future<void> _logActivity(String action, UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList('activity_logs') ?? [];
      
      final logEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'userId': user.id,
        'userName': user.name,
        'userRole': user.role.name,
        'action': action,
      }.toString();

      logs.add(logEntry);
      
      // Keep only last 100 logs
      if (logs.length > 100) {
        logs.removeRange(0, logs.length - 100);
      }

      await prefs.setStringList('activity_logs', logs);
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  /// Get activity logs (for admin audit trail)
  Future<List<String>> getActivityLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('activity_logs') ?? [];
    } catch (e) {
      print('Error getting activity logs: $e');
      return [];
    }
  }

  /// Check if user has permission for specific action
  bool hasPermission(Permission permission) {
    if (_currentUser == null) return false;

    switch (_currentUser!.role) {
      case UserRole.superAdmin:
        // Super Admin has ALL permissions including system-level
        return true;
      case UserRole.admin:
        // Admin has all permissions except system configuration
        return permission != Permission.manageSystemConfig &&
               permission != Permission.backupRestore;
      case UserRole.owner:
        // Owner has most permissions except user management
        return permission != Permission.manageUsers &&
               permission != Permission.manageRoles &&
               permission != Permission.viewAuditLogs &&
               permission != Permission.manageSystemConfig &&
               permission != Permission.backupRestore;
      case UserRole.caretaker:
        // Caretaker has limited permissions
        return permission == Permission.viewDashboard ||
               permission == Permission.viewFarms ||
               permission == Permission.manageTasks ||
               permission == Permission.viewSensors;
    }
  }

  /// Get user's dashboard route based on role
  String getDashboardRoute() {
    // Return stored dashboard route from login
    if (_dashboardRoute != null) {
      return _dashboardRoute!;
    }
    
    // Fallback to role-based routing
    if (_currentUser == null) return '/login';

    switch (_currentUser!.role) {
      case UserRole.superAdmin:
        return '/superadmin_dashboard';
      case UserRole.admin:
        return '/dashboard';
      case UserRole.owner:
        return '/owner_dashboard';
      case UserRole.caretaker:
        return '/caretaker_dashboard';
    }
  }

  /// Validate session (check if session is still valid)
  Future<bool> validateSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      final loginTimeStr = prefs.getString(_keyLoginTime);

      if (!isLoggedIn || loginTimeStr == null) {
        return false;
      }

      final loginTime = DateTime.parse(loginTimeStr);
      final now = DateTime.now();
      final difference = now.difference(loginTime);

      // Session expires after 24 hours
      if (difference.inHours > 24) {
        await logout();
        return false;
      }

      return true;
    } catch (e) {
      print('Error validating session: $e');
      return false;
    }
  }
}

/// Authentication Result
class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}

/// Permissions enum for role-based access control
enum Permission {
  // Dashboard & Viewing
  viewDashboard,
  viewFarms,
  viewUsers,
  viewSensors,
  viewAnalytics,
  viewReports,
  viewAuditLogs,
  
  // Management
  manageFarms,
  manageUsers,
  manageSensors,
  manageSettings,
  manageRoles,
  manageTasks,
  generateReports,
  
  // Super Admin Only
  manageSystemConfig,
  backupRestore,
  approveSuspendUsers,
  approveSuspendFarms,
  managePlantTypes,
  managePackaging,
  managePricing,
}
