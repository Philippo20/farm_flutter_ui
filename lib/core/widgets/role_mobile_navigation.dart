import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'adaptive_logout_confirmation.dart';

class RoleNavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool primary;

  const RoleNavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.primary = false,
  });
}

class RoleMobileDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String userRole;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<RoleNavigationItem> items;

  const RoleMobileDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.neutral100,
      child: SafeArea(
        child: Column(
          children: [
            _header(isDark),
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : AppColors.neutral200,
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = index == selectedIndex;
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      selected: selected,
                      selectedTileColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.1),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withOpacity(0.2)
                              : (isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.04)),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Icon(
                          selected ? item.activeIcon : item.icon,
                          size: 22,
                          color: selected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary),
                        ),
                      ),
                      title: Text(
                        item.label,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? AppColors.primary
                              : (isDark ? Colors.white : AppColors.textPrimary),
                        ),
                      ),
                      onTap: () {
                        onItemSelected(index);
                        Navigator.pop(context);
                        if (index != selectedIndex) {
                          Navigator.pushReplacementNamed(context, item.route);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : AppColors.neutral200,
            ),
            _profile(isDark),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  onTap: () async {
                    final confirmed =
                        await showAdaptiveLogoutConfirmation(context);
                    if (confirmed && context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border:
                          Border.all(color: AppColors.error.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded,
                            size: 20, color: AppColors.error),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Logout',
                            style: AppTypography.bodyMedium.copyWith(
                                fontSize: 15,
                                color: AppColors.error,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _header(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Text(
              userName.isEmpty ? 'U' : userName[0].toUpperCase(),
              style: AppTypography.h4
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h6.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(userRole,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall
                        .copyWith(color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profile(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.08)
                ]
              : [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05)
                ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark]),
            ),
            child: Center(
              child: Text(userName.isEmpty ? 'U' : userName[0].toUpperCase(),
                  style: AppTypography.bodyMedium.copyWith(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(userEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                        fontSize: 12,
                        color:
                            isDark ? Colors.white70 : AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RoleMobileBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<RoleNavigationItem> items;
  final RoleNavigationItem? defaultDynamicItem;

  const RoleMobileBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.defaultDynamicItem,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = items.where((item) => item.primary).toList();
    final selectedItem = selectedIndex >= 0 && selectedIndex < items.length
        ? items[selectedIndex]
        : null;
    final current = selectedItem != null && !primary.contains(selectedItem)
        ? selectedItem
        : null;
    final dynamicItem = current ?? defaultDynamicItem;
    final visible = primary.length >= 5
        ? primary
        : [
            ...primary,
            if (dynamicItem != null && !primary.contains(dynamicItem))
              dynamicItem,
          ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
            top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: visible.map((item) {
              final index = items.indexOf(item);
              final selected = index == selectedIndex;
              final color = selected
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.textOnDark.withOpacity(0.74)
                      : AppColors.textSecondary);
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      onItemSelected(index);
                      if (!selected)
                        Navigator.pushReplacementNamed(context, item.route);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                      .withOpacity(isDark ? 0.16 : 0.10)
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            child: Icon(selected ? item.activeIcon : item.icon,
                                size: 22, color: color),
                          ),
                          const SizedBox(height: 4),
                          Text(item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

const technicianNavigationItems = [
  RoleNavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Home',
      route: '/technician_dashboard',
      primary: true),
  RoleNavigationItem(
      icon: Icons.sensors_outlined,
      activeIcon: Icons.sensors_rounded,
      label: 'Sensors',
      route: '/sensor-management',
      primary: true),
  RoleNavigationItem(
      icon: Icons.build_outlined,
      activeIcon: Icons.build_rounded,
      label: 'Maintain',
      route: '/maintenance-schedule',
      primary: true),
  RoleNavigationItem(
      icon: Icons.history_outlined,
      activeIcon: Icons.history_rounded,
      label: 'History',
      route: '/repair-history',
      primary: true),
  RoleNavigationItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
      route: '/technician-settings'),
];

const fulfillmentNavigationItems = [
  RoleNavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Home',
      route: '/fulfillment_dashboard',
      primary: true),
  RoleNavigationItem(
      icon: Icons.check_box_outlined,
      activeIcon: Icons.check_box_rounded,
      label: 'Confirm',
      route: '/fulfillment-confirm',
      primary: true),
  RoleNavigationItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Packaging',
      route: '/fulfillment-packaging',
      primary: true),
  RoleNavigationItem(
      icon: Icons.calculate_outlined,
      activeIcon: Icons.calculate_rounded,
      label: 'Calculator',
      route: '/fulfillment-yield',
      primary: true),
  RoleNavigationItem(
      icon: Icons.category_outlined,
      activeIcon: Icons.category_rounded,
      label: 'Materials',
      route: '/fulfillment-materials'),
  RoleNavigationItem(
      icon: Icons.assessment_outlined,
      activeIcon: Icons.assessment_rounded,
      label: 'Reports',
      route: '/fulfillment-reports'),
  RoleNavigationItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
      route: '/fulfillment-settings'),
  RoleNavigationItem(
      icon: Icons.tune_outlined,
      activeIcon: Icons.tune_rounded,
      label: 'Catalog',
      route: '/fulfillment/packaging-catalog'),
];

const packagingNavigationItems = [
  RoleNavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Home',
      route: '/packaging-supervisor-dashboard',
      primary: true),
  RoleNavigationItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Packaging',
      route: '/package-recording',
      primary: true),
  RoleNavigationItem(
      icon: Icons.delete_outline,
      activeIcon: Icons.delete_rounded,
      label: 'Waste',
      route: '/waste-tracking',
      primary: true),
  RoleNavigationItem(
      icon: Icons.trending_up_outlined,
      activeIcon: Icons.trending_up_rounded,
      label: 'Progress',
      route: '/progress',
      primary: true),
  RoleNavigationItem(
      icon: Icons.assessment_outlined,
      activeIcon: Icons.assessment_rounded,
      label: 'Reports',
      route: '/packaging-reports'),
  RoleNavigationItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
      route: '/packaging-settings'),
];

const qualityNavigationItems = [
  RoleNavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Home',
      route: '/quality-assurance-dashboard',
      primary: true),
  RoleNavigationItem(
      icon: Icons.verified_outlined,
      activeIcon: Icons.verified_rounded,
      label: 'Inspect',
      route: '/quality-inspection',
      primary: true),
  RoleNavigationItem(
      icon: Icons.check_circle_outline,
      activeIcon: Icons.check_circle_rounded,
      label: 'Approve',
      route: '/quality-approve',
      primary: true),
  RoleNavigationItem(
      icon: Icons.cancel_outlined,
      activeIcon: Icons.cancel_rounded,
      label: 'Reject',
      route: '/quality-reject',
      primary: true),
  RoleNavigationItem(
      icon: Icons.assessment_outlined,
      activeIcon: Icons.assessment_rounded,
      label: 'Reports',
      route: '/quality-reports'),
  RoleNavigationItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
      route: '/quality-settings'),
];

