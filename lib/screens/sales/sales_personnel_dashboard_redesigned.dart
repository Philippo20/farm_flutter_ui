import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sales_personnel_screen_shell.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

class SalesPersonnelDashboardRedesigned extends ConsumerStatefulWidget {
  const SalesPersonnelDashboardRedesigned({super.key});

  @override
  ConsumerState<SalesPersonnelDashboardRedesigned> createState() =>
      _SalesPersonnelDashboardRedesignedState();
}

class _SalesPersonnelDashboardRedesignedState
    extends ConsumerState<SalesPersonnelDashboardRedesigned> {
  final _api = SuperAdminApiService();
  List<Map<String, dynamic>> _sales = const [];
  List<Map<String, dynamic>> _offTakers = const [];
  bool _loading = true;
  String? _error;

  List<Map<String, Object>> get _workItems => [
        {
          'title': 'Record Delivery',
          'subtitle': 'Capture proof, quantity, buyer handoff, and exceptions.',
          'metric': '${_sales.where((s) => _status(s) == 'pending').length} pending',
          'status': '${_sales.length} personal sales',
          'route': '/sales-personnel-record-delivery',
          'icon': Icons.local_shipping_outlined,
          'color': AppColors.primary,
        },
        {
          'title': 'Off-Taker Pipeline',
          'subtitle': 'Follow prospects and close new buyer opportunities.',
          'metric': '${_prospectCount} prospects',
          'status': '${_activeOffTakers} active',
          'route': '/sales-personnel-pipeline',
          'icon': Icons.timeline_outlined,
          'color': AppColors.success,
        },
        {
          'title': 'My Sales',
          'subtitle': 'Track personal revenue, collections, and order value.',
          'metric': _money(_revenue),
          'status': '${_sales.length} records',
          'route': '/sales-personnel-sales',
          'icon': Icons.payments_outlined,
          'color': AppColors.warning,
        },
        {
          'title': 'Expenses',
          'subtitle': 'Log receipts and prepare accountant sync records.',
          'metric': 'No expense data',
          'status': 'Backend endpoint pending',
          'route': '/sales-personnel-expenses',
          'icon': Icons.receipt_long_outlined,
          'color': AppColors.error,
        },
      ];

  List<Map<String, Object>> get _activity {
    final records = [..._sales]
      ..sort((a, b) => _date(b).compareTo(_date(a)));
    return records.take(3).map((sale) => <String, Object>{
          'title': '${_text(sale['buyer_name'], 'Buyer')} sale ${_title(_status(sale))}',
          'subtitle': '${_number(sale['quantity_delivered'])} kg delivery record',
          'time': _relative(_date(sale)),
          'color': _status(sale) == 'delivered' ? AppColors.success : AppColors.warning,
        }).toList();
  }

  double get _revenue => _sales
      .where((sale) => _status(sale) != 'cancelled')
      .fold<double>(0, (sum, sale) => sum + _number(sale['total_amount']));

  int get _prospectCount => _offTakers
      .where((item) => _text(item['status'], 'Active').toLowerCase() == 'prospect')
      .length;

  int get _activeOffTakers => _offTakers
      .where((item) => _text(item['status'], 'Active').toLowerCase() == 'active')
      .length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final allSales = await _api.getSales();
      final offTakers = await _api.getOffTakers();
      final user = ref.read(authProvider).user;
      final identity = {user?.id ?? '', user?.email ?? '', user?.name ?? ''}
        ..removeWhere((value) => value.trim().isEmpty);
      final personalSales = allSales.where((sale) {
        final creator = _text(sale['created_by'], '');
        return identity.contains(creator);
      }).toList();
      if (!mounted) return;
      setState(() {
        _sales = personalSales;
        _offTakers = offTakers;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  String _status(Map<String, dynamic> sale) =>
      _text(sale['status'], 'Pending').toLowerCase();

  String _text(Object? value, String fallback) {
    final text = '$value'.trim();
    return value == null || text == 'null' || text.isEmpty ? fallback : text;
  }

  double _number(Object? value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  DateTime _date(Map<String, dynamic> sale) =>
      DateTime.tryParse(_text(sale['delivered_at'], '')) ??
      DateTime.tryParse(_text(sale['\$createdAt'], '')) ??
      DateTime.fromMillisecondsSinceEpoch(0);

  String _money(double value) => value >= 1000
      ? 'GHS ${(value / 1000).toStringAsFixed(1)}K'
      : 'GHS ${value.toStringAsFixed(0)}';

  String _relative(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return 'No date';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    return '${difference.inHours} hr ago';
  }

  String _title(String value) => value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SalesPersonnelScreenShell(
        selectedIndex: 0,
        child: const SizedBox(
          height: 420,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error != null) {
      return SalesPersonnelScreenShell(
        selectedIndex: 0,
        child: Center(
          child: OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_outlined),
            label: const Text('Retry loading sales data'),
          ),
        ),
      );
    }

    return SalesPersonnelScreenShell(
      selectedIndex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(context),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _KpiCard(
                title: 'Today deliveries',
                value: '${_sales.where((s) => _status(s) == 'pending').length}',
                subtitle: 'Pending sales deliveries',
                icon: Icons.local_shipping_outlined,
                color: AppColors.primary,
              ),
              _KpiCard(
                title: 'Personal sales',
                value: _money(_revenue),
                subtitle: '${_sales.length} backend records',
                icon: Icons.payments_outlined,
                color: AppColors.success,
              ),
              _KpiCard(
                title: 'Prospects',
                value: '$_prospectCount',
                subtitle: 'Off-taker records',
                icon: Icons.people_outlined,
                color: AppColors.warning,
              ),
              _KpiCard(
                title: 'Expenses',
                value: 'N/A',
                subtitle: 'No expenses endpoint',
                icon: Icons.receipt_long_outlined,
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 980;
              if (!twoColumns) {
                return Column(
                  children: [
                    _buildWorkPanel(),
                    const SizedBox(height: AppSpacing.md),
                    _buildActionsPanel(),
                    const SizedBox(height: AppSpacing.md),
                    _buildActivityPanel(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildWorkPanel()),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildActionsPanel(),
                        const SizedBox(height: AppSpacing.md),
                        _buildActivityPanel(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withOpacity(0.16),
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
                  Icons.delivery_dining_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Field Sales Workspace',
                      style: AppTypography.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 24 : 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Record deliveries, grow off-taker relationships, track personal revenue, and submit field expenses.',
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
                  label: '${_sales.where((s) => _status(s) == 'pending').length} deliveries pending',
                  icon: Icons.today_outlined),
              _HeroChip(
                  label: '$_prospectCount off-taker prospects',
                  icon: Icons.people_outlined),
              _HeroChip(
                  label: '${_money(_revenue)} personal sales',
                  icon: Icons.payments_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkPanel() {
    return _DashboardPanel(
      title: 'Today Workboard',
      subtitle: 'Primary sales personnel tasks and operating metrics.',
      icon: Icons.grid_view_outlined,
      color: AppColors.primary,
      child: _ResponsiveGrid(
        itemCount: _workItems.length,
        itemBuilder: (index) => _WorkCard(item: _workItems[index]),
      ),
    );
  }

  Widget _buildActionsPanel() {
    return _DashboardPanel(
      title: 'Fast Actions',
      subtitle: 'Complete common field sales tasks quickly.',
      icon: Icons.bolt_outlined,
      color: AppColors.warning,
      child: Column(
        children: [
          _ActionTile(
            title: 'Record delivery proof',
            subtitle: '${_sales.where((s) => _status(s) == 'pending').length} sales need delivery follow-up',
            icon: Icons.add_photo_alternate_outlined,
            color: AppColors.primary,
            route: '/sales-personnel-record-delivery',
          ),
          SizedBox(height: AppSpacing.sm),
          _ActionTile(
            title: 'Update buyer pipeline',
            subtitle: '$_prospectCount off-taker prospects',
            icon: Icons.timeline_outlined,
            color: AppColors.success,
            route: '/sales-personnel-pipeline',
          ),
          SizedBox(height: AppSpacing.sm),
          _ActionTile(
            title: 'Submit expense',
            subtitle: 'Prepare accountant sync',
            icon: Icons.receipt_long_outlined,
            color: AppColors.warning,
            route: '/sales-personnel-expenses',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPanel() {
    return _DashboardPanel(
      title: 'Recent Activity',
      subtitle: 'Delivery, sales, and expense updates.',
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

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
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

class _WorkCard extends StatelessWidget {
  final Map<String, Object> item;

  const _WorkCard({required this.item});

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
