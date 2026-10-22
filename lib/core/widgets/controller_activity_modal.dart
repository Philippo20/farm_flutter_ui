import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/command_device_service.dart';
import '../../services/heartbeat_poller.dart';
import '../theme/app_typography.dart';
import 'maintenance_form_shell.dart';

Future<bool?> showControllerActivity(BuildContext context, String serial) =>
    showMaintenanceRoute(context, ControllerActivityModal(serial: serial));

class ControllerActivityModal extends StatefulWidget {
  const ControllerActivityModal(
      {super.key, required this.serial, this.service});
  final String serial;
  final CommandDeviceService? service;
  @override
  State<ControllerActivityModal> createState() =>
      _ControllerActivityModalState();
}

class _ControllerActivityModalState extends State<ControllerActivityModal>
    with WidgetsBindingObserver {
  late final _service = widget.service ?? CommandDeviceService();
  late final _poller = HeartbeatPoller<Map<String, dynamic>>(
      fetch: () => _service.activity(widget.serial),
      cancelFetch: _service.cancelPolling,
      isHeartbeat: (data) => data['online'] == true,
      sourceHeartbeat: (data) => DateTime.tryParse('${data['seen_at']}'));
  final _events = <Map<String, dynamic>>[];
  String? _cursor, _historyError;
  bool _history = false, _loadingHistory = false, _historyLoaded = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poller.addListener(_changed);
    _poller.startPolling();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) return;
    if (state == AppLifecycleState.resumed) {
      _poller.startPolling();
    } else {
      _poller.stopPolling();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poller.removeListener(_changed);
    _poller.dispose();
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  Future<void> _loadHistory({bool more = false}) async {
    if (_loadingHistory) return;
    setState(() {
      _loadingHistory = true;
      _historyError = null;
    });
    try {
      final result = await _service.activityHistory(widget.serial,
          before: more ? _cursor : null);
      if (!mounted) return;
      setState(() {
        if (!more) _events.clear();
        final known = _events.map((e) => e['event_id']).toSet();
        _events.addAll(List<Map<String, dynamic>>.from(result['events'])
            .where((e) => !known.contains(e['event_id'])));
        _cursor = result['next_cursor']?.toString();
        _historyLoaded = true;
      });
    } catch (e) {
      if (mounted) setState(() => _historyError = '$e');
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  String _words(dynamic value) => '${value ?? 'Unknown'}'.replaceAll('_', ' ');
  String _time(dynamic value) {
    final parsed = DateTime.tryParse('$value');
    return parsed == null
        ? 'Not received'
        : DateFormat('d MMM, h:mm:ss a').format(parsed.toLocal());
  }

  Widget _value(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(label, style: AppTypography.bodySmall)),
        const SizedBox(width: 12),
        Flexible(
            child: Text(value,
                textAlign: TextAlign.right, style: AppTypography.bodySmall)),
      ]));
  Widget _section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: AppTypography.titleSmall),
        const SizedBox(height: 10),
        ...children,
      ]));
  Widget _snapshot(Map<String, dynamic> snapshot) {
    final lights = Map<String, dynamic>.from(snapshot['lights'] as Map);
    final feeding = Map<String, dynamic>.from(snapshot['fertigation'] as Map);
    final enabled = Map<String, dynamic>.from(feeding['enabled'] as Map);
    final drainage = Map<String, dynamic>.from(snapshot['drainage'] as Map);
    String on(dynamic value) => value == true ? 'ON' : 'OFF';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _section('Lights', [
        _value('Pair', '${lights['pair']}'),
        _value('Reported outputs',
            'E ${on(lights['E'])} · F ${on(lights['F'])} · P ${on(lights['P'])}'),
        _value(
            'Changeover', lights['changing'] == true ? 'In progress' : 'Idle'),
      ]),
      _section('Fertigation', [
        _value('Enabled racks',
            'E ${on(enabled['E'])} · F ${on(enabled['F'])} · P ${on(enabled['P'])}'),
        _value('Stage', _words(feeding['state'])),
        _value('Pump D12', on(feeding['pump_on'])),
        _value('Selected rack', '${feeding['rack'] ?? 'None'}'),
        _value('Source', _words(feeding['source'])),
        _value('Configured feeding time',
            '${((feeding['configured_duration_ms'] as num) / 1000).toStringAsFixed(1)} s'),
      ]),
      _section('Drainage', [
        for (final entry in {'ef': 'Shared E/F (D11)', 'p': 'P (D10)'}.entries)
          _value(entry.value,
              '${on(drainage[entry.key]['pump_on'])} · Tank ${drainage[entry.key]['tank_full'] == true ? 'full' : 'not full'}'),
      ]),
      _section('Controller', [
        _value('Grid power',
            snapshot['grid_available'] == true ? 'Available' : 'Unavailable'),
        _value('RTC',
            snapshot['rtc_available'] == true ? 'Available' : 'Unavailable'),
        _value('Report received', _time(snapshot['received_at'])),
        _value('Report sequence', '${snapshot['generation']}'),
      ]),
      Text(
          'Outputs are reported relay commands. They do not verify water flow or electrical current.',
          style: AppTypography.bodySmall),
      const SizedBox(height: 14),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final state = _poller.data;
    final snapshot = state?['snapshot'] is Map
        ? Map<String, dynamic>.from(state!['snapshot'])
        : null;
    return MaintenanceFormShell(
        title: 'Controller activity',
        subtitle: widget.serial,
        saving: false,
        dismissLabel: 'Close',
        action: 'Refresh',
        icon: Icons.monitor_heart_outlined,
        onSave: _history
            ? (_loadingHistory ? null : () => _loadHistory())
            : () => _poller.refresh(),
        error: _history ? _historyError : _poller.lastError?.toString(),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Latest report')),
                ButtonSegment(value: true, label: Text('History'))
              ],
              selected: {_history},
              onSelectionChanged: (values) {
                setState(() => _history = values.first);
                if (_history && !_historyLoaded) _loadHistory();
              }),
          const SizedBox(height: 14),
          if (!_history) ...[
            Text(
                _poller.isOnline
                    ? 'Controller online'
                    : !_poller.hasCompleted
                        ? 'Checking controller…'
                        : 'Controller offline',
                style: AppTypography.bodyMedium),
            if (!_poller.isOnline && snapshot != null)
              Text(
                  'Last known report. Current output states are unavailable while the controller is offline.',
                  style: AppTypography.bodySmall),
            if (snapshot != null)
              _snapshot(snapshot)
            else
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                      'No report received for this controller’s current boot session.',
                      style: AppTypography.bodySmall)),
          ] else ...[
            if (!_loadingHistory && _events.isEmpty)
              Text('No activity reports received yet.',
                  style: AppTypography.bodySmall),
            for (final event in _events)
              Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                      childrenPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      title: Text(_words(event['type']),
                          style: AppTypography.bodySmall),
                      subtitle: Text('Received ${_time(event['received_at'])}',
                          style: AppTypography.caption),
                      children: [
                        if ('${event['message'] ?? ''}'.isNotEmpty)
                          Text('${event['message']}',
                              style: AppTypography.bodySmall),
                        if (event['reason'] != null)
                          _value('Reason', _words(event['reason'])),
                        _value('Target', _words(event['target'])),
                        _value('Boot session', '${event['session_id']}'),
                        _snapshot(event),
                      ])),
            if (_loadingHistory)
              const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator())),
            if (_cursor != null && !_loadingHistory)
              TextButton(
                  onPressed: () => _loadHistory(more: true),
                  child: const Text('Load earlier reports')),
          ],
        ]));
  }
}