const salesManagerNavigationItems = [
  RoleNavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Home',
      route: '/sales_dashboard',
      primary: true),
  RoleNavigationItem(
      icon: Icons.people_outlined,
      activeIcon: Icons.people_rounded,
      label: 'Buyers',
      route: '/sales-off-takers',
      primary: true),
  RoleNavigationItem(
      icon: Icons.trending_up_outlined,
      activeIcon: Icons.trending_up_rounded,
      label: 'Growth',
      route: '/sales-performance',
      primary: true),
  RoleNavigationItem(
      icon: Icons.local_shipping_outlined,
      activeIcon: Icons.local_shipping_rounded,
      label: 'Delivery',
      route: '/sales-deliveries',
      primary: true),
  RoleNavigationItem(
      icon: Icons.price_change_outlined,
      activeIcon: Icons.price_change_rounded,
      label: 'Pricing',
      route: '/sales-pricing',
      primary: true),
  RoleNavigationItem(
      icon: Icons.attach_money_outlined,
      activeIcon: Icons.attach_money_rounded,
      label: 'Financial',
      route: '/sales-financial'),
  RoleNavigationItem(
      icon: Icons.assessment_outlined,
      activeIcon: Icons.assessment_rounded,
      label: 'Reports',
      route: '/sales-reports'),
  RoleNavigationItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
      route: '/sales-settings'),
];

const salesPersonnelNavigationItems = [
  RoleNavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Home',
      route: '/sales-personnel-dashboard',
      primary: true),
  RoleNavigationItem(
      icon: Icons.local_shipping_outlined,
      activeIcon: Icons.local_shipping_rounded,
      label: 'Deliver',
      route: '/sales-personnel-record-delivery',
      primary: true),
  RoleNavigationItem(
      icon: Icons.timeline_outlined,
      activeIcon: Icons.timeline_rounded,
      label: 'Pipeline',
      route: '/sales-personnel-pipeline',
      primary: true),
  RoleNavigationItem(
      icon: Icons.payments_outlined,
      activeIcon: Icons.payments_rounded,
      label: 'Sales',
      route: '/sales-personnel-sales',
      primary: true),
  RoleNavigationItem(
      icon: Icons.assessment_outlined,
      activeIcon: Icons.assessment_rounded,
      label: 'Reports',
      route: '/sales-personnel-reports',
      primary: true),
];

const driverNavigationItems = [
  RoleNavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Home',
      route: '/driver_dashboard',
      primary: true),
  RoleNavigationItem(
      icon: Icons.local_shipping_outlined,
      activeIcon: Icons.local_shipping_rounded,
      label: 'Deliveries',
      route: '/driver-deliveries',
      primary: true),
  RoleNavigationItem(
      icon: Icons.history_outlined,
      activeIcon: Icons.history_rounded,
      label: 'History',
      route: '/driver-history',
      primary: true),
];

const accountantNavigationItems = [
  RoleNavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Home',
      route: '/accountant-dashboard',
      primary: true),
  RoleNavigationItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Ledger',
      route: '/accountant-transactions',
      primary: true),
  RoleNavigationItem(
      icon: Icons.account_balance_outlined,
      activeIcon: Icons.account_balance_rounded,
      label: 'Bank',
      route: '/accountant-reconciliation',
      primary: true),
  RoleNavigationItem(
      icon: Icons.approval_outlined,
      activeIcon: Icons.approval_rounded,
      label: 'Approvals',
      route: '/accountant-approvals',
      primary: true),
  RoleNavigationItem(
      icon: Icons.assessment_outlined,
      activeIcon: Icons.assessment_rounded,
      label: 'Reports',
      route: '/accountant-reports'),
];
