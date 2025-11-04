import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Auth State
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

/// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState()) {
    _initialize();
  }

  /// Initialize and restore session
  Future<void> _initialize() async {
    await _authService.initialize();
    if (_authService.isLoggedIn && _authService.currentUser != null) {
      state = AuthState(
        user: _authService.currentUser,
        isAuthenticated: true,
      );
    }
  }

  /// Login
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.login(email, password);

      if (result.success && result.user != null) {
        state = AuthState(
          user: result.user,
          isAuthenticated: true,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An error occurred: $e',
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    state = AuthState();
  }

  /// Check if user has permission
  bool hasPermission(Permission permission) {
    return _authService.hasPermission(permission);
  }

  /// Get dashboard route for current user
  String getDashboardRoute() {
    return _authService.getDashboardRoute();
  }

  /// Validate session
  Future<bool> validateSession() async {
    return await _authService.validateSession();
  }

  /// Get activity logs (admin only)
  Future<List<String>> getActivityLogs() async {
    if (!_authService.isAdmin) return [];
    return await _authService.getActivityLogs();
  }
}

/// Auth Provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Convenience providers
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isAdmin ?? false;
});

final isOwnerProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isOwner ?? false;
});

final isCaretakerProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isCaretaker ?? false;
});
