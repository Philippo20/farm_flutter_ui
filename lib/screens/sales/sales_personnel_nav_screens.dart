import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sales_personnel_screen_shell.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

String _saleStatus(Map<String, dynamic> sale) =>
    '${sale['status'] ?? 'Pending'}'.toLowerCase();

String _saleNumber(Object? value) {
  final number = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  return number == number.roundToDouble()
      ? number.toStringAsFixed(0)
      : number.toStringAsFixed(1);
}

class SalesPersonnelRecordDeliveryScreen extends ConsumerStatefulWidget {
  const SalesPersonnelRecordDeliveryScreen({super.key});

  @override
  ConsumerState<SalesPersonnelRecordDeliveryScreen> createState() =>
      _SalesPersonnelRecordDeliveryScreenState();
}

class _SalesPersonnelRecordDeliveryScreenState
    extends ConsumerState<SalesPersonnelRecordDeliveryScreen> {
  final _api = SuperAdminApiService();
  List<Map<String, dynamic>> _sales = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final allSales = await _api.getSales();
      final user = ref.read(authProvider).user;
      final identity = {user?.id ?? '', user?.email ?? '', user?.name ?? ''}
        ..removeWhere((value) => value.trim().isEmpty);
      final sales = allSales
          .where((sale) => identity.contains('${sale['created_by'] ?? ''}'))
          .toList();
      if (!mounted) return;
      setState(() {
        _sales = sales;
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

  @override
  Widget build(BuildContext context) {
    if (_loading || _error != null) {
      return SalesPersonnelScreenShell(
        selectedIndex: 1,
        child: Center(
          child: _error == null
              ? const CircularProgressIndicator()
              : OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Retry loading deliveries'),
                ),
        ),
      );
    }

    final pending = _sales.where((sale) => _saleStatus(sale) == 'pending').length;
    final cards = _sales.map<Map<String, Object>>((sale) {
      final status = '${sale['status'] ?? 'Pending'}';
      final color = status == 'Delivered' ? AppColors.success : AppColors.warning;
      return {
        'title': '${sale['buyer_name'] ?? 'Buyer'}',
        'subtitle': '${sale['batch_id'] ?? 'Batch'} | ${_saleNumber(sale['quantity_delivered'])} kg',
        'metric': '${sale['delivered_at'] ?? sale['payment_date'] ?? 'No date'}'.split('T').first,
        'status': status,
        'color': color,
      };
    }).toList();

    return _SalesPersonnelPage(
      selectedIndex: 1,
      title: 'Record Delivery',
      subtitle:
          'Capture delivery proof, buyer handoff notes, quantities delivered, and exception details.',
      icon: Icons.local_shipping_outlined,
      colors: const [Color(0xFF1D4ED8), Color(0xFF0F766E)],
      kpis: [
        _KpiData('Pending', '$pending', 'Awaiting completion', Icons.today_outlined,
            AppColors.primary),
        _KpiData('Completed', '${_sales.where((sale) => _saleStatus(sale) == 'delivered').length}', 'Backend sales records', Icons.task_alt_outlined,
            AppColors.success),
        _KpiData('Exceptions', '${_sales.where((sale) => _saleStatus(sale) == 'cancelled').length}', 'Cancelled records',
            Icons.report_problem_outlined, AppColors.warning),
      ],
      sectionTitle: 'Delivery Queue',
      cards: cards,
    );
  }
}

class SalesPersonnelPipelineScreen extends StatelessWidget {
  const SalesPersonnelPipelineScreen({super.key});

  static const _stages = [
    {
      'stage': 'Qualification',
      'count': '2 deals',
      'value': 'GHS 17K',
      'color': AppColors.primary,
      'deals': [
        {
          'buyer': 'Urban Kitchens',
          'crop': 'Basil, lettuce weekly supply',
          'value': 'GHS 9K',
          'probability': 35,
          'close': 'May 22',
          'next': 'Confirm volume requirement',
          'ownerNote': 'New hospitality lead',
          'temperature': 'Warm',
        },
        {
          'buyer': 'Sunrise Cafeteria',
          'crop': 'Mixed greens subscription',
          'value': 'GHS 8K',
          'probability': 30,
          'close': 'May 27',
          'next': 'Send product catalogue',
          'ownerNote': 'Needs pricing sheet',
          'temperature': 'New',
        },
      ],
    },
    {
      'stage': 'Proposal',
      'count': '2 deals',
      'value': 'GHS 31K',
      'color': AppColors.warning,
      'deals': [
        {
          'buyer': 'Green Market Co',
          'crop': 'Tomato and herb package',
          'value': 'GHS 18K',
          'probability': 55,
          'close': 'May 20',
          'next': 'Review delivery frequency',
          'ownerNote': 'Proposal sent yesterday',
          'temperature': 'Hot',
        },
        {
          'buyer': 'North Ridge Grocers',
          'crop': 'Romaine lettuce contract',
          'value': 'GHS 13K',
          'probability': 50,
          'close': 'May 25',
          'next': 'Confirm credit terms',
          'ownerNote': 'Waiting on finance contact',
          'temperature': 'Warm',
        },
      ],
    },
    {
      'stage': 'Negotiation',
      'count': '1 deal',
      'value': 'GHS 24K',
      'color': AppColors.error,
      'deals': [
        {
          'buyer': 'Organic Plus',
          'crop': 'Premium vegetable supply',
          'value': 'GHS 24K',
          'probability': 72,
          'close': 'May 18',
          'next': 'Resolve final pricing',
          'ownerNote': 'Decision maker engaged',
          'temperature': 'Hot',
        },
      ],
    },
    {
      'stage': 'Closing',
      'count': '1 deal',
      'value': 'GHS 16K',
      'color': AppColors.success,
      'deals': [
        {
          'buyer': 'FreshPlate Foods',
          'crop': 'Restaurant produce bundle',
          'value': 'GHS 16K',
          'probability': 88,
          'close': 'May 16',
          'next': 'Collect signed PO',
          'ownerNote': 'Verbal approval received',
          'temperature': 'Commit',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SalesPersonnelScreenShell(
      selectedIndex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Hero(
            title: 'Sales Pipeline',
            subtitle:
                'Manage every off-taker opportunity by stage, probability, value, next action, and expected close date.',
            icon: Icons.account_tree_outlined,
            colors: [Color(0xFF166534), Color(0xFF0F766E)],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: const [
              _KpiCard(
                data: _KpiData(
                  'Open pipeline',
                  'GHS 88K',
                  '6 active deals',
                  Icons.account_balance_wallet_outlined,
                  AppColors.primary,
                ),
              ),
              _KpiCard(
                data: _KpiData(
                  'Weighted value',
                  'GHS 51K',
                  'Probability adjusted',
                  Icons.trending_up_outlined,
                  AppColors.success,
                ),
              ),
              _KpiCard(
                data: _KpiData(
                  'Closing soon',
                  '2',
                  'Due this week',
                  Icons.flag_outlined,
                  AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Pipeline Board',
                style: AppTypography.h5.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _PipelineSummaryChip(
                label: 'Next follow-up',
                value: 'Today, 3:30 PM',
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _PipelineBoard(stages: _stages),
        ],
      ),
    );
  }
}

class SalesPersonnelMySalesScreen extends ConsumerStatefulWidget {
  const SalesPersonnelMySalesScreen({super.key});

  @override
  ConsumerState<SalesPersonnelMySalesScreen> createState() =>
      _SalesPersonnelMySalesScreenState();
}

class _SalesPersonnelMySalesScreenState
    extends ConsumerState<SalesPersonnelMySalesScreen> {
  final _api = SuperAdminApiService();
  List<Map<String, Object>> _sales = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final allSales = await _api.getSales();
      final user = ref.read(authProvider).user;
      final identity = {user?.id ?? '', user?.email ?? '', user?.name ?? ''}
        ..removeWhere((value) => value.trim().isEmpty);
      final records = allSales.where((sale) {
        return identity.contains('${sale['created_by'] ?? ''}');
      }).map<Map<String, Object>>(_mapSale).toList();
      if (!mounted) return;
      setState(() {
        _sales = records;
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

  Map<String, Object> _mapSale(Map<String, dynamic> sale) {
    final paid = sale['paid'] == true;
    final status = '${sale['status'] ?? 'Pending'}';
    final amount = _number(sale['total_amount']);
    return {
      'invoice': '${sale['receipt_number'] ?? sale['\$id'] ?? 'Sale'}',
      'buyer': '${sale['buyer_name'] ?? 'Buyer'}',
      'crop': '${sale['batch_id'] ?? 'Batch'}',
      'quantity': '${_number(sale['quantity_delivered'])} kg',
      'amount': _money(amount),
      'payment': paid ? 'Collected' : 'Due',
      'delivery': status,
      'date': '${sale['delivered_at'] ?? sale['payment_date'] ?? 'No date'}'.split('T').first,
      'margin': 'N/A',
      'color': paid ? AppColors.success : AppColors.warning,
    };
  }

  double _number(Object? value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  String _money(double value) => value >= 1000
      ? 'GHS ${(value / 1000).toStringAsFixed(1)}K'
      : 'GHS ${value.toStringAsFixed(0)}';

  double get _gross => _sales.fold<double>(0, (sum, sale) {
    final value = '${sale['amount']}'.replaceAll('GHS ', '').replaceAll('K', '');
    return sum + (double.tryParse(value) ?? 0) * (sale['amount'].toString().contains('K') ? 1000 : 1);
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading || _error != null) {
      return SalesPersonnelScreenShell(
        selectedIndex: 3,
        child: Center(
          child: _error == null
              ? const CircularProgressIndicator()
              : OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Retry loading my sales'),
                ),
        ),
      );
    }

    final collected = _sales.where((sale) => sale['payment'] == 'Collected').length;
    final receivables = _sales.length - collected;

    return SalesPersonnelScreenShell(
      selectedIndex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Hero(
            title: 'My Sales Ledger',
            subtitle:
                'Track personal revenue, buyer orders, payment collection, delivery status, and sale margins.',
            icon: Icons.payments_outlined,
            colors: [Color(0xFF7C2D12), Color(0xFFEA580C)],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _KpiCard(
                data: _KpiData(
                  'Gross sales',
                  _money(_gross),
                  '${_sales.length} backend records',
                  Icons.payments_outlined,
                  AppColors.success,
                ),
              ),
              _KpiCard(
                data: _KpiData(
                  'Collected',
                  '${_money(collected == 0 ? 0 : _gross * collected / _sales.length)}',
                  '$collected collected records',
                  Icons.account_balance_wallet_outlined,
                  AppColors.primary,
                ),
              ),
              _KpiCard(
                data: _KpiData(
                  'Receivables',
                  '$receivables open',
                  'Unpaid sales records',
                  Icons.receipt_long_outlined,
                  AppColors.warning,
                ),
              ),
              _KpiCard(
                data: _KpiData(
                  'Avg margin',
                  'N/A',
                  'Margin not stored in Sales schema',
                  Icons.trending_up_outlined,
                  AppColors.error,
                ),
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
                    _SalesCollectionPanel(sales: _sales),
                    const SizedBox(height: AppSpacing.md),
                    _SalesPerformanceNotesSection(),
                    const SizedBox(height: AppSpacing.md),
                    _SalesLedgerPanel(sales: _sales),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SalesCollectionPanel(sales: _sales),
                        const SizedBox(height: AppSpacing.md),
                        _SalesPerformanceNotesSection(),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(flex: 3, child: _SalesLedgerPanel(sales: _sales)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class SalesPersonnelExpensesScreen extends StatelessWidget {
  const SalesPersonnelExpensesScreen({super.key});

  static const _cards = [
    {
      'title': 'Expense Tracking Unavailable',
      'subtitle': 'The backend has no expense collection yet',
      'metric': 'N/A',
      'status': 'Not connected',
      'color': AppColors.primary,
    },
    {
      'title': 'Receipt Sync',
      'subtitle': 'Waiting for the expense API and schema',
      'metric': 'N/A',
      'status': 'Not connected',
      'color': AppColors.warning,
    },
    {
      'title': 'Accountant Handoff',
      'subtitle': 'No expense records available to sync',
      'metric': 'N/A',
      'status': 'Not connected',
      'color': AppColors.success,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _SalesPersonnelPage(
      selectedIndex: 5,
      title: 'Expense Tracking',
      subtitle:
          'Log field expenses, attach receipts, and keep accountant sync ready.',
      icon: Icons.receipt_long_outlined,
      colors: const [Color(0xFF334155), Color(0xFF1D4ED8)],
      kpis: const [
        _KpiData('Submitted', 'N/A', 'Expense API not available',
            Icons.receipt_long_outlined, AppColors.primary),
        _KpiData('Approved', 'N/A', 'Expense API not available',
            Icons.verified_outlined, AppColors.success),
        _KpiData('Pending', 'N/A', 'Expense API not available', Icons.schedule_outlined,
            AppColors.warning),
      ],
      sectionTitle: 'Expense Records',
      cards: _cards,
    );
  }
}

class SalesPersonnelReportsScreen extends ConsumerStatefulWidget {
  const SalesPersonnelReportsScreen({super.key});

  @override
  ConsumerState<SalesPersonnelReportsScreen> createState() =>
      _SalesPersonnelReportsScreenState();
}

class _SalesPersonnelReportsScreenState
    extends ConsumerState<SalesPersonnelReportsScreen> {
  final _api = SuperAdminApiService();
  List<Map<String, dynamic>> _sales = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final allSales = await _api.getSales();
      final user = ref.read(authProvider).user;
      final identity = {user?.id ?? '', user?.email ?? '', user?.name ?? ''}
        ..removeWhere((value) => value.trim().isEmpty);
      final sales = allSales
          .where((sale) => identity.contains('${sale['created_by'] ?? ''}'))
          .toList();
      if (!mounted) return;
      setState(() {
        _sales = sales;
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

  @override
  Widget build(BuildContext context) {
    if (_loading || _error != null) {
      return SalesPersonnelScreenShell(
        selectedIndex: 4,
        child: Center(
          child: _error == null
              ? const CircularProgressIndicator()
              : OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Retry loading reports'),
                ),
        ),
      );
    }

    final revenue = _sales.fold<double>(0, (sum, sale) {
      final amount = sale['total_amount'];
      return sum + (amount is num ? amount.toDouble() : 0);
    });
    final revenueLabel = revenue >= 1000
        ? 'GHS ${(revenue / 1000).toStringAsFixed(1)}K'
        : 'GHS ${revenue.toStringAsFixed(0)}';
    final cards = <Map<String, Object>>[
      {
        'title': 'Daily Delivery Summary',
        'subtitle': 'Backend delivery status and quantities',
        'metric': '${_sales.length} records',
        'status': 'Live',
        'color': AppColors.primary,
      },
      {
        'title': 'Personal Sales Report',
        'subtitle': 'Revenue by buyer and sales record',
        'metric': revenueLabel,
        'status': 'Live',
        'color': AppColors.success,
      },
      {
        'title': 'Expense Sync Report',
        'subtitle': 'Expense data is not available in the backend yet',
        'metric': 'N/A',
        'status': 'Unavailable',
        'color': AppColors.warning,
      },
    ];

    return _SalesPersonnelPage(
      selectedIndex: 4,
      title: 'Sales Reports',
      subtitle:
          'Generate personal sales, delivery, expense, and pipeline summaries.',
      icon: Icons.assessment_outlined,
      colors: const [Color(0xFF1E3A8A), Color(0xFF0F766E)],
      kpis: [
        _KpiData('Sales records', '${_sales.length}', 'From backend', Icons.assessment_outlined,
            AppColors.primary),
        _KpiData('Revenue', revenueLabel, 'Personal records', Icons.file_download_outlined,
            AppColors.success),
        _KpiData('Unpaid', '${_sales.where((sale) => sale['paid'] != true).length}', 'Needs collection',
            Icons.report_problem_outlined, AppColors.warning),
      ],
      sectionTitle: 'Report Library',
      cards: cards,
    );
  }
}

class SalesPersonnelSettingsScreen extends StatelessWidget {
  const SalesPersonnelSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SalesPersonnelScreenShell(
      selectedIndex: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Hero(
            title: 'Sales Personnel Settings',
            subtitle:
                'Manage delivery alerts, proof requirements, expense sync, and sales reminders.',
            icon: Icons.settings_outlined,
            colors: [Color(0xFF334155), Color(0xFF475569)],
          ),
          SizedBox(height: AppSpacing.lg),
          _SettingsPanel(),
        ],
      ),
    );
  }
}

class _SalesPersonnelPage extends StatelessWidget {
  final int selectedIndex;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final List<_KpiData> kpis;
  final String sectionTitle;
  final List<Map<String, Object>> cards;

  const _SalesPersonnelPage({
    required this.selectedIndex,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.kpis,
    required this.sectionTitle,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SalesPersonnelScreenShell(
      selectedIndex: selectedIndex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Hero(title: title, subtitle: subtitle, icon: icon, colors: colors),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: kpis.map((kpi) => _KpiCard(data: kpi)).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            sectionTitle,
            style: AppTypography.h5.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ResponsiveGrid(
            itemCount: cards.length,
            itemBuilder: (index) => _SalesPersonnelCard(item: cards[index]),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  const _Hero({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 24 : 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.88),
                  ),
                ),
              ],
            ),
          ),
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
        final isMobile = MediaQuery.of(context).size.width < 600;
        final columns = constraints.maxWidth >= 820 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: isMobile ? 260 : 230,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (context, index) => itemBuilder(index),
        );
      },
    );
  }
}

class _SalesPersonnelCard extends StatelessWidget {
  final Map<String, Object> item;

  const _SalesPersonnelCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = item['color']! as Color;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        gradient: LinearGradient(
          colors: [
            isDark ? AppColors.surfaceDark : Colors.white,
            color.withOpacity(isDark ? 0.08 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(isDark ? 0.28 : 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBox(icon: Icons.assignment_outlined, color: color),
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
          _MetricPill(label: 'Metric', value: item['metric']! as String),
        ],
      ),
    );
  }
}

class _SalesCollectionPanel extends StatelessWidget {
  final List<Map<String, Object>> sales;

  const _SalesCollectionPanel({required this.sales});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double amount(Map<String, Object> sale) {
      final raw = '${sale['amount']}'.replaceAll('GHS ', '');
      final multiplier = raw.contains('K') ? 1000 : 1;
      return (double.tryParse(raw.replaceAll('K', '')) ?? 0) * multiplier;
    }

    final total = sales.fold<double>(0, (sum, sale) => sum + amount(sale));
    final collected = sales
        .where((sale) => sale['payment'] == 'Collected')
        .fold<double>(0, (sum, sale) => sum + amount(sale));
    final collectionRate = total == 0 ? 0.0 : collected / total;
    String money(double value) => value >= 1000
        ? 'GHS ${(value / 1000).toStringAsFixed(1)}K'
        : 'GHS ${value.toStringAsFixed(0)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
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
              _IconBox(
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collection Health',
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _MutedText('Payment collection across personal sales.'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _CollectionProgress(
            label: 'Collected revenue',
            value: money(collected),
            percent: collectionRate,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.md),
          _CollectionProgress(
            label: 'Open receivables',
            value: money(total - collected),
            percent: 1 - collectionRate,
            color: AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...sales.map(
            (sale) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PaymentStatusRow(sale: sale),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesLedgerPanel extends StatelessWidget {
  final List<Map<String, Object>> sales;

  const _SalesLedgerPanel({required this.sales});

  @override
  Widget build(BuildContext context) {
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
              _IconBox(
                  icon: Icons.receipt_long_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Orders',
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _MutedText(
                        'Invoice, buyer, crop, quantity, and delivery status.'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...sales.map(
            (sale) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _SaleOrderCard(sale: sale),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleOrderCard extends StatelessWidget {
  final Map<String, Object> sale;

  const _SaleOrderCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = sale['color']! as Color;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(isDark ? 0.28 : 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBox(
                  icon: Icons.shopping_cart_checkout_outlined, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale['buyer']! as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${sale['crop']} | ${sale['quantity']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: sale['payment']! as String, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _PipelineMetric(
                  label: 'Invoice',
                  value: sale['invoice']! as String,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _PipelineMetric(
                  label: 'Amount',
                  value: sale['amount']! as String,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _PipelineMetric(
                  label: 'Delivery',
                  value: sale['delivery']! as String,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _PipelineMetric(
                  label: 'Margin',
                  value: sale['margin']! as String,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionProgress extends StatelessWidget {
  final String label;
  final String value;
  final double percent;
  final Color color;

  const _CollectionProgress({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _MutedText(label)),
            Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: percent,
            backgroundColor: isDark ? Colors.white10 : AppColors.neutral200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _PaymentStatusRow extends StatelessWidget {
  final Map<String, Object> sale;

  const _PaymentStatusRow({required this.sale});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = sale['color']! as Color;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
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
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              sale['buyer']! as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            sale['amount']! as String,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesPerformanceNotesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Notes',
          style: AppTypography.h5.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _SalesInsightCard(),
      ],
    );
  }
}

class _SalesInsightCard extends StatelessWidget {
  const _SalesInsightCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.primary.withOpacity(isDark ? 0.28 : 0.16),
        ),
      ),
      child: Row(
        children: [
          _IconBox(icon: Icons.insights_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Focus on collecting Green Basket and North Ridge balances before opening new credit sales. FreshMart remains the strongest margin account this week.',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineBoard extends StatelessWidget {
  final List<Map<String, Object>> stages;

  const _PipelineBoard({required this.stages});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000;

        if (!isDesktop) {
          return Column(
            children: stages
                .map(
                  (stage) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _PipelineStage(stage: stage),
                  ),
                )
                .toList(),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: stages
                .map(
                  (stage) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: SizedBox(
                      width: 320,
                      child: _PipelineStage(stage: stage),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _PipelineStage extends StatelessWidget {
  final Map<String, Object> stage;

  const _PipelineStage({required this.stage});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = stage['color']! as Color;
    final deals = stage['deals']! as List<Map<String, Object>>;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(isDark ? 0.28 : 0.18)),
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
              Container(
                width: 10,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage['stage']! as String,
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _MutedText('${stage['count']} | ${stage['value']}'),
                  ],
                ),
              ),
              _StatusBadge(label: stage['value']! as String, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...deals.map(
            (deal) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PipelineDealCard(
                deal: deal,
                color: color,
                stage: stage['stage']! as String,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineDealCard extends StatelessWidget {
  final Map<String, Object> deal;
  final Color color;
  final String stage;

  const _PipelineDealCard({
    required this.deal,
    required this.color,
    required this.stage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final probability = deal['probability']! as int;

    return InkWell(
      onTap: () => _showPipelineDealDetails(context),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deal['buyer']! as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deal['crop']! as String,
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
                const SizedBox(width: AppSpacing.sm),
                _StatusBadge(
                  label: deal['temperature']! as String,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _PipelineMetric(
                    label: 'Deal value',
                    value: deal['value']! as String,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PipelineMetric(
                    label: 'Close date',
                    value: deal['close']! as String,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: probability / 100,
                      backgroundColor:
                          isDark ? Colors.white10 : AppColors.neutral200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$probability%',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _PipelineNextAction(
              title: deal['next']! as String,
              note: deal['ownerNote']! as String,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  void _showPipelineDealDetails(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 760;

    if (isDesktop) {
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.16),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: _PipelineDealDetailsContent(
                  deal: deal,
                  stage: stage,
                  color: color,
                  showHandle: false,
                ),
              ),
            ),
          );
        },
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PipelineDealDetailsSheet(
          deal: deal,
          stage: stage,
          color: color,
        );
      },
    );
  }
}

class _PipelineDealDetailsSheet extends StatelessWidget {
  final Map<String, Object> deal;
  final String stage;
  final Color color;

  const _PipelineDealDetailsSheet({
    required this.deal,
    required this.stage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.48,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
          child: _PipelineDealDetailsContent(
            deal: deal,
            stage: stage,
            color: color,
            scrollController: scrollController,
          ),
        );
      },
    );
  }
}

class _PipelineDealDetailsContent extends StatelessWidget {
  final Map<String, Object> deal;
  final String stage;
  final Color color;
  final ScrollController? scrollController;
  final bool showHandle;

  const _PipelineDealDetailsContent({
    required this.deal,
    required this.stage,
    required this.color,
    this.scrollController,
    this.showHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final probability = deal['probability']! as int;

    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        showHandle ? AppSpacing.sm : AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHandle) ...[
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.neutral300,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBox(icon: Icons.business_center_outlined, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal['buyer']! as String,
                      style: AppTypography.h5.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deal['crop']! as String,
                      style: AppTypography.bodyMedium.copyWith(
                        color:
                            isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                label: deal['temperature']! as String,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _PipelineSummaryChip(label: 'Stage', value: stage, color: color),
              _PipelineSummaryChip(
                label: 'Close',
                value: deal['close']! as String,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _PipelineMetric(
                  label: 'Deal value',
                  value: deal['value']! as String,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _PipelineMetric(
                  label: 'Probability',
                  value: '$probability%',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: probability / 100,
              backgroundColor: isDark ? Colors.white10 : AppColors.neutral200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PipelineNextAction(
            title: deal['next']! as String,
            note: deal['ownerNote']! as String,
            color: color,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Opportunity Controls',
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DealActionButton(
            icon: Icons.arrow_forward_rounded,
            label: 'Move to next stage',
            color: AppColors.primary,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DealActionButton(
            icon: Icons.event_available_outlined,
            label: 'Schedule follow-up',
            color: AppColors.warning,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DealActionButton(
            icon: Icons.check_circle_outline,
            label: 'Mark as won',
            color: AppColors.success,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _DealActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _DealActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.45)),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }
}

class _PipelineMetric extends StatelessWidget {
  final String label;
  final String value;

  const _PipelineMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.035) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MutedText(label),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineNextAction extends StatelessWidget {
  final String title;
  final String note;
  final Color color;

  const _PipelineNextAction({
    required this.title,
    required this.note,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Icon(Icons.next_plan_outlined, color: color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                _MutedText(note),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineSummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PipelineSummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_active_outlined, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiData(this.title, this.value, this.subtitle, this.icon, this.color);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;

  const _KpiCard({required this.data});

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
        border: Border.all(color: data.color.withOpacity(isDark ? 0.26 : 0.16)),
      ),
      child: Row(
        children: [
          _IconBox(icon: data.icon, color: data.color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MutedText(data.title),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  style: AppTypography.h5.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                _MutedText(data.subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SettingRow(
          title: 'Delivery proof reminders',
          subtitle: 'Prompt before handoff when image proof is missing.',
          icon: Icons.notifications_active_outlined,
          enabled: true,
        ),
        _SettingRow(
          title: 'Expense sync',
          subtitle: 'Send approved expenses to accountant review.',
          icon: Icons.sync_outlined,
          enabled: true,
        ),
        _SettingRow(
          title: 'Buyer follow-up reminders',
          subtitle: 'Create reminders for prospects and renewal accounts.',
          icon: Icons.event_note_outlined,
          enabled: false,
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;

  const _SettingRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          _IconBox(icon: icon, color: AppColors.primary),
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
          Switch(value: enabled, onChanged: (_) {}),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
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

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({required this.icon, required this.color});

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

  const _StatusBadge({required this.label, required this.color});

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
