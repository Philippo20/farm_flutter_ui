import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/fulfillment_manager_header.dart';
import '../../core/widgets/fulfillment_manager_mobile_bottom_nav.dart';
import '../../core/widgets/fulfillment_manager_sidebar.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../providers/auth_provider.dart';

/// Fulfillment Manager Dashboard - Redesigned
/// Command center for intake, packaging, yield, materials, and reporting.
class FulfillmentManagerDashboardRedesigned extends ConsumerStatefulWidget {
  const FulfillmentManagerDashboardRedesigned({super.key});

  @override
  ConsumerState<FulfillmentManagerDashboardRedesigned> createState() =>
      _FulfillmentManagerDashboardRedesignedState();
}

class _FulfillmentManagerDashboardRedesignedState
    extends ConsumerState<FulfillmentManagerDashboardRedesigned> {
  int _selectedNavIndex = 0;
  WeatherInfo? _weatherInfo;

  static const _pipeline = [
    {
      'title': 'Harvest Intake',
      'subtitle': '7 loads pending dock confirmation',
      'metric': '826 kg',
      'status': '3 urgent',
      'route': '/fulfillment-confirm',
      'icon': Icons.fact_check_outlined,
      'color': AppColors.warning,
    },
    {
      'title': 'Packaging Lines',
      'subtitle': '3 active lines moving confirmed loads',
      'metric': '526/hr',
      'status': '1 watch',
      'route': '/fulfillment-packaging',
      'icon': Icons.precision_manufacturing_outlined,
      'color': AppColors.success,
    },
    {
      'title': 'Yield Control',
      'subtitle': 'Recovery and waste under daily target',
      'metric': '3.5%',
      'status': '2 reviews',
      'route': '/fulfillment-yield',
      'icon': Icons.analytics_outlined,
      'color': AppColors.primary,
    },
    {
      'title': 'Materials',
      'subtitle': 'Barcode labels below safe coverage',
      'metric': '1 risk',
      'status': 'Action',
      'route': '/fulfillment-materials',
      'icon': Icons.inventory_2_outlined,
      'color': AppColors.error,
    },
  ];

  static const _activity = [
    {
      'title': 'LTC-24019 moved to packaging',
      'subtitle': 'Dock 02 confirmed 420 kg romaine lettuce',
      'time': '12 min ago',
      'color': AppColors.success,
    },
    {
      'title': 'Line B requires attention',
      'subtitle': 'Clamshell labels are close to reorder threshold',
      'time': '24 min ago',
      'color': AppColors.warning,
    },
    {
      'title': 'Yield exception created',
      'subtitle': 'Sweet Basil handling loss is above target',
      'time': '41 min ago',
      'color': AppColors.error,
    },
  ];

  @override
  void initState() {
    super.initState();
    _weatherInfo = const WeatherInfo(condition: 'Sunny', temperature: 28.5);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Fulfillment Manager';
    final userEmail = authState.user?.email ?? 'fulfillment@farmestates.com';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail),
      floatingActionButton: !isMobile
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(
                context,
                '/fulfillment-confirm',
              ),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('Confirm Harvest'),
            )
          : null,
      bottomNavigationBar: isMobile
          ? SafeArea(
              top: false,
              child: FulfillmentManagerMobileBottomNav(
                selectedIndex: _selectedNavIndex,
                onItemSelected: (index) {
                  setState(() => _selectedNavIndex = index);
                },
              ))
          : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail) {
    return Row(
      children: [
        FulfillmentManagerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) {
            setState(() => _selectedNavIndex = index);
          },
          userName: userName,
          userEmail: userEmail,
          userRole: 'Fulfillment Manager',
        ),
        Expanded(
          child: Column(
            children: [
              FulfillmentManagerHeader(
                userName: userName,
                weatherInfo: _weatherInfo,
                onNotificationTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _buildDashboardContent(isDark, false),
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
        FulfillmentManagerHeader(
          userName: userName,
          weatherInfo: _weatherInfo,
          onNotificationTap: () {},
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              96,
            ),
            child: _buildDashboardContent(isDark, true),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: const [
            _FulfillmentKpi(
              title: 'Pending harvest',
              value: '7',
              subtitle: 'Loads waiting',
              icon: Icons.pending_actions_outlined,
              color: AppColors.warning,
            ),
            _FulfillmentKpi(
              title: 'Received today',
              value: '826 kg',
              subtitle: '+12% vs yesterday',
              icon: Icons.move_to_inbox_outlined,
              color: AppColors.success,
            ),
            _FulfillmentKpi(
              title: 'Yield loss',
              value: '3.5%',
              subtitle: '29 kg waste',
              icon: Icons.trending_down_outlined,
              color: AppColors.error,
            ),
            _FulfillmentKpi(
              title: 'Material coverage',
              value: '85%',
              subtitle: '1 SKU at risk',
              icon: Icons.inventory_2_outlined,
              color: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildMainGrid(isDark),
      ],
    );
  }

  Widget _buildHero(bool isDark, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(isDark ? 0.22 : 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fulfillment Command Center',
                      style: AppTypography.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 24 : 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Control harvest intake, packaging flow, yield recovery, materials, and operational reporting.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.88),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              _HeroChip(
                  label: '3 dock lanes active', icon: Icons.warehouse_outlined),
              _HeroChip(
                  label: '4 reports ready', icon: Icons.assessment_outlined),
              _HeroChip(
                  label: '1 material risk', icon: Icons.warning_amber_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainGrid(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 980;

        if (!twoColumns) {
          return Column(
            children: [
              _buildPipelinePanel(),
              const SizedBox(height: AppSpacing.md),
              _buildActionPanel(),
              const SizedBox(height: AppSpacing.md),
              _buildActivityPanel(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildPipelinePanel()),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildActionPanel(),
                  const SizedBox(height: AppSpacing.md),
                  _buildActivityPanel(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPipelinePanel() {
    return _DashboardPanel(
      title: 'Fulfillment Pipeline',
      subtitle: 'Current operational health across the chain.',
      icon: Icons.account_tree_outlined,
      color: AppColors.primary,
      child: _ResponsiveGrid(
        itemCount: _pipeline.length,
        itemBuilder: (index) => _PipelineCard(item: _pipeline[index]),
      ),
    );
  }

  Widget _buildActionPanel() {
    return _DashboardPanel(
      title: 'Priority Actions',
      subtitle: 'Fast paths for daily fulfillment work.',
      icon: Icons.bolt_outlined,
      color: AppColors.warning,
      child: Column(
        children: const [
          _ActionTile(
            title: 'Confirm harvest intake',
            subtitle: 'Review 7 pending loads',
            icon: Icons.fact_check_outlined,
            color: AppColors.warning,
            route: '/fulfillment-confirm',
          ),
          SizedBox(height: AppSpacing.sm),
          _ActionTile(
            title: 'Coordinate packaging',
            subtitle: 'Balance 3 active lines',
            icon: Icons.precision_manufacturing_outlined,
            color: AppColors.success,
            route: '/fulfillment-packaging',
          ),
          SizedBox(height: AppSpacing.sm),
          _ActionTile(
            title: 'Open reports',
            subtitle: 'Review exceptions and exports',
            icon: Icons.assessment_outlined,
            color: AppColors.primary,
            route: '/fulfillment-reports',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPanel() {
    return _DashboardPanel(
      title: 'Fulfillment Activity',
      subtitle: 'Recent chain events and exceptions.',
      icon: Icons.history_outlined,
      color: AppColors.success,
      child: Column(
        children: _activity
            .map((activity) => _ActivityRow(activity: activity))
            .toList(),
      ),
    );
  }
}

class _FulfillmentKpi extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _FulfillmentKpi({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width =
        MediaQuery.of(context).size.width < 600 ? double.infinity : 230.0;

    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(isDark ? 0.26 : 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _IconBox(icon: icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MutedText(title),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.h5.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                _MutedText(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  const _DashboardPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(isDark ? 0.24 : 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.14 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBox(icon: icon, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _MutedText(subtitle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(int index) itemBuilder;

  const _ResponsiveGrid({
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 230,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (context, index) => itemBuilder(index),
        );
      },
    );
  }
}

class _PipelineCard extends StatelessWidget {
  final Map<String, Object> item;

  const _PipelineCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = item['color']! as Color;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, item['route']! as String),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: color.withOpacity(isDark ? 0.28 : 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBox(icon: item['icon']! as IconData, color: color),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']! as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h6.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['subtitle']! as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color:
                              isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(label: item['status']! as String, color: color),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _MetricBlock(
                    label: 'Current metric',
                    value: item['metric']! as String,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? Colors.white10 : AppColors.neutral200,
          ),
        ),
        child: Row(
          children: [
            _IconBox(icon: icon, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _MutedText(subtitle),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final Map<String, Object> activity;

  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = activity['color']! as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title']! as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                _MutedText(activity['subtitle']! as String),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _MutedText(activity['time']! as String),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final String label;
  final String value;

  const _MetricBlock({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MutedText(label),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeroChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 136),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  final String text;

  const _MutedText(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.caption.copyWith(
        color: isDark ? Colors.white60 : AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
