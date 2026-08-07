import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sales_manager_header.dart';
import '../../core/widgets/sales_manager_sidebar.dart';
import '../../core/widgets/role_mobile_navigation.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Sales Manager Dashboard - Redesigned
class SalesManagerDashboardRedesigned extends ConsumerStatefulWidget {
  const SalesManagerDashboardRedesigned({super.key});

  @override
  ConsumerState<SalesManagerDashboardRedesigned> createState() =>
      _SalesManagerDashboardRedesignedState();
}

class _SalesManagerDashboardRedesignedState
    extends ConsumerState<SalesManagerDashboardRedesigned> {
  int _selectedNavIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _api = SuperAdminApiService();
  WeatherInfo? _weatherInfo;
  bool _isLoading = true;
  String? _loadError;
  List<Map<String, dynamic>> _sales = const [];
  List<Map<String, dynamic>> _offTakers = const [];

  @override
  void initState() {
    super.initState();
    _weatherInfo = const WeatherInfo(condition: 'Sunny', temperature: 28.5);
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final sales = await _api.getSales();
      final offTakers = await _api.getOffTakers();
      if (!mounted) return;
      setState(() {
        _sales = sales;
        _offTakers = offTakers;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  List<Map<String, Object>> get _pipeline {
    final validSales = _sales.where((sale) => !_isCancelled(sale)).toList();
    final revenue = validSales.fold<double>(0, (sum, sale) =>
        sum + _number(sale['total_amount']));
    final receivables = validSales.where((sale) => sale['paid'] != true).fold<double>(
        0, (sum, sale) => sum + _number(sale['total_amount']));
    final pending = _sales.where((sale) => _status(sale) == 'pending').length;
    final paidAmount = validSales.where((sale) => sale['paid'] == true).fold<double>(
        0, (sum, sale) => sum + _number(sale['total_amount']));
    final paidRate = revenue == 0 ? 0 : ((paidAmount / revenue) * 100).round();

    return [
      {
        'title': 'Off-Takers',
        'subtitle': 'Buyer accounts and sales relationships',
        'metric': '${_activeBuyerCount} active',
        'status': '${_offTakers.length} total',
        'route': '/sales-off-takers',
        'icon': Icons.people_outlined,
        'color': AppColors.primary,
      },
      {
        'title': 'Performance',
        'subtitle': 'Revenue collection and crop sales momentum',
        'metric': '$paidRate% paid',
        'status': '${_sales.length} sales',
        'route': '/sales-performance',
        'icon': Icons.trending_up_outlined,
        'color': AppColors.success,
      },
      {
        'title': 'Deliveries',
        'subtitle': 'Dispatch commitments and buyer handoff',
        'metric': '$pending pending',
        'status': '${validSales.length} valid',
        'route': '/sales-deliveries',
        'icon': Icons.local_shipping_outlined,
        'color': AppColors.warning,
      },
      {
        'title': 'Financials',
        'subtitle': 'Revenue, receivables, and payment exposure',
        'metric': _money(revenue),
        'status': '${_money(receivables)} due',
        'route': '/sales-financial',
        'icon': Icons.account_balance_wallet_outlined,
        'color': AppColors.error,
      },
    ];
  }

  List<Map<String, Object>> get _activity {
    final records = [..._sales]
      ..sort((a, b) => _dateValue(b).compareTo(_dateValue(a)));
    return records.take(3).map((sale) {
      final buyer = _text(sale['buyer_name'], fallback: 'Buyer');
      final status = _status(sale);
      final quantity = _number(sale['quantity_delivered']);
      final color = status == 'delivered'
          ? AppColors.success
          : status == 'cancelled'
              ? AppColors.error
              : AppColors.warning;
      return <String, Object>{
        'title': '$buyer sale ${_titleCase(status)}',
        'subtitle': '${_formatQuantity(quantity)} kg recorded for delivery',
        'time': _relativeTime(_dateValue(sale)),
        'color': color,
      };
    }).toList();
  }

  int get _activeBuyerCount => _offTakers
      .where((offTaker) =>
          _text(offTaker['status'], fallback: 'Active').toLowerCase() ==
          'active')
      .length;

  bool _isCancelled(Map<String, dynamic> sale) => _status(sale) == 'cancelled';

  String _status(Map<String, dynamic> sale) =>
      _text(sale['status'], fallback: 'pending').toLowerCase();

  double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  String _text(Object? value, {String fallback = ''}) {
    final text = '$value'.trim();
    return value == null || text == 'null' || text.isEmpty ? fallback : text;
  }

  DateTime _dateValue(Map<String, dynamic> sale) =>
      DateTime.tryParse(_text(sale['delivered_at'])) ??
      DateTime.tryParse(_text(sale['payment_date'])) ??
      DateTime.tryParse(_text(sale['\$createdAt'])) ??
      DateTime.fromMillisecondsSinceEpoch(0);

  String _money(double amount) {
    if (amount >= 1000000) return 'GHS ${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return 'GHS ${(amount / 1000).toStringAsFixed(1)}K';
    return 'GHS ${amount.toStringAsFixed(0)}';
  }

  String _formatQuantity(double quantity) =>
      quantity == quantity.roundToDouble()
          ? quantity.toStringAsFixed(0)
          : quantity.toStringAsFixed(1);

  String _relativeTime(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return 'No date';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hr ago';
    return '${difference.inDays} d ago';
  }

  String _titleCase(String value) => value.isEmpty
      ? value
      : '${value[0].toUpperCase()}${value.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Sales Manager';
    final userEmail = authState.user?.email ?? 'sales@farmestates.com';

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? RoleMobileDrawer(
              userName: userName,
              userEmail: userEmail,
              userRole: 'Sales Manager',
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) {
                setState(() => _selectedNavIndex = index);
              },
              items: salesManagerNavigationItems,
            )
          : null,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail),
      floatingActionButton: !isMobile
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(
                context,
                '/sales-off-takers',
              ),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.person_add_alt_outlined),
              label: const Text('Add Off-Taker'),
            )
          : null,
      bottomNavigationBar: isMobile
          ? RoleMobileBottomNav(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) {
                setState(() => _selectedNavIndex = index);
              },
              items: salesManagerNavigationItems,
            )
          : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail) {
    return Row(
      children: [
        SalesManagerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) {
            setState(() => _selectedNavIndex = index);
          },
          userName: userName,
          userEmail: userEmail,
          userRole: 'Sales Manager',
        ),
        Expanded(
          child: Column(
            children: [
              SalesManagerHeader(
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
        SalesManagerHeader(
          userName: userName,
          weatherInfo: _weatherInfo,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              92,
            ),
            child: _buildDashboardContent(isDark, true),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent(bool isDark, bool isMobile) {
    if (_isLoading) {
      return const SizedBox(
        height: 420,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return _buildLoadError(isDark);
    }

    final validSales = _sales.where((sale) => !_isCancelled(sale)).toList();
    final revenue = validSales.fold<double>(0, (sum, sale) =>
        sum + _number(sale['total_amount']));
    final paidAmount = validSales.where((sale) => sale['paid'] == true).fold<double>(
        0, (sum, sale) => sum + _number(sale['total_amount']));
    final paidRate = revenue == 0 ? 0 : ((paidAmount / revenue) * 100).round();
    final pending = _sales.where((sale) => _status(sale) == 'pending').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _SalesKpi(
              title: 'Revenue',
              value: _money(revenue),
              subtitle: '${validSales.length} valid sales',
              icon: Icons.payments_outlined,
              color: AppColors.success,
            ),
            _SalesKpi(
              title: 'Off-takers',
              value: '${_activeBuyerCount}',
              subtitle: 'Active or recorded buyers',
              icon: Icons.people_outlined,
              color: AppColors.primary,
            ),
            _SalesKpi(
              title: 'Deliveries',
              value: '$pending',
              subtitle: 'Pending dispatch',
              icon: Icons.local_shipping_outlined,
              color: AppColors.warning,
            ),
            _SalesKpi(
              title: 'Paid rate',
              value: '$paidRate%',
              subtitle: 'Collected from sales',
              icon: Icons.track_changes_outlined,
              color: AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildMainGrid(),
      ],
    );
  }

  Widget _buildLoadError(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.error.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppColors.error),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Sales data could not be loaded',
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          _MutedText('Check the API connection and try again.'),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _loadSalesData,
            icon: const Icon(Icons.refresh_outlined),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(bool isDark, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(isDark ? 0.22 : 0.14),
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
                  Icons.storefront_outlined,
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
                      'Sales Command Center',
                      style: AppTypography.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 24 : 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Manage buyer demand, revenue growth, deliveries, receivables, and sales performance.',
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
            children: [
              _HeroChip(
                  label: '$_activeBuyerCount active off-takers',
                  icon: Icons.people_outlined),
              _HeroChip(
                  label: '${_sales.where((sale) => _status(sale) == 'pending').length} deliveries pending',
                  icon: Icons.local_shipping_outlined),
              _HeroChip(
                  label: '${_money(_sales.where((sale) => !_isCancelled(sale) && sale['paid'] != true).fold<double>(0, (sum, sale) => sum + _number(sale['total_amount'])))} receivables',
                  icon: Icons.receipt_long_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainGrid() {
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
      title: 'Sales Pipeline',
      subtitle: 'Current sales health by operating area.',
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
      subtitle: 'Fast paths for sales manager work.',
      icon: Icons.bolt_outlined,
      color: AppColors.warning,
      child: Column(
        children: [
          _ActionTile(
            title: 'Add or review off-takers',
            subtitle: '${_offTakers.length} registered accounts',
            icon: Icons.people_outlined,
            color: AppColors.primary,
            route: '/sales-off-takers',
          ),
          SizedBox(height: AppSpacing.sm),
          _ActionTile(
            title: 'Check delivery commitments',
            subtitle: '${_sales.where((sale) => _status(sale) == 'pending').length} dispatches need follow-up',
            icon: Icons.local_shipping_outlined,
            color: AppColors.warning,
            route: '/sales-deliveries',
          ),
          SizedBox(height: AppSpacing.sm),
          _ActionTile(
            title: 'Review financial exposure',
            subtitle: '${_money(_sales.where((sale) => !_isCancelled(sale) && sale['paid'] != true).fold<double>(0, (sum, sale) => sum + _number(sale['total_amount'])))} receivables open',
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.success,
            route: '/sales-financial',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPanel() {
    return _DashboardPanel(
      title: 'Sales Activity',
      subtitle: 'Recent buyer, delivery, and revenue events.',
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

class _SalesKpi extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SalesKpi({
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
            _MetricBlock(
              label: 'Current metric',
              value: item['metric']! as String,
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
      width: double.infinity,
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
