import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_manager_sidebar.dart';
import '../../core/widgets/farm_manager_header.dart';
import '../../core/widgets/farm_manager_mobile_drawer.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Farms Screen for Farm Manager
/// Shows farms under management with team members, roles, and progress
class FarmsScreen extends ConsumerStatefulWidget {
  const FarmsScreen({super.key});

  @override
  ConsumerState<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends ConsumerState<FarmsScreen>
    with SingleTickerProviderStateMixin {
  final SuperAdminApiService _api = SuperAdminApiService();
  int _selectedNavIndex = 1;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? _selectedFarm;

  // ── Backend data cache ─────────────────────────────────────────────────

  final List<Map<String, dynamic>> _farms = [];
  final List<Map<String, dynamic>> _users = [];
  final List<Map<String, dynamic>> _batches = [];
  final List<Map<String, dynamic>> _inventory = [];
  final List<Map<String, dynamic>> _sensors = [];
  final List<Map<String, dynamic>> _sales = [];
  final List<Map<String, dynamic>> _tasks = [];
  final Set<String> _updatingTaskIds = {};
  final Set<String> _deletingTaskIds = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _api.getFarms(),
        _api.getUsers(),
        _api.getBatches(),
        _api.getInventory(),
        _api.getSensors(),
        _api.getSales(),
        _api.getFarmTasks(),
      ]);
      if (!mounted) return;
      setState(() {
        _users
          ..clear()
          ..addAll(results[1]);
        _batches
          ..clear()
          ..addAll(results[2]);
        _inventory
          ..clear()
          ..addAll(results[3]);
        _sensors
          ..clear()
          ..addAll(results[4]);
        _sales
          ..clear()
          ..addAll(results[5]);
        _tasks
          ..clear()
          ..addAll(results[6]);
        _farms
          ..clear()
          ..addAll(results[0].where(_isAssignedToCurrentManager).map(_mapFarm));
        if (_selectedFarm != null) {
          final selectedId = _selectedFarm!['id']?.toString() ?? '';
          _selectedFarm = _farms.cast<Map<String, dynamic>?>().firstWhere(
                (farm) => farm?['id']?.toString() == selectedId,
                orElse: () => null,
              );
        }
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  String _docId(Map<String, dynamic> doc) =>
      (doc[r'$id'] ?? doc['id'] ?? doc['farm_id'] ?? '').toString();

  String _taskDocId(Map<String, dynamic> task) =>
      (task[r'$id'] ?? task['id'] ?? '').toString();

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

  String _normaliseKey(dynamic value) =>
      value?.toString().trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ??
      '';

  void _addIdentityToken(Set<String> tokens, dynamic value) {
    final token = _normaliseKey(value);
    if (token.isNotEmpty && token != 'unassigned' && token != 'system') {
      tokens.add(token);
    }
  }

  void _addFarmAssignmentToken(Set<String> tokens, dynamic value) {
    if (value is Iterable) {
      for (final item in value) {
        _addFarmAssignmentToken(tokens, item);
      }
      return;
    }
    if (value is Map<String, dynamic>) {
      _addIdentityToken(tokens, _docId(value));
      _addIdentityToken(tokens, value['id']);
      _addIdentityToken(tokens, value['email']);
      _addIdentityToken(tokens, value['name']);
      return;
    }
    _addIdentityToken(tokens, value);
  }

  num _numValue(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _isAssignedToCurrentManager(Map<String, dynamic> farm) {
    final user = ref.read(authProvider).user;
    if (user == null) return true;
    final identityTokens = <String>{};
    _addIdentityToken(identityTokens, user.id);
    _addIdentityToken(identityTokens, user.email);
    _addIdentityToken(identityTokens, user.name);
    _addIdentityToken(identityTokens, user.farmId);

    for (final backendUser in _users) {
      final backendTokens = <String>{};
      _addIdentityToken(backendTokens, _docId(backendUser));
      _addIdentityToken(backendTokens, backendUser['id']);
      _addIdentityToken(backendTokens, backendUser['email']);
      _addIdentityToken(backendTokens, backendUser['name']);
      if (backendTokens.intersection(identityTokens).isNotEmpty) {
        identityTokens.addAll(backendTokens);
      }
    }

    final assignmentTokens = <String>{};
    _addFarmAssignmentToken(assignmentTokens, _docId(farm));
    _addFarmAssignmentToken(assignmentTokens, farm['farmID']);
    _addFarmAssignmentToken(assignmentTokens, farm['farm_id']);
    for (final key in [
      'farm_manager_id',
      'farmManagerId',
      'farmManagerID',
      'farm_manager',
      'farmManager',
      'farm_manager_email',
      'farmManagerEmail',
      'farm_manager_name',
      'farmManagerName',
      'assigned_manager_id',
      'assignedManagerId',
      'assignedManagerID',
      'assignedManagers',
      'manager_ids',
      'managerIds',
      'managerIDs',
    ]) {
      _addFarmAssignmentToken(assignmentTokens, farm[key]);
    }

    return assignmentTokens.intersection(identityTokens).isNotEmpty;
  }

  void _openFarmDetails(Map<String, dynamic> farm) {
    setState(() => _selectedFarm = farm);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _closeFarmDetails() {
    setState(() => _selectedFarm = null);
  }

  bool _matchesFarm(Map<String, dynamic> doc, Map<String, dynamic> farm) {
    final farmId = _docId(farm);
    final farmName = _value(farm, ['name', 'farm_name']);
    final docFarmId = _value(doc, ['farmID', 'farm_id', 'farmId']);
    final docFarmName = _value(doc, ['farm_name', 'farmName']);
    return (farmId.isNotEmpty && docFarmId == farmId) ||
        (farmName.isNotEmpty && docFarmName == farmName);
  }

  Map<String, dynamic>? _findUser(String idOrEmail) {
    if (idOrEmail.trim().isEmpty ||
        idOrEmail == 'Unassigned' ||
        idOrEmail == 'system') {
      return null;
    }
    for (final user in _users) {
      final userId = _docId(user);
      final email = _value(user, ['email']);
      final name = _value(user, ['name']);
      if (idOrEmail == userId || idOrEmail == email || idOrEmail == name) {
        return user;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _tasksForFarm(Map<String, dynamic> farm) =>
      _tasks.where((task) => _matchesFarm(task, farm)).toList();

  List<Map<String, dynamic>> _tasksForMember(
    Map<String, dynamic> farm,
    String memberRef,
  ) {
    final user = _findUser(memberRef);
    final refs = <String>{memberRef};
    if (user != null) {
      refs.addAll([
        _docId(user),
        user['id']?.toString() ?? '',
        user['email']?.toString() ?? '',
        user['name']?.toString() ?? '',
      ]);
    }
    final tokens = refs.map(_normaliseKey).where((token) => token.isNotEmpty);
    return _tasksForFarm(farm).where((task) {
      final assignee = [
        task['assigned_to_id'],
        task['assigned_to_name'],
      ].map(_normaliseKey);
      return assignee.any(tokens.contains);
    }).toList();
  }

  Map<String, dynamic> _teamMember(
    Map<String, dynamic> farm,
    List<String> keys,
    String role,
  ) {
    final userRef = _value(farm, keys);
    final user = _findUser(userRef);
    final memberTasks = _tasksForMember(farm, userRef);
    final completedTasks = memberTasks
        .where((task) =>
            _value(task, ['status']).toLowerCase().trim() == 'completed')
        .length;
    final name = user == null
        ? (userRef.isEmpty || userRef == 'Unassigned' ? 'Unassigned' : userRef)
        : _value(user, ['name'], fallback: userRef);
    final status = user == null
        ? 'Unassigned'
        : _value(user, ['status'], fallback: 'Active');
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return {
      'name': name,
      'role': role,
      'avatar': initials.isEmpty ? '--' : initials,
      'status': status,
      'id': user == null ? userRef : _docId(user),
      'tasks': memberTasks.length,
      'completed': completedTasks,
      'progress':
          memberTasks.isEmpty ? 0.0 : completedTasks / memberTasks.length,
      'hasTaskData': memberTasks.isNotEmpty,
      'phone': user == null ? '' : _value(user, ['phone', 'phone_number']),
      'email': user == null ? '' : _value(user, ['email']),
      'joinedDate': user == null
          ? 'N/A'
          : _formatDate(_value(user, [r'$createdAt', 'created_at'])),
      'specialty': role,
    };
  }

  Map<String, dynamic> _mapFarm(Map<String, dynamic> farm) {
    final activeBatches = _batches.where((batch) {
      final status =
          _value(batch, ['production_status', 'status']).toLowerCase().trim();
      return _matchesFarm(batch, farm) &&
          !{'completed', 'delivered', 'cancelled', 'harvested'}
              .contains(status);
    }).length;
    final farmInventory = _inventory.where((item) => _matchesFarm(item, farm));
    final totalHarvest = farmInventory.fold<num>(
      0,
      (sum, item) =>
          sum +
          _numValue(
              item['quantity_available'] ?? item['quantity'] ?? item['stock']),
    );
    final sensorCount =
        _sensors.where((sensor) => _matchesFarm(sensor, farm)).length;
    final crops = <String>{
      _value(farm, ['plant_type', 'plantType']),
      _value(farm, ['plant_variety', 'plantVariety']),
    }.where((crop) => crop.isNotEmpty).toList();
    final progress = activeBatches == 0
        ? 0.0
        : (farmInventory.isEmpty ? 0.35 : 0.75).clamp(0.0, 1.0).toDouble();

    return {
      ...farm,
      'id': _docId(farm),
      'name': _value(farm, ['name', 'farm_name'], fallback: 'Unnamed Farm'),
      'location': _value(farm, ['location'], fallback: 'Location not set'),
      'size': _value(farm, ['size', 'acreage'], fallback: 'Not set'),
      'type': _value(farm, ['plant_type', 'type'], fallback: 'Farm'),
      'status': _value(farm, ['status'], fallback: 'Active'),
      'crops': crops,
      'activeBatches': activeBatches,
      'totalHarvest': '${_formatCompact(totalHarvest)} units',
      'revenue': 'GHS 0',
      'progress': progress,
      'sensorCount': sensorCount,
      'sensorApiKey': _value(farm, ['sensor_ingest_api_key']),
      'team': [
        _teamMember(farm, ['farm_manager_id', 'farmManagerId'], 'Farm Manager'),
        _teamMember(farm, ['technician_id', 'technicianId'], 'Technician'),
        _teamMember(farm, ['caretakerID', 'caretaker_id'], 'Caretaker'),
        _teamMember(farm, ['ownerID', 'owner_id'], 'Owner'),
      ].where((member) => member['name'] != 'Unassigned').toList(),
    };
  }

  String _formatCompact(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return 'N/A';
    return '${date.month}/${date.year}';
  }

  String _formatTaskDate(String value, {String fallback = 'No due date'}) {
    final date = DateTime.tryParse(value);
    if (date == null) return fallback;
    return DateFormat('MMM d, yyyy').format(date.toLocal());
  }

  String _formatTaskDateTime(String value, {String fallback = 'N/A'}) {
    final date = DateTime.tryParse(value);
    if (date == null) return fallback;
    return DateFormat('MMM d, yyyy • h:mm a').format(date.toLocal());
  }

  List<Map<String, dynamic>> get _filteredFarms {
    var result = _farms;
    if (_selectedFilter != 'All') {
      result =
          result.where((f) => (f['status'] ?? '') == _selectedFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((f) =>
              (f['name']?.toString() ?? '').toLowerCase().contains(q) ||
              (f['location']?.toString() ?? '').toLowerCase().contains(q) ||
              (f['type']?.toString() ?? '').toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  int get _totalTeamMembers =>
      _farms.fold(0, (sum, f) => sum + ((f['team'] as List?)?.length ?? 0));

  int get _activeTeamMembers => _farms.fold(0, (sum, f) {
        final team = f['team'] as List<Map<String, dynamic>>? ?? [];
        return sum + team.where((m) => m['status'] == 'Active').length;
      });

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Farm Manager';

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
          : _buildDesktopLayout(isDark, userName),
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName) {
    final authState = ref.watch(authProvider);
    return Row(
      children: [
        FarmManagerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (i) => setState(() => _selectedNavIndex = i),
          userName: userName,
          userEmail: authState.user?.email ?? '',
          userRole: 'Farm Manager',
        ),
        Expanded(
          child: Column(
            children: [
              FarmManagerHeader(userName: userName),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: _buildContent(isDark, false),
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
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildContent(isDark, true),
          ),
        ),
        SafeArea(top: false, child: _buildBottomNavigation(isDark)),
      ],
    );
  }

  // ── Content ─────────────────────────────────────────────────────────────

  Widget _buildContent(bool isDark, bool isMobile) {
    if (_isLoading) {
      return const AdminDataSkeleton(rowCount: 6);
    }
    if (_errorMessage != null) {
      return _buildErrorState(isDark);
    }
    if (_selectedFarm != null) {
      return _buildFarmDetailsPage(_selectedFarm!, isDark);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(isDark, isMobile),
        SizedBox(height: isMobile ? 16 : 24),
        _buildStatsRow(isDark, isMobile),
        SizedBox(height: isMobile ? 16 : 24),
        _buildFarmsSection(isDark, isMobile),
      ],
    );
  }

  // ── Page Header ─────────────────────────────────────────────────────────

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Could not load farms',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'The farm service did not return data.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadFarms,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(bool isDark, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Farms',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your farms, teams and track performance',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 13 : 14,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stats Row ───────────────────────────────────────────────────────────

  Widget _buildStatsRow(bool isDark, bool isMobile) {
    final stats = [
      {
        'label': 'Total Farms',
        'value': '${_farms.length}',
        'icon': Icons.agriculture_rounded,
        'color': AppColors.primary
      },
      {
        'label': 'Team Members',
        'value': '$_totalTeamMembers',
        'icon': Icons.groups_rounded,
        'color': AppColors.info
      },
      {
        'label': 'Active Staff',
        'value': '$_activeTeamMembers',
        'icon': Icons.person_rounded,
        'color': AppColors.success
      },
      {
        'label': 'Active Batches',
        'value':
            '${_farms.fold(0, (int s, f) => s + ((f['activeBatches'] as int?) ?? 0))}',
        'icon': Icons.layers_rounded,
        'color': AppColors.warning
      },
    ];

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: isMobile ? 2.0 : 2.5,
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
        border: Border.all(
            color:
                isDark ? Colors.white.withOpacity(0.06) : AppColors.neutral200),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat['icon'] as IconData,
                size: isMobile ? 20 : 22, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat['value'] as String,
                  style: GoogleFonts.inter(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimary),
                ),
                Text(
                  stat['label'] as String,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                      fontWeight: FontWeight.w500),
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

  // ── Farms Section ───────────────────────────────────────────────────────

  Widget _buildFarmsSection(bool isDark, bool isMobile) {
    final filtered = _filteredFarms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : AppColors.neutral200,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: isMobile
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.agriculture_rounded,
                            size: 22, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Farms Overview',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Showing ${filtered.length} assigned farms',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isMobile) const Spacer(),
                  if (isMobile) const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ['All', 'Active', 'Seasonal']
                        .map((f) => _filterChip(f, isDark))
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search farms by name, location, crop or team...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : AppColors.textSecondary,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20,
                      color: isDark ? Colors.white38 : AppColors.textSecondary),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : AppColors.neutral50,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : AppColors.neutral200,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : AppColors.neutral200,
              ),
            ),
            child: _buildEmptyState(isDark),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : AppColors.neutral200,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.035),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildFarmDataCard(filtered[i], isDark, isMobile),
            ),
          ),
      ],
    );
  }

  Widget _filterChip(String label, bool isDark) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : AppColors.neutral100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                      ? Colors.white.withOpacity(0.08)
                      : AppColors.neutral300)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white60 : AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.agriculture_outlined,
              size: 56, color: isDark ? Colors.white24 : AppColors.neutral400),
          const SizedBox(height: 12),
          Text('No farms found',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('Try adjusting your search or filter',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ── Farm Card ───────────────────────────────────────────────────────────

  Widget _buildFarmDataCard(
      Map<String, dynamic> farm, bool isDark, bool isMobile) {
    final team = (farm['team'] as List<Map<String, dynamic>>?) ?? [];
    final crops = (farm['crops'] as List<String>?) ?? [];
    final rawProgress = farm['progress'];
    final progress = rawProgress is num
        ? rawProgress.toDouble().clamp(0.0, 1.0).toDouble()
        : 0.0;
    final status = farm['status']?.toString() ?? 'Pending';
    final statusColor = status.toLowerCase() == 'active'
        ? AppColors.success
        : AppColors.warning;
    final visibleCrops = crops.take(4).toList();
    final hiddenCropCount = crops.length - visibleCrops.length;

    return Material(
      color: Colors.transparent,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () => _openFarmDetails(farm),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 680;
                final metricWidth = compact
                    ? (constraints.maxWidth - 10) / 2
                    : (constraints.maxWidth - 30) / 4;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: isMobile ? 58 : 64,
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: isMobile ? 44 : 50,
                          height: isMobile ? 44 : 50,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.16),
                            ),
                          ),
                          child: Icon(
                            Icons.agriculture_rounded,
                            color: AppColors.primary,
                            size: isMobile ? 22 : 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    farm['name']?.toString() ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: isMobile ? 16 : 18,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  _buildFarmStatusPill(
                                      status, statusColor, isDark),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 14,
                                runSpacing: 6,
                                children: [
                                  _buildFarmMeta(
                                    Icons.location_on_outlined,
                                    farm['location']?.toString() ??
                                        'No location',
                                    isDark,
                                  ),
                                  _buildFarmMeta(
                                    Icons.straighten_outlined,
                                    farm['size']?.toString() ?? 'Size pending',
                                    isDark,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 12),
                          _buildFarmDetailsButton(isDark),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: metricWidth,
                          child: _buildFarmRecordMetric(
                            icon: Icons.layers_rounded,
                            label: 'Active Batches',
                            value: '${farm['activeBatches'] ?? 0}',
                            color: AppColors.info,
                            isDark: isDark,
                          ),
                        ),
                        SizedBox(
                          width: metricWidth,
                          child: _buildFarmRecordMetric(
                            icon: Icons.scale_rounded,
                            label: 'Total Harvest',
                            value: farm['totalHarvest']?.toString() ?? '0 kg',
                            color: AppColors.success,
                            isDark: isDark,
                          ),
                        ),
                        SizedBox(
                          width: metricWidth,
                          child: _buildFarmRecordMetric(
                            icon: Icons.sensors_rounded,
                            label: 'Sensors',
                            value: '${farm['sensorCount'] ?? 0}',
                            color: AppColors.warning,
                            isDark: isDark,
                          ),
                        ),
                        SizedBox(
                          width: metricWidth,
                          child: _buildFarmRecordMetric(
                            icon: Icons.groups_rounded,
                            label: 'Assigned Team',
                            value: '${team.length}',
                            color: AppColors.primary,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Operational progress',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white60
                                : AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(progress * 100).round()}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.08)
                            : AppColors.neutral200,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.035)
                            : AppColors.neutral50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : AppColors.neutral200,
                        ),
                      ),
                      child: compact
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFarmCropSummary(
                                  visibleCrops,
                                  hiddenCropCount,
                                  isDark,
                                ),
                                const SizedBox(height: 12),
                                _buildFarmTeamSummary(team, isDark),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildFarmDetailsButton(isDark),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildFarmCropSummary(
                                    visibleCrops,
                                    hiddenCropCount,
                                    isDark,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFarmTeamSummary(team, isDark),
                                ),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFarmMeta(IconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? Colors.white38 : AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFarmStatusPill(String status, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmDetailsButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'View details',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildFarmRecordMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      height: 74,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
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

  Widget _buildFarmCropSummary(
    List<String> crops,
    int hiddenCropCount,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFarmSummaryLabel(Icons.grass_rounded, 'Crop varieties', isDark),
        const SizedBox(height: 10),
        crops.isEmpty
            ? Text(
                'No crop varieties assigned',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : AppColors.textSecondary,
                ),
              )
            : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...crops.map((crop) => _buildFarmCropTag(crop, isDark)),
                  if (hiddenCropCount > 0)
                    _buildFarmCropTag('+$hiddenCropCount more', isDark),
                ],
              ),
      ],
    );
  }

  Widget _buildFarmTeamSummary(List<Map<String, dynamic>> team, bool isDark) {
    final visibleTeam = team.take(4).toList();
    final teamNames = team
        .take(2)
        .map((member) => member['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFarmSummaryLabel(Icons.groups_rounded, 'Assigned team', isDark),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildFarmTeamAvatars(visibleTeam, isDark),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                team.isEmpty
                    ? 'No team assigned'
                    : '$teamNames${team.length > 2 ? ' +${team.length - 2} more' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFarmSummaryLabel(IconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: isDark ? Colors.white38 : AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFarmCropTag(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.07) : AppColors.neutral200,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white70 : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFarmTeamAvatars(List<Map<String, dynamic>> team, bool isDark) {
    if (team.isEmpty) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
          ),
        ),
        child: Icon(
          Icons.person_add_alt_1_rounded,
          size: 18,
          color: isDark ? Colors.white38 : AppColors.textSecondary,
        ),
      );
    }

    return SizedBox(
      width: 34.0 + ((team.length - 1) * 22.0),
      height: 36,
      child: Stack(
        children: [
          for (var i = 0; i < team.length; i++)
            Positioned(
              left: i * 22.0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    team[i]['avatar']?.toString().isNotEmpty == true
                        ? team[i]['avatar'].toString()
                        : _initialsForName(team[i]['name']?.toString() ?? ''),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _initialsForName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'NA';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Widget buildFarmCardLegacy(
      Map<String, dynamic> farm, bool isDark, bool isMobile) {
    final team = (farm['team'] as List<Map<String, dynamic>>?) ?? [];
    final crops = (farm['crops'] as List<String>?) ?? [];
    final progress = (farm['progress'] as double?) ?? 0.0;
    final statusColor =
        farm['status'] == 'Active' ? AppColors.success : AppColors.warning;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openFarmDetails(farm),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Farm Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Farm icon
                  Container(
                    width: isMobile ? 48 : 56,
                    height: isMobile ? 48 : 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: Icon(Icons.agriculture_rounded,
                        color: Colors.white, size: isMobile ? 24 : 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                farm['name'] ?? '',
                                style: GoogleFonts.inter(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: statusColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: statusColor)),
                                  const SizedBox(width: 5),
                                  Text(farm['status'] ?? '',
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (isMobile)
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 14,
                                      color: isDark
                                          ? Colors.white38
                                          : AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    farm['location'] ?? '',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white54
                                            : AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.straighten_outlined,
                                      size: 14,
                                      color: isDark
                                          ? Colors.white38
                                          : AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    farm['size'] ?? '',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white54
                                            : AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 14,
                                  color: isDark
                                      ? Colors.white38
                                      : AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(farm['location'] ?? '',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white54
                                          : AppColors.textSecondary)),
                              const SizedBox(width: 12),
                              Icon(Icons.straighten_outlined,
                                  size: 14,
                                  color: isDark
                                      ? Colors.white38
                                      : AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(farm['size'] ?? '',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white54
                                          : AppColors.textSecondary)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Farm stats row
              if (isMobile)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _farmInfoChip(
                        Icons.layers_rounded,
                        '${farm['activeBatches']} Batches',
                        AppColors.info,
                        isDark),
                    _farmInfoChip(Icons.scale_rounded,
                        farm['totalHarvest'] ?? '', AppColors.success, isDark),
                    _farmInfoChip(
                        Icons.sensors_rounded,
                        '${farm['sensorCount'] ?? 0} Sensors',
                        AppColors.warning,
                        isDark),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                        child: _farmInfoChip(
                            Icons.layers_rounded,
                            '${farm['activeBatches']} Batches',
                            AppColors.info,
                            isDark)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _farmInfoChip(
                            Icons.scale_rounded,
                            farm['totalHarvest'] ?? '',
                            AppColors.success,
                            isDark)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _farmInfoChip(
                            Icons.sensors_rounded,
                            '${farm['sensorCount'] ?? 0} Sensors',
                            AppColors.warning,
                            isDark)),
                  ],
                ),

              const SizedBox(height: 14),

              // Progress bar
              Row(
                children: [
                  Text('Overall Progress',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white38
                              : AppColors.textSecondary)),
                  const Spacer(),
                  Text('${(progress * 100).toInt()}%',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.08)
                      : AppColors.neutral200,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),

              const SizedBox(height: 14),

              // Crops tags
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: crops
                    .map((c) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : AppColors.neutral100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(c,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white60
                                      : AppColors.textSecondary)),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 16),

              // Team section header
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.groups_rounded,
                            size: 16,
                            color: isDark
                                ? Colors.white38
                                : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Team',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white54
                                    : AppColors.textSecondary)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text('${team.length}',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.info)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => _openFarmDetails(farm),
                        child: Text('View All',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Icon(Icons.groups_rounded,
                        size: 16,
                        color:
                            isDark ? Colors.white38 : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Team',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white54
                                : AppColors.textSecondary)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('${team.length}',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.info)),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _openFarmDetails(farm),
                      child: Text('View All',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ),
                  ],
                ),
              const SizedBox(height: 10),

              // Team members preview (first 3)
              ...team
                  .take(3)
                  .map((m) => _buildTeamMemberRow(m, isDark, isMobile)),

              if (team.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      '+${team.length - 3} more members',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _farmInfoChip(IconData icon, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ── Team Member Row ─────────────────────────────────────────────────────

  Widget _buildTeamMemberRow(
      Map<String, dynamic> member, bool isDark, bool isMobile) {
    final memberStatus = member['status'] as String? ?? 'Active';
    final memberColor = memberStatus == 'Active'
        ? AppColors.success
        : memberStatus == 'On Leave'
            ? AppColors.warning
            : AppColors.neutral500;
    final progress = _taskProgress(member);
    final hasTaskData = _hasTaskData(member);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showMemberDetails(member, isDark),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : AppColors.neutral200.withOpacity(0.6)),
            ),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          memberColor.withOpacity(0.7),
                          memberColor
                        ]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          member['avatar'] ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: memberColor,
                          border: Border.all(
                              color:
                                  isDark ? AppColors.surfaceDark : Colors.white,
                              width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member['name'] ?? '',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary),
                      ),
                      Text(
                        member['role'] ?? '',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white54
                                : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Progress
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _taskProgressLabel(member),
                      style: GoogleFonts.inter(
                          fontSize: hasTaskData ? 12 : 10,
                          fontWeight: FontWeight.w700,
                          color: hasTaskData
                              ? _progressColor(progress)
                              : (isDark
                                  ? Colors.white38
                                  : AppColors.textSecondary)),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 50,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.08)
                              : AppColors.neutral200,
                          valueColor: AlwaysStoppedAnimation(
                            hasTaskData
                                ? _progressColor(progress)
                                : (isDark
                                    ? Colors.white24
                                    : AppColors.neutral300),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    size: 18,
                    color: isDark ? Colors.white24 : AppColors.neutral400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _progressColor(double p) {
    if (p >= 0.8) return AppColors.success;
    if (p >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  // ── Farm Details Dialog ─────────────────────────────────────────────────

  bool _hasTaskData(Map<String, dynamic> member) {
    final tasks = member['tasks'] as int? ?? 0;
    return tasks > 0 || member['hasTaskData'] == true;
  }

  double _taskProgress(Map<String, dynamic> member) {
    final tasks = member['tasks'] as int? ?? 0;
    final completed = member['completed'] as int? ?? 0;
    if (tasks <= 0) return 0.0;
    return (completed / tasks).clamp(0.0, 1.0);
  }

  String _taskProgressLabel(Map<String, dynamic> member) {
    if (!_hasTaskData(member)) return 'No task data';
    final progress = _taskProgress(member);
    return '${(progress * 100).round()}%';
  }

  List<Map<String, dynamic>> _batchesForFarm(Map<String, dynamic> farm) =>
      _batches.where((batch) => _matchesFarm(batch, farm)).toList();

  int _batchStatusStep(String status) {
    switch (status.toLowerCase()) {
      case 'planted':
        return 1;
      case 'growing':
        return 2;
      case 'harvested':
        return 3;
      case 'delivered':
        return 4;
      case 'completed':
        return 5;
      default:
        return 0;
    }
  }

  Map<String, dynamic> _productionStatsForFarm(Map<String, dynamic> farm) {
    final batches = _batchesForFarm(farm);
    final total = batches.length;
    final completed = batches
        .where((batch) =>
            (batch['production_status'] ?? '').toString() == 'Completed')
        .length;
    final active = batches
        .where((batch) => !['Completed', 'Delivered']
            .contains((batch['production_status'] ?? '').toString()))
        .length;
    final harvestedHeads = batches.fold<num>(
      0,
      (sum, batch) => sum + _numValue(batch['total_harvested']),
    );
    final transplantedHeads = batches.fold<num>(
      0,
      (sum, batch) => sum + _numValue(batch['total_transplanted']),
    );
    final lossHeads =
        (transplantedHeads - harvestedHeads).clamp(0, double.infinity);
    final lossRate = transplantedHeads <= 0
        ? 0.0
        : lossHeads.toDouble() / transplantedHeads.toDouble();
    final totalWeightKg = batches.fold<num>(
      0,
      (sum, batch) => sum + _numValue(batch['total_weight_kg']),
    );
    final progress = total == 0
        ? 0.0
        : batches.fold<double>(
              0,
              (sum, batch) =>
                  sum +
                  (_batchStatusStep(
                        (batch['production_status'] ?? '').toString(),
                      ) /
                      5),
            ) /
            total;
    return {
      'total': total,
      'active': active,
      'completed': completed,
      'harvestedHeads': harvestedHeads,
      'transplantedHeads': transplantedHeads,
      'lossHeads': lossHeads,
      'lossRate': lossRate.clamp(0.0, 1.0),
      'totalWeightKg': totalWeightKg,
      'progress': progress.clamp(0.0, 1.0),
    };
  }

  List<Map<String, dynamic>> _salesForFarm(Map<String, dynamic> farm) {
    final batchKeys = <String>{};
    for (final batch in _batchesForFarm(farm)) {
      for (final key in [r'$id', 'batch_id', 'batch_no', 'batch_number']) {
        final value = batch[key]?.toString() ?? '';
        if (value.isNotEmpty) batchKeys.add(value);
      }
    }
    return _sales.where((sale) {
      final batchId =
          (sale['batch_id'] ?? sale['batch_number'] ?? '').toString().trim();
      return batchKeys.contains(batchId);
    }).toList();
  }

  _RevenueStats _revenueStatsForFarm(Map<String, dynamic> farm) {
    final sales = _salesForFarm(farm);
    final totalRevenue = sales.fold<double>(
      0,
      (sum, sale) => sum + _numValue(sale['total_amount']).toDouble(),
    );
    final paidRevenue =
        sales.where((sale) => sale['paid'] == true).fold<double>(
              0,
              (sum, sale) => sum + _numValue(sale['total_amount']).toDouble(),
            );
    final delivered = sales
        .where((sale) => (sale['status'] ?? '').toString() == 'Delivered')
        .length;
    final pointsByDate = <DateTime, double>{};
    for (final sale in sales) {
      final rawDate =
          (sale['payment_date'] ?? sale['delivered_at'] ?? '').toString();
      final parsed = DateTime.tryParse(rawDate);
      final date = parsed == null
          ? DateTime.now()
          : DateTime(parsed.year, parsed.month, parsed.day);
      pointsByDate[date] = (pointsByDate[date] ?? 0) +
          _numValue(sale['total_amount']).toDouble();
    }
    final points = pointsByDate.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final chartPoints = points
        .map((entry) => _RevenuePoint(entry.key, entry.value))
        .take(12)
        .toList();
    final paidRatio = totalRevenue <= 0 ? 0.0 : paidRevenue / totalRevenue;
    return _RevenueStats(
      totalRevenue: totalRevenue,
      paidRevenue: paidRevenue,
      deliveredSales: delivered,
      totalSales: sales.length,
      paidRatio: paidRatio.clamp(0.0, 1.0),
      points: chartPoints,
    );
  }

  Widget _buildFarmDetailsPage(Map<String, dynamic> farm, bool isDark) {
    final statusColor =
        farm['status'] == 'Active' ? AppColors.success : AppColors.warning;
    final stats = _productionStatsForFarm(farm);
    final revenueStats = _revenueStatsForFarm(farm);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: _closeFarmDetails,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back to farms'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFarmDetailsHero(farm, statusColor, isDark),
            const SizedBox(height: AppSpacing.lg),
            _buildFarmDetailsMetrics(farm, stats, isDark),
            const SizedBox(height: AppSpacing.lg),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildProductionProfilePanel(farm, isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildDetailsTeamPanel(farm, isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildDetailsRevenuePanel(revenueStats, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 4,
                    child: _buildDetailsYieldPanel(farm, stats, isDark),
                  ),
                ],
              )
            else ...[
              _buildProductionProfilePanel(farm, isDark),
              const SizedBox(height: AppSpacing.lg),
              _buildDetailsTeamPanel(farm, isDark),
              const SizedBox(height: AppSpacing.lg),
              _buildDetailsRevenuePanel(revenueStats, isDark),
              const SizedBox(height: AppSpacing.lg),
              _buildDetailsYieldPanel(farm, stats, isDark),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFarmDetailsHero(
    Map<String, dynamic> farm,
    Color statusColor,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.10)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;
          final title = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Icon(Icons.agriculture_rounded,
                    color: statusColor, size: 34),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _buildFarmBadge(farm['status']?.toString() ?? 'Active',
                            statusColor),
                        _buildFarmBadge(farm['type']?.toString() ?? 'Farm',
                            AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      farm['name']?.toString() ?? 'Farm',
                      style: AppTypography.h4.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      farm['location']?.toString() ?? 'Location not set',
                      style: AppTypography.bodyMedium.copyWith(
                        color:
                            isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final apiKeyButton = OutlinedButton.icon(
            onPressed: () {
              final apiKey = farm['sensorApiKey']?.toString() ?? '';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(apiKey.isEmpty
                      ? 'No farm sensor API key configured.'
                      : 'Farm sensor API key available from farm setup.'),
                ),
              );
            },
            icon: const Icon(Icons.vpn_key_rounded, size: 18),
            label: const Text('API Key'),
          );
          final actions = Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.end,
            children: [apiKeyButton],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: AppSpacing.md),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: title),
              const SizedBox(width: AppSpacing.md),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildFarmBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFarmDetailsMetrics(
    Map<String, dynamic> farm,
    Map<String, dynamic> stats,
    bool isDark,
  ) {
    final metrics = [
      (
        'Batches Done',
        '${stats['completed']}/${stats['total']}',
        Icons.task_alt_rounded,
        AppColors.success
      ),
      (
        'Yield Weight',
        '${(stats['totalWeightKg'] as num).toStringAsFixed(1)} kg',
        Icons.scale_rounded,
        AppColors.warning
      ),
      (
        'Active Batches',
        '${stats['active']}',
        Icons.loop_rounded,
        AppColors.info
      ),
      (
        'Sensors',
        '${farm['sensorCount'] ?? 0}',
        Icons.sensors_rounded,
        AppColors.primary
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 680 ? 2 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            mainAxisExtent: 112,
          ),
          itemBuilder: (_, index) {
            final metric = metrics[index];
            return _buildDetailMetricCard(
              label: metric.$1,
              value: metric.$2,
              icon: metric.$3,
              color: metric.$4,
              isDark: isDark,
            );
          },
        );
      },
    );
  }

  Widget _buildDetailMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.14 : 0.09),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.h6
                      .copyWith(color: color, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
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

  Widget _buildDetailsSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.10)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.h6.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }

  Widget _buildProductionProfilePanel(Map<String, dynamic> farm, bool isDark) {
    return _buildDetailsSection(
      title: 'Production Profile',
      subtitle: 'Crop, variety, farm status, and sensor setup',
      icon: Icons.eco_rounded,
      color: AppColors.success,
      isDark: isDark,
      child: Column(
        children: [
          _buildDetailTile('Plant Type', farm['type']?.toString() ?? 'Farm',
              Icons.eco_outlined, isDark),
          _buildDetailTile(
              'Crop Varieties',
              ((farm['crops'] as List?) ?? []).join(', '),
              Icons.grass_outlined,
              isDark),
          _buildDetailTile('Farm ID', farm['id']?.toString() ?? '',
              Icons.tag_outlined, isDark),
          _buildDetailTile(
              'Sensor API Key',
              (farm['sensorApiKey']?.toString().isEmpty ?? true)
                  ? 'Not configured'
                  : 'Configured',
              Icons.vpn_key_outlined,
              isDark),
        ],
      ),
    );
  }

  Widget _buildDetailTile(
      String label, String value, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.035) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: isDark ? Colors.white54 : AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              textAlign: TextAlign.end,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTeamPanel(Map<String, dynamic> farm, bool isDark) {
    final team = (farm['team'] as List<Map<String, dynamic>>?) ?? [];
    return _buildDetailsSection(
      title: 'Assigned Team',
      subtitle: 'Operational team assigned to this farm',
      icon: Icons.groups_rounded,
      color: AppColors.primary,
      isDark: isDark,
      child: team.isEmpty
          ? Text(
              'No assigned team members yet.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            )
          : Column(
              children: team
                  .map((member) => _buildCompactTeamTile(member, isDark))
                  .toList(),
            ),
    );
  }

  Widget _buildCompactTeamTile(Map<String, dynamic> member, bool isDark) {
    final status = member['status']?.toString() ?? 'Active';
    final color = status == 'Active' ? AppColors.success : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.035) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.12),
            child: Text(
              member['avatar']?.toString() ?? '',
              style: AppTypography.caption
                  .copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name']?.toString() ?? '',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  member['role']?.toString() ?? '',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildFarmBadge(status, color),
        ],
      ),
    );
  }

  Widget _buildDetailsYieldPanel(
    Map<String, dynamic> farm,
    Map<String, dynamic> stats,
    bool isDark,
  ) {
    final total = stats['total'] as int;
    final active = stats['active'] as int;
    final completed = stats['completed'] as int;
    final harvestedHeads = stats['harvestedHeads'] as num;
    final lossHeads = stats['lossHeads'] as num;
    final lossRate = stats['lossRate'] as double;
    final totalWeightKg = stats['totalWeightKg'] as num;
    final progress = stats['progress'] as double;
    final farmTasks = _tasksForFarm(farm);
    final pendingTasks = farmTasks
        .where((task) =>
            _value(task, ['status']).toLowerCase().trim() != 'completed')
        .length;
    final items = [
      ('Total Batches', '$total', Icons.all_inbox_rounded, AppColors.primary),
      ('Active Batches', '$active', Icons.loop_rounded, AppColors.info),
      ('Completed', '$completed', Icons.task_alt_rounded, AppColors.success),
      (
        'Harvested Heads',
        harvestedHeads.toStringAsFixed(0),
        Icons.grass_rounded,
        AppColors.success
      ),
      (
        'Yield Weight',
        '${totalWeightKg.toStringAsFixed(1)} kg',
        Icons.scale_rounded,
        AppColors.warning
      ),
      (
        'Loss Heads',
        lossHeads.toStringAsFixed(0),
        Icons.trending_down_rounded,
        AppColors.error
      ),
      (
        'Loss Rate',
        '${(lossRate * 100).toStringAsFixed(1)}%',
        Icons.report_problem_rounded,
        AppColors.error
      ),
    ];
    return _buildDetailsSection(
      title: 'Yield & Batch Progress',
      subtitle: 'Production progress from backend batch records',
      icon: Icons.insights_rounded,
      color: AppColors.warning,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Overall batch progress',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: AppTypography.h6.copyWith(
                    color: AppColors.warning, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: isDark ? Colors.white12 : AppColors.neutral200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.warning),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 420;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: twoColumns ? 2 : 1,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  mainAxisExtent: 128,
                ),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return _buildDetailMetricCard(
                    label: item.$1,
                    value: item.$2,
                    icon: item.$3,
                    color: item.$4,
                    isDark: isDark,
                  );
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildFarmTasksBlock(
            farm: farm,
            tasks: farmTasks,
            pendingTasks: pendingTasks,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFarmTasksBlock({
    required Map<String, dynamic> farm,
    required List<Map<String, dynamic>> tasks,
    required int pendingTasks,
    required bool isDark,
  }) {
    final completedTasks = tasks.length - pendingTasks;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.035) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(Icons.assignment_turned_in_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Farm Tasks',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$pendingTasks pending • $completedTasks completed',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAssignTaskDialog(farm, isDark),
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: const Text('Assign Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (tasks.isEmpty)
            Text(
              'No tasks assigned to this farm yet.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            )
          else
            ...tasks
                .take(4)
                .map((task) => _buildFarmTaskTile(task, isDark))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildFarmTaskTile(Map<String, dynamic> task, bool isDark) {
    const taskStatuses = [
      'Not Started',
      'Started',
      'Pending',
      'In Progress',
      'Completed',
      'Cancelled',
    ];
    final taskId = _taskDocId(task);
    final status = _value(task, ['status'], fallback: 'Pending');
    final priority = _value(task, ['priority'], fallback: 'Medium');
    final statusColor = _taskStatusColor(status);
    final priorityColor = priority == 'High'
        ? AppColors.error
        : priority == 'Low'
            ? AppColors.info
            : AppColors.warning;
    final isUpdating = _updatingTaskIds.contains(taskId);
    final isDeleting = _deletingTaskIds.contains(taskId);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showFarmTaskDetailsDialog(task, isDark),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.035) : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              Icon(Icons.task_alt_rounded, color: statusColor, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _value(task, ['title'], fallback: 'Untitled task'),
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Assigned to ${_value(task, [
                            'assigned_to_name'
                          ], fallback: 'Team member')}',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_value(task, ['description']).isNotEmpty ||
                        _value(task, ['manager_comment']).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.notes_rounded,
                            size: 13,
                            color: isDark
                                ? Colors.white38
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _value(task, ['manager_comment']).isNotEmpty
                                ? 'Manager comment added'
                                : 'Task note available',
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildFarmBadge(priority, priorityColor),
              const SizedBox(width: AppSpacing.xs),
              PopupMenuButton<String>(
                enabled: taskId.isNotEmpty && !isUpdating && !isDeleting,
                tooltip: 'Change task status',
                onSelected: (value) => _updateFarmTaskStatus(task, value),
                itemBuilder: (context) => taskStatuses
                    .map(
                      (value) => PopupMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Icon(
                              value == status
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 16,
                              color: _taskStatusColor(value),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(value),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                child: isUpdating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _buildTaskStatusDropdownBadge(status, statusColor),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                tooltip: 'Delete task',
                onPressed: taskId.isEmpty || isUpdating || isDeleting
                    ? null
                    : () => _confirmDeleteFarmTask(task, isDark),
                icon: isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
                color: AppColors.error,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _taskStatusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'completed':
        return AppColors.success;
      case 'in progress':
      case 'started':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      case 'not started':
        return AppColors.neutral500;
      case 'pending':
      default:
        return AppColors.warning;
    }
  }

  Widget _buildTaskStatusDropdownBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: color),
        ],
      ),
    );
  }

  Future<void> _updateFarmTaskStatus(
      Map<String, dynamic> task, String status) async {
    final taskId = _taskDocId(task);
    if (taskId.isEmpty) return;
    final currentStatus = _value(task, ['status'], fallback: 'Pending');
    if (currentStatus == status) return;

    setState(() => _updatingTaskIds.add(taskId));
    try {
      await _api.updateFarmTask(
        id: taskId,
        data: _farmTaskPayload(task, status: status),
      );
      await _loadFarms();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task marked as $status')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingTaskIds.remove(taskId));
      }
    }
  }

  Map<String, dynamic> _farmTaskPayload(
    Map<String, dynamic> task, {
    required String status,
    String? managerComment,
  }) {
    return {
      'farm_id': _value(task, ['farm_id']),
      'farm_name': _value(task, ['farm_name']),
      'title': _value(task, ['title'], fallback: 'Untitled task'),
      'description': _value(task, ['description']),
      'manager_comment': managerComment ?? _value(task, ['manager_comment']),
      'assigned_to_id': _value(task, ['assigned_to_id']),
      'assigned_to_name':
          _value(task, ['assigned_to_name'], fallback: 'Team member'),
      'assigned_by_id': _value(task, ['assigned_by_id']),
      'assigned_by_name':
          _value(task, ['assigned_by_name'], fallback: 'Farm Manager'),
      'priority': _value(task, ['priority'], fallback: 'Medium'),
      'status': status,
      if (_value(task, ['due_date']).isNotEmpty)
        'due_date': _value(task, ['due_date']),
    };
  }

  void _showFarmTaskDetailsDialog(Map<String, dynamic> task, bool isDark) {
    final commentController = TextEditingController(
      text: _value(task, ['manager_comment']),
    );
    final status = _value(task, ['status'], fallback: 'Pending');
    final statusColor = _taskStatusColor(status);
    final priority = _value(task, ['priority'], fallback: 'Medium');
    final priorityColor = priority == 'High'
        ? AppColors.error
        : priority == 'Low'
            ? AppColors.info
            : AppColors.warning;
    String? modalError;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final notes = _value(task, ['description']);
          final dueDate = _formatTaskDate(
            _value(task, ['due_date']),
            fallback: 'No due date',
          );
          final createdAt = _formatTaskDateTime(
            _value(task, ['created_at', r'$createdAt']),
          );
          final updatedAt = _formatTaskDateTime(
            _value(task, ['updated_at', r'$updatedAt']),
          );
          final assignedBy =
              _value(task, ['assigned_by_name'], fallback: 'Farm Manager');

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.035)
                            : AppColors.neutral50,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppSpacing.radiusXl),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : AppColors.neutral200,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusLg),
                              border: Border.all(
                                  color: statusColor.withOpacity(0.2)),
                            ),
                            child: Icon(Icons.assignment_turned_in_rounded,
                                color: statusColor, size: 26),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Task Review',
                                  style: AppTypography.caption.copyWith(
                                    color: isDark
                                        ? Colors.white54
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _value(task, ['title'],
                                      fallback: 'Untitled task'),
                                  style: AppTypography.h4.copyWith(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.xs,
                                  runSpacing: AppSpacing.xs,
                                  children: [
                                    _buildFarmBadge(status, statusColor),
                                    _buildFarmBadge(priority, priorityColor),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: isSaving
                                ? null
                                : () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 520;
                                final tiles = [
                                  _buildTaskDetailInfoTile(
                                    'Assigned To',
                                    _value(task, ['assigned_to_name'],
                                        fallback: 'Team member'),
                                    Icons.person_outline_rounded,
                                    isDark,
                                  ),
                                  _buildTaskDetailInfoTile(
                                    'Assigned By',
                                    assignedBy,
                                    Icons.supervisor_account_rounded,
                                    isDark,
                                  ),
                                  _buildTaskDetailInfoTile(
                                    'Due Date',
                                    dueDate,
                                    Icons.event_available_rounded,
                                    isDark,
                                  ),
                                  _buildTaskDetailInfoTile(
                                    'Task ID',
                                    _value(task, ['task_id'],
                                        fallback: _taskDocId(task)),
                                    Icons.tag_rounded,
                                    isDark,
                                  ),
                                  _buildTaskDetailInfoTile(
                                    'Created',
                                    createdAt,
                                    Icons.schedule_rounded,
                                    isDark,
                                  ),
                                  _buildTaskDetailInfoTile(
                                    'Last Updated',
                                    updatedAt,
                                    Icons.update_rounded,
                                    isDark,
                                  ),
                                ];
                                if (compact) {
                                  return Column(
                                    children: tiles
                                        .map(
                                          (tile) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: AppSpacing.sm),
                                            child: tile,
                                          ),
                                        )
                                        .toList(),
                                  );
                                }
                                return Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: tiles
                                      .map(
                                        (tile) => SizedBox(
                                          width: (constraints.maxWidth -
                                                  AppSpacing.sm) /
                                              2,
                                          child: tile,
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _buildTaskModalSection(
                              title: 'Task Instructions',
                              subtitle:
                                  'Original note provided when this task was assigned.',
                              icon: Icons.notes_rounded,
                              isDark: isDark,
                              child: Text(
                                notes.isEmpty
                                    ? 'No task instructions were added.'
                                    : notes,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: notes.isEmpty
                                      ? (isDark
                                          ? Colors.white38
                                          : AppColors.textSecondary)
                                      : (isDark
                                          ? Colors.white70
                                          : AppColors.textPrimary),
                                  height: 1.45,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildTaskModalSection(
                              title: 'Manager Response',
                              subtitle:
                                  'Add feedback, clarification, or completion notes for this task.',
                              icon: Icons.reply_rounded,
                              isDark: isDark,
                              child: TextField(
                                controller: commentController,
                                maxLines: 5,
                                minLines: 4,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  height: 1.4,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Write the manager response here...',
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.white.withOpacity(0.04)
                                      : Colors.white,
                                  contentPadding:
                                      const EdgeInsets.all(AppSpacing.md),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? Colors.white12
                                          : AppColors.neutral300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? Colors.white12
                                          : AppColors.neutral300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd),
                                    borderSide: const BorderSide(
                                        color: AppColors.primary),
                                  ),
                                ),
                              ),
                            ),
                            if (modalError != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                modalError!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.of(dialogContext).pop(),
                              child: const Text('Close'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      setDialogState(() {
                                        modalError = null;
                                        isSaving = true;
                                      });
                                      try {
                                        await _api.updateFarmTask(
                                          id: _taskDocId(task),
                                          data: _farmTaskPayload(
                                            task,
                                            status: status,
                                            managerComment:
                                                commentController.text.trim(),
                                          ),
                                        );
                                        if (!dialogContext.mounted) return;
                                        Navigator.of(dialogContext).pop();
                                        await _loadFarms();
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(this.context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Task comment saved'),
                                          ),
                                        );
                                      } catch (error) {
                                        setDialogState(() {
                                          modalError = error.toString();
                                          isSaving = false;
                                        });
                                      }
                                    },
                              icon: isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.reply_rounded, size: 18),
                              label:
                                  Text(isSaving ? 'Saving...' : 'Save Reply'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
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
          );
        },
      ),
    ).whenComplete(commentController.dispose);
  }

  Widget _buildTaskModalSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.035) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
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

  Widget _buildTaskDetailInfoTile(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: isDark ? Colors.white54 : AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
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

  Future<void> _confirmDeleteFarmTask(
      Map<String, dynamic> task, bool isDark) async {
    final taskId = _taskDocId(task);
    if (taskId.isEmpty) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(
          'Delete Task',
          style: AppTypography.h4.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Delete "${_value(task, [
                'title'
              ], fallback: 'this task')}"? This cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    setState(() => _deletingTaskIds.add(taskId));
    try {
      await _api.deleteFarmTask(taskId);
      await _loadFarms();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted successfully')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete task: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingTaskIds.remove(taskId));
      }
    }
  }

  void _showAssignTaskDialog(Map<String, dynamic> farm, bool isDark) {
    final team = (farm['team'] as List<Map<String, dynamic>>? ?? [])
        .where((member) => member['name'] != 'Unassigned')
        .toList();
    if (team.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Assign team members to this farm before creating tasks.'),
        ),
      );
      return;
    }

    final authUser = ref.read(authProvider).user;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedMemberId = team.first['id']?.toString() ?? '';
    String selectedPriority = 'Medium';
    DateTime? dueDate;
    String? modalError;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final selectedMember = team.firstWhere(
            (member) => member['id']?.toString() == selectedMemberId,
            orElse: () => team.first,
          );
          final dueDateLabel = dueDate == null
              ? 'Select date'
              : '${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}';
          final fieldStyle = AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          );
          final inputDecoration = InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : AppColors.neutral300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : AppColors.neutral300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            labelStyle: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
            hintStyle: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white38 : AppColors.textSecondary,
            ),
          );

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 540,
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.78),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusXl),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: const Icon(Icons.add_task_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assign Farm Task',
                                style: AppTypography.h6.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                farm['name']?.toString() ?? 'Selected farm',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.76),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: isSaving
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      width: double.infinity,
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: titleController,
                              style: fieldStyle,
                              decoration: inputDecoration.copyWith(
                                labelText: 'Task title',
                                hintText: 'e.g. Inspect irrigation line',
                                prefixIcon: const Icon(Icons.task_alt_rounded),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            DropdownButtonFormField<String>(
                              initialValue: selectedMemberId,
                              decoration: inputDecoration.copyWith(
                                labelText: 'Assign to',
                                prefixIcon:
                                    const Icon(Icons.person_outline_rounded),
                              ),
                              dropdownColor:
                                  isDark ? AppColors.surfaceDark : Colors.white,
                              style: fieldStyle,
                              items: team
                                  .map((member) => DropdownMenuItem<String>(
                                        value: member['id']?.toString() ?? '',
                                        child: Text(
                                          "${member['name']} - ${member['role']}",
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: isSaving
                                  ? null
                                  : (value) => setDialogState(
                                      () => selectedMemberId = value!),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: selectedPriority,
                                    decoration: inputDecoration.copyWith(
                                      labelText: 'Priority',
                                      prefixIcon: const Icon(
                                          Icons.flag_circle_outlined),
                                    ),
                                    dropdownColor: isDark
                                        ? AppColors.surfaceDark
                                        : Colors.white,
                                    style: fieldStyle,
                                    items: ['High', 'Medium', 'Low']
                                        .map((priority) =>
                                            DropdownMenuItem<String>(
                                              value: priority,
                                              child: Text(priority),
                                            ))
                                        .toList(),
                                    onChanged: isSaving
                                        ? null
                                        : (value) => setDialogState(
                                            () => selectedPriority = value!),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd),
                                    onTap: isSaving
                                        ? null
                                        : () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              firstDate: DateTime.now(),
                                              lastDate: DateTime.now().add(
                                                const Duration(days: 365),
                                              ),
                                              initialDate:
                                                  dueDate ?? DateTime.now(),
                                            );
                                            if (picked != null) {
                                              setDialogState(
                                                  () => dueDate = picked);
                                            }
                                          },
                                    child: InputDecorator(
                                      decoration: inputDecoration.copyWith(
                                        labelText: 'Due date',
                                        prefixIcon:
                                            const Icon(Icons.event_rounded),
                                      ),
                                      child: Text(
                                        dueDateLabel,
                                        style: fieldStyle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextField(
                              controller: descriptionController,
                              style: fieldStyle,
                              minLines: 3,
                              maxLines: 5,
                              decoration: inputDecoration.copyWith(
                                labelText: 'Notes',
                                hintText: 'Optional task instructions',
                                alignLabelWithHint: true,
                              ),
                            ),
                            if (modalError != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd),
                                  border: Border.all(
                                    color: AppColors.error.withOpacity(0.18),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.error_outline_rounded,
                                        size: 18, color: AppColors.error),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        modalError!,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppSpacing.radiusXl),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.white10 : AppColors.neutral200,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final title = titleController.text.trim();
                                    if (title.isEmpty) {
                                      setDialogState(() => modalError =
                                          'Task title is required.');
                                      return;
                                    }
                                    setDialogState(() {
                                      modalError = null;
                                      isSaving = true;
                                    });
                                    try {
                                      await _api.createFarmTask(data: {
                                        'farm_id': farm['id'] ?? '',
                                        'farm_name': farm['name'] ?? '',
                                        'title': title,
                                        'description':
                                            descriptionController.text.trim(),
                                        'assigned_to_id': selectedMemberId,
                                        'assigned_to_name':
                                            selectedMember['name'] ?? '',
                                        'assigned_by_id': authUser?.id ?? '',
                                        'assigned_by_name':
                                            authUser?.name ?? 'Farm Manager',
                                        'priority': selectedPriority,
                                        if (dueDate != null)
                                          'due_date':
                                              dueDate!.toIso8601String(),
                                      });
                                      if (!dialogContext.mounted) return;
                                      Navigator.of(dialogContext).pop();
                                      await _loadFarms();
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(this.context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Task assigned successfully'),
                                        ),
                                      );
                                    } catch (error) {
                                      setDialogState(() {
                                        modalError = error.toString();
                                        isSaving = false;
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                            ),
                            icon: isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.add_task_rounded, size: 18),
                            label:
                                Text(isSaving ? 'Assigning...' : 'Assign Task'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsRevenuePanel(_RevenueStats stats, bool isDark) {
    return _buildDetailsSection(
      title: 'Revenue Performance',
      subtitle: 'Sales revenue and payment progress from backend records',
      icon: Icons.trending_up_rounded,
      color: AppColors.primary,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildRevenueMetricTile(
                    'Total Revenue',
                    'GHS ${stats.totalRevenue.toStringAsFixed(2)}',
                    Icons.payments_rounded,
                    AppColors.primary,
                    isDark),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildRevenueMetricTile(
                    'Paid Revenue',
                    'GHS ${stats.paidRevenue.toStringAsFixed(2)}',
                    Icons.verified_rounded,
                    AppColors.success,
                    isDark),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Payment progress',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(stats.paidRatio * 100).round()}%',
                style: AppTypography.h6.copyWith(
                    color: AppColors.success, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: stats.paidRatio,
              minHeight: 10,
              backgroundColor: isDark ? Colors.white12 : AppColors.neutral200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 220,
            child: _FarmRevenueAreaChart(points: stats.points, isDark: isDark),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${stats.deliveredSales}/${stats.totalSales} sales delivered',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueMetricTile(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
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

  void _showMemberDetails(Map<String, dynamic> member, bool isDark) {
    final memberStatus = member['status'] as String? ?? 'Active';
    final memberColor = memberStatus == 'Active'
        ? AppColors.success
        : memberStatus == 'On Leave'
            ? AppColors.warning
            : AppColors.neutral500;
    final progress = _taskProgress(member);
    final hasTaskData = _hasTaskData(member);
    final tasks = member['tasks'] as int? ?? 0;
    final completed = member['completed'] as int? ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [memberColor.withOpacity(0.8), memberColor]),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                          child: Text(member['avatar'] ?? '',
                              style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member['name'] ?? '',
                              style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(member['role'] ?? '',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white70, size: 22),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Row(
                      children: [
                        Text('Status',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white38
                                    : AppColors.textSecondary)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                              color: memberColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: memberColor.withOpacity(0.3))),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: memberColor)),
                              const SizedBox(width: 6),
                              Text(memberStatus,
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: memberColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Detail rows
                    _memberDetailRow(Icons.work_outline_rounded, 'Specialty',
                        member['specialty'] ?? '', isDark),
                    _memberDetailRow(Icons.calendar_month_rounded, 'Joined',
                        member['joinedDate'] ?? '', isDark),
                    _memberDetailRow(Icons.phone_outlined, 'Phone',
                        member['phone'] ?? '', isDark),
                    _memberDetailRow(Icons.email_outlined, 'Email',
                        member['email'] ?? '', isDark),

                    const SizedBox(height: 16),

                    // Task progress
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.03)
                            : AppColors.neutral50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : AppColors.neutral200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text('Task Progress',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white70
                                          : AppColors.textPrimary)),
                              const Spacer(),
                              Text(
                                  hasTaskData
                                      ? '$completed/$tasks'
                                      : 'Not configured',
                                  style: GoogleFonts.inter(
                                      fontSize: hasTaskData ? 13 : 11,
                                      fontWeight: FontWeight.w700,
                                      color: hasTaskData
                                          ? _progressColor(progress)
                                          : (isDark
                                              ? Colors.white38
                                              : AppColors.textSecondary))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : AppColors.neutral200,
                              valueColor: AlwaysStoppedAnimation(
                                hasTaskData
                                    ? _progressColor(progress)
                                    : (isDark
                                        ? Colors.white24
                                        : AppColors.neutral300),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Completion',
                                  style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: isDark
                                          ? Colors.white38
                                          : AppColors.textSecondary)),
                              Text(_taskProgressLabel(member),
                                  style: GoogleFonts.inter(
                                      fontSize: hasTaskData ? 12 : 10,
                                      fontWeight: FontWeight.w800,
                                      color: hasTaskData
                                          ? _progressColor(progress)
                                          : (isDark
                                              ? Colors.white38
                                              : AppColors.textSecondary))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Close'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              isDark ? Colors.white70 : AppColors.textSecondary,
                          side: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.12)
                                  : AppColors.neutral300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Contacting ${member['name']}...'),
                              backgroundColor: AppColors.primary));
                        },
                        icon: const Icon(Icons.message_rounded, size: 16),
                        label: const Text('Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
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
    );
  }

  Widget _memberDetailRow(
      IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : AppColors.neutral100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                size: 15,
                color: isDark ? Colors.white54 : AppColors.textSecondary),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark ? Colors.white38 : AppColors.textSecondary)),
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation ───────────────────────────────────────────────────

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
              offset: const Offset(0, -2))
        ],
        border: Border(
            top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08),
                width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final isSelected = index == 1; // Farms is selected

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (!isSelected) {
                        try {
                          Navigator.pushReplacementNamed(context, route);
                        } catch (e) {
                          Navigator.pushNamed(context, route);
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

class _RevenueStats {
  const _RevenueStats({
    required this.totalRevenue,
    required this.paidRevenue,
    required this.deliveredSales,
    required this.totalSales,
    required this.paidRatio,
    required this.points,
  });

  final double totalRevenue;
  final double paidRevenue;
  final int deliveredSales;
  final int totalSales;
  final double paidRatio;
  final List<_RevenuePoint> points;
}

class _RevenuePoint {
  const _RevenuePoint(this.date, this.value);

  final DateTime date;
  final double value;
}

class _FarmRevenueAreaChart extends StatelessWidget {
  const _FarmRevenueAreaChart({
    required this.points,
    required this.isDark,
  });

  final List<_RevenuePoint> points;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.035) : AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Text(
          'No revenue data yet',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white60 : AppColors.textSecondary,
          ),
        ),
      );
    }

    final maxValue =
        points.map((point) => point.value).reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue * 1.2;
    final spots = points
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
        .toList();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: safeMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark ? Colors.white10 : AppColors.neutral200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval:
                  points.length <= 1 ? 1 : (points.length / 3).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                final date = points[index].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? AppColors.surfaceDark : Colors.white,
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              return LineTooltipItem(
                'GHS ${spot.y.toStringAsFixed(1)}',
                AppTypography.caption.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: points.length <= 8),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withOpacity(0.22),
                  AppColors.primary.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
