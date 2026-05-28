import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/accountant_screen_shell.dart';

class AccountantTransactionsScreen extends StatefulWidget {
  const AccountantTransactionsScreen({super.key});

  @override
  State<AccountantTransactionsScreen> createState() =>
      _AccountantTransactionsScreenState();
}

class _AccountantTransactionsScreenState
    extends State<AccountantTransactionsScreen> {
  bool _showTable = false;

  static const _items = [
    _FinanceItem('INV-1042', 'FreshMart Retail', 'Sales receipt', 'GHS 18.4K',
        'Confirmed', AppColors.success),
    _FinanceItem('EXP-778', 'Delivery fuel claim', 'Field expense', 'GHS 420',
        'Review', AppColors.warning),
    _FinanceItem('INV-1041', 'Green Basket', 'Receivable invoice', 'GHS 13.2K',
        'Due', AppColors.error),
    _FinanceItem('REQ-221', 'Packaging supplies', 'Fund request', 'GHS 6.8K',
        'Pending', AppColors.primary),
  ];

  @override
  Widget build(BuildContext context) {
    return _AccountantPage(
      selectedIndex: 1,
      title: 'Transaction Ledger',
      subtitle:
          'Review confirmed sales, expenses, receivables, and fund movements in one ledger.',
      icon: Icons.receipt_long_outlined,
      colors: const [Color(0xFF0F766E), Color(0xFF1D4ED8)],
      kpis: const [
        _KpiData('Ledger value', 'GHS 126K', 'This month',
            Icons.account_balance_wallet_outlined, AppColors.primary),
        _KpiData('Unconfirmed', '7', 'Need accountant review',
            Icons.pending_actions_outlined, AppColors.warning),
        _KpiData('Receivables', 'GHS 37K', 'Open invoices',
            Icons.receipt_outlined, AppColors.error),
      ],
      sectionTitle: 'Recent Transactions',
      sectionAction: _ViewToggle(
        showTable: _showTable,
        onChanged: (value) => setState(() => _showTable = value),
      ),
      filters: const [
        _FilterOption('Status', 'All statuses', Icons.tune_outlined),
        _FilterOption('Type', 'Sales + expenses', Icons.category_outlined),
        _FilterOption('Period', 'This month', Icons.date_range_outlined),
      ],
      items: _items,
      content: _showTable
          ? const _FinanceTable(items: _items)
          : const _FinanceGrid(items: _items),
    );
  }
}

class AccountantReconciliationScreen extends StatelessWidget {
  const AccountantReconciliationScreen({super.key});

  static const _items = [
    _FinanceItem('BANK-901', 'FreshMart deposit', 'Matched to INV-1042',
        'GHS 18.4K', 'Matched', AppColors.success),
    _FinanceItem('BANK-897', 'Mobile money transfer', 'Missing sales reference',
        'GHS 2.1K', 'Exception', AppColors.error),
    _FinanceItem('BANK-893', 'Fuel vendor payment', 'Matched to EXP-778',
        'GHS 420', 'Matched', AppColors.success),
  ];

  @override
  Widget build(BuildContext context) {
    return _AccountantPage(
      selectedIndex: 2,
      title: 'Bank Reconciliation',
      subtitle:
          'Match bank deposits, mobile money inflows, expenses, and ledger entries.',
      icon: Icons.account_balance_outlined,
      colors: const [Color(0xFF334155), Color(0xFF0F766E)],
      kpis: const [
        _KpiData('Matched', '91%', 'Bank to ledger', Icons.check_circle_outline,
            AppColors.success),
        _KpiData('Exceptions', '3', 'Need investigation',
            Icons.report_problem_outlined, AppColors.error),
        _KpiData('Unposted', 'GHS 2.1K', 'Missing reference',
            Icons.sync_problem_outlined, AppColors.warning),
      ],
      sectionTitle: 'Reconciliation Queue',
      filters: const [
        _FilterOption('Match', 'Exceptions first', Icons.rule_outlined),
        _FilterOption(
            'Source', 'Bank + mobile money', Icons.account_balance_outlined),
        _FilterOption('Period', 'Last 7 days', Icons.date_range_outlined),
      ],
      items: _items,
    );
  }
}

