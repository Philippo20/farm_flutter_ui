import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Super Admin Farm Management - Manage all farms with approval workflow
class FarmManagementScreen extends ConsumerStatefulWidget {
  const FarmManagementScreen({super.key});

  @override
  ConsumerState<FarmManagementScreen> createState() =>
      _FarmManagementScreenState();
}

class _FarmManagementScreenState extends ConsumerState<FarmManagementScreen> {
  String _selectedFilter = 'All';
  int _selectedNavIndex = 2;
  bool _isLoadingFarms = false;
  bool _showFarmDetails = false;
  String? _farmsError;
  Map<String, dynamic>? _selectedFarm;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SuperAdminApiService _api = SuperAdminApiService();

  final List<Map<String, dynamic>> _farms = [];
  final List<Map<String, dynamic>> _users = [];
  final List<Map<String, dynamic>> _plantTypes = [];
  final List<Map<String, dynamic>> _cropVarieties = [];
  final List<Map<String, dynamic>> _batches = [];
  final List<Map<String, dynamic>> _sales = [];

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    setState(() {
      _isLoadingFarms = true;
      _farmsError = null;
      _farms.clear();
    });

    try {
      final results = await Future.wait([
        _api.getFarms(),
        _api.getUsers(),
        _api.getPlantTypes(),
        _api.getCrops(),
        _api.getBatches(),
        _api.getSales(),
      ]);
      if (!mounted) return;
      setState(() {
        _users
          ..clear()
          ..addAll(results[1].map(_mapUserDocument));
        _plantTypes
          ..clear()
          ..addAll(results[2].map(_mapPlantTypeDocument));
        _cropVarieties
          ..clear()
          ..addAll(results[3].map(_mapCropDocument));
        _batches
          ..clear()
          ..addAll(results[4]);
        _sales
          ..clear()
          ..addAll(results[5]);
        _farms
          ..clear()
          ..addAll(results[0].map(_mapFarmDocument));
        if (_selectedFarm != null) {
          final selectedId = _selectedFarm!['id'].toString();
          _selectedFarm = _farms.cast<Map<String, dynamic>?>().firstWhere(
                (farm) => farm?['id'] == selectedId,
                orElse: () => null,
              );
          _showFarmDetails = _selectedFarm != null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _farmsError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoadingFarms = false);
      }
    }
  }

  Map<String, dynamic> _mapFarmDocument(Map<String, dynamic> doc) {
    final ownerID = (doc['ownerID'] ?? doc['owner'] ?? 'Unassigned').toString();
    final caretakerID = (doc['caretakerID'] ?? 'Unassigned').toString();
    final farmManagerId = (doc['farm_manager_id'] ?? 'Unassigned').toString();
    final technicianId = (doc['technician_id'] ?? 'Unassigned').toString();
    return {
      'id': (doc[r'$id'] ?? doc['farm_id'] ?? doc['id'] ?? '').toString(),
      'name': (doc['name'] ?? 'Unnamed Farm').toString(),
      'owner': _userNameById(ownerID, fallback: ownerID),
      'ownerID': ownerID,
      'caretaker': _userNameById(caretakerID, fallback: caretakerID),
      'caretakerID': caretakerID,
      'farmManager': _userNameById(farmManagerId, fallback: farmManagerId),
      'farmManagerId': farmManagerId,
      'technician': _userNameById(technicianId, fallback: technicianId),
      'technicianId': technicianId,
      'location': (doc['location'] ?? '-').toString(),
      'plantType': (doc['plant_type'] ?? '').toString(),
      'plantVariety': (doc['plant_variety'] ?? '').toString(),
      'tier': _tierLabel(doc['tier_type'] ?? doc['tierType'] ?? doc['tier']),
      'status': _statusLabel(doc['status']),
      'sensorApiKey': (doc['sensor_ingest_api_key'] ?? '').toString(),
      'batches': doc['batches'] ?? 0,
      'created': _dateLabel(doc[r'$createdAt'] ?? doc['created_at']),
    };
  }

  Map<String, dynamic> _mapUserDocument(Map<String, dynamic> doc) {
    final role = _roleLabel(doc['role']);
    return {
      'id': (doc[r'$id'] ?? doc['user_id'] ?? doc['id'] ?? '').toString(),
      'name': (doc['name'] ?? 'Unnamed User').toString(),
      'email': (doc['email'] ?? '').toString(),
      'role': role,
      'status': _statusLabel(doc['status']),
    };
  }

  Map<String, dynamic> _mapPlantTypeDocument(Map<String, dynamic> doc) {
    return {
      'id': (doc[r'$id'] ?? doc['plant_type_ID'] ?? doc['id'] ?? '').toString(),
      'name': (doc['name'] ?? 'Unnamed Plant Type').toString(),
      'status': _statusLabel(doc['status']),
      'isCategory': doc['is_category'] == true,
    };
  }

  Map<String, dynamic> _mapCropDocument(Map<String, dynamic> doc) {
    return {
      'id': (doc[r'$id'] ?? doc['crop_id'] ?? doc['id'] ?? '').toString(),
      'plantType': (doc['crop_name'] ?? '').toString(),
      'variety': (doc['variety_name'] ?? '').toString(),
      'status': _statusLabel(doc['status']),
    };
  }

  String _roleLabel(dynamic value) {
    final text = value?.toString() ?? '';
    final normalized = text.toLowerCase().replaceAll('_', ' ').trim();
    if (normalized == 'farm owner' || normalized == 'owner') return 'Owner';
    if (normalized == 'farm manager') return 'Farm Manager';
    if (normalized == 'farm caretaker' || normalized == 'caretaker') {
      return 'Caretaker';
    }
    if (normalized == 'technicians' || normalized == 'technician') {
      return 'Technician';
    }
    return _labelFromSnakeCase(text);
  }

  String _userNameById(String id, {required String fallback}) {
    for (final user in _users) {
      if (user['id'] == id) return user['name'].toString();
    }
    return fallback.isEmpty ? 'Unassigned' : fallback;
  }

  List<Map<String, dynamic>> _usersForRole(String role) {
    return _users
        .where((user) => user['role'] == role && user['status'] == 'Active')
        .toList();
  }

  List<String> get _plantTypeOptions => _uniqueOptions(
        _plantTypes
            .where((plant) =>
                plant['isCategory'] != true && plant['status'] != 'Suspended')
            .map((plant) => plant['name'].toString())
            .toList(),
        fallback: 'Plant Type',
      );

