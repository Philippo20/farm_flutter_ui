import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/packaging_supervisor_screen_shell.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/fulfillment_data_service.dart';
import '../../services/superadmin_api_service.dart';

class PackageRecordingScreen extends ConsumerStatefulWidget {
  const PackageRecordingScreen({super.key});

  @override
  ConsumerState<PackageRecordingScreen> createState() =>
      _PackageRecordingScreenState();
}

class _PackageRecordingScreenState
    extends ConsumerState<PackageRecordingScreen> {
  final SuperAdminApiService _api = SuperAdminApiService();
  bool _isLoading = true;
  String? _loadError;
  List<Map<String, dynamic>> _lines = [];
  List<Map<String, dynamic>> _packages = [];

  @override
  void initState() {
    super.initState();
    _loadPackagingRecords();
  }

  Future<void> _loadPackagingRecords() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final snapshot = await FulfillmentDataService().load();
      final records = snapshot.fulfillments.where((item) {
        final status = _firstText(item, ['status']).toLowerCase();
        return status == 'packaging' || status == 'packaged';
      });
      final packages = snapshot.packages.where((item) {
        return _firstText(item, ['status']).toLowerCase() == 'active' &&
            _asDouble(item['quantity_available']) > 0;
      }).toList();
      final userNames = <String, String>{
        for (final user in snapshot.users)
          if (_documentId(user).isNotEmpty)
            _documentId(user):
                _firstText(user, ['name'], 'Packaging Supervisor'),
      };

      final lines = records.map((item) {
        final target = _asDouble(item['total_weight']);
        final completed = _asDouble(item['total_packaged_weight']);
        final waste = _asDouble(item['packaging_waste_weight']);
        final unitWeight = _asDouble(item['packaging_weight']);
        final progress =
            target > 0 ? (completed / target).clamp(0.0, 1.0) : 0.0;
        final status = _firstText(item, ['status'], 'Packaging');
        return <String, dynamic>{
          'id': _documentId(item),
          'batch': _firstText(
              item, ['batch_number', 'batch_id'], 'Unassigned batch'),
          'crop': _firstText(
              item, ['plant_variety', 'crop_variety'], 'Unassigned variety'),
          'plantType': _firstText(item, ['plant_type', 'crop']),
          'target': '${target.toStringAsFixed(1)} kg',
          'completed': '${completed.toStringAsFixed(1)} kg',
          'waste': '${waste.toStringAsFixed(1)} kg',
          'packages':
              unitWeight > 0 ? '${(completed / unitWeight).round()}' : '0',
          'operator':
              userNames[_firstText(item, ['packaging_supervisor_id'])] ??
                  'Not recorded',
          'packageType': _firstText(
              item, ['packaging_type'], 'Packaging material not selected'),
          'status': status,
          'progress': progress,
          'color': status.toLowerCase() == 'packaged'
              ? AppColors.success
              : AppColors.primary,
          'raw': item,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _lines = lines;
          _packages = packages;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _openRecordForm(Map<String, dynamic> line) async {
    final crop = line['crop']?.toString() ?? '';
    final compatible = _packages.where((item) {
      final packageCrop = _firstText(item, ['crop_variety_name']);
      return packageCrop.isNotEmpty &&
          packageCrop.toLowerCase() == crop.toLowerCase();
    }).toList();
    final user = ref.read(currentUserProvider);
    final form = _PackagingRecordForm(
      line: line,
      packages: compatible,
      api: _api,
      recorderId: user?.id ?? 'system',
      recorderName: user?.name ?? 'Packaging Supervisor',
    );
    final isMobile = MediaQuery.of(context).size.width < 600;
    final saved = isMobile
        ? await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => form,
          )
        : await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 720, maxHeight: 760),
                child: form,
              ),
            ),
          );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Packaging output recorded.')),
      );
      await _loadPackagingRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PackagingSupervisorScreenShell(
      selectedIndex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: _PackagingQueueSkeleton(),
            )
          else if (_loadError != null)
            _LoadErrorPanel(
              message: _loadError!,
              onRetry: _loadPackagingRecords,
            )
          else ...[
            const _HeroPanel(
              title: 'Package Recording',
              subtitle:
                  'Capture completed packs, active batch movement, and operator accountability by line.',
              icon: Icons.inventory_2_outlined,
              colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _KpiCard(
                  title: 'Total packaged',
                  value:
                      '${_lines.fold<double>(0, (sum, line) => sum + (double.tryParse((line['completed'] as String).split(' ').first) ?? 0)).toStringAsFixed(1)} kg',
                  subtitle: 'Current queue output',
                  icon: Icons.fact_check_outlined,
                  color: AppColors.primary,
                ),
                _KpiCard(
                  title: 'Active lines',
                  value:
                      '${_lines.where((line) => line['status'] == 'Packaging').length}',
                  subtitle: 'Batches in packaging',
                  icon: Icons.precision_manufacturing_outlined,
                  color: AppColors.success,
                ),
                _KpiCard(
                  title: 'Pending entry',
                  value:
                      '${_lines.where((line) => line['status'] == 'Packaging' && line['completed'] == '0.0 kg').length}',
                  subtitle: 'Not recorded yet',
                  icon: Icons.edit_note_outlined,
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Line Recording Queue',
              style: AppTypography.h5.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_lines.isEmpty)
              const _EmptyPackagingQueue()
            else
              _ResponsiveGrid(
                itemCount: _lines.length,
                mobileExtent: 420,
                desktopExtent: 350,
                itemBuilder: (index) => _LineCard(
                  item: _lines[index],
                  onRecord: () => _openRecordForm(_lines[index]),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

double _asDouble(dynamic value) =>
    double.tryParse(value?.toString() ?? '') ?? 0;

String _firstText(Map<String, dynamic> item, List<String> keys,
    [String fallback = '']) {
  for (final key in keys) {
    final value = item[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return fallback;
}

String _documentId(Map<String, dynamic> item) =>
    _firstText(item, [r'$id', 'fulfillment_id', 'package_id']);

double _packageWeightKg(Map<String, dynamic> package) {
  final capacity = _asDouble(package['weight_capacity']);
  switch (_firstText(package, ['unit'], 'kg').toLowerCase()) {
    case 'g':
    case 'gram':
    case 'grams':
      return capacity / 1000;
    case 'mg':
    case 'milligram':
    case 'milligrams':
      return capacity / 1000000;
    case 'lb':
    case 'lbs':
    case 'pound':
    case 'pounds':
      return capacity * 0.45359237;
    case 'oz':
    case 'ounce':
    case 'ounces':
      return capacity * 0.028349523125;
    default:
      return capacity;
  }
}

class _PackagingRecordForm extends StatefulWidget {
  const _PackagingRecordForm({
    required this.line,
    required this.packages,
    required this.api,
    required this.recorderId,
    required this.recorderName,
  });

  final Map<String, dynamic> line;
  final List<Map<String, dynamic>> packages;
  final SuperAdminApiService api;
  final String recorderId;
  final String recorderName;

  @override
  State<_PackagingRecordForm> createState() => _PackagingRecordFormState();
}

class _PackagingRecordFormState extends State<_PackagingRecordForm> {
  final _formKey = GlobalKey<FormState>();
  final _countController = TextEditingController();
  final _wasteController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  Map<String, dynamic>? _selectedPackage;
  String _wasteType = 'None';
  bool _complete = false;
  bool _saving = false;
  String? _error;

  static const _wasteTypes = [
    'None',
    'Trimming loss',
    'Damaged produce',
    'Damaged package',
    'Spillage',
    'Quality rejection',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.packages.length == 1) _selectedPackage = widget.packages.first;
  }

  @override
  void dispose() {
    _countController.dispose();
    _wasteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _count => _asDouble(_countController.text);
  double get _waste => _asDouble(_wasteController.text);
  double get _unitWeight =>
      _selectedPackage == null ? 0 : _packageWeightKg(_selectedPackage!);
  double get _entryWeight => _count * _unitWeight;
  double get _previousOutput => _asDouble(
      (widget.line['raw'] as Map<String, dynamic>)['total_packaged_weight']);
  double get _previousWaste => _asDouble(
      (widget.line['raw'] as Map<String, dynamic>)['packaging_waste_weight']);
  double get _target =>
      _asDouble((widget.line['raw'] as Map<String, dynamic>)['total_weight']);
  double get _remaining =>
      (_target - _previousOutput - _previousWaste).clamp(0, double.infinity);

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPackage == null) {
      setState(() => _error = 'Select the package used for this run.');
      return;
    }
    final available = _asDouble(_selectedPackage!['quantity_available']);
    if (_count > available) {
      setState(() => _error =
          'Only ${available.toStringAsFixed(0)} package units are available.');
      return;
    }
    if (_target > 0 && _entryWeight + _waste > _remaining + 0.05) {
      setState(() => _error =
          'This entry exceeds the remaining ${_remaining.toStringAsFixed(2)} kg.');
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.api.recordPackagingOutput(
        fulfillmentId: widget.line['id'].toString(),
        data: {
          'package_id': _documentId(_selectedPackage!),
          'package_count': _count.round(),
          'waste_weight': _waste,
          'waste_type': _waste > 0 ? _wasteType : 'None',
          'notes': _notesController.text.trim(),
          'complete': _complete,
          'recorded_by_id': widget.recorderId,
          'recorded_by_name': widget.recorderName,
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final background = isDark ? AppColors.surfaceDark : Colors.white;
    return Material(
      color: background,
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(20),
        bottom: Radius.circular(isMobile ? 0 : 20),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (isMobile)
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.neutral300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            _RecordFormHeader(
              batch: widget.line['batch'].toString(),
              onClose: _saving ? null : () => Navigator.of(context).pop(false),
            ),
            Divider(
                height: 1,
                color: isDark ? Colors.white10 : AppColors.neutral200),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BatchSummary(line: widget.line),
                      const SizedBox(height: AppSpacing.lg),
                      if (_error != null) ...[
                        _InlineFormError(message: _error!),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (widget.packages.isEmpty)
                        const _InlineFormError(
                          message:
                              'No active package is configured for this crop. Ask an administrator to add package stock first.',
                        )
                      else
                        _FormFieldLabel(
                          label: 'Package type',
                          child: DropdownButtonFormField<String>(
                            value: _selectedPackage == null
                                ? null
                                : _documentId(_selectedPackage!),
                            isExpanded: true,
                            decoration: _inputDecoration(
                              context,
                              icon: Icons.inventory_2_outlined,
                              hint: 'Select available packaging',
                            ),
                            items: widget.packages.map((package) {
                              final id = _documentId(package);
                              final stock =
                                  _asDouble(package['quantity_available']);
                              return DropdownMenuItem(
                                value: id,
                                child: Text(
                                  '${_firstText(package, [
                                        'package_name'
                                      ])} (${stock.toStringAsFixed(0)} available)',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: _saving
                                ? null
                                : (id) => setState(() {
                                      _selectedPackage =
                                          widget.packages.firstWhere(
                                        (item) => _documentId(item) == id,
                                      );
                                    }),
                            validator: (value) => value == null
                                ? 'Select the package used for this run.'
                                : null,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      LayoutBuilder(builder: (context, constraints) {
                        final paired = !isMobile && constraints.maxWidth >= 560;
                        final countField = _FormFieldLabel(
                          label: 'Package count',
                          child: TextFormField(
                            controller: _countController,
                            keyboardType: TextInputType.number,
                            enabled: !_saving && widget.packages.isNotEmpty,
                            decoration: _inputDecoration(
                              context,
                              icon: Icons.numbers_rounded,
                              hint: 'e.g. 120',
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              final count = int.tryParse(value?.trim() ?? '');
                              if (count == null || count < 1) {
                                return 'Enter at least one package.';
                              }
                              return null;
                            },
                          ),
                        );
                        final wasteField = _FormFieldLabel(
                          label: 'Waste weight (kg)',
                          child: TextFormField(
                            controller: _wasteController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            enabled: !_saving && widget.packages.isNotEmpty,
                            decoration: _inputDecoration(
                              context,
                              icon: Icons.scale_outlined,
                              hint: '0.00',
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              final amount =
                                  double.tryParse(value?.trim() ?? '');
                              return amount == null || amount < 0
                                  ? 'Enter a valid weight.'
                                  : null;
                            },
                          ),
                        );
                        if (!paired) {
                          return Column(children: [
                            countField,
                            const SizedBox(height: AppSpacing.md),
                            wasteField,
                          ]);
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: countField),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: wasteField),
                          ],
                        );
                      }),
                      const SizedBox(height: AppSpacing.md),
                      _FormFieldLabel(
                        label: 'Waste reason',
                        child: DropdownButtonFormField<String>(
                          value: _wasteType,
                          isExpanded: true,
                          decoration: _inputDecoration(
                            context,
                            icon: Icons.delete_outline_rounded,
                            hint: 'Select waste reason',
                          ),
                          items: _wasteTypes
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ))
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _wasteType = value!),
                          validator: (_) => _waste > 0 && _wasteType == 'None'
                              ? 'Select why waste was recorded.'
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FormFieldLabel(
                        label: 'Recording notes (optional)',
                        child: TextFormField(
                          controller: _notesController,
                          enabled: !_saving && widget.packages.isNotEmpty,
                          maxLines: 3,
                          maxLength: 500,
                          decoration: _inputDecoration(
                            context,
                            icon: Icons.notes_rounded,
                            hint: 'Add shift, seal, label, or handling notes',
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _PackagingCalculation(
                        package: _selectedPackage,
                        entryWeight: _entryWeight,
                        cumulativeWeight: _previousOutput + _entryWeight,
                        remainingWeight: (_remaining - _entryWeight - _waste)
                            .clamp(0, double.infinity),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : AppColors.neutral50,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : AppColors.neutral200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_outlined,
                                color: AppColors.primary, size: 22),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Mark this batch ready for quality inspection',
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: _complete,
                              onChanged: _saving
                                  ? null
                                  : (value) =>
                                      setState(() => _complete = value),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(
                height: 1,
                color: isDark ? Colors.white10 : AppColors.neutral200),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50)),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          _saving || widget.packages.isEmpty ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.add_circle_outline_rounded),
                      label: Text(_saving ? 'Recording...' : 'Record output'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(BuildContext context,
    {required IconData icon, required String hint}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTypography.bodySmall.copyWith(
      color: isDark ? Colors.white38 : AppColors.textDisabled,
    ),
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor: isDark ? Colors.white.withOpacity(0.045) : AppColors.neutral50,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide:
          BorderSide(color: isDark ? Colors.white12 : AppColors.neutral300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide:
          BorderSide(color: isDark ? Colors.white12 : AppColors.neutral300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
    ),
  );
}

class _RecordFormHeader extends StatelessWidget {
  const _RecordFormHeader({required this.batch, required this.onClose});
  final String batch;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      child: Row(
        children: [
          const _IconBox(
              icon: Icons.inventory_2_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Record Packaging Output',
                    style: AppTypography.titleSmall.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    )),
                Text('Batch $batch',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                    )),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _FormFieldLabel extends StatelessWidget {
  const _FormFieldLabel({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      );
}

class _BatchSummary extends StatelessWidget {
  const _BatchSummary({required this.line});
  final Map<String, dynamic> line;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.sm,
        children: [
          _SummaryValue(label: 'Crop', value: line['crop'].toString()),
          _SummaryValue(label: 'Received', value: line['target'].toString()),
          _SummaryValue(label: 'Packaged', value: line['completed'].toString()),
          _SummaryValue(label: 'Waste', value: line['waste'].toString()),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 125,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SmallText(label),
            const SizedBox(height: 2),
            Text(value,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _PackagingCalculation extends StatelessWidget {
  const _PackagingCalculation({
    required this.package,
    required this.entryWeight,
    required this.cumulativeWeight,
    required this.remainingWeight,
  });
  final Map<String, dynamic>? package;
  final double entryWeight;
  final double cumulativeWeight;
  final double remainingWeight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border:
            Border.all(color: isDark ? Colors.white10 : AppColors.neutral200),
      ),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.sm,
        children: [
          _SummaryValue(
            label: 'Unit weight',
            value: package == null
                ? 'Select package'
                : '${_packageWeightKg(package!).toStringAsFixed(3)} kg',
          ),
          _SummaryValue(
              label: 'This entry',
              value: '${entryWeight.toStringAsFixed(2)} kg'),
          _SummaryValue(
              label: 'Cumulative',
              value: '${cumulativeWeight.toStringAsFixed(2)} kg'),
          _SummaryValue(
              label: 'Remaining',
              value: '${remainingWeight.toStringAsFixed(2)} kg'),
        ],
      ),
    );
  }
}

class _InlineFormError extends StatelessWidget {
  const _InlineFormError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.error.withOpacity(0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(message,
                  style:
                      AppTypography.bodySmall.copyWith(color: AppColors.error)),
            ),
          ],
        ),
      );
}

class _LoadErrorPanel extends StatelessWidget {
  const _LoadErrorPanel({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InlineFormError(
            message: 'Unable to load packaging records. $message',
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      );
}

class _PackagingQueueSkeleton extends StatelessWidget {
  const _PackagingQueueSkeleton();

  @override
  Widget build(BuildContext context) => const SkeletonPulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 120, borderRadius: AppSpacing.radiusLg),
            SizedBox(height: AppSpacing.lg),
            SkeletonBox(height: 84, borderRadius: AppSpacing.radiusLg),
            SizedBox(height: AppSpacing.lg),
            SkeletonBox(height: 220, borderRadius: AppSpacing.radiusLg),
          ],
        ),
      );
}

class _EmptyPackagingQueue extends StatelessWidget {
  const _EmptyPackagingQueue();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border:
            Border.all(color: isDark ? Colors.white10 : AppColors.neutral200),
      ),
      child: Column(
        children: [
          const _IconBox(
              icon: Icons.inventory_2_outlined, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text('No batches are ready for packaging',
              textAlign: TextAlign.center,
              style: AppTypography.h6.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Batches appear here after fulfillment completes intake inspection and releases them.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class WasteTrackingScreen extends StatefulWidget {
  const WasteTrackingScreen({super.key});

  @override
  State<WasteTrackingScreen> createState() => _WasteTrackingScreenState();
}

class _WasteTrackingScreenState extends State<WasteTrackingScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  double _wasteRate = 0;
  List<Map<String, dynamic>> _waste = [
    {
      'source': 'Trimming loss',
      'batch': 'LTC-24019',
      'amount': '16 kg',
      'reason': 'Outer leaves removed',
      'severity': 'Normal',
      'color': AppColors.success,
    },
    {
      'source': 'Damaged clamshells',
      'batch': 'TMT-24022',
      'amount': '42 units',
      'reason': 'Seal failure on Line B',
      'severity': 'Review',
      'color': AppColors.warning,
    },
    {
      'source': 'Label mismatch',
      'batch': 'BSL-24007',
      'amount': '3 rolls',
      'reason': 'Wrong print batch',
      'severity': 'Critical',
      'color': AppColors.error,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadWasteRecords();
  }

  Future<void> _loadWasteRecords() async {
    try {
      final snapshot = await FulfillmentDataService().load();
      final records = snapshot.fulfillments;
      double number(Map<String, dynamic> item, List<String> keys) {
        for (final key in keys) {
          final value = double.tryParse(item[key]?.toString() ?? '');
          if (value != null) return value;
        }
        return 0;
      }

      String text(Map<String, dynamic> item, List<String> keys,
          [String fallback = '']) {
        for (final key in keys) {
          final value = item[key]?.toString().trim() ?? '';
          if (value.isNotEmpty) return value;
        }
        return fallback;
      }

      final totalPackaged = records.fold<double>(
          0,
          (sum, item) =>
              sum +
              number(item, ['total_packaged_weight', 'packaging_weight']));
      final totalWaste = records.fold<double>(
          0, (sum, item) => sum + number(item, ['packaging_waste_weight']));
      final waste = records
          .where((item) => number(item, ['packaging_waste_weight']) > 0)
          .map((item) {
        final amount = number(item, ['packaging_waste_weight']);
        final severity = amount >= 25
            ? 'Critical'
            : amount >= 10
                ? 'Review'
                : 'Normal';
        return <String, dynamic>{
          'source': text(item, ['packaging_waste_type'], 'Packaging waste'),
          'batch': text(item, ['batch_number', 'batch_id'], 'Unassigned batch'),
          'amount': '${amount.toStringAsFixed(1)} kg',
          'reason': text(item, ['packaging_waste_type'], 'Reason not recorded'),
          'severity': severity,
          'color': severity == 'Critical'
              ? AppColors.error
              : severity == 'Review'
                  ? AppColors.warning
                  : AppColors.success,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _waste = waste;
          _wasteRate = totalPackaged + totalWaste == 0
              ? 0
              : totalWaste / (totalPackaged + totalWaste) * 100;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PackagingSupervisorScreenShell(
      selectedIndex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasError)
            Text(
              'Unable to load waste records from the backend.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            )
          else ...[
            const _HeroPanel(
              title: 'Waste Tracking',
              subtitle:
                  'Monitor packaging waste, isolate loss reasons, and escalate preventable issues quickly.',
              icon: Icons.delete_sweep_outlined,
              colors: [Color(0xFF991B1B), Color(0xFFEA580C)],
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _KpiCard(
                  title: 'Waste rate',
                  value: '${_wasteRate.toStringAsFixed(1)}%',
                  subtitle: 'Below 3% target',
                  icon: Icons.trending_down_outlined,
                  color: AppColors.success,
                ),
                _KpiCard(
                  title: 'Open issues',
                  value: '${_waste.length}',
                  subtitle: 'Need line follow-up',
                  icon: Icons.report_problem_outlined,
                  color: AppColors.warning,
                ),
                _KpiCard(
                  title: 'Critical',
                  value:
                      '${_waste.where((item) => item['severity'] == 'Critical').length}',
                  subtitle: 'Label mismatch',
                  icon: Icons.priority_high_outlined,
                  color: AppColors.error,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Waste Events',
              style: AppTypography.h5.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ResponsiveGrid(
              itemCount: _waste.length,
              mobileExtent: 330,
              desktopExtent: 280,
              itemBuilder: (index) => _WasteCard(item: _waste[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class PackagingProgressScreen extends StatefulWidget {
  const PackagingProgressScreen({super.key});

  @override
  State<PackagingProgressScreen> createState() =>
      _PackagingProgressScreenState();
}

class _PackagingProgressScreenState extends State<PackagingProgressScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  double _averageProgress = 0;
  double _outputRate = 0;
  List<Map<String, dynamic>> _progress = [
    {
      'line': 'Line A',
      'batch': 'LTC-24019',
      'progress': '76%',
      'eta': '24 min',
      'throughput': '184 packs/hr',
      'status': 'On pace',
      'color': AppColors.success,
    },
    {
      'line': 'Line B',
      'batch': 'TMT-24022',
      'progress': '48%',
      'eta': '42 min',
      'throughput': '126 packs/hr',
      'status': 'Watch',
      'color': AppColors.warning,
    },
    {
      'line': 'Line C',
      'batch': 'BSL-24007',
      'progress': '91%',
      'eta': '11 min',
      'throughput': '216 sleeves/hr',
      'status': 'Closing',
      'color': AppColors.primary,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProgressRecords();
  }

  Future<void> _loadProgressRecords() async {
    try {
      final snapshot = await FulfillmentDataService().load();
      final records = snapshot.fulfillments;
      double number(Map<String, dynamic> item, List<String> keys) {
        for (final key in keys) {
          final value = double.tryParse(item[key]?.toString() ?? '');
          if (value != null) return value;
        }
        return 0;
      }

      String text(Map<String, dynamic> item, List<String> keys,
          [String fallback = '']) {
        for (final key in keys) {
          final value = item[key]?.toString().trim() ?? '';
          if (value.isNotEmpty) return value;
        }
        return fallback;
      }

      final rows = records.asMap().entries.map((entry) {
        final item = entry.value;
        final received = number(item, ['total_weight']);
        final packaged =
            number(item, ['total_packaged_weight', 'packaging_weight']);
        final progress =
            received > 0 ? (packaged / received * 100).clamp(0, 100) : 0.0;
        final status = text(item, ['status', 'delivery_status'], 'Pending');
        return <String, dynamic>{
          'line': 'Line ${String.fromCharCode(65 + entry.key)}',
          'batch': text(item, ['batch_number', 'batch_id'], 'Unassigned batch'),
          'progress': '${progress.toStringAsFixed(0)}%',
          'eta': text(item, ['eta'], 'Not set'),
          'throughput': '${packaged.toStringAsFixed(1)} kg',
          'status': status,
          'color': progress < 50 ? AppColors.warning : AppColors.success,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _progress = rows;
          _averageProgress = rows.isEmpty
              ? 0
              : rows
                      .map((row) =>
                          double.tryParse((row['progress'] as String)
                              .replaceAll('%', '')) ??
                          0)
                      .reduce((a, b) => a + b) /
                  rows.length;
          _outputRate = records.fold<double>(
              0,
              (sum, item) =>
                  sum +
                  number(item, ['total_packaged_weight', 'packaging_weight']));
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PackagingSupervisorScreenShell(
      selectedIndex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasError)
            Text(
              'Unable to load progress records from the backend.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            )
          else ...[
            const _HeroPanel(
              title: 'Packaging Progress',
              subtitle:
                  'Track line completion, estimated finish times, and throughput variance in real time.',
              icon: Icons.trending_up_outlined,
              colors: [Color(0xFF1D4ED8), Color(0xFF0F766E)],
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                _KpiCard(
                  title: 'Average progress',
                  value: '${_averageProgress.toStringAsFixed(0)}%',
                  subtitle: 'Across active lines',
                  icon: Icons.pie_chart_outline,
                  color: AppColors.primary,
                ),
                _KpiCard(
                  title: 'Output rate',
                  value: '${_outputRate.toStringAsFixed(1)} kg',
                  subtitle: 'Current velocity',
                  icon: Icons.speed_outlined,
                  color: AppColors.success,
                ),
                _KpiCard(
                  title: 'Line watch',
                  value:
                      '${_progress.where((row) => (double.tryParse((row['progress'] as String).replaceAll('%', '')) ?? 0) < 50).length}',
                  subtitle: 'Line B below pace',
                  icon: Icons.visibility_outlined,
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Line Progress',
              style: AppTypography.h5.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ResponsiveGrid(
              itemCount: _progress.length,
              mobileExtent: 330,
              desktopExtent: 280,
              itemBuilder: (index) => _ProgressCard(item: _progress[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class PackagingSupervisorSettingsScreen extends StatelessWidget {
  const PackagingSupervisorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PackagingSupervisorScreenShell(
      selectedIndex: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroPanel(
            title: 'Packaging Settings',
            subtitle:
                'Manage supervisor preferences, line thresholds, notifications, and package approval rules.',
            icon: Icons.settings_outlined,
            colors: [Color(0xFF334155), Color(0xFF475569)],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsPanel(isDark: isDark),
        ],
      ),
    );
  }
}

class PackagingReportsScreen extends StatelessWidget {
  const PackagingReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PackagingSupervisorScreenShell(
      selectedIndex: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeroPanel(
            title: 'Packaging Reports',
            subtitle:
                'Review packaging output, waste trends, and operational performance.',
            icon: Icons.assessment_outlined,
            colors: [Color(0xFF334155), Color(0xFF1D4ED8)],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isDark ? Colors.white10 : AppColors.neutral200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Library',
                  style: AppTypography.h5.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _ReportRow(
                  title: 'Packaging progress report',
                  subtitle: 'Completed quantity and line throughput',
                  icon: Icons.trending_up_outlined,
                  color: AppColors.primary,
                ),
                _ReportRow(
                  title: 'Waste tracking report',
                  subtitle: 'Waste volume and operational loss rate',
                  icon: Icons.delete_outline,
                  color: AppColors.warning,
                ),
                _ReportRow(
                  title: 'Production activity report',
                  subtitle: 'Packaging records and shift activity',
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ReportRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          _IconBox(icon: icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: isDark ? Colors.white70 : AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  const _HeroPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 46 : 54,
            height: isMobile ? 46 : 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: Colors.white, size: isMobile ? 24 : 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 24 : 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  final int itemCount;
  final double mobileExtent;
  final double desktopExtent;
  final Widget Function(int index) itemBuilder;

  const _ResponsiveGrid({
    required this.itemCount,
    required this.mobileExtent,
    required this.desktopExtent,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.of(context).size.width < 600;
        final columns = constraints.maxWidth >= 820 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: isMobile ? mobileExtent : desktopExtent,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (context, index) => itemBuilder(index),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width =
        MediaQuery.of(context).size.width < 600 ? double.infinity : 240.0;

    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(isDark ? 0.26 : 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _IconBox(icon: icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SmallText(title),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.h5.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                _SmallText(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRecord;

  const _LineCard({required this.item, required this.onRecord});

  @override
  Widget build(BuildContext context) {
    return _OperationalCard(
      color: item['color']! as Color,
      icon: Icons.inventory_2_outlined,
      title: item['batch']! as String,
      subtitle: '${item['crop']} | ${item['packageType']}',
      status: item['status']! as String,
      metrics: [
        _MetricData('Target', item['target']! as String),
        _MetricData('Completed', item['completed']! as String),
        _MetricData('Waste', item['waste']! as String),
        _MetricData('Packages', item['packages']! as String),
        _MetricData('Operator', item['operator']! as String),
      ],
      progress: item['progress']! as double,
      footer: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: item['status'] == 'Packaging' ? onRecord : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(44),
          ),
          icon: Icon(item['status'] == 'Packaging'
              ? Icons.edit_note_rounded
              : Icons.verified_rounded),
          label: Text(item['status'] == 'Packaging'
              ? 'Record output'
              : 'Packaging completed'),
        ),
      ),
    );
  }
}

class _WasteCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _WasteCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return _OperationalCard(
      color: item['color']! as Color,
      icon: Icons.delete_sweep_outlined,
      title: item['source']! as String,
      subtitle: item['reason']! as String,
      status: item['severity']! as String,
      metrics: [
        _MetricData('Batch', item['batch']! as String),
        _MetricData('Amount', item['amount']! as String),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ProgressCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return _OperationalCard(
      color: item['color']! as Color,
      icon: Icons.trending_up_outlined,
      title: item['line']! as String,
      subtitle: item['batch']! as String,
      status: item['status']! as String,
      metrics: [
        _MetricData('Progress', item['progress']! as String),
        _MetricData('ETA', item['eta']! as String),
        _MetricData('Throughput', item['throughput']! as String),
      ],
    );
  }
}

class _OperationalCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final List<_MetricData> metrics;
  final double? progress;
  final Widget? footer;

  const _OperationalCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.metrics,
    this.progress,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        gradient: LinearGradient(
          colors: [
            isDark ? AppColors.surfaceDark : Colors.white,
            color.withOpacity(isDark ? 0.08 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(isDark ? 0.28 : 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBox(icon: icon, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h6.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: status, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: metrics
                .map((metric) => _MetricPill(metric: metric, color: color))
                .toList(),
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor:
                          isDark ? Colors.white10 : AppColors.neutral200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${(progress! * 100).toStringAsFixed(0)}%',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (footer != null) ...[
            const Spacer(),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  final bool isDark;

  const _SettingsPanel({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.14 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: const [
          _SettingRow(
            title: 'Require supervisor approval',
            subtitle: 'Hold package records before final dispatch posting.',
            icon: Icons.verified_user_outlined,
            enabled: true,
          ),
          _SettingRow(
            title: 'Waste escalation alerts',
            subtitle: 'Notify when waste events exceed line threshold.',
            icon: Icons.notifications_active_outlined,
            enabled: true,
          ),
          _SettingRow(
            title: 'Auto-close completed batches',
            subtitle: 'Close batches when target packaging count is reached.',
            icon: Icons.task_alt_outlined,
            enabled: false,
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;

  const _SettingRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          _IconBox(icon: icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: (_) {}),
        ],
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;

  const _MetricData(this.label, this.value);
}

class _MetricPill extends StatelessWidget {
  final _MetricData metric;
  final Color color;

  const _MetricPill({required this.metric, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SmallText(metric.label),
          const SizedBox(height: 4),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _SmallText extends StatelessWidget {
  final String text;

  const _SmallText(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.caption.copyWith(
        color: isDark ? Colors.white60 : AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 136),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
