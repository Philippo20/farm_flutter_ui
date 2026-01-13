import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/models/batch/batch_model.dart';
import '../../core/providers/batch_provider.dart';
import '../../core/widgets/farm_manager_sidebar.dart';
import '../../core/widgets/farm_manager_header.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/status_badge.dart';

/// Batch Management & Tracking Screen
/// Farm Manager can generate new batches and track their progress
class BatchGenerationScreen extends ConsumerStatefulWidget {
  const BatchGenerationScreen({super.key});

  @override
  ConsumerState<BatchGenerationScreen> createState() => _BatchGenerationScreenState();
}

class _BatchGenerationScreenState extends ConsumerState<BatchGenerationScreen> {
  final _formKey = GlobalKey<FormState>();
  int _selectedNavIndex = 2;
  final _scrollController = ScrollController();

  // Form controllers
  String? _selectedFarm;
  String? _selectedPlantType;
  DateTime? _startDate;
  DateTime? _endDate;
  int _nursedSeeds = 0;
  String? _caretakerId;
  final _notesController = TextEditingController();

  bool _isGenerating = false;
  bool _showForm = false; // Default to tracking view (table/cards)
  String _searchQuery = '';

  // Demo data
  final List<Map<String, String>> _farms = [
    {'id': 'FARM001', 'name': 'Green Valley Farm'},
    {'id': 'FARM002', 'name': 'Sunny Acres'},
    {'id': 'FARM003', 'name': 'Fresh Farms'},
    {'id': 'FARM004', 'name': 'Urban Greens'},
    {'id': 'FARM005', 'name': 'Hydro Haven'},
  ];

