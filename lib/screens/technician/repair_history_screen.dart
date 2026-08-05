import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/technician_header.dart';
import '../../core/widgets/technician_mobile_bottom_nav.dart';
import '../../core/widgets/technician_sidebar.dart';
import '../../core/widgets/role_mobile_navigation.dart';
import '../../providers/auth_provider.dart';

class RepairHistoryScreen extends ConsumerStatefulWidget {
  const RepairHistoryScreen({super.key});

  @override
  ConsumerState<RepairHistoryScreen> createState() =>
      _RepairHistoryScreenState();
}

class _RepairHistoryScreenState extends ConsumerState<RepairHistoryScreen> {
  int _selectedNavIndex = 3;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _repairs = [
    {
      'asset': 'Irrigation Pump A2',
      'issue': 'Pressure drop and intermittent stoppage',
      'status': 'Resolved',
      'date': '2026-04-27',
      'technician': 'Kwame Mensah',
      'cost': 'GHS 420',
      'priority': 'High',
      'color': AppColors.error,
    },
    {
      'asset': 'North Greenhouse Sensor Rack',
      'issue': 'Faulty humidity probe replaced and recalibrated',
      'status': 'Resolved',
      'date': '2026-04-25',
      'technician': 'Abena Owusu',
      'cost': 'GHS 180',
      'priority': 'Medium',
      'color': AppColors.info,
    },
    {
      'asset': 'Ventilation Fan F4',
      'issue': 'Bearing wear detected during preventive inspection',
      'status': 'Monitoring',
      'date': '2026-04-22',
      'technician': 'Kojo Asare',
      'cost': 'GHS 95',
      'priority': 'Medium',
      'color': AppColors.warning,
    },
    {
      'asset': 'Nutrient Doser Line 3',
      'issue': 'Valve seal replaced and flow stabilized',
      'status': 'Resolved',
      'date': '2026-04-18',
      'technician': 'Kwame Mensah',
      'cost': 'GHS 250',
      'priority': 'High',
      'color': AppColors.success,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Technician';
    final userEmail = authState.user?.email ?? 'technician@farmestates.com';

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? RoleMobileDrawer(
              userName: userName,
              userEmail: userEmail,
              userRole: 'Technician',
              selectedIndex: _selectedNavIndex,
              onItemSelected: (_) {},
              items: technicianNavigationItems,
            )
          : null,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail),
      bottomNavigationBar: isMobile
          ? TechnicianMobileBottomNav(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
            )
          : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail) {
    return Row(
      children: [
        TechnicianSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) => setState(() => _selectedNavIndex = index),
          userName: userName,
          userEmail: userEmail,
          userRole: 'Technician',
        ),
        Expanded(
          child: Column(
            children: [
              TechnicianHeader(userName: userName, onNotificationTap: () {}),
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
        TechnicianHeader(
          userName: userName,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              100,
            ),
            child: _buildContent(isDark, true),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark, bool isMobile) {
    final filteredRepairs = _selectedFilter == 'All'
        ? _repairs
        : _repairs.where((item) => item['status'] == _selectedFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderCard(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        _buildFilterChips(isDark),
        const SizedBox(height: AppSpacing.md),
        ...filteredRepairs.map((repair) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _buildRepairCard(repair, isDark, isMobile),
            )),
      ],
    );
  }

  Widget _buildHeaderCard(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.warning.withOpacity(0.22), AppColors.surfaceDark]
              : [AppColors.warning.withOpacity(0.12), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.warning.withOpacity(isDark ? 0.3 : 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Repair History',
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: isMobile ? 24 : 28,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Review completed repairs, maintenance cost, and technician notes across farm assets.',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _buildMetricChip('Resolved', '3', AppColors.success, isDark),
              const SizedBox(width: AppSpacing.sm),
              _buildMetricChip('Monitoring', '1', AppColors.warning, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(
      String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: AppTypography.bodyLarge.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              )),
          Text(label,
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    const filters = ['All', 'Resolved', 'Monitoring'];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: filters.map((filter) {
        final isSelected = _selectedFilter == filter;
        return ChoiceChip(
          label: Text(filter),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedFilter = filter),
          selectedColor: AppColors.primary.withOpacity(0.18),
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          labelStyle: AppTypography.bodySmall.copyWith(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white : AppColors.textPrimary),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
          side: BorderSide(
            color: isSelected
                ? AppColors.primary.withOpacity(0.35)
                : (isDark ? Colors.white12 : AppColors.neutral200),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRepairCard(
    Map<String, dynamic> repair,
    bool isDark,
    bool isMobile,
  ) {
    final color = repair['color'] as Color;

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child:
                    Icon(Icons.build_circle_outlined, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repair['asset'] as String,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      repair['issue'] as String,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  repair['status'] as String,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _buildDetail('Date', repair['date'] as String, isDark),
              _buildDetail(
                  'Technician', repair['technician'] as String, isDark),
              _buildDetail('Priority', repair['priority'] as String, isDark),
              _buildDetail('Cost', repair['cost'] as String, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isDark ? Colors.white60 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
