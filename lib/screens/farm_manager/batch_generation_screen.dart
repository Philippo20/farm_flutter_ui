import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/models/batch/batch_model.dart';
import '../../core/providers/batch_provider.dart';
import '../../core/widgets/farm_manager_sidebar.dart';
import '../../core/widgets/farm_manager_header.dart';
import '../../core/widgets/farm_manager_mobile_drawer.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/status_badge.dart';
import '../../services/superadmin_api_service.dart';

/// Batch Management & Tracking Screen
/// Farm Manager can generate new batches and track their progress
class BatchGenerationScreen extends ConsumerStatefulWidget {
  const BatchGenerationScreen({super.key});

  @override
  ConsumerState<BatchGenerationScreen> createState() =>
      _BatchGenerationScreenState();
}

class _BatchGenerationScreenState extends ConsumerState<BatchGenerationScreen> {
  final SuperAdminApiService _api = SuperAdminApiService();
  final _formKey = GlobalKey<FormState>();
  int _selectedNavIndex = 3;
  final _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Form controllers
  String? _selectedFarm;
  String? _selectedPlantType;
  String? _selectedPlantVariety;
  DateTime? _startDate;
  DateTime? _endDate;
  int _nursedSeeds = 0;
  String? _caretakerId;
  final _notesController = TextEditingController();

  bool _isGenerating = false;
  bool _showForm = false; // Default to tracking view (table/cards)
  String _searchQuery = '';
  String _selectedBatchFarm = 'All Farms';
  String _selectedBatchStatus = 'All Statuses';
  String _selectedBatchPlant = 'All Plants';
  final _batchSearchController = TextEditingController();

