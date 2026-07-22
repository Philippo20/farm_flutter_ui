import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/enhanced_auth_provider.dart';

/// Permission Gate Widget
/// Shows content only if user has the required permission
/// Provides role-based access control at the UI level
class PermissionGate extends ConsumerWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;
  final bool showFallback;

  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
    this.showFallback = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return showFallback
          ? (fallback ?? const SizedBox.shrink())
          : const SizedBox.shrink();
    }

    final hasPermission = user.hasPermission(permission);

    if (hasPermission) {
      return child;
    }

    return showFallback
        ? (fallback ?? const SizedBox.shrink())
        : const SizedBox.shrink();
  }
}

/// Multi-Permission Gate
/// Shows content only if user has ANY of the required permissions
class AnyPermissionGate extends ConsumerWidget {
  final List<String> permissions;
  final Widget child;
  final Widget? fallback;
  final bool showFallback;

  const AnyPermissionGate({
    super.key,
    required this.permissions,
    required this.child,
    this.fallback,
    this.showFallback = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return showFallback
          ? (fallback ?? const SizedBox.shrink())
          : const SizedBox.shrink();
    }

    final hasAnyPermission = user.hasAnyPermission(permissions);

    if (hasAnyPermission) {
      return child;
    }

    return showFallback
        ? (fallback ?? const SizedBox.shrink())
        : const SizedBox.shrink();
  }
}

/// All Permissions Gate
/// Shows content only if user has ALL of the required permissions
class AllPermissionsGate extends ConsumerWidget {
  final List<String> permissions;
  final Widget child;
  final Widget? fallback;
  final bool showFallback;

  const AllPermissionsGate({
    super.key,
    required this.permissions,
    required this.child,
    this.fallback,
    this.showFallback = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return showFallback
          ? (fallback ?? const SizedBox.shrink())
          : const SizedBox.shrink();
    }

    final hasAllPermissions = user.hasAllPermissions(permissions);

    if (hasAllPermissions) {
      return child;
    }

    return showFallback
        ? (fallback ?? const SizedBox.shrink())
        : const SizedBox.shrink();
  }
}

/// Role Gate Widget
/// Shows content only if user has the specified role
class RoleGate extends ConsumerWidget {
  final List<String> allowedRoles; // List of role codes
  final Widget child;
  final Widget? fallback;
  final bool showFallback;

  const RoleGate({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
    this.showFallback = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return showFallback
          ? (fallback ?? const SizedBox.shrink())
          : const SizedBox.shrink();
    }

    final hasRole = allowedRoles.contains(user.role.code);

    if (hasRole) {
      return child;
    }

    return showFallback
        ? (fallback ?? const SizedBox.shrink())
        : const SizedBox.shrink();
  }
}

/// Permission Builder
/// Provides a builder function with permission status
class PermissionBuilder extends ConsumerWidget {
  final String permission;
  final Widget Function(BuildContext context, bool hasPermission) builder;

  const PermissionBuilder({
    super.key,
    required this.permission,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final hasPermission = user?.hasPermission(permission) ?? false;

    return builder(context, hasPermission);
  }
}

/// Unauthorized Access Screen
class UnauthorizedScreen extends StatelessWidget {
  final String? message;

  const UnauthorizedScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'Unauthorized Access',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              message ?? 'You do not have permission to access this resource',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
