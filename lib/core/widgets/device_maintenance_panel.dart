import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/device_maintenance_api.dart';
import '../theme/app_typography.dart';
import 'device_registration_form.dart';
import 'maintenance_form_shell.dart';

class DeviceMaintenancePanel extends StatefulWidget {
  const DeviceMaintenancePanel({super.key, this.api});
  final DeviceMaintenanceApi? api;
  @override
  State<DeviceMaintenancePanel> createState() => DeviceMaintenancePanelState();
}

class DeviceMaintenancePanelState extends State<DeviceMaintenancePanel> {
  late final DeviceMaintenanceApi _api;
  bool _loading = true, _refreshing = false;
  String? _error, _deviceId;
  String _filter = 'All';
  List<Map<String, dynamic>> _tasks = [], _history = [], _devices = [];
  @override
  void initState() {
    super.initState();
    _api = widget.api ?? DeviceMaintenanceApi();
    refresh();
  }

  @override
  void dispose() {
    if (widget.api == null) _api.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      final data = await _api.overview();
      if (!mounted) return;
      setState(() {
        _tasks = List<Map<String, dynamic>>.from(data['tasks']);
        _history = List<Map<String, dynamic>>.from(data['history']);
        _devices = List<Map<String, dynamic>>.from(data['devices']);
        if (!_devices.any((device) => device[r'$id'] == _deviceId))
          _deviceId = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
          _refreshing = false;
        });
    }
  }

  Future<void> register() async {
    if (await showDeviceRegistration(context) == true && mounted) refresh();
  }

  Color _statusColor(String status) => switch (status) {
        'Overdue' => Theme.of(context).colorScheme.error,
        'Due soon' => const Color(0xffa86500),
        'Completed' => const Color(0xff23834b),
        _ => Theme.of(context).colorScheme.primary,
      };
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (_loading) return const Center(child: CircularProgressIndicator());
    final records = _filter == 'Completed'
        ? _history
        : _tasks
            .where((task) => _filter == 'All' || task['status'] == _filter)
            .toList();
    return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            Expanded(
                child: Text('Device maintenance',
                    style: AppTypography.titleMedium)),
            IconButton(
                onPressed: _refreshing ? null : refresh,
                tooltip: 'Refresh maintenance',
                icon: const Icon(Icons.refresh))
          ]),
          Text(
              'Cleaning, calibration, servicing and inspections have separate schedules.',
              style: AppTypography.bodySmall),
          const SizedBox(height: 12),
          Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                  onPressed: register,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Register device'))),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 4 : 2;
            return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['Overdue', 'Due soon', 'Scheduled', 'Completed']
                    .map((status) => SizedBox(
                          width: (constraints.maxWidth - (columns - 1) * 10) /
                              columns,
                          child: Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side:
                                      BorderSide(color: colors.outlineVariant)),
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(status,
                                            style: AppTypography.bodySmall),
                                        const SizedBox(height: 6),
                                        Text(
                                            '${status == 'Completed' ? _history.length : _tasks.where((task) => task['status'] == status).length}',
                                            style: AppTypography.titleLarge
                                                .copyWith(
                                                    color:
                                                        _statusColor(status))),
                                      ]))),
                        ))
                    .toList());
          }),
          const SizedBox(height: 16),
          maintenanceField(
              'Configure an existing device',
              DropdownButtonFormField<String>(
                  key: ValueKey(_deviceId),
                  initialValue: _deviceId,
                  isExpanded: true,
                  decoration:
                      maintenanceInput(context, icon: Icons.devices_other),
                  hint: const Text('Select device'),
                  items: _devices
                      .map((device) => DropdownMenuItem(
                          value: '${device[r'$id']}',
                          child: Text(
                              '${device['model_number']} · ${device['serial_number']}',
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (value) => setState(() => _deviceId = value))),
          Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                  onPressed: _deviceId == null
                      ? null
                      : () async {
                          final device = _devices.firstWhere(
                              (device) => device[r'$id'] == _deviceId);
                          if (await showDeviceRegistration(context,
                                      device: device) ==
                                  true &&
                              mounted) refresh();
                        },
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Configure schedules'))),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_error!,
                    style:
                        AppTypography.bodySmall.copyWith(color: colors.error))),
          const SizedBox(height: 12),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['All', 'Overdue', 'Due soon', 'Scheduled', 'Completed']
                  .map((status) => ChoiceChip(
                      label: Text(status),
                      showCheckmark: false,
                      selected: _filter == status,
                      onSelected: (_) => setState(() => _filter = status)))
                  .toList()),
          const SizedBox(height: 16),
          if (records.isEmpty)
            Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                    _filter == 'Completed'
                        ? 'Completed device maintenance will appear here.'
                        : 'No tasks match this filter. Configure a device to schedule its maintenance.',
                    style: AppTypography.bodyMedium)),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1120
                ? 3
                : constraints.maxWidth >= 660
                    ? 2
                    : 1;
            return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: records
                    .map((task) => SizedBox(
                          width: (constraints.maxWidth - (columns - 1) * 12) /
                              columns,
                          child: _card(task),
                        ))
                    .toList());
          }),
        ]));
  }

  Widget _card(Map<String, dynamic> task) {
    final completed = task['status'] == 'Completed';
    final colors = Theme.of(context).colorScheme;
    final kind = maintenanceTypes[task['type']] ?? '${task['type']}';
    final due = DateTime.tryParse(
        '${completed ? task['completed_on'] : task['due_date']}');
    return Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: colors.outlineVariant)),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(
                    switch (task['type']) {
                      'cleaning' => Icons.cleaning_services_outlined,
                      'calibration' => Icons.tune,
                      'inspection' => Icons.fact_check_outlined,
                      _ => Icons.build_outlined
                    },
                    size: 20,
                    color: colors.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(kind, style: AppTypography.titleSmall)),
                Flexible(
                    child: Text('${task['status']}',
                        textAlign: TextAlign.end,
                        style: AppTypography.bodySmall.copyWith(
                            color: _statusColor('${task['status']}'))))
              ]),
              const SizedBox(height: 14),
              Text('${task['device_name']}', style: AppTypography.bodyMedium),
              const SizedBox(height: 4),
              Text('Serial: ${task['serial_number']}',
                  style: AppTypography.bodySmall),
              const SizedBox(height: 4),
              Text('${task['farm_name']}', style: AppTypography.bodySmall),
              const Divider(height: 24),
              Text(
                  '${completed ? 'Completed' : 'Due'}: ${due == null ? 'Not recorded' : DateFormat('dd MMM yyyy').format(due)}',
                  style: AppTypography.bodySmall),
              const SizedBox(height: 6),
              Text(
                  completed
                      ? 'By: ${task['performed_by_name']}'
                      : 'Repeat every ${task['interval_days']} days',
                  style: AppTypography.bodySmall),
              if ('${task['assigned_to_name'] ?? ''}'.isNotEmpty &&
                  !completed) ...[
                const SizedBox(height: 6),
                Text('Assigned: ${task['assigned_to_name']}',
                    style: AppTypography.bodySmall)
              ],
              const SizedBox(height: 14),
              SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                      icon: Icon(
                          completed
                              ? Icons.receipt_long_outlined
                              : Icons.check_circle_outline,
                          size: 18),
                      label:
                          Text(completed ? 'View record' : 'Record completion'),
                      onPressed: () async {
                        final saved = await showMaintenanceRoute(
                            context,
                            MaintenanceCompletionForm(
                                task: task, api: _api, readOnly: completed));
                        if (saved == true && mounted) refresh();
                      })),
            ])));
  }
}

