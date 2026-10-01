import 'dart:async';
import 'light_switch_setup_guide.dart';
import 'package:flutter/material.dart';
import '../../services/light_switch_service.dart';
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
      this.service});
  final String serial, name, farm, zone;
  final bool isDark;
  final VoidCallback onSettings;
  final VoidCallback? onDelete;
  final LightSwitchService? service;
  @override
  State<LightSwitchDeviceCard> createState() => _LightSwitchDeviceCardState();
}

class _LightSwitchDeviceCardState extends State<LightSwitchDeviceCard> {
  late final _service = widget.service ?? LightSwitchService();
  final _clock = Stopwatch()..start();
  Timer? _timer;
  Map<String, dynamic>? _state;
  int _received = 0, _revision = 0;
  bool _fetching = false, _saving = false;
  String? _error;
  bool? _requested;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
      _refresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clock.stop();
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  bool get _online {
    final server = DateTime.tryParse('${_state?['server_time']}');
    final seen = DateTime.tryParse('${_state?['seen_at']}');
    if (_state?['online'] != true ||
        server == null ||
        seen == null ||
        _error != null) return false;
    final age = server.difference(seen).inMilliseconds +
        _clock.elapsedMilliseconds -
        _received;
    return age >= 0 && age <= 15000;
  }

  bool get _pending => _saving || _state?['pending'] == true;
  Future<void> _refresh() async {
    if (_fetching || _saving) return;
    _fetching = true;
    final revision = _revision;
    final began = _clock.elapsedMilliseconds;
    try {
      final result = await _service.state(widget.serial);
      if (!mounted || revision != _revision) return;
      setState(() {
        _state = result;
        _received = began;
        _error = null;
      });
    } catch (error) {
      if (mounted && revision == _revision)
        setState(() => _error = '$error'.replaceFirst('Exception: ', ''));
    } finally {
      _fetching = false;
    }
  }

  Future<void> _change(bool desired) async {
    if (!_online || _pending || _state?['reported_on'] is! bool) return;
    setState(() {
      _saving = true;
      _requested = desired;
      _revision++;
    });
    final began = _clock.elapsedMilliseconds;
    try {
      final result =
          await _service.command(widget.serial, desired, _service.requestId());
      if (!mounted) return;
      setState(() {
        _state = result;
        _received = began;
        _error = null;
      });
    } catch (error) {
      if (mounted)
        setState(() => _error = '$error'.replaceFirst('Exception: ', ''));
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
    final label = _error != null
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
              if (_error != null || issue == 'expired' || issue == 'failed')
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
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
