import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/models/batch/batch_model.dart';
import '../../core/providers/enhanced_auth_provider.dart';
import '../../core/providers/batch_provider.dart';

/// Batch Generation Screen
/// Farm Manager can generate new production batches
class BatchGenerationScreen extends ConsumerStatefulWidget {
  const BatchGenerationScreen({super.key});

  @override
  ConsumerState<BatchGenerationScreen> createState() => _BatchGenerationScreenState();
}

class _BatchGenerationScreenState extends ConsumerState<BatchGenerationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  String? _selectedFarm;
  String? _selectedPlantType;
  DateTime? _startDate;
  DateTime? _endDate;
  int _nursedSeeds = 0;
  String? _caretakerId;
  final _notesController = TextEditingController();
  
  bool _isGenerating = false;

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
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

    final user = ref.read(currentUserProvider);
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
      caretakerId: _caretakerId,
      caretakerName: _caretakers.firstWhere((c) => c['id'] == _caretakerId, orElse: () => {'name': ''})['name'],
      createdAt: DateTime.now(),
      nurseryDate: DateTime.now(),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    // Save to provider
    ref.read(batchProvider.notifier).addBatch(batch);

    setState(() {
      _isGenerating = false;
    });

    // Show success dialog
    if (mounted) {
      _showSuccessDialog(batch);
    }
  }

  void _showSuccessDialog(BatchModel batch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 32),
            const SizedBox(width: AppSpacing.sm),
            const Text('Batch Generated!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Batch Number: ${batch.batchNumber}', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            Text('Farm: ${batch.farmName}'),
            Text('Plant: ${batch.plantType}'),
            Text('Start: ${DateFormat('MMM dd, yyyy').format(batch.startDate)}'),
            Text('Expected Harvest: ${DateFormat('MMM dd, yyyy').format(batch.expectedHarvestDate)}'),
            Text('Nursed Seeds: ${batch.nursedSeeds}'),
            if (batch.caretakerName != null && batch.caretakerName!.isNotEmpty)
              Text('Caretaker: ${batch.caretakerName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetForm();
            },
            child: const Text('Create Another'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              context.pop(); // Go back to dashboard
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Generate New Batch',
          style: AppTypography.h5.copyWith(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success.withOpacity(0.1),
                      AppColors.success.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle, color: AppColors.success, size: 32),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Production Batch',
                            style: AppTypography.h6.copyWith(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Fill in the details to generate a new batch',
                            style: AppTypography.bodySmall.copyWith(
                              fontFamily: 'Roboto',
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Form Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Farm Selection
                    Text(
                      'Select Farm',
                      style: AppTypography.bodyLarge.copyWith(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: _selectedFarm,
                      decoration: InputDecoration(
                        hintText: 'Choose a farm',
                        prefixIcon: const Icon(Icons.agriculture),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                    const SizedBox(height: AppSpacing.lg),

                    // Plant Type Selection
                    Text(
                      'Plant Type',
                      style: AppTypography.bodyLarge.copyWith(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: _selectedPlantType,
                      decoration: InputDecoration(
                        hintText: 'Choose plant type',
                        prefixIcon: const Icon(Icons.eco),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                    const SizedBox(height: AppSpacing.lg),

                    // Date Selection
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
                                style: AppTypography.bodyLarge.copyWith(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              InkWell(
                                onTap: () => _selectDate(context, true),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.calendar_today),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                    ),
                                  ),
                                  child: Text(
                                    _startDate != null
                                        ? DateFormat('MMM dd, yyyy').format(_startDate!)
                                        : 'Select date',
                                    style: TextStyle(
                                      color: _startDate != null
                                          ? (isDark ? Colors.white : AppColors.textPrimary)
                                          : Colors.grey,
                                    ),
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
                                style: AppTypography.bodyLarge.copyWith(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              InputDecorator(
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.event_available),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  ),
                                ),
                                child: Text(
                                  _endDate != null
                                      ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                      : 'Auto-calculated',
                                  style: TextStyle(
                                    color: _endDate != null
                                        ? AppColors.success
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Nursed Seeds
                    Text(
                      'Number of Seeds to Nurse',
                      style: AppTypography.bodyLarge.copyWith(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter number of seeds',
                        prefixIcon: const Icon(Icons.spa),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                    const SizedBox(height: AppSpacing.lg),

                    // Caretaker Assignment
                    Text(
                      'Assign Caretaker (Optional)',
                      style: AppTypography.bodyLarge.copyWith(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: _caretakerId,
                      decoration: InputDecoration(
                        hintText: 'Choose a caretaker',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                    const SizedBox(height: AppSpacing.lg),

                    // Notes
                    Text(
                      'Notes (Optional)',
                      style: AppTypography.bodyLarge.copyWith(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add any additional notes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isGenerating ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTypography.button.copyWith(fontFamily: 'Poppins'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isGenerating ? null : _generateBatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
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
                          : Text(
                              'Generate Batch',
                              style: AppTypography.button.copyWith(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                              ),
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
}
