import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/command_device_service.dart';
import '../../services/heartbeat_poller.dart';
import '../../services/calibration_controls.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_dialog.dart';
import 'crop_variety_modal_frame.dart';

const calibrationLabels = {
  'request_received': 'Selection received',
  'waiting_for_start': 'Ready to start',
  'starting': 'Preparing calibration',
  'running': 'Measuring',
  'completed': 'Completed',
  'cancelled': 'Cancelled',
  'rejected': 'Cannot proceed',
  'not_saved': 'Measurement not saved',
};
const calibrationReasons = {
  'grid_power_lost': 'Grid power was lost',
  'grid_power_unavailable': 'Grid power is unavailable',
  'tank_not_full': 'The drainage tank must be full',
  'all_racks_disabled': 'All racks are disabled',
  'selected_rack_disabled': 'The selected rack is disabled',
  'calibration_already_running': 'Another calibration is already running',
  'no_calibration_selected': 'Select a calibration before starting',
  'pump_start_delay': 'Waiting for the pump safety interval',
  'pump_not_started': 'The pump had not started',
  'maximum_duration_reached': 'The maximum safety duration was reached',
  'duration_too_short': 'The measurement was too short to save',
  'user_cancelled': 'Cancelled by the user',
  'command_expired': 'The command expired before execution',
};
String calibrationTarget(Map data) => switch (data['target']) {
      'ef_drain' => 'EF Drain',
      'p_drain' => 'P Drain',
      'fertigation' => 'Fertigation · Rack ${data['rack']}',
      _ => 'Calibration'
    };
String calibrationDuration(dynamic value) {
  if (value is! num) return 'Not recorded';
  final seconds = value / 1000;
  final text = seconds
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
  return '$text s';
}

String calibrationMessage(Map event) {
  final message = '${event['message'] ?? ''}';
  return message.isNotEmpty
      ? message
      : calibrationReasons[event['reason']] ??
          'The controller rejected this request.';
}

Future<void> showDeviceCalibration(
  BuildContext context, {
  required String serial,
  required HeartbeatPoller<Map<String, dynamic>> deviceState,
  required bool allowSend,
  CommandDeviceService? api,
}) =>
    showAppDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => DeviceCalibrationModal(
            serial: serial,
            deviceState: deviceState,
            allowSend: allowSend,
            api: api));

class DeviceCalibrationModal extends StatefulWidget {
  const DeviceCalibrationModal(
      {super.key,
      required this.serial,
      required this.deviceState,
      required this.allowSend,
      this.api,
      this.embedded = false});
  final String serial;
  final HeartbeatPoller<Map<String, dynamic>> deviceState;
  final bool allowSend;
  final CommandDeviceService? api;

  /// Reuse the same controller-confirmed workflow directly on a device card.
  final bool embedded;
  @override
  State<DeviceCalibrationModal> createState() => _DeviceCalibrationModalState();
}

