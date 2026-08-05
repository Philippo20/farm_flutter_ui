import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_manager_sidebar.dart';
import '../../core/widgets/farm_manager_header.dart';
import '../../core/widgets/farm_manager_mobile_drawer.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Farm Manager Dashboard - Redesigned
/// Professional layout with sidebar, weather, and compact stats
class FarmManagerDashboardRedesigned extends ConsumerStatefulWidget {
  const FarmManagerDashboardRedesigned({super.key});

  @override
  ConsumerState<FarmManagerDashboardRedesigned> createState() =>
      _FarmManagerDashboardRedesignedState();
}

class _FarmManagerDashboardRedesignedState
    extends ConsumerState<FarmManagerDashboardRedesigned> {
  final SuperAdminApiService _api = SuperAdminApiService();
  int _selectedNavIndex = 0;
  WeatherInfo? _weatherInfo;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, dynamic>> _farms = [];
  final List<Map<String, dynamic>> _batches = [];
  final List<Map<String, dynamic>> _inventory = [];
  final List<Map<String, dynamic>> _sensors = [];
  final List<Map<String, dynamic>> _deliveries = [];
  final List<Map<String, dynamic>> _audits = [];
  bool _isLoadingDashboard = true;
  String? _dashboardError;

  // Content-level navigation state
  String _currentView =
      'dashboard'; // 'dashboard', 'harvest_approval', 'delivery_trigger'

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
        _api.getInventory(),
        _api.getSensors(),
        _api.getFulfillments(),
        _api.getAudits(),
      ]);
      if (!mounted) return;
      setState(() {
        _farms
          ..clear()
          ..addAll(results[0]);
        _batches
          ..clear()
          ..addAll(results[1]);
        _inventory
          ..clear()
          ..addAll(results[2]);
        _sensors
          ..clear()
          ..addAll(results[3]);
        _deliveries
          ..clear()
          ..addAll(results[4]);
        _audits
          ..clear()
          ..addAll(results[5]);
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

  String _value(Map<String, dynamic> doc, List<String> keys) {
    for (final key in keys) {
      final value = doc[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  num _numValue(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _status(Map<String, dynamic> doc, List<String> keys) =>
      _value(doc, keys).toLowerCase().trim();

  DateTime? _dateValue(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }

  bool _isManagedFarm(Map<String, dynamic> farm) {
    final user = ref.read(authProvider).user;
    if (user == null) return true;
    final managerId = _value(farm, ['farm_manager_id', 'farmManagerId']);
    final managerName = _value(farm, ['farm_manager_name', 'farmManagerName']);
    return managerId == user.id ||
        managerId == user.email ||
        managerName.toLowerCase() == user.name.toLowerCase();
  }

  List<Map<String, dynamic>> get _managedFarms =>
      _farms.where(_isManagedFarm).toList();

  Set<String> get _managedFarmIds =>
      _managedFarms.map(_docId).where((id) => id.isNotEmpty).toSet();

  Set<String> get _managedFarmNames => _managedFarms
      .map((farm) => _value(farm, ['name', 'farm_name']))
      .where((name) => name.isNotEmpty)
      .toSet();

  bool _matchesManagedFarm(Map<String, dynamic> doc) {
    if (_managedFarms.isEmpty) return true;
    final farmId = _value(doc, ['farmID', 'farm_id', 'farmId']);
    final farmName = _value(doc, ['farm_name', 'farmName']);
    return _managedFarmIds.contains(farmId) ||
        _managedFarmNames.contains(farmName);
  }

  List<Map<String, dynamic>> get _managedBatches =>
      _batches.where(_matchesManagedFarm).toList();

  List<Map<String, dynamic>> get _managedInventory =>
      _inventory.where(_matchesManagedFarm).toList();

  List<Map<String, dynamic>> get _managedDeliveries =>
      _deliveries.where(_matchesManagedFarm).toList();

  bool _isActiveBatch(Map<String, dynamic> batch) {
    final status = _status(batch, ['production_status', 'status']);
    return !{'completed', 'delivered', 'cancelled', 'harvested'}
        .contains(status);
  }

  bool _isHarvestReady(Map<String, dynamic> batch) {
    final status = _status(batch, ['production_status', 'status']);
    if (status.contains('harvest')) return true;
    final endDate = _dateValue(batch['end_date']);
    if (endDate == null) return false;
    return !DateTime.now().isBefore(endDate);
  }

  bool _isLowStock(Map<String, dynamic> item) {
    final available = _numValue(
      item['quantity_available'] ?? item['quantity'] ?? item['stock'],
    );
    final reorder = _numValue(item['reorder_level']);
    return reorder > 0 && available <= reorder;
  }

  bool _isPendingDelivery(Map<String, dynamic> delivery) {
    final status = _status(delivery, ['delivery_status', 'status']);
    return status.isEmpty ||
        {'pending', 'pending approval', 'scheduled', 'on hold'}
            .contains(status);
  }

  String _formatCompact(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }

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
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? FarmManagerMobileDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
              userName: userName,
              userEmail: userEmail,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      bottomNavigationBar: isMobile
          ? FarmManagerMobileBottomNav(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
            )
          : null,
      floatingActionButton: isMobile
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(
                  context, '/farm-manager/batch-generation'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('Generate Batch'),
            ),
    );
  }

  Widget _buildDesktopLayout(
      bool isDark, String userName, String userEmail, String userRole) {
    return Row(
      children: [
        // Sidebar
        FarmManagerSidebar(
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
              FarmManagerHeader(
                userName: userName,
                weatherInfo: _weatherInfo,
                onNotificationTap: () {
                  // Handle notifications
                },
              ),

              // Content
              Expanded(
                child: _buildContentView(isDark),
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
        FarmManagerHeader(
          userName: userName,
          weatherInfo: _weatherInfo,
          onNotificationTap: () {
            // Handle notifications
          },
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),

        // Content
        Expanded(
          child: _buildContentView(isDark),
        ),

      ],
    );
  }

  Widget _buildContentView(bool isDark) {
    switch (_currentView) {
      case 'harvest_approval':
        return _buildHarvestApprovalContent(isDark);
      case 'delivery_trigger':
        return _buildDeliveryTriggerContent(isDark);
      default:
        return _buildDashboardContent(isDark);
    }
  }

  Widget _buildDashboardContent(bool isDark) {
    if (_isLoadingDashboard) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: AdminDataSkeleton(rowCount: 6),
      );
    }
    if (_dashboardError != null) {
      return _buildDashboardError(isDark);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Row
              _buildModernStatsRow(isDark, isMobile),
              SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),

              // Main Content
              if (isMobile) ...[
                // Mobile: Stacked layout
                _buildQuickActionsSection(context, isDark, isMobile),
                const SizedBox(height: AppSpacing.lg),
                _buildTasksOverview(isDark, isMobile),
                const SizedBox(height: AppSpacing.lg),
                _buildActivityTimeline(isDark, isMobile),
              ] else ...[
                // Desktop: Grid layout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildQuickActionsSection(context, isDark, isMobile),
                          const SizedBox(height: AppSpacing.lg),
                          _buildTasksOverview(isDark, isMobile),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: _buildActivityTimeline(isDark, isMobile),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernStatsRow(bool isDark, bool isMobile) {
    final totalInventoryKg = _managedInventory.fold<num>(
      0,
      (sum, item) =>
          sum +
          _numValue(
              item['quantity_available'] ?? item['quantity'] ?? item['stock']),
    );
    final activeBatches = _managedBatches.where(_isActiveBatch).length;
    final harvestReady = _managedBatches.where(_isHarvestReady).length;
    final pendingDeliveries =
        _managedDeliveries.where(_isPendingDelivery).length;
    final lowStock = _managedInventory.where(_isLowStock).length;
    final pendingTasks = harvestReady + pendingDeliveries + lowStock;
    final sensorCount = _sensors.where(_matchesManagedFarm).length;
    final stats = [
      {
        'label': 'Total Inventory',
        'value': _formatCompact(totalInventoryKg),
        'unit': 'units',
        'icon': Icons.inventory_2_rounded,
        'color': const Color(0xFF6366F1),
        'change': '$sensorCount sensors'
      },
      {
        'label': 'Active Batches',
        'value': '$activeBatches',
        'unit': 'batches',
        'icon': Icons.layers_rounded,
        'color': const Color(0xFF0EA5E9),
        'change': '${_managedBatches.length} total'
      },
      {
        'label': 'Pending Tasks',
        'value': '$pendingTasks',
        'unit': 'tasks',
        'icon': Icons.pending_actions_rounded,
        'color': const Color(0xFFF59E0B),
        'change': lowStock > 0 ? '$lowStock low stock' : 'Live'
      },
      {
        'label': 'Harvest Ready',
        'value': '$harvestReady',
        'unit': 'batches',
        'icon': Icons.agriculture_rounded,
        'color': const Color(0xFF10B981),
        'change': 'Backend'
      },
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildModernStatCard(stats[0], isDark, isMobile)),
              const SizedBox(width: 12),
              Expanded(child: _buildModernStatCard(stats[1], isDark, isMobile)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildModernStatCard(stats[2], isDark, isMobile)),
              const SizedBox(width: 12),
              Expanded(child: _buildModernStatCard(stats[3], isDark, isMobile)),
            ],
          ),
        ],
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
              Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: isMobile ? 26 : 32,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  height: 1,
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

  Widget _buildTasksOverview(bool isDark, bool isMobile) {
    final harvestReady = _managedBatches.where(_isHarvestReady).length;
    final pendingDeliveries =
        _managedDeliveries.where(_isPendingDelivery).length;
    final lowStock = _managedInventory.where(_isLowStock).length;
    final pendingCount = harvestReady + pendingDeliveries + lowStock;
    final tasks = [
      {
        'title': 'Harvest Approval Required',
        'subtitle': '$harvestReady batches are ready for harvest review',
        'icon': Icons.check_circle_outline_rounded,
        'color': const Color(0xFF10B981),
        'badge': '$harvestReady',
        'action': 'harvest_approval'
      },
      {
        'title': 'Pending Deliveries',
        'subtitle': '$pendingDeliveries delivery records need monitoring',
        'icon': Icons.local_shipping_rounded,
        'color': const Color(0xFF0EA5E9),
        'badge': '$pendingDeliveries',
        'action': 'delivery_trigger'
      },
      {
        'title': 'Inventory Low Stock',
        'subtitle': lowStock == 0
            ? 'No inventory item is below reorder level'
            : '$lowStock inventory items are below reorder level',
        'icon': Icons.warning_amber_rounded,
        'color': const Color(0xFFF59E0B),
        'badge': lowStock == 0 ? '0' : '!',
        'action': 'inventory'
      },
    ];

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
                child: const Icon(Icons.task_alt_rounded,
                    size: 20, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 12),
              Text(
                'Tasks Overview',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pendingCount Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...tasks.map((task) => _buildTaskItem(task, isDark, isMobile)),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task, bool isDark, bool isMobile) {
    final color = task['color'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final action = task['action'] as String;
            if (action == 'harvest_approval' || action == 'delivery_trigger') {
              setState(() => _currentView = action);
            } else if (action == 'inventory') {
              Navigator.pushNamed(context, '/farm-manager/inventory');
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.03)
                  : color.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(task['icon'] as IconData, size: 22, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'] as String,
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task['subtitle'] as String,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          color:
                              isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      task['badge'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(
      BuildContext context, bool isDark, bool isMobile) {
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
    final activities = _dashboardActivities;

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
                  color: const Color(0xFF0EA5E9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timeline_rounded,
                    size: 20, color: Color(0xFF0EA5E9)),
              ),
              const SizedBox(width: 12),
              Text(
                'Activity',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('View All',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            _buildActivityEmptyState(isDark)
          else
            ...activities.asMap().entries.map((entry) {
              final index = entry.key;
              final activity = entry.value;
              final isLast = index == activities.length - 1;
              return _buildTimelineItem(activity, isDark, isMobile, isLast);
            }),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _dashboardActivities {
    final recentAudits = _audits.take(5).map((audit) {
      final collection = _value(audit, ['collection_name']);
      final action = _value(audit, ['action_type', 'action']);
      final details = _value(audit, ['action_details', 'details']);
      return {
        'title': action.isEmpty ? 'Backend Activity' : action,
        'desc': details.isEmpty
            ? (collection.isEmpty ? 'System activity recorded' : collection)
            : details,
        'time': _relativeTime(_dateValue(audit['timestamp'])),
        'icon': _activityIcon(collection, action),
        'color': _activityColor(collection, action),
      };
    }).toList();
    if (recentAudits.isNotEmpty) return recentAudits;

    final fallback = <Map<String, dynamic>>[];
    for (final batch in _managedBatches.take(2)) {
      fallback.add({
        'title': 'Batch ${_value(batch, ['production_status', 'status'])}',
        'desc': '${_value(batch, [
              'batch_no',
              'batch_id',
              r'$id'
            ])} | ${_value(batch, ['plant_name', 'plant_type'])}',
        'time': _relativeTime(
            _dateValue(batch['updated_at'] ?? batch['created_at'])),
        'icon': Icons.layers_rounded,
        'color': const Color(0xFF0EA5E9),
      });
    }
    for (final item in _managedInventory.take(2)) {
      fallback.add({
        'title': 'Inventory Record',
        'desc': '${_value(item, [
              'item_name',
              'name'
            ])} | ${_numValue(item['quantity_available'] ?? item['quantity'])} ${_value(item, [
              'unit'
            ])}',
        'time': _relativeTime(_dateValue(item['date_added'])),
        'icon': Icons.inventory_rounded,
        'color': const Color(0xFFF59E0B),
      });
    }
    return fallback.take(5).toList();
  }

  String _relativeTime(DateTime? date) {
    if (date == null) return 'Recently';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  IconData _activityIcon(String collection, String action) {
    final text = '$collection $action'.toLowerCase();
    if (text.contains('delivery') || text.contains('fulfillment')) {
      return Icons.local_shipping_rounded;
    }
    if (text.contains('inventory')) return Icons.inventory_rounded;
    if (text.contains('batch')) return Icons.layers_rounded;
    if (text.contains('farm')) return Icons.agriculture_rounded;
    if (text.contains('update')) return Icons.edit_rounded;
    return Icons.timeline_rounded;
  }

  Color _activityColor(String collection, String action) {
    final text = '$collection $action'.toLowerCase();
    if (text.contains('delete') || text.contains('cancel')) {
      return const Color(0xFFEF4444);
    }
    if (text.contains('delivery') || text.contains('fulfillment')) {
      return const Color(0xFF0EA5E9);
    }
    if (text.contains('inventory')) return const Color(0xFFF59E0B);
    if (text.contains('batch')) return const Color(0xFF10B981);
    return const Color(0xFF6366F1);
  }

  Widget _buildActivityEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        'No activity has been recorded for this farm manager yet.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDark ? Colors.white60 : AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildDashboardError(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
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
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.error, size: 42),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Farm manager dashboard could not be loaded',
              style: AppTypography.h6.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _dashboardError ?? 'Unknown backend error',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
      Map<String, dynamic> activity, bool isDark, bool isMobile, bool isLast) {
    final color = activity['color'] as Color;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(activity['icon'] as IconData, size: 18, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['desc'] as String,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['time'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // HARVEST APPROVAL CONTENT VIEW
  // ============================================
  Widget _buildHarvestApprovalContent(bool isDark) {
    final pendingHarvests = [
      {
        'id': 'H001',
        'batch': 'BATCH-156',
        'farm': 'Green Valley',
        'crop': 'Tomatoes',
        'quantity': '250',
        'unit': 'kg',
        'date': '2026-01-29',
        'time': '08:30 AM',
        'status': 'Pending',
        'quality': 'A',
        'moisture': '12',
        'caretaker': 'John Doe',
        'section': 'Section A',
        'expectedYield': '280',
        'actualYield': '250',
        'notes': 'Ready for harvest, optimal ripeness achieved'
      },
      {
        'id': 'H002',
        'batch': 'BATCH-157',
        'farm': 'Sunny Acres',
        'crop': 'Lettuce',
        'quantity': '180',
        'unit': 'kg',
        'date': '2026-01-29',
        'time': '09:15 AM',
        'status': 'Pending',
        'quality': 'A',
        'moisture': '15',
        'caretaker': 'Jane Smith',
        'section': 'Section B',
        'expectedYield': '200',
        'actualYield': '180',
        'notes': 'Fresh harvest, good leaf quality'
      },
      {
        'id': 'H003',
        'batch': 'BATCH-158',
        'farm': 'Fresh Farms',
        'crop': 'Peppers',
        'quantity': '120',
        'unit': 'kg',
        'date': '2026-01-30',
        'time': '07:00 AM',
        'status': 'Pending',
        'quality': 'B',
        'moisture': '10',
        'caretaker': 'Mike Brown',
        'section': 'Section C',
        'expectedYield': '150',
        'actualYield': '120',
        'notes': 'Some minor blemishes, still marketable'
      },
      {
        'id': 'H004',
        'batch': 'BATCH-159',
        'farm': 'Green Valley',
        'crop': 'Herbs',
        'quantity': '45',
        'unit': 'kg',
        'date': '2026-01-30',
        'time': '10:00 AM',
        'status': 'Pending',
        'quality': 'A',
        'moisture': '8',
        'caretaker': 'Sarah Lee',
        'section': 'Section D',
        'expectedYield': '50',
        'actualYield': '45',
        'notes': 'Aromatic herbs, excellent quality'
      },
      {
        'id': 'H005',
        'batch': 'BATCH-160',
        'farm': 'Sunny Acres',
        'crop': 'Kale',
        'quantity': '95',
        'unit': 'kg',
        'date': '2026-01-31',
        'time': '06:45 AM',
        'status': 'Pending',
        'quality': 'A',
        'moisture': '14',
        'caretaker': 'Tom Wilson',
        'section': 'Section A',
        'expectedYield': '100',
        'actualYield': '95',
        'notes': 'Organic kale, premium quality'
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Bar with back button (keeping same header)
              Container(
                padding:
                    EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success,
                      AppColors.success.withOpacity(0.8)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          setState(() => _currentView = 'dashboard'),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      tooltip: 'Back to Dashboard',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const Icon(Icons.check_circle,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Harvest Approval',
                            style: AppTypography.h5.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 18 : 20),
                          ),
                          Text(
                            '${pendingHarvests.length} pending approvals',
                            style: AppTypography.bodySmall
                                .copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    if (!isMobile) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                    'All ${pendingHarvests.length} harvests approved')
                              ]),
                              backgroundColor: Colors.white.withOpacity(0.2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text('Approve All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),

              // Professional Stats Cards Row
              _buildProfessionalStatsRow(
                  isDark, isMobile, pendingHarvests.length),
              SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),

              // Search and Filter Bar
              _buildSearchFilterBar(isDark, isMobile),
              SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),

              // Section Header
              Row(
                children: [
                  Text(
                    'Pending Approvals',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      '${pendingHarvests.length} items',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),

              // Professional Harvest Cards - Grid on desktop, list on mobile
              if (isMobile)
                ...pendingHarvests.map((harvest) =>
                    _buildProfessionalHarvestCard(
                        harvest, isDark, isMobile, isTablet))
              else
                _buildHarvestCardsGrid(
                    pendingHarvests, isDark, isMobile, isTablet),

              // Mobile Approve All Button
              if (isMobile) ...[
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                              'All ${pendingHarvests.length} harvests approved')
                        ]),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.done_all),
                  label: const Text('Approve All Pending'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfessionalStatsRow(
      bool isDark, bool isMobile, int pendingCount) {
    final stats = [
      {
        'icon': Icons.pending_actions,
        'label': 'Pending',
        'value': '$pendingCount',
        'color': AppColors.warning,
        'trend': '+2 today'
      },
      {
        'icon': Icons.today,
        'label': 'Due Today',
        'value': '2',
        'color': AppColors.info,
        'trend': 'On track'
      },
      {
        'icon': Icons.check_circle_outline,
        'label': 'Approved',
        'value': '18',
        'color': AppColors.success,
        'trend': 'This week'
      },
      {
        'icon': Icons.inventory_2,
        'label': 'Total Yield',
        'value': '690 kg',
        'color': AppColors.primary,
        'trend': '+12% vs last'
      },
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.8,
        children: stats
            .map((stat) => _buildProfessionalStatCard(stat, isDark, isMobile))
            .toList(),
      );
    }

    return Row(
      children: stats
          .map((stat) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildProfessionalStatCard(stat, isDark, isMobile),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildProfessionalStatCard(
      Map<String, dynamic> stat, bool isDark, bool isMobile) {
    final color = stat['color'] as Color;
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border:
            Border.all(color: isDark ? Colors.white10 : AppColors.neutral200),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(stat['icon'] as IconData,
                color: color, size: isMobile ? 18 : 22),
          ),
          SizedBox(width: isMobile ? AppSpacing.sm : AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat['value'] as String,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  stat['label'] as String,
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 12,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterBar(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border:
            Border.all(color: isDark ? Colors.white10 : AppColors.neutral200),
      ),
      child: isMobile
          ? Column(
              children: [
                // Search Field
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search batches, crops, farms...',
                    hintStyle: TextStyle(
                        color:
                            isDark ? Colors.white38 : AppColors.textSecondary,
                        fontSize: 13),
                    prefixIcon: Icon(Icons.search,
                        color:
                            isDark ? Colors.white38 : AppColors.textSecondary,
                        size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide: BorderSide(
                          color:
                              isDark ? Colors.white10 : AppColors.neutral300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide: BorderSide(
                          color:
                              isDark ? Colors.white10 : AppColors.neutral300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide: const BorderSide(color: AppColors.success),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.03)
                        : AppColors.neutral50,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    isDense: true,
                  ),
                  style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', true, isDark),
                      _buildFilterChip('Today', false, isDark),
                      _buildFilterChip('A Grade', false, isDark),
                      _buildFilterChip('B Grade', false, isDark),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                // Search Field
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search batches, crops, farms...',
                      hintStyle: TextStyle(
                          color:
                              isDark ? Colors.white38 : AppColors.textSecondary,
                          fontSize: 13),
                      prefixIcon: Icon(Icons.search,
                          color:
                              isDark ? Colors.white38 : AppColors.textSecondary,
                          size: 20),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        borderSide: BorderSide(
                            color:
                                isDark ? Colors.white10 : AppColors.neutral300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        borderSide: BorderSide(
                            color:
                                isDark ? Colors.white10 : AppColors.neutral300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        borderSide: const BorderSide(color: AppColors.success),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.03)
                          : AppColors.neutral50,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      isDense: true,
                    ),
                    style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Filter Chips
                _buildFilterChip('All', true, isDark),
                _buildFilterChip('Today', false, isDark),
                _buildFilterChip('A Grade', false, isDark),
                _buildFilterChip('B Grade', false, isDark),
                const SizedBox(width: AppSpacing.sm),
                // Sort Button
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: isDark ? Colors.white10 : AppColors.neutral300),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.sort,
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary,
                        size: 20),
                    tooltip: 'Sort',
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.textSecondary))),
        selected: isSelected,
        onSelected: (v) {},
        backgroundColor:
            isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral100,
        selectedColor: AppColors.success,
        checkmarkColor: Colors.white,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildHarvestCardsGrid(List<Map<String, String>> harvests, bool isDark,
      bool isMobile, bool isTablet) {
    // Create rows of 2 cards each
    final List<Widget> rows = [];
    for (int i = 0; i < harvests.length; i += 2) {
      final List<Widget> rowChildren = [];

      // First card
      rowChildren.add(
        Expanded(
          child: _buildCompactHarvestCard(harvests[i], isDark),
        ),
      );

      // Add spacing
      rowChildren.add(const SizedBox(width: 16));

      // Second card (if exists)
      if (i + 1 < harvests.length) {
        rowChildren.add(
          Expanded(
            child: _buildCompactHarvestCard(harvests[i + 1], isDark),
          ),
        );
      } else {
        // Empty spacer for odd number of cards
        rowChildren.add(const Expanded(child: SizedBox()));
      }

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren,
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildCompactHarvestCard(Map<String, String> harvest, bool isDark) {
    final qualityColor =
        harvest['quality'] == 'A' ? AppColors.success : AppColors.warning;
    final yieldPercent = (int.parse(harvest['actualYield']!) /
            int.parse(harvest['expectedYield']!) *
            100)
        .round();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border:
            Border.all(color: isDark ? Colors.white10 : AppColors.neutral200),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header with Status Strip
          Container(
            decoration: const BoxDecoration(
              border:
                  Border(left: BorderSide(color: AppColors.warning, width: 4)),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusLg),
                  topRight: Radius.circular(AppSpacing.radiusLg)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crop Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.success.withOpacity(0.2),
                          AppColors.success.withOpacity(0.1)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.eco,
                        color: AppColors.success, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Batch Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                harvest['crop']!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: qualityColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Grade ${harvest['quality']}',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: qualityColor,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${harvest['batch']} • ${harvest['farm']}',
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Compact Metrics
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
            ),
            child: Row(
              children: [
                Expanded(
                    child: _buildCompactMetricWithLabel(Icons.scale, 'Quantity',
                        '${harvest['quantity']} ${harvest['unit']}', isDark)),
                Container(
                    width: 1,
                    height: 36,
                    color: isDark ? Colors.white10 : AppColors.neutral200),
                Expanded(
                    child: _buildCompactMetricWithLabel(Icons.water_drop,
                        'Moisture', '${harvest['moisture']}%', isDark)),
                Container(
                    width: 1,
                    height: 36,
                    color: isDark ? Colors.white10 : AppColors.neutral200),
                Expanded(
                    child: _buildCompactMetricWithLabel(Icons.calendar_today,
                        'Harvest Date', harvest['date']!, isDark)),
              ],
            ),
          ),

          // Yield Progress
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Yield: $yieldPercent%',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondary),
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          child: Text(
                            harvest['caretaker']!
                                .split(' ')
                                .map((n) => n[0])
                                .take(2)
                                .join(),
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          harvest['caretaker']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color:
                                isDark ? Colors.white70 : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: yieldPercent / 100,
                    backgroundColor:
                        isDark ? Colors.white10 : AppColors.neutral200,
                    valueColor: AlwaysStoppedAnimation(yieldPercent >= 90
                        ? AppColors.success
                        : AppColors.warning),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withOpacity(0.02) : AppColors.neutral50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppSpacing.radiusLg),
                bottomRight: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Row(
              children: [
                // Details Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        _showHarvestDetailsModal(context, harvest, isDark),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color:
                                isDark ? Colors.white24 : AppColors.neutral300),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_outlined,
                              size: 16,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Reject Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(children: [
                            const Icon(Icons.cancel,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text('${harvest['batch']} rejected'),
                          ]),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: AppColors.error.withOpacity(0.5)),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close_rounded,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: 4),
                          Text(
                            'Reject',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Approve Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(children: [
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text('${harvest['batch']} approved'),
                          ]),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.success,
                            AppColors.success.withOpacity(0.85)
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_rounded,
                              size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Approve',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetric(IconData icon, String value, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 12, color: isDark ? Colors.white38 : AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildCompactMetricWithLabel(
      IconData icon, String label, String value, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isDark ? Colors.white38 : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white38 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showHarvestDetailsModal(
      BuildContext context, Map<String, String> harvest, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Extended harvest data with nursery info
    final harvestDetails = {
      ...harvest,
      'seedManufacturer': 'AgriSeeds Pro',
      'seedVariety': 'Premium Hybrid F1',
      'seedLot': 'LOT-2025-A142',
      'nurseryDate': '2025-11-15',
      'seedsNursed': '5,000',
      'germinationRate': '94%',
      'transplantDate': '2025-12-10',
      'transplantAmount': '4,700',
      'plantSpacing': '30cm x 45cm',
      'growthDuration': '49 days',
      'harvestPcs': '4,250',
      'wastage': '450 pcs (9.6%)',
      'avgWeight': '58.8g/pc',
      'fieldLocation': 'Block A, Row 1-15',
      'soilType': 'Loamy',
      'irrigationType': 'Drip Irrigation',
      'fertilizerUsed': 'NPK 15-15-15',
      'pesticidesUsed': 'Organic Neem Oil',
      'weatherCondition': 'Optimal',
    };

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40,
          vertical: isMobile ? 24 : 40,
        ),
        child: Container(
          width: isMobile ? double.infinity : 700,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modal Header
              Container(
                padding:
                    EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success,
                      AppColors.success.withOpacity(0.8)
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusXl)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child:
                          const Icon(Icons.eco, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${harvestDetails['crop']} Harvest Details',
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  harvestDetails['batch']!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                harvestDetails['farm']!,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.8)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Modal Content
              Flexible(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Stats Row
                      _buildQuickStatsRow(harvestDetails, isDark, isMobile),
                      SizedBox(
                          height: isMobile ? AppSpacing.md : AppSpacing.lg),

                      // Seed & Nursery Section
                      _buildDetailSection(
                        'Seed & Nursery Information',
                        Icons.grass,
                        AppColors.success,
                        [
                          _buildDetailRow(
                              'Seed Manufacturer',
                              harvestDetails['seedManufacturer']!,
                              Icons.factory,
                              isDark,
                              isMobile),
                          _buildDetailRow(
                              'Seed Variety',
                              harvestDetails['seedVariety']!,
                              Icons.eco,
                              isDark,
                              isMobile),
                          _buildDetailRow(
                              'Seed Lot Number',
                              harvestDetails['seedLot']!,
                              Icons.numbers,
                              isDark,
                              isMobile),
                          _buildDetailRow(
                              'Nursery Date',
                              harvestDetails['nurseryDate']!,
                              Icons.calendar_today,
                              isDark,
                              isMobile),
                          _buildDetailRow(
                              'Seeds Nursed',
                              harvestDetails['seedsNursed']!,
                              Icons.grain,
                              isDark,
                              isMobile),
                          _buildDetailRow(
                              'Germination Rate',
                              harvestDetails['germinationRate']!,
                              Icons.trending_up,
                              isDark,
                              isMobile),
                        ],
                        isDark,
                        isMobile,
                      ),
                      SizedBox(
                          height: isMobile ? AppSpacing.md : AppSpacing.lg),

                      // Transplant Section
                      _buildDetailSection(
                        'Transplant Information',
                        Icons.move_down,
                        AppColors.info,
                        [
                          _buildDetailRow(
                              'Transplant Date',
                              harvestDetails['transplantDate']!,
                              Icons.calendar_month,
                              isDark,
                              isMobile),
                          _buildDetailRow(
                              'Amount Transplanted',
                              harvestDetails['transplantAmount']!,
                              Icons.format_list_numbered,
                              isDark,
                              isMobile),
                          _buildDetailRow(
                              'Plant Spacing',
                              harvestDetails['plantSpacing']!,
                              Icons.space_bar,
                              isDark,
                              isMobile),
                          _buildDetailRow(
                              'Growth Duration',
                              harvestDetails['growthDuration']!,
                              Icons.timer,
                              isDark,
                              isMobile),
                        ],
                        isDark,
                        isMobile,
                      ),
                      SizedBox(
                          height: isMobile ? AppSpacing.md : AppSpacing.lg),

                      // Harvest Section
                      _buildDetailSection(
                        'Harvest Information',
                        Icons.agriculture,
                        AppColors.warning,
                        [
                          _buildDetailRow(
                              'Harvest Date',
                              harvestDetails['date']!,
                              Icons.event_available,
                              isDark,
                              isMobile),
                          _buildDetailRow(
                              'Harvest Time',
                              harvestDetails['time']!,
                              Icons.access_time,
                              isDark,
                              isMobile),
                          _buildDetailRow(
                              'Harvested Amount',
                              '${harvestDetails['quantity']} ${harvestDetails['unit']}',
                              Icons.scale,
                              isDark,
                              isMobile),
                          _buildDetailRow(
                              'Harvested Pieces',
                              harvestDetails['harvestPcs']!,
                              Icons.category,
                              isDark,
                              isMobile),
                          _buildDetailRow(
                              'Average Weight',
                              harvestDetails['avgWeight']!,
                              Icons.monitor_weight,
                              isDark,
                              isMobile),
                          _buildDetailRow('Wastage', harvestDetails['wastage']!,
                              Icons.delete_outline, isDark, isMobile),
                        ],
                        isDark,
                        isMobile,
                      ),
                      SizedBox(
                          height: isMobile ? AppSpacing.md : AppSpacing.lg),

                      // Caretaker & Notes
                      _buildCaretakerSection(harvestDetails, isDark, isMobile),
                    ],
                  ),
                ),
              ),

              // Modal Footer
              Container(
                padding:
                    EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : AppColors.neutral50,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppSpacing.radiusXl)),
                ),
                child: Row(
                  children: [
                    // Print Button
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.print, size: isMobile ? 16 : 18),
                      label: Text('Print',
                          style: TextStyle(fontSize: isMobile ? 12 : 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.white70 : AppColors.textSecondary,
                        side: BorderSide(
                            color:
                                isDark ? Colors.white24 : AppColors.neutral300),
                        padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16,
                            vertical: isMobile ? 10 : 12),
                      ),
                    ),
                    const Spacer(),
                    // Reject Button
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(children: [
                              const Icon(Icons.cancel,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text('${harvestDetails['batch']} rejected'),
                            ]),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: Icon(Icons.close, size: isMobile ? 16 : 18),
                      label: Text('Reject',
                          style: TextStyle(fontSize: isMobile ? 12 : 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16,
                            vertical: isMobile ? 10 : 12),
                      ),
                    ),
                    SizedBox(width: isMobile ? AppSpacing.sm : AppSpacing.md),
                    // Approve Button
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text('${harvestDetails['batch']} approved'),
                            ]),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: Icon(Icons.check, size: isMobile ? 16 : 18),
                      label: Text('Approve',
                          style: TextStyle(fontSize: isMobile ? 12 : 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 20,
                            vertical: isMobile ? 10 : 12),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow(
      Map<String, String> harvest, bool isDark, bool isMobile) {
    final stats = [
      {
        'icon': Icons.grain,
        'label': 'Seeds Nursed',
        'value': harvest['seedsNursed']!,
        'color': AppColors.success
      },
      {
        'icon': Icons.move_down,
        'label': 'Transplanted',
        'value': harvest['transplantAmount']!,
        'color': AppColors.info
      },
      {
        'icon': Icons.category,
        'label': 'Harvested Pcs',
        'value': harvest['harvestPcs']!,
        'color': AppColors.warning
      },
      {
        'icon': Icons.trending_up,
        'label': 'Germ. Rate',
        'value': harvest['germinationRate']!,
        'color': AppColors.primary
      },
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.2,
        children:
            stats.map((s) => _buildQuickStatCard(s, isDark, isMobile)).toList(),
      );
    }

    return Row(
      children: stats
          .map((s) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildQuickStatCard(s, isDark, isMobile),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildQuickStatCard(
      Map<String, dynamic> stat, bool isDark, bool isMobile) {
    final color = stat['color'] as Color;
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(stat['icon'] as IconData,
                size: isMobile ? 16 : 18, color: color),
          ),
          SizedBox(width: isMobile ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat['value'] as String,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  stat['label'] as String,
                  style: TextStyle(
                    fontSize: isMobile ? 9 : 10,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, Color color,
      List<Widget> children, bool isDark, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border:
            Border.all(color: isDark ? Colors.white10 : AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusMd)),
            ),
            child: Row(
              children: [
                Icon(icon, size: isMobile ? 18 : 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Padding(
            padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
            child: isMobile
                ? Column(children: children)
                : Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: children
                        .map((c) => SizedBox(width: 200, child: c))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, IconData icon, bool isDark, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon,
              size: 14,
              color: isDark ? Colors.white38 : AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaretakerSection(
      Map<String, String> harvest, bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
            AppColors.primary.withOpacity(isDark ? 0.08 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 24 : 28,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Text(
              harvest['caretaker']!.split(' ').map((n) => n[0]).take(2).join(),
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Responsible Caretaker',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  harvest['caretaker']!,
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${harvest['farm']} • ${harvest['section']}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalHarvestCard(
      Map<String, String> harvest, bool isDark, bool isMobile, bool isTablet) {
    final qualityColor =
        harvest['quality'] == 'A' ? AppColors.success : AppColors.warning;
    final yieldPercent = (int.parse(harvest['actualYield']!) /
            int.parse(harvest['expectedYield']!) *
            100)
        .round();

    return Container(
      margin: isMobile
          ? const EdgeInsets.only(bottom: AppSpacing.md)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border:
            Border.all(color: isDark ? Colors.white10 : AppColors.neutral200),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: Column(
        children: [
          // Card Header with Status Strip
          Container(
            decoration: BoxDecoration(
              border:
                  Border(left: BorderSide(color: AppColors.warning, width: 4)),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusLg),
                  topRight: Radius.circular(AppSpacing.radiusLg)),
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
              child: Column(
                children: [
                  // Top Row: Batch Info & Status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Crop Icon
                      Container(
                        width: isMobile ? 48 : 56,
                        height: isMobile ? 48 : 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.success.withOpacity(0.2),
                              AppColors.success.withOpacity(0.1)
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Icon(Icons.eco,
                            color: AppColors.success, size: isMobile ? 24 : 28),
                      ),
                      SizedBox(width: isMobile ? AppSpacing.sm : AppSpacing.md),
                      // Batch Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  harvest['crop']!,
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: qualityColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Grade ${harvest['quality']}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: qualityColor,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.tag,
                                    size: 12,
                                    color: isDark
                                        ? Colors.white38
                                        : AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  harvest['batch']!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white54
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.location_on_outlined,
                                    size: 12,
                                    color: isDark
                                        ? Colors.white38
                                        : AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${harvest['farm']} • ${harvest['section']}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white54
                                            : AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(
                              color: AppColors.warning.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  color: AppColors.warning,
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              harvest['status']!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Metrics Section
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppSpacing.md : AppSpacing.lg,
                vertical: isMobile ? AppSpacing.sm : AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.02)
                  : AppColors.neutral50.withOpacity(0.5),
            ),
            child: isMobile
                ? Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: _buildMetricItem(
                                  Icons.scale,
                                  'Quantity',
                                  '${harvest['quantity']} ${harvest['unit']}',
                                  isDark,
                                  isMobile)),
                          Expanded(
                              child: _buildMetricItem(
                                  Icons.water_drop,
                                  'Moisture',
                                  '${harvest['moisture']}%',
                                  isDark,
                                  isMobile)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                              child: _buildMetricItem(
                                  Icons.calendar_today,
                                  'Harvest Date',
                                  harvest['date']!,
                                  isDark,
                                  isMobile)),
                          Expanded(
                              child: _buildMetricItem(Icons.access_time, 'Time',
                                  harvest['time']!, isDark, isMobile)),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                          child: _buildMetricItem(
                              Icons.scale,
                              'Quantity',
                              '${harvest['quantity']} ${harvest['unit']}',
                              isDark,
                              isMobile)),
                      _buildMetricDivider(isDark),
                      Expanded(
                          child: _buildMetricItem(Icons.water_drop, 'Moisture',
                              '${harvest['moisture']}%', isDark, isMobile)),
                      _buildMetricDivider(isDark),
                      Expanded(
                          child: _buildMetricItem(
                              Icons.calendar_today,
                              'Harvest Date',
                              harvest['date']!,
                              isDark,
                              isMobile)),
                      _buildMetricDivider(isDark),
                      Expanded(
                          child: _buildMetricItem(Icons.access_time, 'Time',
                              harvest['time']!, isDark, isMobile)),
                    ],
                  ),
          ),

          // Yield Progress & Caretaker
          Padding(
            padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
            child: Column(
              children: [
                // Yield Progress Bar
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Yield Achievement',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : AppColors.textSecondary),
                              ),
                              Text(
                                '$yieldPercent%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: yieldPercent >= 90
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: yieldPercent / 100,
                              backgroundColor: isDark
                                  ? Colors.white10
                                  : AppColors.neutral200,
                              valueColor: AlwaysStoppedAnimation(
                                  yieldPercent >= 90
                                      ? AppColors.success
                                      : AppColors.warning),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${harvest['actualYield']} of ${harvest['expectedYield']} kg expected',
                            style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.white38
                                    : AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isMobile ? AppSpacing.md : AppSpacing.lg),
                    // Caretaker Info
                    Container(
                      padding: EdgeInsets.all(
                          isMobile ? AppSpacing.sm : AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.03)
                            : AppColors.neutral100,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: isMobile ? 14 : 16,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              harvest['caretaker']!
                                  .split(' ')
                                  .map((n) => n[0])
                                  .take(2)
                                  .join(),
                              style: TextStyle(
                                  fontSize: isMobile ? 10 : 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                harvest['caretaker']!,
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Caretaker',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.white38
                                        : AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Notes (if any)
                if (harvest['notes']?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border:
                          Border.all(color: AppColors.info.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: AppColors.info),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            harvest['notes']!,
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Buttons
          Container(
            padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withOpacity(0.02) : AppColors.neutral50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppSpacing.radiusLg),
                bottomRight: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Row(
              children: [
                // View Details Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        _showHarvestDetailsModal(context, harvest, isDark),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 10 : 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color:
                                isDark ? Colors.white24 : AppColors.neutral300),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_outlined,
                              size: isMobile ? 16 : 18,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Details',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Reject Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(children: [
                            const Icon(Icons.cancel,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text('${harvest['batch']} rejected'),
                          ]),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 10 : 12),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: AppColors.error.withOpacity(0.5)),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close_rounded,
                              size: isMobile ? 16 : 18, color: AppColors.error),
                          const SizedBox(width: 6),
                          Text(
                            'Reject',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? AppSpacing.sm : AppSpacing.md),
                // Approve Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(children: [
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text('${harvest['batch']} approved'),
                          ]),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 20,
                          vertical: isMobile ? 10 : 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.success,
                            AppColors.success.withOpacity(0.85)
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded,
                              size: isMobile ? 16 : 18, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Approve',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
      IconData icon, String label, String value, bool isDark, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 8),
      child: Row(
        children: [
          Icon(icon,
              size: isMobile ? 14 : 16,
              color: isDark ? Colors.white38 : AppColors.textSecondary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                    fontSize: isMobile ? 9 : 10,
                    color: isDark ? Colors.white38 : AppColors.textSecondary),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDivider(bool isDark) {
    return Container(
      width: 1,
      height: 30,
      color: isDark ? Colors.white10 : AppColors.neutral200,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  // ============================================
  // DELIVERY TRIGGER CONTENT VIEW
  // ============================================
  Widget _buildDeliveryTriggerContent(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Bar with back button
              Container(
                padding:
                    EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.info, AppColors.info.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          setState(() => _currentView = 'dashboard'),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      tooltip: 'Back to Dashboard',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const Icon(Icons.local_shipping,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Management',
                            style: AppTypography.h5.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 18 : 20),
                          ),
                          Text(
                            'Schedule and manage deliveries',
                            style: AppTypography.bodySmall
                                .copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),

              // Quick Stats
              Row(
                children: [
                  _buildDeliveryStat('Scheduled', '3', AppColors.info,
                      Icons.schedule, isDark, isMobile),
                  const SizedBox(width: AppSpacing.sm),
                  _buildDeliveryStat('In Transit', '2', AppColors.warning,
                      Icons.local_shipping, isDark, isMobile),
                  const SizedBox(width: AppSpacing.sm),
                  _buildDeliveryStat('Delivered', '12', AppColors.success,
                      Icons.check_circle, isDark, isMobile),
                ],
              ),
              SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),

              // Schedule New Delivery Section (move select - must come before round history on mobile)
              _buildSectionTitle(
                  'Schedule New Delivery', Icons.add_circle, isDark, isMobile),
              const SizedBox(height: AppSpacing.md),
              _buildDeliveryForm(isDark, isMobile),

              SizedBox(height: isMobile ? AppSpacing.lg : AppSpacing.xl),

              if (isMobile) ...[
                // Mobile: move select (form) before round history - Recent first, then Upcoming
                _buildSectionTitle(
                    'Recent Deliveries', Icons.history, isDark, isMobile),
                const SizedBox(height: AppSpacing.md),
                _buildRecentDeliveries(isDark, isMobile),
                SizedBox(height: AppSpacing.lg),
                _buildSectionTitle(
                    'Upcoming Deliveries', Icons.upcoming, isDark, isMobile),
                const SizedBox(height: AppSpacing.md),
                _buildUpcomingDeliveries(isDark, isMobile),
              ] else ...[
                // Desktop: Upcoming first, then Recent
                _buildSectionTitle(
                    'Upcoming Deliveries', Icons.upcoming, isDark, isMobile),
                const SizedBox(height: AppSpacing.md),
                _buildUpcomingDeliveries(isDark, isMobile),
                SizedBox(height: AppSpacing.xl),
                _buildSectionTitle(
                    'Recent Deliveries', Icons.history, isDark, isMobile),
                const SizedBox(height: AppSpacing.md),
                _buildRecentDeliveries(isDark, isMobile),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryStat(String label, String value, Color color,
      IconData icon, bool isDark, bool isMobile) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
              ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: isMobile ? 20 : 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: isMobile ? 18 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
      String title, IconData icon, bool isDark, bool isMobile) {
    return Row(
      children: [
        Icon(icon, color: AppColors.info, size: isMobile ? 20 : 24),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTypography.h6.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 16 : 18,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryForm(bool isDark, bool isMobile) {
    final availableBatches = [
      'BATCH-156',
      'BATCH-157',
      'BATCH-158',
      'BATCH-159',
      'BATCH-160'
    ];
    final destinations = [
      'Warehouse A',
      'Warehouse B',
      'Distribution Center',
      'Market Stand',
      'Direct Customer'
    ];
    final vehicles = ['Truck-01', 'Truck-02', 'Van-01', 'Van-02', 'Pickup-01'];

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border:
            Border.all(color: isDark ? Colors.white10 : AppColors.neutral200),
      ),
      child: Column(
        children: [
          if (isMobile) ...[
            // Mobile: Stack vertically
            _buildFormField('Select Batch', availableBatches.first,
                availableBatches, Icons.inventory_2, isDark),
            const SizedBox(height: AppSpacing.md),
            _buildFormField('Destination', destinations.first, destinations,
                Icons.location_on, isDark),
            const SizedBox(height: AppSpacing.md),
            _buildFormField('Assign Vehicle', vehicles.first, vehicles,
                Icons.local_shipping, isDark),
            const SizedBox(height: AppSpacing.md),
            _buildDateField('Delivery Date',
                DateTime.now().add(const Duration(days: 1)), isDark),
            const SizedBox(height: AppSpacing.md),
            TextField(
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Delivery Notes (Optional)',
                hintText: 'Special instructions...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : AppColors.neutral50,
              ),
              style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary),
            ),
          ] else ...[
            // Desktop: Grid layout
            Row(
              children: [
                Expanded(
                    child: _buildFormField(
                        'Select Batch',
                        availableBatches.first,
                        availableBatches,
                        Icons.inventory_2,
                        isDark)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: _buildFormField('Destination', destinations.first,
                        destinations, Icons.location_on, isDark)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                    child: _buildFormField('Assign Vehicle', vehicles.first,
                        vehicles, Icons.local_shipping, isDark)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: _buildDateField('Delivery Date',
                        DateTime.now().add(const Duration(days: 1)), isDark)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Delivery Notes (Optional)',
                hintText: 'Special instructions for delivery...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : AppColors.neutral50,
              ),
              style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(child: Text('Delivery scheduled successfully!'))
                    ]),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.local_shipping),
              label: const Text('Schedule Delivery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, String value, List<String> options,
      IconData icon, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(
                color: isDark ? Colors.white24 : AppColors.neutral300),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            color:
                isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down,
                  color: isDark ? Colors.white54 : AppColors.textSecondary),
              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
              items: options
                  .map((e) => DropdownMenuItem(
                      value: e,
                      child: Row(
                        children: [
                          Icon(icon,
                              size: 16,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(e,
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary)),
                        ],
                      )))
                  .toList(),
              onChanged: (v) {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime date, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(
                  color: isDark ? Colors.white24 : AppColors.neutral300),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              color:
                  isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 18,
                    color: isDark ? Colors.white54 : AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down,
                    color: isDark ? Colors.white54 : AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingDeliveries(bool isDark, bool isMobile) {
    final upcoming = [
      {
        'batch': 'BATCH-155',
        'dest': 'Warehouse A',
        'vehicle': 'Truck-01',
        'date': 'Jan 29',
        'status': 'Scheduled'
      },
      {
        'batch': 'BATCH-154',
        'dest': 'Market Stand',
        'vehicle': 'Van-01',
        'date': 'Jan 30',
        'status': 'Scheduled'
      },
      {
        'batch': 'BATCH-153',
        'dest': 'Distribution Center',
        'vehicle': 'Truck-02',
        'date': 'Jan 31',
        'status': 'Scheduled'
      },
    ];

    return Column(
      children: upcoming
          .map((d) => _buildDeliveryCard(d, AppColors.info, isDark, isMobile))
          .toList(),
    );
  }

  Widget _buildRecentDeliveries(bool isDark, bool isMobile) {
    final recent = [
      {
        'batch': 'BATCH-150',
        'dest': 'Warehouse B',
        'vehicle': 'Van-02',
        'date': 'Jan 27',
        'status': 'Delivered'
      },
      {
        'batch': 'BATCH-149',
        'dest': 'Direct Customer',
        'vehicle': 'Pickup-01',
        'date': 'Jan 26',
        'status': 'Delivered'
      },
    ];

    return Column(
      children: recent
          .map(
              (d) => _buildDeliveryCard(d, AppColors.success, isDark, isMobile))
          .toList(),
    );
  }

  Widget _buildDeliveryCard(Map<String, String> delivery, Color statusColor,
      bool isDark, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border:
            Border.all(color: isDark ? Colors.white10 : AppColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(Icons.local_shipping,
                color: statusColor, size: isMobile ? 18 : 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delivery['batch']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 13 : 14,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${delivery['dest']} • ${delivery['vehicle']}',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  delivery['status']!,
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                delivery['date']!,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
            ],
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
        'route': '/farm-manager'
      },
      {
        'icon': Icons.agriculture_outlined,
        'label': 'Farms',
        'index': 1,
        'route': '/farm-manager/farms'
      },
      {
        'icon': Icons.inventory_2_outlined,
        'label': 'Inventory',
        'index': 2,
        'route': '/farm-manager/inventory'
      },
      {
        'icon': Icons.local_shipping_outlined,
        'label': 'Deliveries',
        'index': 3,
        'route': '/farm-manager/deliveries'
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

  Widget _buildFeaturesGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final features = [
      {
        'title': 'Inventory',
        'icon': Icons.inventory_2_rounded,
        'color': const Color(0xFF6366F1),
        'route': '/farm-manager/inventory'
      },
      {
        'title': 'Batches',
        'icon': Icons.layers_rounded,
        'color': const Color(0xFF0EA5E9),
        'route': '/farm-manager/batch-generation'
      },
      {
        'title': 'Harvest',
        'icon': Icons.agriculture_rounded,
        'color': const Color(0xFF10B981),
        'action': 'harvest_approval'
      },
      {
        'title': 'Budget',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFFF59E0B),
        'route': '/farm-manager/fund-request'
      },
      {
        'title': 'Delivery',
        'icon': Icons.local_shipping_rounded,
        'color': const Color(0xFF8B5CF6),
        'route': '/farm-manager/deliveries'
      },
      {
        'title': 'Reports',
        'icon': Icons.bar_chart_rounded,
        'color': const Color(0xFFEC4899),
        'route': '/farm-manager/reports'
      },
      {
        'title': 'Team',
        'icon': Icons.groups_rounded,
        'color': const Color(0xFF14B8A6),
        'route': '/farm-manager/team'
      },
      {
        'title': 'Settings',
        'icon': Icons.settings_rounded,
        'color': const Color(0xFF64748B),
        'route': null
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = isMobile ? 8.0 : 12.0;
        final cardWidth = isMobile
            ? (constraints.maxWidth - (spacing * 3)) / 4
            : 80.0;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: features
              .map((f) => _buildFeatureCard(
                    context,
                    isDark,
                    f['title'] as String,
                    f['icon'] as IconData,
                    f['color'] as Color,
                    f,
                    isMobile,
                    cardWidth,
                  ))
              .toList(),
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
    Map<String, dynamic> feature,
    bool isMobile,
    double cardWidth,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (feature['action'] != null) {
            setState(() => _currentView = feature['action'] as String);
          } else if (feature['dialog'] == 'budget') {
            _showBudgetRequestDialog(context, isDark);
          } else if (feature['route'] != null) {
            Navigator.pushNamed(context, feature['route'] as String);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: cardWidth.clamp(60.0, 90.0),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isMobile ? 44 : 52,
                height: isMobile ? 44 : 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: isMobile ? 22 : 26, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============= FARM MANAGER DIALOGS =============

  void _showBudgetRequestDialog(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Seeds & Inputs';
    String selectedFarm = 'Green Valley Farm';
    String selectedPriority = 'Medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl,
              vertical: AppSpacing.lg),
          child: Container(
            width: isMobile ? double.infinity : 500,
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.warning,
                      AppColors.warning.withOpacity(0.8)
                    ]),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd)),
                        child: const Icon(Icons.request_quote,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Budget Request',
                                style: AppTypography.h6.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            Text('Request funds for farm operations',
                                style: AppTypography.bodySmall
                                    .copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Farm Selection
                        _buildDialogLabel('Select Farm', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDialogDropdown(
                            selectedFarm,
                            ['Green Valley Farm', 'Sunny Acres', 'Fresh Farms'],
                            (v) => setDialogState(() => selectedFarm = v!),
                            isDark),
                        const SizedBox(height: AppSpacing.lg),

                        // Category
                        _buildDialogLabel('Budget Category', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDialogDropdown(
                            selectedCategory,
                            [
                              'Seeds & Inputs',
                              'Equipment',
                              'Labor',
                              'Maintenance',
                              'Utilities',
                              'Transport',
                              'Other'
                            ],
                            (v) => setDialogState(() => selectedCategory = v!),
                            isDark),
                        const SizedBox(height: AppSpacing.lg),

                        // Amount
                        _buildDialogLabel('Amount Requested', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            prefixText: 'GH₵ ',
                            hintText: 'Enter amount',
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd)),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withOpacity(0.05)
                                : AppColors.neutral50,
                          ),
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Priority
                        _buildDialogLabel('Priority', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children:
                              ['Low', 'Medium', 'High', 'Urgent'].map((p) {
                            final isSelected = selectedPriority == p;
                            final color = p == 'Urgent'
                                ? AppColors.error
                                : p == 'High'
                                    ? AppColors.warning
                                    : p == 'Medium'
                                        ? AppColors.info
                                        : AppColors.success;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    right: p != 'Urgent' ? AppSpacing.xs : 0),
                                child: InkWell(
                                  onTap: () => setDialogState(
                                      () => selectedPriority = p),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? color.withOpacity(0.2)
                                          : (isDark
                                              ? Colors.white.withOpacity(0.05)
                                              : AppColors.neutral50),
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusSm),
                                      border: Border.all(
                                          color: isSelected
                                              ? color
                                              : (isDark
                                                  ? Colors.white10
                                                  : AppColors.neutral200)),
                                    ),
                                    child: Text(p,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? color
                                                : (isDark
                                                    ? Colors.white70
                                                    : AppColors
                                                        .textSecondary))),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Description
                        _buildDialogLabel(
                            'Description / Justification', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                'Provide details about why this budget is needed...',
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd)),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withOpacity(0.05)
                                : AppColors.neutral50,
                          ),
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Info
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                                color: AppColors.info.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: AppColors.info, size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                  child: Text(
                                      'Request will be sent to Admin for approval. You will be notified once approved.',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.white70
                                              : AppColors.textSecondary))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.03)
                        : AppColors.neutral50,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md)),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (amountController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        const Text('Please enter an amount'),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating),
                              );
                              return;
                            }
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(
                                          'Budget request of GH₵${amountController.text} submitted for $selectedFarm'))
                                ]),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          },
                          icon: const Icon(Icons.send, size: 18),
                          label: const Text('Submit Request'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widgets for Dialogs
  Widget _buildDialogLabel(String label, bool isDark) {
    return Text(label,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.textSecondary));
  }

  Widget _buildDialogDropdown(String value, List<String> items,
      Function(String?) onChanged, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        border:
            Border.all(color: isDark ? Colors.white24 : AppColors.neutral300),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          items: items
              .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item,
                      style: TextStyle(
                          color:
                              isDark ? Colors.white : AppColors.textPrimary))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.textPrimary)),
        ],
      ),
    );
  }
}
