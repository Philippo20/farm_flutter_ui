import 'dart:async';
import 'light_switch_setup_guide.dart';
import 'package:flutter/material.dart';
import '../../services/light_switch_service.dart';
import '../../services/device_presence.dart';
import '../../services/foreground_refresh.dart';
import '../theme/app_typography.dart';

/// A relay controller has a confirmed output state, not a numeric sensor reading.
class LightSwitchDeviceCard extends StatefulWidget {
  const LightSwitchDeviceCard(
      {super.key,
      required this.serial,
      required this.name,
      required this.farm,
      required this.zone,
      required this.isDark,
      required this.onSettings,
      this.onDelete,
      this.elapsedMilliseconds,
      this.service});
  final String serial, name, farm, zone;
  final bool isDark;
  final VoidCallback onSettings;
  final VoidCallback? onDelete;
  final LightSwitchService? service;
  final int Function()? elapsedMilliseconds;
  @override
  State<LightSwitchDeviceCard> createState() => _LightSwitchDeviceCardState();
}

class _LightSwitchDeviceCardState extends State<LightSwitchDeviceCard>
    with WidgetsBindingObserver {
  late final _service = widget.service ?? LightSwitchService();
  final _clock = Stopwatch()..start();
  late final ForegroundRefresh _refreshLoop;
  final _presence = DevicePresence(grace: const Duration(seconds: 15));
  Timer? _expiry;
  bool _active = true;
  int get _elapsed =>
      widget.elapsedMilliseconds?.call() ?? _clock.elapsedMilliseconds;
  Map<String, dynamic>? _state;
  int _revision = 0;
  bool _saving = false;
  String? _error, _commandError;
  bool? _requested;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshLoop = ForegroundRefresh(
        fetch: _fetch,
        cancelFetch: _service.cancelPolling,
        interval: const Duration(seconds: 2));
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshLoop.dispose();
    _expiry?.cancel();
    _clock.stop();
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  bool get _online => _active && _presence.online(_elapsed);

  bool get _pending => _saving || _state?['pending'] == true;
  Future<void> _refresh() => _refreshLoop.refresh();
  Future<void> _fetch(RefreshTicket ticket) async {
    if (_saving || !mounted || !ticket.isCurrent) return;
    final revision = _revision;
    try {
      final result = await _service.state(widget.serial);
      if (!mounted || !ticket.isCurrent || revision != _revision) return;
      setState(() {
        _state = result;
        _presence.accept(result, _elapsed);
        _error = null;
      });
      _scheduleExpiry();
    } catch (error) {
      if (mounted && ticket.isCurrent && revision == _revision)
        setState(() => _error = '$error'.replaceFirst('Exception: ', ''));
    }
  }

  void _scheduleExpiry() {
    _expiry?.cancel();
    final remaining = _presence.expiresIn(_elapsed);
    if (remaining != null)
      _expiry = Timer(Duration(milliseconds: remaining), () {
        if (mounted && _active) {
          setState(() {});
          _scheduleExpiry();
        }
      });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) return;
    final active = state == AppLifecycleState.resumed;
    if (active == _active) return;
    _active = active;
    _revision++;
    _presence.reset();
    _expiry?.cancel();
    _error = null;
    _commandError = null;
    if (mounted) setState(() {});
  }

  Future<void> _change(bool desired) async {
    if (!_online || _pending || _state?['reported_on'] is! bool) return;
    setState(() {
      _saving = true;
      _commandError = null;
      _requested = desired;
      _revision++;
    });
    final revision = _revision;
    try {
      final result =
          await _service.command(widget.serial, desired, _service.requestId());
      if (!mounted || !_active || revision != _revision) return;
      setState(() {
        _state = result;
        _presence.accept(result, _elapsed);
        _error = null;
      });
      _scheduleExpiry();
    } catch (error) {
      if (mounted && _active && revision == _revision)
        setState(
            () => _commandError = '$error'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted)
        setState(() {
          _saving = false;
          _requested = null;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = _state?['reported_on'] == true;
    final known = _state?['reported_on'] is bool;
    final desired = _requested ?? _state?['desired_on'] == true;
    final label = _error != null && !_online
        ? 'Unavailable'
        : _state == null
            ? 'Connecting'
            : !_online
                ? 'Offline'
                : _pending
                    ? (desired ? 'Turning on…' : 'Turning off…')
                    : on
                        ? 'On'
                        : 'Off';
    final accent = _online && on ? scheme.primary : scheme.onSurfaceVariant;
    final issue = _state?['command_status'];
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant)),
      child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.lightbulb_outline_rounded,
                        color: scheme.onPrimaryContainer, size: 24)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(widget.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSmall
                              .copyWith(color: scheme.onSurface)),
                      const SizedBox(height: 4),
                      Text('Light Switch · Relay control',
                          style: AppTypography.caption
                              .copyWith(color: scheme.onSurfaceVariant)),
                    ])),
              ]),
              const SizedBox(height: 16),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(label,
                              style: AppTypography.titleMedium
                                  .copyWith(color: accent)),
                          const SizedBox(height: 4),
                          Text(
                              _pending
                                  ? 'Waiting for device confirmation'
                                  : _online && known
                                      ? 'Device-confirmed output'
                                      : 'Controls available when connected',
                              style: AppTypography.caption
                                  .copyWith(color: scheme.onSurfaceVariant)),
                        ])),
                    const SizedBox(width: 8),
                    if (_pending)
                      const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))),
                    Semantics(
                        label: 'Switch ${widget.name}',
                        child: Switch(
                          value: on,
                          onChanged:
                              _online && known && !_pending ? _change : null,
                        )),
                  ])),
              const SizedBox(height: 14),
              SelectableText(widget.serial,
                  style: AppTypography.caption
                      .copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                    child: Text('${widget.farm} · ${widget.zone}',
                        style: AppTypography.bodySmall
                            .copyWith(color: scheme.onSurfaceVariant)))
              ]),
              if (_commandError != null ||
                  (_error != null && !_online) ||
                  issue == 'expired' ||
                  issue == 'failed')
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                        _commandError ??
                            _error ??
                            (issue == 'expired'
                                ? 'Last command expired without confirmation.'
                                : 'Device did not confirm the requested output.'),
                        style: AppTypography.caption
                            .copyWith(color: scheme.error))),
              Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        showLightSwitchSetupGuide(context, widget.serial),
                    icon: const Icon(Icons.menu_book_outlined, size: 16),
                    label: Text('Setup guide', style: AppTypography.caption),
                  )),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: Text(_online ? 'Connected' : 'Not connected',
                        style: AppTypography.caption
                            .copyWith(color: scheme.onSurfaceVariant))),
                if (_error != null)
                  IconButton(
                      onPressed: _refresh,
                      tooltip: 'Retry connection',
                      icon: const Icon(Icons.refresh_rounded)),
                IconButton(
                    onPressed: widget.onSettings,
                    tooltip: 'Edit light switch',
                    icon: const Icon(Icons.tune_rounded)),
                if (widget.onDelete != null)
                  IconButton(
                      onPressed: widget.onDelete,
                      tooltip: 'Delete light switch',
                      icon: Icon(Icons.delete_outline_rounded,
                          color: scheme.error)),
              ]),
            ],
          )),
    );
  }
}