  final List<Map<String, String>> _caretakers = [
    {'id': 'CT001', 'name': 'Bob Caretaker'},
    {'id': 'CT002', 'name': 'Jane Smith'},
    {'id': 'CT003', 'name': 'Mike Johnson'},
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    _notesController.dispose();
    super.dispose();
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
          // Auto-calculate end date if plant type is selected
          if (_selectedPlantType != null) {
            final plant = PlantType.getByName(_selectedPlantType!);
            if (plant != null) {
              _endDate = _startDate!.add(Duration(days: plant.maturityDays));
            }
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _onPlantTypeChanged(String? plantType) {
    setState(() {
      _selectedPlantType = plantType;
      // Auto-calculate end date if start date is set
      if (_startDate != null && plantType != null) {
        final plant = PlantType.getByName(plantType);
        if (plant != null) {
          _endDate = _startDate!.add(Duration(days: plant.maturityDays));
        }
      }
    });
  }

  Future<void> _generateBatch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGenerating = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    final authState = ref.read(authProvider);
    final user = authState.user;
    final farmName = _farms.firstWhere((f) => f['id'] == _selectedFarm)['name']!;

    // Generate batch number
    final batchNumber = BatchModel.generateBatchNumber(
      farmName,
      _startDate!,
      _endDate!,
    );

    final plant = PlantType.getByName(_selectedPlantType!)!;

    // Create batch
    final batch = BatchModel(
      id: 'BATCH_${DateTime.now().millisecondsSinceEpoch}',
      batchNumber: batchNumber,
      farmId: _selectedFarm!,
      farmName: farmName,
      farmManagerId: user!.id,
      farmManagerName: user.name,
      plantType: _selectedPlantType!,
      startDate: _startDate!,
      endDate: _endDate!,
      plantMaturityDays: plant.maturityDays,
      nursedSeeds: _nursedSeeds,
      transplantedPlants: 0, // Will be updated when transplanted
      harvestedHeads: 0, // Will be updated when harvested
      harvestedWeight: 0.0, // Will be updated when harvested
      caretakerId: _caretakerId,
      caretakerName: _caretakers.firstWhere((c) => c['id'] == _caretakerId,
          orElse: () => {'name': ''})['name'],
      createdAt: DateTime.now(),
      nurseryDate: DateTime.now(),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      status: BatchStatus.nursery,
    );

    // Save to provider
    ref.read(batchProvider.notifier).addBatch(batch);

    setState(() {
      _isGenerating = false;
      _showForm = false; // Switch to table view
    });

    // Show success notification
    if (mounted) {
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
    }
  }

  void _resetForm() {
    setState(() {
      _selectedFarm = null;
      _selectedPlantType = null;
      _startDate = null;
      _endDate = null;
      _nursedSeeds = 0;
      _caretakerId = null;
      _notesController.clear();
    });
    _formKey.currentState?.reset();
  }

  Widget _buildFormCard(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Batch',
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Fill in the details to generate a new production batch',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                                fillColor:
                                    isDark ? Colors.black.withOpacity(0.1) : AppColors.neutral50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: _farms.map((farm) {
                                return DropdownMenuItem(
                                  value: farm['id'],
                                  child: Text(farm['name']!),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _selectedFarm = value),
                              validator: (value) => value == null ? 'Please select a farm' : null,
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
                                fillColor:
                                    isDark ? Colors.black.withOpacity(0.1) : AppColors.neutral50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: PlantType.allNames.map((name) {
                                final plant = PlantType.getByName(name)!;
                                return DropdownMenuItem(
                                  value: name,
                                  child: Text('$name (${plant.maturityDays} days)'),
                                );
                              }).toList(),
                              onChanged: _onPlantTypeChanged,
                              validator: (value) =>
                                  value == null ? 'Please select a plant type' : null,
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
                          fillColor: isDark ? Colors.black.withOpacity(0.1) : AppColors.neutral50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _farms.map((farm) {
                          return DropdownMenuItem(
                            value: farm['id'],
                            child: Text(farm['name']!),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedFarm = value),
                        validator: (value) => value == null ? 'Please select a farm' : null,
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
                          fillColor: isDark ? Colors.black.withOpacity(0.1) : AppColors.neutral50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: PlantType.allNames.map((name) {
                          final plant = PlantType.getByName(name)!;
                          return DropdownMenuItem(
                            value: name,
                            child: Text('$name (${plant.maturityDays} days)'),
                          );
                        }).toList(),
                        onChanged: _onPlantTypeChanged,
                        validator: (value) => value == null ? 'Please select a plant type' : null,
                      ),
                    ],
                  ),
                ],
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
                              color: isDark ? Colors.white : AppColors.textPrimary,
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
                                color: isDark ? Colors.black.withOpacity(0.1) : AppColors.neutral50,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(
                                  color: isDark ? Colors.transparent : AppColors.neutral200,
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
                                          ? DateFormat('MMM dd, yyyy').format(_startDate!)
                                          : 'Select start date',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: _startDate != null
                                            ? (isDark ? Colors.white : AppColors.textPrimary)
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
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          'End Date',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withOpacity(0.1) : AppColors.neutral50,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: isDark ? Colors.transparent : AppColors.neutral200,
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
                                      ? DateFormat('MMM dd, yyyy').format(_endDate!)
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
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextFormField(
                              initialValue: _nursedSeeds == 0 ? '' : _nursedSeeds.toString(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Enter number',
                                prefixIcon: const Icon(Icons.spa_outlined),
                                filled: true,
                                fillColor:
                                    isDark ? Colors.black.withOpacity(0.1) : AppColors.neutral50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                                fillColor:
                                    isDark ? Colors.black.withOpacity(0.1) : AppColors.neutral50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: _caretakers.map((caretaker) {
                                return DropdownMenuItem(
                                  value: caretaker['id'],
                                  child: Text(caretaker['name']!),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _caretakerId = value),
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
                        initialValue: _nursedSeeds == 0 ? '' : _nursedSeeds.toString(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter number',
                          prefixIcon: const Icon(Icons.spa_outlined),
                          filled: true,
                          fillColor: isDark ? Colors.black.withOpacity(0.1) : AppColors.neutral50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                          fillColor: isDark ? Colors.black.withOpacity(0.1) : AppColors.neutral50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: _caretakers.map((caretaker) {
                          return DropdownMenuItem(
                            value: caretaker['id'],
                            child: Text(caretaker['name']!),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _caretakerId = value),
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
                    fillColor: isDark ? Colors.black.withOpacity(0.1) : AppColors.neutral50,
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
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          side: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.2) : AppColors.neutral300,
                          ),
                        ),
                        child: Text(
                          'Clear Form',
                          style: AppTypography.button.copyWith(
                            color: isDark ? Colors.white : AppColors.textPrimary,
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
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
    final totalTransplanted = batches.fold<int>(0, (sum, b) => sum + b.transplantedPlants);
    final totalHarvested = batches.fold<int>(0, (sum, b) => sum + b.harvestedHeads);
    final avgSurvivalRate = batches.isEmpty
        ? 0.0
        : batches.fold<double>(0, (sum, b) => sum + b.survivalRate) / batches.length;

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
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral100,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.insights_outlined,
                    color: AppColors.primary,
                    size: isMobile ? 20 : 24,
                  ),
                  SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),
                  Text(
                    'Batch Overview',
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: isMobile ? 16 : 20,
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

  Widget _buildBatchStatCard(Map<String, dynamic> stat, bool isDark, [bool isMobile = false]) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.xs : AppSpacing.md),
      decoration: BoxDecoration(
        color: (stat['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: (stat['color'] as Color).withOpacity(0.3),
          width: isMobile ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                stat['icon'] as IconData,
                color: stat['color'] as Color,
                size: isMobile ? 18 : 20,
              ),
            ],
          ),
          const Spacer(),
          // Value
          Text(
            stat['value'] as String,
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.w700,
              color: stat['color'] as Color,
              fontSize: isMobile ? 20 : 22,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isMobile ? 4 : 6),
          // Title
          Text(
            stat['title'] as String,
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
              fontSize: isMobile ? 11 : 12,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBatchesTable(bool isDark, bool isMobile, List<BatchModel> batches) {
    final filteredBatches = batches
        .where((batch) => batch.batchNumber.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    if (isMobile) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredBatches.length,
        itemBuilder: (context, index) {
          final batch = filteredBatches[index];
          return _buildBatchCard(batch, isDark);
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral100,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text('Batch No.', style: _tableHeaderStyle(isDark))),
            DataColumn(label: Text('Farm', style: _tableHeaderStyle(isDark))),
            DataColumn(label: Text('Plant Type', style: _tableHeaderStyle(isDark))),
            DataColumn(label: Text('Status', style: _tableHeaderStyle(isDark))),
            DataColumn(label: Text('Progress', style: _tableHeaderStyle(isDark))),
            DataColumn(label: Text('Nursed', style: _tableHeaderStyle(isDark))),
            DataColumn(label: Text('Transplanted', style: _tableHeaderStyle(isDark))),
            DataColumn(label: Text('Harvested', style: _tableHeaderStyle(isDark))),
            DataColumn(label: Text('Progress %', style: _tableHeaderStyle(isDark))),
            DataColumn(label: Text('Start Date', style: _tableHeaderStyle(isDark))),
            DataColumn(label: Text('Actions', style: _tableHeaderStyle(isDark))),
          ],
          rows: filteredBatches.map((batch) {
            return DataRow(cells: [
              DataCell(Text(
                batch.batchNumber,
                style: _tableCellStyle(isDark, isBold: true),
              )),
              DataCell(Text(batch.farmName, style: _tableCellStyle(isDark))),
              DataCell(Text(batch.plantType, style: _tableCellStyle(isDark))),
              DataCell(StatusBadge(status: batch.status)),
              DataCell(_buildProgressIndicator(batch, isDark)),
              DataCell(Text(
                batch.nursedSeeds.toString(),
                style: _tableCellStyle(isDark),
              )),
              DataCell(Text(
                batch.transplantedPlants.toString(),
                style: _tableCellStyle(isDark,
                    color: batch.transplantedPlants > 0 ? AppColors.success : null),
              )),
              DataCell(Text(
                batch.harvestedHeads.toString(),
                style: _tableCellStyle(isDark,
                    color: batch.harvestedHeads > 0 ? AppColors.warning : null),
              )),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '${batch.progressPercentage.toStringAsFixed(0)}%',
                  style: _tableCellStyle(isDark, color: AppColors.primary, isBold: true),
                ),
              )),
              DataCell(Text(
                DateFormat('MMM dd, yyyy').format(batch.startDate),
                style: _tableCellStyle(isDark),
              )),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    onPressed: () => _viewBatchDetails(batch),
                    tooltip: 'View Details',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _editBatch(batch),
                    tooltip: 'Edit',
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BatchModel batch, bool isDark) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildProgressDot(batch.nursedSeeds > 0, AppColors.info, 'N'),
              const SizedBox(width: 4),
              _buildProgressDot(batch.transplantedPlants > 0, AppColors.success, 'T'),
              const SizedBox(width: 4),
              _buildProgressDot(batch.harvestedHeads > 0, AppColors.warning, 'H'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: batch.progressPercentage / 100,
            backgroundColor: isDark ? Colors.white10 : AppColors.neutral100,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(bool isActive, Color color, String label) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isActive ? color : Colors.grey.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? color : Colors.grey.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isActive ? Colors.white : Colors.grey,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBatchCard(BatchModel batch, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(Icons.grid_view_outlined, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    batch.batchNumber,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    batch.farmName,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            StatusBadge(status: batch.status),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Progress Metrics
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.2) : AppColors.neutral50,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Progress Metrics',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: _buildProgressMetric(
                      'Nursed',
                      batch.nursedSeeds.toString(),
                      Icons.spa_outlined,
                      AppColors.info,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _buildProgressMetric(
                      'Transplanted',
                      batch.transplantedPlants.toString(),
                      Icons.eco_outlined,
                      AppColors.success,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _buildProgressMetric(
                      'Harvested',
                      batch.harvestedHeads.toString(),
                      Icons.agriculture_outlined,
                      AppColors.warning,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: _buildProgressBar(
                      'Progress',
                      batch.progressPercentage,
                      AppColors.primary,
                      isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 3.2,
          children: [
            _buildBatchDetailItem(
              'Plant Type',
              batch.plantType,
              Icons.eco_outlined,
              isDark,
            ),
            _buildBatchDetailItem(
              'Start Date',
              DateFormat('MMM dd').format(batch.startDate),
              Icons.calendar_today_outlined,
              isDark,
            ),
            _buildBatchDetailItem(
              'End Date',
              DateFormat('MMM dd').format(batch.endDate),
              Icons.event_available_outlined,
              isDark,
            ),
            _buildBatchDetailItem(
              'Survival Rate',
              '${batch.survivalRate.toStringAsFixed(1)}%',
              Icons.trending_up_outlined,
              isDark,
            ),
          ],
        ),
        if (batch.caretakerName != null) ...[
          const SizedBox(height: AppSpacing.md),
          _buildBatchDetailItem(
            'Caretaker',
            batch.caretakerName!,
            Icons.person_outlined,
            isDark,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _viewBatchDetails(batch),
                icon: const Icon(Icons.visibility_outlined, size: 14),
                label: const Text('View', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _editBatch(batch),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _buildProgressMetric(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double percentage, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: isDark ? Colors.white10 : AppColors.neutral100,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildBatchDetailItem(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.1) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 12, color: isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary,
                    fontSize: 9,
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

  TextStyle _tableHeaderStyle(bool isDark) {
    return AppTypography.labelLarge.copyWith(
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : AppColors.textPrimary,
    );
  }

  TextStyle _tableCellStyle(bool isDark, {bool isBold = false, Color? color}) {
    return AppTypography.bodyMedium.copyWith(
      fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
      color: color ?? (isDark ? Colors.white.withOpacity(0.9) : AppColors.textPrimary),
    );
  }

  void _viewBatchDetails(BatchModel batch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.grid_view_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text('Batch Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Batch Number', batch.batchNumber),
              _buildDetailRow('Farm', batch.farmName),
              _buildDetailRow('Plant Type', batch.plantType),
              _buildDetailRow('Status', batch.status.toString().split('.').last),
              _buildDetailRow('Start Date', DateFormat('MMM dd, yyyy').format(batch.startDate)),
              _buildDetailRow('End Date', DateFormat('MMM dd, yyyy').format(batch.endDate)),
              _buildDetailRow('Nursed Seeds', batch.nursedSeeds.toString()),
              if (batch.caretakerName != null) _buildDetailRow('Caretaker', batch.caretakerName!),
              if (batch.notes != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Notes:',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(batch.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
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
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName, batches)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole, batches),
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }

  Widget _buildDesktopLayout(
      bool isDark, String userName, String userEmail, String userRole, List<BatchModel> batches) {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Toggle
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Batch Management & Tracking',
                                  style: AppTypography.h4.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
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
                              onPressed: () => setState(() => _showForm = true),
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
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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
                              onPressed: () => setState(() => _showForm = false),
                              tooltip: 'Back to Batches',
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Create New Batch',
                              style: AppTypography.h5.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.textPrimary,
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
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral100,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      onChanged: (value) => setState(() => _searchQuery = value),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Search batches by number, farm, or plant type...',
                                        prefixIcon: const Icon(Icons.search),
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
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  ElevatedButton.icon(
                                    onPressed: () => setState(() => _showForm = true),
                                    icon: const Icon(Icons.add),
                                    label: const Text('New Batch'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                        vertical: AppSpacing.md,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              if (batches.isEmpty)
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.grid_view_outlined,
                                        size: 64,
                                        color: isDark
                                            ? Colors.white.withOpacity(0.3)
                                            : AppColors.neutral300,
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Text(
                                        'No batches created yet',
                                        style: AppTypography.bodyLarge.copyWith(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.5)
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        'Create your first batch to get started',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.4)
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      ElevatedButton.icon(
                                        onPressed: () => setState(() => _showForm = true),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Create First Batch'),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                _buildBatchesTable(isDark, false, batches),
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

  Widget _buildMobileLayout(bool isDark, String userName, List<BatchModel> batches) {
    return Column(
      children: [
        FarmManagerHeader(
          userName: userName,
          onNotificationTap: () {},
        ),
        if (_showForm) ...[
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral100,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'All Batches (${batches.length})',
                            style: AppTypography.h5.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New'),
                          onPressed: () => setState(() => _showForm = true),
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
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Batches Table
                  _buildBatchesTable(isDark, true, batches),
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
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral100,
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
              final isSelected = index == _selectedNavIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_selectedNavIndex != index) {
                        setState(() => _selectedNavIndex = index);
                        try {
                          Navigator.pushReplacementNamed(context, item['route'] as String);
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
                                top: BorderSide(color: AppColors.primary, width: 2),
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
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
