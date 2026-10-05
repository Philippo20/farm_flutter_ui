import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/device_maintenance_api.dart';
import '../theme/app_typography.dart';
import 'maintenance_form_shell.dart';

const maintenanceTypes = {
  'cleaning': 'Cleaning',
  'calibration': 'Calibration',
  'servicing': 'Servicing',
  'inspection': 'Inspection'
};
const registeredDeviceTypes = {
  'temperature': 'Temperature',
  'water_temperature': 'Water temperature',
  'humidity': 'Humidity',
  'Carbon Dioxide': 'CO2',
  'light': 'Light',
  'light_switch': 'Light switch',
  'pH Level': 'pH sensor',
  'EC Level': 'EC sensor',
  'Water level': 'Water level',
  'electricity_current': 'Current',
  'electricity_voltage': 'Voltage',
  'electricity_wattage': 'Wattage',
  'VPD': 'VPD',
  'air_conditioner': 'Air conditioner',
};

Future<bool?> showDeviceRegistration(BuildContext context,
        {Map<String, dynamic>? device}) =>
    showMaintenanceRoute(context, DeviceRegistrationForm(device: device));

class _PlanDraft {
  _PlanDraft(this.type, [Map<String, dynamic>? initial])
      : id = initial?['id']?.toString() ?? '',
        enabled = initial != null,
        due = DateTime.tryParse('${initial?['first_due']}') ??
            DateTime.now().add(const Duration(days: 30)),
        days =
            TextEditingController(text: '${initial?['interval_days'] ?? 30}'),
        instructions =
            TextEditingController(text: '${initial?['instructions'] ?? ''}');
  final String type, id;
  bool enabled;
  DateTime due;
  final TextEditingController days, instructions;
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'interval_days': int.parse(days.text),
        'first_due': DateFormat('yyyy-MM-dd').format(due),
        'assigned_to_id': '',
        'instructions': instructions.text.trim()
      };
  void dispose() {
    days.dispose();
    instructions.dispose();
  }
}

class DeviceRegistrationForm extends StatefulWidget {
  const DeviceRegistrationForm({super.key, this.device, this.api});
  final Map<String, dynamic>? device;
  final DeviceMaintenanceApi? api;
  @override
  State<DeviceRegistrationForm> createState() => _DeviceRegistrationFormState();
}

