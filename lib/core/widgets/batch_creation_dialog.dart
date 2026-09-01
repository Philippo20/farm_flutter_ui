import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../services/superadmin_api_service.dart';

({int value, String unit}) _cropDuration(Map<String, dynamic>? crop) {
  if (crop == null) return (value: 0, unit: 'days');
  final rawValue = crop['plant_duration_value'];
  var value = rawValue is num
      ? rawValue.toInt()
      : int.tryParse(rawValue?.toString() ?? '') ?? 0;
  var unit = (crop['plant_duration_unit'] ?? '').toString().toLowerCase();
  if (value > 0 && (unit == 'days' || unit == 'months')) {
    return (value: value, unit: unit);
  }

  final legacy = (crop['plant_duration'] ?? '').toString().toLowerCase();
  final match = RegExp(
    r'(\d+)\s*(day|days|month|months|week|weeks)?',
  ).firstMatch(legacy);
  if (match == null) return (value: 0, unit: 'days');
  value = int.tryParse(match.group(1) ?? '') ?? 0;
  final legacyUnit = match.group(2) ?? 'days';
  if (legacyUnit.startsWith('week')) {
    return (value: value * 7, unit: 'days');
  }
  unit = legacyUnit.startsWith('month') ? 'months' : 'days';
  return (value: value, unit: unit);
}

DateTime _calculateBatchEndDate(
  DateTime startDate,
  int durationValue,
  String durationUnit,
) {
  if (durationValue <= 0) return startDate;
  if (durationUnit != 'months') {
    return startDate.add(Duration(days: durationValue));
  }
  final targetMonth = DateTime(
    startDate.year,
    startDate.month + durationValue,
    1,
  );
  final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
  final targetDay = startDate.day > lastDay ? lastDay : startDate.day;
  return DateTime(targetMonth.year, targetMonth.month, targetDay);
}

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
  final varietyRecords = <String, Map<String, dynamic>>{};
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
        varietyRecords[variety] = crop;
      }
    }
  } catch (_) {
    // The farm's saved variety remains available if the catalog is offline.
  }
  if (selectedVariety.isEmpty && varietyOptions.isNotEmpty) {
    selectedVariety = varietyOptions.first;
  }
  if (!context.mounted) return null;
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
  var selectedDuration = _cropDuration(varietyRecords[selectedVariety]);
  var endDate = _calculateBatchEndDate(
    startDate,
    selectedDuration.value,
    selectedDuration.unit,
  );
  var saving = false;
  String? formError;

  String dateText(DateTime date) => DateFormat('MMM dd, yyyy').format(date);
  String isoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  InputDecoration inputDecoration(bool isDark, String label,
      {String? hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 12.5,
        color: isDark ? Colors.white54 : AppColors.textSecondary,
      ),
      errorStyle: GoogleFonts.poppins(fontSize: 10.5, height: 1.25),
      prefixIcon: icon == null ? null : Icon(icon, size: 18),
      filled: true,
      fillColor:
          isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.neutral50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(
          color: isDark ? Colors.white12 : AppColors.neutral200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: AppColors.success, width: 2),
      ),
    );
  }

  TextStyle inputTextStyle(bool isDark) => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: isDark ? Colors.white : AppColors.textPrimary,
      );

  Widget fieldLabel(String label, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.35,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      );

  Future<void> pickStartDate(
    BuildContext dialogContext,
    StateSetter setModalState,
  ) async {
    final picked = await showDatePicker(
      context: dialogContext,
      initialDate: startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setModalState(() {
      startDate = picked;
      endDate = _calculateBatchEndDate(
        startDate,
        selectedDuration.value,
        selectedDuration.unit,
      );
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
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 600,
                maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.success,
                          AppColors.success.withValues(alpha: 0.82),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusLg),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: const Icon(
                            Icons.add_circle_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Batch Number',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text('Generate a production batch for $farmName',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white70,
                                    height: 1.35,
                                  )),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: saving
                              ? null
                              : () => Navigator.pop(dialogContext),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
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
                                  color:
                                      AppColors.error.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd),
                                  border: Border.all(
                                      color: AppColors.error
                                          .withValues(alpha: 0.25)),
                                ),
                                child: Text(
                                  formError!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    height: 1.4,
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
                                  style: inputTextStyle(isDark),
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
                                  style: inputTextStyle(isDark),
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
                                  initialValue:
                                      varietyOptions.contains(selectedVariety)
                                          ? selectedVariety
                                          : null,
                                  isExpanded: true,
                                  style: inputTextStyle(isDark),
                                  decoration: inputDecoration(
                                    isDark,
                                    'Crop Variety',
                                    hint: 'Select crop variety',
                                    icon: Icons.category_outlined,
                                  ),
                                  items: varietyOptions
                                      .map((variety) => DropdownMenuItem(
                                            value: variety,
                                            child: Text(
                                              variety,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: saving
                                      ? null
                                      : (value) => setModalState(() {
                                            selectedVariety = value ?? '';
                                            selectedDuration = _cropDuration(
                                              varietyRecords[selectedVariety],
                                            );
                                            endDate = _calculateBatchEndDate(
                                              startDate,
                                              selectedDuration.value,
                                              selectedDuration.unit,
                                            );
                                            formError = null;
                                          }),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
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
                                        : () => pickStartDate(
                                              dialogContext,
                                              setModalState,
                                            ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _BatchDateField(
                                    label: 'End Date (Auto)',
                                    value: dateText(endDate),
                                    icon: Icons.event_available_outlined,
                                    onTap: null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Icon(
                                  selectedDuration.value > 0
                                      ? Icons.auto_awesome_outlined
                                      : Icons.info_outline_rounded,
                                  size: 14,
                                  color: selectedDuration.value > 0
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    selectedDuration.value > 0
                                        ? 'Calculated from ${selectedDuration.value} ${selectedDuration.unit}'
                                        : 'Add a duration to this crop variety before creating a batch.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.5,
                                      color: selectedDuration.value > 0
                                          ? (isDark
                                              ? Colors.white60
                                              : AppColors.textSecondary)
                                          : AppColors.warning,
                                    ),
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
                                  style: inputTextStyle(isDark),
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
                                  style: inputTextStyle(isDark),
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
                                  style: inputTextStyle(isDark),
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
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
                              onPressed: saving
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                textStyle: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      if (selectedDuration.value <= 0) {
                                        setModalState(() => formError =
                                            'The selected crop variety has no valid plant duration.');
                                        return;
                                      }
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
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.add_circle_outline_rounded,
                                      size: 17,
                                    ),
                              label:
                                  Text(saving ? 'Creating...' : 'Create Batch'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                textStyle: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
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
          padding: const EdgeInsets.only(bottom: 7),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.neutral50,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : AppColors.neutral200,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : AppColors.neutral200,
                ),
              ),
            ),
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
