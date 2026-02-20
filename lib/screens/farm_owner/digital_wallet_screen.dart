import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_owner_sidebar.dart';
import '../../core/widgets/farm_owner_header.dart';
import '../../core/widgets/farm_owner_mobile_drawer.dart';
import '../../providers/auth_provider.dart';

/// Digital Wallet Screen for Farm Owner
/// View wallet balance, transactions, and financial overview
class DigitalWalletScreen extends ConsumerStatefulWidget {
  const DigitalWalletScreen({super.key});

  @override
  ConsumerState<DigitalWalletScreen> createState() => _DigitalWalletScreenState();
}

class _DigitalWalletScreenState extends ConsumerState<DigitalWalletScreen> {
  int _selectedNavIndex = 2;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  String _sortBy = 'date';
  bool _sortAscending = false;
  String _selectedWithdrawBank = 'Chase Bank - ****1234';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _withdrawAmountController = TextEditingController();
  final TextEditingController _withdrawNoteController = TextEditingController();

  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 'TXN001',
      'type': 'Credit',
      'amount': 50000,
      'description': 'Harvest Payment - Green Valley Farm',
      'date': '2024-01-15',
      'status': 'Completed',
      'icon': Icons.arrow_downward,
      'color': AppColors.success,
    },
    {
      'id': 'TXN002',
      'type': 'Debit',
      'amount': 15000,
      'description': 'Withdrawal to Bank Account',
      'date': '2024-01-12',
      'status': 'Completed',
      'icon': Icons.arrow_upward,
      'color': AppColors.error,
    },
    {
      'id': 'TXN003',
      'type': 'Credit',
      'amount': 30000,
      'description': 'Harvest Payment - Sunny Acres',
      'date': '2024-01-10',
      'status': 'Completed',
      'icon': Icons.arrow_downward,
      'color': AppColors.success,
    },
    {
      'id': 'TXN004',
      'type': 'Credit',
      'amount': 25000,
      'description': 'Harvest Payment - Fresh Farms',
      'date': '2024-01-08',
      'status': 'Completed',
      'icon': Icons.arrow_downward,
      'color': AppColors.success,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _withdrawAmountController.dispose();
    _withdrawNoteController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    final filtered = _transactions.where((transaction) {
      final matchesType =
          _selectedFilter == 'All' || transaction['type'] == _selectedFilter;
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return matchesType;
      final description = (transaction['description'] as String).toLowerCase();
      final date = (transaction['date'] as String).toLowerCase();
      final status = (transaction['status'] as String).toLowerCase();
      final type = (transaction['type'] as String).toLowerCase();
      return matchesType &&
          (description.contains(query) ||
              date.contains(query) ||
              status.contains(query) ||
              type.contains(query));
    }).toList();

    filtered.sort((a, b) {
      int result;
      switch (_sortBy) {
        case 'amount':
          result = (a['amount'] as int).compareTo(b['amount'] as int);
          break;
        case 'type':
          result = (a['type'] as String).compareTo(b['type'] as String);
          break;
        case 'status':
          result = (a['status'] as String).compareTo(b['status'] as String);
          break;
        case 'description':
          result = (a['description'] as String).compareTo(b['description'] as String);
          break;
        case 'date':
        default:
          result = (a['date'] as String).compareTo(b['date'] as String);
          break;
      }
      return _sortAscending ? result : -result;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Farm Owner';
    final userEmail = authState.user?.email ?? 'owner@farmestates.com';
    final userRole = 'Farm Owner';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? FarmOwnerMobileDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (i) => setState(() => _selectedNavIndex = i),
              userName: userName,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail, String userRole) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    
    return Row(
      children: [
        FarmOwnerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) {
            setState(() => _selectedNavIndex = index);
          },
          userName: userName,
          userEmail: userEmail,
          userRole: userRole,
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
                  padding: EdgeInsets.all(isTablet ? AppSpacing.md : AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWalletBalanceCard(isDark),
                      SizedBox(height: isTablet ? AppSpacing.md : AppSpacing.lg),
                      _buildStatsCards(isDark),
                      SizedBox(height: isTablet ? AppSpacing.md : AppSpacing.lg),
                      _buildTransactionsSection(isDark),
                    ],
                  ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWalletBalanceCard(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildStatsCards(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildTransactionsSection(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletBalanceCard(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: isMobile ? double.infinity : null,
          constraints: isMobile ? null : const BoxConstraints(maxWidth: 500),
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : (isTablet ? AppSpacing.lg : AppSpacing.xl)),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.12 : 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Wallet Balance',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.12 : 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                      size: isMobile ? 22 : (isTablet ? 24 : 26),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$48,500.00',
                    style: AppTypography.h3.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 28 : (isTablet ? 32 : 36),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'USD',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                        fontSize: isMobile ? 10 : 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? AppSpacing.xs : AppSpacing.sm),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.12 : 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: AppColors.success,
                          size: isMobile ? 12 : 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+23% this month',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            fontSize: isMobile ? 10 : 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Last updated 2 hours ago',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                        fontSize: isMobile ? 10 : 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _showWithdrawFundsModal(isDark),
                  icon: const Icon(Icons.payments_outlined, size: 16),
                  label: const Text('Withdraw Funds'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.3),
                    ),
                    backgroundColor: isDark ? Colors.white.withOpacity(0.04) : AppColors.primary.withOpacity(0.08),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCards(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    
    final stats = [
      {
        'title': 'Total Income',
        'value': '\$105,000',
        'icon': Icons.arrow_downward,
        'color': AppColors.success,
      },
      {
        'title': 'Total Withdrawals',
        'value': '\$56,500',
        'icon': Icons.arrow_upward,
        'color': AppColors.error,
      },
      {
        'title': 'Pending',
        'value': '\$12,000',
        'icon': Icons.pending,
        'color': AppColors.warning,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);
        final childAspectRatio = isMobile ? 3.0 : (isTablet ? 2.8 : 2.5);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
          mainAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
          children: stats.map((stat) {
            return Container(
              padding: EdgeInsets.all(isMobile ? AppSpacing.sm : (isTablet ? AppSpacing.sm : AppSpacing.md)),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: (stat['color'] as Color).withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 8 : (isTablet ? 9 : 10)),
                        decoration: BoxDecoration(
                          color: (stat['color'] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          stat['icon'] as IconData,
                          color: stat['color'] as Color,
                          size: isMobile ? 18 : (isTablet ? 19 : 20),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (stat['color'] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Updated',
                          style: AppTypography.caption.copyWith(
                            color: stat['color'] as Color,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.sm),
                  Text(
                    stat['value'] as String,
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: isMobile ? 20 : (isTablet ? 22 : 24),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMobile ? 6 : 4),
                  Text(
                    stat['title'] as String,
                    style: AppTypography.caption.copyWith(
                      color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
                      fontSize: isMobile ? 11 : (isTablet ? 11.5 : 12),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTransactionsSection(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    final filteredTransactions = _getFilteredTransactions();
    
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : (isTablet ? AppSpacing.lg : AppSpacing.xl)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) {
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildSearchField(isDark, isMobile),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(child: _buildFilterDropdown(isDark, isMobile)),
                        const SizedBox(width: AppSpacing.sm),
                        _buildSortButton(isDark, isMobile),
                        const SizedBox(width: AppSpacing.xs),
                        _buildExportButton(isDark, isMobile),
                      ],
                    ),
                  ],
                );
              }
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(
                              'Recent Transactions',
                              style: AppTypography.h5.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                                fontSize: isTablet ? 20 : 22,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildSearchField(isDark, isMobile),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _buildFilterDropdown(isDark, isMobile),
                  const SizedBox(width: AppSpacing.sm),
                  _buildSortButton(isDark, isMobile),
                  const SizedBox(width: AppSpacing.xs),
                  _buildExportButton(isDark, isMobile),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (isMobile)
            ...filteredTransactions.map((transaction) {
              return _buildTransactionCard(transaction, isDark);
            })
          else
            _buildTransactionsTable(isDark, isTablet, filteredTransactions),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark, bool isMobile) {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Search transactions',
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        filled: true,
        fillColor: isDark ? Colors.white10 : AppColors.neutral100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.2,
          ),
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white54 : AppColors.textSecondary,
          fontSize: isMobile ? 12 : 13,
        ),
      ),
      style: TextStyle(
        color: isDark ? Colors.white : AppColors.textPrimary,
        fontSize: isMobile ? 12 : 13,
      ),
    );
  }

  Widget _buildFilterDropdown(bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
        ),
      ),
      child: DropdownButton<String>(
        value: _selectedFilter,
        isExpanded: isMobile,
        items: ['All', 'Credit', 'Debit'].map((filter) {
          return DropdownMenuItem(
            value: filter,
            child: Text(
              filter,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: isMobile ? 12 : 13,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _selectedFilter = value!);
        },
        underline: const SizedBox(),
        icon: Icon(
          Icons.arrow_drop_down,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textPrimary,
          fontSize: isMobile ? 12 : 13,
        ),
      ),
    );
  }

  Widget _buildSortButton(bool isDark, bool isMobile) {
    return PopupMenuButton<String>(
      tooltip: 'Sort',
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      onSelected: (value) {
        if (value == 'toggle') {
          setState(() => _sortAscending = !_sortAscending);
        } else {
          setState(() => _sortBy = value);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'date',
          child: _buildSortItem('Date', _sortBy == 'date'),
        ),
        PopupMenuItem(
          value: 'amount',
          child: _buildSortItem('Amount', _sortBy == 'amount'),
        ),
        PopupMenuItem(
          value: 'type',
          child: _buildSortItem('Type', _sortBy == 'type'),
        ),
        PopupMenuItem(
          value: 'status',
          child: _buildSortItem('Status', _sortBy == 'status'),
        ),
        PopupMenuItem(
          value: 'description',
          child: _buildSortItem('Description', _sortBy == 'description'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(_sortAscending ? 'Ascending' : 'Descending'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Icon(
          _sortAscending ? Icons.sort_by_alpha : Icons.sort,
          size: isMobile ? 18 : 20,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSortItem(String label, bool selected) {
    return Row(
      children: [
        Icon(
          selected ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildExportButton(bool isDark, bool isMobile) {
    return InkWell(
      onTap: _exportTransactionsCsv,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
          ),
        ),
        child: Icon(
          Icons.download_rounded,
          size: isMobile ? 18 : 20,
          color: AppColors.primary,
        ),
      ),
    );
  }

  void _showWithdrawFundsModal(bool isDark) {
    const availableBalance = 48500.0;
    const fee = 3.5;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final amount = double.tryParse(_withdrawAmountController.text.trim()) ?? 0;
        final netAmount = (amount - fee).clamp(0.0, double.infinity).toDouble();

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Withdraw From Wallet',
                          style: AppTypography.h6.copyWith(
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Available: \$48,500.00',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: _selectedWithdrawBank,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                      decoration: InputDecoration(
                        labelText: 'Bank Account',
                        labelStyle: AppTypography.bodySmall.copyWith(
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : AppColors.neutral100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        'Chase Bank - ****1234',
                        'Bank of America - ****5678',
                        'Wells Fargo - ****9012',
                      ]
                          .map(
                            (bank) => DropdownMenuItem(
                              value: bank,
                              child: Text(bank),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedWithdrawBank = value);
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _withdrawAmountController,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
                      ],
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        labelStyle: AppTypography.bodySmall.copyWith(
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                        prefixText: '\$ ',
                        prefixStyle: AppTypography.bodyMedium.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : AppColors.neutral100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [500, 1000, 2500, 5000].map((quick) {
                        return InkWell(
                          onTap: () {
                            _withdrawAmountController.text = quick.toString();
                            setModalState(() {});
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text('\$$quick', style: AppTypography.caption),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _withdrawNoteController,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Note (Optional)',
                        labelStyle: AppTypography.bodySmall.copyWith(
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : AppColors.neutral100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Requested', '\$${amount.toStringAsFixed(2)}', isDark, null),
                          _buildDetailRow('Fee', '\$${fee.toStringAsFixed(2)}', isDark, null),
                          _buildDetailRow('Net Payout', '\$${netAmount.toStringAsFixed(2)}', isDark, AppColors.primary),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final submitAmount = double.tryParse(_withdrawAmountController.text.trim());
                            if (submitAmount == null || submitAmount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Enter a valid amount')),
                              );
                              return;
                            }
                            if (submitAmount > availableBalance) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Amount exceeds available balance')),
                              );
                              return;
                            }

                            setState(() {
                              _transactions.insert(0, {
                                'id': 'TXN${(_transactions.length + 1).toString().padLeft(3, '0')}',
                                'type': 'Debit',
                                'amount': submitAmount.round(),
                                'description': 'Withdrawal Request - $_selectedWithdrawBank',
                                'date': _formatDate(DateTime.now()),
                                'status': 'Pending',
                                'icon': Icons.arrow_upward,
                                'color': AppColors.error,
                              });
                              _selectedFilter = 'All';
                            });

                            _withdrawAmountController.clear();
                            _withdrawNoteController.clear();
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Withdrawal request submitted')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  void _exportTransactionsCsv() {
    final rows = [
      ['Date', 'Description', 'Type', 'Status', 'Amount'],
      ..._getFilteredTransactions().map((t) {
        final amount = t['amount'] as int;
        final isCredit = t['type'] == 'Credit';
        return [
          t['date'].toString(),
          t['description'].toString(),
          t['type'].toString(),
          t['status'].toString(),
          '${isCredit ? '+' : '-'}$amount',
        ];
      }),
    ];

    final csv = rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Widget _buildTransactionsTable(
      bool isDark, bool isTablet, List<Map<String, dynamic>> transactions) {
    final headerStyle = AppTypography.bodySmall.copyWith(
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white70 : AppColors.textSecondary,
      fontSize: isTablet ? 11 : 12,
    );

    final cellStyle = AppTypography.bodySmall.copyWith(
      color: isDark ? Colors.white : AppColors.textPrimary,
      fontSize: isTablet ? 12 : 13,
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              SizedBox(width: 110, child: Text('Date', style: headerStyle)),
              const SizedBox(width: 12),
              Expanded(child: Text('Description', style: headerStyle)),
              const SizedBox(width: 12),
              SizedBox(width: 90, child: Text('Type', style: headerStyle)),
              const SizedBox(width: 12),
              SizedBox(width: 110, child: Text('Status', style: headerStyle)),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: Text(
                  'Amount',
                  style: headerStyle,
                  textAlign: TextAlign.end,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...transactions.asMap().entries.map((entry) {
          final index = entry.key;
          final transaction = entry.value;
          final isCredit = transaction['type'] == 'Credit';
          final amount = transaction['amount'] as int;
          final color = transaction['color'] as Color;
          final statusColor = _transactionStatusColor(transaction['status'] as String);
          final baseColor = isDark ? Colors.white.withOpacity(0.02) : Colors.white;
          final altColor = isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC);

          return Material(
            color: index.isEven ? baseColor : altColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              hoverColor: AppColors.primary.withOpacity(0.06),
              onTap: () => _showTransactionDetails(transaction, isDark),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 110,
                      child: Text(transaction['date'] as String, style: cellStyle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              transaction['icon'] as IconData,
                              size: 16,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              transaction['description'] as String,
                              style: cellStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 90,
                      child: Text(
                        transaction['type'] as String,
                        style: cellStyle.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          transaction['status'] as String,
                          style: AppTypography.caption.copyWith(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${isCredit ? '+' : '-'}\$${amount.toStringAsFixed(0)}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    final isCredit = transaction['type'] == 'Credit';
    final amount = transaction['amount'] as int;
    final color = transaction['color'] as Color;
    final statusColor = _transactionStatusColor(transaction['status'] as String);

    return InkWell(
      onTap: () => _showTransactionDetails(transaction, isDark),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: EdgeInsets.all(isMobile ? AppSpacing.sm : (isTablet ? AppSpacing.sm : AppSpacing.md)),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : (isTablet ? 11 : 12)),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              transaction['icon'] as IconData,
              color: color,
              size: isMobile ? 20 : (isTablet ? 22 : 24),
            ),
          ),
          SizedBox(width: isMobile ? AppSpacing.sm : AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  transaction['description'] as String,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: isMobile ? 13 : (isTablet ? 14 : 15),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        transaction['date'] as String,
                        style: AppTypography.caption.copyWith(
                          color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
                          fontSize: isMobile ? 10 : 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        transaction['status'] as String,
                        style: AppTypography.caption.copyWith(
                          color: statusColor,
                          fontSize: isMobile ? 9 : 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              '${isCredit ? '+' : '-'}\$${amount.toStringAsFixed(0)}',
              style: AppTypography.h6.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 16 : (isTablet ? 17 : 18),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction, bool isDark) {
    final isCredit = transaction['type'] == 'Credit';
    final amount = transaction['amount'] as int;
    final color = transaction['color'] as Color;
    final statusColor = _transactionStatusColor(transaction['status'] as String);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  transaction['icon'] as IconData,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Transaction Details',
                  style: AppTypography.h6.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Type', transaction['type'] as String, isDark, color),
              _buildDetailRow('Status', transaction['status'] as String, isDark, statusColor),
              _buildDetailRow('Date', transaction['date'] as String, isDark, null),
              _buildDetailRow('Description', transaction['description'] as String, isDark, null),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Amount',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${isCredit ? '+' : '-'}\$${amount.toStringAsFixed(0)}',
                      style: AppTypography.bodyLarge.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Close',
                style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, Color? accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: accent ?? (isDark ? Colors.white : AppColors.textPrimary),
                fontWeight: accent != null ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _transactionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.info;
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.take(5).map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final isSelected = index == _selectedNavIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_selectedNavIndex != index) {
                        setState(() => _selectedNavIndex = index);
                        try {
                          Navigator.pushReplacementNamed(context, route);
                        } catch (e) {
                          try {
                            Navigator.pushNamed(context, route);
                          } catch (e2) {
                            debugPrint('Navigation error: $e2');
                          }
                        }
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 24,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : AppColors.textSecondary),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
