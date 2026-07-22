import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/role_permissions.dart';
import '../../providers/auth_provider.dart';

/// Permission Wrapper Widget
/// Conditionally shows/hides widgets based on user permissions
class PermissionWrapper extends ConsumerWidget {
  final Permission permission;
  final Widget child;
  final Widget? fallback;
  final bool showFallback;

  const PermissionWrapper({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
    this.showFallback = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userRole = authState.user?.role.name;

    // If no user, show fallback or nothing
    if (userRole == null) {
      return showFallback && fallback != null
          ? fallback!
          : const SizedBox.shrink();
    }

    // Check if user has permission
    final hasPermission = _checkPermission(userRole, permission);

    if (hasPermission) {
      return child;
    } else {
      return showFallback && fallback != null
          ? fallback!
          : const SizedBox.shrink();
    }
  }

  bool _checkPermission(String role, Permission permission) {
    final permissions = RolePermissions.getPermissions(role);
    return permissions.contains(permission);
  }
}

/// Role Wrapper Widget
/// Conditionally shows/hides widgets based on user role
class RoleWrapper extends ConsumerWidget {
  final List<String> allowedRoles;
  final Widget child;
  final Widget? fallback;
  final bool showFallback;

  const RoleWrapper({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
    this.showFallback = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userRole = authState.user?.role.name;

    // If no user, show fallback or nothing
    if (userRole == null) {
      return showFallback && fallback != null
          ? fallback!
          : const SizedBox.shrink();
    }

    // Check if user's role is in allowed roles
    final hasAccess = allowedRoles.contains(userRole);

    if (hasAccess) {
      return child;
    } else {
      return showFallback && fallback != null
          ? fallback!
          : const SizedBox.shrink();
    }
  }
}

/// Protected Button Widget
/// Button that's only enabled if user has permission
class ProtectedButton extends ConsumerWidget {
  final Permission permission;
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle? style;
  final String? disabledMessage;

  const ProtectedButton({
    super.key,
    required this.permission,
    required this.onPressed,
    required this.child,
    this.style,
    this.disabledMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userRole = authState.user?.role.name;

    // Check if user has permission
    final hasPermission =
        userRole != null && _checkPermission(userRole, permission);

    return ElevatedButton(
      onPressed: hasPermission
          ? onPressed
          : () {
              if (disabledMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(disabledMessage!)),
                );
              }
            },
      style: style,
      child: child,
    );
  }

  bool _checkPermission(String role, Permission permission) {
    final permissions = RolePermissions.getPermissions(role);
    return permissions.contains(permission);
  }
}

/// Protected Route Widget
/// Wrapper for entire screens that require specific permissions
class ProtectedRoute extends ConsumerWidget {
  final Permission permission;
  final Widget child;
  final Widget? unauthorizedWidget;

  const ProtectedRoute({
    super.key,
    required this.permission,
    required this.child,
    this.unauthorizedWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userRole = authState.user?.role.name;

    // If no user, show unauthorized
    if (userRole == null) {
      return unauthorizedWidget ?? _buildUnauthorized(context);
    }

    // Check if user has permission
    final hasPermission = _checkPermission(userRole, permission);

    if (hasPermission) {
      return child;
    } else {
      return unauthorizedWidget ?? _buildUnauthorized(context);
    }
  }

  bool _checkPermission(String role, Permission permission) {
    final permissions = RolePermissions.getPermissions(role);
    return permissions.contains(permission);
  }

  Widget _buildUnauthorized(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You do not have permission to access this page.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
