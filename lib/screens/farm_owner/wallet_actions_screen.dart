import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_owner_header.dart';
import '../../core/widgets/farm_owner_mobile_drawer.dart';
import '../../core/widgets/farm_owner_sidebar.dart';
import '../../providers/auth_provider.dart';

class WalletActionsScreen extends ConsumerStatefulWidget {
  const WalletActionsScreen({super.key});

  @override
  ConsumerState<WalletActionsScreen> createState() =>
      _WalletActionsScreenState();
}

class _WalletActionsScreenState extends ConsumerState<WalletActionsScreen> {
  int _selectedNavIndex = 2;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Farm Owner';
    final userEmail = authState.user?.email ?? 'owner@farmestates.com';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? FarmOwnerMobileDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (i) => setState(() => _selectedNavIndex = i),
              userName: userName,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail),
      bottomNavigationBar: isMobile
          ? SafeArea(top: false, child: _buildBottomNavigation(isDark))
          : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail) {
    return Row(
      children: [
        FarmOwnerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) => setState(() => _selectedNavIndex = index),
          userName: userName,
          userEmail: userEmail,
          userRole: 'Farm Owner',
        ),
        Expanded(
          child: Column(
            children: [
              FarmOwnerHeader(
                userName: userName,
                onNotificationTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _buildContent(isDark, false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark, String userName) {
    return Column(
      children: [
        FarmOwnerHeader(
          userName: userName,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md + MediaQuery.of(context).padding.bottom + 72,
            ),
            child: _buildContent(isDark, true),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wallet Actions',
          style: AppTypography.h4.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Run payout actions and review wallet operations.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white60 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildActionCard(
          isDark,
          title: 'Withdraw Funds',
          subtitle: 'Create a payout request to a bank account',
          icon: Icons.payments_outlined,
          color: AppColors.primary,
          onTap: () => _navigate('/farm-owner/digital-wallet'),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildActionCard(
          isDark,
          title: 'Payout History',
          subtitle: 'Check completed and pending wallet debits',
          icon: Icons.history_rounded,
          color: AppColors.info,
          onTap: () => _navigate('/farm-owner/digital-wallet'),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildActionCard(
          isDark,
          title: 'Export Transactions',
          subtitle: 'Download wallet activity for accounting',
          icon: Icons.download_rounded,
          color: AppColors.success,
          onTap: () => _navigate('/farm-owner/digital-wallet'),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    bool isDark, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(String route) {
    try {
      Navigator.pushNamed(context, route);
    } catch (e) {
      debugPrint('Wallet action navigation error: $e');
    }
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/farm-owner'
      },
      {
        'icon': Icons.agriculture_outlined,
        'label': 'Farm',
        'index': 1,
        'route': '/farm-owner/farm'
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'Wallet',
        'index': 2,
        'route': '/farm-owner/digital-wallet'
      },
      {
        'icon': Icons.analytics_outlined,
        'label': 'Analytics',
        'index': 3,
        'route': '/farm-owner/analytics'
      },
      {
        'icon': Icons.assessment_outlined,
        'label': 'Reports',
        'index': 4,
        'route': '/farm-owner/reports'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            children: navItems.map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final selected = index == _selectedNavIndex;
              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (_selectedNavIndex != index) {
                      setState(() => _selectedNavIndex = index);
                      _navigate(route);
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 22,
                        color: selected
                            ? AppColors.primary
                            : (isDark
                                ? Colors.white.withOpacity(0.5)
                                : AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'] as String,
                        style: AppTypography.caption.copyWith(
                          color: selected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : AppColors.textSecondary),
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
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
