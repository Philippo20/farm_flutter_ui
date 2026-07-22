import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // ── Mock Farms Data ─────────────────────────────────────────────────────

  final List<Map<String, dynamic>> _farms = [
    {
      'id': 'FARM-001',
      'name': 'Green Valley Farm',
      'location': 'Accra, Greater Accra',
      'size': '25 acres',
      'type': 'Vegetable Farm',
      'status': 'Active',
      'crops': ['Lettuce', 'Spinach', 'Tomatoes', 'Peppers'],
      'activeBatches': 8,
      'totalHarvest': '2,450 kg',
      'revenue': 'GH₵ 45,200',
      'progress': 0.78,
      'image': 'green_valley',
      'team': [
        {
          'name': 'Kwame Asante',
          'role': 'Lead Caretaker',
          'avatar': 'KA',
          'status': 'Active',
          'progress': 0.92,
          'tasks': 12,
          'completed': 11,
          'phone': '+233 24 567 8901',
          'email': 'kwame@farmestates.com',
          'joinedDate': 'Jan 2024',
          'specialty': 'Crop Management'
        },
        {
          'name': 'Ama Mensah',
          'role': 'Irrigation Specialist',
          'avatar': 'AM',
          'status': 'Active',
          'progress': 0.85,
          'tasks': 8,
          'completed': 7,
          'phone': '+233 20 345 6789',
          'email': 'ama@farmestates.com',
          'joinedDate': 'Mar 2024',
          'specialty': 'Water Systems'
        },
        {
          'name': 'Kofi Boateng',
          'role': 'Technician',
          'avatar': 'KB',
          'status': 'Active',
          'progress': 0.70,
          'tasks': 10,
          'completed': 7,
          'phone': '+233 27 890 1234',
          'email': 'kofi@farmestates.com',
          'joinedDate': 'Feb 2024',
          'specialty': 'Equipment Maintenance'
        },
        {
          'name': 'Efua Darko',
          'role': 'Harvester',
          'avatar': 'ED',
          'status': 'On Leave',
          'progress': 0.60,
          'tasks': 6,
          'completed': 4,
          'phone': '+233 55 123 4567',
          'email': 'efua@farmestates.com',
          'joinedDate': 'May 2024',
          'specialty': 'Harvest Operations'
        },
      ],
    },
    {
      'id': 'FARM-002',
      'name': 'Sunrise Acres',
      'location': 'Kumasi, Ashanti Region',
      'size': '40 acres',
      'type': 'Mixed Farming',
      'status': 'Active',
      'crops': ['Maize', 'Cassava', 'Yam', 'Plantain'],
      'activeBatches': 12,
      'totalHarvest': '5,800 kg',
      'revenue': 'GH₵ 78,500',
      'progress': 0.65,
      'image': 'sunrise_acres',
      'team': [
        {
          'name': 'Yaw Owusu',
          'role': 'Lead Caretaker',
          'avatar': 'YO',
          'status': 'Active',
          'progress': 0.88,
          'tasks': 15,
          'completed': 13,
          'phone': '+233 24 111 2222',
          'email': 'yaw@farmestates.com',
          'joinedDate': 'Dec 2023',
          'specialty': 'Soil Management'
        },
        {
          'name': 'Abena Frimpong',
          'role': 'Pest Control Specialist',
          'avatar': 'AF',
          'status': 'Active',
          'progress': 0.75,
          'tasks': 9,
          'completed': 7,
          'phone': '+233 20 333 4444',
          'email': 'abena@farmestates.com',
          'joinedDate': 'Apr 2024',
          'specialty': 'Pest Management'
        },
        {
          'name': 'Nana Agyei',
          'role': 'Field Supervisor',
          'avatar': 'NA',
          'status': 'Active',
          'progress': 0.82,
          'tasks': 11,
          'completed': 9,
          'phone': '+233 55 555 6666',
          'email': 'nana@farmestates.com',
          'joinedDate': 'Jan 2024',
          'specialty': 'Field Operations'
        },
        {
          'name': 'Akua Sarpong',
          'role': 'Technician',
          'avatar': 'AS',
          'status': 'Active',
          'progress': 0.68,
          'tasks': 7,
          'completed': 5,
          'phone': '+233 27 777 8888',
          'email': 'akua@farmestates.com',
          'joinedDate': 'Jun 2024',
          'specialty': 'Equipment Repair'
        },
        {
          'name': 'Kwesi Appiah',
          'role': 'Harvester',
          'avatar': 'KAP',
          'status': 'Active',
          'progress': 0.90,
          'tasks': 14,
          'completed': 13,
          'phone': '+233 24 999 0000',
          'email': 'kwesi@farmestates.com',
          'joinedDate': 'Feb 2024',
          'specialty': 'Harvest & Packaging'
        },
      ],
    },
    {
      'id': 'FARM-003',
      'name': 'Golden Harvest Farm',
      'location': 'Tamale, Northern Region',
      'size': '60 acres',
      'type': 'Grain Farm',
      'status': 'Seasonal',
      'crops': ['Rice', 'Millet', 'Sorghum'],
      'activeBatches': 5,
      'totalHarvest': '8,200 kg',
      'revenue': 'GH₵ 52,000',
      'progress': 0.45,
      'image': 'golden_harvest',
      'team': [
        {
          'name': 'Ibrahim Mahama',
          'role': 'Lead Caretaker',
          'avatar': 'IM',
          'status': 'Active',
          'progress': 0.80,
          'tasks': 10,
          'completed': 8,
          'phone': '+233 20 222 3333',
          'email': 'ibrahim@farmestates.com',
          'joinedDate': 'Mar 2024',
          'specialty': 'Rice Cultivation'
        },
        {
          'name': 'Fatima Alhassan',
          'role': 'Irrigation Specialist',
          'avatar': 'FA',
          'status': 'Active',
          'progress': 0.72,
          'tasks': 8,
          'completed': 6,
          'phone': '+233 24 444 5555',
          'email': 'fatima@farmestates.com',
          'joinedDate': 'Apr 2024',
          'specialty': 'Canal Systems'
        },
        {
          'name': 'Salifu Bamba',
          'role': 'Harvester',
          'avatar': 'SB',
          'status': 'Inactive',
          'progress': 0.30,
          'tasks': 4,
          'completed': 1,
          'phone': '+233 27 666 7777',
          'email': 'salifu@farmestates.com',
          'joinedDate': 'May 2024',
          'specialty': 'Grain Processing'
        },
      ],
    },
  ];
  final List<Map<String, dynamic>> _users = [];
  final List<Map<String, dynamic>> _batches = [];
  final List<Map<String, dynamic>> _inventory = [];
  final List<Map<String, dynamic>> _sensors = [];
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
        _farms
          ..clear()
          ..addAll(results[0].where(_isAssignedToCurrentManager).map(_mapFarm));
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

  num _numValue(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _isAssignedToCurrentManager(Map<String, dynamic> farm) {
    final user = ref.read(authProvider).user;
    if (user == null) return true;
    final farmManagerId = _value(farm, ['farm_manager_id', 'farmManagerId']);
    final farmManagerName =
        _value(farm, ['farm_manager_name', 'farmManagerName']);
    return farmManagerId == user.id ||
        farmManagerId == user.email ||
        farmManagerName.toLowerCase() == user.name.toLowerCase();
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

  Map<String, dynamic> _teamMember(
    Map<String, dynamic> farm,
    List<String> keys,
    String role,
  ) {
    final userRef = _value(farm, keys);
    final user = _findUser(userRef);
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
      'tasks': 0,
      'completed': 0,
      'progress': 0.0,
      'hasTaskData': false,
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
        _buildBottomNavigation(isDark),
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 20),
            child: Column(
              children: [
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.agriculture_rounded,
                                size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Farms Overview',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${filtered.length}',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: ['All', 'Active', 'Seasonal']
                            .map((f) => _filterChip(f, isDark))
                            .toList(),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.agriculture_rounded,
                            size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Farms Overview',
                        style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${filtered.length}',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ),
                      const Spacer(),
                      ...['All', 'Active', 'Seasonal'].map((f) => Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _filterChip(f, isDark),
                          )),
                    ],
                  ),
                const SizedBox(height: 12),
                // Search
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search farms...',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color:
                            isDark ? Colors.white38 : AppColors.textSecondary),
                    prefixIcon: Icon(Icons.search,
                        size: 20,
                        color:
                            isDark ? Colors.white38 : AppColors.textSecondary),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : AppColors.neutral50,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : AppColors.neutral200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: AppColors.primary.withOpacity(0.5))),
                  ),
                ),
              ],
            ),
          ),

          if (filtered.isEmpty)
            _buildEmptyState(isDark)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : AppColors.neutral200),
              itemBuilder: (_, i) =>
                  _buildFarmCard(filtered[i], isDark, isMobile),
            ),
        ],
      ),
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

  Widget _buildFarmCard(Map<String, dynamic> farm, bool isDark, bool isMobile) {
    final team = (farm['team'] as List<Map<String, dynamic>>?) ?? [];
    final crops = (farm['crops'] as List<String>?) ?? [];
    final progress = (farm['progress'] as double?) ?? 0.0;
    final statusColor =
        farm['status'] == 'Active' ? AppColors.success : AppColors.warning;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showFarmDetails(farm, isDark, isMobile),
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
                        onTap: () => _showFarmDetails(farm, isDark, isMobile),
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
                      onTap: () => _showFarmDetails(farm, isDark, isMobile),
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

  void _showFarmDetails(Map<String, dynamic> farm, bool isDark, bool isMobile) {
    final team = (farm['team'] as List<Map<String, dynamic>>?) ?? [];
    final crops = (farm['crops'] as List<String>?) ?? [];
    final progress = (farm['progress'] as double?) ?? 0.0;
    final statusColor =
        farm['status'] == 'Active' ? AppColors.success : AppColors.warning;
    final sensorApiKey = farm['sensorApiKey']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding:
            EdgeInsets.symmetric(horizontal: isMobile ? 12 : 40, vertical: 24),
        child: Container(
          width: isMobile ? double.infinity : 650,
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark]),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.agriculture_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(farm['name'] ?? '',
                              style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 13, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(farm['location'] ?? '',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle, color: statusColor)),
                          const SizedBox(width: 5),
                          Text(farm['status'] ?? '',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),

              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Farm Info Grid
                      _sectionTitle('Farm Information',
                          Icons.info_outline_rounded, isDark),
                      const SizedBox(height: 12),
                      _detailGrid([
                        {'label': 'Farm ID', 'value': farm['id'] ?? ''},
                        {'label': 'Type', 'value': farm['type'] ?? ''},
                        {'label': 'Size', 'value': farm['size'] ?? ''},
                        {
                          'label': 'Active Batches',
                          'value': '${farm['activeBatches']}'
                        },
                        {
                          'label': 'Total Harvest',
                          'value': farm['totalHarvest'] ?? ''
                        },
                        {
                          'label': 'Sensors',
                          'value': '${farm['sensorCount'] ?? 0}'
                        },
                        {
                          'label': 'Sensor API Key',
                          'value': sensorApiKey.isEmpty
                              ? 'Not generated'
                              : sensorApiKey
                        },
                      ], isDark, isMobile),

                      const SizedBox(height: 16),

                      // Progress
                      _sectionTitle('Overall Progress',
                          Icons.trending_up_rounded, isDark),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                backgroundColor: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : AppColors.neutral200,
                                valueColor:
                                    AlwaysStoppedAnimation(AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('${(progress * 100).toInt()}%',
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Crops
                      _sectionTitle(
                          'Crops (${crops.length})', Icons.eco_rounded, isDark),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: crops
                            .map((c) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color:
                                            AppColors.primary.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.eco_rounded,
                                          size: 14, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text(c,
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),

                      const SizedBox(height: 20),

                      // Team Section
                      _sectionTitle('Team Members (${team.length})',
                          Icons.groups_rounded, isDark),
                      const SizedBox(height: 12),

                      ...team.map(
                          (m) => _buildDetailTeamCard(m, isDark, isMobile)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary)),
      ],
    );
  }

  Widget _detailGrid(
      List<Map<String, String>> items, bool isDark, bool isMobile) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: items.map((item) {
        return SizedBox(
          width: isMobile ? (MediaQuery.of(context).size.width - 100) / 2 : 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['label'] ?? '',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white38 : AppColors.textSecondary,
                      letterSpacing: 0.5)),
              const SizedBox(height: 3),
              Text(item['value'] ?? '',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Detail Team Card (inside dialog) ────────────────────────────────────

  Widget _buildDetailTeamCard(
      Map<String, dynamic> member, bool isDark, bool isMobile) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                isDark ? Colors.white.withOpacity(0.06) : AppColors.neutral200),
      ),
      child: Column(
        children: [
          // Top row: Avatar + name + status
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [memberColor.withOpacity(0.7), memberColor]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                    child: Text(member['avatar'] ?? '',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member['name'] ?? '',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(member['role'] ?? '',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: memberColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: memberColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: memberColor)),
                    const SizedBox(width: 5),
                    Text(memberStatus,
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: memberColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Info chips
          Row(
            children: [
              _memberInfoChip(Icons.work_outline_rounded,
                  member['specialty'] ?? '', isDark),
              const SizedBox(width: 8),
              _memberInfoChip(Icons.calendar_month_rounded,
                  'Since ${member['joinedDate'] ?? ''}', isDark),
            ],
          ),

          const SizedBox(height: 10),

          // Tasks + progress
          Row(
            children: [
              Text('Tasks: ',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color:
                          isDark ? Colors.white38 : AppColors.textSecondary)),
              Text(hasTaskData ? '$completed/$tasks completed' : 'No task data',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.textPrimary)),
              const Spacer(),
              Text(_taskProgressLabel(member),
                  style: GoogleFonts.inter(
                      fontSize: hasTaskData ? 12 : 10,
                      fontWeight: FontWeight.w700,
                      color: hasTaskData
                          ? _progressColor(progress)
                          : (isDark
                              ? Colors.white38
                              : AppColors.textSecondary))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.08)
                  : AppColors.neutral200,
              valueColor: AlwaysStoppedAnimation(
                hasTaskData
                    ? _progressColor(progress)
                    : (isDark ? Colors.white24 : AppColors.neutral300),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Contact row
          Row(
            children: [
              Icon(Icons.phone_outlined,
                  size: 13,
                  color: isDark ? Colors.white38 : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(member['phone'] ?? '',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color:
                          isDark ? Colors.white54 : AppColors.textSecondary)),
              const Spacer(),
              Icon(Icons.email_outlined,
                  size: 13,
                  color: isDark ? Colors.white38 : AppColors.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(member['email'] ?? '',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _memberInfoChip(IconData icon, String label, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : AppColors.neutral200),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 13,
                color: isDark ? Colors.white38 : AppColors.textSecondary),
            const SizedBox(width: 5),
            Flexible(
                child: Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  // ── Member Details Dialog ───────────────────────────────────────────────

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
