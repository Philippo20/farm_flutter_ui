import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
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
  static const String _keyJwt = 'auth_jwt';
  static const String _keySessionId = 'auth_session_id';
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-5u45d.ondigitalocean.app',
  );

  // Current user's dashboard route (set during login)
  String? _dashboardRoute;
  String? _jwt;
  String? _sessionId;

  UserModel? _currentUser;

  /// Get current logged-in user
  UserModel? get currentUser => _currentUser;

  String? get jwt => _jwt;

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Check if current user is admin
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Check if current user is owner
  bool get isOwner => _currentUser?.isOwner ?? false;

  /// Check if current user is caretaker
  bool get isCaretaker => _currentUser?.isCaretaker ?? false;

  /// Update local session details after the backend profile has been saved.
  Future<UserModel?> updateCurrentUserProfile({
    required String name,
    required String email,
    required String address,
  }) async {
    final user = _currentUser;
    if (user == null) return null;

    _currentUser = user.copyWith(
      name: name,
      email: email,
      address: address,
      updatedAt: DateTime.now(),
    );
    await _saveSession();
    return _currentUser;
  }

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
        _jwt = prefs.getString(_keyJwt);
        _sessionId = prefs.getString(_keySessionId);

        if (userId != null &&
            userName != null &&
            userEmail != null &&
            userRole != null) {
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

      final exactDemoAccount = DemoAccounts.getByEmail(normalizedEmail);

      final apiResult = await _loginWithApi(normalizedEmail, password);
      if (apiResult != null) {
        // Demo credentials are intentionally displayed on the login screen.
        // Keep them usable when the corresponding account has not been seeded,
        // while preferring the real backend identity whenever login succeeds.
        if (!apiResult.success &&
            exactDemoAccount != null &&
            exactDemoAccount.password == password) {
          return _loginWithDemoAccount(exactDemoAccount);
        }
        return apiResult;
      }

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

      return _loginWithDemoAccount(demoAccount);
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An error occurred during login: $e',
      );
    }
  }

  Future<AuthResult> _loginWithDemoAccount(DemoAccount account) async {
    _dashboardRoute = account.dashboardRoute;
    _jwt = null;
    _sessionId = null;
    _currentUser = UserModel(
      id: account.role,
      name: account.displayName,
      email: account.email,
      role: _mapRoleStringToEnum(account.role),
      address: 'Farm Estates',
      farmId: 'F001',
      createdAt: DateTime.now(),
    );
    await _saveSession();
    await _logActivity('User logged in with demo account', _currentUser!);
    return AuthResult(
      success: true,
      message: 'Login successful',
      user: _currentUser,
    );
  }

  Future<AuthResult?> _loginWithApi(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/account/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'email': email,
          'password': password,
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 401 || response.statusCode == 403) {
        return AuthResult(
          success: false,
          message: _extractApiErrorMessage(
            response.body,
            fallback: response.statusCode == 403
                ? 'Login blocked for this account.'
                : 'Invalid email or password',
          ),
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AuthResult(
          success: false,
          message: 'Login failed. API returned ${response.statusCode}.',
        );
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final userJson = payload['user'] as Map<String, dynamic>?;
      if (userJson == null) {
        return AuthResult(
          success: false,
          message: 'Login failed. No user profile was returned.',
        );
      }

      final role = UserRole.fromString(userJson['role'] as String);
      _dashboardRoute = _routeForRole(role);
      _jwt = payload['jwt'] as String?;
      _sessionId = payload['session_id'] as String?;
      _currentUser = UserModel(
        id: (userJson[r'$id'] ?? userJson['id'] ?? email) as String,
        name: userJson['name'] as String? ?? email.split('@').first,
        email: userJson['email'] as String? ?? email,
        role: role,
        address: userJson['address'] as String? ?? '',
        farmId: userJson['farmID'] as String?,
        createdAt: DateTime.now(),
      );

      await _saveSession();
      await _logActivity('User logged in', _currentUser!);

      return AuthResult(
        success: true,
        message: 'Login successful',
        user: _currentUser,
      );
    } on TimeoutException {
      return null;
    } on http.ClientException {
      return null;
    } on FormatException {
      return AuthResult(
        success: false,
        message: 'Login failed. API returned an invalid response.',
      );
    } catch (_) {
      return null;
    }
  }

  String _extractApiErrorMessage(String body, {required String fallback}) {
    try {
      final payload = jsonDecode(body);
      if (payload is Map<String, dynamic>) {
        final detail = payload['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {
      // Keep the fallback when the API response is not JSON.
    }
    return fallback;
  }

  /// Map role string to UserRole enum
  UserRole _mapRoleStringToEnum(String role) {
    switch (role) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'farm_manager':
        return UserRole.farmManager;
      case 'farm_owner':
      case 'owner':
        return UserRole.owner;
      case 'caretaker':
        return UserRole.caretaker;
      case 'technician':
        return UserRole.technician;
      case 'fulfillment_manager':
        return UserRole.fulfillmentManager;
      case 'packaging_supervisor':
        return UserRole.packagingSupervisor;
      case 'quality_assurance':
      case 'quality_officer':
        return UserRole.qualityAssurance;
      case 'sales_manager':
        return UserRole.salesManager;
      case 'sales_personnel':
      case 'sales_person':
        return UserRole.salesPersonnel;
      case 'driver':
      case 'delivery_agent':
        return UserRole.driver;
      case 'accountant':
        return UserRole.accountant;
      default:
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
      _jwt = null;
      _sessionId = null;
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
      if (_jwt != null) {
        await prefs.setString(_keyJwt, _jwt!);
      }
      if (_sessionId != null) {
        await prefs.setString(_keySessionId, _sessionId!);
      }
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
      await prefs.remove(_keyJwt);
      await prefs.remove(_keySessionId);
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
      case UserRole.farmManager:
        return permission == Permission.viewDashboard ||
            permission == Permission.viewFarms ||
            permission == Permission.manageFarms ||
            permission == Permission.viewReports ||
            permission == Permission.generateReports ||
            permission == Permission.manageTasks;
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
      case UserRole.technician:
        return permission == Permission.viewDashboard ||
            permission == Permission.viewSensors ||
            permission == Permission.manageSensors ||
            permission == Permission.manageTasks;
      case UserRole.fulfillmentManager:
      case UserRole.packagingSupervisor:
      case UserRole.qualityAssurance:
      case UserRole.salesManager:
      case UserRole.salesPersonnel:
      case UserRole.driver:
      case UserRole.accountant:
        return permission == Permission.viewDashboard ||
            permission == Permission.viewReports ||
            permission == Permission.generateReports ||
            permission == Permission.manageTasks;
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
      case UserRole.farmManager:
        return '/farm-manager';
      case UserRole.owner:
        return '/owner_dashboard';
      case UserRole.caretaker:
        return '/caretaker_dashboard';
      case UserRole.technician:
        return '/technician_dashboard';
      case UserRole.fulfillmentManager:
        return '/fulfillment_dashboard';
      case UserRole.packagingSupervisor:
        return '/packaging_dashboard';
      case UserRole.qualityAssurance:
        return '/quality_dashboard';
      case UserRole.salesManager:
        return '/sales_dashboard';
      case UserRole.salesPersonnel:
        return '/sales_personnel_dashboard';
      case UserRole.driver:
        return '/driver_dashboard';
      case UserRole.accountant:
        return '/accountant_dashboard';
    }
  }

  String _routeForRole(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return '/superadmin_dashboard';
      case UserRole.admin:
        return '/dashboard';
      case UserRole.farmManager:
        return '/farm-manager';
      case UserRole.owner:
        return '/owner_dashboard';
      case UserRole.caretaker:
        return '/caretaker_dashboard';
      case UserRole.technician:
        return '/technician_dashboard';
      case UserRole.fulfillmentManager:
        return '/fulfillment_dashboard';
      case UserRole.packagingSupervisor:
        return '/packaging_dashboard';
      case UserRole.qualityAssurance:
        return '/quality_dashboard';
      case UserRole.salesManager:
        return '/sales_dashboard';
      case UserRole.salesPersonnel:
        return '/sales_personnel_dashboard';
      case UserRole.driver:
        return '/driver_dashboard';
      case UserRole.accountant:
        return '/accountant_dashboard';
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
