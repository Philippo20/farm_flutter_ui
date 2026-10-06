import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_typography.dart';

/// Each choice is verified by the API before opening its dashboard.
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _opening;
  String? _error;

  Future<void> _open(UserRole role) async {
    if (_opening != null) return;
    setState(() {
      _opening = role;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).selectRole(role);
      if (!mounted) return;
      final route = ref.read(authProvider.notifier).getDashboardRoute();
      Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
    } catch (error) {
      if (mounted)
        setState(() {
          _opening = null;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
    }
  }

  IconData _icon(UserRole role) => switch (role) {
        UserRole.superAdmin => Icons.admin_panel_settings_outlined,
        UserRole.admin => Icons.manage_accounts_outlined,
        UserRole.farmManager => Icons.agriculture_outlined,
        UserRole.owner => Icons.home_work_outlined,
        UserRole.caretaker => Icons.eco_outlined,
        UserRole.technician => Icons.build_outlined,
        UserRole.fulfillmentManager => Icons.warehouse_outlined,
        UserRole.packagingSupervisor => Icons.inventory_2_outlined,
        UserRole.qualityAssurance => Icons.verified_outlined,
        UserRole.salesManager => Icons.insights_outlined,
        UserRole.salesPersonnel => Icons.storefront_outlined,
        UserRole.driver => Icons.local_shipping_outlined,
        UserRole.accountant => Icons.account_balance_wallet_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Choose your workspace'),
          actions: [
            TextButton(
                onPressed: _opening != null
                    ? null
                    : () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted)
                          Navigator.of(context)
                              .pushNamedAndRemoveUntil('/login', (_) => false);
                      },
                child: const Text('Sign out')),
            const SizedBox(width: 12)
          ]),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user == null ? 'Please sign in' : 'Welcome, ${user.name}',
                    style: AppTypography.h5),
                const SizedBox(height: 8),
                Text(
                    'Select the role you want to work in. Each workspace shows the tools and data available to that role.',
                    style: AppTypography.bodySmall
                        .copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: 24),
                LayoutBuilder(builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 820
                      ? 3
                      : constraints.maxWidth >= 520
                          ? 2
                          : 1;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 16) / columns;
                  return Wrap(spacing: 16, runSpacing: 16, children: [
                    for (final role in user?.roles ?? <UserRole>[])
                      SizedBox(
                          width: width,
                          child: Material(
                            color: colors.surface,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: colors.outlineVariant)),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap:
                                  _opening == null ? () => _open(role) : null,
                              child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(_icon(role),
                                            color: colors.primary, size: 30),
                                        const SizedBox(height: 20),
                                        Text(role.displayName,
                                            style: AppTypography.body.copyWith(
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 12),
                                        Row(children: [
                                          Expanded(
                                              child: Text(
                                                  _opening == role
                                                      ? 'Opening workspace...'
                                                      : 'Open dashboard',
                                                  style: AppTypography.bodySmall
                                                      .copyWith(
                                                          color: colors
                                                              .onSurfaceVariant))),
                                          if (_opening == role)
                                            const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2))
                                          else
                                            Icon(Icons.arrow_forward_rounded,
                                                size: 18, color: colors.primary)
                                        ]),
                                      ])),
                            ),
                          )),
                  ]);
                }),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(_error!,
                          style: AppTypography.bodySmall
                              .copyWith(color: colors.error))),
              ],
            )),
      ))),
    );
  }
}
