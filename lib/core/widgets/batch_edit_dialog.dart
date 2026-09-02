import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/batch/batch_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../services/superadmin_api_service.dart';

Future<bool?> showBatchEditDialog({
  required BuildContext context,
  required SuperAdminApiService api,
  required BatchModel batch,
  required List<Map<String, dynamic>> cropVarieties,
  required String updatedBy,
  required String updatedByRole,
  required Future<void> Function() onUpdated,
}) {
  final isMobile = MediaQuery.sizeOf(context).width < 600;
  final editor = _BatchEditForm(
    api: api,
    batch: batch,
    cropVarieties: cropVarieties,
    updatedBy: updatedBy,
    updatedByRole: updatedByRole,
    onUpdated: onUpdated,
  );
  if (isMobile) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.94,
        child: editor,
      ),
    );
  }
  return showDialog<bool>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660, maxHeight: 780),
        child: editor,
      ),
    ),
  );
}

class _BatchEditForm extends StatefulWidget {
  const _BatchEditForm({
    required this.api,
    required this.batch,
    required this.cropVarieties,
    required this.updatedBy,
    required this.updatedByRole,
    required this.onUpdated,
  });

  final SuperAdminApiService api;
  final BatchModel batch;
  final List<Map<String, dynamic>> cropVarieties;
  final String updatedBy;
  final String updatedByRole;
  final Future<void> Function() onUpdated;

  @override
  State<_BatchEditForm> createState() => _BatchEditFormState();
}

class _BatchEditFormState extends State<_BatchEditForm> {
  static const _statuses = [
    'Planted',
    'Growing',
    'Harvested',
    'Delivered',
    'Completed',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nursedController;
  late final TextEditingController _transplantedController;
  late final TextEditingController _harvestedController;
  late final TextEditingController _weightController;
  late final TextEditingController _notesController;
  late DateTime _startDate;
  late DateTime _endDate;
  late String _status;
  late String _variety;
  bool _saving = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final metadata = widget.batch.metadata ?? const <String, dynamic>{};
    _startDate = widget.batch.startDate;
    _endDate = widget.batch.endDate;
    _variety = widget.batch.plantVariety;
    _status = _backendStatus(
      (metadata['production_status'] ?? '').toString(),
      widget.batch.status,
    );
    _nursedController =
        TextEditingController(text: widget.batch.nursedSeeds.toString());
    _transplantedController = TextEditingController(
      text: widget.batch.transplantedPlants.toString(),
    );
    _harvestedController =
        TextEditingController(text: widget.batch.harvestedHeads.toString());
    _weightController = TextEditingController(
      text: widget.batch.harvestedWeight.toStringAsFixed(1),
    );
    _notesController = TextEditingController(text: widget.batch.notes ?? '');
  }

