import 'package:flutter/material.dart';
import '../../services/superadmin_api_service.dart';
import '../theme/app_typography.dart';
import '../utils/production_plan.dart';
import 'maintenance_form_shell.dart';

class PlantTypeForm extends StatefulWidget {
  const PlantTypeForm(
      {super.key, required this.api, required this.categories, this.plant});
  final SuperAdminApiService api;
  final List<String> categories;
  final Map<String, dynamic>? plant;
  @override
  State<PlantTypeForm> createState() => _PlantTypeFormState();
}

class _StageFields {
  _StageFields(String name, String days)
      : name = TextEditingController(text: name),
        days = TextEditingController(text: days);
  final TextEditingController name, days;
  void dispose() {
    name.dispose();
    days.dispose();
  }
}

class _PlantTypeFormState extends State<PlantTypeForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name, _image, _min, _max, _interval, _lead;
  final _stages = <_StageFields>[];
  final _retired = <_StageFields>[];
  late String _category, _status, _unit;
  bool _custom = false, _staggered = false, _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final p = widget.plant ?? {};
    final plan = productionPlan(p['production_plan']);
    _name = TextEditingController(text: p['name']?.toString());
    _image = TextEditingController(text: p['imageUrl']?.toString());
    _min = TextEditingController(text: '${p['maturityMin'] ?? 1}');
    _max = TextEditingController(text: '${p['maturityMax'] ?? 1}');
    _category =
        '${p['category'] ?? (widget.categories.isEmpty ? 'Plant Types' : widget.categories.first)}';
    _status = '${p['status'] ?? 'Active'}'.toLowerCase();
    _unit = '${p['maturityUnit'] ?? 'weeks'}';
    _custom = plan.isNotEmpty;
    _staggered = (plan['interval_days'] as num? ?? 0) > 0;
    _interval = TextEditingController(
        text: '${_staggered ? plan['interval_days'] : 14}');
    _lead = TextEditingController(text: '${plan['reminder_days'] ?? 2}');
    for (final stage in productionStages(plan)) {
      _stages.add(_StageFields('${stage['name']}', '${stage['days']}'));
    }
    if (_stages.isEmpty) {
      _stages.add(_StageFields('', ''));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _image, _min, _max, _interval, _lead]) {
      c.dispose();
    }
    for (final stage in [..._stages, ..._retired]) {
      stage.dispose();
    }
    super.dispose();
  }

  Widget field(String label, TextEditingController controller,
          {bool number = false, bool required = true}) =>
      maintenanceField(
          label,
          TextFormField(
            controller: controller,
            enabled: !_saving,
            style: AppTypography.font(fontSize: 12),
            keyboardType: number ? TextInputType.number : TextInputType.text,
            decoration: maintenanceInput(context,
                icon: number ? Icons.schedule_outlined : Icons.edit_outlined),
            onChanged: (_) => setState(() {}),
            validator: (value) {
              if (!required) return null;
              if (value == null || value.trim().isEmpty) return 'Required';
              if (number &&
                  (int.tryParse(value) == null ||
                      int.parse(value) < (controller == _lead ? 0 : 1))) {
                return 'Enter a whole number';
              }
              return null;
            },
          ));

  Widget choice(String label, String value, List<String> options,
          ValueChanged<String> change) =>
      maintenanceField(
          label,
          DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            style: AppTypography.font(
                fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
            decoration: maintenanceInput(context),
            items: options
                .toSet()
                .map((v) => DropdownMenuItem(
                    value: v, child: Text(v, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: _saving
                ? null
                : (v) {
                    if (v != null) setState(() => change(v));
                  },
          ));

  Future<void> _save() async {
    if (_saving || !_key.currentState!.validate()) return;
    final stages = _stages
        .map((s) => {
              'name': s.name.text.trim(),
              'days': int.tryParse(s.days.text) ?? 0
            })
        .toList();
    final days = stages.fold<int>(0, (a, b) => a + (b['days'] as int));
    final min = _custom ? days : int.parse(_min.text);
    final max = _custom ? days : int.parse(_max.text);
    if (max < min) {
      setState(
          () => _error = 'Maximum maturity must not be less than minimum.');
      return;
    }
    final plan = _custom
        ? <String, dynamic>{
            'stages': stages,
            'interval_days': _staggered ? int.parse(_interval.text) : 0,
            'reminder_days': int.parse(_lead.text),
          }
        : <String, dynamic>{};
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.plant == null) {
        await widget.api.createPlantType(
            name: _name.text.trim(),
            category: _category,
            maturityMinValue: min,
            maturityMaxValue: max,
            maturityUnit: _custom ? 'days' : _unit,
            imageFileName: _image.text.trim(),
            status: _status,
            productionPlan: plan);
      } else {
        await widget.api.updatePlantType(
            id: '${widget.plant!['id']}',
            name: _name.text.trim(),
            category: _category,
            maturityMinValue: min,
            maturityMaxValue: max,
            maturityUnit: _custom ? 'days' : _unit,
            imageFileName: _image.text.trim(),
            status: _status,
            productionPlan: plan);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => MaintenanceFormShell(
        title: widget.plant == null ? 'Add plant type' : 'Edit plant type',
        subtitle: 'Growth stages and production timing',
        icon: Icons.eco_outlined,
        saving: _saving,
        onSave: _save,
        error: _error,
        child: Form(
            key: _key,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  field('Plant name', _name),
                  maintenancePair(
                      context,
                      choice(
                          'Category',
                          _category,
                          [...widget.categories, _category],
                          (v) => _category = v),
                      choice('Status', _status, ['active', 'inactive'],
                          (v) => _status = v)),
                  field('Image file name (optional)', _image, required: false),
                  SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Custom growth stages'),
                      subtitle:
                          const Text('Set the ordered stages for new batches.'),
                      value: _custom,
                      onChanged:
                          _saving ? null : (v) => setState(() => _custom = v)),
                  if (!_custom) ...[
                    maintenancePair(
                        context,
                        field('Minimum maturity', _min, number: true),
                        field('Maximum maturity', _max, number: true)),
                    choice('Maturity unit', _unit, ['days', 'weeks', 'months'],
                        (v) => _unit = v),
                  ] else ...[
                    const Text(
                        'Duration is time spent in each stage. Total duration determines the expected harvest date.',
                        style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 14),
                    for (var i = 0; i < _stages.length; i++) ...[
                      Row(children: [
                        Expanded(
                            child: Text('Stage ${i + 1}',
                                style: AppTypography.labelSmall)),
                        IconButton(
                            tooltip: 'Move stage up',
                            onPressed: _saving || i == 0
                                ? null
                                : () => setState(() {
                                      final item = _stages.removeAt(i);
                                      _stages.insert(i - 1, item);
                                    }),
                            icon: const Icon(Icons.arrow_upward, size: 16)),
                        IconButton(
                            tooltip: 'Move stage down',
                            onPressed: _saving || i == _stages.length - 1
                                ? null
                                : () => setState(() {
                                      final item = _stages.removeAt(i);
                                      _stages.insert(i + 1, item);
                                    }),
                            icon: const Icon(Icons.arrow_downward, size: 16)),
                        IconButton(
                            tooltip: 'Remove stage',
                            onPressed: _saving || _stages.length == 1
                                ? null
                                : () => setState(
                                    () => _retired.add(_stages.removeAt(i))),
                            icon: const Icon(Icons.delete_outline, size: 16)),
                      ]),
                      maintenancePair(
                          context,
                          field('Stage name', _stages[i].name),
                          field('Duration (days)', _stages[i].days,
                              number: true)),
                    ],
                    OutlinedButton.icon(
                        onPressed: _saving || _stages.length >= 20
                            ? null
                            : () => setState(
                                () => _stages.add(_StageFields('', ''))),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add stage')),
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                            'Expected maturity: ${_stages.fold<int>(0, (n, s) => n + (int.tryParse(s.days.text) ?? 0))} days',
                            style: AppTypography.bodySmall)),
                    SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Staggered production'),
                        subtitle: const Text(
                            'Start separate batches at a regular interval.'),
                        value: _staggered,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _staggered = v)),
                    if (_staggered)
                      field('Start a new batch every (days)', _interval,
                          number: true),
                    field('Remind before the planned date (days)', _lead,
                        number: true),
                    const Text(
                        'For a two-week cycle enter 14 days. Admins, the assigned farm manager and caretaker receive in-app reminders. Existing batches keep their saved plan.',
                        style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 14),
                  ],
                ])),
      );
}
