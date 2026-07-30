import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_owner_sidebar.dart';
import '../../core/widgets/farm_owner_header.dart';
import '../../core/widgets/farm_owner_mobile_drawer.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Digital Wallet Screen for Farm Owner
/// View wallet balance, transactions, and financial overview
class DigitalWalletScreen extends ConsumerStatefulWidget {
  const DigitalWalletScreen({super.key});

  @override
  ConsumerState<DigitalWalletScreen> createState() =>
      _DigitalWalletScreenState();
}

class _DigitalWalletScreenState extends ConsumerState<DigitalWalletScreen> {
  final SuperAdminApiService _api = SuperAdminApiService();
  int _selectedNavIndex = 2;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  String _sortBy = 'date';
  bool _sortAscending = false;
  String _selectedWithdrawBank = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _withdrawAmountController =
      TextEditingController();
  final TextEditingController _withdrawNoteController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final List<Map<String, dynamic>> _farms = [];
  final List<Map<String, dynamic>> _sales = [];
  final List<Map<String, dynamic>> _fundRequests = [];
  final List<Map<String, dynamic>> _walletRecords = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _withdrawAmountController.dispose();
    _withdrawNoteController.dispose();
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final results = await Future.wait([
        _api.getFarms(),
        _api.getSales(),
        _api.getFundRequests(),
        _api.getWallet(),
      ]);
      if (!mounted) return;
      setState(() {
        _farms
          ..clear()
          ..addAll(results[0]);
        _sales
          ..clear()
          ..addAll(results[1]);
        _fundRequests
          ..clear()
          ..addAll(results[2]);
        _walletRecords
          ..clear()
          ..addAll(results[3]);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted || !showLoading) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  String _docId(Map<String, dynamic> doc) =>
      (doc[r'$id'] ?? doc['id'] ?? doc['farm_id'] ?? '').toString();

  String _value(Map<String, dynamic> doc, List<String> keys,
      {String fallback = ''}) {
    for (final key in keys) {
      final value = doc[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String _normalise(dynamic value) =>
      value?.toString().trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ??
      '';

  num _numValue(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
  }

  DateTime? _dateValue(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }

  bool _isOwnerFarm(Map<String, dynamic> farm) {
    final user = ref.read(authProvider).user;
    if (user == null) return true;
    final ownerTokens = {
      _normalise(user.id),
      _normalise(user.email),
      _normalise(user.name),
    }..removeWhere((token) => token.isEmpty);
    final farmOwnerTokens = {
      _normalise(_value(farm, ['ownerID', 'owner_id', 'ownerId'])),
      _normalise(_value(farm, ['owner_name', 'ownerName'])),
      _normalise(_value(farm, ['owner_email', 'ownerEmail'])),
    }..removeWhere((token) => token.isEmpty || token == 'unassigned');
    return farmOwnerTokens.any(ownerTokens.contains);
  }

  List<Map<String, dynamic>> get _ownerFarms =>
      _farms.where(_isOwnerFarm).toList();

  Set<String> get _ownerFarmIds =>
      _ownerFarms.map(_docId).where((id) => id.isNotEmpty).toSet();

  Set<String> get _ownerFarmNames => _ownerFarms
      .map((farm) => _value(farm, ['name', 'farm_name']))
      .where((name) => name.isNotEmpty)
      .map(_normalise)
      .toSet();

  bool _matchesOwnerFarm(Map<String, dynamic> doc) {
    final farmId = _value(doc, ['farm_id', 'farmID', 'farmId']);
    final farmName = _value(doc, ['farm_name', 'farmName']);
    return (farmId.isNotEmpty && _ownerFarmIds.contains(farmId)) ||
        (farmName.isNotEmpty && _ownerFarmNames.contains(_normalise(farmName)));
  }

  List<Map<String, dynamic>> get _ownerSales =>
      _sales.where(_matchesOwnerFarm).toList();

  List<Map<String, dynamic>> get _ownerFundRequests =>
      _fundRequests.where(_matchesOwnerFarm).toList();

  List<Map<String, dynamic>> get _ownerWalletRecords {
    final user = ref.read(authProvider).user;
    if (user == null) return _walletRecords;
    final tokens = {
      _normalise(user.id),
      _normalise(user.name),
      _normalise(user.email),
    }..removeWhere((token) => token.isEmpty);
    return _walletRecords.where((record) {
      final recordTokens = {
        _normalise(_value(record, ['user_id'])),
        _normalise(_value(record, ['user_name'])),
        _normalise(_value(record, ['email'])),
        _normalise(_value(record, ['created_by'])),
      }..removeWhere((token) => token.isEmpty);
      return recordTokens.any(tokens.contains);
    }).toList();
  }

  bool _isWithdrawalRecord(Map<String, dynamic> record) {
    final type = _normalise(_value(record, ['transaction_type']));
    final withdrawalStatus = _value(record, ['withdrawal_status']);
    return type == 'withdrawal' || withdrawalStatus.isNotEmpty;
  }

  bool _isPayoutAccountRecord(Map<String, dynamic> record) {
    final type = _normalise(_value(record, ['transaction_type']));
    final status = _normalise(_value(record, ['status'], fallback: 'Active'));
    return type == 'payout account' && status != 'closed';
  }

  String _payoutAccountLabel(Map<String, dynamic> record) {
    final existingLabel = _value(record, ['bank_account']);
    if (existingLabel.isNotEmpty) return existingLabel;
    final method = _value(record, ['payout_method'], fallback: 'Bank');
    final bankName = _value(record, ['bank_name'],
        fallback: method == 'Mobile Money' ? 'Mobile money' : 'Bank account');
    final accountNumber = _value(record, ['account_number']);
    if (accountNumber.isEmpty) return bankName;
    final suffix = accountNumber.length > 4
        ? accountNumber.substring(accountNumber.length - 4)
        : accountNumber;
    return '$method: $bankName - ****$suffix';
  }

  List<String> get _savedPayoutAccounts {
    final accounts = _ownerWalletRecords
        .where(_isPayoutAccountRecord)
        .map(_payoutAccountLabel)
        .where((account) => account.trim().isNotEmpty)
        .toSet()
        .toList();
    accounts.sort();
    return accounts;
  }

  List<Map<String, dynamic>> get _transactions {
    final transactions = <Map<String, dynamic>>[];
    for (final sale in _ownerSales) {
      final amount = _numValue(sale['total_amount'] ?? sale['amount']);
      if (amount <= 0) continue;
      final id = _value(sale, ['sale_id', 'sales_id', 'batch_id'],
          fallback: _docId(sale));
      final farmName = _value(sale, ['farm_name'], fallback: 'Owned farm');
      transactions.add({
        'id': id.isEmpty ? 'SALE-${transactions.length + 1}' : id,
        'type': 'Credit',
        'amount': amount,
        'description': 'Hub sale payment - $farmName',
        'date': _formatDate(
            _dateValue(sale['created_at'] ?? sale[r'$createdAt']) ??
                DateTime.now()),
        'status': _value(sale, ['payment_status', 'status'],
            fallback: sale['paid'] == true ? 'Completed' : 'Pending'),
        'icon': Icons.arrow_downward,
        'color': AppColors.success,
      });
    }
    for (final withdrawal in _ownerWalletRecords.where(_isWithdrawalRecord)) {
      final amount =
          _numValue(withdrawal['amount'] ?? withdrawal['total_debits']);
      if (amount <= 0) continue;
      final status = _value(withdrawal, ['withdrawal_status', 'status'],
          fallback: 'Pending');
      final bankAccount =
          _value(withdrawal, ['bank_account'], fallback: 'Bank transfer');
      final farmName =
          _value(withdrawal, ['farm_name'], fallback: 'Owned farm');
      transactions.add({
        'id': _value(withdrawal, ['transaction_id'],
            fallback: _docId(withdrawal)),
        'type': 'Debit',
        'amount': amount,
        'description': 'Wallet withdrawal - $bankAccount',
        'date': _formatDate(_dateValue(withdrawal['requested_at'] ??
                withdrawal['processed_at'] ??
                withdrawal[r'$createdAt']) ??
            DateTime.now()),
        'status': status,
        'farm': farmName,
        'bank': bankAccount,
        'note': _value(withdrawal, ['note']),
        'icon': Icons.account_balance_outlined,
        'color': AppColors.error,
      });
    }
    for (final request in _ownerFundRequests) {
      final amount = _numValue(request['amount']);
      if (amount <= 0) continue;
      final status = _value(request, ['status'], fallback: 'Pending');
      final isDebit = ['approved', 'disbursed', 'completed', 'paid']
          .contains(status.toLowerCase());
      transactions.add({
        'id': _value(request, ['request_id'], fallback: _docId(request)),
        'type': 'Debit',
        'amount': amount,
        'description':
            '${isDebit ? 'Fund disbursement' : 'Pending fund request'} - ${_value(request, [
                  'purpose'
                ], fallback: 'Farm operations')}',
        'date': _formatDate(_dateValue(request['request_date'] ??
                request['updated_at'] ??
                request[r'$createdAt']) ??
            DateTime.now()),
        'status': status,
        'icon': Icons.arrow_upward,
        'color': AppColors.error,
      });
    }
    transactions
        .sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    return transactions;
  }

  num get _totalIncome => _transactions
      .where((t) => t['type'] == 'Credit')
      .fold<num>(0, (sum, t) => sum + _numValue(t['amount']));

  num get _totalWithdrawals => _transactions
      .where((t) =>
          t['type'] == 'Debit' &&
          ['approved', 'disbursed', 'completed', 'paid']
              .contains(_normalise(t['status'])))
      .fold<num>(0, (sum, t) => sum + _numValue(t['amount']));

  num get _pendingAmount => _transactions
      .where((t) => _normalise(t['status']) == 'pending')
      .fold<num>(0, (sum, t) => sum + _numValue(t['amount']));

  num get _walletBalance {
    final balanceRecords = _ownerWalletRecords.where((record) {
      if (_isWithdrawalRecord(record)) return false;
      final type = _normalise(_value(record, ['transaction_type']));
      return type == 'balance' || _numValue(record['balance']) != 0;
    }).toList();
    if (balanceRecords.isNotEmpty) {
      return balanceRecords.fold<num>(
        0,
        (sum, record) => sum + _numValue(record['balance']),
      );
    }
    return _totalIncome - _totalWithdrawals;
  }

  String _formatMoney(num value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return 'GHS $whole.${parts.last}';
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
          result = _numValue(a['amount']).compareTo(_numValue(b['amount']));
          break;
        case 'type':
          result = (a['type'] as String).compareTo(b['type'] as String);
          break;
        case 'status':
          result = (a['status'] as String).compareTo(b['status'] as String);
          break;
        case 'description':
          result = (a['description'] as String)
              .compareTo(b['description'] as String);
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
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      bottomNavigationBar: isMobile
          ? SafeArea(top: false, child: _buildBottomNavigation(isDark))
          : null,
    );
  }