  @override
  void dispose() {
    _nursedController.dispose();
    _transplantedController.dispose();
    _harvestedController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _backendStatus(String raw, BatchStatus fallback) {
    for (final status in _statuses) {
      if (status.toLowerCase() == raw.toLowerCase()) return status;
    }
    switch (fallback) {
      case BatchStatus.growing:
        return 'Growing';
      case BatchStatus.harvested:
      case BatchStatus.harvesting:
        return 'Harvested';
      case BatchStatus.delivered:
        return 'Delivered';
      case BatchStatus.completed:
        return 'Completed';
      default:
        return 'Planted';
    }
  }

  String _key(Object? value) => value
      .toString()
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  bool _samePlant(String first, String second) {
    final firstKey = _key(first);
    final secondKey = _key(second);
    return firstKey.isNotEmpty &&
        secondKey.isNotEmpty &&
        (firstKey == secondKey ||
            firstKey.contains(secondKey) ||
            secondKey.contains(firstKey));
  }

  String _value(Map<String, dynamic> record, List<String> keys) {
    for (final key in keys) {
      final value = record[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  List<String> get _varietyOptions {
    final options = <String>{if (_variety.isNotEmpty) _variety};
    for (final crop in widget.cropVarieties) {
      final plant = _value(
        crop,
        ['crop_name', 'plant_type', 'plant_name', 'plantType'],
      );
      final variety = _value(crop, ['variety_name', 'variety', 'name']);
      if (variety.isNotEmpty && _samePlant(plant, widget.batch.plantType)) {
        options.add(variety);
      }
    }
    return options.toList()..sort();
  }

  ({int value, String unit})? _durationFor(String variety) {
    for (final crop in widget.cropVarieties) {
      final cropVariety = _value(crop, ['variety_name', 'variety', 'name']);
      if (_key(cropVariety) != _key(variety)) continue;
      final raw = crop['plant_duration_value'];
      final value =
          raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '') ?? 0;
      final unit = (crop['plant_duration_unit'] ?? '').toString().toLowerCase();
      if (value > 0 && ['days', 'weeks', 'months'].contains(unit)) {
        return (value: value, unit: unit);
      }
    }
    return null;
  }

  DateTime? _calculateEndDate(DateTime start, String variety) {
    final duration = _durationFor(variety);
    if (duration == null) return null;
    if (duration.unit == 'weeks') {
      return start.add(Duration(days: duration.value * 7));
    }
    if (duration.unit == 'days') {
      return start.add(Duration(days: duration.value));
    }
    final month = DateTime(start.year, start.month + duration.value, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    return DateTime(
      month.year,
      month.month,
      start.day.clamp(1, lastDay).toInt(),
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startDate = picked;
      _endDate = _calculateEndDate(picked, _variety) ?? _endDate;
      _formError = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endDate.isBefore(_startDate)) {
      setState(() => _formError = 'End date cannot be before the start date.');
      return;
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    try {
      await widget.api.updateBatch(
        id: widget.batch.id,
        data: {
          'plant_variety': _variety,
          'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
          'end_date': DateFormat('yyyy-MM-dd').format(_endDate),
          'total_seeds_nursed': int.parse(_nursedController.text.trim()),
          'total_transplanted': int.parse(_transplantedController.text.trim()),
          'total_harvested': int.parse(_harvestedController.text.trim()),
          'total_weight_kg': double.parse(_weightController.text.trim()),
          'production_status': _status,
          'technical_issues': _notesController.text.trim(),
          'updated_by': widget.updatedBy,
          'updated_by_role': widget.updatedByRole,
        },
      );
      await widget.onUpdated();
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = error.toString();
      });
    }
  }

  InputDecoration _decoration(bool isDark, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorStyle: GoogleFonts.poppins(fontSize: 10.5, height: 1.25),
    );
  }

  Widget _label(String text, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      );

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, isDark),
        TextFormField(
          controller: controller,
          enabled: !_saving,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: _decoration(isDark, label, icon),
          validator: validator,
        ),
      ],
    );
  }

  String? _wholeNumber(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    return number == null || number < 0 ? 'Enter zero or a whole number' : null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    return Material(
      color: surface,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(isMobile ? 22 : 16),
        bottom: Radius.circular(isMobile ? 0 : 16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : AppColors.neutral50,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : AppColors.neutral200,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Batch',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.batch.batchNumber,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color:
                              isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_formError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.10),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          _formError!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            height: 1.4,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: _ReadOnlyBatchField(
                            label: 'Farm',
                            value: widget.batch.farmName,
                            icon: Icons.agriculture_outlined,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ReadOnlyBatchField(
                            label: 'Plant Type',
                            value: widget.batch.plantType,
                            icon: Icons.eco_outlined,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _label('Crop Variety', isDark),
                    DropdownButtonFormField<String>(
                      initialValue:
                          _varietyOptions.contains(_variety) ? _variety : null,
                      isExpanded: true,
                      decoration: _decoration(
                        isDark,
                        'Select crop variety',
                        Icons.category_outlined,
                      ),
                      items: _varietyOptions
                          .map(
                            (variety) => DropdownMenuItem(
                              value: variety,
                              child: Text(
                                variety,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() {
                                _variety = value ?? '';
                                _endDate =
                                    _calculateEndDate(_startDate, _variety) ??
                                        _endDate;
                              }),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Select a crop variety'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _EditDateField(
                            label: 'Start Date',
                            value:
                                DateFormat('MMM dd, yyyy').format(_startDate),
                            icon: Icons.calendar_today_outlined,
                            onTap: _saving ? null : _pickStartDate,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EditDateField(
                            label: 'End Date',
                            value: DateFormat('MMM dd, yyyy').format(_endDate),
                            icon: Icons.event_available_outlined,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final fields = [
                          _textField(
                            label: 'Seeds Nursed',
                            controller: _nursedController,
                            icon: Icons.spa_outlined,
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                            validator: _wholeNumber,
                          ),
                          _textField(
                            label: 'Transplanted',
                            controller: _transplantedController,
                            icon: Icons.grass_outlined,
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                            validator: _wholeNumber,
                          ),
                          _textField(
                            label: 'Harvested',
                            controller: _harvestedController,
                            icon: Icons.agriculture_rounded,
                            isDark: isDark,
                            keyboardType: TextInputType.number,
                            validator: _wholeNumber,
                          ),
                          _textField(
                            label: 'Weight (kg)',
                            controller: _weightController,
                            icon: Icons.scale_outlined,
                            isDark: isDark,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              final number =
                                  double.tryParse(value?.trim() ?? '');
                              return number == null || number < 0
                                  ? 'Enter zero or a valid weight'
                                  : null;
                            },
                          ),
                        ];
                        if (constraints.maxWidth < 500) {
                          return Column(
                            children: [
                              for (var i = 0; i < fields.length; i++) ...[
                                fields[i],
                                if (i < fields.length - 1)
                                  const SizedBox(height: 16),
                              ],
                            ],
                          );
                        }
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: fields[0]),
                                const SizedBox(width: 12),
                                Expanded(child: fields[1]),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: fields[2]),
                                const SizedBox(width: 12),
                                Expanded(child: fields[3]),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _label('Production Status', isDark),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      isExpanded: true,
                      decoration: _decoration(
                        isDark,
                        'Production status',
                        Icons.flag_outlined,
                      ),
                      items: _statuses
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status,
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _status = value!),
                    ),
                    const SizedBox(height: 16),
                    _textField(
                      label: 'Notes / Technical Issues',
                      controller: _notesController,
                      icon: Icons.notes_rounded,
                      isDark: isDark,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : AppColors.neutral50,
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
                      onPressed:
                          _saving ? null : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(_saving ? 'Saving...' : 'Save Changes'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyBatchField extends StatelessWidget {
  const _ReadOnlyBatchField({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
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
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.035)
                : AppColors.neutral50,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isDark ? Colors.white10 : AppColors.neutral200,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditDateField extends StatelessWidget {
  const _EditDateField({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : AppColors.neutral50,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isDark ? Colors.white12 : AppColors.neutral200,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
