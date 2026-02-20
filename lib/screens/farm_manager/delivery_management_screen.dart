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

/// Delivery Management Screen for Farm Manager
/// Schedule, track, and manage deliveries from farm to buyers/distributors
class DeliveryManagementScreen extends ConsumerStatefulWidget {
  const DeliveryManagementScreen({super.key});

  @override
  ConsumerState<DeliveryManagementScreen> createState() =>
      _DeliveryManagementScreenState();
}

class _DeliveryManagementScreenState
    extends ConsumerState<DeliveryManagementScreen>
    with SingleTickerProviderStateMixin {
  int _selectedNavIndex = 5;
  String _selectedTab = 'All';
  String _searchQuery = '';
  final _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;

  // ── Mock data ──────────────────────────────────────────────────────────

  final List<Map<String, dynamic>> _deliveries = [
    {
      'id': 'DEL-001',
      'batch': 'BATCH-2024-001',
      'destination': 'Fresh Mart Supermarket',
      'address': '12 Victoria Island, Lagos',
      'quantity': 500,
      'unit': 'heads',
      'crop': 'Lettuce',
      'status': 'In Transit',
      'driver': 'Adebayo Okonkwo',
      'vehicle': 'Toyota Dyna - LG 234 ABC',
      'scheduledDate': '2024-01-28',
      'estimatedArrival': '2024-01-28 14:30',
      'temperature': '4°C',
      'priority': 'High',
    },
    {
      'id': 'DEL-002',
      'batch': 'BATCH-2024-003',
      'destination': 'Shoprite Ikeja',
      'address': 'Ikeja City Mall, Lagos',
      'quantity': 300,
      'unit': 'heads',
      'crop': 'Spinach',
      'status': 'Delivered',
      'driver': 'Chinedu Eze',
      'vehicle': 'Hyundai H100 - LG 567 DEF',
      'scheduledDate': '2024-01-27',
      'estimatedArrival': '2024-01-27 11:00',
      'temperature': '3°C',
      'priority': 'Medium',
    },
    {
      'id': 'DEL-003',
      'batch': 'BATCH-2024-002',
      'destination': 'Jara Foods Distribution',
      'address': '45 Lekki Phase 1, Lagos',
      'quantity': 1000,
      'unit': 'kg',
      'crop': 'Tomatoes',
      'status': 'Scheduled',
      'driver': 'Unassigned',
      'vehicle': 'Pending',
      'scheduledDate': '2024-01-30',
      'estimatedArrival': '2024-01-30 09:00',
      'temperature': 'N/A',
      'priority': 'High',
    },
    {
      'id': 'DEL-004',
      'batch': 'BATCH-2024-005',
      'destination': 'Spar Lekki',
      'address': 'Spar Circle Mall, Lekki',
      'quantity': 200,
      'unit': 'heads',
      'crop': 'Cabbage',
      'status': 'Pending Pickup',
      'driver': 'Adebayo Okonkwo',
      'vehicle': 'Toyota Dyna - LG 234 ABC',
      'scheduledDate': '2024-01-29',
      'estimatedArrival': '2024-01-29 16:00',
      'temperature': '5°C',
      'priority': 'Low',
    },
    {
      'id': 'DEL-005',
      'batch': 'BATCH-2024-004',
      'destination': 'Hubmart Stores',
      'address': 'Maryland, Lagos',
      'quantity': 750,
      'unit': 'heads',
      'crop': 'Lettuce',
      'status': 'Cancelled',
      'driver': 'N/A',
      'vehicle': 'N/A',
      'scheduledDate': '2024-01-26',
      'estimatedArrival': 'N/A',
      'temperature': 'N/A',
      'priority': 'Medium',
    },
    {
      'id': 'DEL-006',
      'batch': 'BATCH-2024-006',
      'destination': 'Next Cash & Carry',
      'address': 'Jabi, Abuja',
      'quantity': 400,
      'unit': 'kg',
      'crop': 'Peppers',
      'status': 'In Transit',
      'driver': 'Ibrahim Musa',
      'vehicle': 'Mitsubishi Canter - ABJ 890 GHI',
      'scheduledDate': '2024-01-28',
      'estimatedArrival': '2024-01-29 08:00',
      'temperature': '6°C',
      'priority': 'High',
    },
  ];

  final List<String> _statusTabs = [
    'All',
    'Scheduled',
    'Pending Pickup',
    'In Transit',
    'Delivered',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _statusTabs[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredDeliveries {
    return _deliveries.where((d) {
      final matchesTab =
          _selectedTab == 'All' || d['status'] == _selectedTab;
      final matchesSearch = _searchQuery.isEmpty ||
          d['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d['destination'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d['crop'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d['driver'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesTab && matchesSearch;
    }).toList();
  }

  // ── Status helpers ─────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'Delivered':
        return AppColors.success;
      case 'In Transit':
        return AppColors.info;
      case 'Scheduled':
        return AppColors.primary;
      case 'Pending Pickup':
        return AppColors.warning;
      case 'Cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Delivered':
        return Icons.check_circle_rounded;
      case 'In Transit':
        return Icons.local_shipping_rounded;
      case 'Scheduled':
        return Icons.schedule_rounded;
      case 'Pending Pickup':
        return Icons.inventory_2_rounded;
      case 'Cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppColors.error;
      case 'Medium':
        return AppColors.warning;
      case 'Low':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  // ── Stats ──────────────────────────────────────────────────────────────

  int _countByStatus(String status) =>
      _deliveries.where((d) => d['status'] == status).length;

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
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
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
    );
  }

  // ── Desktop Layout ─────────────────────────────────────────────────────

  Widget _buildDesktopLayout(
      bool isDark, String userName, String userEmail) {
    return Row(
      children: [
        FarmManagerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) =>
              setState(() => _selectedNavIndex = index),
          userName: userName,
          userEmail: userEmail,
          userRole: 'Farm Manager',
        ),
        Expanded(
          child: Column(
            children: [
              FarmManagerHeader(
                  userName: userName, onNotificationTap: () {}),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: _buildContent(isDark, isMobile: false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mobile Layout ──────────────────────────────────────────────────────

  Widget _buildMobileLayout(bool isDark, String userName) {
    return Column(
      children: [
        FarmManagerHeader(
          userName: userName,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildContent(isDark, isMobile: true),
          ),
        ),
      ],
    );
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
        _buildDeliveriesSection(isDark, isMobile),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // PAGE HEADER
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildPageHeader(bool isDark, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Management',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Schedule, track, and manage produce deliveries',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 12 : 14,
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _showCreateDeliveryDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('Schedule Delivery',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
            ),
          ),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // STATS ROW
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildStatsRow(bool isDark, bool isMobile) {
    final stats = [
      {
        'label': 'Total',
        'value': '${_deliveries.length}',
        'icon': Icons.local_shipping_outlined,
        'color': AppColors.primary,
      },
      {
        'label': 'In Transit',
        'value': '${_countByStatus('In Transit')}',
        'icon': Icons.route_rounded,
        'color': AppColors.info,
      },
      {
        'label': 'Delivered',
        'value': '${_countByStatus('Delivered')}',
        'icon': Icons.check_circle_outline_rounded,
        'color': AppColors.success,
      },
      {
        'label': 'Scheduled',
        'value': '${_countByStatus('Scheduled') + _countByStatus('Pending Pickup')}',
        'icon': Icons.pending_actions_rounded,
        'color': AppColors.warning,
      },
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final cols = isMobile ? 2 : 4;
      final spacing = isMobile ? 10.0 : 14.0;

      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: cols,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: isMobile ? 2.4 : 2.8,
        children: stats.map((s) => _buildStatCard(s, isDark, isMobile)).toList(),
      );
    });
  }

  Widget _buildStatCard(
      Map<String, dynamic> stat, bool isDark, bool isMobile) {
    final color = stat['color'] as Color;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: color.withOpacity(isDark ? 0.12 : 0.1)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: color.withOpacity(0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 3)),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat['icon'] as IconData,
                size: isMobile ? 18 : 20, color: color),
          ),
          SizedBox(width: isMobile ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat['value'] as String,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white.withOpacity(0.4)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // DELIVERIES SECTION (tabs + search + table/cards)
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildDeliveriesSection(bool isDark, bool isMobile) {
    final deliveries = _filteredDeliveries;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.local_shipping_rounded,
                      size: 18, color: AppColors.info),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Delivery Tracking',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimary)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${deliveries.length} deliveries',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info),
                  ),
                ),
                if (isMobile) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showCreateDeliveryDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
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
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.3)),
                ),
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark
                    ? Colors.white.withOpacity(0.4)
                    : AppColors.textSecondary,
                labelStyle: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w500),
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 10),
                tabs: _statusTabs.map((t) {
                  final count = t == 'All'
                      ? _deliveries.length
                      : _countByStatus(t);
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: _selectedTab == t
                                ? AppColors.primary.withOpacity(0.15)
                                : (isDark
                                    ? Colors.white.withOpacity(0.06)
                                    : Colors.black.withOpacity(0.05)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white
                            : AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search deliveries...',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white24
                              : AppColors.textSecondary),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 18,
                          color: isDark
                              ? Colors.white24
                              : AppColors.textSecondary),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.04)
                          : AppColors.neutral50,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.black.withOpacity(0.06))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.black.withOpacity(0.06))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _showCreateDeliveryDialog,
                    icon:
                        const Icon(Icons.add_rounded, size: 16),
                    label: Text('New Delivery',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Table or cards
          if (deliveries.isEmpty)
            _buildEmptyState(isDark)
          else if (isMobile)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: deliveries.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (_, i) =>
                    _buildDeliveryCard(deliveries[i], isDark),
              ),
            )
          else
            _buildDeliveryTable(deliveries, isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.local_shipping_outlined,
                  size: 40, color: AppColors.info.withOpacity(0.4)),
            ),
            const SizedBox(height: 16),
            Text('No deliveries found',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white54
                        : AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('Schedule a delivery to get started',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white24
                        : AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showCreateDeliveryDialog,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text('Schedule Delivery',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // DESKTOP TABLE
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildDeliveryTable(
      List<Map<String, dynamic>> deliveries, bool isDark) {
    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(bottom: Radius.circular(14)),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : AppColors.neutral50,
              border: Border(
                  bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.06))),
            ),
            child: Row(
              children: [
                _th('ID', 2, isDark),
                _th('Destination', 3, isDark),
                _th('Crop', 1, isDark),
                _th('Qty', 1, isDark),
                _th('Status', 2, isDark),
                _th('Driver', 2, isDark),
                _th('Schedule', 2, isDark),
                _th('Priority', 1, isDark),
                _th('', 1, isDark),
              ],
            ),
          ),
          // Rows
          ...deliveries.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            return _buildTableRow(d, isDark, i % 2 != 0);
          }),
        ],
      ),
    );
  }

  Widget _th(String label, int flex, bool isDark) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white38 : AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTableRow(
      Map<String, dynamic> d, bool isDark, bool isOdd) {
    final status = d['status'] as String;
    final sColor = _statusColor(status);
    final priority = d['priority'] as String;
    final pColor = _priorityColor(priority);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDeliveryDetails(d),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: isOdd
                ? (isDark
                    ? Colors.white.withOpacity(0.02)
                    : AppColors.neutral50.withOpacity(0.5))
                : Colors.transparent,
            border: Border(
                bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.black.withOpacity(0.04))),
          ),
          child: Row(
            children: [
              // ID
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: sColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(d['id'] as String,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              // Destination
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['destination'] as String,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(d['address'] as String,
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: isDark
                                ? Colors.white24
                                : AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // Crop
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Icon(Icons.eco_rounded,
                        size: 12,
                        color: AppColors.success.withOpacity(0.7)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(d['crop'] as String,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              // Qty
              Expanded(
                flex: 1,
                child: Text(
                    '${d['quantity']} ${d['unit']}',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white70
                            : AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              // Status badge
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: sColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: sColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(status),
                              size: 11, color: sColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(status,
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: sColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Driver
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 13,
                        color: isDark
                            ? Colors.white24
                            : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(d['driver'] as String,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              // Schedule
              Expanded(
                flex: 2,
                child: Text(d['scheduledDate'] as String,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white54
                            : AppColors.textSecondary)),
              ),
              // Priority
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: pColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(priority,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: pColor)),
                ),
              ),
              // Actions
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _actionBtn(Icons.visibility_outlined, 'View',
                        () => _showDeliveryDetails(d), isDark),
                    const SizedBox(width: 4),
                    _actionBtn(Icons.edit_outlined, 'Edit',
                        () => _editDelivery(d), isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(
      IconData icon, String tooltip, VoidCallback onTap, bool isDark) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon,
              size: 15,
              color: isDark
                  ? Colors.white54
                  : AppColors.textSecondary),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // MOBILE CARD
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildDeliveryCard(Map<String, dynamic> d, bool isDark) {
    final status = d['status'] as String;
    final sColor = _statusColor(status);
    final priority = d['priority'] as String;
    final pColor = _priorityColor(priority);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    sColor,
                    sColor.withOpacity(0.75),
                  ]),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(_statusIcon(status),
                    size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['id'] as String,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary)),
                    const SizedBox(height: 1),
                    Text(d['destination'] as String,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white38
                                : AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: sColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: sColor.withOpacity(0.2)),
                ),
                child: Text(status,
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: sColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Info grid
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : AppColors.neutral50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _cardInfoItem(Icons.eco_rounded, 'Crop',
                        d['crop'] as String, isDark),
                    _cardInfoItem(
                        Icons.scale_rounded,
                        'Quantity',
                        '${d['quantity']} ${d['unit']}',
                        isDark),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _cardInfoItem(
                        Icons.person_outline_rounded,
                        'Driver',
                        d['driver'] as String,
                        isDark),
                    _cardInfoItem(
                        Icons.calendar_today_rounded,
                        'Scheduled',
                        d['scheduledDate'] as String,
                        isDark),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Footer: priority + actions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: pColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_rounded,
                        size: 10, color: pColor),
                    const SizedBox(width: 3),
                    Text(priority,
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: pColor)),
                  ],
                ),
              ),
              if (d['temperature'] != 'N/A') ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.thermostat_rounded,
                          size: 10, color: AppColors.info),
                      const SizedBox(width: 3),
                      Text(d['temperature'] as String,
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.info)),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              OutlinedButton(
                onPressed: () => _showDeliveryDetails(d),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.08)),
                ),
                child: Text('Details',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardInfoItem(
      IconData icon, String label, String value, bool isDark) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon,
              size: 13,
              color: isDark
                  ? Colors.white24
                  : AppColors.textSecondary),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        color: isDark
                            ? Colors.white24
                            : AppColors.textSecondary)),
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // DELIVERY DETAILS DIALOG
  // ══════════════════════════════════════════════════════════════════════

  void _showDeliveryDetails(Map<String, dynamic> d) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = d['status'] as String;
    final sColor = _statusColor(status);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            sColor,
                            sColor.withOpacity(0.75),
                          ]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_statusIcon(status),
                            size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(d['id'] as String,
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary)),
                            Text(d['batch'] as String,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white38
                                        : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 16,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Status
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: sColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: sColor.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        Icon(_statusIcon(status),
                            size: 18, color: sColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Status',
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: isDark
                                          ? Colors.white24
                                          : AppColors.textSecondary)),
                              Text(status,
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: sColor)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _priorityColor(
                                    d['priority'] as String)
                                .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flag_rounded,
                                  size: 10,
                                  color: _priorityColor(
                                      d['priority'] as String)),
                              const SizedBox(width: 3),
                              Text(d['priority'] as String,
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight.w600,
                                      color: _priorityColor(
                                          d['priority']
                                              as String))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Detail rows
                  _detailRow('Destination', d['destination'] as String,
                      Icons.storefront_outlined, isDark),
                  _detailRow('Address', d['address'] as String,
                      Icons.location_on_outlined, isDark),
                  _detailRow('Crop', d['crop'] as String,
                      Icons.eco_outlined, isDark),
                  _detailRow(
                      'Quantity',
                      '${d['quantity']} ${d['unit']}',
                      Icons.scale_outlined,
                      isDark),
                  _detailRow('Driver', d['driver'] as String,
                      Icons.person_outline_rounded, isDark),
                  _detailRow('Vehicle', d['vehicle'] as String,
                      Icons.directions_car_outlined, isDark),
                  _detailRow('Scheduled', d['scheduledDate'] as String,
                      Icons.calendar_today_outlined, isDark),
                  _detailRow('ETA', d['estimatedArrival'] as String,
                      Icons.access_time_rounded, isDark),
                  _detailRow(
                      'Temperature',
                      d['temperature'] as String,
                      Icons.thermostat_outlined,
                      isDark),
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            side: BorderSide(
                                color: isDark
                                    ? Colors.white
                                        .withOpacity(0.1)
                                    : Colors.black
                                        .withOpacity(0.08)),
                          ),
                          child: Text('Close',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight.w500)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _editDelivery(d);
                          },
                          icon: const Icon(
                              Icons.edit_outlined,
                              size: 15),
                          label: Text('Edit Delivery',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
      String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon,
              size: 14,
              color: isDark
                  ? Colors.white24
                  : AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white38
                        : AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white
                        : AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // CREATE DELIVERY DIALOG
  // ══════════════════════════════════════════════════════════════════════

  void _showCreateDeliveryDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();
    String destination = '';
    String address = '';
    String crop = '';
    String quantity = '';
    String driver = '';
    String priority = 'Medium';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.75),
                            ]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 20,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Schedule Delivery',
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textPrimary)),
                              Text('Plan a new delivery shipment',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white38
                                          : AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.black.withOpacity(0.04),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.close_rounded,
                                size: 16,
                                color: isDark
                                    ? Colors.white38
                                    : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _formField('Destination', 'e.g. Fresh Mart Supermarket',
                        Icons.storefront_outlined, isDark,
                        onChanged: (v) => destination = v),
                    const SizedBox(height: 12),
                    _formField('Address', 'e.g. 12 Victoria Island, Lagos',
                        Icons.location_on_outlined, isDark,
                        onChanged: (v) => address = v),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _formField('Crop', 'e.g. Lettuce',
                              Icons.eco_outlined, isDark,
                              onChanged: (v) => crop = v),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _formField('Quantity', 'e.g. 500',
                              Icons.scale_outlined, isDark,
                              onChanged: (v) => quantity = v,
                              inputType: TextInputType.number),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _formField('Driver', 'e.g. Adebayo',
                              Icons.person_outline_rounded, isDark,
                              onChanged: (v) => driver = v),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Priority',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white54
                                          : AppColors
                                              .textSecondary)),
                              const SizedBox(height: 6),
                              StatefulBuilder(
                                builder: (context, setLocal) {
                                  return DropdownButtonFormField<
                                      String>(
                                    value: priority,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: isDark
                                          ? Colors.white
                                              .withOpacity(0.04)
                                          : AppColors.neutral50,
                                      contentPadding:
                                          const EdgeInsets
                                              .symmetric(
                                              horizontal: 12,
                                              vertical: 10),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(10),
                                          borderSide: BorderSide(
                                              color: isDark
                                                  ? Colors.white
                                                      .withOpacity(
                                                          0.06)
                                                  : Colors.black
                                                      .withOpacity(
                                                          0.06))),
                                      enabledBorder:
                                          OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                          10),
                                              borderSide: BorderSide(
                                                  color: isDark
                                                      ? Colors
                                                          .white
                                                          .withOpacity(
                                                              0.06)
                                                      : Colors
                                                          .black
                                                          .withOpacity(
                                                              0.06))),
                                    ),
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors
                                                .textPrimary),
                                    dropdownColor: isDark
                                        ? AppColors.surfaceDark
                                        : Colors.white,
                                    items: ['High', 'Medium', 'Low']
                                        .map((p) => DropdownMenuItem(
                                            value: p,
                                            child: Text(p)))
                                        .toList(),
                                    onChanged: (v) => setLocal(
                                        () => priority = v!),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Submit
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                              side: BorderSide(
                                  color: isDark
                                      ? Colors.white
                                          .withOpacity(0.1)
                                      : Colors.black
                                          .withOpacity(0.08)),
                            ),
                            child: Text('Cancel',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w500)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(this.context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    'Delivery scheduled to $destination'),
                                backgroundColor:
                                    AppColors.success,
                              ));
                            },
                            icon: const Icon(
                                Icons.check_rounded,
                                size: 16),
                            label: Text('Schedule',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formField(String label, String hint, IconData icon, bool isDark,
      {required ValueChanged<String> onChanged,
      TextInputType inputType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white54
                    : AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          onChanged: onChanged,
          keyboardType: inputType,
          style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white : AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
                fontSize: 12,
                color: isDark
                    ? Colors.white24
                    : AppColors.textSecondary),
            prefixIcon: Icon(icon,
                size: 16,
                color: isDark
                    ? Colors.white24
                    : AppColors.textSecondary),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.04)
                : AppColors.neutral50,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  void _editDelivery(Map<String, dynamic> d) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Edit functionality for ${d['id']}'),
      backgroundColor: AppColors.info,
    ));
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final index = item['index'] as int;
              final isSelected = index == 3; // Deliveries is active

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      try {
                        Navigator.pushReplacementNamed(
                            context, item['route'] as String);
                      } catch (_) {}
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected)
                          Container(
                            width: 24,
                            height: 2.5,
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                        else
                          const SizedBox(height: 6.5),
                        Icon(
                          item['icon'] as IconData,
                          size: 20,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white.withOpacity(0.4)
                                  : AppColors.textSecondary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['label'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white.withOpacity(0.4)
                                    : AppColors.textSecondary),
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
      ),
    );
  }
}