  final List<Map<String, dynamic>> _farms = [];
  final List<Map<String, dynamic>> _caretakers = [];
  final List<Map<String, dynamic>> _plantTypes = [];
  final List<Map<String, dynamic>> _cropVarieties = [];
  bool _isLoadingData = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadBatchData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notesController.dispose();
    _batchSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadBatchData() async {
    setState(() {
      _isLoadingData = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        _api.getFarms(),
        _api.getUsers(),
        _api.getPlantTypes(),
        _api.getCrops(),
        _api.getBatches(),
      ]);
      if (!mounted) return;
      final assignedFarms =
          results[0].where(_isAssignedToCurrentManager).toList();
      final assignedBatches = results[4]
          .where((batch) => _matchesAnyFarm(batch, assignedFarms))
          .map(_mapBatch)
          .toList();
      setState(() {
        _farms
          ..clear()
          ..addAll(assignedFarms.map((farm) => {
                'id': _docId(farm),
                'name': _value(farm, ['name', 'farm_name'],
                    fallback: 'Unnamed Farm'),
                'plantType': _value(farm, ['plant_type', 'plantType']),
                'plantVariety': _value(farm, ['plant_variety', 'plantVariety']),
                'caretakerId': _value(farm, ['caretakerID', 'caretaker_id']),
              }));
        _caretakers
          ..clear()
          ..addAll(results[1].where((user) {
            final role = _value(user, ['role']).toLowerCase();
            return role.contains('caretaker');
          }).map((user) => {
                'id': _docId(user),
                'name': _value(user, ['name'], fallback: 'Caretaker'),
              }));
        _plantTypes
          ..clear()
          ..addAll(results[2]);
        _cropVarieties
          ..clear()
          ..addAll(results[3]);
        ref.read(batchProvider.notifier).setBatches(assignedBatches);
        _isLoadingData = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoadingData = false;
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

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime _dateValue(dynamic value, {DateTime? fallback}) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        fallback ??
        DateTime.now();
  }

  bool _isAssignedToCurrentManager(Map<String, dynamic> farm) {
    final user = ref.read(authProvider).user;
    if (user == null) return true;
    final managerId = _value(farm, ['farm_manager_id', 'farmManagerId']);
    final managerName = _value(farm, ['farm_manager_name', 'farmManagerName']);
    return managerId == user.id ||
        managerId == user.email ||
        managerName.toLowerCase() == user.name.toLowerCase();
  }

  bool _matchesAnyFarm(
      Map<String, dynamic> doc, List<Map<String, dynamic>> farms) {
    if (farms.isEmpty) return false;
    final farmIds = farms.map(_docId).where((id) => id.isNotEmpty).toSet();
    final farmNames = farms
        .map((farm) => _value(farm, ['name', 'farm_name']))
        .where((name) => name.isNotEmpty)
        .toSet();
    final farmId = _value(doc, ['farmID', 'farm_id', 'farmId']);
    final farmName = _value(doc, ['farm_name', 'farmName']);
    return farmIds.contains(farmId) || farmNames.contains(farmName);
  }

  BatchModel _mapBatch(Map<String, dynamic> doc) {
    final startDate = _dateValue(doc['start_date']);
    final endDate = _dateValue(doc['end_date'], fallback: startDate);
    return BatchModel(
      id: _docId(doc),
      batchNumber: _value(doc, ['batch_no', 'batchNumber'], fallback: 'Batch'),
      farmId: _value(doc, ['farmID', 'farm_id', 'farmId']),
      farmName:
          _value(doc, ['farm_name', 'farmName'], fallback: 'Unassigned Farm'),
      farmManagerId: _value(doc, ['farm_manager_id', 'farmManagerId']),
      farmManagerName: _value(doc, ['farm_manager_name', 'farmManagerName']),
      plantType: _value(doc, ['plant_name', 'plant_type', 'plantType'],
          fallback: 'Plant'),
      startDate: startDate,
      endDate: endDate,
      plantMaturityDays: endDate.difference(startDate).inDays.clamp(0, 999),
      nursedSeeds: _intValue(doc['total_seeds_nursed']),
      transplantedPlants: _intValue(doc['total_transplanted']),
      harvestedHeads: _intValue(doc['total_harvested']),
      harvestedWeight: _doubleValue(doc['total_weight_kg']),
      caretakerId: _value(doc, ['caretaker_id', 'caretakerId']),
      caretakerName: _value(doc, ['caretaker_name', 'caretakerName']),
      createdAt: _dateValue(doc['created_at'], fallback: startDate),
      nurseryDate: startDate,
      harvestDate: _value(doc, ['actual_harvest_date']).isEmpty
          ? null
          : _dateValue(doc['actual_harvest_date']),
      notes: _value(doc, ['technical_issues', 'notes']),
      status: _batchStatusFromBackend(
        _value(doc, ['production_status', 'status'], fallback: 'Planted'),
      ),
    );
  }

  BatchStatus _batchStatusFromBackend(String value) {
    switch (value.toLowerCase().trim()) {
      case 'planted':
      case 'nursery':
        return BatchStatus.nursery;
      case 'growing':
        return BatchStatus.growing;
      case 'harvested':
        return BatchStatus.harvested;
      case 'delivered':
        return BatchStatus.delivered;
      case 'completed':
        return BatchStatus.completed;
      default:
        return BatchStatus.fromString(value);
    }
  }

  ({int value, String unit})? _selectedVarietyDuration() {
    final variety = _selectedPlantVariety;
    if (variety != null && variety.isNotEmpty) {
      for (final crop in _cropVarieties) {
        if (_value(crop, ['variety_name', 'variety', 'name']) == variety) {
          final rawValue = crop['plant_duration_value'];
          final value = rawValue is num
              ? rawValue.toInt()
              : int.tryParse(rawValue?.toString() ?? '') ?? 0;
          final unit =
              (crop['plant_duration_unit'] ?? '').toString().toLowerCase();
          if (value > 0 && (unit == 'days' || unit == 'months')) {
            return (value: value, unit: unit);
          }
        }
      }
    }
    return null;
  }

  DateTime? _calculatedEndDate(DateTime startDate) {
    final duration = _selectedVarietyDuration();
    if (duration == null) return null;
    if (duration.unit != 'months') {
      return startDate.add(Duration(days: duration.value));
    }
    final targetMonth = DateTime(
      startDate.year,
      startDate.month + duration.value,
      1,
    );
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    final targetDay = startDate.day > lastDay ? lastDay : startDate.day;
    return DateTime(targetMonth.year, targetMonth.month, targetDay);
  }

  List<String> get _plantTypeOptions {
    final fromFarms = _farms
        .map((farm) => farm['plantType']?.toString() ?? '')
        .where((name) => name.isNotEmpty);
    final fromTypes = _plantTypes
        .map((plant) => _value(plant, ['plant_name', 'name']))
        .where((name) => name.isNotEmpty);
    final options = <String>{...fromFarms, ...fromTypes}.toList()..sort();
    return options;
  }

  List<String> _varietyOptionsForPlant(String plantType) {
    final options = <String>{};
    for (final crop in _cropVarieties) {
      final cropPlant =
          _value(crop, ['plant_type', 'plant_name', 'plantType', 'crop_name']);
      final variety = _value(crop, ['variety_name', 'variety', 'name']);
      if (variety.isNotEmpty &&
          (cropPlant.isEmpty ||
              cropPlant.toLowerCase() == plantType.toLowerCase())) {
        options.add(variety);
      }
    }
    return options.toList()..sort();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surfaceDark
                  : Colors.white,
              onSurface: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.textPrimary,
            ),
            dialogTheme: DialogThemeData(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.surfaceDark
                    : Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _endDate = _calculatedEndDate(picked);
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _onPlantTypeChanged(String? plantType) {
    setState(() {
      _selectedPlantType = plantType;
      _selectedPlantVariety = null;
      _endDate = null;
    });
  }

  Future<void> _generateBatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select a start date and a crop variety with a valid duration.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final authState = ref.read(authProvider);
      final user = authState.user;
      final farm = _farms.firstWhere((f) => f['id'] == _selectedFarm);
      final farmName = farm['name'].toString();
      final caretaker = _caretakers.firstWhere(
        (c) => c['id'] == _caretakerId,
        orElse: () => {'id': '', 'name': ''},
      );
      final batchNumber = BatchModel.generateBatchNumber(
        farmName,
        _startDate!,
        _endDate!,
      );
      final now = DateTime.now();

      await _api.createBatch(data: {
        'batch_no': batchNumber,
        'farmID': _selectedFarm!,
        'farm_name': farmName,
        'plant_type_ID': farm['plantType']?.toString() ?? '',
        'plant_name': _selectedPlantType!,
        'plant_variety': _selectedPlantVariety!,
        'farm_manager_id': user?.id ?? '',
        'farm_manager_name': user?.name ?? 'Farm Manager',
        'caretaker_id': caretaker['id']?.toString() ?? '',
        'caretaker_name': caretaker['name']?.toString() ?? '',
        'start_date': DateFormat('yyyy-MM-dd').format(_startDate!),
        'end_date': DateFormat('yyyy-MM-dd').format(_endDate!),
        'actual_harvest_date': DateFormat('yyyy-MM-dd').format(_endDate!),
        'total_seeds_nursed': _nursedSeeds,
        'total_harvested': 0,
        'total_transplanted': 0,
        'total_weight_kg': 0,
        'production_status': 'Planted',
        'technical_issues': _notesController.text.trim(),
        'inputs_supplied': 'Seed batch created',
        'funds_requested': false,
        'financial_status': 'Pending',
        'fund_request_id': '',
        'delivery_status': 'Pending',
        'delivery_details': '',
        'created_by': user?.name ?? 'Farm Manager',
        'created_at': DateFormat('yyyy-MM-dd').format(now),
        'updated_at': now.toIso8601String(),
      });

      await _loadBatchData();
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _showForm = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Batch $batchNumber created successfully')),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      );
      _resetForm();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create batch: $error'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _selectedFarm = null;
      _selectedPlantType = null;
      _selectedPlantVariety = null;
      _startDate = null;
      _endDate = null;
      _nursedSeeds = 0;
      _caretakerId = null;
      _notesController.clear();
    });
    _formKey.currentState?.reset();
  }