class AccountantApprovalsScreen extends StatelessWidget {
  const AccountantApprovalsScreen({super.key});

  static const _items = [
    _FinanceItem('REQ-221', 'Packaging materials', 'Fulfillment request',
        'GHS 6.8K', 'Approve', AppColors.primary),
    _FinanceItem('REQ-219', 'Nutrient purchase', 'Farm operations', 'GHS 4.5K',
        'Review', AppColors.warning),
    _FinanceItem('EXP-778', 'Delivery fuel', 'Sales personnel claim', 'GHS 420',
        'Approve', AppColors.success),
  ];

  @override
  Widget build(BuildContext context) {
    return _AccountantPage(
      selectedIndex: 3,
      title: 'Fund Approvals',
      subtitle:
          'Validate budget requests, expense claims, and release decisions.',
      icon: Icons.approval_outlined,
      colors: const [Color(0xFF7C2D12), Color(0xFFEA580C)],
      kpis: const [
        _KpiData('Pending', '5', 'Awaiting decision',
            Icons.pending_actions_outlined, AppColors.warning),
        _KpiData('Requested', 'GHS 18K', 'Open approval value',
            Icons.payments_outlined, AppColors.primary),
        _KpiData('Approved', 'GHS 9.2K', 'This week', Icons.verified_outlined,
            AppColors.success),
      ],
      sectionTitle: 'Approval Queue',
      filters: const [
        _FilterOption(
            'Priority', 'Pending first', Icons.priority_high_outlined),
        _FilterOption(
            'Request type', 'Funds + expenses', Icons.request_quote_outlined),
        _FilterOption('Amount', 'All values', Icons.payments_outlined),
      ],
      items: _items,
    );
  }
}

class AccountantReportsScreen extends StatelessWidget {
  const AccountantReportsScreen({super.key});

  static const _items = [
    _FinanceItem('FIN-RPT-01', 'Profit and Loss', 'Revenue, COGS, expenses',
        'Ready', 'Monthly', AppColors.success),
    _FinanceItem('FIN-RPT-02', 'Receivables Aging', 'Buyer payment exposure',
        'GHS 37K', 'Live', AppColors.warning),
    _FinanceItem('FIN-RPT-03', 'Expense Analysis', 'Category and farm cost',
        'Ready', 'Export', AppColors.primary),
  ];

  @override
  Widget build(BuildContext context) {
    return _AccountantPage(
      selectedIndex: 4,
      title: 'Financial Reports',
      subtitle:
          'Generate executive finance summaries, receivables aging, and expense breakdowns.',
      icon: Icons.assessment_outlined,
      colors: const [Color(0xFF1E3A8A), Color(0xFF0F766E)],
      kpis: const [
        _KpiData('Reports', '8', 'Ready to export', Icons.assessment_outlined,
            AppColors.primary),
        _KpiData('Profit', 'GHS 82.6K', '+23% this month',
            Icons.trending_up_outlined, AppColors.success),
        _KpiData('Expense ratio', '34%', 'Under budget',
            Icons.pie_chart_outline, AppColors.warning),
      ],
      sectionTitle: 'Report Library',
      filters: const [
        _FilterOption('Report type', 'Finance reports', Icons.folder_outlined),
        _FilterOption('Period', 'Monthly', Icons.calendar_month_outlined),
        _FilterOption('Export', 'PDF + Excel', Icons.file_download_outlined),
      ],
      items: _items,
    );
  }
}

