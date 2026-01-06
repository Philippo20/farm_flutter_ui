import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user/user_model.dart';
import '../models/user/user_role.dart';

/// Enhanced Authentication Provider with unique account validation
/// Manages user authentication, session, and role-based access
class EnhancedAuthProvider extends StateNotifier<AuthState> {
  EnhancedAuthProvider() : super(AuthState.initial());

  /// Login with email and password
  Future<AuthResult> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Validate email format
      if (!UserModel.isValidEmail(email)) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid email format',
        );
        return AuthResult.failure('Invalid email format');
      }

      // Get all users (in production, this would be an API call)
      final users = await _getAllUsers();

      // Find user by email
      final user = users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('User not found'),
      );

      // Check if user is active
      if (!user.isActive) {
        String message;
        if (user.isPending) {
          message = 'Your account is pending approval';
        } else if (user.isSuspended) {
          message = 'Your account has been suspended';
        } else {
          message = 'Your account is inactive';
        }
        state = state.copyWith(isLoading: false, error: message);
        return AuthResult.failure(message);
      }

      // Verify password (in production, use proper password hashing)
      final isPasswordValid = await _verifyPassword(email, password);
      if (!isPasswordValid) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid email or password',
        );
        return AuthResult.failure('Invalid email or password');
      }

      // Update last login
      final updatedUser = user.copyWith(lastLoginAt: DateTime.now());

      // Save session
      await _saveSession(updatedUser);

      // Update state
      state = state.copyWith(
        user: updatedUser,
        isAuthenticated: true,
        isLoading: false,
        error: null,
      );

      return AuthResult.success(updatedUser);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return AuthResult.failure(e.toString());
    }
  }

  /// Logout current user
  Future<void> logout() async {
    await _clearSession();
    state = AuthState.initial();
  }

  /// Check if user is authenticated (restore session)
  Future<void> checkAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');

      if (userJson != null) {
        final user = UserModel.fromJson(json.decode(userJson));
        
        // Check if user is still active
        if (user.isActive) {
          state = state.copyWith(
            user: user,
            isAuthenticated: true,
          );
        } else {
          await _clearSession();
        }
      }
    } catch (e) {
      await _clearSession();
    }
  }

  /// Register new user (Super Admin only)
  Future<AuthResult> registerUser({
    required String email,
    required String name,
    required UserRole role,
    String? phoneNumber,
    String? employeeId,
    String? department,
    List<String> assignedFarmIds = const [],
  }) async {
    try {
      // Get existing users
      final existingUsers = await _getAllUsers();

      // Validate user data
      final errors = UserValidator.validate(
        email: email,
        name: name,
        role: role,
        phoneNumber: phoneNumber,
        employeeId: employeeId,
        existingUsers: existingUsers,
      );

      if (errors.isNotEmpty) {
        final errorMessage = errors.values.join(', ');
        return AuthResult.failure(errorMessage);
      }

      // Create new user
      final newUser = UserModel(
        id: _generateUserId(),
        email: email,
        name: name,
        role: role,
        phoneNumber: phoneNumber,
        employeeId: employeeId,
        department: department,
        status: UserStatus.active,
        createdAt: DateTime.now(),
        assignedFarmIds: assignedFarmIds,
      );

      // Save user (in production, this would be an API call)
      await _saveUser(newUser);

      return AuthResult.success(newUser);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  /// Update user profile
  Future<AuthResult> updateUser(UserModel updatedUser) async {
    try {
      // Get existing users
      final existingUsers = await _getAllUsers();

      // Validate unique constraints (excluding current user)
      if (!UserValidator.isEmailUnique(
        updatedUser.email,
        existingUsers,
        excludeUserId: updatedUser.id,
      )) {
        return AuthResult.failure(UserValidationError.emailExists);
      }

      if (!UserValidator.isPhoneUnique(
        updatedUser.phoneNumber,
        existingUsers,
        excludeUserId: updatedUser.id,
      )) {
        return AuthResult.failure(UserValidationError.phoneExists);
      }

      if (!UserValidator.isEmployeeIdUnique(
        updatedUser.employeeId,
        existingUsers,
        excludeUserId: updatedUser.id,
      )) {
        return AuthResult.failure(UserValidationError.employeeIdExists);
      }

      // Update user (in production, this would be an API call)
      await _saveUser(updatedUser);

      // Update current session if it's the logged-in user
      if (state.user?.id == updatedUser.id) {
        await _saveSession(updatedUser);
        state = state.copyWith(user: updatedUser);
      }

      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  /// Change user status
  Future<AuthResult> changeUserStatus(String userId, UserStatus newStatus) async {
    try {
      final users = await _getAllUsers();
      final user = users.firstWhere((u) => u.id == userId);
      final updatedUser = user.copyWith(status: newStatus);
      
      await _saveUser(updatedUser);
      
      // If suspending current user, logout
      if (state.user?.id == userId && newStatus != UserStatus.active) {
        await logout();
      }
      
      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  // Private helper methods

  Future<List<UserModel>> _getAllUsers() async {
    // In production, this would fetch from API
    // For now, return demo users
    return _getDemoUsers();
  }

  Future<bool> _verifyPassword(String email, String password) async {
    // In production, verify against hashed password from API
    // For demo purposes, use simple mapping
    final passwordMap = {
      'superadmin@farm.com': 'super123',
      'farmmanager@farm.com': 'manager123',
      'owner@farm.com': 'owner123',
      'caretaker@farm.com': 'care123',
      'technician@farm.com': 'tech123',
      'fulfillment@farm.com': 'fulfill123',
      'packaging@farm.com': 'pack123',
      'quality@farm.com': 'quality123',
      'salesmanager@farm.com': 'sales123',
      'salesperson@farm.com': 'person123',
      'accountant@farm.com': 'account123',
    };

    return passwordMap[email.toLowerCase()] == password;
  }

  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', json.encode(user.toJson()));
    await prefs.setString('session_token', _generateSessionToken());
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    await prefs.remove('session_token');
  }

  Future<void> _saveUser(UserModel user) async {
    // In production, save to API
    // For now, just store in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('all_users') ?? '[]';
    final users = (json.decode(usersJson) as List)
        .map((u) => UserModel.fromJson(u))
        .toList();

    final index = users.indexWhere((u) => u.id == user.id);
    if (index >= 0) {
      users[index] = user;
    } else {
      users.add(user);
    }

    await prefs.setString(
      'all_users',
      json.encode(users.map((u) => u.toJson()).toList()),
    );
  }

  String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateSessionToken() {
    return 'token_${DateTime.now().millisecondsSinceEpoch}';
  }

  List<UserModel> _getDemoUsers() {
    return [
      UserModel(
        id: 'SA001',
        email: 'superadmin@farm.com',
        phoneNumber: '+1234567890',
        employeeId: 'EMP001',
        name: 'Sarah SuperAdmin',
        role: UserRole.superAdmin,
        status: UserStatus.active,
        department: 'Administration',
        createdAt: DateTime(2024, 1, 1),
        lastLoginAt: DateTime.now(),
      ),
      UserModel(
        id: 'FM001',
        email: 'farmmanager@farm.com',
        phoneNumber: '+1234567891',
        employeeId: 'EMP002',
        name: 'John Farm Manager',
        role: UserRole.farmManager,
        status: UserStatus.active,
        department: 'Farm Operations',
        createdAt: DateTime(2024, 1, 15),
        assignedFarmIds: ['FARM001', 'FARM002'],
      ),
      UserModel(
        id: 'FO001',
        email: 'owner@farm.com',
        phoneNumber: '+1234567892',
        employeeId: 'EMP003',
        name: 'Alice Farm Owner',
        role: UserRole.farmOwner,
        status: UserStatus.active,
        createdAt: DateTime(2024, 2, 1),
        assignedFarmIds: ['FARM001'],
      ),
      UserModel(
        id: 'CT001',
        email: 'caretaker@farm.com',
        phoneNumber: '+1234567893',
        employeeId: 'EMP004',
        name: 'Bob Caretaker',
        role: UserRole.caretaker,
        status: UserStatus.active,
        department: 'Farm Operations',
        createdAt: DateTime(2024, 2, 15),
        assignedFarmIds: ['FARM001'],
      ),
      UserModel(
        id: 'TN001',
        email: 'technician@farm.com',
        phoneNumber: '+1234567894',
        employeeId: 'EMP005',
        name: 'Mike Technician',
        role: UserRole.technician,
        status: UserStatus.active,
        department: 'Maintenance',
        createdAt: DateTime(2024, 3, 1),
        assignedFarmIds: ['FARM001', 'FARM002', 'FARM003'],
      ),
      UserModel(
        id: 'FLM001',
        email: 'fulfillment@farm.com',
        phoneNumber: '+1234567895',
        employeeId: 'EMP006',
        name: 'Emma Fulfillment Manager',
        role: UserRole.fulfillmentManager,
        status: UserStatus.active,
        department: 'Fulfillment',
        createdAt: DateTime(2024, 3, 15),
      ),
      UserModel(
        id: 'PS001',
        email: 'packaging@farm.com',
        phoneNumber: '+1234567896',
        employeeId: 'EMP007',
        name: 'David Packaging Supervisor',
        role: UserRole.packagingSupervisor,
        status: UserStatus.active,
        department: 'Fulfillment',
        createdAt: DateTime(2024, 4, 1),
      ),
      UserModel(
        id: 'QA001',
        email: 'quality@farm.com',
        phoneNumber: '+1234567897',
        employeeId: 'EMP008',
        name: 'Lisa Quality Officer',
        role: UserRole.qualityAssurance,
        status: UserStatus.active,
        department: 'Quality Control',
        createdAt: DateTime(2024, 4, 15),
      ),
      UserModel(
        id: 'SM001',
        email: 'salesmanager@farm.com',
        phoneNumber: '+1234567898',
        employeeId: 'EMP009',
        name: 'Tom Sales Manager',
        role: UserRole.salesManager,
        status: UserStatus.active,
        department: 'Sales',
        createdAt: DateTime(2024, 5, 1),
      ),
      UserModel(
        id: 'SP001',
        email: 'salesperson@farm.com',
        phoneNumber: '+1234567899',
        employeeId: 'EMP010',
        name: 'Mary Sales Personnel',
        role: UserRole.salesPersonnel,
        status: UserStatus.active,
        department: 'Sales',
        createdAt: DateTime(2024, 5, 15),
      ),
      UserModel(
        id: 'AC001',
        email: 'accountant@farm.com',
        phoneNumber: '+1234567800',
        employeeId: 'EMP011',
        name: 'James Accountant',
        role: UserRole.accountant,
        status: UserStatus.active,
        department: 'Finance',
        createdAt: DateTime(2024, 6, 1),
      ),
    ];
  }
}

/// Authentication state
class AuthState {
  final UserModel? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  factory AuthState.initial() {
    return AuthState();
  }

  AuthState copyWith({
    UserModel? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Authentication result
class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;

  AuthResult.success(this.user)
      : success = true,
        message = null;

  AuthResult.failure(this.message)
      : success = false,
        user = null;
}

/// Provider instance
final enhancedAuthProvider = StateNotifierProvider<EnhancedAuthProvider, AuthState>((ref) {
  return EnhancedAuthProvider();
});

/// Current user provider
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(enhancedAuthProvider).user;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(enhancedAuthProvider).isAuthenticated;
});