  List<Map<String, dynamic>> _matchingCropVarietiesForPlant(String plantType) {
    final activeVarieties = _cropVarieties
        .where((crop) =>
            crop['status'] != 'Suspended' &&
            crop['variety'].toString().trim().isNotEmpty)
        .toList();
    final matched = activeVarieties
        .where((crop) =>
            _catalogNamesMatch(crop['plantType'].toString(), plantType))
        .toList();
    return matched.isEmpty ? activeVarieties : matched;
  }

  List<String> _varietyOptionsForPlant(String plantType) {
    final filtered = _matchingCropVarietiesForPlant(plantType)
        .map((crop) => crop['variety'].toString())
        .toList();
    return _uniqueOptions(
      filtered,
      fallback: 'No varieties available',
    );
  }

  bool _hasVarietiesForPlant(String plantType) {
    return _matchingCropVarietiesForPlant(plantType).isNotEmpty;
  }

  bool _isValidPlantSelection(String plantType, String plantVariety) {
    return _plantTypeOptions.contains(plantType) &&
        _hasVarietiesForPlant(plantType) &&
        plantVariety != 'No varieties available' &&
        _varietyOptionsForPlant(plantType).contains(plantVariety);
  }

  bool _catalogNamesMatch(String cropName, String plantType) {
    final cropKey = _catalogKey(cropName);
    final plantKey = _catalogKey(plantType);
    if (cropKey.isEmpty || plantKey.isEmpty) return false;
    return cropKey == plantKey ||
        cropKey.contains(plantKey) ||
        plantKey.contains(cropKey);
  }