class AccountantSettingsScreen extends StatelessWidget {
  const AccountantSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AccountantScreenShell(
      selectedIndex: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Hero(
            title: 'Accountant Settings',
            subtitle:
                'Configure approval thresholds, reconciliation rules, export format, and finance notifications.',
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

class _AccountantPage extends StatelessWidget {
  final int selectedIndex;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final List<_KpiData> kpis;
  final String sectionTitle;
  final Widget? sectionAction;
  final List<_FilterOption> filters;
  final List<_FinanceItem> items;
  final Widget? content;

  const _AccountantPage({
    required this.selectedIndex,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.kpis,
    required this.sectionTitle,
    this.sectionAction,
    required this.filters,
    required this.items,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AccountantScreenShell(
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
          _FilterBar(filters: filters),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  sectionTitle,
                  style: AppTypography.h5.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (sectionAction != null) sectionAction!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          content ?? _FinanceGrid(items: items),
        ],
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final bool showTable;
  final ValueChanged<bool> onChanged;

  const _ViewToggle({
    required this.showTable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            label: 'Cards',
            icon: Icons.grid_view_outlined,
            selected: !showTable,
            onTap: () => onChanged(false),
          ),
          _ToggleButton(
            label: 'Table',
            icon: Icons.table_rows_outlined,
            selected: showTable,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.textSecondary),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceGrid extends StatelessWidget {
  final List<_FinanceItem> items;

  const _FinanceGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 820 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 210,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (context, index) => _FinanceCard(item: items[index]),
        );
      },
    );
  }
}

class _FinanceTable extends StatelessWidget {
  final List<_FinanceItem> items;

  const _FinanceTable({required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Transactions (${items.length})',
            style: AppTypography.h6.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth =
                  constraints.maxWidth < 820 ? 820.0 : constraints.maxWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: items
                        .map((item) => _FinanceTableRow(item: item))
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FinanceTableRow extends StatelessWidget {
  final _FinanceItem item;

  const _FinanceTableRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: item.color.withOpacity(0.12),
            child: Icon(
              _transactionIcon(item),
              color: item.color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              item.amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                color: item.color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: _StatusBadge(label: item.status, color: item.color),
          ),
          SizedBox(
            width: 104,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                _TableActionButton(
                  icon: Icons.visibility_outlined,
                  color: AppColors.primary,
                ),
                SizedBox(width: AppSpacing.xs),
                _TableActionButton(
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _transactionIcon(_FinanceItem item) {
    if (item.id.startsWith('INV')) return Icons.payments_outlined;
    if (item.id.startsWith('EXP')) return Icons.receipt_long_outlined;
    if (item.id.startsWith('REQ')) return Icons.request_quote_outlined;
    return Icons.account_balance_wallet_outlined;
  }
}

class _TableActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _TableActionButton({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final List<_FilterOption> filters;

  const _FilterBar({required this.filters});

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
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(isDark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_alt_outlined,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Filters',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          ...filters.map((filter) => _FilterChip(option: filter)),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh_outlined, size: 18),
            label: const Text('Reset'),
            style: TextButton.styleFrom(
              foregroundColor:
                  isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final _FilterOption option;

  const _FilterChip({required this.option});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isDark ? Colors.white10 : AppColors.neutral200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              option.icon,
              size: 17,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              '${option.label}: ',
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              option.value,
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 17,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceCard extends StatelessWidget {
  final _FinanceItem item;

  const _FinanceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: item.color.withOpacity(isDark ? 0.28 : 0.18)),
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
              _IconBox(icon: Icons.receipt_long_outlined, color: item.color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _MutedText(item.subtitle),
                  ],
                ),
              ),
              _StatusBadge(label: item.status, color: item.color),
            ],
          ),
          const Spacer(),
          _MetricPill(label: item.id, value: item.amount),
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
                    fontWeight: FontWeight.w800,
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
                    fontWeight: FontWeight.w800,
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
          title: 'Approval threshold',
          subtitle: 'Require senior review above GHS 10K.',
          icon: Icons.verified_user_outlined,
          enabled: true,
        ),
        _SettingRow(
          title: 'Auto reconciliation',
          subtitle: 'Match deposits when invoice references are exact.',
          icon: Icons.sync_alt_outlined,
          enabled: true,
        ),
        _SettingRow(
          title: 'Daily finance export',
          subtitle: 'Prepare daily CSV and PDF finance pack.',
          icon: Icons.file_download_outlined,
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
                    fontWeight: FontWeight.w800,
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
              fontWeight: FontWeight.w800,
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
          fontWeight: FontWeight.w700,
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
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _FinanceItem {
  final String id;
  final String title;
  final String subtitle;
  final String amount;
  final String status;
  final Color color;

  const _FinanceItem(
    this.id,
    this.title,
    this.subtitle,
    this.amount,
    this.status,
    this.color,
  );
}

class _FilterOption {
  final String label;
  final String value;
  final IconData icon;

  const _FilterOption(this.label, this.value, this.icon);
}