  List<BatchModel> _getFilteredBatches(List<BatchModel> batches) {
    final query = _searchQuery.trim().toLowerCase();
    return batches.where((batch) {
      if (_selectedBatchFarm != 'All Farms' &&
          batch.farmName != _selectedBatchFarm) {
        return false;
      }
      if (_selectedBatchStatus != 'All Statuses' &&
          batch.status.displayName != _selectedBatchStatus) {
        return false;
      }
      if (_selectedBatchPlant != 'All Plants' &&
          batch.plantType != _selectedBatchPlant) {
        return false;
      }
      if (query.isEmpty) return true;
      return batch.batchNumber.toLowerCase().contains(query) ||
          batch.farmName.toLowerCase().contains(query) ||
          batch.plantType.toLowerCase().contains(query) ||
          (batch.caretakerName ?? '').toLowerCase().contains(query) ||
          batch.status.displayName.toLowerCase().contains(query);
    }).toList();
  }

  List<String> _batchFarmOptions(List<BatchModel> batches) {
    final options = batches.map((batch) => batch.farmName).toSet().toList()
      ..sort();
    return ['All Farms', ...options];
  }

  List<String> _batchStatusOptions(List<BatchModel> batches) {
    final options = batches
        .map((batch) => batch.status.displayName)
        .toSet()
        .toList()
      ..sort();
    return ['All Statuses', ...options];
  }

  List<String> _batchPlantOptions(List<BatchModel> batches) {
    final options = batches.map((batch) => batch.plantType).toSet().toList()
      ..sort();
    return ['All Plants', ...options];
  }

  bool get _hasActiveBatchFilters =>
      _searchQuery.trim().isNotEmpty ||
      _selectedBatchFarm != 'All Farms' ||
      _selectedBatchStatus != 'All Statuses' ||
      _selectedBatchPlant != 'All Plants';

  void _clearBatchFilters() {
    setState(() {
      _searchQuery = '';
      _batchSearchController.clear();
      _selectedBatchFarm = 'All Farms';
      _selectedBatchStatus = 'All Statuses';
      _selectedBatchPlant = 'All Plants';
    });
  }

