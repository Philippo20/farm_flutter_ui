import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'adaptive_logout_confirmation.dart';

final _pendingLogouts = <NavigatorState>{};

/// Shared by desktop sidebars and mobile drawers, including nested navigators.
Future<void> confirmAndLogout(BuildContext context) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  if (!_pendingLogouts.add(navigator)) return;
  try {
    final auth = ProviderScope.containerOf(context, listen: false)
        .read(authProvider.notifier);
    final confirmed = await showAdaptiveLogoutConfirmation(context);
    if (!confirmed || !context.mounted) return;
    await auth.logout();
    if (navigator.mounted) {
      navigator.pushNamedAndRemoveUntil('/login', (_) => false);
    }
  } finally {
    _pendingLogouts.remove(navigator);
  }
}
