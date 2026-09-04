import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/adaptive_logout_confirmation.dart';
import '../../core/widgets/role_mobile_navigation.dart';
import '../../core/widgets/sales_personnel_header.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  final _api = SuperAdminApiService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _refreshTimer;
  List<Map<String, dynamic>> _deliveries = const [];
  bool _loading = true;
  bool _requestInFlight = false;
  String? _error;

  int get _selectedTab => widget.initialTab.clamp(0, 2);

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    try {
      final sales = await _api.getSales();
      final user = ref.read(authProvider).user;
      final identity = {
        user?.id,
        user?.email,
        user?.name,
      }
          .map((value) => (value ?? '').trim().toLowerCase())
          .where((value) => value.isNotEmpty)
          .toSet();
      final assigned = sales.where((sale) {
        final deliveryIdentity = {
          sale['delivery_agent_id'],
          sale['delivery_agent_email'],
          sale['delivery_agent_name'],
        }
            .map((value) => '${value ?? ''}'.trim().toLowerCase())
            .where((value) => value.isNotEmpty);
        return deliveryIdentity.any(identity.contains);
      }).toList()
        ..sort((a, b) => _date(b).compareTo(_date(a)));
      if (!mounted) return;
      setState(() {
        _deliveries = assigned;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || (silent && _deliveries.isNotEmpty)) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    } finally {
      _requestInFlight = false;
    }
  }

  String _text(Object? value, [String fallback = 'Not set']) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  String _status(Map<String, dynamic> delivery) =>
      _text(delivery['status'], 'Pending').toLowerCase();

  DateTime _date(Map<String, dynamic> delivery) =>
      DateTime.tryParse(_text(delivery['scheduled_for'], '')) ??
      DateTime.tryParse(_text(delivery['delivered_at'], '')) ??
      DateTime.tryParse(_text(delivery[r'$createdAt'], '')) ??
      DateTime.fromMillisecondsSinceEpoch(0);

  List<Map<String, dynamic>> get _active => _deliveries
      .where((item) => const {'pending', 'in transit'}.contains(_status(item)))
      .toList();

  List<Map<String, dynamic>> get _history => _deliveries
      .where((item) => !const {'pending', 'in transit'}.contains(_status(item)))
      .toList();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final name = user?.name ?? 'Driver';
    final email = user?.email ?? 'driver@farmestates.com';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? RoleMobileDrawer(
              userName: name,
              userEmail: email,
              userRole: 'Driver',
              selectedIndex: _selectedTab,
              onItemSelected: (_) {},
              items: driverNavigationItems,
            )
          : null,
      body: isMobile
          ? Column(
              children: [
                SalesPersonnelHeader(
                  userName: name,
                  roleLabel: 'Driver',
                  roleIcon: Icons.local_shipping_outlined,
                  settingsRoute: null,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(child: _body()),
              ],
            )
          : Row(
              children: [
                _DriverDesktopSidebar(
                  selectedIndex: _selectedTab,
                  userName: name,
                  userEmail: email,
                ),
                Expanded(
                  child: Column(
                    children: [
                      SalesPersonnelHeader(
                        userName: name,
                        roleLabel: 'Driver',
                        roleIcon: Icons.local_shipping_outlined,
                        settingsRoute: null,
                      ),
                      Expanded(child: _body()),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: isMobile
          ? RoleMobileBottomNav(
              selectedIndex: _selectedTab,
              onItemSelected: (_) {},
              items: driverNavigationItems,
            )
          : null,
    );
  }

  Widget _body() {
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          96,
        ),
        child: _loading
            ? const AdminDataSkeleton(rowCount: 4, compact: true)
            : _error != null
                ? _ErrorState(message: _error!, onRetry: _load)
                : _tabContent(),
      ),
    );
  }

  Widget _tabContent() {
    switch (_selectedTab) {
      case 1:
        return _deliveryCollection(
          title: 'Assigned Deliveries',
          subtitle: 'Current routes allocated to your driver account',
          deliveries: _active,
          emptyTitle: 'No active deliveries',
          emptyMessage:
              'New dispatches will appear here when a sales manager assigns you.',
        );
      case 2:
        return _deliveryCollection(
          title: 'Delivery History',
          subtitle: 'Completed, cancelled, and returned assignments',
          deliveries: _history,
          emptyTitle: 'No delivery history',
          emptyMessage: 'Completed assignments will be retained here.',
        );
      default:
        return _dashboard();
    }
  }

  Widget _dashboard() {
    final delivered =
        _deliveries.where((item) => _status(item) == 'delivered').length;
    final inTransit =
        _deliveries.where((item) => _status(item) == 'in transit').length;
    final pending =
        _deliveries.where((item) => _status(item) == 'pending').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hero(),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 720 ? 2 : 4;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: constraints.maxWidth < 420 ? 1.3 : 1.65,
              children: [
                _MetricCard(
                  label: 'Assigned',
                  value: '${_deliveries.length}',
                  icon: Icons.assignment_outlined,
                  color: AppColors.info,
                ),
                _MetricCard(
                  label: 'Pending',
                  value: '$pending',
                  icon: Icons.schedule_outlined,
                  color: AppColors.warning,
                ),
                _MetricCard(
                  label: 'In transit',
                  value: '$inTransit',
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFF2563EB),
                ),
                _MetricCard(
                  label: 'Delivered',
                  value: '$delivered',
                  icon: Icons.task_alt_outlined,
                  color: AppColors.success,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _deliveryCollection(
          title: 'Today\'s Route',
          subtitle: 'Assigned dispatches requiring your attention',
          deliveries: _active,
          emptyTitle: 'Your route is clear',
          emptyMessage:
              'Assigned deliveries will appear here with the off-taker, destination, vehicle, and invoice.',
        ),
      ],
    );
  }

  Widget _hero() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(
              Icons.route_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver Workspace',
                  style: AppTypography.h5.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Review assigned routes, delivery details, and printable invoices from one operational view.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh deliveries',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _deliveryCollection({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> deliveries,
    required String emptyTitle,
    required String emptyMessage,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.h6.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _CountBadge(count: deliveries.length),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (deliveries.isEmpty)
            _EmptyState(title: emptyTitle, message: emptyMessage)
          else
            ...deliveries.map(
              (delivery) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _DeliveryCard(
                  delivery: delivery,
                  onInvoice: () => _openInvoice(delivery),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openInvoice(Map<String, dynamic> delivery) async {
    final id = _text(delivery[r'$id'], '');
    if (id.isEmpty) return;
    try {
      final opened = await launchUrl(
        _api.salesInvoiceUrl(id),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw StateError('Invoice could not be opened.');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open invoice: $error')),
      );
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, size: 21, color: color),
          ),
          Text(
            value,
            style: AppTypography.h5.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.delivery, required this.onInvoice});

  final Map<String, dynamic> delivery;
  final VoidCallback onInvoice;

  String _text(Object? value, [String fallback = 'Not set']) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _text(delivery['status'], 'Pending');
    final statusColor = switch (status.toLowerCase()) {
      'delivered' => AppColors.success,
      'in transit' => const Color(0xFF2563EB),
      'cancelled' || 'rejected' => AppColors.error,
      _ => AppColors.warning,
    };
    final scheduled = DateTime.tryParse(_text(delivery['scheduled_for'], ''));
    final dateLabel = scheduled == null
        ? 'Schedule pending'
        : DateFormat('EEE, MMM d | h:mm a').format(scheduled.toLocal());
    final invoice = _text(delivery['invoice_number'], 'Invoice pending');
    final batch = _text(
      delivery['batch_number'] ?? delivery['batch_id'],
      'Batch pending',
    );

    return Material(
      color:
          isDark ? Colors.white.withValues(alpha: 0.035) : AppColors.neutral50,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onInvoice,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      Icons.local_shipping_outlined,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _text(delivery['buyer_name'], 'Off-taker pending'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$invoice | $batch',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? Colors.white60
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      status,
                      style: AppTypography.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailLine(
                icon: Icons.location_on_outlined,
                text: _text(delivery['delivery_address'], 'Address pending'),
              ),
              const SizedBox(height: AppSpacing.xs),
              _DetailLine(icon: Icons.schedule_outlined, text: dateLabel),
              const SizedBox(height: AppSpacing.xs),
              _DetailLine(
                icon: Icons.directions_car_outlined,
                text: _text(
                  delivery['delivery_plate_number'] ??
                      delivery['delivery_vehicle'],
                  'Vehicle pending',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onInvoice,
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('View invoice'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.white54 : AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        '$count',
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.route_outlined,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function({bool silent}) onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 44, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Could not load assigned deliveries',
              style:
                  AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverDesktopSidebar extends ConsumerWidget {
  const _DriverDesktopSidebar({
    required this.selectedIndex,
    required this.userName,
    required this.userEmail,
  });

  final int selectedIndex;
  final String userName;
  final String userEmail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : AppColors.textPrimary;
    return Container(
      width: 252,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white10 : AppColors.neutral200,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              isDark
                  ? 'assets/logos/logo_white.png'
                  : 'assets/logos/logo_black.png',
              height: 52,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'DRIVER WORKSPACE',
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white54 : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var index = 0; index < driverNavigationItems.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Material(
                  color: index == selectedIndex
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    leading: Icon(
                      index == selectedIndex
                          ? driverNavigationItems[index].activeIcon
                          : driverNavigationItems[index].icon,
                      color: index == selectedIndex
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    title: Text(
                      driverNavigationItems[index].label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: index == selectedIndex
                            ? AppColors.primary
                            : foreground,
                        fontWeight: index == selectedIndex
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      if (index != selectedIndex) {
                        Navigator.pushReplacementNamed(
                          context,
                          driverNavigationItems[index].route,
                        );
                      }
                    },
                  ),
                ),
              ),
            const Spacer(),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  userName.isEmpty ? 'D' : userName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                userEmail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                onPressed: () async {
                  final confirmed =
                      await showAdaptiveLogoutConfirmation(context);
                  if (!confirmed || !context.mounted) return;
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (_) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