  Widget _buildDesktopLayout(
      bool isDark, String userName, String userEmail, String userRole) {
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
                  padding:
                      EdgeInsets.all(isTablet ? AppSpacing.md : AppSpacing.lg),
                  child: _buildContent(isDark, isTablet),
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

  Widget _buildContent(bool isDark, bool isTabletOrMobile) {
    if (_isLoading) {
      return const AdminDataSkeleton(rowCount: 5, showStats: true);
    }
    if (_errorMessage != null) {
      return _buildErrorState(isDark);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWalletBalanceCard(isDark),
        SizedBox(height: isTabletOrMobile ? AppSpacing.md : AppSpacing.lg),
        _buildStatsCards(isDark),
        SizedBox(height: isTabletOrMobile ? AppSpacing.md : AppSpacing.lg),
        _buildTransactionsSection(isDark),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              color: AppColors.error, size: 42),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Unable to load wallet data',
            style: AppTypography.h6.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: _loadWalletData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
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
          padding: EdgeInsets.all(isMobile
              ? AppSpacing.md
              : (isTablet ? AppSpacing.lg : AppSpacing.xl)),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.12 : 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Wallet Balance',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white70 : AppColors.textSecondary,
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
                    _formatMoney(_walletBalance),
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
                      'GHS',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          '${_ownerSales.length} sales linked',
                          style: AppTypography.caption.copyWith(
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
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
                      _transactions.isEmpty
                          ? 'No backend transactions yet'
                          : 'Last updated ${_transactions.first['date']}',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
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
                      color: isDark
                          ? Colors.white.withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.3),
                    ),
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.04)
                        : AppColors.primary.withOpacity(0.08),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        'value': _formatMoney(_totalIncome),
        'icon': Icons.arrow_downward,
        'color': AppColors.success,
      },
      {
        'title': 'Total Withdrawals',
        'value': _formatMoney(_totalWithdrawals),
        'icon': Icons.arrow_upward,
        'color': AppColors.error,
      },
      {
        'title': 'Pending',
        'value': _formatMoney(_pendingAmount),
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
              padding: EdgeInsets.all(isMobile
                  ? AppSpacing.sm
                  : (isTablet ? AppSpacing.sm : AppSpacing.md)),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFE2E8F0),
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
                        padding:
                            EdgeInsets.all(isMobile ? 8 : (isTablet ? 9 : 10)),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
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
                      color: isDark
                          ? Colors.white.withOpacity(0.6)
                          : AppColors.textSecondary,
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
      padding: EdgeInsets.all(isMobile
          ? AppSpacing.md
          : (isTablet ? AppSpacing.lg : AppSpacing.xl)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
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
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
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
          if (filteredTransactions.isEmpty)
            _buildEmptyTransactionsState(isDark)
          else if (isMobile)
            ...filteredTransactions.map((transaction) {
              return _buildTransactionCard(transaction, isDark);
            })
          else
            _buildTransactionsTable(isDark, isTablet, filteredTransactions),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactionsState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
            size: 36,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No wallet transactions found',
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sales payments and withdrawal requests linked to your farms will appear here.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  InputDecoration _walletInputDecoration(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTypography.bodySmall.copyWith(
        color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
      filled: true,
      fillColor: isDark ? Colors.white10 : AppColors.neutral100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.2,
        ),
      ),
    );
  }

  Widget _buildModalError(String message, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withOpacity(0.2),
        ),
      ),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNoPayoutAccountState(
    bool isDark, {
    required VoidCallback onAdd,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_outlined,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'No payout account added',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_card_rounded, size: 18),
            label: const Text('Add Account'),
          ),
        ],
      ),
    );
  }

  void _showAddPayoutAccountModal(bool isDark) {
    var isSubmitting = false;
    var payoutMethod = 'Bank';
    var selectedMobileMoneyNetwork = 'MTN';
    String? modalError;
    _bankNameController.clear();
    _accountNameController.clear();
    _accountNumberController.clear();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final isMobileMoney = payoutMethod == 'Mobile Money';
              return Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Add Payout Account',
                          style: AppTypography.h6.copyWith(
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.pop(dialogContext),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : AppColors.neutral100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: ['Bank', 'Mobile Money'].map((method) {
                          final selected = payoutMethod == method;
                          return Expanded(
                            child: InkWell(
                              onTap: isSubmitting
                                  ? null
                                  : () {
                                      setModalState(() {
                                        payoutMethod = method;
                                        if (method == 'Mobile Money') {
                                          selectedMobileMoneyNetwork = 'MTN';
                                          _bankNameController.text =
                                              selectedMobileMoneyNetwork;
                                        } else {
                                          _bankNameController.clear();
                                        }
                                        modalError = null;
                                      });
                                    },
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      method == 'Bank'
                                          ? Icons.account_balance_rounded
                                          : Icons.phone_android_rounded,
                                      size: 16,
                                      color: selected
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white70
                                              : AppColors.textSecondary),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        method,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: selected
                                              ? Colors.white
                                              : (isDark
                                                  ? Colors.white70
                                                  : AppColors.textSecondary),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (isMobileMoney)
                      DropdownButtonFormField<String>(
                        value: selectedMobileMoneyNetwork,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        dropdownColor:
                            isDark ? AppColors.surfaceDark : Colors.white,
                        decoration: _walletInputDecoration(
                            'Mobile Money Network', isDark),
                        items: const ['MTN', 'AIRTELTIGO', 'TELECEL']
                            .map(
                              (network) => DropdownMenuItem(
                                value: network,
                                child: Text(network),
                              ),
                            )
                            .toList(),
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value == null) return;
                                setModalState(() {
                                  selectedMobileMoneyNetwork = value;
                                  _bankNameController.text = value;
                                  modalError = null;
                                });
                              },
                      )
                    else
                      TextField(
                        controller: _bankNameController,
                        textInputAction: TextInputAction.next,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        decoration: _walletInputDecoration('Bank Name', isDark),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _accountNameController,
                      textInputAction: TextInputAction.next,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      decoration: _walletInputDecoration(
                        isMobileMoney ? 'Mobile Money Name' : 'Account Name',
                        isDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _accountNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      decoration: _walletInputDecoration(
                        isMobileMoney
                            ? 'Mobile Money Number'
                            : 'Account Number',
                        isDark,
                      ),
                    ),
                    if (modalError != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildModalError(modalError!, isDark),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.pop(dialogContext),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final accountProvider =
                                      _bankNameController.text.trim();
                                  final accountName =
                                      _accountNameController.text.trim();
                                  final accountNumber =
                                      _accountNumberController.text.trim();
                                  if (accountProvider.isEmpty) {
                                    setModalState(() => modalError =
                                        isMobileMoney
                                            ? 'Enter the mobile money network.'
                                            : 'Enter the bank name.');
                                    return;
                                  }
                                  if (accountName.isEmpty) {
                                    setModalState(() => modalError =
                                        isMobileMoney
                                            ? 'Enter the mobile money name.'
                                            : 'Enter the account name.');
                                    return;
                                  }
                                  if (accountNumber.length < 6) {
                                    setModalState(() => modalError = isMobileMoney
                                        ? 'Enter a valid mobile money number.'
                                        : 'Enter a valid account number.');
                                    return;
                                  }

                                  final user = ref.read(authProvider).user;
                                  setModalState(() {
                                    isSubmitting = true;
                                    modalError = null;
                                  });
                                  try {
                                    await _api.createWalletBankAccount(data: {
                                      'user_id': user?.id ?? '',
                                      'user_name': user?.name ?? 'Farm Owner',
                                      'payout_method': payoutMethod,
                                      'bank_name': accountProvider,
                                      'account_name': accountName,
                                      'account_number': accountNumber,
                                      'currency': 'GHS',
                                    });
                                    final suffix = accountNumber.length > 4
                                        ? accountNumber
                                            .substring(accountNumber.length - 4)
                                        : accountNumber;
                                    if (!mounted) return;
                                    setState(() {
                                      _selectedWithdrawBank =
                                          '$payoutMethod: $accountProvider - ****$suffix';
                                    });
                                    if (!dialogContext.mounted) return;
                                    Navigator.of(dialogContext).pop();
                                    await _loadWalletData(showLoading: false);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(this.context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text('Payout account added'),
                                      ),
                                    );
                                  } catch (error) {
                                    setModalState(() {
                                      isSubmitting = false;
                                      modalError = error.toString();
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add_card_rounded, size: 18),
                          label: Text(isSubmitting ? 'Saving' : 'Save Account'),
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

  void _showWithdrawFundsModal(bool isDark) {
    const fee = 3.5;
    var isSubmitting = false;
    String? modalError;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final payoutAccounts = _savedPayoutAccounts;
              final selectedBank = payoutAccounts
                      .contains(_selectedWithdrawBank)
                  ? _selectedWithdrawBank
                  : (payoutAccounts.isNotEmpty ? payoutAccounts.first : null);
              if (selectedBank != null &&
                  selectedBank != _selectedWithdrawBank) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _selectedWithdrawBank = selectedBank);
                  }
                });
              }
              final amount =
                  double.tryParse(_withdrawAmountController.text.trim()) ?? 0;
              final netAmount =
                  (amount - fee).clamp(0.0, double.infinity).toDouble();
              final availableBalance = _walletBalance.toDouble();
              return Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFE2E8F0),
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
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Available: ${_formatMoney(availableBalance)}',
                      style: AppTypography.caption.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (payoutAccounts.isEmpty)
                      _buildNoPayoutAccountState(
                        isDark,
                        onAdd: () {
                          Navigator.pop(dialogContext);
                          _showAddPayoutAccountModal(isDark);
                        },
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedBank,
                              style: AppTypography.bodyMedium.copyWith(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                              dropdownColor:
                                  isDark ? AppColors.surfaceDark : Colors.white,
                              decoration: _walletInputDecoration(
                                  'Bank Account', isDark),
                              items: payoutAccounts
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
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: 'Add payout account',
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              _showAddPayoutAccountModal(isDark);
                            },
                            icon: const Icon(Icons.add_card_rounded),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _withdrawAmountController,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}$')),
                      ],
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        labelStyle: AppTypography.bodySmall.copyWith(
                          color:
                              isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                        prefixText: 'GHS ',
                        prefixStyle: AppTypography.bodyMedium.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        filled: true,
                        fillColor:
                            isDark ? Colors.white10 : AppColors.neutral100,
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text('GHS $quick',
                                style: AppTypography.caption),
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
                          color:
                              isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor:
                            isDark ? Colors.white10 : AppColors.neutral100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.03)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                              'Requested', _formatMoney(amount), isDark, null),
                          _buildDetailRow(
                              'Fee', _formatMoney(fee), isDark, null),
                          _buildDetailRow('Net Payout', _formatMoney(netAmount),
                              isDark, AppColors.primary),
                        ],
                      ),
                    ),
                    if (modalError != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildModalError(modalError!, isDark),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final submitAmount = double.tryParse(
                                      _withdrawAmountController.text.trim());
                                  if (submitAmount == null ||
                                      submitAmount <= 0) {
                                    setModalState(() =>
                                        modalError = 'Enter a valid amount.');
                                    return;
                                  }
                                  if (submitAmount > availableBalance) {
                                    setModalState(() => modalError =
                                        'Amount exceeds available balance.');
                                    return;
                                  }
                                  if (_ownerFarms.isEmpty) {
                                    setModalState(() => modalError =
                                        'No owned farm is linked to this account.');
                                    return;
                                  }
                                  if (selectedBank == null) {
                                    setModalState(() => modalError =
                                        'Add a payout account before withdrawing.');
                                    return;
                                  }

                                  final user = ref.read(authProvider).user;
                                  final farm = _ownerFarms.first;
                                  setModalState(() {
                                    isSubmitting = true;
                                    modalError = null;
                                  });
                                  try {
                                    await _api.createWalletWithdrawal(data: {
                                      'user_id': user?.id ?? '',
                                      'user_name': user?.name ?? 'Farm Owner',
                                      'farm_id': _docId(farm),
                                      'farm_name': _value(
                                        farm,
                                        ['name', 'farm_name'],
                                        fallback: 'Owned farm',
                                      ),
                                      'amount': submitAmount.toStringAsFixed(2),
                                      'bank_account': selectedBank,
                                      'note':
                                          _withdrawNoteController.text.trim(),
                                      'currency': 'GHS',
                                    });
                                    if (!mounted) return;
                                    setState(() => _selectedFilter = 'All');
                                    _withdrawAmountController.clear();
                                    _withdrawNoteController.clear();
                                    if (!dialogContext.mounted) return;
                                    Navigator.of(dialogContext).pop();
                                    await _loadWalletData(showLoading: false);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(this.context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Withdrawal request submitted'),
                                      ),
                                    );
                                  } catch (error) {
                                    setModalState(() {
                                      isSubmitting = false;
                                      modalError = error.toString();
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Submit'),
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
        final amount = _numValue(t['amount']);
        final isCredit = t['type'] == 'Credit';
        return [
          t['date'].toString(),
          t['description'].toString(),
          t['type'].toString(),
          t['status'].toString(),
          '${isCredit ? '+' : '-'}${_formatMoney(amount)}',
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
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFE2E8F0),
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
          final amount = _numValue(transaction['amount']);
          final color = transaction['color'] as Color;
          final statusColor =
              _transactionStatusColor(transaction['status'] as String);
          final baseColor =
              isDark ? Colors.white.withOpacity(0.02) : Colors.white;
          final altColor =
              isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC);

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
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : const Color(0xFFE2E8F0),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 110,
                      child:
                          Text(transaction['date'] as String, style: cellStyle),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
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
                        '${isCredit ? '+' : '-'}${_formatMoney(amount)}',
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
        }),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    final isCredit = transaction['type'] == 'Credit';
    final amount = _numValue(transaction['amount']);
    final color = transaction['color'] as Color;
    final statusColor =
        _transactionStatusColor(transaction['status'] as String);

    return InkWell(
      onTap: () => _showTransactionDetails(transaction, isDark),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: EdgeInsets.all(isMobile
            ? AppSpacing.sm
            : (isTablet ? AppSpacing.sm : AppSpacing.md)),
        decoration: BoxDecoration(
          color:
              isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE2E8F0),
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
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : AppColors.textSecondary,
                            fontSize: isMobile ? 10 : 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
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
                '${isCredit ? '+' : '-'}${_formatMoney(amount)}',
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
    final amount = _numValue(transaction['amount']);
    final color = transaction['color'] as Color;
    final statusColor =
        _transactionStatusColor(transaction['status'] as String);

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
              _buildDetailRow(
                  'Type', transaction['type'] as String, isDark, color),
              _buildDetailRow('Status', transaction['status'] as String, isDark,
                  statusColor),
              _buildDetailRow(
                  'Date', transaction['date'] as String, isDark, null),
              _buildDetailRow('Description',
                  transaction['description'] as String, isDark, null),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        color:
                            isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${isCredit ? '+' : '-'}${_formatMoney(amount)}',
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
                style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.textSecondary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(
      String label, String value, bool isDark, Color? accent) {
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
                color:
                    accent ?? (isDark ? Colors.white : AppColors.textPrimary),
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
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
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
                              : (isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : AppColors.textSecondary),
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
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
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
