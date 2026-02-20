import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_manager_sidebar.dart';
import '../../core/widgets/farm_manager_header.dart';
import '../../core/widgets/farm_manager_mobile_drawer.dart';
import '../../providers/auth_provider.dart';

/// Fund Request Screen for Farm Manager
/// Request budget allocations from accountant
class FundRequestScreen extends ConsumerStatefulWidget {
  const FundRequestScreen({super.key});

  @override
  ConsumerState<FundRequestScreen> createState() => _FundRequestScreenState();
}

class _FundRequestScreenState extends ConsumerState<FundRequestScreen>
    with SingleTickerProviderStateMixin {
  int _selectedNavIndex = 4;
  String _selectedStatus = 'All';
  String _searchQuery = '';
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  bool _showForm = false;

  // Form fields
  String? _selectedRequestFarm;
  String _requestAmount = '';
  String _requestPurpose = '';
  String _requestDescription = '';
  String _requestCategory = 'Operations';

  final List<String> _statusTabs = ['All', 'Pending', 'Approved', 'Rejected', 'Disbursed'];

  final List<Map<String, dynamic>> _requests = [
    {
      'id': 'FR-001',
      'farm': 'Green Valley Farm',
      'amount': 50000,
      'purpose': 'Seed Purchase',
      'category': 'Inputs',
      'status': 'Pending',
      'date': '2024-01-15',
      'requestedBy': 'John Okafor',
      'description': 'Purchase of improved tomato and pepper seedlings for the new growing season.',
      'priority': 'High',
    },
    {
      'id': 'FR-002',
      'farm': 'Sunny Acres',
      'amount': 30000,
      'purpose': 'Equipment Maintenance',
      'category': 'Maintenance',
      'status': 'Approved',
      'date': '2024-01-10',
      'requestedBy': 'John Okafor',
      'description': 'Routine maintenance for irrigation pumps and drip lines.',
      'priority': 'Medium',
    },
    {
      'id': 'FR-003',
      'farm': 'Fresh Farms',
      'amount': 75000,
      'purpose': 'Infrastructure Upgrade',
      'category': 'Capital',
      'status': 'Rejected',
      'date': '2024-01-05',
      'requestedBy': 'John Okafor',
      'description': 'Expansion of greenhouse facility to increase production capacity.',
      'priority': 'High',
    },
    {
      'id': 'FR-004',
      'farm': 'Green Valley Farm',
      'amount': 15000,
      'purpose': 'Pest Control Supplies',
      'category': 'Inputs',
      'status': 'Disbursed',
      'date': '2024-01-02',
      'requestedBy': 'John Okafor',
      'description': 'Organic pesticides and biological control agents for ongoing pest management.',
      'priority': 'Low',
    },
    {
      'id': 'FR-005',
      'farm': 'Sunny Acres',
      'amount': 22000,
      'purpose': 'Labour Wages',
      'category': 'Operations',
      'status': 'Pending',
      'date': '2024-01-18',
      'requestedBy': 'John Okafor',
      'description': 'Payment for casual labourers engaged during peak harvest period.',
      'priority': 'High',
    },
    {
      'id': 'FR-006',
      'farm': 'Fresh Farms',
      'amount': 8500,
      'purpose': 'Transport & Logistics',
      'category': 'Operations',
      'status': 'Approved',
      'date': '2024-01-12',
      'requestedBy': 'John Okafor',
      'description': 'Fuel and vehicle hire for delivering produce to distribution centres.',
      'priority': 'Medium',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedStatus = _statusTabs[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredRequests {
    final String query = _searchQuery ?? '';
    final String status = _selectedStatus ?? 'All';
    return _requests.where((r) {
      final matchesStatus = status == 'All' || r['status'] == status;
      if (query.isEmpty) return matchesStatus;
      final q = query.toLowerCase();
      final matchesSearch =
          (r['id']?.toString() ?? '').toLowerCase().contains(q) ||
          (r['farm']?.toString() ?? '').toLowerCase().contains(q) ||
          (r['purpose']?.toString() ?? '').toLowerCase().contains(q);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved': return AppColors.success;
      case 'Pending': return AppColors.warning;
      case 'Rejected': return AppColors.error;
      case 'Disbursed': return AppColors.info;
      default: return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Approved': return Icons.check_circle_rounded;
      case 'Pending': return Icons.schedule_rounded;
      case 'Rejected': return Icons.cancel_rounded;
      case 'Disbursed': return Icons.account_balance_wallet_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High': return AppColors.error;
      case 'Medium': return AppColors.warning;
      case 'Low': return AppColors.success;
      default: return AppColors.textSecondary;
    }
  }

  int _countByStatus(String status) {
    try { return _requests.where((r) => r['status'] == status).length; } catch (_) { return 0; }
  }

  double get _totalAmount {
    try { return _requests.fold<double>(0, (sum, r) => sum + ((r['amount'] ?? 0) as num).toDouble()); } catch (_) { return 0; }
  }

  double get _approvedAmount {
    try {
      return _requests.where((r) => r['status'] == 'Approved' || r['status'] == 'Disbursed')
          .fold<double>(0, (sum, r) => sum + ((r['amount'] ?? 0) as num).toDouble());
    } catch (_) { return 0; }
  }

  // ══════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Farm Manager';
    final userEmail = authState.user?.email ?? 'manager@farmestates.com';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? FarmManagerMobileDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (i) => setState(() => _selectedNavIndex = i),
              userName: userName,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail),
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _showCreateRequestDialog(context),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  // ── Desktop Layout ─────────────────────────────────────────────────────

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail) {
    return Row(children: [
      FarmManagerSidebar(
        selectedIndex: _selectedNavIndex,
        onItemSelected: (i) => setState(() => _selectedNavIndex = i),
        userName: userName,
        userEmail: userEmail,
        userRole: 'Farm Manager',
      ),
      Expanded(child: Column(children: [
        FarmManagerHeader(userName: userName, onNotificationTap: () {}),
        Expanded(child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: _buildContent(isDark, isMobile: false),
        )),
      ])),
    ]);
  }

  // ── Mobile Layout ──────────────────────────────────────────────────────

  Widget _buildMobileLayout(bool isDark, String userName) {
    return Column(children: [
      FarmManagerHeader(
        userName: userName,
        onNotificationTap: () {},
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      Expanded(child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _buildContent(isDark, isMobile: true),
      )),
    ]);
  }

  // ── Main Content ───────────────────────────────────────────────────────

  Widget _buildContent(bool isDark, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(isDark, isMobile),
        SizedBox(height: isMobile ? 16 : 24),
        _buildStatsRow(isDark, isMobile),
        SizedBox(height: isMobile ? 16 : 24),
        _buildRequestsSection(isDark, isMobile),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // PAGE HEADER
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildPageHeader(bool isDark, bool isMobile) {
    return Row(children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fund Requests',
            style: GoogleFonts.inter(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Request and track budget allocations for farm operations',
            style: GoogleFonts.inter(
              fontSize: isMobile ? 12 : 14,
              color: isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary,
            ),
          ),
        ],
      )),
      if (!isMobile) ...[
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _showCreateRequestDialog(context),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text('New Request', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          ),
        ),
      ],
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════
  // STATS ROW
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildStatsRow(bool isDark, bool isMobile) {
    final stats = [
      {'label': 'Total Requests', 'value': '${_requests.length}', 'icon': Icons.request_quote_outlined, 'color': AppColors.primary},
      {'label': 'Pending', 'value': '${_countByStatus('Pending')}', 'icon': Icons.schedule_rounded, 'color': AppColors.warning},
      {'label': 'Approved', 'value': '${_countByStatus('Approved') + _countByStatus('Disbursed')}', 'icon': Icons.check_circle_outline_rounded, 'color': AppColors.success},
      {'label': 'Total Amount', 'value': 'GH₵${(_totalAmount / 1000).toStringAsFixed(0)}K', 'icon': Icons.account_balance_wallet_outlined, 'color': AppColors.info},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: isMobile ? 10 : 14,
      mainAxisSpacing: isMobile ? 10 : 14,
      childAspectRatio: isMobile ? 2.4 : 2.8,
      children: stats.map((s) => _buildStatCard(s, isDark, isMobile)).toList(),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, bool isDark, bool isMobile) {
    final color = stat['color'] as Color;
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(isDark ? 0.12 : 0.1)),
        boxShadow: isDark ? null : [BoxShadow(color: color.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 8 : 10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(stat['icon'] as IconData, size: isMobile ? 18 : 20, color: color),
        ),
        SizedBox(width: isMobile ? 10 : 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(stat['value'] as String, style: GoogleFonts.inter(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary, height: 1)),
            const SizedBox(height: 2),
            Text(stat['label'] as String, style: GoogleFonts.inter(fontSize: isMobile ? 10 : 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withOpacity(0.4) : AppColors.textSecondary)),
          ],
        )),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // REQUESTS SECTION (tabs + search + table/cards)
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildRequestsSection(bool isDark, bool isMobile) {
    final requests = _filteredRequests;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
                child: Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.warning),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('Fund Requests', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: Text('${requests.length} requests', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warning)),
              ),
              if (isMobile) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showCreateRequestDialog(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ]),
          ),

          // Status tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              height: 34,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark ? Colors.white.withOpacity(0.4) : AppColors.textSecondary,
                labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
                labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                tabs: _statusTabs.map((t) {
                  final count = t == 'All' ? _requests.length : _countByStatus(t);
                  return Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(t),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _selectedStatus == t ? AppColors.primary.withOpacity(0.15) : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$count', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ]));
                }).toList(),
              ),
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by ID, farm, or purpose...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white24 : AppColors.textSecondary),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: isDark ? Colors.white24 : AppColors.textSecondary),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              )),
              if (!isMobile) ...[
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _showCreateRequestDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text('New Request', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ]),
          ),

          // Content
          if (requests.isEmpty)
            _buildEmptyState(isDark)
          else if (isMobile)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _buildRequestCard(requests[i], isDark),
              ),
            )
          else
            _buildRequestTable(requests, isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.06), shape: BoxShape.circle),
          child: Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.warning.withOpacity(0.4)),
        ),
        const SizedBox(height: 16),
        Text('No requests found', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text('Create a new fund request to get started', style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white24 : AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _showCreateRequestDialog(context),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text('New Request', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        ),
      ])),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // DESKTOP TABLE
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildRequestTable(List<Map<String, dynamic>> requests, bool isDark) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
            border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))),
          ),
          child: Row(children: [
            _th('ID', 2, isDark),
            _th('Farm', 2, isDark),
            _th('Purpose', 2, isDark),
            _th('Category', 1, isDark),
            _th('Amount', 2, isDark),
            _th('Status', 2, isDark),
            _th('Priority', 1, isDark),
            _th('Date', 2, isDark),
            _th('', 1, isDark),
          ]),
        ),
        // Rows
        ...requests.asMap().entries.map((entry) {
          return _buildTableRow(entry.value, isDark, entry.key % 2 != 0);
        }),
      ]),
    );
  }

  Widget _th(String label, int flex, bool isDark) {
    return Expanded(
      flex: flex,
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : AppColors.textSecondary, letterSpacing: 0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> r, bool isDark, bool isOdd) {
    final status = r['status'] as String;
    final sColor = _statusColor(status);
    final priority = r['priority'] as String;
    final pColor = _priorityColor(priority);
    final amount = r['amount'] as num;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showRequestDetails(r),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: isOdd ? (isDark ? Colors.white.withOpacity(0.02) : AppColors.neutral50.withOpacity(0.5)) : Colors.transparent,
            border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04))),
          ),
          child: Row(children: [
            // ID
            Expanded(flex: 2, child: Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: sColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(r['id'] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ])),
            // Farm
            Expanded(flex: 2, child: Row(children: [
              Icon(Icons.location_on_outlined, size: 12, color: isDark ? Colors.white24 : AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(child: Text(r['farm'] as String, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ])),
            // Purpose
            Expanded(flex: 2, child: Text(r['purpose'] as String, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            // Category
            Expanded(flex: 1, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(6)),
              child: Text(r['category'] as String, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: isDark ? Colors.white54 : AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
            // Amount
            Expanded(flex: 2, child: Text('GH₵${_formatAmount(amount.toDouble())}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary))),
            // Status
            Expanded(flex: 2, child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: sColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: sColor.withOpacity(0.2))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_statusIcon(status), size: 11, color: sColor),
                  const SizedBox(width: 4),
                  Text(status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: sColor)),
                ]),
              ),
            ])),
            // Priority
            Expanded(flex: 1, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: pColor.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
              child: Text(priority, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: pColor)),
            )),
            // Date
            Expanded(flex: 2, child: Text(r['date'] as String, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white54 : AppColors.textSecondary))),
            // Actions
            Expanded(flex: 1, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              _actionBtn(Icons.visibility_outlined, 'View', () => _showRequestDetails(r), isDark),
              const SizedBox(width: 4),
              _actionBtn(Icons.delete_outline_rounded, 'Delete', () => _deleteRequest(r), isDark, isDestructive: true),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String tooltip, VoidCallback onTap, bool isDark, {bool isDestructive = false}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isDestructive ? AppColors.error.withOpacity(0.06) : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: isDestructive ? AppColors.error : (isDark ? Colors.white54 : AppColors.textSecondary)),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // MOBILE CARD
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildRequestCard(Map<String, dynamic> r, bool isDark) {
    final status = r['status'] as String;
    final sColor = _statusColor(status);
    final priority = r['priority'] as String;
    final pColor = _priorityColor(priority);
    final amount = r['amount'] as num;

    return GestureDetector(
      onTap: () => _showRequestDetails(r),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
          boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [sColor, sColor.withOpacity(0.75)]),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(_statusIcon(status), size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r['id'] as String, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: 1),
              Row(children: [
                Icon(Icons.location_on_outlined, size: 11, color: isDark ? Colors.white38 : AppColors.textSecondary),
                const SizedBox(width: 3),
                Expanded(child: Text(r['farm'] as String, style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white38 : AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: sColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: sColor.withOpacity(0.2))),
              child: Text(status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: sColor)),
            ),
          ]),
          const SizedBox(height: 14),

          // Amount row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Amount Requested', style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white24 : AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text('GH₵${_formatAmount(amount.toDouble())}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary, height: 1.1)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: pColor.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.flag_rounded, size: 10, color: pColor),
                    const SizedBox(width: 3),
                    Text(priority, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: pColor)),
                  ]),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(6)),
                  child: Text(r['category'] as String, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500, color: isDark ? Colors.white38 : AppColors.textSecondary)),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 10),

          // Details row
          Row(children: [
            _cardDetail(Icons.label_outline_rounded, r['purpose'] as String, isDark),
            const SizedBox(width: 10),
            _cardDetail(Icons.calendar_today_rounded, r['date'] as String, isDark),
          ]),
          const SizedBox(height: 10),

          // Description preview
          Text(
            r['description'] as String,
            style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white38 : AppColors.textSecondary, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ]),
      ),
    );
  }

  Widget _cardDetail(IconData icon, String text, bool isDark) {
    return Expanded(child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: isDark ? Colors.white24 : AppColors.textSecondary),
      const SizedBox(width: 4),
      Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white54 : AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]));
  }

  // ══════════════════════════════════════════════════════════════════════
  // REQUEST DETAILS DIALOG
  // ══════════════════════════════════════════════════════════════════════

  void _showRequestDetails(Map<String, dynamic> r) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = r['status'] as String;
    final sColor = _statusColor(status);
    final amount = r['amount'] as num;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [sColor, sColor.withOpacity(0.75)]), borderRadius: BorderRadius.circular(10)),
                    child: Icon(_statusIcon(status), size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r['id'] as String, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary)),
                    Text(r['farm'] as String, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white38 : AppColors.textSecondary)),
                  ])),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.close_rounded, size: 16, color: isDark ? Colors.white38 : AppColors.textSecondary),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                // Amount + Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Amount Requested', style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white24 : AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('GH₵${_formatAmount(amount.toDouble())}', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: sColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: sColor.withOpacity(0.2))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_statusIcon(status), size: 14, color: sColor),
                        const SizedBox(width: 4),
                        Text(status, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: sColor)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // Detail rows
                _detailRow('Purpose', r['purpose'] as String, Icons.label_outline_rounded, isDark),
                _detailRow('Category', r['category'] as String, Icons.category_outlined, isDark),
                _detailRow('Priority', r['priority'] as String, Icons.flag_outlined, isDark),
                _detailRow('Date', r['date'] as String, Icons.calendar_today_outlined, isDark),
                _detailRow('Requested By', r['requestedBy'] as String, Icons.person_outline_rounded, isDark),

                // Description
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50, borderRadius: BorderRadius.circular(10), border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Description', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(r['description'] as String, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textPrimary, height: 1.5)),
                  ]),
                ),
                const SizedBox(height: 20),

                // Actions
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08))),
                    child: Text('Close', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                  )),
                  const SizedBox(width: 8),
                  if (status == 'Pending')
                    Expanded(child: ElevatedButton.icon(
                      onPressed: () { Navigator.of(context).pop(); _editRequest(r); },
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: Text('Edit Request', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    )),
                ]),
              ],
            )),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 14, color: isDark ? Colors.white24 : AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(width: 100, child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white38 : AppColors.textSecondary))),
        Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary))),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // CREATE REQUEST DIALOG
  // ══════════════════════════════════════════════════════════════════════

  void _showCreateRequestDialog(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    String farm = '';
    String amount = '';
    String purpose = '';
    String description = '';
    String category = 'Operations';
    String priority = 'Medium';

    showDialog(
      context: ctx,
      builder: (_) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)]), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add_circle_outline_rounded, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('New Fund Request', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary)),
                    Text('Request budget allocation for operations', style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white38 : AppColors.textSecondary)),
                  ])),
                  InkWell(
                    onTap: () => Navigator.of(ctx).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.close_rounded, size: 16, color: isDark ? Colors.white38 : AppColors.textSecondary),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),

                // Farm dropdown
                _dialogLabel('Farm', isDark),
                const SizedBox(height: 6),
                StatefulBuilder(builder: (context, setLocal) {
                  return DropdownButtonFormField<String>(
                    value: farm.isEmpty ? null : farm,
                    hint: Text('Select farm', style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white24 : AppColors.textSecondary)),
                    decoration: _dialogInputDecoration(isDark),
                    style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white : AppColors.textPrimary),
                    dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                    items: ['Green Valley Farm', 'Sunny Acres', 'Fresh Farms'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                    onChanged: (v) => setLocal(() => farm = v ?? ''),
                  );
                }),
                const SizedBox(height: 14),

                // Amount + Category
                Row(children: [
                  Expanded(child: _dialogField('Amount (GH₵)', 'e.g. 50000', Icons.payments_outlined, isDark, onChanged: (v) => amount = v, inputType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _dialogLabel('Category', isDark),
                    const SizedBox(height: 6),
                    StatefulBuilder(builder: (context, setLocal) {
                      return DropdownButtonFormField<String>(
                        value: category,
                        decoration: _dialogInputDecoration(isDark),
                        style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white : AppColors.textPrimary),
                        dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                        items: ['Operations', 'Inputs', 'Maintenance', 'Capital', 'Labour'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setLocal(() => category = v ?? 'Operations'),
                      );
                    }),
                  ])),
                ]),
                const SizedBox(height: 14),

                // Purpose + Priority
                Row(children: [
                  Expanded(child: _dialogField('Purpose', 'e.g. Seed Purchase', Icons.label_outline_rounded, isDark, onChanged: (v) => purpose = v)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _dialogLabel('Priority', isDark),
                    const SizedBox(height: 6),
                    StatefulBuilder(builder: (context, setLocal) {
                      return DropdownButtonFormField<String>(
                        value: priority,
                        decoration: _dialogInputDecoration(isDark),
                        style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white : AppColors.textPrimary),
                        dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                        items: ['High', 'Medium', 'Low'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (v) => setLocal(() => priority = v ?? 'Medium'),
                      );
                    }),
                  ])),
                ]),
                const SizedBox(height: 14),

                _dialogField('Description', 'Describe the purpose of this fund request...', Icons.description_outlined, isDark, onChanged: (v) => description = v, maxLines: 3),
                const SizedBox(height: 24),

                // Submit
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08))),
                    child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Fund request submitted — GH₵$amount for $purpose'), backgroundColor: AppColors.success));
                    },
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: Text('Submit Request', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  )),
                ]),
              ],
            )),
          ),
        ),
      ),
    );
  }

  Widget _dialogLabel(String label, bool isDark) {
    return Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : AppColors.textSecondary));
  }

  InputDecoration _dialogInputDecoration(bool isDark) {
    return InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }

  Widget _dialogField(String label, String hint, IconData icon, bool isDark, {required ValueChanged<String> onChanged, TextInputType inputType = TextInputType.text, int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _dialogLabel(label, isDark),
      const SizedBox(height: 6),
      TextFormField(
        onChanged: onChanged,
        keyboardType: inputType,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white : AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white24 : AppColors.textSecondary),
          prefixIcon: maxLines == 1 ? Icon(icon, size: 16, color: isDark ? Colors.white24 : AppColors.textSecondary) : null,
          filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    ]);
  }

  // ── Utilities ──────────────────────────────────────────────────────────

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)},${(amount % 1000).toStringAsFixed(0).padLeft(3, '0')}';
    return amount.toStringAsFixed(0);
  }

  void _editRequest(Map<String, dynamic> r) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final farmCtrl = TextEditingController(text: r['farm'] as String? ?? '');
    final amountCtrl = TextEditingController(text: (r['amount'] ?? '').toString());
    final purposeCtrl = TextEditingController(text: r['purpose'] as String? ?? '');
    final descCtrl = TextEditingController(text: r['description'] as String? ?? '');
    String category = r['category'] as String? ?? 'Operations';
    String priority = r['priority'] as String? ?? 'Medium';
    String farm = r['farm'] as String? ?? '';

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.warning, AppColors.warning.withOpacity(0.75)]), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.edit_rounded, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Edit Request ${r['id']}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary)),
                    Text('Update the fund request details', style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white38 : AppColors.textSecondary)),
                  ])),
                  InkWell(
                    onTap: () => Navigator.of(dialogCtx).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.close_rounded, size: 16, color: isDark ? Colors.white38 : AppColors.textSecondary),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),

                // Farm dropdown
                _dialogLabel('Farm', isDark),
                const SizedBox(height: 6),
                StatefulBuilder(builder: (context, setLocal) {
                  return DropdownButtonFormField<String>(
                    value: farm.isNotEmpty ? farm : null,
                    hint: Text('Select farm', style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white24 : AppColors.textSecondary)),
                    decoration: _dialogInputDecoration(isDark),
                    style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white : AppColors.textPrimary),
                    dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                    items: ['Green Valley Farm', 'Sunny Acres', 'Fresh Farms'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                    onChanged: (v) => setLocal(() { farm = v ?? ''; farmCtrl.text = farm; }),
                  );
                }),
                const SizedBox(height: 14),

                // Amount + Category
                Row(children: [
                  Expanded(child: _dialogFieldEditable('Amount (GH₵)', 'e.g. 50000', Icons.payments_outlined, isDark, controller: amountCtrl, inputType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _dialogLabel('Category', isDark),
                    const SizedBox(height: 6),
                    StatefulBuilder(builder: (context, setLocal) {
                      return DropdownButtonFormField<String>(
                        value: category,
                        decoration: _dialogInputDecoration(isDark),
                        style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white : AppColors.textPrimary),
                        dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                        items: ['Operations', 'Inputs', 'Maintenance', 'Capital', 'Labour'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setLocal(() => category = v ?? 'Operations'),
                      );
                    }),
                  ])),
                ]),
                const SizedBox(height: 14),

                // Purpose + Priority
                Row(children: [
                  Expanded(child: _dialogFieldEditable('Purpose', 'e.g. Seed Purchase', Icons.label_outline_rounded, isDark, controller: purposeCtrl)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _dialogLabel('Priority', isDark),
                    const SizedBox(height: 6),
                    StatefulBuilder(builder: (context, setLocal) {
                      return DropdownButtonFormField<String>(
                        value: priority,
                        decoration: _dialogInputDecoration(isDark),
                        style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white : AppColors.textPrimary),
                        dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                        items: ['High', 'Medium', 'Low'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (v) => setLocal(() => priority = v ?? 'Medium'),
                      );
                    }),
                  ])),
                ]),
                const SizedBox(height: 14),

                _dialogFieldEditable('Description', 'Describe the purpose...', Icons.description_outlined, isDark, controller: descCtrl, maxLines: 3),
                const SizedBox(height: 24),

                // Actions
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08))),
                    child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () {
                      // Update the request data
                      setState(() {
                        final index = _requests.indexOf(r);
                        if (index != -1) {
                          _requests[index] = {
                            ...r,
                            'farm': farm,
                            'amount': int.tryParse(amountCtrl.text) ?? r['amount'],
                            'purpose': purposeCtrl.text.isNotEmpty ? purposeCtrl.text : r['purpose'],
                            'category': category,
                            'priority': priority,
                            'description': descCtrl.text.isNotEmpty ? descCtrl.text : r['description'],
                          };
                        }
                      });
                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
                        content: Row(children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${r['id']} updated successfully')),
                        ]),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ));
                    },
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: Text('Save Changes', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  )),
                ]),
              ],
            )),
          ),
        ),
      ),
    ).then((_) {
      farmCtrl.dispose();
      amountCtrl.dispose();
      purposeCtrl.dispose();
      descCtrl.dispose();
    });
  }

  /// Text field with a pre-filled [TextEditingController] for edit dialogs.
  Widget _dialogFieldEditable(String label, String hint, IconData icon, bool isDark, {required TextEditingController controller, TextInputType inputType = TextInputType.text, int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _dialogLabel(label, isDark),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: inputType,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white : AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white24 : AppColors.textSecondary),
          prefixIcon: maxLines == 1 ? Icon(icon, size: 16, color: isDark ? Colors.white24 : AppColors.textSecondary) : null,
          filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    ]);
  }

  void _deleteRequest(Map<String, dynamic> r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Delete Request', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete ${r['id']}?', style: GoogleFonts.inter(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13))),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); setState(() => _requests.remove(r)); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text('Delete', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard', 'index': 0, 'route': '/farm-manager'},
      {'icon': Icons.agriculture_outlined, 'label': 'Farms', 'index': 1, 'route': '/farm-manager/farms'},
      {'icon': Icons.inventory_2_outlined, 'label': 'Inventory', 'index': 2, 'route': '/farm-manager/inventory'},
      {'icon': Icons.local_shipping_outlined, 'label': 'Deliveries', 'index': 3, 'route': '/farm-manager/deliveries'},
      {'icon': Icons.assessment_outlined, 'label': 'Reports', 'index': 4, 'route': '/farm-manager/reports'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.08), blurRadius: 16, offset: const Offset(0, -2))],
        border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))),
      ),
      child: SafeArea(child: SizedBox(
        height: 62,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: navItems.map((item) {
            final index = item['index'] as int;
            // Fund request is not in bottom nav, so none selected
            const isSelected = false;

            return Expanded(child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  try { Navigator.pushReplacementNamed(context, item['route'] as String); } catch (_) {}
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 6.5),
                    Icon(item['icon'] as IconData, size: 20, color: isDark ? Colors.white.withOpacity(0.4) : AppColors.textSecondary),
                    const SizedBox(height: 3),
                    Text(item['label'] as String, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withOpacity(0.4) : AppColors.textSecondary)),
                  ],
                ),
              ),
            ));
          }).toList(),
        ),
      )),
    );
  }
}
