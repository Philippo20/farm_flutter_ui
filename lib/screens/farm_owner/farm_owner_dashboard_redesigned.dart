import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_owner_sidebar.dart';
import '../../core/widgets/farm_owner_header.dart';
import '../../core/widgets/farm_owner_mobile_drawer.dart';
import '../../core/widgets/modern_dashboard_scaffold.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Farm Owner Dashboard - Redesigned
/// Financial focus with digital wallet
class FarmOwnerDashboardRedesigned extends ConsumerStatefulWidget {
  const FarmOwnerDashboardRedesigned({super.key});

  @override
  ConsumerState<FarmOwnerDashboardRedesigned> createState() =>
      _FarmOwnerDashboardRedesignedState();
}

class _FarmOwnerDashboardRedesignedState
    extends ConsumerState<FarmOwnerDashboardRedesigned> {
  final SuperAdminApiService _api = SuperAdminApiService();
  int _selectedNavIndex = 0;
  WeatherInfo? _weatherInfo;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, dynamic>> _farms = [];
  final List<Map<String, dynamic>> _batches = [];
  final List<Map<String, dynamic>> _sales = [];
  final List<Map<String, dynamic>> _sensors = [];
  final List<Map<String, dynamic>> _fundRequests = [];
  bool _isLoadingDashboard = true;
  String? _dashboardError;

  @override
  void initState() {
    super.initState();
    // Load weather info if needed
    _weatherInfo = const WeatherInfo(condition: 'Sunny', temperature: 28.5);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoadingDashboard = true;
      _dashboardError = null;
    });
    try {
      final results = await Future.wait([
        _api.getFarms(),
        _api.getBatches(),
        _api.getSales(),
        _api.getSensors(),
        _api.getFundRequests(),
      ]);
      if (!mounted) return;
      setState(() {
        _farms
          ..clear()
          ..addAll(results[0]);
        _batches
          ..clear()
          ..addAll(results[1]);
        _sales
          ..clear()
          ..addAll(results[2]);
        _sensors
          ..clear()
          ..addAll(results[3]);
        _fundRequests
          ..clear()
          ..addAll(results[4]);
        _isLoadingDashboard = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _dashboardError = error.toString();
        _isLoadingDashboard = false;
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
    final ids = _ownerFarmIds;
    final names = _ownerFarmNames;
    final farmId = _value(doc, ['farm_id', 'farmID', 'farmId']);
    final farmName = _value(doc, ['farm_name', 'farmName']);
    return (farmId.isNotEmpty && ids.contains(farmId)) ||
        (farmName.isNotEmpty && names.contains(_normalise(farmName)));
  }

  List<Map<String, dynamic>> get _ownerBatches =>
      _batches.where(_matchesOwnerFarm).toList();

  List<Map<String, dynamic>> get _ownerSales =>
      _sales.where(_matchesOwnerFarm).toList();

  List<Map<String, dynamic>> get _ownerSensors =>
      _sensors.where(_matchesOwnerFarm).toList();

  List<Map<String, dynamic>> get _ownerFundRequests =>
      _fundRequests.where(_matchesOwnerFarm).toList();

  String _formatMoney(num value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return 'GHS $whole.${parts.last}';
  }

  String _relativeTime(DateTime? date) {
    if (date == null) return 'Recently';
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
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
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
              userName: userName,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      floatingActionButton: isMobile
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _navigateTo('/farm-owner/wallet-actions'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('Wallet Action'),
            ),
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
        // Sidebar
        FarmOwnerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) {
            setState(() {
              _selectedNavIndex = index;
            });
          },
          userName: userName,
          userEmail: userEmail,
          userRole: userRole,
        ),

        // Main Content
        Expanded(
          child: Column(
            children: [
              // Header
              FarmOwnerHeader(
                userName: userName,
                weatherInfo: _weatherInfo,
                onNotificationTap: () {
                  // Handle notifications
                },
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.all(isTablet ? AppSpacing.md : AppSpacing.lg),
                  child: _buildDashboardContent(isDark, isTablet),
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
        // Header
        FarmOwnerHeader(
          userName: userName,
          weatherInfo: _weatherInfo,
          onNotificationTap: () {
            // Handle notifications
          },
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),

        // Content
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bottomInset = MediaQuery.of(context).padding.bottom;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md + bottomInset + 72,
                ),
                child: _buildDashboardContent(isDark, true),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent(bool isDark, bool isMobile) {
    if (_isLoadingDashboard) {
      return const AdminDataSkeleton(rowCount: 4, showStats: true);
    }

    if (_dashboardError != null) {
      return _buildDashboardError(isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModernStatsRow(isDark, isMobile),
        SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),
        if (isMobile) ...[
          _buildQuickActionsSection(isDark, isMobile),
          const SizedBox(height: AppSpacing.lg),
          _buildActivityTimeline(isDark, isMobile),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildQuickActionsSection(isDark, isMobile),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _buildActivityTimeline(isDark, isMobile),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDashboardError(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 42),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Unable to load dashboard data',
            style: AppTypography.h4.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _dashboardError ?? '',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: _loadDashboardData,
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

  Widget _buildModernStatsRow(bool isDark, bool isMobile) {
    final revenue = _ownerSales.fold<num>(
      0,
      (sum, sale) =>
          sum + _numValue(sale['total_amount'] ?? sale['amount'] ?? 0),
    );
    final thisMonth = DateTime(DateTime.now().year, DateTime.now().month);
    final monthlyRevenue = _ownerSales.where((sale) {
      final date = _dateValue(sale['created_at'] ?? sale[r'$createdAt']);
      return date != null &&
          DateTime(date.year, date.month).isAtSameMomentAs(thisMonth);
    }).fold<num>(
      0,
      (sum, sale) =>
          sum + _numValue(sale['total_amount'] ?? sale['amount'] ?? 0),
    );
    final pendingRequests = _ownerFundRequests
        .where((request) =>
            _value(request, ['status']).toLowerCase().trim() == 'pending')
        .length;
    final activeFarms = _ownerFarms
        .where((farm) => _value(farm, ['status']).toLowerCase() == 'active')
        .length;

    final stats = [
      {
        'label': 'Total Revenue',
        'value': _formatMoney(revenue),
        'unit': 'earned',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFF6366F1),
        'change': '${_ownerSales.length} sales',
      },
      {
        'label': 'Monthly Revenue',
        'value': _formatMoney(monthlyRevenue),
        'unit': 'this month',
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFF10B981),
        'change': _ownerSales.isEmpty ? 'No sales' : 'Live',
      },
      {
        'label': 'Pending Requests',
        'value': '$pendingRequests',
        'unit': 'requests',
        'icon': Icons.pending_actions_rounded,
        'color': const Color(0xFFF59E0B),
        'change': '${_ownerFundRequests.length} total',
      },
      {
        'label': 'Active Farms',
        'value': '$activeFarms',
        'unit': 'farms',
        'icon': Icons.agriculture_rounded,
        'color': const Color(0xFF0EA5E9),
        'change': '${_ownerFarms.length} owned',
      },
    ];

    if (isMobile) {
      return LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 12.0;
          final cardWidth = (constraints.maxWidth - spacing) / 2;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: stats
                .map(
                  (stat) => SizedBox(
                    width: cardWidth,
                    child: _buildModernStatCard(stat, isDark, isMobile),
                  ),
                )
                .toList(),
          );
        },
      );
    }

    return Row(
      children: stats
          .map((s) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildModernStatCard(s, isDark, isMobile),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildModernStatCard(
      Map<String, dynamic> stat, bool isDark, bool isMobile) {
    final color = stat['color'] as Color;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(stat['icon'] as IconData,
                    size: isMobile ? 20 : 22, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  stat['change'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    stat['value'] as String,
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 30,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  stat['unit'] as String,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            stat['label'] as String,
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flash_on_rounded,
                    size: 20, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFeaturesGrid(context),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline(bool isDark, bool isMobile) {
    final activities = _ownerActivities;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timeline_rounded,
                    size: 20, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (activities.isEmpty)
            Text(
              'No recent farm activity yet.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            )
          else
            ...activities.map((a) => _buildActivityItem(a, isDark)),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _ownerActivities {
    final activities = <Map<String, dynamic>>[];
    for (final sale in _ownerSales) {
      final amount = _numValue(sale['total_amount'] ?? sale['amount']);
      activities.add({
        'title': 'Farm Revenue Recorded',
        'desc': '${_formatMoney(amount)} from ${_value(sale, [
              'farm_name'
            ], fallback: 'owned farm')}',
        'time': _relativeTime(
            _dateValue(sale['created_at'] ?? sale[r'$createdAt'])),
        'sortDate': _dateValue(sale['created_at'] ?? sale[r'$createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFF6366F1),
      });
    }
    for (final request in _ownerFundRequests) {
      final status = _value(request, ['status']);
      activities.add({
        'title': 'Fund Request ${status.isEmpty ? 'Updated' : status}',
        'desc':
            '${_formatMoney(_numValue(request['amount']))} for ${_value(request, [
                  'farm_name'
                ], fallback: 'owned farm')}',
        'time': _relativeTime(_dateValue(request['updated_at'] ??
            request['request_date'] ??
            request[r'$updatedAt'])),
        'sortDate': _dateValue(request['updated_at'] ??
                request['request_date'] ??
                request[r'$updatedAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        'icon': Icons.pending_actions_rounded,
        'color': status.toLowerCase() == 'approved'
            ? const Color(0xFF10B981)
            : const Color(0xFFF59E0B),
      });
    }
    for (final batch in _ownerBatches) {
      final status = _value(batch, ['production_status']);
      activities.add({
        'title': 'Batch ${status.isEmpty ? 'Updated' : status}',
        'desc': '${_value(batch, [
              'batch_code',
              'batch_id'
            ], fallback: 'Batch')} at ${_value(batch, ['farm_name'], fallback: 'owned farm')}',
        'time': _relativeTime(
            _dateValue(batch['updated_at'] ?? batch['created_at'])),
        'sortDate': _dateValue(batch['updated_at'] ?? batch['created_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        'icon': Icons.inventory_2_rounded,
        'color': const Color(0xFF0EA5E9),
      });
    }
    activities.sort((a, b) =>
        (b['sortDate'] as DateTime).compareTo(a['sortDate'] as DateTime));
    return activities.take(5).toList();
  }

  Widget _buildActivityItem(Map<String, dynamic> activity, bool isDark) {
    final color = activity['color'] as Color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(activity['icon'] as IconData, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['desc'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity['time'] as String,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border(
                                top: BorderSide(
                                    color: AppColors.primary, width: 2),
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 22,
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
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget buildStatsSectionLegacy(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isMobile ? 2 : (isTablet ? 2 : 4);
        final childAspectRatio = isMobile ? 2.8 : (isTablet ? 3.0 : 3.2);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: isMobile ? AppSpacing.xs : AppSpacing.sm,
          mainAxisSpacing: isMobile ? AppSpacing.xs : AppSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            CompactStatCard(
              title: 'Wallet Balance',
              value: '\$48,500',
              icon: Icons.account_balance_wallet,
              color: AppColors.primary,
              trend: '+23%',
              isPositive: true,
              onTap: () {},
            ),
            CompactStatCard(
              title: 'Monthly Revenue',
              value: '\$12,300',
              icon: Icons.trending_up,
              color: AppColors.success,
              trend: '+15%',
              isPositive: true,
            ),
            CompactStatCard(
              title: 'Total Farms',
              value: '5 Farms',
              icon: Icons.agriculture,
              color: AppColors.info,
            ),
            CompactStatCard(
              title: 'Total Yield',
              value: '850 kg',
              icon: Icons.inventory,
              color: AppColors.warning,
              trend: '+8%',
              isPositive: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
    final totalRevenue = _ownerSales.fold<num>(
      0,
      (sum, sale) =>
          sum + _numValue(sale['total_amount'] ?? sale['amount'] ?? 0),
    );
    final activeSensors = _ownerSensors
        .where((sensor) => _value(sensor, ['status']).toLowerCase() == 'online')
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isMobile ? 2 : (isTablet ? 2 : 3);
        final childAspectRatio = isMobile ? 1.1 : (isTablet ? 1.15 : 1.2);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
          mainAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildFeatureCard(
              context,
              isDark,
              'Digital Wallet',
              Icons.account_balance_wallet_outlined,
              AppColors.primary,
              '${_formatMoney(totalRevenue)} tracked',
              () => _navigateTo('/farm-owner/digital-wallet', navIndex: 2),
              isMobile: isMobile,
              isTablet: isTablet,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Wallet Actions',
              Icons.payments_outlined,
              AppColors.success,
              '${_ownerFundRequests.length} requests',
              () => _navigateTo('/farm-owner/wallet-actions'),
              isMobile: isMobile,
              isTablet: isTablet,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Analytics',
              Icons.analytics,
              AppColors.info,
              '${_ownerBatches.length} batches',
              () => _navigateTo('/farm-owner/analytics', navIndex: 3),
              isMobile: isMobile,
              isTablet: isTablet,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Financial Reports',
              Icons.assessment,
              AppColors.warning,
              'Download reports',
              () => _navigateTo('/farm-owner/reports', navIndex: 4),
              isMobile: isMobile,
              isTablet: isTablet,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Farm Performance',
              Icons.trending_up,
              AppColors.primary,
              '${_ownerFarms.length} farms • $activeSensors sensors online',
              () => _navigateTo('/farm-owner/farm', navIndex: 1),
              isMobile: isMobile,
              isTablet: isTablet,
            ),
            _buildFeatureCard(
              context,
              isDark,
              'Settings',
              Icons.settings_outlined,
              AppColors.textSecondary,
              'Account settings',
              () => _navigateTo('/farm-owner/settings', navIndex: 5),
              isMobile: isMobile,
              isTablet: isTablet,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    bool isDark,
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap, {
    bool isMobile = false,
    bool isTablet = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isMobile
            ? AppSpacing.sm
            : (isTablet ? AppSpacing.sm : AppSpacing.md)),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: color.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 10 : (isTablet ? 10 : 12)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: isMobile ? 22 : (isTablet ? 24 : 26),
                color: color,
              ),
            ),
            SizedBox(height: isMobile ? AppSpacing.xs : AppSpacing.sm),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: isMobile ? 12 : (isTablet ? 13 : 14),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                  fontSize: isMobile ? 10 : (isTablet ? 10.5 : 11),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(String route, {int? navIndex}) {
    if (navIndex != null) {
      setState(() => _selectedNavIndex = navIndex);
    }
    try {
      Navigator.pushNamed(context, route);
    } catch (e) {
      debugPrint('Quick action navigation error: $e');
    }
  }
}