class _DeviceRegistrationFormState extends State<DeviceRegistrationForm> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  final _plans = <_PlanDraft>[];
  late final DeviceMaintenanceApi _api;
  List<Map<String, dynamic>> _farms = [];
  String? _farm;
  String _type = 'temperature', _status = 'Active';
  bool _alerts = true, _saving = false, _loading = true;
  String? _error;
  bool _maintenanceReviewed = true;
  bool get _equipment => _type == 'air_conditioner' || _type == 'light_switch';
  @override
  void initState() {
    super.initState();
    _api = widget.api ?? DeviceMaintenanceApi();
    final device = widget.device ?? <String, dynamic>{};
    for (final key in [
      'model_number',
      'serial_number',
      'location',
      'value',
      'unit',
      'range_min',
      'range_max',
      'warning_min',
      'warning_max'
    ]) {
      _fields[key] = TextEditingController(text: '${device[key] ?? ''}');
    }
    _type = '${device['sensortype'] ?? 'temperature'}';
    _farm = device['farmID']?.toString();
    _status = '${device['status'] ?? 'Active'}';
    _alerts = device['alerts_enabled'] != false;
    if (widget.device == null) _fields['unit']!.text = _unit(_type);
    final raw = device['maintenance_plan'];
    final oldFrequency =
        '${device['maintenance_frequency'] ?? ''}'.trim().toLowerCase();
    _maintenanceReviewed =
        raw != null || oldFrequency.isEmpty || oldFrequency == 'not required';
    final plans = raw is String && raw.isNotEmpty
        ? jsonDecode(raw) as List
        : raw is List
            ? raw
            : <dynamic>[];
    for (final type in maintenanceTypes.keys) {
      final matches = plans.where((plan) => plan['type'] == type);
      _plans.add(_PlanDraft(type,
          matches.isEmpty ? null : Map<String, dynamic>.from(matches.first)));
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.options();
      if (!mounted) return;
      setState(() {
        _farms = List<Map<String, dynamic>>.from(result['farms']);
        _loading = false;
      });
    } catch (error) {
      if (mounted)
        setState(() {
          _error = error.toString();
          _loading = false;
        });
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    for (final plan in _plans) {
      plan.dispose();
    }
    if (widget.api == null) _api.dispose();
    super.dispose();
  }

  String _unit(String type) => switch (type) {
        'temperature' || 'water_temperature' => '°C',
        'humidity' => '%',
        'pH Level' => 'pH',
        'EC Level' => 'mS/cm',
        'Carbon Dioxide' => 'ppm',
        'light' => 'lux',
        'VPD' => 'psi',
        'light_switch' => 'state',
        'air_conditioner' => 'equipment',
        _ => '',
      };
  void _suggestTasks() {
    setState(() {
      _maintenanceReviewed = true;
      for (final plan in _plans) {
        plan.enabled = switch (_type) {
          'pH Level' ||
          'EC Level' =>
            ['cleaning', 'calibration'].contains(plan.type),
          'air_conditioner' =>
            ['cleaning', 'servicing', 'inspection'].contains(plan.type),
          _ => plan.type == 'inspection',
        };
      }
    });
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (!_maintenanceReviewed) {
      setState(() => _error =
          'Review the previous maintenance schedule: choose tasks or explicitly select No scheduled maintenance.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final data = <String, dynamic>{
        'farmID': _farm,
        'sensortype': _type,
        'status': _status,
        'model_number': _fields['model_number']!.text.trim(),
        'serial_number': _fields['serial_number']!.text.trim(),
        'location': _fields['location']!.text.trim(),
        'unit': _equipment ? _unit(_type) : _fields['unit']!.text.trim(),
        'value': _equipment ? 0 : double.tryParse(_fields['value']!.text) ?? 0,
        'alerts_enabled': _equipment ? false : _alerts,
        'plans': _plans
            .where((plan) => plan.enabled)
            .map((plan) => plan.toJson())
            .toList(),
        for (final key in [
          'range_min',
          'range_max',
          'warning_min',
          'warning_max'
        ])
          key: _equipment ? null : double.tryParse(_fields[key]!.text),
      };
      await _api.saveDevice(data, id: widget.device?[r'$id']?.toString());
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _input(String key, String label,
          {bool required = false, bool number = false}) =>
      maintenanceField(
          label,
          TextFormField(
            controller: _fields[key],
            enabled: !_saving,
            style: AppTypography.font(fontSize: 12),
            keyboardType: number
                ? const TextInputType.numberWithOptions(
                    decimal: true, signed: true)
                : TextInputType.text,
            decoration: maintenanceInput(context,
                icon: number ? Icons.numbers : Icons.edit_outlined),
            validator: (value) {
              if (required && (value?.trim().isEmpty ?? true))
                return 'Enter $label';
              if (number &&
                  value!.isNotEmpty &&
                  (double.tryParse(value)?.isFinite != true))
                return 'Enter a valid number';
              return null;
            },
          ));
  @override
  Widget build(BuildContext context) {
    return MaintenanceFormShell(
      title: widget.device == null ? 'Register device' : 'Update device',
      subtitle: 'Device details and maintenance schedules',
      saving: _saving,
      onSave: _loading || _farms.isEmpty ? null : _save,
      error: _error,
      child: _loading
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()))
          : Form(
              key: _form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_farms.isEmpty) ...[
                      const Text('No assigned farms are available.'),
                      TextButton(onPressed: _load, child: const Text('Retry'))
                    ],
                    maintenanceField(
                        'Farm',
                        DropdownButtonFormField<String>(
                          initialValue:
                              _farms.any((farm) => farm[r'$id'] == _farm)
                                  ? _farm
                                  : null,
                          isExpanded: true,
                          style: AppTypography.font(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface),
                          decoration: maintenanceInput(context,
                              icon: Icons.agriculture_outlined),
                          items: _farms
                              .map((farm) => DropdownMenuItem(
                                  value: farm[r'$id'].toString(),
                                  child: Text('${farm['name']}',
                                      overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: _saving || widget.device != null
                              ? null
                              : (value) => setState(() => _farm = value),
                          validator: (value) =>
                              value == null ? 'Select an assigned farm' : null,
                        )),
                    maintenanceField(
                        'Device type',
                        DropdownButtonFormField<String>(
                          initialValue: _type,
                          isExpanded: true,
                          style: AppTypography.font(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface),
                          decoration: maintenanceInput(context,
                              icon: Icons.devices_other),
                          items: {
                            ...registeredDeviceTypes,
                            if (!registeredDeviceTypes.containsKey(_type))
                              _type: _type
                          }
                              .entries
                              .map((item) => DropdownMenuItem(
                                  value: item.key,
                                  child: Text(item.value,
                                      overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() {
                                    _type = value!;
                                    _fields['unit']!.text = _unit(_type);
                                  }),
                        )),
                    maintenancePair(
                        context,
                        _input('model_number', 'Device name / model',
                            required: true),
                        _input('location', 'Location', required: true)),
                    _input(
                        'serial_number', 'Serial number (generated if blank)'),
                    maintenanceField(
                        'Status',
                        DropdownButtonFormField<String>(
                          initialValue: _status,
                          isExpanded: true,
                          style: AppTypography.font(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface),
                          decoration: maintenanceInput(context,
                              icon: Icons.info_outline),
                          items: ['Active', 'Inactive', 'Faulty', 'Maintenance']
                              .map((item) => DropdownMenuItem(
                                  value: item, child: Text(item)))
                              .toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _status = value!),
                        )),
                    if (!_equipment) ...[
                      if (widget.device == null)
                        _input('value', 'Initial reading (optional)',
                            number: true),
                      _input('unit', 'Reading unit', required: true),
                      maintenancePair(
                          context,
                          _input('range_min', 'Good range: low', number: true),
                          _input('range_max', 'Good range: high',
                              number: true)),
                      maintenancePair(
                          context,
                          _input('warning_min', 'Warning range: low',
                              number: true),
                          _input('warning_max', 'Warning range: high',
                              number: true)),
                      SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Reading alerts',
                              style: AppTypography.bodySmall),
                          value: _alerts,
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _alerts = value)),
                    ],
                    const Divider(height: 24),
                    Text('Maintenance tasks', style: AppTypography.titleSmall),
                    const SizedBox(height: 6),
                    Text(
                        'Select the work this device needs. Each task has its own schedule. Use the manufacturer\'s recommended intervals.',
                        style: AppTypography.bodySmall),
                    if (widget.device != null &&
                        widget.device!['maintenance_plan'] == null)
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                              'Previous schedule: ${widget.device!['maintenance_frequency'] ?? 'Not recorded'}. Select tasks below to replace it with individual schedules.',
                              style: AppTypography.bodySmall)),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                            onPressed: _saving ? null : _suggestTasks,
                            child: const Text('Suggest task types'))),
                    CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text('No scheduled maintenance',
                            style: AppTypography.bodySmall),
                        value: !_plans.any((plan) => plan.enabled),
                        onChanged: _saving
                            ? null
                            : (value) {
                                setState(() {
                                  for (final plan in _plans) {
                                    plan.enabled = false;
                                    _maintenanceReviewed = true;
                                  }
                                });
                              }),
                    for (final plan in _plans) ...[
                      CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(maintenanceTypes[plan.type]!,
                              style: AppTypography.bodySmall),
                          value: plan.enabled,
                          onChanged: _saving
                              ? null
                              : (value) => setState(() {
                                    _maintenanceReviewed = true;
                                    plan.enabled = value!;
                                  })),
                      if (plan.enabled) ...[
                        maintenancePair(
                          context,
                          maintenanceField(
                              'Repeat every (days)',
                              TextFormField(
                                  controller: plan.days,
                                  enabled: !_saving,
                                  style: AppTypography.font(fontSize: 12),
                                  keyboardType: TextInputType.number,
                                  decoration: maintenanceInput(context,
                                      icon: Icons.repeat),
                                  validator: (value) =>
                                      (int.tryParse(value ?? '') ?? 0) < 1 ||
                                              (int.tryParse(value ?? '') ?? 0) >
                                                  3650
                                          ? 'Use 1 to 3650 days'
                                          : null)),
                          maintenanceField(
                              'First due date',
                              OutlinedButton.icon(
                                  icon: const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 16),
                                  onPressed: _saving
                                      ? null
                                      : () async {
                                          final selected = await showDatePicker(
                                              context: context,
                                              initialDate: plan.due,
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2100));
                                          if (selected != null && mounted)
                                            setState(() => plan.due = selected);
                                        },
                                  label: Text(
                                      DateFormat('dd MMM yyyy')
                                          .format(plan.due),
                                      style:
                                          AppTypography.font(fontSize: 12)))),
                        ),
                        maintenanceField(
                            'Instructions (optional)',
                            TextFormField(
                                controller: plan.instructions,
                                enabled: !_saving,
                                maxLines: 2,
                                maxLength: 1000,
                                style: AppTypography.font(fontSize: 12),
                                decoration: maintenanceInput(context,
                                    icon: Icons.notes))),
                      ],
                    ],
                    Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                            'Tasks use the technician assigned to this farm. Completing cleaning will not complete calibration or servicing.',
                            style: AppTypography.bodySmall)),
                  ])),
    );
  }
}