class MaintenanceCompletionForm extends StatefulWidget {
  const MaintenanceCompletionForm(
      {super.key,
      required this.task,
      required this.api,
      this.readOnly = false});
  final Map<String, dynamic> task;
  final DeviceMaintenanceApi api;
  final bool readOnly;
  @override
  State<MaintenanceCompletionForm> createState() =>
      _MaintenanceCompletionFormState();
}

class _MaintenanceCompletionFormState extends State<MaintenanceCompletionForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _work, _results, _followUp;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _work =
        TextEditingController(text: '${widget.task['work_performed'] ?? ''}');
    _results = TextEditingController(
        text: '${widget.task['calibration_results'] ?? ''}');
    _followUp =
        TextEditingController(text: '${widget.task['follow_up'] ?? ''}');
  }

  @override
  void dispose() {
    _work.dispose();
    _results.dispose();
    _followUp.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.complete(widget.task, {
        'due_date': widget.task['due_date'],
        'completed_on': DateFormat('yyyy-MM-dd').format(_date),
        'work_performed': _work.text.trim(),
        'calibration_results': _results.text.trim(),
        'follow_up': _followUp.text.trim()
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _text(String label, TextEditingController controller,
          {bool required = false, int max = 2000}) =>
      maintenanceField(
          label,
          TextFormField(
              controller: controller,
              enabled: !_saving,
              readOnly: widget.readOnly,
              maxLines: 3,
              maxLength: max,
              style: AppTypography.font(fontSize: 12),
              decoration: maintenanceInput(context, icon: Icons.notes),
              validator: (value) => required && (value?.trim().length ?? 0) < 3
                  ? 'Please record $label'
                  : null));
  @override
  Widget build(BuildContext context) => MaintenanceFormShell(
        title: widget.readOnly
            ? 'Maintenance record'
            : 'Complete ${maintenanceTypes[widget.task['type']]?.toLowerCase() ?? 'maintenance'}',
        subtitle:
            '${widget.task['device_name']} · ${widget.task['serial_number']}',
        saving: _saving,
        error: _error,
        action: widget.readOnly ? 'Done' : 'Complete',
        onSave: widget.readOnly ? () => Navigator.pop(context) : _save,
        child: Form(
            key: _form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('${widget.task['farm_name']}',
                      style: AppTypography.bodyMedium),
                  const SizedBox(height: 10),
                  if ('${widget.task['instructions'] ?? ''}'.isNotEmpty)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text('${widget.task['instructions']}',
                            style: AppTypography.bodySmall)),
                  if (widget.readOnly)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                            'Completed ${widget.task['completed_on']} by ${widget.task['performed_by_name']}',
                            style: AppTypography.bodySmall))
                  else
                    maintenanceField(
                        'Completion date',
                        OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today_outlined,
                                size: 16),
                            onPressed: _saving
                                ? null
                                : () async {
                                    final selected = await showDatePicker(
                                        context: context,
                                        initialDate: _date,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime.now());
                                    if (selected != null && mounted)
                                      setState(() => _date = selected);
                                  },
                            label: Text(DateFormat('dd MMM yyyy').format(_date),
                                style: AppTypography.font(fontSize: 12)))),
                  _text('Work performed', _work, required: true, max: 3000),
                  if (widget.task['type'] == 'calibration')
                    _text('Calibration results', _results, required: true),
                  _text('Faults / follow-up needed (optional)', _followUp),
                  if (!widget.readOnly)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                            'Only this task will be completed. Its next due date is calculated from the completion date.',
                            style: AppTypography.bodySmall)),
                ])),
      );
}