  String _catalogKey(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '').trim();
  }

  Map<String, String> _userLabels(List<Map<String, dynamic>> users) {
    return {
      for (final user in users)
        user['id'].toString(): _joinParts(
          [
            user['name']?.toString() ?? '',
            user['email']?.toString() ?? '',
          ],
          fallback: user['id'].toString(),
        ),
    };
  }

  List<Map<String, dynamic>> _ensureSelectedUser(
    List<Map<String, dynamic>> users,
    String id,
    String name,
    String role,
  ) {
    if (id.isEmpty || id == 'Unassigned') return users;
    if (users.any((user) => user['id'] == id)) return users;
    return [
      {
        'id': id,
        'name': name.isEmpty ? id : name,
        'email': 'Existing farm assignment',
        'role': role,
        'status': 'Active',
      },
      ...users,
    ];
  }

  String _joinParts(List<String> parts, {required String fallback}) {
    final cleaned = parts
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return cleaned.isEmpty ? fallback : cleaned.join(' | ');
  }

  void _openFarmDetails(Map<String, dynamic> farm) {
    setState(() {
      _selectedFarm = farm;
      _showFarmDetails = true;
    });
  }

  void _closeFarmDetails() {
    setState(() {
      _selectedFarm = null;
      _showFarmDetails = false;
    });
  }

  List<Map<String, dynamic>> _batchesForFarm(Map<String, dynamic> farm) {
    final id = farm['id'].toString();
    final name = farm['name'].toString();
    return _batches.where((batch) {
      return (batch['farmID'] ?? batch['farm_id'] ?? '').toString() == id ||
          (batch['farm_name'] ?? '').toString() == name;
    }).toList();
  }

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

  num _numValue(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
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
      for (final key in [r'$id', 'batch_id', 'batch_no']) {
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

  String _tierLabel(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return 'Standard';
    if (text.toLowerCase() == 'compact') return 'Basic';
    if (text.toLowerCase() == 'medium') return 'Standard';
    if (text.toLowerCase() == 'mega') return 'Premium';
    return _labelFromSnakeCase(text);
  }

  String _statusLabel(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return 'Active';
    if (text.toLowerCase() == 'active') return 'Active';
    if (text.toLowerCase() == 'pending') return 'Pending';
    if (text.toLowerCase() == 'inactive') return 'Suspended';
    if (text.toLowerCase() == 'suspended') return 'Suspended';
    return _labelFromSnakeCase(text);
  }

  String _labelFromSnakeCase(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _dateLabel(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.length >= 10) return text.substring(0, 10);
    return text.isEmpty ? '-' : text;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;

    final filteredFarms = _selectedFilter == 'All'
        ? _farms
        : _farms.where((f) => f['status'] == _selectedFilter).toList();

    final userName = user?.name ?? 'Super Admin';
    final userEmail = user?.email ?? '';
    final firstName = userName.split(' ').first;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? SuperAdminDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) {
                setState(() => _selectedNavIndex = index);
              },
              userName: userName,
              userEmail: userEmail,
              userRole: 'Super Administrator',
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(
              isDark: isDark,
              filteredFarms: filteredFarms,
              firstName: firstName,
            )
          : _buildDesktopLayout(
              isDark: isDark,
              filteredFarms: filteredFarms,
              userName: userName,
              userEmail: userEmail,
              firstName: firstName,
              isTablet: isTablet,
            ),
      bottomNavigationBar: isMobile
          ? SuperAdminMobileBottomNav(
              selectedIndex: 2,
              onItemSelected: (_) {},
            )
          : null,
    );
  }

  Widget _buildDesktopLayout({
    required bool isDark,
    required List<Map<String, dynamic>> filteredFarms,
    required String userName,
    required String userEmail,
    required String firstName,
    required bool isTablet,
  }) {
    return Row(
      children: [
        SuperAdminSidebar(
          selectedIndex: 2,
          onItemSelected: (_) {},
          userName: userName,
          userEmail: userEmail,
          userRole: 'Super Administrator',
        ),
        Expanded(
          child: Column(
            children: [
              ModernAdminHeader(
                userName: firstName,
                onNotificationTap: () {},
                onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: _buildFarmContent(
                    isDark: isDark,
                    filteredFarms: filteredFarms,
                    isCompact: isTablet,
                    isMobile: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout({
    required bool isDark,
    required List<Map<String, dynamic>> filteredFarms,
    required String firstName,
  }) {
    return Column(
      children: [
        ModernAdminHeader(
          userName: firstName,
          onNotificationTap: () {},
          onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildFarmContent(
              isDark: isDark,
              filteredFarms: filteredFarms,
              isCompact: true,
              isMobile: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFarmContent({
    required bool isDark,
    required List<Map<String, dynamic>> filteredFarms,
    required bool isCompact,
    required bool isMobile,
  }) {
    final sectionSpacing = isMobile ? AppSpacing.lg : AppSpacing.xl;
    final statsColumns = isMobile ? 2 : (isCompact ? 2 : 4);
    final statsRatio = isMobile ? 1.8 : (isCompact ? 2.2 : 2.6);

    if (_showFarmDetails && _selectedFarm != null) {
      return _buildFarmDetailsPage(_selectedFarm!, isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderSection(isDark, isCompact),
        SizedBox(height: isMobile ? 0 : sectionSpacing),
        _buildStats(
          isDark,
          crossAxisCount: statsColumns,
          childAspectRatio: statsRatio,
        ),
        SizedBox(height: sectionSpacing),
        _buildFilters(isDark),
        const SizedBox(height: AppSpacing.lg),
        if (_farmsError != null) ...[
          _buildSyncStatus(isDark),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_isLoadingFarms && _farms.isEmpty)
          const AdminDataSkeleton(showStats: false)
        else if (isCompact)
          _buildFarmCards(filteredFarms, isDark)
        else
          _buildFarmTable(filteredFarms, isDark),
      ],
    );
  }

  Widget _buildSyncStatus(bool isDark) {
    final hasError = _farmsError != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hasError
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Could not refresh farms: $_farmsError',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh farms',
            onPressed: _isLoadingFarms ? null : _loadFarms,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(bool isDark, bool isCompact) {
    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Farm Management',
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage farms, approve registrations, and monitor operations',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddFarmDialog(context, isDark),
              icon: const Icon(Icons.add_business, size: 18),
              label: const Text('Add Farm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farm Management',
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              'Manage farms, approve registrations, and monitor operations',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddFarmDialog(context, isDark),
          icon: const Icon(Icons.add_business, size: 20),
          label: const Text('Add Farm'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          ),
        ),
      ],
    );
  }

  Widget _buildFarmTable(
      List<Map<String, dynamic>> filteredFarms, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
            color:
                isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'All Farms',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${filteredFarms.length} records',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildFarmTableHeader(isDark),
          const SizedBox(height: AppSpacing.sm),
          ...filteredFarms.map((f) => _buildFarmRow(f, isDark)),
        ],
      ),
    );
  }

  Widget _buildFarmTableHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          _buildTableHeader('Farm', flex: 3, isDark: isDark),
          _buildTableHeader('Location', flex: 2, isDark: isDark),
          _buildTableHeader('Tier', isDark: isDark),
          _buildTableHeader('Batches', isDark: isDark),
          _buildTableHeader('Status', isDark: isDark),
          _buildTableHeader('Created', isDark: isDark),
          const SizedBox(width: 88),
        ],
      ),
    );
  }

  Widget _buildTableHeader(
    String label, {
    int flex = 1,
    required bool isDark,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? Colors.white54 : AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildHeaderBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildFarmActionButtons(Map<String, dynamic> farm, bool isDark) {
    final isPending = farm['status'] == 'Pending';
    return SizedBox(
      width: isPending ? 88 : 132,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isPending) ...[
            _buildTableIconAction(
              Icons.check_circle,
              AppColors.success,
              () => _approveFarm(farm),
              'Approve',
            ),
            _buildTableIconAction(
              Icons.cancel,
              AppColors.error,
              () => _rejectFarm(farm),
              'Reject',
            ),
          ] else ...[
            _buildTableIconAction(
              Icons.vpn_key_rounded,
              AppColors.success,
              () => _showFarmSensorKeyDialog(context, farm, isDark),
              'Sensor API key',
            ),
            _buildTableIconAction(
              Icons.edit_outlined,
              AppColors.primary,
              () => _showEditFarmDialog(context, farm, isDark),
              'Edit',
            ),
            _buildTableIconAction(
              farm['status'] == 'Suspended'
                  ? Icons.check_circle_outline
                  : Icons.block,
              farm['status'] == 'Suspended'
                  ? AppColors.success
                  : AppColors.error,
              () => _toggleSuspend(farm),
              farm['status'] == 'Suspended' ? 'Activate' : 'Suspend',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableIconAction(
    IconData icon,
    Color color,
    VoidCallback onPressed,
    String tooltip,
  ) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: color,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildFarmCards(
      List<Map<String, dynamic>> filteredFarms, bool isDark) {
    return Column(
      children: [
        for (final farm in filteredFarms) _buildMobileFarmCard(farm, isDark),
      ],
    );
  }

  Widget _buildStats(
    bool isDark, {
    required int crossAxisCount,
    required double childAspectRatio,
  }) {
    final totalFarms = _farms.length;
    final activeFarms =
        _farms.where((farm) => farm['status'] == 'Active').length;
    final pendingFarms =
        _farms.where((farm) => farm['status'] == 'Pending').length;
    final suspendedFarms =
        _farms.where((farm) => farm['status'] == 'Suspended').length;
    final stats = [
      {
        'title': 'Total Farms',
        'value': totalFarms.toString(),
        'icon': Icons.agriculture,
        'color': AppColors.success
      },
      {
        'title': 'Active',
        'value': activeFarms.toString(),
        'icon': Icons.check_circle,
        'color': AppColors.primary
      },
      {
        'title': 'Pending',
        'value': pendingFarms.toString(),
        'icon': Icons.pending,
        'color': AppColors.warning
      },
      {
        'title': 'Suspended',
        'value': suspendedFarms.toString(),
        'icon': Icons.block,
        'color': AppColors.error
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        final statColor = stat['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: statColor.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: statColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child:
                    Icon(stat['icon'] as IconData, color: statColor, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat['value'] as String,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: statColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      stat['title'] as String,
                      style: TextStyle(
                          fontSize: 10,
                          color: statColor.withValues(alpha: 0.8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters(bool isDark) {
    final filters = ['All', 'Active', 'Pending', 'Suspended'];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: filters.map((filter) {
        final isSelected = _selectedFilter == filter;
        return ChoiceChip(
          label: Text(filter),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _selectedFilter = filter);
          },
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.neutral100,
          labelStyle: TextStyle(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white70 : AppColors.textSecondary),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFarmRow(Map<String, dynamic> farm, bool isDark) {
    final statusColor = _statusColor(farm['status']);
    final tierColor = _tierColor(farm['tier']);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openFarmDetails(farm),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : AppColors.neutral50,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(Icons.agriculture,
                          color: AppColors.success, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(farm['name'],
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary)),
                          Text(
                              '${farm['id']} | Manager: ${farm['farmManager']} | Caretaker: ${farm['caretaker']}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white54
                                      : AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  farm['location'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(child: _buildBadge(farm['tier'], tierColor)),
              Expanded(
                child: Text(
                  '${farm['batches']}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(child: _buildBadge(farm['status'], statusColor)),
              Expanded(
                child: Text(
                  farm['created'],
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
              ),
              _buildFarmActionButtons(farm, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFarmCard(Map<String, dynamic> farm, bool isDark) {
    final statusColor = _statusColor(farm['status']);
    final tierColor = _tierColor(farm['tier']);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openFarmDetails(farm),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.agriculture,
                        color: AppColors.success, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farm['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manager: ${farm['farmManager']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white60
                                : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      farm['status'],
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _buildInfoPill('Location', farm['location'], isDark),
                  _buildInfoPill('Technician', farm['technician'], isDark),
                  _buildInfoPill('Caretaker', farm['caretaker'], isDark),
                  _buildInfoPill('Tier', farm['tier'], isDark,
                      valueColor: tierColor),
                  _buildInfoPill(
                      'Batches', '${farm['batches']} batches', isDark),
                  _buildInfoPill('Created', farm['created'], isDark),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (farm['status'] == 'Pending') ...[
                      IconButton(
                        onPressed: () => _approveFarm(farm),
                        icon: const Icon(Icons.check_circle, size: 20),
                        color: AppColors.success,
                        tooltip: 'Approve',
                      ),
                      IconButton(
                        onPressed: () => _rejectFarm(farm),
                        icon: const Icon(Icons.cancel, size: 20),
                        color: AppColors.error,
                        tooltip: 'Reject',
                      ),
                    ] else ...[
                      IconButton(
                        onPressed: () =>
                            _showFarmSensorKeyDialog(context, farm, isDark),
                        icon: const Icon(Icons.vpn_key_rounded, size: 18),
                        color: AppColors.success,
                        tooltip: 'Sensor API key',
                      ),
                      IconButton(
                        onPressed: () =>
                            _showEditFarmDialog(context, farm, isDark),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: AppColors.primary,
                      ),
                      IconButton(
                        onPressed: () => _toggleSuspend(farm),
                        icon: Icon(
                            farm['status'] == 'Suspended'
                                ? Icons.check_circle_outline
                                : Icons.block,
                            size: 18),
                        color: farm['status'] == 'Suspended'
                            ? AppColors.success
                            : AppColors.error,
                        tooltip: farm['status'] == 'Suspended'
                            ? 'Activate'
                            : 'Suspend',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPill(String label, String value, bool isDark,
      {Color? valueColor}) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          color:
              valueColor ?? (isDark ? Colors.white70 : AppColors.textSecondary),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'Pending':
        return AppColors.warning;
      case 'Suspended':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'Premium':
        return Colors.purple;
      case 'Standard':
        return AppColors.info;
      case 'Basic':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _approveFarm(Map<String, dynamic> farm) {
    return _updateFarmStatus(farm, 'Active');
  }

  Future<void> _rejectFarm(Map<String, dynamic> farm) {
    return _updateFarmStatus(farm, 'Suspended');
  }

  Future<void> _toggleSuspend(Map<String, dynamic> farm) {
    final nextStatus = farm['status'] == 'Suspended' ? 'Active' : 'Suspended';
    return _updateFarmStatus(farm, nextStatus);
  }

  Future<void> _updateFarmStatus(
    Map<String, dynamic> farm,
    String status,
  ) async {
    await _saveFarm(
      id: farm['id'].toString(),
      name: farm['name'].toString(),
      ownerID: farm['ownerID'].toString(),
      caretakerID: farm['caretakerID'].toString(),
      farmManagerId: farm['farmManagerId'].toString(),
      technicianId: farm['technicianId'].toString(),
      location: farm['location'].toString(),
      plantType: farm['plantType'].toString(),
      plantVariety: farm['plantVariety'].toString(),
      tier: farm['tier'].toString(),
      status: status,
      successMessage: '${farm['name']} ${status.toLowerCase()}',
    );
  }

  Future<void> _saveFarm({
    String? id,
    required String name,
    required String ownerID,
    required String caretakerID,
    required String farmManagerId,
    required String technicianId,
    required String location,
    required String plantType,
    required String plantVariety,
    required String tier,
    required String status,
    required String successMessage,
  }) async {
    if (name.trim().isEmpty ||
        location.trim().isEmpty ||
        plantType.trim().isEmpty ||
        plantVariety.trim().isEmpty ||
        !_isValidPlantSelection(plantType.trim(), plantVariety.trim())) {
      _showErrorSnack('Select a valid plant type and matching crop variety.');
      return;
    }

    setState(() {
      _isLoadingFarms = true;
      _farmsError = null;
    });

    try {
      if (id == null) {
        await _api.createFarm(
          name: name.trim(),
          location: location.trim(),
          ownerID: ownerID.trim().isEmpty ? 'Unassigned' : ownerID.trim(),
          caretakerID:
              caretakerID.trim().isEmpty ? 'Unassigned' : caretakerID.trim(),
          farmManagerId: farmManagerId.trim().isEmpty
              ? 'Unassigned'
              : farmManagerId.trim(),
          technicianId:
              technicianId.trim().isEmpty ? 'Unassigned' : technicianId.trim(),
          plantType: plantType.trim(),
          plantVariety: plantVariety.trim(),
          tierType: _tierApiValue(tier),
          status: status,
        );
      } else {
        await _api.updateFarm(
          id: id,
          name: name.trim(),
          location: location.trim(),
          ownerID: ownerID.trim().isEmpty ? 'Unassigned' : ownerID.trim(),
          caretakerID:
              caretakerID.trim().isEmpty ? 'Unassigned' : caretakerID.trim(),
          farmManagerId: farmManagerId.trim().isEmpty
              ? 'Unassigned'
              : farmManagerId.trim(),
          technicianId:
              technicianId.trim().isEmpty ? 'Unassigned' : technicianId.trim(),
          plantType: plantType.trim(),
          plantVariety: plantVariety.trim(),
          tierType: _tierApiValue(tier),
          status: status,
        );
      }
      await _loadFarms();
      if (!mounted) return;
      _showSuccessSnack(successMessage);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _farmsError = error.toString();
        _isLoadingFarms = false;
      });
      _showErrorSnack(error.toString());
    }
  }

  String _tierApiValue(String tier) {
    switch (tier) {
      case 'Basic':
        return 'Compact';
      case 'Premium':
        return 'Mega';
      default:
        return 'Medium';
    }
  }

  Widget _buildFarmDetailsPage(Map<String, dynamic> farm, bool isDark) {
    final stats = _productionStatsForFarm(farm);
    final revenueStats = _revenueStatsForFarm(farm);
    final statusColor = _statusColor(farm['status']);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        _buildDetailsSection(
                          title: 'Production Profile',
                          subtitle: 'Crop, variety, tier, and registration',
                          icon: Icons.eco_rounded,
                          color: AppColors.success,
                          isDark: isDark,
                          child: Column(
                            children: [
                              _buildDetailTile('Plant Type', farm['plantType'],
                                  Icons.eco_outlined, isDark),
                              _buildDetailTile(
                                  'Crop Variety',
                                  farm['plantVariety'],
                                  Icons.grass_outlined,
                                  isDark),
                              _buildDetailTile(
                                  'Subscription Tier',
                                  farm['tier'],
                                  Icons.workspace_premium_outlined,
                                  isDark),
                              _buildDetailTile('Created', farm['created'],
                                  Icons.event_outlined, isDark),
                            ],
                          ),
                        ),
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
                    child: Column(
                      children: [
                        _buildDetailsYieldPanel(stats, isDark),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              _buildDetailsSection(
                title: 'Production Profile',
                subtitle: 'Crop, variety, tier, and registration',
                icon: Icons.eco_rounded,
                color: AppColors.success,
                isDark: isDark,
                child: Column(
                  children: [
                    _buildDetailTile('Plant Type', farm['plantType'],
                        Icons.eco_outlined, isDark),
                    _buildDetailTile('Crop Variety', farm['plantVariety'],
                        Icons.grass_outlined, isDark),
                    _buildDetailTile('Subscription Tier', farm['tier'],
                        Icons.workspace_premium_outlined, isDark),
                    _buildDetailTile('Created', farm['created'],
                        Icons.event_outlined, isDark),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildDetailsTeamPanel(farm, isDark),
              const SizedBox(height: AppSpacing.lg),
              _buildDetailsRevenuePanel(revenueStats, isDark),
              const SizedBox(height: AppSpacing.lg),
              _buildDetailsYieldPanel(stats, isDark),
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
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildHeaderBadge(farm['status'], statusColor),
            _buildHeaderBadge(farm['tier'], AppColors.primary),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          farm['name'],
          style: AppTypography.h4.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          farm['location'],
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ],
    );
    final actions = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton.icon(
          onPressed: () => _showFarmSensorKeyDialog(context, farm, isDark),
          icon: const Icon(Icons.vpn_key_rounded, size: 18),
          label: const Text('API Key'),
        ),
        ElevatedButton.icon(
          onPressed: () => _showEditFarmDialog(context, farm, isDark),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit Farm'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _closeFarmDetails,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back to farms'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isMobile) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Icon(
                    Icons.agriculture_rounded,
                    color: statusColor,
                    size: 34,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: identity),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            actions,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Icon(
                    Icons.agriculture_rounded,
                    color: statusColor,
                    size: 34,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: identity),
                actions,
              ],
            ),
        ],
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
        'Harvested Heads',
        (stats['harvestedHeads'] as num).toStringAsFixed(0),
        Icons.grass_rounded,
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
        color: color.withValues(alpha: isDark ? 0.14 : 0.09),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.20)),
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
                  style: AppTypography.h6.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
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
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.06),
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
                  color: color.withValues(alpha: 0.10),
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

  Widget _buildDetailTile(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.035)
            : AppColors.neutral50,
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
              value,
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
    final members = [
      ('Owner', farm['owner'], Icons.person_outline, AppColors.info),
      (
        'Farm Manager',
        farm['farmManager'],
        Icons.manage_accounts_outlined,
        AppColors.primary
      ),
      (
        'Technician',
        farm['technician'],
        Icons.precision_manufacturing_outlined,
        AppColors.warning
      ),
      (
        'Caretaker',
        farm['caretaker'],
        Icons.engineering_outlined,
        AppColors.success
      ),
    ];
    return _buildDetailsSection(
      title: 'Assigned Team',
      subtitle: 'Operational ownership for this farm',
      icon: Icons.groups_rounded,
      color: AppColors.primary,
      isDark: isDark,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns = constraints.maxWidth >= 520;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: twoColumns ? 2 : 1,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              mainAxisExtent: 84,
            ),
            itemBuilder: (_, index) {
              final member = members[index];
              return _buildTeamMemberTile(
                role: member.$1,
                name: member.$2,
                icon: member.$3,
                color: member.$4,
                isDark: isDark,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTeamMemberTile({
    required String role,
    required String name,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  role,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  name,
                  style: AppTypography.bodyMedium.copyWith(
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

  Widget _buildDetailsYieldPanel(Map<String, dynamic> stats, bool isDark) {
    final total = stats['total'] as int;
    final active = stats['active'] as int;
    final completed = stats['completed'] as int;
    final harvestedHeads = stats['harvestedHeads'] as num;
    final lossHeads = stats['lossHeads'] as num;
    final lossRate = stats['lossRate'] as double;
    final totalWeightKg = stats['totalWeightKg'] as num;
    final progress = stats['progress'] as double;
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
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
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
              final twoColumns = constraints.maxWidth >= 520;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: twoColumns ? 2 : 1,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  mainAxisExtent: 86,
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
        ],
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
                  isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildRevenueMetricTile(
                  'Paid Revenue',
                  'GHS ${stats.paidRevenue.toStringAsFixed(2)}',
                  Icons.verified_rounded,
                  AppColors.success,
                  isDark,
                ),
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
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
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
            child: _FarmRevenueAreaChart(
              points: stats.points,
              isDark: isDark,
            ),
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
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.16)),
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

  void _showAddFarmDialog(BuildContext context, bool isDark) {
    final ownerUsers = _usersForRole('Owner');
    final farmManagerUsers = _usersForRole('Farm Manager');
    final technicianUsers = _usersForRole('Technician');
    final caretakerUsers = _usersForRole('Caretaker');
    if (ownerUsers.isEmpty ||
        farmManagerUsers.isEmpty ||
        technicianUsers.isEmpty ||
        caretakerUsers.isEmpty) {
      _showErrorSnack(
        'Create active Owner, Farm Manager, Technician, and Caretaker users before adding a farm.',
      );
      return;
    }
    if (_plantTypes.isEmpty || _cropVarieties.isEmpty) {
      _showErrorSnack(
        'Create plant types and crop varieties before adding a farm.',
      );
      return;
    }

    final nameController = TextEditingController();
    final locationController = TextEditingController();
    String selectedOwnerId = ownerUsers.first['id'].toString();
    String selectedFarmManagerId = farmManagerUsers.first['id'].toString();
    String selectedTechnicianId = technicianUsers.first['id'].toString();
    String selectedCaretakerId = caretakerUsers.first['id'].toString();
    String selectedPlantType = _plantTypeOptions.firstWhere(
      _hasVarietiesForPlant,
      orElse: () => _plantTypeOptions.first,
    );
    String selectedPlantVariety =
        _varietyOptionsForPlant(selectedPlantType).first;
    String selectedTier = 'Standard';
    String selectedStatus = 'Pending';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
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
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(Icons.add_business,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Farm',
                              style: AppTypography.h6.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Register a new farm in the system',
                              style: AppTypography.bodySmall
                                  .copyWith(color: Colors.white70),
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

                // Form Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormLabel('Farm Name', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(
                            controller: nameController,
                            hint: 'Enter farm name',
                            icon: Icons.agriculture,
                            isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Owner', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedOwnerId,
                          items: ownerUsers
                              .map((user) => user['id'].toString())
                              .toList(),
                          labels: _userLabels(ownerUsers),
                          icon: Icons.person_outline,
                          isDark: isDark,
                          onChanged: (value) =>
                              setDialogState(() => selectedOwnerId = value!),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Farm Manager', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedFarmManagerId,
                          items: farmManagerUsers
                              .map((user) => user['id'].toString())
                              .toList(),
                          labels: _userLabels(farmManagerUsers),
                          icon: Icons.manage_accounts_outlined,
                          isDark: isDark,
                          onChanged: (value) => setDialogState(
                              () => selectedFarmManagerId = value!),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Technician', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedTechnicianId,
                          items: technicianUsers
                              .map((user) => user['id'].toString())
                              .toList(),
                          labels: _userLabels(technicianUsers),
                          icon: Icons.precision_manufacturing_outlined,
                          isDark: isDark,
                          onChanged: (value) => setDialogState(
                              () => selectedTechnicianId = value!),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Caretaker', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedCaretakerId,
                          items: caretakerUsers
                              .map((user) => user['id'].toString())
                              .toList(),
                          labels: _userLabels(caretakerUsers),
                          icon: Icons.engineering_outlined,
                          isDark: isDark,
                          onChanged: (value) => setDialogState(
                              () => selectedCaretakerId = value!),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Location', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(
                            controller: locationController,
                            hint: 'Enter farm location',
                            icon: Icons.location_on_outlined,
                            isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Plant Type', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedPlantType,
                          items: _plantTypeOptions,
                          icon: Icons.eco_outlined,
                          isDark: isDark,
                          onChanged: (value) => setDialogState(() {
                            selectedPlantType = value!;
                            selectedPlantVariety =
                                _varietyOptionsForPlant(selectedPlantType)
                                    .first;
                          }),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Crop Variety', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedPlantVariety,
                          items: _varietyOptionsForPlant(selectedPlantType),
                          icon: Icons.grass_outlined,
                          isDark: isDark,
                          onChanged: _hasVarietiesForPlant(selectedPlantType)
                              ? (value) => setDialogState(
                                  () => selectedPlantVariety = value!)
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Subscription Tier', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedTier,
                          items: ['Basic', 'Standard', 'Premium'],
                          icon: Icons.star_outline,
                          isDark: isDark,
                          onChanged: (value) =>
                              setDialogState(() => selectedTier = value!),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Status', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedStatus,
                          items: ['Active', 'Pending', 'Suspended'],
                          icon: Icons.toggle_on_outlined,
                          isDark: isDark,
                          onChanged: (value) =>
                              setDialogState(() => selectedStatus = value!),
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
                        ? Colors.white.withValues(alpha: 0.03)
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
                                vertical: AppSpacing.md),
                            side: BorderSide(
                                color: isDark
                                    ? Colors.white24
                                    : AppColors.neutral300),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd)),
                          ),
                          child: Text('Cancel',
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _saveFarm(
                              name: nameController.text,
                              ownerID: selectedOwnerId,
                              caretakerID: selectedCaretakerId,
                              farmManagerId: selectedFarmManagerId,
                              technicianId: selectedTechnicianId,
                              location: locationController.text,
                              plantType: selectedPlantType,
                              plantVariety: selectedPlantVariety,
                              tier: selectedTier,
                              status: selectedStatus,
                              successMessage:
                                  '${nameController.text.isEmpty ? "Farm" : nameController.text} added successfully.',
                            );
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Farm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd)),
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

  void _showEditFarmDialog(
      BuildContext context, Map<String, dynamic> farm, bool isDark) {
    final ownerUsers = _ensureSelectedUser(
      _usersForRole('Owner'),
      farm['ownerID'].toString(),
      farm['owner'].toString(),
      'Owner',
    );
    final farmManagerUsers = _ensureSelectedUser(
      _usersForRole('Farm Manager'),
      farm['farmManagerId'].toString(),
      farm['farmManager'].toString(),
      'Farm Manager',
    );
    final technicianUsers = _ensureSelectedUser(
      _usersForRole('Technician'),
      farm['technicianId'].toString(),
      farm['technician'].toString(),
      'Technician',
    );
    final caretakerUsers = _ensureSelectedUser(
      _usersForRole('Caretaker'),
      farm['caretakerID'].toString(),
      farm['caretaker'].toString(),
      'Caretaker',
    );
    if (ownerUsers.isEmpty ||
        farmManagerUsers.isEmpty ||
        technicianUsers.isEmpty ||
        caretakerUsers.isEmpty) {
      _showErrorSnack(
        'Create active Owner, Farm Manager, Technician, and Caretaker users before editing farm assignment.',
      );
      return;
    }
    if (_plantTypes.isEmpty || _cropVarieties.isEmpty) {
      _showErrorSnack(
        'Create plant types and crop varieties before editing farm planting details.',
      );
      return;
    }

    final nameController = TextEditingController(text: farm['name']);
    final locationController = TextEditingController(text: farm['location']);
    String selectedPlantType = farm['plantType'].toString().isEmpty
        ? _plantTypeOptions.first
        : farm['plantType'].toString();
    final plantTypeOptions = _ensureTextOption(
      _plantTypeOptions,
      selectedPlantType,
    );
    String selectedPlantVariety = farm['plantVariety'].toString().isEmpty
        ? _varietyOptionsForPlant(selectedPlantType).first
        : farm['plantVariety'].toString();
    if (!_hasVarietiesForPlant(selectedPlantType)) {
      final fallbackPlantType = _plantTypeOptions.firstWhere(
        _hasVarietiesForPlant,
        orElse: () => selectedPlantType,
      );
      if (fallbackPlantType != selectedPlantType) {
        selectedPlantType = fallbackPlantType;
        selectedPlantVariety = _varietyOptionsForPlant(selectedPlantType).first;
      }
    } else if (!_varietyOptionsForPlant(selectedPlantType)
        .contains(selectedPlantVariety)) {
      selectedPlantVariety = _varietyOptionsForPlant(selectedPlantType).first;
    }
    String selectedOwnerId =
        ownerUsers.any((user) => user['id'] == farm['ownerID'])
            ? farm['ownerID'].toString()
            : ownerUsers.first['id'].toString();
    String selectedFarmManagerId =
        farmManagerUsers.any((user) => user['id'] == farm['farmManagerId'])
            ? farm['farmManagerId'].toString()
            : farmManagerUsers.first['id'].toString();
    String selectedTechnicianId =
        technicianUsers.any((user) => user['id'] == farm['technicianId'])
            ? farm['technicianId'].toString()
            : technicianUsers.first['id'].toString();
    String selectedCaretakerId =
        caretakerUsers.any((user) => user['id'] == farm['caretakerID'])
            ? farm['caretakerID'].toString()
            : caretakerUsers.first['id'].toString();
    String selectedTier = farm['tier'];
    String selectedStatus = farm['status'];
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
          child: Container(
            width: isMobile ? double.infinity : 500,
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit Farm',
                                style: AppTypography.h6.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            Text('Update farm information',
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

                // Farm Preview
                Container(
                  margin: const EdgeInsets.all(AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.neutral50,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(Icons.agriculture,
                            color: AppColors.success, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(farm['name'],
                                style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary)),
                            Text(
                                'ID: ${farm['id']} | ${farm['batches']} batches',
                                style: AppTypography.bodySmall.copyWith(
                                    color: isDark
                                        ? Colors.white60
                                        : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Content
                Flexible(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormLabel('Farm Name', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(
                            controller: nameController,
                            hint: 'Enter farm name',
                            icon: Icons.agriculture,
                            isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Owner', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedOwnerId,
                          items: ownerUsers
                              .map((user) => user['id'].toString())
                              .toList(),
                          labels: _userLabels(ownerUsers),
                          icon: Icons.person_outline,
                          isDark: isDark,
                          onChanged: (value) =>
                              setDialogState(() => selectedOwnerId = value!),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Farm Manager', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedFarmManagerId,
                          items: farmManagerUsers
                              .map((user) => user['id'].toString())
                              .toList(),
                          labels: _userLabels(farmManagerUsers),
                          icon: Icons.manage_accounts_outlined,
                          isDark: isDark,
                          onChanged: (value) => setDialogState(
                              () => selectedFarmManagerId = value!),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Technician', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedTechnicianId,
                          items: technicianUsers
                              .map((user) => user['id'].toString())
                              .toList(),
                          labels: _userLabels(technicianUsers),
                          icon: Icons.precision_manufacturing_outlined,
                          isDark: isDark,
                          onChanged: (value) => setDialogState(
                              () => selectedTechnicianId = value!),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Caretaker', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedCaretakerId,
                          items: caretakerUsers
                              .map((user) => user['id'].toString())
                              .toList(),
                          labels: _userLabels(caretakerUsers),
                          icon: Icons.engineering_outlined,
                          isDark: isDark,
                          onChanged: (value) => setDialogState(
                              () => selectedCaretakerId = value!),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Location', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(
                            controller: locationController,
                            hint: 'Enter farm location',
                            icon: Icons.location_on_outlined,
                            isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Plant Type', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedPlantType,
                          items: plantTypeOptions,
                          icon: Icons.eco_outlined,
                          isDark: isDark,
                          onChanged: (value) => setDialogState(() {
                            selectedPlantType = value!;
                            selectedPlantVariety =
                                _varietyOptionsForPlant(selectedPlantType)
                                    .first;
                          }),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Crop Variety', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedPlantVariety,
                          items: _ensureTextOption(
                            _varietyOptionsForPlant(selectedPlantType),
                            selectedPlantVariety,
                          ),
                          icon: Icons.grass_outlined,
                          isDark: isDark,
                          onChanged: _hasVarietiesForPlant(selectedPlantType)
                              ? (value) => setDialogState(
                                  () => selectedPlantVariety = value!)
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (!isMobile)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFormLabel('Tier', isDark),
                                    const SizedBox(height: AppSpacing.sm),
                                    _buildDropdownField(
                                        value: selectedTier,
                                        items: ['Basic', 'Standard', 'Premium'],
                                        icon: Icons.star_outline,
                                        isDark: isDark,
                                        onChanged: (v) => setDialogState(
                                            () => selectedTier = v!)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFormLabel('Status', isDark),
                                    const SizedBox(height: AppSpacing.sm),
                                    _buildDropdownField(
                                        value: selectedStatus,
                                        items: [
                                          'Active',
                                          'Pending',
                                          'Suspended'
                                        ],
                                        icon: Icons.toggle_on_outlined,
                                        isDark: isDark,
                                        onChanged: (v) => setDialogState(
                                            () => selectedStatus = v!)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _buildFormLabel('Tier', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildDropdownField(
                              value: selectedTier,
                              items: ['Basic', 'Standard', 'Premium'],
                              icon: Icons.star_outline,
                              isDark: isDark,
                              onChanged: (v) =>
                                  setDialogState(() => selectedTier = v!)),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Status', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildDropdownField(
                              value: selectedStatus,
                              items: ['Active', 'Pending', 'Suspended'],
                              icon: Icons.toggle_on_outlined,
                              isDark: isDark,
                              onChanged: (v) =>
                                  setDialogState(() => selectedStatus = v!)),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : AppColors.neutral50,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteFarmDialog(context, farm, isDark);
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                              horizontal: AppSpacing.md),
                          side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            side: BorderSide(
                                color: isDark
                                    ? Colors.white24
                                    : AppColors.neutral300),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd)),
                          ),
                          child: Text('Cancel',
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _saveFarm(
                              id: farm['id'].toString(),
                              name: nameController.text,
                              ownerID: selectedOwnerId,
                              caretakerID: selectedCaretakerId,
                              farmManagerId: selectedFarmManagerId,
                              technicianId: selectedTechnicianId,
                              location: locationController.text,
                              plantType: selectedPlantType,
                              plantVariety: selectedPlantVariety,
                              tier: selectedTier,
                              status: selectedStatus,
                              successMessage: '${nameController.text} updated.',
                            );
                          },
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd)),
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

  String _maskedFarmSensorKey(String key) {
    if (key.isEmpty) return 'No API key generated';
    if (key.length <= 18) return key;
    return '${key.substring(0, 14)}...${key.substring(key.length - 6)}';
  }

  Future<void> _generateFarmSensorApiKey(
    Map<String, dynamic> farm,
    void Function(void Function()) setDialogState,
  ) async {
    setDialogState(() => farm['isGeneratingSensorKey'] = true);

    try {
      final user = ref.read(currentUserProvider);
      final email = user?.email.trim();
      final updatedBy = email != null && email.isNotEmpty ? email : 'system';
      final updatedFarm = await _api.generateFarmSensorApiKey(
        farmId: farm['id'].toString(),
        updatedBy: updatedBy,
      );
      final mapped = _mapFarmDocument(updatedFarm);
      if (!mounted) return;
      setState(() {
        final index = _farms.indexWhere((item) => item['id'] == mapped['id']);
        if (index >= 0) {
          _farms[index] = mapped;
        }
      });
      setDialogState(() {
        farm
          ..clear()
          ..addAll(mapped)
          ..['isGeneratingSensorKey'] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Farm sensor API key generated'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setDialogState(() => farm['isGeneratingSensorKey'] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showFarmSensorKeyDialog(
      BuildContext context, Map<String, dynamic> sourceFarm, bool isDark) {
    final farm = Map<String, dynamic>.from(sourceFarm);
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final key = (farm['sensorApiKey'] ?? '').toString();
          final hasKey = key.isNotEmpty;
          final isGenerating = farm['isGeneratingSensorKey'] == true;

          return Dialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Container(
              width: 520,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(Icons.vpn_key_rounded,
                            color: AppColors.success),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Farm Sensor API Key',
                              style: AppTypography.titleMedium.copyWith(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              farm['name'].toString(),
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Use this key in the x-sensor-key header for devices sending readings for this farm only.',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : AppColors.neutral50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            _maskedFarmSensorKey(key),
                            style: AppTypography.bodySmall.copyWith(
                              color: hasKey
                                  ? (isDark
                                      ? Colors.white
                                      : AppColors.textPrimary)
                                  : (isDark
                                      ? Colors.white54
                                      : AppColors.textSecondary),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy full key',
                          onPressed: hasKey
                              ? () {
                                  Clipboard.setData(ClipboardData(text: key));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Farm sensor API key copied'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.copy_rounded),
                          color: AppColors.success,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isGenerating
                            ? null
                            : () => Navigator.of(dialogContext).pop(),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ElevatedButton.icon(
                        onPressed: isGenerating
                            ? null
                            : () => _generateFarmSensorApiKey(
                                  farm,
                                  setDialogState,
                                ),
                        icon: isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.autorenew_rounded, size: 18),
                        label: Text(hasKey ? 'Regenerate Key' : 'Generate Key'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteFarmDialog(
      BuildContext context, Map<String, dynamic> farm, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.delete_forever,
                    color: AppColors.error, size: 40),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Delete Farm?',
                  style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Are you sure you want to delete "${farm['name']}"? This will remove all associated data.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        side: BorderSide(
                            color:
                                isDark ? Colors.white24 : AppColors.neutral300),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd)),
                      ),
                      child: Text('Cancel',
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteFarm(farm);
                      },
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteFarm(Map<String, dynamic> farm) async {
    setState(() {
      _isLoadingFarms = true;
      _farmsError = null;
    });
    try {
      await _api.deleteFarm(farm['id'].toString());
      await _loadFarms();
      if (!mounted) return;
      _showSuccessSnack('${farm['name']} deleted.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _farmsError = error.toString();
        _isLoadingFarms = false;
      });
      _showErrorSnack(error.toString());
    }
  }

  // Helper widgets for form fields
  Widget _buildFormLabel(String label, bool isDark) {
    return Text(label,
        style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.textPrimary));
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      required bool isDark,
      TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: isDark
                ? Colors.white38
                : AppColors.textSecondary.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon,
            color: isDark ? Colors.white54 : AppColors.textSecondary, size: 20),
        filled: true,
        fillColor:
            isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.neutral50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
                color: isDark ? Colors.white12 : AppColors.neutral200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
                color: isDark ? Colors.white12 : AppColors.neutral200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.success, width: 2)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
      ),
    );
  }

  Widget _buildDropdownField(
      {required String value,
      required List<String> items,
      required IconData icon,
      required bool isDark,
      required ValueChanged<String?>? onChanged,
      Map<String, String>? labels}) {
    final normalizedItems = _uniqueOptions(items, fallback: value);
    final normalizedValue =
        normalizedItems.contains(value) ? value : normalizedItems.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border:
            Border.all(color: isDark ? Colors.white12 : AppColors.neutral200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: normalizedValue,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down,
              color: isDark ? Colors.white54 : AppColors.textSecondary),
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 14),
          items: normalizedItems
              .map((item) => DropdownMenuItem(
                  value: item,
                  child: Row(children: [
                    Icon(icon,
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary,
                        size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        labels?[item] ?? item,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ])))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  List<String> _uniqueOptions(List<String> items, {required String fallback}) {
    final seen = <String>{};
    final options = <String>[];
    for (final item in items) {
      final trimmed = item.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) continue;
      options.add(trimmed);
    }
    return options.isEmpty ? [fallback] : options;
  }

  List<String> _ensureTextOption(List<String> options, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || options.contains(trimmed)) return options;
    return [trimmed, ...options];
  }

  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
      return Center(
        child: Text(
          'No revenue records yet',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white60 : AppColors.textSecondary,
          ),
        ),
      );
    }

    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value)
    ];
    final maxY = spots
        .map((spot) => spot.y)
        .fold<double>(0, (max, value) => value > max ? value : max);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: 0,
        maxY: maxY <= 0 ? 100 : maxY * 1.18,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, _) => Text(
                value >= 1000
                    ? '${(value / 1000).toStringAsFixed(1)}k'
                    : value.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, _) {
                final index = value.round();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                final date = points[index].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.16),
            ),
          ),
        ],
      ),
    );
  }
}
