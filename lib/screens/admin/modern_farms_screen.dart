import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/batch_creation_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

class ModernFarmsScreen extends ConsumerStatefulWidget {
  const ModernFarmsScreen({super.key});

  @override
  ConsumerState<ModernFarmsScreen> createState() => _ModernFarmsScreenState();
}

class _ModernFarmsScreenState extends ConsumerState<ModernFarmsScreen> {
  final SuperAdminApiService _api = SuperAdminApiService();
  final List<Map<String, dynamic>> _farms = [];
  final List<Map<String, dynamic>> _users = [];
  final List<Map<String, dynamic>> _sensors = [];
  final List<Map<String, dynamic>> _inventory = [];
  final List<Map<String, dynamic>> _batches = [];
  final List<Map<String, dynamic>> _sales = [];
  final List<Map<String, dynamic>> _plantTypes = [];
  final List<Map<String, dynamic>> _cropVarieties = [];

  String _searchQuery = '';
  String _selectedStatus = 'All';
  bool _isLoading = true;
  bool _isGeneratingFarmKey = false;
  String? _loadError;
  bool _showingDetails = false;
  Map<String, dynamic>? _selectedFarm;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        _api.getFarms(),
        _api.getUsers(),
        _api.getSensors(),
        _api.getInventory(),
        _api.getBatches(),
        _api.getSales(),
        _api.getPlantTypes(),
        _api.getCrops(),
      ]);
      if (!mounted) return;
      _users
        ..clear()
        ..addAll(results[1].map(_mapUser));
      setState(() {
        _farms
          ..clear()
          ..addAll(results[0].map(_mapFarm));
        _sensors
          ..clear()
          ..addAll(results[2]);
        _inventory
          ..clear()
          ..addAll(results[3]);
        _batches
          ..clear()
          ..addAll(results[4]);
        _sales
          ..clear()
          ..addAll(results[5]);
        _plantTypes
          ..clear()
          ..addAll(results[6].map(_mapPlantType));
        _cropVarieties
          ..clear()
          ..addAll(results[7].map(_mapCropVariety));
        if (_selectedFarm != null) {
          final id = _selectedFarm!['id'].toString();
          _selectedFarm = _farms.cast<Map<String, dynamic>?>().firstWhere(
                (farm) => farm?['id'] == id,
                orElse: () => null,
              );
          _showingDetails = _selectedFarm != null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _mapUser(Map<String, dynamic> doc) {
    return {
      'id': (doc[r'$id'] ?? doc['user_id'] ?? doc['id'] ?? '').toString(),
      'name': (doc['name'] ?? 'Unnamed User').toString(),
      'email': (doc['email'] ?? '').toString(),
      'role': _roleLabel(doc['role']),
      'status': _label(doc['status'], fallback: 'Active'),
    };
  }

  Map<String, dynamic> _mapFarm(Map<String, dynamic> doc) {
    final id = (doc[r'$id'] ?? doc['farm_id'] ?? doc['id'] ?? '').toString();
    final ownerId = (doc['ownerID'] ?? 'Unassigned').toString();
    final managerId = (doc['farm_manager_id'] ?? 'Unassigned').toString();
    final technicianId = (doc['technician_id'] ?? 'Unassigned').toString();
    final caretakerId = (doc['caretakerID'] ?? 'Unassigned').toString();
    return {
      'id': id,
      'name': (doc['name'] ?? 'Unnamed Farm').toString(),
      'location': (doc['location'] ?? '-').toString(),
      'owner': _userName(ownerId),
      'ownerID': ownerId,
      'farmManager': _userName(managerId),
      'farmManagerId': managerId,
      'technician': _userName(technicianId),
      'technicianId': technicianId,
      'caretaker': _userName(caretakerId),
      'caretakerID': caretakerId,
      'plantType': (doc['plant_type'] ?? '-').toString(),
      'plantVariety': (doc['plant_variety'] ?? '-').toString(),
      'tier': _tierLabel(doc['tier_type']),
      'status': _label(doc['status'], fallback: 'Pending'),
      'sensorApiKey': (doc['sensor_ingest_api_key'] ?? '').toString(),
      'created': _dateLabel(doc[r'$createdAt'] ?? doc['created_at']),
    };
  }

  Map<String, dynamic> _mapPlantType(Map<String, dynamic> doc) {
    return {
      'id': (doc[r'$id'] ?? doc['plant_type_ID'] ?? doc['id'] ?? '').toString(),
      'name': (doc['name'] ?? 'Unnamed Plant Type').toString(),
      'status': _label(doc['status'], fallback: 'Active'),
      'isCategory': doc['is_category'] == true,
    };
  }

  Map<String, dynamic> _mapCropVariety(Map<String, dynamic> doc) {
    return {
      'id': (doc[r'$id'] ?? doc['crop_id'] ?? doc['id'] ?? '').toString(),
      'plantType': (doc['crop_name'] ?? '').toString(),
      'variety': (doc['variety_name'] ?? '').toString(),
      'status': _label(doc['status'], fallback: 'Active'),
    };
  }

  String _roleLabel(dynamic value) {
    final raw = value?.toString() ?? '';
    final normalized = raw.toLowerCase().replaceAll('_', ' ').trim();
    if (normalized == 'farm owner' || normalized == 'owner') return 'Owner';
    if (normalized == 'farm manager') return 'Farm Manager';
    if (normalized == 'technicians' || normalized == 'technician') {
      return 'Technician';
    }
    if (normalized == 'farm caretaker' || normalized == 'caretaker') {
      return 'Caretaker';
    }
    return _label(raw, fallback: 'Team Member');
  }

  String _label(dynamic value, {String fallback = '-'}) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return fallback;
    return text
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _tierLabel(dynamic value) {
    final text = value?.toString().toLowerCase() ?? '';
    if (text == 'compact') return 'Basic';
    if (text == 'medium') return 'Standard';
    if (text == 'mega') return 'Premium';
    return _label(value, fallback: 'Standard');
  }

  String _dateLabel(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return '-';
    final date = DateTime.tryParse(text);
    if (date == null) return text.length > 10 ? text.substring(0, 10) : text;
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _userName(String id) {
    if (id.isEmpty || id == 'Unassigned') return 'Unassigned';
    for (final user in _users) {
      if (user['id'] == id) return user['name'].toString();
    }
    return id;
  }

  List<Map<String, dynamic>> _usersForRole(String role) {
    return _users
        .where((user) => user['role'] == role && user['status'] == 'Active')
        .toList();
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
      ...users,
      {
        'id': id,
        'name': name.isEmpty ? id : name,
        'email': 'Existing farm assignment',
        'role': role,
        'status': 'Active',
      },
    ];
  }

  List<String> _uniqueOptions(List<String> values, {required String fallback}) {
    final cleaned = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return cleaned.isEmpty ? [fallback] : cleaned;
  }

  List<String> get _plantTypeOptions => _uniqueOptions(
        _plantTypes
            .where((plant) =>
                plant['isCategory'] != true && plant['status'] != 'Suspended')
            .map((plant) => plant['name'].toString())
            .toList(),
        fallback: 'Plant Type',
      );

  String _catalogKey(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '').trim();

  bool _catalogNamesMatch(String cropName, String plantType) {
    final cropKey = _catalogKey(cropName);
    final plantKey = _catalogKey(plantType);
    if (cropKey.isEmpty || plantKey.isEmpty) return false;
    return cropKey == plantKey ||
        cropKey.contains(plantKey) ||
        plantKey.contains(cropKey);
  }

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
    return _uniqueOptions(
      _matchingCropVarietiesForPlant(plantType)
          .map((crop) => crop['variety'].toString())
          .toList(),
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

  List<String> _ensureTextOption(List<String> options, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || options.contains(trimmed)) return options;
    return [...options, trimmed];
  }

  Map<String, String> _userLabels(List<Map<String, dynamic>> users) {
    return {
      for (final user in users)
        user['id'].toString():
            '${user['name']} (${user['email'].toString().isEmpty ? user['role'] : user['email']})',
    };
  }

  String _tierApiValue(String tier) {
    switch (tier) {
      case 'Basic':
        return 'compact';
      case 'Premium':
        return 'mega';
      case 'Standard':
      default:
        return 'medium';
    }
  }

  String _maskedFarmSensorKey(String key) {
    if (key.isEmpty) return 'No API key generated';
    if (key.length <= 20) return key;
    return '${key.substring(0, 16)}...${key.substring(key.length - 6)}';
  }

  Future<void> _regenerateFarmSensorKey(Map<String, dynamic> farm) async {
    if (_isGeneratingFarmKey) return;
    final messenger = ScaffoldMessenger.of(context);
    final currentUser = ref.read(currentUserProvider);
    setState(() => _isGeneratingFarmKey = true);
    try {
      final updatedFarm = await _api.generateFarmSensorApiKey(
        farmId: farm['id'].toString(),
        updatedBy: currentUser?.id ?? 'admin',
      );
      final mappedFarm = _mapFarm(updatedFarm);
      if (!mounted) return;
      setState(() {
        final index =
            _farms.indexWhere((item) => item['id'] == mappedFarm['id']);
        if (index >= 0) {
          _farms[index] = mappedFarm;
        }
        _selectedFarm = mappedFarm;
        _isGeneratingFarmKey = false;
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Farm sensor API key regenerated.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isGeneratingFarmKey = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not regenerate key: $error'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _updateFarmFromAdmin({
    required String id,
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
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await _api.updateFarm(
        id: id,
        name: name.trim(),
        ownerID: ownerID,
        caretakerID: caretakerID,
        farmManagerId: farmManagerId,
        technicianId: technicianId,
        location: location.trim(),
        plantType: plantType,
        plantVariety: plantVariety,
        tierType: _tierApiValue(tier),
        status: status,
      );
      final mapped = _mapFarm(updated);
      if (!mounted) return;
      setState(() {
        final index = _farms.indexWhere((farm) => farm['id'] == mapped['id']);
        if (index >= 0) {
          _farms[index] = mapped;
        }
        _selectedFarm = mapped;
        _showingDetails = true;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text('${mapped['name']} updated.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not update farm: $error'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      rethrow;
    }
  }

  List<Map<String, dynamic>> get _filteredFarms {
    final query = _searchQuery.trim().toLowerCase();
    return _farms.where((farm) {
      final haystack = [
        farm['name'],
        farm['location'],
        farm['plantType'],
        farm['plantVariety'],
        farm['farmManager'],
        farm['technician'],
        farm['caretaker'],
      ].join(' ').toLowerCase();
      if (query.isNotEmpty && !haystack.contains(query)) return false;
      if (_selectedStatus != 'All' && farm['status'] != _selectedStatus) {
        return false;
      }
      return true;
    }).toList();
  }

  int _sensorCountForFarm(Map<String, dynamic> farm) {
    final id = farm['id'].toString();
    final name = farm['name'].toString();
    return _sensors.where((sensor) {
      return (sensor['farmID'] ?? '').toString() == id ||
          (sensor['farm_name'] ?? '').toString() == name;
    }).length;
  }

  int _inventoryCountForFarm(Map<String, dynamic> farm) {
    final id = farm['id'].toString();
    final name = farm['name'].toString();
    return _inventory.where((item) {
      return (item['farm_id'] ?? item['farmID'] ?? '').toString() == id ||
          (item['farm_name'] ?? '').toString() == name;
    }).length;
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
        .where((batch) => !['Completed', 'Delivered'].contains(
              (batch['production_status'] ?? '').toString(),
            ))
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

  Future<void> _createBatchForFarm(Map<String, dynamic> farm) async {
    final controller = TextEditingController();
    var saving = false;
    String? errorText;
    final now = DateTime.now();
    final start = now.toIso8601String().substring(0, 10);
    final end =
        now.add(const Duration(days: 30)).toIso8601String().substring(0, 10);
    final farmId = '${farm['id'] ?? farm[r'$id'] ?? ''}';
    final farmName = '${farm['name'] ?? farm['farm_name'] ?? 'Farm'}';
    final plantName = '${farm['plantType'] ?? farm['plant_type'] ?? 'Plant'}';
    final managerId =
        '${farm['farmManagerId'] ?? farm['farm_manager_id'] ?? ''}';
    final managerName =
        '${farm['farmManager'] ?? farm['farm_manager_name'] ?? ''}';

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setModalState) => AlertDialog(
            title: const Text('Create Batch Number'),
            content: TextField(
              controller: controller,
              autofocus: true,
              enabled: !saving,
              decoration: InputDecoration(
                labelText: 'Batch number',
                hintText: 'Example: FAM-2026-001',
                errorText: errorText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        final batchNumber = controller.text.trim();
                        if (batchNumber.isEmpty) {
                          setModalState(
                              () => errorText = 'Enter a batch number.');
                          return;
                        }
                        setModalState(() => saving = true);
                        try {
                          await _api.createBatch(data: {
                            'batch_no': batchNumber,
                            'farmID': farmId,
                            'farm_name': farmName,
                            'plant_type_ID': '',
                            'plant_name': plantName,
                            'farm_manager_id': managerId,
                            'farm_manager_name': managerName,
                            'caretaker_id': '',
                            'caretaker_name': '',
                            'start_date': start,
                            'end_date': end,
                            'actual_harvest_date': end,
                            'total_seeds_nursed': 0,
                            'total_harvested': 0,
                            'total_transplanted': 0,
                            'total_weight_kg': 0,
                            'production_status': 'Planted',
                            'technical_issues': '',
                            'inputs_supplied':
                                'Batch created from farm details',
                            'funds_requested': false,
                            'financial_status': 'Pending',
                            'fund_request_id': '',
                            'delivery_status': 'Pending',
                            'delivery_details': '',
                            'created_by': ref.read(currentUserProvider)?.name ??
                                'Administrator',
                            'created_at': start,
                            'updated_at': now.toIso8601String(),
                          });
                          if (!mounted) return;
                          Navigator.pop(dialogContext);
                          await _loadData();
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Batch $batchNumber created successfully')),
                          );
                        } catch (error) {
                          setModalState(() {
                            saving = false;
                            errorText = error.toString();
                          });
                        }
                      },
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add, size: 18),
                label: Text(saving ? 'Creating...' : 'Create Batch'),
              ),
            ],
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
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
        .toList()
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

  double get _activeRatio {
    if (_farms.isEmpty) return 0;
    return _farms.where((farm) => farm['status'] == 'Active').length /
        _farms.length;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final userName = user?.name ?? 'Admin';
    final userEmail = user?.email ?? '';

    return Scaffold(
      drawer: isMobile
          ? AdminDrawer(
              selectedIndex: 2,
              onItemSelected: (_) {},
              userName: userName,
              userEmail: userEmail,
              userRole: 'Administrator',
            )
          : null,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail),
      bottomNavigationBar: isMobile
          ? AdminMobileBottomNav(selectedIndex: 2, onItemSelected: (_) {})
          : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail) {
    return Row(
      children: [
        ModernAdminSidebar(
          selectedIndex: 2,
          onItemSelected: (_) {},
          userName: userName,
          userEmail: userEmail,
          userRole: 'Administrator',
        ),
        Expanded(
          child: Column(
            children: [
              ModernAdminHeader(
                userName: userName.split(' ').first,
                onNotificationTap: () {},
                onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
              ),
              Expanded(child: _buildBody(isDark, AppSpacing.xl, false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark, String userName) {
    return Column(
      children: [
        ModernAdminHeader(
          userName: userName.split(' ').first,
          onNotificationTap: () {},
          onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
        ),
        Expanded(child: _buildBody(isDark, AppSpacing.md, true)),
      ],
    );
  }

  Widget _buildBody(bool isDark, double padding, bool isMobile) {
    if (_isLoading) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: const AdminDataSkeleton(rowCount: 6),
      );
    }
    if (_loadError != null) {
      return _buildErrorState(isDark, padding);
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: _showingDetails && _selectedFarm != null
            ? _buildDetails(isDark, _selectedFarm!)
            : _buildFarmList(isDark, isMobile),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, double padding) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: _panel(
        isDark,
        child: Column(
          children: [
            const Icon(Icons.cloud_off, color: AppColors.error, size: 42),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to load farms',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _loadError ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmList(bool isDark, bool isMobile) {
    final farms = _filteredFarms;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Farm Management',
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitor farm status, crop assignments, and operating teams',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh farms',
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Transform.translate(
          offset: Offset(0, isMobile ? -70 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStats(isDark),
              const SizedBox(height: AppSpacing.xl),
              _buildControls(isDark),
              const SizedBox(height: AppSpacing.lg),
              Transform.translate(
                offset: Offset(0, isMobile ? -50 : 0),
                child: farms.isEmpty
                    ? _buildEmptyState(isDark)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 980;
                          final cardHeight = isWide ? 320.0 : 330.0;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: farms.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isWide ? 2 : 1,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                              mainAxisExtent: cardHeight,
                            ),
                            itemBuilder: (_, index) =>
                                _buildFarmCard(farms[index], isDark),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats(bool isDark) {
    final active = _farms.where((farm) => farm['status'] == 'Active').length;
    final pending = _farms.where((farm) => farm['status'] == 'Pending').length;
    final suspended =
        _farms.where((farm) => farm['status'] == 'Suspended').length;
    final stats = [
      ('Total Farms', '${_farms.length}', Icons.agriculture, AppColors.primary),
      ('Active Farms', '$active', Icons.check_circle, AppColors.success),
      ('Pending Review', '$pending', Icons.pending_actions, AppColors.warning),
      ('Suspended', '$suspended', Icons.block, AppColors.error),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 700 ? 2 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: columns == 2 ? 2.2 : 2.8,
          ),
          itemBuilder: (_, index) {
            final stat = stats[index];
            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: stat.$4.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: stat.$4.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(stat.$3, color: stat.$4),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          stat.$2,
                          style: AppTypography.h6.copyWith(
                            color: stat.$4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          stat.$1,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
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
          },
        );
      },
    );
  }

  Widget _buildControls(bool isDark) {
    return _panel(
      isDark,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;
          final search = TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search farms...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDark ? Colors.white10 : AppColors.neutral100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
          );
          final status = _buildDropdown(
            value: _selectedStatus,
            items: const ['All', 'Active', 'Pending', 'Suspended'],
            isDark: isDark,
            onChanged: (value) => setState(() => _selectedStatus = value!),
          );
          if (isNarrow) {
            return Column(
              children: [
                search,
                const SizedBox(height: AppSpacing.sm),
                status,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: AppSpacing.md),
              SizedBox(width: 180, child: status),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFarmCard(Map<String, dynamic> farm, bool isDark) {
    final statusColor = _statusColor(farm['status']);
    final sensorCount = _sensorCountForFarm(farm);
    final inventoryCount = _inventoryCountForFarm(farm);
    final isActive = farm['status'] == 'Active';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => setState(() {
          _selectedFarm = farm;
          _showingDetails = true;
        }),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.07),
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 4, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Icon(
                              isActive
                                  ? Icons.agriculture_rounded
                                  : Icons.agriculture_outlined,
                              color: statusColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  farm['name'],
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: isDark
                                          ? Colors.white54
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        farm['location'],
                                        style: AppTypography.bodySmall.copyWith(
                                          color: isDark
                                              ? Colors.white60
                                              : AppColors.textSecondary,
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
                          _badge(farm['status'], statusColor),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.045)
                              : AppColors.neutral50,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _compactMetric(
                                'Crop',
                                farm['plantType'],
                                Icons.eco_outlined,
                                isDark,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: _compactMetric(
                                'Variety',
                                farm['plantVariety'],
                                Icons.grass_outlined,
                                isDark,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: _compactMetric(
                                'Tier',
                                farm['tier'],
                                Icons.workspace_premium_outlined,
                                isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _teamLine(
                              Icons.manage_accounts_outlined,
                              'Manager',
                              farm['farmManager'],
                              isDark,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _teamLine(
                              Icons.precision_manufacturing_outlined,
                              'Technician',
                              farm['technician'],
                              isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _teamLine(
                        Icons.engineering_outlined,
                        'Caretaker',
                        farm['caretaker'],
                        isDark,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.xs,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _footerMetric(
                                    Icons.sensors_outlined,
                                    '$sensorCount sensors',
                                    isDark,
                                  ),
                                  _footerMetric(
                                    Icons.inventory_2_outlined,
                                    '$inventoryCount items',
                                    isDark,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            IconButton(
                              tooltip: 'Edit farm',
                              onPressed: () =>
                                  _showEditFarmDialog(context, farm, isDark),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _detailsPill(),
                          ],
                        ),
                      ),
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

  Widget _buildDetails(bool isDark, Map<String, dynamic> farm) {
    final sensorCount = _sensorCountForFarm(farm);
    final inventoryCount = _inventoryCountForFarm(farm);
    final productionStats = _productionStatsForFarm(farm);
    final revenueStats = _revenueStatsForFarm(farm);
    final readiness = '${(_activeRatio * 100).round()}%';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFarmDetailsHero(farm, isDark),
            const SizedBox(height: AppSpacing.lg),
            _buildDetailsMetricGrid(
              isDark: isDark,
              sensorCount: sensorCount,
              inventoryCount: inventoryCount,
              completedBatches: productionStats['completed'] as int,
              totalBatches: productionStats['total'] as int,
              yieldWeightKg: productionStats['totalWeightKg'] as num,
              readiness: readiness,
              status: farm['status'],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildOverviewPanel(farm, isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildTeamPanel(farm, isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildRevenuePerformancePanel(revenueStats, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        _buildProductionProgressPanel(
                          productionStats,
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              _buildOverviewPanel(farm, isDark),
              const SizedBox(height: AppSpacing.lg),
              _buildTeamPanel(farm, isDark),
              const SizedBox(height: AppSpacing.lg),
              _buildRevenuePerformancePanel(revenueStats, isDark),
              const SizedBox(height: AppSpacing.lg),
              _buildProductionProgressPanel(productionStats, isDark),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFarmDetailsHero(Map<String, dynamic> farm, bool isDark) {
    final statusColor = _statusColor(farm['status']);
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
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() {
              _showingDetails = false;
              _selectedFarm = null;
            }),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back to farms'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Icon(
                  Icons.agriculture_rounded,
                  color: statusColor,
                  size: 34,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _badge(farm['status'], statusColor),
                        _badge(farm['tier'], AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      farm['name'],
                      style: AppTypography.h4.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color:
                              isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            farm['location'],
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
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
              const SizedBox(width: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => showBatchCreationDialog(
                      context: context,
                      api: _api,
                      farm: farm,
                      createdBy: ref.read(currentUserProvider)?.name ??
                          'Administrator',
                      onCreated: _loadData,
                    ),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: const Text('Batch Number'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showEditFarmDialog(context, farm, isDark),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Farm'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showAdminFarmSensorKeyDialog(
                      context,
                      farm,
                      isDark,
                    ),
                    icon: const Icon(Icons.vpn_key_rounded, size: 18),
                    label: const Text('API Key'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsMetricGrid({
    required bool isDark,
    required int sensorCount,
    required int inventoryCount,
    required int completedBatches,
    required int totalBatches,
    required num yieldWeightKg,
    required String readiness,
    required String status,
  }) {
    final metrics = [
      _DetailMetric(
        label: 'Sensors',
        value: '$sensorCount',
        icon: Icons.sensors_rounded,
        color: AppColors.info,
      ),
      _DetailMetric(
        label: 'Batches Done',
        value: '$completedBatches/$totalBatches',
        icon: Icons.task_alt_rounded,
        color: AppColors.success,
      ),
      _DetailMetric(
        label: 'Yield Weight',
        value: '${yieldWeightKg.toStringAsFixed(1)} kg',
        icon: Icons.scale_rounded,
        color: AppColors.warning,
      ),
      _DetailMetric(
        label: 'Inventory Items',
        value: '$inventoryCount',
        icon: Icons.inventory_2_rounded,
        color: AppColors.success,
      ),
      _DetailMetric(
        label: 'Readiness',
        value: readiness,
        icon: Icons.speed_rounded,
        color: AppColors.primary,
      ),
      _DetailMetric(
        label: 'Farm Status',
        value: status,
        icon: Icons.verified_rounded,
        color: _statusColor(status),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 680 ? 2 : 3;
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
          itemBuilder: (_, index) =>
              _buildDetailsMetricCard(metrics[index], isDark),
        );
      },
    );
  }

  Widget _buildDetailsMetricCard(_DetailMetric metric, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: metric.color.withValues(alpha: isDark ? 0.14 : 0.09),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: metric.color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.85),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(metric.icon, color: metric.color, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  style: AppTypography.h6.copyWith(
                    color: metric.color,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  metric.label,
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

  Widget _buildOverviewPanel(Map<String, dynamic> farm, bool isDark) {
    return _detailsSection(
      title: 'Production Profile',
      subtitle: 'Crop, variety, tier, and registration details',
      icon: Icons.eco_rounded,
      color: AppColors.success,
      isDark: isDark,
      child: Column(
        children: [
          _detailTile(
              'Plant Type', farm['plantType'], Icons.eco_outlined, isDark),
          _detailTile('Crop Variety', farm['plantVariety'],
              Icons.grass_outlined, isDark),
          _detailTile('Subscription Tier', farm['tier'],
              Icons.workspace_premium_outlined, isDark),
          _detailTile(
              'Registered', farm['created'], Icons.event_outlined, isDark),
        ],
      ),
    );
  }

  Widget _buildProductionProgressPanel(
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

    return _detailsSection(
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
              final items = [
                (
                  'Total Batches',
                  '$total',
                  Icons.all_inbox_rounded,
                  AppColors.primary
                ),
                (
                  'Active Batches',
                  '$active',
                  Icons.loop_rounded,
                  AppColors.info
                ),
                (
                  'Completed',
                  '$completed',
                  Icons.task_alt_rounded,
                  AppColors.success
                ),
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
                  return _productionStatTile(
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

  Widget _productionStatTile({
    required String label,
    required String value,
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

  Widget _buildRevenuePerformancePanel(_RevenueStats stats, bool isDark) {
    return _detailsSection(
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
                child: _revenueMetricTile(
                  'Total Revenue',
                  'GHS ${stats.totalRevenue.toStringAsFixed(2)}',
                  Icons.payments_rounded,
                  AppColors.primary,
                  isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _revenueMetricTile(
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

  Widget _revenueMetricTile(
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

  Widget _buildTeamPanel(Map<String, dynamic> farm, bool isDark) {
    return _detailsSection(
      title: 'Assigned Team',
      subtitle: 'Operational ownership for this farm',
      icon: Icons.groups_rounded,
      color: AppColors.primary,
      isDark: isDark,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns = constraints.maxWidth >= 520;
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
              return _teamMemberTile(
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

  void _showEditFarmDialog(
    BuildContext context,
    Map<String, dynamic> farm,
    bool isDark,
  ) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Create active Owner, Farm Manager, Technician, and Caretaker users before editing farm assignment.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final nameController = TextEditingController(text: farm['name']);
    final locationController = TextEditingController(text: farm['location']);
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
    String selectedPlantType = farm['plantType'].toString().trim().isEmpty
        ? _plantTypeOptions.first
        : farm['plantType'].toString();
    var plantTypeOptions =
        _ensureTextOption(_plantTypeOptions, selectedPlantType);
    if (!_hasVarietiesForPlant(selectedPlantType)) {
      selectedPlantType = _plantTypeOptions.firstWhere(
        _hasVarietiesForPlant,
        orElse: () => selectedPlantType,
      );
      plantTypeOptions =
          _ensureTextOption(_plantTypeOptions, selectedPlantType);
    }
    String selectedPlantVariety = farm['plantVariety'].toString().trim().isEmpty
        ? _varietyOptionsForPlant(selectedPlantType).first
        : farm['plantVariety'].toString();
    if (!_varietyOptionsForPlant(selectedPlantType)
        .contains(selectedPlantVariety)) {
      selectedPlantVariety = _varietyOptionsForPlant(selectedPlantType).first;
    }
    String selectedTier =
        ['Basic', 'Standard', 'Premium'].contains(farm['tier'])
            ? farm['tier'].toString()
            : 'Standard';
    String selectedStatus =
        ['Active', 'Pending', 'Suspended'].contains(farm['status'])
            ? farm['status'].toString()
            : 'Pending';
    bool isSaving = false;
    String? formError;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Dialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 620,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusLg),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Farm',
                                style: AppTypography.h6.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Update assignments, crop, location, tier, and status',
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
                          onPressed: isSaving
                              ? null
                              : () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (formError != null) ...[
                            _formError(formError!, isDark),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          _formTextField(
                            controller: nameController,
                            label: 'Farm Name',
                            icon: Icons.agriculture_outlined,
                            isDark: isDark,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _formTextField(
                            controller: locationController,
                            label: 'Location',
                            icon: Icons.location_on_outlined,
                            isDark: isDark,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _formDropdown(
                            value: selectedOwnerId,
                            items: ownerUsers
                                .map((user) => user['id'].toString())
                                .toList(),
                            labels: _userLabels(ownerUsers),
                            label: 'Owner',
                            icon: Icons.person_outline,
                            isDark: isDark,
                            onChanged: (value) =>
                                setDialogState(() => selectedOwnerId = value!),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _formDropdown(
                            value: selectedFarmManagerId,
                            items: farmManagerUsers
                                .map((user) => user['id'].toString())
                                .toList(),
                            labels: _userLabels(farmManagerUsers),
                            label: 'Farm Manager',
                            icon: Icons.manage_accounts_outlined,
                            isDark: isDark,
                            onChanged: (value) => setDialogState(
                                () => selectedFarmManagerId = value!),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _formDropdown(
                            value: selectedTechnicianId,
                            items: technicianUsers
                                .map((user) => user['id'].toString())
                                .toList(),
                            labels: _userLabels(technicianUsers),
                            label: 'Technician',
                            icon: Icons.precision_manufacturing_outlined,
                            isDark: isDark,
                            onChanged: (value) => setDialogState(
                                () => selectedTechnicianId = value!),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _formDropdown(
                            value: selectedCaretakerId,
                            items: caretakerUsers
                                .map((user) => user['id'].toString())
                                .toList(),
                            labels: _userLabels(caretakerUsers),
                            label: 'Caretaker',
                            icon: Icons.engineering_outlined,
                            isDark: isDark,
                            onChanged: (value) => setDialogState(
                                () => selectedCaretakerId = value!),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _formDropdown(
                            value: selectedPlantType,
                            items: plantTypeOptions,
                            label: 'Plant Type',
                            icon: Icons.eco_outlined,
                            isDark: isDark,
                            onChanged: (value) => setDialogState(() {
                              selectedPlantType = value!;
                              final varieties =
                                  _varietyOptionsForPlant(selectedPlantType);
                              selectedPlantVariety = varieties.first;
                            }),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _formDropdown(
                            value: selectedPlantVariety,
                            items: _ensureTextOption(
                              _varietyOptionsForPlant(selectedPlantType),
                              selectedPlantVariety,
                            ),
                            label: 'Crop Variety',
                            icon: Icons.grass_outlined,
                            isDark: isDark,
                            onChanged: _hasVarietiesForPlant(selectedPlantType)
                                ? (value) => setDialogState(
                                    () => selectedPlantVariety = value!)
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final stacked = constraints.maxWidth < 460;
                              final tier = _formDropdown(
                                value: selectedTier,
                                items: const ['Basic', 'Standard', 'Premium'],
                                label: 'Tier',
                                icon: Icons.workspace_premium_outlined,
                                isDark: isDark,
                                onChanged: (value) =>
                                    setDialogState(() => selectedTier = value!),
                              );
                              final status = _formDropdown(
                                value: selectedStatus,
                                items: const ['Active', 'Pending', 'Suspended'],
                                label: 'Status',
                                icon: Icons.verified_outlined,
                                isDark: isDark,
                                onChanged: (value) => setDialogState(
                                    () => selectedStatus = value!),
                              );
                              if (stacked) {
                                return Column(
                                  children: [
                                    tier,
                                    const SizedBox(height: AppSpacing.md),
                                    status,
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(child: tier),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(child: status),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : AppColors.neutral50,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppSpacing.radiusLg),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final name = nameController.text.trim();
                                    final location =
                                        locationController.text.trim();
                                    if (name.isEmpty || location.isEmpty) {
                                      setDialogState(() => formError =
                                          'Farm name and location are required.');
                                      return;
                                    }
                                    if (!_isValidPlantSelection(
                                      selectedPlantType,
                                      selectedPlantVariety,
                                    )) {
                                      setDialogState(() => formError =
                                          'Select a valid plant type and matching crop variety.');
                                      return;
                                    }
                                    setDialogState(() {
                                      isSaving = true;
                                      formError = null;
                                    });
                                    final navigator =
                                        Navigator.of(dialogContext);
                                    try {
                                      await _updateFarmFromAdmin(
                                        id: farm['id'].toString(),
                                        name: name,
                                        ownerID: selectedOwnerId,
                                        caretakerID: selectedCaretakerId,
                                        farmManagerId: selectedFarmManagerId,
                                        technicianId: selectedTechnicianId,
                                        location: location,
                                        plantType: selectedPlantType,
                                        plantVariety: selectedPlantVariety,
                                        tier: selectedTier,
                                        status: selectedStatus,
                                      );
                                      if (!mounted) return;
                                      navigator.pop();
                                    } catch (error) {
                                      if (!mounted) return;
                                      setDialogState(() {
                                        isSaving = false;
                                        formError = error.toString();
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
                                : const Icon(Icons.save_outlined, size: 18),
                            label: Text(isSaving ? 'Saving...' : 'Save Farm'),
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
    ).whenComplete(() {
      nameController.dispose();
      locationController.dispose();
    });
  }

  void _showAdminFarmSensorKeyDialog(
    BuildContext context,
    Map<String, dynamic> farm,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final currentFarm = _selectedFarm ?? farm;
          final apiKey = currentFarm['sensorApiKey']?.toString() ?? '';
          final hasKey = apiKey.isNotEmpty;
          return Dialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.10),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(
                          Icons.vpn_key_rounded,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sensor Hardware API',
                              style: AppTypography.h6.copyWith(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              currentFarm['name'].toString(),
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
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.045)
                          : AppColors.neutral50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: SelectableText(
                      _maskedFarmSensorKey(apiKey),
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _badge(hasKey ? 'Configured' : 'Missing',
                          hasKey ? AppColors.success : AppColors.warning),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: hasKey
                            ? () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await Clipboard.setData(
                                  ClipboardData(text: apiKey),
                                );
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Farm sensor API key copied.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ElevatedButton.icon(
                        onPressed: _isGeneratingFarmKey
                            ? null
                            : () async {
                                await _regenerateFarmSensorKey(currentFarm);
                                setDialogState(() {});
                              },
                        icon: _isGeneratingFarmKey
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.autorenew_rounded, size: 18),
                        label: Text(
                          _isGeneratingFarmKey
                              ? 'Working...'
                              : hasKey
                                  ? 'Regenerate'
                                  : 'Generate',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
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

  Widget _detailsSection({
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

  Widget _detailTile(String label, String value, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.035)
            : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.035),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
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

  Widget _teamMemberTile({
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

  Widget _teamLine(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon,
            size: 16, color: isDark ? Colors.white54 : AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            '$label: $value',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _compactMetric(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.white54 : AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _footerMetric(IconData icon, String label, bool isDark) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 128),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Details',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.primary,
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(color: color),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _formTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      decoration: _formDecoration(label, icon, isDark),
    );
  }

  Widget _formDropdown({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required bool isDark,
    Map<String, String>? labels,
    ValueChanged<String?>? onChanged,
  }) {
    final safeItems = items.isEmpty ? [value] : items;
    final safeValue = safeItems.contains(value) ? value : safeItems.first;
    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      items: safeItems
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                labels?[item] ?? item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: _formDecoration(label, icon, isDark),
    );
  }

  InputDecoration _formDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor:
          isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.neutral50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : AppColors.neutral300,
        ),
      ),
    );
  }

  Widget _formError(String message, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return _panel(
      isDark,
      child: Column(
        children: [
          Icon(Icons.agriculture_outlined,
              color: isDark ? Colors.white38 : AppColors.textSecondary,
              size: 42),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No farms found',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(
    bool isDark, {
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.lg),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.07),
        ),
      ),
      child: child,
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'Suspended':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      (Icons.dashboard_outlined, 'Dashboard', '/dashboard', false),
      (Icons.people_outline, 'Users', '/users', false),
      (Icons.agriculture_outlined, 'Farms', '/farms', true),
      (Icons.sensors_outlined, 'Sensors', '/sensors', false),
      (Icons.analytics_outlined, 'Analytics', '/analytics', false),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            children: navItems.map((item) {
              final selected = item.$4;
              return Expanded(
                child: InkWell(
                  onTap: selected
                      ? null
                      : () => Navigator.pushReplacementNamed(context, item.$3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.$1,
                        color: selected
                            ? AppColors.primary
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.$2,
                        style: AppTypography.caption.copyWith(
                          color: selected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : AppColors.textSecondary),
                          fontWeight:
                              selected ? FontWeight.w500 : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ],
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

class _DetailMetric {
  const _DetailMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
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
