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
  int _selectedNavIndex = 3;
  final _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_circle_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create New Batch',
                    style: GoogleFonts.inter(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('Fill in the details to generate a new production batch',
                    style: GoogleFonts.inter(fontSize: isMobile ? 11 : 12, color: isDark ? Colors.white38 : AppColors.textSecondary)),
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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
            boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
                    child: Icon(Icons.insights_rounded, color: AppColors.primary, size: isMobile ? 16 : 18),
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

  Widget _buildBatchStatCard(Map<String, dynamic> stat, bool isDark, [bool isMobile = false]) {
    final color = stat['color'] as Color;
    return LayoutBuilder(builder: (context, box) {
      final compact = box.maxWidth < 140;
      return Container(
        padding: EdgeInsets.all(compact ? 8 : 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(isDark ? 0.15 : 0.12)),
          boxShadow: isDark ? null : [BoxShadow(color: color.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 5 : 7),
              decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Icon(stat['icon'] as IconData, color: color, size: compact ? 14 : 16),
            ),
            const Spacer(),
            Text(stat['value'] as String,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary, fontSize: compact ? 18 : 22, height: 1.1),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: compact ? 2 : 4),
            Text(stat['title'] as String,
                style: GoogleFonts.inter(color: isDark ? Colors.white38 : AppColors.textSecondary, fontSize: compact ? 10 : 11, height: 1.2),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      );
    });
  }

  // ============================================
  // PROFESSIONAL BATCHES TABLE & CARDS
  // ============================================

  Widget _buildBatchesTable(bool isDark, bool isMobile, List<BatchModel> batches) {
    final filteredBatches = batches
        .where((batch) => batch.batchNumber.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    if (isMobile) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredBatches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildBatchCard(filteredBatches[index], isDark),
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
              color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
              border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))),
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
          ...filteredBatches.asMap().entries.map((entry) {
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
    final pctColor = pct >= 75 ? AppColors.success : (pct >= 40 ? AppColors.warning : AppColors.info);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _viewBatchDetails(batch),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isEven
                ? (isDark ? Colors.transparent : Colors.transparent)
                : (isDark ? Colors.white.withOpacity(0.02) : AppColors.neutral50.withOpacity(0.5)),
            border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04))),
          ),
          child: Row(children: [
            // Batch No.
            Expanded(
              flex: 2,
              child: Row(children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  batch.batchNumber,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                )),
              ]),
            ),
            // Farm
            Expanded(
              flex: 2,
              child: Text(batch.farmName, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            // Crop
            Expanded(
              flex: 1,
              child: Row(children: [
                Icon(Icons.eco_rounded, size: 13, color: AppColors.success.withOpacity(0.7)),
                const SizedBox(width: 4),
                Expanded(child: Text(batch.plantType, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: pctColor),
                ),
              ),
            ),
            // Start Date
            Expanded(
              flex: 2,
              child: Text(
                DateFormat('MMM dd, yyyy').format(batch.startDate),
                style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white54 : AppColors.textSecondary),
              ),
            ),
            // Actions
            Expanded(
              flex: 1,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                _actionIcon(Icons.visibility_outlined, 'View', () => _viewBatchDetails(batch), isDark),
                const SizedBox(width: 4),
                _actionIcon(Icons.edit_outlined, 'Edit', () => _editBatch(batch), isDark),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, String tooltip, VoidCallback onTap, bool isDark) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: isDark ? Colors.white54 : AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildPipeline(BatchModel batch, bool isDark) {
    final stages = [
      {'label': 'Nursed', 'value': batch.nursedSeeds, 'color': AppColors.info, 'icon': Icons.spa_rounded},
      {'label': 'Transplanted', 'value': batch.transplantedPlants, 'color': AppColors.success, 'icon': Icons.eco_rounded},
      {'label': 'Harvested', 'value': batch.harvestedHeads, 'color': AppColors.warning, 'icon': Icons.agriculture_rounded},
    ];

    return Row(children: [
      ...stages.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        final value = s['value'] as int;
        final color = s['color'] as Color;
        final isActive = value > 0;
        final isLast = i == stages.length - 1;

        return Expanded(child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.1) : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(s['icon'] as IconData, size: 10, color: isActive ? color : (isDark ? Colors.white24 : AppColors.neutral400)),
              const SizedBox(width: 3),
              Text(
                '$value',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: isActive ? color : (isDark ? Colors.white24 : AppColors.neutral400)),
              ),
            ]),
          ),
          if (!isLast) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(Icons.arrow_forward_ios_rounded, size: 8, color: isDark ? Colors.white12 : AppColors.neutral300),
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
    final pctColor = pct >= 75 ? AppColors.success : (pct >= 40 ? AppColors.warning : AppColors.info);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)]),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.layers_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(batch.batchNumber, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 1),
              Row(children: [
                Icon(Icons.location_on_outlined, size: 11, color: isDark ? Colors.white38 : AppColors.textSecondary),
                const SizedBox(width: 3),
                Expanded(child: Text(batch.farmName, style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white38 : AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
            color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            // Pipeline stages
            Row(children: [
              _mobilePipelineStage('Nursed', batch.nursedSeeds, AppColors.info, Icons.spa_rounded, isDark),
              _mobilePipelineArrow(isDark),
              _mobilePipelineStage('Transplant', batch.transplantedPlants, AppColors.success, Icons.eco_rounded, isDark),
              _mobilePipelineArrow(isDark),
              _mobilePipelineStage('Harvest', batch.harvestedHeads, AppColors.warning, Icons.agriculture_rounded, isDark),
            ]),
            const SizedBox(height: 10),
            // Progress bar
            Row(children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                  minHeight: 5,
                ),
              )),
              const SizedBox(width: 8),
              Text('${pct.toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: pctColor)),
            ]),
          ]),
        ),

        const SizedBox(height: 12),

        // Details row
        Row(children: [
          _mobileDetail(Icons.eco_outlined, batch.plantType, isDark),
          const SizedBox(width: 10),
          _mobileDetail(Icons.calendar_today_rounded, DateFormat('MMM dd').format(batch.startDate), isDark),
          const SizedBox(width: 10),
          _mobileDetail(Icons.trending_up_rounded, '${batch.survivalRate.toStringAsFixed(0)}%', isDark),
        ]),

        if (batch.caretakerName != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.person_outline_rounded, size: 12, color: isDark ? Colors.white24 : AppColors.textSecondary),
            const SizedBox(width: 4),
            Expanded(child: Text(batch.caretakerName!, style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white38 : AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ],

        const SizedBox(height: 12),

        // Action buttons
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => _viewBatchDetails(batch),
            icon: const Icon(Icons.visibility_outlined, size: 14),
            label: Text('View', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08)),
            ),
          )),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton.icon(
            onPressed: () => _editBatch(batch),
            icon: const Icon(Icons.edit_outlined, size: 14),
            label: Text('Edit', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 7),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
          )),
        ]),
      ]),
    );
  }

  Widget _mobilePipelineStage(String label, int value, Color color, IconData icon, bool isDark) {
    final isActive = value > 0;
    return Expanded(child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? color.withOpacity(0.2) : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))),
        ),
        child: Column(children: [
          Icon(icon, size: 14, color: isActive ? color : (isDark ? Colors.white24 : AppColors.neutral400)),
          const SizedBox(height: 2),
          Text('$value', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: isActive ? color : (isDark ? Colors.white24 : AppColors.neutral400))),
        ]),
      ),
      const SizedBox(height: 3),
      Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500, color: isDark ? Colors.white38 : AppColors.textSecondary)),
    ]));
  }

  Widget _mobilePipelineArrow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? Colors.white12 : AppColors.neutral300),
    );
  }

  Widget _mobileDetail(IconData icon, String text, bool isDark) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: isDark ? Colors.white24 : AppColors.textSecondary),
      const SizedBox(width: 4),
      Text(text, style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white54 : AppColors.textSecondary)),
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
      color: color ?? (isDark ? Colors.white.withOpacity(0.9) : AppColors.textPrimary),
    );
  }

  void _viewBatchDetails(BatchModel batch) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = batch.progressPercentage;
    final pctColor = pct >= 75 ? AppColors.success : (pct >= 40 ? AppColors.warning : AppColors.info);

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
                        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.layers_rounded, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(batch.batchNumber, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary)),
                        Text(batch.farmName, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white38 : AppColors.textSecondary)),
                      ],
                    )),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.close_rounded, size: 16, color: isDark ? Colors.white38 : AppColors.textSecondary),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Progress section
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Overall Progress', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : AppColors.textSecondary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: pctColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text('${pct.toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: pctColor)),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: pct / 100, backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06), valueColor: AlwaysStoppedAnimation<Color>(pctColor), minHeight: 6),
                      ),
                      const SizedBox(height: 14),
                      Row(children: [
                        _dialogMetric('Nursed', batch.nursedSeeds.toString(), AppColors.info, isDark),
                        const SizedBox(width: 8),
                        _dialogMetric('Transplanted', batch.transplantedPlants.toString(), AppColors.success, isDark),
                        const SizedBox(width: 8),
                        _dialogMetric('Harvested', batch.harvestedHeads.toString(), AppColors.warning, isDark),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Detail rows
                  _buildDetailRow('Plant Type', batch.plantType, Icons.eco_outlined, isDark),
                  _buildDetailRow('Status', batch.status.toString().split('.').last, Icons.flag_outlined, isDark),
                  _buildDetailRow('Start Date', DateFormat('MMM dd, yyyy').format(batch.startDate), Icons.calendar_today_outlined, isDark),
                  _buildDetailRow('End Date', DateFormat('MMM dd, yyyy').format(batch.endDate), Icons.event_available_outlined, isDark),
                  _buildDetailRow('Survival Rate', '${batch.survivalRate.toStringAsFixed(1)}%', Icons.trending_up_rounded, isDark),
                  if (batch.caretakerName != null) _buildDetailRow('Caretaker', batch.caretakerName!, Icons.person_outline_rounded, isDark),

                  if (batch.notes != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Notes', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(batch.notes!, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textPrimary, height: 1.5)),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08)),
                      ),
                      child: Text('Close', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: ElevatedButton.icon(
                      onPressed: () { Navigator.of(context).pop(); _editBatch(batch); },
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: Text('Edit Batch', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500, color: isDark ? Colors.white38 : AppColors.textSecondary)),
      ]),
    ));
  }

  Widget _buildDetailRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 14, color: isDark ? Colors.white24 : AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white38 : AppColors.textSecondary)),
        ),
        Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary))),
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
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
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
                          padding: const EdgeInsets.all(0),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
                            boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Search & Actions bar
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: Row(children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Icon(Icons.table_chart_rounded, size: 18, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text('Batch Tracking', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text('${batches.length} batches', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                  ),
                                ]),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(children: [
                                  Expanded(
                                    child: TextField(
                                      onChanged: (value) => setState(() => _searchQuery = value),
                                      style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary),
                                      decoration: InputDecoration(
                                        hintText: 'Search batches...',
                                        hintStyle: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white24 : AppColors.textSecondary),
                                        prefixIcon: Icon(Icons.search_rounded, size: 18, color: isDark ? Colors.white24 : AppColors.textSecondary),
                                        filled: true,
                                        fillColor: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: () => setState(() => _showForm = true),
                                    icon: const Icon(Icons.add_rounded, size: 16),
                                    label: Text('New Batch', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ]),
                              ),
                              if (batches.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.06),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.layers_outlined, size: 40, color: AppColors.primary.withOpacity(0.4)),
                                        ),
                                        const SizedBox(height: 16),
                                        Text('No batches created yet', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : AppColors.textSecondary)),
                                        const SizedBox(height: 4),
                                        Text('Create your first batch to get started', style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white24 : AppColors.textSecondary)),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () => setState(() => _showForm = true),
                                          icon: const Icon(Icons.add_rounded, size: 16),
                                          label: Text('Create First Batch', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ],
                                    ),
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
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
                      boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.table_chart_rounded, size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text('All Batches', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                          child: Text('${batches.length}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 15),
                          label: Text('New', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                          onPressed: () => setState(() => _showForm = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      // Mobile search
                      TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white : AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search batches...',
                          hintStyle: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white24 : AppColors.textSecondary),
                          prefixIcon: Icon(Icons.search_rounded, size: 16, color: isDark ? Colors.white24 : AppColors.textSecondary),
                          filled: true,
                          fillColor: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),

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
              const isSelected = false; // Batches is not in bottom nav

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