class _DeviceCalibrationModalState extends State<DeviceCalibrationModal>
    with WidgetsBindingObserver {
  late final _api = widget.api ?? CommandDeviceService();
  late final HeartbeatPoller<Map<String, dynamic>> _poller;
  final _events = <String, Map<String, dynamic>>{};
  String? _cursor, _selected, _error;
  String? _pendingAction,
      _pendingRequestId,
      _pendingCalibrationId,
      _pendingBoot;
  String? _handledTerminal;
  Map? _acknowledgement;
  String? _ackAction, _ackCalibrationId, _activeCalibrationId;
  String? _pendingPreviousCalibrationId;
  String? _submissionId;
  CalibrationStage _stage = CalibrationStage.selection;
  CalibrationStage _baseline = CalibrationStage.selection;
  bool _sending = false,
      _loadingHistory = false,
      _refreshing = false,
      _historyStarted = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.deviceState.addListener(_deviceChanged);
    _poller = HeartbeatPoller<Map<String, dynamic>>(
        fetch: () => _api.calibrations(widget.serial),
        cancelFetch: _api.cancelPolling)
      ..addListener(_changed);
    _poller.startPolling();
  }

  void _deviceChanged() {
    if (!mounted) return;
    _syncWorkflow();
    final last = widget.deviceState.data?['last_command'] as Map?;
    if (_pendingRequestId != null &&
        last?['id'] == _pendingRequestId &&
        ['failed', 'expired'].contains(last?['status'])) {
      _error =
          '${last?['result'] ?? 'Command ${last?['status']}. Check the controller before retrying.'}';
      _stage = _baseline;
      _activeCalibrationId = _pendingPreviousCalibrationId;
      _clearPending();
    }
    setState(() {});
  }

  void _changed() {
    if (!mounted) return;
    for (final item in (_poller.data?['recent_events'] as List? ?? [])) {
      final event = Map<String, dynamic>.from(item as Map);
      _events['${event['event_id']}'] = event;
    }
    if (!_historyStarted) _cursor = _poller.data?['next_cursor'] as String?;
    _syncWorkflow();
    setState(() {});
  }

  void _clearPending() {
    _sending = false;
    _submissionId = null;
    _pendingAction =
        _pendingRequestId = _pendingCalibrationId = _pendingBoot = null;
    _pendingPreviousCalibrationId = null;
  }

  String? get _confirmationMessage => _ackCalibrationId != _activeCalibrationId
      ? null
      : switch (_ackAction) {
          'select' => 'Selection confirmed',
          'start' => 'Start confirmed. Waiting for measurement status.',
          'stop' => 'Stop confirmed. Waiting for the calibration result.',
          'cancel' =>
            'Cancellation confirmed. Previous saved measurements retained.',
          _ => null,
        };

  void _observeAcknowledgement(Map? current, dynamic boot) {
    final command = widget.deviceState.data?['last_command'] as Map?;
    if (command == null || command['status'] != 'confirmed' || boot == null) {
      return;
    }
    final matchesPending = command['id'] == _pendingRequestId;
    if (_pendingRequestId != null && !matchesPending) return;
    if (command['session_id'] != boot &&
        !(matchesPending && _pendingBoot == boot)) {
      return;
    }
    final action = calibrationCommandAction(command['value'] as String?) ??
        (matchesPending ? _pendingAction : null);
    if (action == null || command['id'] == _acknowledgement?['id']) return;
    final created = DateTime.tryParse('${command['created_at']}');
    final prior = DateTime.tryParse('${_acknowledgement?['created_at']}');
    if (!matchesPending &&
        _acknowledgement != null &&
        (created == null || prior == null || !created.isAfter(prior))) {
      return;
    }
    _ackCalibrationId = action == 'select'
        ? command['id'] as String?
        : _pendingCalibrationId ??
            _activeCalibrationId ??
            (current?['session_id'] == boot
                ? (current?['calibration_id'] as String?)
                : null);
    _activeCalibrationId = _ackCalibrationId;
    _acknowledgement = Map.of(command)..['session_id'] = boot;
    _ackAction = action;
    _error = null;
    if (matchesPending) _clearPending();
    if (action == 'stop' || action == 'cancel') _selected = null;
    // Promptly reconcile telemetry too, without blocking the acknowledged UI.
    unawaited(_poller.refresh());
  }

  void _applyAcknowledgementStage() {
    if (_acknowledgement == null || _ackCalibrationId != _activeCalibrationId) {
      return;
    }
    _stage = switch (_ackAction) {
      'select' => CalibrationStage.ready,
      'start' => CalibrationStage.running,
      _ => CalibrationStage.selection,
    };
  }

  void _syncWorkflow() {
    final data = _poller.data;
    final current = data?['current'] as Map?;
    final attempt = data?['latest_attempt'] as Map?;
    final boot = widget.deviceState.data?['controller_session_id'];
    if (_pendingBoot != null && boot != null && _pendingBoot != boot) {
      _clearPending();
      _activeCalibrationId = null;
      _stage = CalibrationStage.selection;
    }
    if (_acknowledgement != null && _acknowledgement?['session_id'] != boot) {
      _acknowledgement = null;
      _ackAction = _ackCalibrationId = _activeCalibrationId = null;
      _stage = CalibrationStage.selection;
    }
    _observeAcknowledgement(current, boot);
    _applyAcknowledgementStage();
    Map? session = current;
    if (_activeCalibrationId != null || _pendingCalibrationId != null) {
      session = [current, attempt]
          .whereType<Map>()
          .where((s) =>
              s['calibration_id'] ==
              (_activeCalibrationId ?? _pendingCalibrationId))
          .firstOrNull;
      if (session == null) {
        return; // An older run cannot confirm a new selection.
      }
    }
    if (session == null) return;
    if (boot != null &&
        session['session_id'] != null &&
        session['session_id'] != boot) {
      _stage = CalibrationStage.selection;
      return;
    }
    final status = session['status'];
    final event = session['event'] as Map?;
    final latest = session['latest_event'] as Map? ?? event;
    final terminal = ['completed', 'cancelled', 'not_saved'].contains(status);
    if (terminal) {
      _stage = CalibrationStage.selection;
      if (_handledTerminal != event?['event_id']) {
        _handledTerminal = event?['event_id'] as String?;
        _selected = null;
        _error = null;
      }
      _clearPending();
      _ackAction = null;
      return;
    }
    if (_pendingRequestId != null &&
        latest?['type'] == 'calibration.rejected' &&
        (latest?['command_id'] == _pendingRequestId ||
            (_pendingAction == 'select' &&
                session['calibration_id'] == _pendingRequestId))) {
      _error = calibrationMessage(latest!);
      _clearPending();
    }
    _stage = calibrationStage(session);
    final rejectsAck = latest?['type'] == 'calibration.rejected' &&
        latest?['command_id'] == _acknowledgement?['id'];
    if (!rejectsAck && _ackCalibrationId == session['calibration_id']) {
      // Progress can advance beyond a selection ACK; a delayed earlier event
      // cannot undo a confirmed Start, Stop or Cancel command.
      if ((_ackAction == 'start' && _stage != CalibrationStage.running) ||
          _ackAction == 'stop' ||
          _ackAction == 'cancel' ||
          (_ackAction == 'select' && _stage == CalibrationStage.selecting)) {
        _applyAcknowledgementStage();
      }
    }
    if (rejectsAck) _ackAction = null;
    if ((_pendingAction == 'select' &&
            [CalibrationStage.ready, CalibrationStage.running]
                .contains(_stage)) ||
        (_pendingAction == 'start' && _stage == CalibrationStage.running)) {
      _clearPending();
    }
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
    widget.deviceState.removeListener(_deviceChanged);
    _poller.removeListener(_changed);
    _poller.dispose();
    if (widget.api == null) _api.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await _poller.refresh();
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _loadHistory() async {
    if (_loadingHistory || _cursor == null) return;
    setState(() {
      _loadingHistory = true;
      _error = null;
    });
    try {
      final page =
          await _api.calibrationHistory(widget.serial, before: _cursor);
      if (!mounted) return;
      setState(() {
        for (final item in page['events'] as List) {
          final event = Map<String, dynamic>.from(item as Map);
          _events['${event['event_id']}'] = event;
        }
        _historyStarted = true;
        _cursor = page['next_cursor'] as String?;
      });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _send([String action = 'select']) async {
    final state = widget.deviceState.data;
    final commands =
        CalibrationCommands(deviceNamedCommands(state?['commands']));
    final command =
        action == 'select' ? _selected : commands.action(action)?['id'];
    if (_sending ||
        !widget.allowSend ||
        !widget.deviceState.isOnline ||
        state?['ready'] != true ||
        command == null ||
        (_pendingAction != null &&
            (action != 'cancel' || _pendingAction == 'cancel'))) {
      return;
    }
    final request = newCommandId();
    final current = _poller.data?['current'] as Map?;
    final calibrationId = action == 'select'
        ? request
        : _activeCalibrationId ??
            _pendingCalibrationId ??
            current?['calibration_id'] as String?;
    setState(() {
      _baseline = _stage == CalibrationStage.selecting
          ? CalibrationStage.selection
          : _stage;
      _pendingAction = action;
      _pendingPreviousCalibrationId = _activeCalibrationId;
      _activeCalibrationId = calibrationId;
      _pendingRequestId = request;
      _pendingCalibrationId = calibrationId;
      _pendingBoot = state?['controller_session_id'] as String?;
      if (action == 'select') _stage = CalibrationStage.selecting;
      _sending = true;
      _submissionId = request;
      _error = null;
    });
    try {
      final result = await _api.send(widget.serial, command, request,
          revision: state?['config_revision']?.toString());
      if (!mounted || _submissionId != request) return;
      widget.deviceState.acceptData(result);
      unawaited(_poller.refresh());
    } catch (error) {
      if (mounted && _pendingRequestId == request) {
        setState(() {
          _error = '$error';
          _stage = _baseline;
          _activeCalibrationId = _pendingPreviousCalibrationId;
          _clearPending();
        });
      }
    } finally {
      if (mounted && _submissionId == request) {
        setState(() {
          _sending = false;
          _submissionId = null;
        });
      }
    }
  }

  TextStyle _font([double size = 12, FontWeight weight = FontWeight.normal]) =>
      AppTypography.font(fontSize: size, fontWeight: weight);
  Widget _box(Widget child, {Color? tint}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: tint ?? colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.outlineVariant)),
        child: child);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mobile = MediaQuery.sizeOf(context).width < 600 ||
        Theme.of(context).platform == TargetPlatform.android;
    final data = _poller.data;
    final snapshot = data?['current'] as Map?;
    final attempt = data?['latest_attempt'] as Map?;
    final current = _activeCalibrationId == null ||
            snapshot?['calibration_id'] == _activeCalibrationId
        ? snapshot
        : attempt?['calibration_id'] == _activeCalibrationId
            ? attempt
            : null;
    final event = current?['event'] as Map?;
    final status = current?['status'] as String?;
    final latest = (data?['latest_attempt'] as Map?)?['latest_event'] as Map?;
    final online = widget.deviceState.isOnline;
    final active = [
          'request_received',
          'waiting_for_start',
          'starting',
          'running'
        ].contains(status) ||
        [
          CalibrationStage.selecting,
          CalibrationStage.ready,
          CalibrationStage.running
        ].contains(_stage);
    final confirmation = _ackAction == 'start' &&
            status == 'running' &&
            current?['calibration_id'] == _activeCalibrationId
        ? null
        : _confirmationMessage;
    final controllerSession = widget.deviceState.data?['controller_session_id'];
    final restarted = active &&
        current != null &&
        controllerSession != null &&
        current['session_id'] != controllerSession &&
        _acknowledgement?['session_id'] != controllerSession;
    final unknown = active && (!online || restarted);
    final commands = CalibrationCommands(
        deviceNamedCommands(widget.deviceState.data?['commands']));
    if (!commands.selections.any((c) => c['id'] == _selected)) _selected = null;
    final canSend = widget.allowSend &&
        online &&
        !_sending &&
        widget.deviceState.data?['ready'] == true;
    if (widget.embedded) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
              child: Text(
                  unknown
                      ? 'Calibration status unknown'
                      : confirmation ??
                          calibrationLabels[status] ??
                          (data == null
                              ? 'Loading calibration…'
                              : 'Calibration'),
                  style: _font(12, FontWeight.w600))),
          IconButton(
              tooltip: 'Refresh calibration',
              onPressed: _refreshing || _sending ? null : _refresh,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.refresh_rounded, size: 16)),
        ]),
        if (current != null)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(calibrationTarget(current), style: _font(11))),
        if (unknown)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                  restarted
                      ? 'Controller restarted. Select a new calibration before starting.'
                      : 'Reconnect to confirm the controller state.',
                  style: _font(11))),
        if (event != null && '${event['message'] ?? ''}'.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${event['message']}', style: _font())),
        if (latest?['type'] == 'calibration.rejected')
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(calibrationMessage(latest!),
                  style: _font().copyWith(color: colors.error))),
        if (widget.allowSend) _controls(commands, canSend),
        if (_error != null || _poller.lastError != null)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error ?? '${_poller.lastError}',
                  style: _font().copyWith(color: colors.error))),
      ]);
    }
    final saved = data?['saved_durations'] as List? ?? [];
    final events = _events.values.toList()
      ..sort((a, b) {
        final selection =
            '${b['selection_at']}'.compareTo('${a['selection_at']}');
        if (selection != 0) return selection;
        final uptime = (b['uptime_ms'] as num).compareTo(a['uptime_ms'] as num);
        if (uptime != 0) return uptime;
        final stages = calibrationLabels.keys.toList();
        final phase = stages
            .indexOf('${b['type']}'.split('.').last)
            .compareTo(stages.indexOf('${a['type']}'.split('.').last));
        return phase != 0
            ? phase
            : '${b['event_id']}'.compareTo('${a['event_id']}');
      });
    return CropVarietyModalFrame(
        mobile: mobile,
        isDark: Theme.of(context).brightness == Brightness.dark,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Row(children: [
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xff15803d)]),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.tune_rounded,
                        size: 20, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Controller calibration',
                          style: _font(16, FontWeight.bold)),
                      Text(widget.serial,
                          style: _font(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ])),
                IconButton(
                    tooltip: 'Close calibration',
                    onPressed: _sending ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 16)),
              ])),
          Flexible(
              child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _box(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(spacing: 8, runSpacing: 6, children: [
                                Text(
                                    online
                                        ? 'Controller online'
                                        : widget.deviceState.isOfflineConfirmed
                                            ? 'Controller offline'
                                            : 'Syncing with controller…',
                                    style: _font(11, FontWeight.w600)),
                                if (current != null)
                                  Text(calibrationTarget(current),
                                      style: _font(11)),
                              ]),
                              const SizedBox(height: 8),
                              Text(
                                  unknown
                                      ? 'Calibration status unknown'
                                      : confirmation ??
                                          calibrationLabels[status] ??
                                          (data == null
                                              ? 'Loading calibration…'
                                              : 'No calibration events yet'),
                                  style: _font(14, FontWeight.w600)),
                              if (unknown)
                                Text(
                                    restarted
                                        ? 'Controller restarted. The previous run needs a controller result; select a new calibration before starting.'
                                        : 'Last reported: ${calibrationLabels[status]}. Reconnect to confirm the controller state.',
                                    style: _font()),
                              if (event != null) ...[
                                if ('${event['message'] ?? ''}'.isNotEmpty)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text('${event['message']}',
                                          style: _font())),
                                if (event['reason'] != null)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                          calibrationReasons[event['reason']] ??
                                              '${event['reason']}',
                                          style: _font())),
                                if (event['elapsed_ms'] != null)
                                  Text(
                                      'Reported elapsed: ${calibrationDuration(event['elapsed_ms'])}',
                                      style: _font()),
                                if (event['grid_available'] != null)
                                  Text(
                                      'Grid power: ${event['grid_available'] == true ? 'Available' : 'Unavailable'}',
                                      style: _font()),
                                if (event['saved'] == true)
                                  Text(
                                      'Saved duration: ${calibrationDuration(event['saved_duration_ms'])}',
                                      style: _font(12, FontWeight.w600)),
                                if (['cancelled', 'not_saved'].contains(status))
                                  Text('Previous saved duration retained.',
                                      style: _font()),
                              ],
                              if (latest?['type'] ==
                                  'calibration.rejected') ...[
                                const SizedBox(height: 8),
                                Text('Latest command was rejected',
                                    style: _font(12, FontWeight.w600)
                                        .copyWith(color: colors.error)),
                                Text(calibrationMessage(latest!),
                                    style: _font()),
                              ],
                            ])),
                        if (widget.allowSend) ...[
                          _controls(commands, canSend),
                          const SizedBox(height: 14),
                        ],
                        Text('Saved measurements',
                            style: _font(13, FontWeight.w600)),
                        const SizedBox(height: 8),
                        if (saved.isEmpty)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Text(
                                  'No confirmed saved measurements yet.',
                                  style: _font())),
                        for (final item in saved)
                          _box(Row(children: [
                            const Icon(Icons.verified_outlined, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(calibrationTarget(item as Map),
                                    style: _font())),
                            Text(calibrationDuration(item['saved_duration_ms']),
                                style: _font(12, FontWeight.w600)),
                          ])),
                        Text('Event history',
                            style: _font(13, FontWeight.w600)),
                        const SizedBox(height: 8),
                        if (events.isEmpty)
                          Text(
                              'Controller events will appear here when received.',
                              style: _font()),
                        for (final item in events) _eventTile(item),
                        if (_cursor != null)
                          TextButton(
                              onPressed: _loadingHistory ? null : _loadHistory,
                              child: Text(
                                  _loadingHistory
                                      ? 'Loading history…'
                                      : 'Load older events',
                                  style: _font())),
                        if (_error != null || _poller.lastError != null)
                          Padding(
                              padding:
                                  const EdgeInsets.only(top: 12, bottom: 14),
                              child: Text(_error ?? '${_poller.lastError}',
                                  style:
                                      _font().copyWith(color: colors.error))),
                      ]))),
          Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed:
                            _sending ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: Text('Close', style: _font(13)))),
                const SizedBox(width: 12),
                Expanded(
                    child: FilledButton(
                        onPressed: _refreshing || _sending ? null : _refresh,
                        style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: Text(_refreshing ? 'Refreshing…' : 'Refresh',
                            style: _font(13)))),
              ])),
        ]));
  }

  Widget _controls(CalibrationCommands commands, bool enabled) {
    final choosing = [CalibrationStage.selection, CalibrationStage.selecting]
        .contains(_stage);
    final action = choosing
        ? 'select'
        : _stage == CalibrationStage.ready
            ? 'start'
            : 'stop';
    final configured = action == 'select'
        ? _selected != null
        : commands.action(action) != null;
    final waiting = _pendingAction == action ||
        (action == 'select' && _stage == CalibrationStage.selecting);
    final label = switch (action) {
      'start' => waiting ? 'Starting…' : 'Start',
      'stop' => waiting ? 'Stopping…' : 'Stop',
      _ => waiting ? 'Waiting for selection…' : 'Send command',
    };
    final primary = FilledButton.icon(
      onPressed: enabled &&
              configured &&
              _pendingAction == null &&
              (action != 'select' || _stage == CalibrationStage.selection)
          ? () => _send(action)
          : null,
      icon: _sending && waiting
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(
              waiting
                  ? Icons.hourglass_top_rounded
                  : switch (action) {
                      'start' => Icons.play_arrow_rounded,
                      'stop' => Icons.stop_rounded,
                      _ => Icons.send_rounded,
                    },
              size: 16),
      style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      label: Text(label, textAlign: TextAlign.center, style: _font(13)),
    );
    final showCancel = _stage != CalibrationStage.selection;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (choosing) ...[
        Text('Calibration', style: _font(11, FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
            key: ValueKey(_selected),
            initialValue: _selected,
            isExpanded: true,
            style: _font()
                .copyWith(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
                prefixIcon: const Icon(Icons.tune_rounded, size: 16),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5))),
            hint: Text('Select a calibration', style: _font()),
            items: commands.selections
                .map((c) => DropdownMenuItem(
                    value: c['id'],
                    child: Text(c['label']!,
                        maxLines: 1, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: _sending ||
                    _pendingAction != null ||
                    _stage != CalibrationStage.selection
                ? null
                : (value) => setState(() => _selected = value)),
        const SizedBox(height: 10),
        if (commands.selections.isEmpty)
          Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                  'No calibration selection commands are configured for this device.',
                  style: _font())),
      ],
      if (showCancel)
        Row(children: [
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: enabled &&
                          commands.action('cancel') != null &&
                          _pendingAction != 'cancel'
                      ? () => _send('cancel')
                      : null,
                  icon: _sending && _pendingAction == 'cancel'
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.close_rounded, size: 16),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  label: Text(
                      _pendingAction == 'cancel' ? 'Cancelling…' : 'Cancel',
                      textAlign: TextAlign.center,
                      style: _font(13)))),
          const SizedBox(width: 12),
          Expanded(child: primary),
        ])
      else
        primary,
      const SizedBox(height: 8),
      Text(
          _pendingAction == 'cancel'
              ? 'Waiting for the controller to confirm cancellation. Previous saved measurements are retained.'
              : _pendingAction == 'stop'
                  ? 'Waiting for the controller to stop and report whether the measurement was saved.'
                  : choosing
                      ? 'Selection must be confirmed by the controller before starting.'
                      : 'Start, Stop and Cancel use this device’s saved commands. The controller confirms every result.',
          style: _font(11)),
      if (!choosing && commands.action(action) == null)
        Text(
            'Configure ${action == 'start' ? 'CAL_START' : 'CAL_STOP'} on this device to enable this action.',
            style: _font(11)),
      if (showCancel && commands.action('cancel') == null)
        Text('Configure CAL_CANCEL on this device to enable cancellation.',
            style: _font(11)),
    ]);
  }

  Widget _eventTile(Map<String, dynamic> event) {
    final status = '${event['type']}'.split('.').last;
    final received = DateTime.tryParse('${event['received_at']}');
    return Material(
        color: Theme.of(context).colorScheme.surface,
        child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 12),
            title: Text(calibrationLabels[status] ?? status,
                style: _font(12, FontWeight.w600)),
            subtitle: Text(
                '${calibrationTarget(event)}${received == null ? '' : ' · Received ${DateFormat('dd MMM, h:mm a').format(received.toLocal())}'}',
                style: _font(11)),
            children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ('${event['message'] ?? ''}'.isNotEmpty)
                          Text('${event['message']}', style: _font()),
                        if (event['reason'] != null)
                          Text(
                              calibrationReasons[event['reason']] ??
                                  '${event['reason']}',
                              style: _font()),
                        if (event['grid_available'] != null)
                          Text(
                              'Grid power: ${event['grid_available'] == true ? 'Available' : 'Unavailable'}',
                              style: _font()),
                        if (event['elapsed_ms'] != null)
                          Text(
                              'Measured elapsed: ${calibrationDuration(event['elapsed_ms'])}',
                              style: _font()),
                        Text('Controller state: ${event['state']}',
                            style: _font()),
                        if (event['saved'] == true)
                          Text(
                              'Saved: ${calibrationDuration(event['saved_duration_ms'])}',
                              style: _font()),
                        Text(
                            'Controller uptime: ${calibrationDuration(event['uptime_ms'])}',
                            style: _font(11)),
                        SelectableText(
                            'Calibration: ${event['calibration_id']}\nCommand: ${event['command_id']}',
                            style: _font(11)),
                      ]))
            ]));
  }
}
