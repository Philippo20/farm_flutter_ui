import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_manager_sidebar.dart';
import '../../core/widgets/farm_manager_header.dart';
import '../../providers/auth_provider.dart';

/// Fund Request Screen for Farm Manager
/// Request budget allocations from accountant
class FundRequestScreen extends ConsumerStatefulWidget {
  const FundRequestScreen({super.key});

  @override
  ConsumerState<FundRequestScreen> createState() => _FundRequestScreenState();
}

class _FundRequestScreenState extends ConsumerState<FundRequestScreen> {
  int _selectedNavIndex = 3;
  String _selectedStatus = 'All';
  String _selectedFarm = 'All Farms';
  final _formKey = GlobalKey<FormState>();

  // Form fields
  String? _selectedRequestFarm;
  String _requestAmount = '';
  String _requestPurpose = '';
  String _requestDescription = '';

  final List<Map<String, dynamic>> _requests = [
    {
      'id': 'FR001',
      'farm': 'Green Valley Farm',
      'amount': 50000,
      'purpose': 'Seed Purchase',
      'status': 'Pending',
      'date': '2024-01-15',
      'requestedBy': 'Farm Manager',
    },
    {
      'id': 'FR002',
      'farm': 'Sunny Acres',
      'amount': 30000,
      'purpose': 'Equipment Maintenance',
      'status': 'Approved',
      'date': '2024-01-10',
      'requestedBy': 'Farm Manager',
    },
    {
      'id': 'FR003',
      'farm': 'Fresh Farms',
      'amount': 75000,
      'purpose': 'Infrastructure Upgrade',
      'status': 'Rejected',
      'date': '2024-01-05',
      'requestedBy': 'Farm Manager',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Farm Manager';
    final userEmail = authState.user?.email ?? 'manager@farmestates.com';
    final userRole = 'Farm Manager';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail, String userRole) {
    return Row(
      children: [
        FarmManagerSidebar(
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
              FarmManagerHeader(
                userName: userName,
                onNotificationTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isDark, isMobile: false),
                      const SizedBox(height: AppSpacing.xl),
                      _buildStatsCards(isDark, isMobile: false),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildRequestForm(isDark, isMobile: false),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            flex: 3,
                            child: _buildRequestsList(isDark, isMobile: false),
                          ),
                        ],
                      ),
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
        FarmManagerHeader(
          userName: userName,
          onNotificationTap: () {},
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDark, isMobile: true),
                const SizedBox(height: AppSpacing.lg),
                _buildStatsCards(isDark, isMobile: true),
                const SizedBox(height: AppSpacing.lg),
                _buildRequestForm(isDark, isMobile: true),
                const SizedBox(height: AppSpacing.lg),
                _buildRequestsList(isDark, isMobile: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark, {bool isMobile = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fund Requests',
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: isMobile ? 20 : 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Request budget allocations for farm operations',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ],
        ),
        if (!isMobile)
          ElevatedButton.icon(
            onPressed: () => _showRequestDialog(isDark),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('New Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsCards(bool isDark, {bool isMobile = false}) {
    final pending = _requests.where((r) => r['status'] == 'Pending').length;
    final approved = _requests.where((r) => r['status'] == 'Approved').length;
    final totalAmount =
        _requests.fold<double>(0, (sum, r) => sum + (r['amount'] as num).toDouble());

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: isMobile ? 2.8 : 3.2,
          children: [
            _buildStatCard('Total Requests', '${_requests.length}', Icons.request_quote,
                AppColors.primary, isDark),
            _buildStatCard('Pending', '$pending', Icons.pending, AppColors.warning, isDark),
            _buildStatCard('Approved', '$approved', Icons.check_circle, AppColors.success, isDark),
            _buildStatCard('Total Amount', '\$${(totalAmount / 1000).toStringAsFixed(1)}K',
                Icons.attach_money, AppColors.info, isDark),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isDark ? 0.15 : 0.9),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: AppTypography.h6.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestForm(bool isDark, {bool isMobile = false}) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Fund Request',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildDropdownField(
                    'Farm',
                    _selectedRequestFarm,
                    ['Green Valley Farm', 'Sunny Acres', 'Fresh Farms'],
                    (v) => setState(() => _selectedRequestFarm = v),
                    isDark,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField('Amount (\$)', _requestAmount, (v) => _requestAmount = v, isDark,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField('Purpose', _requestPurpose, (v) => _requestPurpose = v, isDark),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(
                      'Description', _requestDescription, (v) => _requestDescription = v, isDark,
                      maxLines: 3),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _submitRequest(isDark),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                      ),
                      child: const Text('Submit Request'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(bool isDark, {bool isMobile = false}) {
    final filteredRequests = _requests.where((r) {
      if (_selectedFarm != 'All Farms' &&
          !r['farm'].toString().contains(_selectedFarm.replaceAll(' Farms', ''))) return false;
      if (_selectedStatus != 'All' && r['status'] != _selectedStatus) return false;
      return true;
    }).toList();

    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Recent Requests',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: isMobile ? 16 : 18,
                  ),
                ),
                if (isMobile) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFilterDropdown(
                            'Farm',
                            _selectedFarm,
                            ['All Farms', 'Green Valley', 'Sunny Acres'],
                            (v) => setState(() => _selectedFarm = v!),
                            isDark,
                            isMobile: true),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: _buildFilterDropdown(
                            'Status',
                            _selectedStatus,
                            ['All', 'Pending', 'Approved', 'Rejected'],
                            (v) => setState(() => _selectedStatus = v!),
                            isDark,
                            isMobile: true),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Flexible(
                        child: _buildFilterDropdown(
                            'Farm',
                            _selectedFarm,
                            ['All Farms', 'Green Valley', 'Sunny Acres'],
                            (v) => setState(() => _selectedFarm = v!),
                            isDark,
                            isMobile: false),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: _buildFilterDropdown(
                            'Status',
                            _selectedStatus,
                            ['All', 'Pending', 'Approved', 'Rejected'],
                            (v) => setState(() => _selectedStatus = v!),
                            isDark,
                            isMobile: false),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isMobile) ...[
            if (filteredRequests.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: isDark
                            ? Colors.white.withOpacity(0.3)
                            : AppColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No requests found',
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      filteredRequests.map((r) => _buildMobileRequestCard(r, isDark)).toList(),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ] else
            _buildDesktopTable(isDark),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
            ),
            child: Row(
              children: [
                const Expanded(
                    flex: 2,
                    child: Text('ID', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                const Expanded(
                    flex: 2,
                    child:
                        Text('Farm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                const Expanded(
                    flex: 2,
                    child: Text('Amount',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                const Expanded(
                    flex: 2,
                    child: Text('Purpose',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                const Expanded(
                    flex: 2,
                    child: Text('Status',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                const Expanded(
                    flex: 2,
                    child:
                        Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                const SizedBox(
                    width: 80,
                    child: Text('Actions',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        textAlign: TextAlign.center)),
              ],
            ),
          ),
          // Table Rows
          ..._requests.where((r) {
            if (_selectedFarm != 'All Farms' &&
                !r['farm'].toString().contains(_selectedFarm.replaceAll(' Farms', '')))
              return false;
            if (_selectedStatus != 'All' && r['status'] != _selectedStatus) return false;
            return true;
          }).map((r) => _buildRequestRow(r, isDark)),
        ],
      ),
    );
  }

  Widget _buildRequestRow(Map<String, dynamic> request, bool isDark) {
    final statusColor = request['status'] == 'Approved'
        ? AppColors.success
        : request['status'] == 'Pending'
            ? AppColors.warning
            : AppColors.error;

    return Container(
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
      ),
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                  flex: 2,
                  child: Text(request['id'],
                      style: TextStyle(
                          fontSize: 12, color: isDark ? Colors.white : AppColors.textPrimary))),
              Expanded(
                  flex: 2,
                  child: Text(request['farm'],
                      style: TextStyle(
                          fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary))),
              Expanded(
                  flex: 2,
                  child: Text('\$${request['amount']}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary))),
              Expanded(
                  flex: 2,
                  child: Text(request['purpose'],
                      style: TextStyle(
                          fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis)),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    request['status'],
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                  flex: 2,
                  child: Text(request['date'],
                      style: TextStyle(
                          fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary))),
              SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.visibility_outlined),
                        iconSize: 18,
                        color: AppColors.primary),
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.delete_outline),
                        iconSize: 18,
                        color: AppColors.error),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileRequestCard(Map<String, dynamic> request, bool isDark) {
    final statusColor = request['status'] == 'Approved'
        ? AppColors.success
        : request['status'] == 'Pending'
            ? AppColors.warning
            : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.2) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: ID and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  request['id'] as String,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  request['status'] as String,
                  style: AppTypography.caption.copyWith(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Farm Name
          Text(
            request['farm'] as String,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              color: isDark ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          // Amount and Date Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '\$${request['amount']}',
                  style: AppTypography.h6.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                request['date'] as String,
                style: AppTypography.caption.copyWith(
                  fontSize: 10,
                  color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Purpose
          Text(
            request['purpose'] as String,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              color: isDark ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
      String label, String? value, List<String> items, Function(String?) onChanged, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : AppColors.neutral100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
          ),
          child: DropdownButton<String>(
            value: value,
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String value, Function(String) onChanged, bool isDark,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          onChanged: onChanged,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.white10 : AppColors.neutral100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
      String label, String value, List<String> items, Function(String?) onChanged, bool isDark,
      {bool isMobile = false}) {
    return SizedBox(
      height: isMobile ? 36 : 40,
      child: Container(
        constraints: BoxConstraints(
          minWidth: isMobile ? 100 : 120,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.xs : AppSpacing.sm,
          vertical: isMobile ? 4 : 8,
        ),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
            width: 1,
          ),
        ),
        child: DropdownButton<String>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          underline: const SizedBox(),
          icon: Icon(
            Icons.arrow_drop_down,
            size: isMobile ? 16 : 18,
            color: isDark ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
          ),
          isDense: true,
          isExpanded: true,
          style: TextStyle(
            fontSize: isMobile ? 11 : 12,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  void _showRequestDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Fund Request'),
        content: const Text('Use the form on the left to create a new fund request.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _submitRequest(bool isDark) {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fund request submitted successfully')),
      );
      _formKey.currentState!.reset();
      setState(() {
        _selectedRequestFarm = null;
        _requestAmount = '';
        _requestPurpose = '';
        _requestDescription = '';
      });
    }
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/farm-manager'
      },
      {
        'icon': Icons.inventory_2_outlined,
        'label': 'Inventory',
        'index': 1,
        'route': '/farm-manager/inventory'
      },
      {
        'icon': Icons.grid_view_outlined,
        'label': 'Batches',
        'index': 2,
        'route': '/farm-manager/batch-generation'
      },
      {
        'icon': Icons.request_quote_outlined,
        'label': 'Funds',
        'index': 3,
        'route': '/farm-manager/fund-request'
      },
      {
        'icon': Icons.assessment_outlined,
        'label': 'Reports',
        'index': 4,
        'route': '/farm-manager/reports'
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
