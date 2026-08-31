import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../../services/superadmin_api_service.dart';

Future<bool?> showBatchCreationDialog({
  required BuildContext context,
  required SuperAdminApiService api,
  required Map<String, dynamic> farm,
  required String createdBy,
  required Future<void> Function() onCreated,
}) async {
  final farmId = '${farm['id'] ?? farm[r'$id'] ?? ''}';
  final farmName = '${farm['name'] ?? farm['farm_name'] ?? 'Farm'}';
  final plantName = '${farm['plantType'] ?? farm['plant_type'] ?? ''}';
  var selectedVariety =
      '${farm['plantVariety'] ?? farm['plant_variety'] ?? ''}'.trim();
  if (selectedVariety == '-' || selectedVariety.toLowerCase() == 'none') {
    selectedVariety = '';
  }
  final varietyOptions = <String>{
    if (selectedVariety.isNotEmpty) selectedVariety,
  };
  try {
    final crops = await api.getCrops();
    for (final crop in crops) {
      final cropPlant =
          '${crop['plant_type'] ?? crop['plant_name'] ?? crop['plantType'] ?? crop['crop_name'] ?? ''}'
              .trim();
      final variety =
          '${crop['variety_name'] ?? crop['variety'] ?? crop['name'] ?? ''}'
              .trim();
      if (variety.isNotEmpty &&
          (plantName.trim().isEmpty ||
              cropPlant.isEmpty ||
              cropPlant.toLowerCase() == plantName.trim().toLowerCase())) {
        varietyOptions.add(variety);
      }
    }
  } catch (_) {
    // The farm's saved variety remains available if the catalog is offline.
  }
  if (selectedVariety.isEmpty && varietyOptions.isNotEmpty) {
    selectedVariety = varietyOptions.first;
  }
  final managerId = '${farm['farmManagerId'] ?? farm['farm_manager_id'] ?? ''}';
  final managerName =
      '${farm['farmManager'] ?? farm['farm_manager_name'] ?? ''}';
  final seedsController = TextEditingController();
  final caretakerController = TextEditingController(
    text: '${farm['caretaker'] ?? farm['caretaker_name'] ?? ''}',
  );
  final notesController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var startDate = DateTime.now();
  var endDate = startDate.add(const Duration(days: 30));
  var saving = false;
  String? formError;

  String dateText(DateTime date) => DateFormat('MMM dd, yyyy').format(date);
  String isoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  InputDecoration inputDecoration(bool isDark, String label,
      {String? hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: isDark ? Colors.black.withOpacity(0.1) : AppColors.neutral50,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget fieldLabel(String label, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
      );

  Future<void> pickDate(BuildContext dialogContext, bool isStart,
      StateSetter setModalState) async {
    final picked = await showDatePicker(
      context: dialogContext,
      initialDate: isStart ? startDate : endDate,
      firstDate: isStart ? DateTime.now() : startDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setModalState(() {
      if (isStart) {
        startDate = picked;
        if (!endDate.isAfter(startDate)) {
          endDate = startDate.add(const Duration(days: 30));
        }
      } else {
        endDate = picked;
      }
      formError = null;
    });
  }

  try {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.lg),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.08),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 16, 18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.75),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_circle_outline_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Batch Number',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text('Generate a production batch for $farmName',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white38
                                        : AppColors.textSecondary,
                                  )),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: saving
                              ? null
                              : () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (formError != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd),
                                  border: Border.all(
                                      color: AppColors.error.withOpacity(0.25)),
                                ),
                            child: Text(
                              formError!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.error,
                              ),
                            ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel('Farm', isDark),
                                TextFormField(
                                  initialValue: farmName,
                                  readOnly: true,
                                  decoration: inputDecoration(isDark, 'Farm',
                                      icon: Icons.agriculture_outlined),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel('Plant Type', isDark),
                                TextFormField(
                                  initialValue:
                                      plantName.isEmpty ? 'Plant' : plantName,
                                  readOnly: true,
                                  decoration: inputDecoration(
                                      isDark, 'Plant Type',
                                      icon: Icons.eco_outlined),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel('Crop Variety', isDark),
                                DropdownButtonFormField<String>(
                                  value: varietyOptions.contains(selectedVariety)
                                      ? selectedVariety
                                      : null,
                                  isExpanded: true,
                                  decoration: inputDecoration(
                                    isDark,
                                    'Crop Variety',
                                    hint: 'Select crop variety',
                                    icon: Icons.category_outlined,
                                  ),
                                  items: varietyOptions
                                      .map((variety) => DropdownMenuItem(
                                            value: variety,
                                            child: Text(variety,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ))
                                      .toList(),
                                  onChanged: saving
                                      ? null
                                      : (value) => setModalState(
                                          () => selectedVariety = value ?? ''),
                                  validator: (value) => value == null ||
                                          value.trim().isEmpty
                                      ? 'Select a crop variety'
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _BatchDateField(
                                    label: 'Start Date',
                                    value: dateText(startDate),
                                    icon: Icons.calendar_today_outlined,
                                    onTap: saving
                                        ? null
                                        : () => pickDate(
                                            dialogContext, true, setModalState),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _BatchDateField(
                                    label: 'End Date',
                                    value: dateText(endDate),
                                    icon: Icons.event_available_outlined,
                                    onTap: saving
                                        ? null
                                        : () => pickDate(dialogContext, false,
                                            setModalState),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel('Number of Seeds', isDark),
                                TextFormField(
                                  controller: seedsController,
                                  enabled: !saving,
                                  keyboardType: TextInputType.number,
                                  decoration: inputDecoration(
                                      isDark, 'Number of Seeds',
                                      hint: 'Enter number',
                                      icon: Icons.spa_outlined),
                                  validator: (value) {
                                    final number =
                                        int.tryParse(value?.trim() ?? '');
                                    if (number == null || number <= 0) {
                                      return 'Enter a valid number of seeds';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel('Caretaker (Optional)', isDark),
                                TextFormField(
                                  controller: caretakerController,
                                  enabled: !saving,
                                  decoration: inputDecoration(
                                    isDark,
                                    'Caretaker (Optional)',
                                    hint: 'Select caretaker',
                                    icon: Icons.person_outline,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel('Notes (Optional)', isDark),
                                TextFormField(
                                  controller: notesController,
                                  enabled: !saving,
                                  maxLines: 3,
                                  decoration: inputDecoration(
                                      isDark, 'Notes (Optional)',
                                      hint: 'Add any additional notes...',
                                      icon: Icons.note_outlined),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate())
                                        return;
                                      setModalState(() {
                                        saving = true;
                                        formError = null;
                                      });
                                      try {
                                        final batchNumber =
                                            '${farmName.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase()}-${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';
                                        await api.createBatch(data: {
                                          'batch_no': batchNumber,
                                          'farmID': farmId,
                                          'farm_name': farmName,
                                          'plant_type_ID': '',
                                          'plant_name': plantName.isEmpty
                                              ? 'Plant'
                                              : plantName,
                                          'plant_variety': selectedVariety,
                                          'farm_manager_id': managerId,
                                          'farm_manager_name': managerName,
                                          'caretaker_id': '',
                                          'caretaker_name':
                                              caretakerController.text.trim(),
                                          'start_date': isoDate(startDate),
                                          'end_date': isoDate(endDate),
                                          'actual_harvest_date':
                                              isoDate(endDate),
                                          'total_seeds_nursed': int.parse(
                                              seedsController.text.trim()),
                                          'total_harvested': 0,
                                          'total_transplanted': 0,
                                          'total_weight_kg': 0,
                                          'production_status': 'Planted',
                                          'technical_issues':
                                              notesController.text.trim(),
                                          'inputs_supplied':
                                              'Batch created from farm details',
                                          'funds_requested': false,
                                          'financial_status': 'Pending',
                                          'fund_request_id': '',
                                          'delivery_status': 'Pending',
                                          'delivery_details': '',
                                          'created_by': createdBy,
                                          'created_at': isoDate(DateTime.now()),
                                          'updated_at':
                                              DateTime.now().toIso8601String(),
                                        });
                                        await onCreated();
                                        if (dialogContext.mounted) {
                                          Navigator.pop(dialogContext, true);
                                        }
                                      } catch (error) {
                                        setModalState(() {
                                          saving = false;
                                          formError = error.toString();
                                        });
                                      }
                                    },
                              icon: saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.add, size: 18),
                              label:
                                  Text(saving ? 'Creating...' : 'Create Batch'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  } finally {
    seedsController.dispose();
    caretakerController.dispose();
    notesController.dispose();
  }
}

class _BatchDateField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _BatchDateField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: Icon(icon),
              filled: true,
              fillColor:
                  isDark ? Colors.black.withOpacity(0.1) : AppColors.neutral50,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                ),
              ),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