  Widget _buildBatchFilterDropdown({
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    required bool isDark,
    required IconData icon,
  }) {
    final effectiveValue = options.contains(value) ? value : options.first;
    return DropdownButtonFormField<String>(
      value: effectiveValue,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
      items: options
          .map((option) => DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildFormCard(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
                    offset: const Offset(0, 3))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.75)
                ]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_circle_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create New Batch',
                    style: GoogleFonts.inter(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('Fill in the details to generate a new production batch',
                    style: GoogleFonts.inter(
                        fontSize: isMobile ? 11 : 12,
                        color:
                            isDark ? Colors.white38 : AppColors.textSecondary)),
              ],
            )),
          ]),
          const SizedBox(height: AppSpacing.xl),

          // Form Fields
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Farm and Plant Type Row
                if (!isMobile)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Farm',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            DropdownButtonFormField<String>(
                              value: _selectedFarm,
                              decoration: InputDecoration(
                                hintText: 'Select farm',
                                prefixIcon:
                                    const Icon(Icons.agriculture_outlined),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.black.withOpacity(0.1)
                                    : AppColors.neutral50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: _farms.map((farm) {
                                return DropdownMenuItem(
                                  value: farm['id']?.toString(),
                                  child: Text(farm['name']?.toString() ?? ''),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() {
                                _selectedFarm = value;
                                _selectedPlantType = null;
                                _selectedPlantVariety = null;
                                _endDate = null;
                              }),
                              validator: (value) =>
                                  value == null ? 'Please select a farm' : null,
                              isExpanded: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plant Type',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            DropdownButtonFormField<String>(
                              value: _selectedPlantType,
                              decoration: InputDecoration(
                                hintText: 'Select plant type',
                                prefixIcon: const Icon(Icons.eco_outlined),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.black.withOpacity(0.1)
                                    : AppColors.neutral50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: _plantTypeOptions.map((name) {
                                return DropdownMenuItem(
                                  value: name,
                                  child: Text(name),
                                );
                              }).toList(),
                              onChanged: _onPlantTypeChanged,
                              validator: (value) => value == null
                                  ? 'Please select a plant type'
                                  : null,
                              isExpanded: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  // Mobile: Farm Selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Farm',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      DropdownButtonFormField<String>(
                        value: _selectedFarm,
                        decoration: InputDecoration(
                          hintText: 'Select farm',
                          prefixIcon: const Icon(Icons.agriculture_outlined),
                          filled: true,
                          fillColor: isDark
                              ? Colors.black.withOpacity(0.1)
                              : AppColors.neutral50,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _farms.map((farm) {
                          return DropdownMenuItem(
                            value: farm['id']?.toString(),
                            child: Text(farm['name']?.toString() ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() {
                          _selectedFarm = value;
                          _selectedPlantType = null;
                          _selectedPlantVariety = null;
                          _endDate = null;
                        }),
                        validator: (value) =>
                            value == null ? 'Please select a farm' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Mobile: Plant Type
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plant Type',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      DropdownButtonFormField<String>(
                        value: _selectedPlantType,
                        decoration: InputDecoration(
                          hintText: 'Select plant type',
                          prefixIcon: const Icon(Icons.eco_outlined),
                          filled: true,
                          fillColor: isDark
                              ? Colors.black.withOpacity(0.1)
                              : AppColors.neutral50,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _plantTypeOptions.map((name) {
                          return DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: _onPlantTypeChanged,
                        validator: (value) =>
                            value == null ? 'Please select a plant type' : null,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crop Variety',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonFormField<String>(
                      value: _selectedPlantVariety,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: _selectedPlantType == null
                            ? 'Select plant type first'
                            : 'Select crop variety',
                        prefixIcon: const Icon(Icons.category_outlined),
                        filled: true,
                        fillColor: isDark
                            ? Colors.black.withOpacity(0.1)
                            : AppColors.neutral50,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _selectedPlantType == null
                          ? const []
                          : _varietyOptionsForPlant(_selectedPlantType!)
                              .map((variety) => DropdownMenuItem(
                                    value: variety,
                                    child: Text(variety,
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                      onChanged: _selectedPlantType == null
                          ? null
                          : (value) => setState(() {
                                _selectedPlantVariety = value;
                                if (_startDate != null && value != null) {
                                  _endDate = _calculatedEndDate(_startDate!);
                                } else {
                                  _endDate = null;
                                }
                              }),
                      validator: (value) =>
                          value == null ? 'Please select a crop variety' : null,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Date Selection Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          InkWell(
                            onTap: () => _selectDate(context, true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withOpacity(0.1)
                                    : AppColors.neutral50,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.transparent
                                      : AppColors.neutral200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.6)
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      _startDate != null
                                          ? DateFormat('MMM dd, yyyy')
                                              .format(_startDate!)
                                          : 'Select start date',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: _startDate != null
                                            ? (isDark
                                                ? Colors.white
                                                : AppColors.textPrimary)
                                            : (isDark
                                                ? Colors.white.withOpacity(0.5)
                                                : AppColors.textSecondary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End Date (Auto)',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withOpacity(0.1)
                                    : AppColors.neutral50,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.transparent
                                      : AppColors.neutral200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.event_available_outlined,
                                    size: 18,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.6)
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      _endDate != null
                                          ? DateFormat('MMM dd, yyyy')
                                              .format(_endDate!)
                                          : 'Auto-calculated',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: _endDate != null
                                            ? AppColors.success
                                            : (isDark
                                                ? Colors.white.withOpacity(0.5)
                                                : AppColors.textSecondary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Builder(
                  builder: (context) {
                    final duration = _selectedVarietyDuration();
                    final available = duration != null;
                    final durationLabel = duration == null
                        ? null
                        : '${duration.value} ${duration.unit}';
                    return Row(
                      children: [
                        Icon(
                          available
                              ? Icons.auto_awesome_outlined
                              : Icons.info_outline_rounded,
                          size: 14,
                          color:
                              available ? AppColors.success : AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            available
                                ? 'Calculated from $durationLabel'
                                : 'Select a crop variety with a valid duration.',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: available
                                  ? (isDark
                                      ? Colors.white60
                                      : AppColors.textSecondary)
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Nursed Seeds and Caretaker Row
                if (!isMobile)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Number of Seeds',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextFormField(
                              initialValue: _nursedSeeds == 0
                                  ? ''
                                  : _nursedSeeds.toString(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Enter number',
                                prefixIcon: const Icon(Icons.spa_outlined),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.black.withOpacity(0.1)
                                    : AppColors.neutral50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _nursedSeeds = int.tryParse(value) ?? 0;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter number of seeds';
                                }
                                final number = int.tryParse(value);
                                if (number == null || number <= 0) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Caretaker (Optional)',
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            DropdownButtonFormField<String>(
                              value: _caretakerId,
                              decoration: InputDecoration(
                                hintText: 'Select caretaker',
                                prefixIcon: const Icon(Icons.person_outline),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.black.withOpacity(0.1)
                                    : AppColors.neutral50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: _caretakers.map((caretaker) {
                                return DropdownMenuItem<String>(
                                  value: caretaker['id']?.toString(),
                                  child:
                                      Text(caretaker['name']?.toString() ?? ''),
                                );
                              }).toList(),
                              onChanged: (value) =>
                                  setState(() => _caretakerId = value),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  // Mobile: Nursed Seeds
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Number of Seeds',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        initialValue:
                            _nursedSeeds == 0 ? '' : _nursedSeeds.toString(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter number',
                          prefixIcon: const Icon(Icons.spa_outlined),
                          filled: true,
                          fillColor: isDark
                              ? Colors.black.withOpacity(0.1)
                              : AppColors.neutral50,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _nursedSeeds = int.tryParse(value) ?? 0;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter number of seeds';
                          }
                          final number = int.tryParse(value);
                          if (number == null || number <= 0) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Mobile: Caretaker
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Caretaker (Optional)',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      DropdownButtonFormField<String>(
                        value: _caretakerId,
                        decoration: InputDecoration(
                          hintText: 'Select caretaker',
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: isDark
                              ? Colors.black.withOpacity(0.1)
                              : AppColors.neutral50,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _caretakers.map((caretaker) {
                          return DropdownMenuItem<String>(
                            value: caretaker['id']?.toString(),
                            child: Text(caretaker['name']?.toString() ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _caretakerId = value),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),

                // Notes
                Text(
                  'Notes (Optional)',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add any additional notes...',
                    prefixIcon: const Icon(Icons.note_outlined),
                    filled: true,
                    fillColor: isDark
                        ? Colors.black.withOpacity(0.1)
                        : AppColors.neutral50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetForm,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.2)
                                : AppColors.neutral300,
                          ),
                        ),
                        child: Text(
                          'Clear Form',
                          style: AppTypography.button.copyWith(
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isGenerating ? null : _generateBatch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          elevation: 2,
                          shadowColor: AppColors.primary.withOpacity(0.3),
                        ),
                        child: _isGenerating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add, size: 20),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Generate Batch',
                                    style: AppTypography.button.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchStatsOverview(bool isDark, List<BatchModel> batches) {
    final activeBatches = batches.where((b) => b.isActive).length;
    final totalSeeds = batches.fold<int>(0, (sum, b) => sum + b.nursedSeeds);
    final totalTransplanted =
        batches.fold<int>(0, (sum, b) => sum + b.transplantedPlants);
    final totalHarvested =
        batches.fold<int>(0, (sum, b) => sum + b.harvestedHeads);
    final avgSurvivalRate = batches.isEmpty
        ? 0.0
        : batches.fold<double>(0, (sum, b) => sum + b.survivalRate) /
            batches.length;

    final stats = [
      {
        'title': 'Active Batches',
        'value': activeBatches.toString(),
        'icon': Icons.grid_view_outlined,
        'color': AppColors.primary,
      },
      {
        'title': 'Total Seeds',
        'value': totalSeeds.toString(),
        'icon': Icons.spa_outlined,
        'color': AppColors.info,
      },
      {
        'title': 'Transplanted',
        'value': totalTransplanted.toString(),
        'icon': Icons.eco_outlined,
        'color': AppColors.success,
      },
      {
        'title': 'Harvested',
        'value': totalHarvested.toString(),
        'icon': Icons.agriculture_outlined,
        'color': AppColors.warning,
      },
      {
        'title': 'Avg Survival',
        'value': '${avgSurvivalRate.toStringAsFixed(1)}%',
        'icon': Icons.trending_up_outlined,
        'color': AppColors.success,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 768;
        final isTablet = screenWidth < 1024 && screenWidth >= 768;

        int crossAxisCount;
        double childAspectRatio;
        double padding;
        double spacing;

        if (isMobile) {
          crossAxisCount = 2;
          childAspectRatio = 1.6; // Slightly taller for better readability
          padding = AppSpacing.sm; // Add small padding for better spacing
          spacing = AppSpacing.xs; // Tighter spacing between cards
        } else if (isTablet) {
          crossAxisCount = 3;
          childAspectRatio = 2.0;
          padding = AppSpacing.lg;
          spacing = AppSpacing.md;
        } else {
          crossAxisCount = 5;
          childAspectRatio = 2.2;
          padding = AppSpacing.lg;
          spacing = AppSpacing.md;
        }

        return Container(
          padding: EdgeInsets.all(padding),
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
                        offset: const Offset(0, 3))
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9)),
                    child: Icon(Icons.insights_rounded,
                        color: AppColors.primary, size: isMobile ? 16 : 18),
                  ),
                  SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),
                  Text(
                    'Batch Overview',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: isMobile ? 15 : 17,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.lg),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  final stat = stats[index];
                  return _buildBatchStatCard(stat, isDark, isMobile);
                },
              ),
              // Add bottom padding for mobile to match spacing
              if (isMobile) SizedBox(height: AppSpacing.xs),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBatchStatCard(Map<String, dynamic> stat, bool isDark,
      [bool isMobile = false]) {
    final color = stat['color'] as Color;
    return LayoutBuilder(builder: (context, box) {
      final compact = box.maxWidth < 140;
      return Container(
        padding: EdgeInsets.all(compact ? 8 : 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(isDark ? 0.15 : 0.12)),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                      color: color.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 5 : 7),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(stat['icon'] as IconData,
                  color: color, size: compact ? 14 : 16),
            ),
            const Spacer(),
            Text(stat['value'] as String,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: compact ? 18 : 22,
                    height: 1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            SizedBox(height: compact ? 2 : 4),
            Text(stat['title'] as String,
                style: GoogleFonts.inter(
                    color: isDark ? Colors.white38 : AppColors.textSecondary,
                    fontSize: compact ? 10 : 11,
                    height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );
    });
  }

  // ============================================
  // PROFESSIONAL BATCHES TABLE & CARDS
  // ============================================

  Widget _buildBatchesTable(
      bool isDark, bool isMobile, List<BatchModel> batches) {
    if (isMobile) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: batches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _buildBatchCard(batches[index], isDark),
      );
    }

    // Desktop: professional data table with custom styling
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
              border: Border(
                  bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.06))),
            ),
            child: Row(children: [
              _thCell('Batch No.', flex: 2, isDark: isDark),
              _thCell('Farm', flex: 2, isDark: isDark),
              _thCell('Crop', flex: 1, isDark: isDark),
              _thCell('Status', flex: 1, isDark: isDark),
              _thCell('Pipeline', flex: 3, isDark: isDark),
              _thCell('Progress', flex: 1, isDark: isDark),
              _thCell('Started', flex: 2, isDark: isDark),
              _thCell('', flex: 1, isDark: isDark), // Actions
            ]),
          ),
          // Table rows
          ...batches.asMap().entries.map((entry) {
            final i = entry.key;
            final batch = entry.value;
            final isEven = i % 2 == 0;
            return _buildTableRow(batch, isDark, isEven);
          }),
        ],
      ),
    );
  }

  Widget _thCell(String label, {required int flex, required bool isDark}) {
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

  Widget _buildTableRow(BatchModel batch, bool isDark, bool isEven) {
    final pct = batch.progressPercentage;
    final pctColor = pct >= 75
        ? AppColors.success
        : (pct >= 40 ? AppColors.warning : AppColors.info);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _viewBatchDetails(batch),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isEven
                ? (isDark ? Colors.transparent : Colors.transparent)
                : (isDark
                    ? Colors.white.withOpacity(0.02)
                    : AppColors.neutral50.withOpacity(0.5)),
            border: Border(
                bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.black.withOpacity(0.04))),
          ),
          child: Row(children: [
            // Batch No.
            Expanded(
              flex: 2,
              child: Row(children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                  batch.batchNumber,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )),
              ]),
            ),
            // Farm
            Expanded(
              flex: 2,
              child: Text(batch.farmName,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            // Crop
            Expanded(
              flex: 1,
              child: Row(children: [
                Icon(Icons.eco_rounded,
                    size: 13, color: AppColors.success.withOpacity(0.7)),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(batch.plantType,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white70
                                : AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              ]),
            ),
            // Status
            Expanded(flex: 1, child: StatusBadge(status: batch.status)),
            // Pipeline (N → T → H)
            Expanded(
              flex: 3,
              child: _buildPipeline(batch, isDark),
            ),
            // Progress %
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: pctColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${pct.toStringAsFixed(0)}%',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pctColor),
                ),
              ),
            ),
            // Start Date
            Expanded(
              flex: 2,
              child: Text(
                DateFormat('MMM dd, yyyy').format(batch.startDate),
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppColors.textSecondary),
              ),
            ),
            // Actions
            Expanded(
              flex: 1,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                _actionIcon(Icons.visibility_outlined, 'View',
                    () => _viewBatchDetails(batch), isDark),
                const SizedBox(width: 4),
                _actionIcon(Icons.edit_outlined, 'Edit',
                    () => _editBatch(batch), isDark),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _actionIcon(
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
              color: isDark ? Colors.white54 : AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildPipeline(BatchModel batch, bool isDark) {
    final stages = [
      {
        'label': 'Nursed',
        'value': batch.nursedSeeds,
        'color': AppColors.info,
        'icon': Icons.spa_rounded
      },
      {
        'label': 'Transplanted',
        'value': batch.transplantedPlants,
        'color': AppColors.success,
        'icon': Icons.eco_rounded
      },
      {
        'label': 'Harvested',
        'value': batch.harvestedHeads,
        'color': AppColors.warning,
        'icon': Icons.agriculture_rounded
      },
    ];

    return Row(children: [
      ...stages.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        final value = s['value'] as int;
        final color = s['color'] as Color;
        final isActive = value > 0;
        final isLast = i == stages.length - 1;

        return Expanded(
            child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isActive
                  ? color.withOpacity(0.1)
                  : (isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.black.withOpacity(0.03)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(s['icon'] as IconData,
                  size: 10,
                  color: isActive
                      ? color
                      : (isDark ? Colors.white24 : AppColors.neutral400)),
              const SizedBox(width: 3),
              Text(
                '$value',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? color
                        : (isDark ? Colors.white24 : AppColors.neutral400)),
              ),
            ]),
          ),
          if (!isLast)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 8,
                  color: isDark ? Colors.white12 : AppColors.neutral300),
            ),
        ]));
      }),
    ]);
  }

  // ============================================
  // MOBILE BATCH CARD — PROFESSIONAL DESIGN
  // ============================================

  Widget _buildBatchCard(BatchModel batch, bool isDark) {
    final pct = batch.progressPercentage;
    final pctColor = pct >= 75
        ? AppColors.success
        : (pct >= 40 ? AppColors.warning : AppColors.info);

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
                    offset: const Offset(0, 2))
              ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.75)
              ]),
              borderRadius: BorderRadius.circular(9),
            ),
            child:
                const Icon(Icons.layers_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(batch.batchNumber,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 1),
              Row(children: [
                Icon(Icons.location_on_outlined,
                    size: 11,
                    color: isDark ? Colors.white38 : AppColors.textSecondary),
                const SizedBox(width: 3),
                Expanded(
                    child: Text(batch.farmName,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white38
                                : AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              ]),
            ],
          )),
          StatusBadge(status: batch.status),
        ]),

        const SizedBox(height: 14),

        // Pipeline visual
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            // Pipeline stages
            Row(children: [
              _mobilePipelineStage('Nursed', batch.nursedSeeds, AppColors.info,
                  Icons.spa_rounded, isDark),
              _mobilePipelineArrow(isDark),
              _mobilePipelineStage('Transplant', batch.transplantedPlants,
                  AppColors.success, Icons.eco_rounded, isDark),
              _mobilePipelineArrow(isDark),
              _mobilePipelineStage('Harvest', batch.harvestedHeads,
                  AppColors.warning, Icons.agriculture_rounded, isDark),
            ]),
            const SizedBox(height: 10),
            // Progress bar
            Row(children: [
              Expanded(
                  child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                  minHeight: 5,
                ),
              )),
              const SizedBox(width: 8),
              Text('${pct.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pctColor)),
            ]),
          ]),
        ),

        const SizedBox(height: 12),

        // Details row
        Row(children: [
          _mobileDetail(Icons.eco_outlined, batch.plantType, isDark),
          const SizedBox(width: 10),
          _mobileDetail(Icons.calendar_today_rounded,
              DateFormat('MMM dd').format(batch.startDate), isDark),
          const SizedBox(width: 10),
          _mobileDetail(Icons.trending_up_rounded,
              '${batch.survivalRate.toStringAsFixed(0)}%', isDark),
        ]),

        if (batch.caretakerName != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.person_outline_rounded,
                size: 12,
                color: isDark ? Colors.white24 : AppColors.textSecondary),
            const SizedBox(width: 4),
            Expanded(
                child: Text(batch.caretakerName!,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color:
                            isDark ? Colors.white38 : AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          ]),
        ],

        const SizedBox(height: 12),

        // Action buttons
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
            onPressed: () => _viewBatchDetails(batch),
            icon: const Icon(Icons.visibility_outlined, size: 14),
            label: Text('View',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w500)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 7),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
              side: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08)),
            ),
          )),
          const SizedBox(width: 8),
          Expanded(
              child: ElevatedButton.icon(
            onPressed: () => _editBatch(batch),
            icon: const Icon(Icons.edit_outlined, size: 14),
            label: Text('Edit',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 7),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
            ),
          )),
        ]),
      ]),
    );
  }

  Widget _mobilePipelineStage(
      String label, int value, Color color, IconData icon, bool isDark) {
    final isActive = value > 0;
    return Expanded(
        child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isActive
                  ? color.withOpacity(0.2)
                  : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06))),
        ),
        child: Column(children: [
          Icon(icon,
              size: 14,
              color: isActive
                  ? color
                  : (isDark ? Colors.white24 : AppColors.neutral400)),
          const SizedBox(height: 2),
          Text('$value',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? color
                      : (isDark ? Colors.white24 : AppColors.neutral400))),
        ]),
      ),
      const SizedBox(height: 3),
      Text(label,
          style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : AppColors.textSecondary)),
    ]));
  }

  Widget _mobilePipelineArrow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Icon(Icons.chevron_right_rounded,
          size: 16, color: isDark ? Colors.white12 : AppColors.neutral300),
    );
  }

  Widget _mobileDetail(IconData icon, String text, bool isDark) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon,
          size: 12, color: isDark ? Colors.white24 : AppColors.textSecondary),
      const SizedBox(width: 4),
      Text(text,
          style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark ? Colors.white54 : AppColors.textSecondary)),
    ]);
  }

  TextStyle _tableHeaderStyle(bool isDark) {
    return GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: isDark ? Colors.white54 : AppColors.textSecondary,
    );
  }

  TextStyle _tableCellStyle(bool isDark, {bool isBold = false, Color? color}) {
    return GoogleFonts.inter(
      fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
      fontSize: 13,
      color: color ??
          (isDark ? Colors.white.withOpacity(0.9) : AppColors.textPrimary),
    );
  }

  void _viewBatchDetails(BatchModel batch) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = batch.progressPercentage;
    final pctColor = pct >= 75
        ? AppColors.success
        : (pct >= 40 ? AppColors.warning : AppColors.info);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.75)
                        ]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.layers_rounded,
                          size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(batch.batchNumber,
                            style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary)),
                        Text(batch.farmName,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white38
                                    : AppColors.textSecondary)),
                      ],
                    )),
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
                  ]),
                  const SizedBox(height: 20),

                  // Progress section
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.03)
                          : AppColors.neutral50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Overall Progress',
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white54
                                        : AppColors.textSecondary)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: pctColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text('${pct.toStringAsFixed(0)}%',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: pctColor)),
                            ),
                          ]),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                            value: pct / 100,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.black.withOpacity(0.06),
                            valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                            minHeight: 6),
                      ),
                      const SizedBox(height: 14),
                      Row(children: [
                        _dialogMetric('Nursed', batch.nursedSeeds.toString(),
                            AppColors.info, isDark),
                        const SizedBox(width: 8),
                        _dialogMetric(
                            'Transplanted',
                            batch.transplantedPlants.toString(),
                            AppColors.success,
                            isDark),
                        const SizedBox(width: 8),
                        _dialogMetric(
                            'Harvested',
                            batch.harvestedHeads.toString(),
                            AppColors.warning,
                            isDark),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Detail rows
                  _buildDetailRow('Plant Type', batch.plantType,
                      Icons.eco_outlined, isDark),
                  _buildDetailRow(
                      'Status',
                      batch.status.toString().split('.').last,
                      Icons.flag_outlined,
                      isDark),
                  _buildDetailRow(
                      'Start Date',
                      DateFormat('MMM dd, yyyy').format(batch.startDate),
                      Icons.calendar_today_outlined,
                      isDark),
                  _buildDetailRow(
                      'End Date',
                      DateFormat('MMM dd, yyyy').format(batch.endDate),
                      Icons.event_available_outlined,
                      isDark),
                  _buildDetailRow(
                      'Survival Rate',
                      '${batch.survivalRate.toStringAsFixed(1)}%',
                      Icons.trending_up_rounded,
                      isDark),
                  if (batch.caretakerName != null)
                    _buildDetailRow('Caretaker', batch.caretakerName!,
                        Icons.person_outline_rounded, isDark),

                  if (batch.notes != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.03)
                            : AppColors.neutral50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.black.withOpacity(0.04)),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Notes',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white38
                                        : AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(batch.notes!,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white70
                                        : AppColors.textPrimary,
                                    height: 1.5)),
                          ]),
                    ),
                  ],

                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                        child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.08)),
                      ),
                      child: Text('Close',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    )),
                    const SizedBox(width: 8),
                    Expanded(
                        child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _editBatch(batch);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: Text('Edit Batch',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    )),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogMetric(String label, String value, Color color, bool isDark) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(children: [
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white38 : AppColors.textSecondary)),
      ]),
    ));
  }

  Widget _buildDetailRow(
      String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon,
            size: 14, color: isDark ? Colors.white24 : AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white38 : AppColors.textSecondary)),
        ),
        Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary))),
      ]),
    );
  }

  void _editBatch(BatchModel batch) {
    // Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit functionality for ${batch.batchNumber}'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Widget _buildLoadingOrError(bool isDark) {
    if (_isLoadingData) {
      return const AdminDataSkeleton(rowCount: 6);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Could not load batches',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _loadError ?? 'The batch service did not return data.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _loadBatchData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final authState = ref.watch(authProvider);
    final batches = ref.watch(batchProvider);
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
              onItemSelected: (i) => setState(() => _selectedNavIndex = i),
              userName: userName,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName, batches)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole, batches),
      bottomNavigationBar: isMobile
          ? FarmManagerMobileBottomNav(
              selectedIndex: 4,
              onItemSelected: (_) {},
            )
          : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail,
      String userRole, List<BatchModel> batches) {
    final filteredBatches = _getFilteredBatches(batches);
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
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: (_isLoadingData || _loadError != null)
                      ? _buildLoadingOrError(isDark)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with Toggle
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Batch Management & Tracking',
                                        style: AppTypography.h4.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      Text(
                                        'Create batches and track progress from seedlings to harvest',
                                        style: AppTypography.bodyLarge.copyWith(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.7)
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!_showForm)
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        setState(() => _showForm = true),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Create Batch'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                        vertical: AppSpacing.md,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusFull),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            if (_showForm) ...[
                              // Form View (Secondary)
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: () =>
                                        setState(() => _showForm = false),
                                    tooltip: 'Back to Batches',
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Create New Batch',
                                    style: AppTypography.h5.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _buildFormCard(isDark, false),
                            ] else ...[
                              // Batch Tracking View (Primary)
                              // Batch Stats Overview
                              _buildBatchStatsOverview(isDark, batches),
                              const SizedBox(height: AppSpacing.xl),

                              // Batches Table Section
                              Container(
                                padding: const EdgeInsets.all(0),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.surfaceDark
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.06)
                                          : Colors.black.withOpacity(0.06)),
                                  boxShadow: isDark
                                      ? null
                                      : [
                                          BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.04),
                                              blurRadius: 12,
                                              offset: const Offset(0, 3))
                                        ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Search & Actions bar
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 16, 16, 0),
                                      child: Row(children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(9),
                                          ),
                                          child: Icon(Icons.table_chart_rounded,
                                              size: 18,
                                              color: AppColors.primary),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Text('Batch Tracking',
                                                style: GoogleFonts.inter(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark
                                                        ? Colors.white
                                                        : AppColors
                                                            .textPrimary))),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                              '${filteredBatches.length}/${batches.length} batches',
                                              style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primary)),
                                        ),
                                      ]),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _batchSearchController,
                                            onChanged: (value) => setState(
                                                () => _searchQuery = value),
                                            style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors.textPrimary),
                                            decoration: InputDecoration(
                                              hintText: 'Search batches...',
                                              hintStyle: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: isDark
                                                      ? Colors.white24
                                                      : AppColors
                                                          .textSecondary),
                                              prefixIcon: Icon(
                                                  Icons.search_rounded,
                                                  size: 18,
                                                  color: isDark
                                                      ? Colors.white24
                                                      : AppColors
                                                          .textSecondary),
                                              filled: true,
                                              fillColor: isDark
                                                  ? Colors.white
                                                      .withOpacity(0.04)
                                                  : AppColors.neutral50,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                      horizontal: 14),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: BorderSide(
                                                    color: isDark
                                                        ? Colors.white
                                                            .withOpacity(0.06)
                                                        : Colors.black
                                                            .withOpacity(0.06)),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: BorderSide(
                                                    color: isDark
                                                        ? Colors.white
                                                            .withOpacity(0.06)
                                                        : Colors.black
                                                            .withOpacity(0.06)),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: BorderSide(
                                                    color: AppColors.primary,
                                                    width: 1.5),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton.icon(
                                          onPressed: () =>
                                              setState(() => _showForm = true),
                                          icon: const Icon(Icons.add_rounded,
                                              size: 16),
                                          label: Text('New Batch',
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
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ]),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 16, 16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _buildBatchFilterDropdown(
                                              value: _selectedBatchFarm,
                                              options:
                                                  _batchFarmOptions(batches),
                                              onChanged: (value) => setState(
                                                  () => _selectedBatchFarm =
                                                      value ?? 'All Farms'),
                                              isDark: isDark,
                                              icon: Icons.agriculture_outlined,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _buildBatchFilterDropdown(
                                              value: _selectedBatchStatus,
                                              options:
                                                  _batchStatusOptions(batches),
                                              onChanged: (value) => setState(
                                                  () => _selectedBatchStatus =
                                                      value ?? 'All Statuses'),
                                              isDark: isDark,
                                              icon: Icons.flag_outlined,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _buildBatchFilterDropdown(
                                              value: _selectedBatchPlant,
                                              options:
                                                  _batchPlantOptions(batches),
                                              onChanged: (value) => setState(
                                                  () => _selectedBatchPlant =
                                                      value ?? 'All Plants'),
                                              isDark: isDark,
                                              icon: Icons.eco_outlined,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          OutlinedButton.icon(
                                            onPressed: _hasActiveBatchFilters
                                                ? _clearBatchFilters
                                                : null,
                                            icon: const Icon(
                                                Icons.filter_alt_off_rounded,
                                                size: 16),
                                            label: const Text('Clear'),
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 15),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (filteredBatches.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(40),
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withOpacity(0.06),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                    Icons.layers_outlined,
                                                    size: 40,
                                                    color: AppColors.primary
                                                        .withOpacity(0.4)),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                  _hasActiveBatchFilters
                                                      ? 'No batches match your filters'
                                                      : 'No batches created yet',
                                                  style: GoogleFonts.inter(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isDark
                                                          ? Colors.white54
                                                          : AppColors
                                                              .textSecondary)),
                                              const SizedBox(height: 4),
                                              Text(
                                                  _hasActiveBatchFilters
                                                      ? 'Adjust or clear the filters to see more batches'
                                                      : 'Create your first batch to get started',
                                                  style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: isDark
                                                          ? Colors.white24
                                                          : AppColors
                                                              .textSecondary)),
                                              const SizedBox(height: 16),
                                              ElevatedButton.icon(
                                                onPressed: () => setState(
                                                    () => _showForm = true),
                                                icon: const Icon(
                                                    Icons.add_rounded,
                                                    size: 16),
                                                label: Text(
                                                    'Create First Batch',
                                                    style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.primary,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      _buildBatchesTable(
                                          isDark, false, filteredBatches),
                                  ],
                                ),
                              ),
                            ],
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

  Widget _buildMobileLayout(
      bool isDark, String userName, List<BatchModel> batches) {
    final filteredBatches = _getFilteredBatches(batches);
    return Column(
      children: [
        FarmManagerHeader(
          userName: userName,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        if (_isLoadingData || _loadError != null)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _buildLoadingOrError(isDark),
            ),
          )
        else if (_showForm) ...[
          // Mobile Form View (Secondary)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _showForm = false),
                  tooltip: 'Back to Batches',
                ),
                Expanded(
                  child: Text(
                    'Create New Batch',
                    style: AppTypography.h6.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _buildFormCard(isDark, true),
            ),
          ),
        ] else ...[
          // Mobile Batches View (Primary) - All content scrolls together
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Batch Stats Overview
                  _buildBatchStatsOverview(isDark, batches),
                  const SizedBox(height: AppSpacing.md),

                  // Batches List Header
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.06)),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ],
                    ),
                    child: Column(children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.table_chart_rounded,
                              size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text('All Batches',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary))),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(
                              '${filteredBatches.length}/${batches.length}',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 15),
                          label: Text('New',
                              style: GoogleFonts.inter(
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                          onPressed: () => setState(() => _showForm = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9)),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      // Mobile search
                      TextField(
                        controller: _batchSearchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search batches...',
                          hintStyle: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white24
                                  : AppColors.textSecondary),
                          prefixIcon: Icon(Icons.search_rounded,
                              size: 16,
                              color: isDark
                                  ? Colors.white24
                                  : AppColors.textSecondary),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.04)
                              : AppColors.neutral50,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9),
                              borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9),
                              borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.06)
                                      : Colors.black.withOpacity(0.06))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9),
                              borderSide: BorderSide(
                                  color: AppColors.primary, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildBatchFilterDropdown(
                        value: _selectedBatchFarm,
                        options: _batchFarmOptions(batches),
                        onChanged: (value) => setState(
                            () => _selectedBatchFarm = value ?? 'All Farms'),
                        isDark: isDark,
                        icon: Icons.agriculture_outlined,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildBatchFilterDropdown(
                              value: _selectedBatchStatus,
                              options: _batchStatusOptions(batches),
                              onChanged: (value) => setState(() =>
                                  _selectedBatchStatus =
                                      value ?? 'All Statuses'),
                              isDark: isDark,
                              icon: Icons.flag_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildBatchFilterDropdown(
                              value: _selectedBatchPlant,
                              options: _batchPlantOptions(batches),
                              onChanged: (value) => setState(() =>
                                  _selectedBatchPlant = value ?? 'All Plants'),
                              isDark: isDark,
                              icon: Icons.eco_outlined,
                            ),
                          ),
                        ],
                      ),
                      if (_hasActiveBatchFilters) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _clearBatchFilters,
                            icon: const Icon(Icons.filter_alt_off_rounded,
                                size: 16),
                            label: const Text('Clear filters'),
                          ),
                        ),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // Batches Table
                  if (filteredBatches.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text(
                          _hasActiveBatchFilters
                              ? 'No batches match your filters'
                              : 'No batches created yet',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white54
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    _buildBatchesTable(isDark, true, filteredBatches),
                ],
              ),
            ),
          ),
        ],
      ],
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
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color:
                isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral100,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final index = item['index'] as int;
              const isSelected = false; // Batches is not in bottom nav

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_selectedNavIndex != index) {
                        setState(() => _selectedNavIndex = index);
                        try {
                          Navigator.pushReplacementNamed(
                              context, item['route'] as String);
                        } catch (e) {
                          debugPrint('Navigation error: $e');
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
}
