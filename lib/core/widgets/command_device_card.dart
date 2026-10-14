import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/command_device_service.dart';
import '../theme/app_typography.dart';
import 'command_device_setup_guide.dart';

class CommandDeviceCard extends StatefulWidget {
  const CommandDeviceCard(
      {super.key,
      required this.device,
      this.onSettings,
      this.onDelete,
      this.allowSend = true,
      this.service});
  final Map<String, dynamic> device;
  final VoidCallback? onSettings, onDelete;
  final bool allowSend;
  final CommandDeviceService? service;
  @override
  State<CommandDeviceCard> createState() => _CommandDeviceCardState();
}

class _CommandDeviceCardState extends State<CommandDeviceCard>
    with WidgetsBindingObserver {
  late final _service = widget.service ?? CommandDeviceService();
  final _clock = Stopwatch()..start();
  Timer? _timer;
  Map<String, dynamic>? _state;
  String? _selected, _error, _commandError;
  bool _saving = false, _foreground = true, _checking = false;
  int _revision = 0, _received = 0;
  int? _fetchRevision;
  String get _serial => '${widget.device['serial_number'] ?? ''}';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  void _start() {
    _refresh();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
      _refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _revision++;
    if (_foreground) {
      setState(() => _checking = true);
      _start();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void didUpdateWidget(covariant CommandDeviceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device['serial_number'] != _serial ||
        oldWidget.device['command_config'] != widget.device['command_config']) {
      _state = null;
      _selected = null;
      _error = null;
      _checking = true;
      _revision++;
      _refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _clock.stop();
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  bool get _online {
    final server = DateTime.tryParse('${_state?['server_time']}');
    final seen = DateTime.tryParse('${_state?['seen_at']}');
    if (_state?['online'] != true || server == null || seen == null) {
      return false;
    }
    final age = server.difference(seen).inMilliseconds +
        _clock.elapsedMilliseconds -
        _received;
    return age >= 0 && age <= 15000;
  }

  Future<void> _refresh() async {
    if (!mounted || !_foreground || _saving || _fetchRevision == _revision) {
      return;
    }
    final revision = _revision, began = _clock.elapsedMilliseconds;
    _fetchRevision = revision;
    try {
      final result = await _service.state(_serial);
      if (mounted && revision == _revision) {
        setState(() {
          _state = result;
          _received = began;
          _error = null;
          _checking = false;
        });
      }
    } catch (error) {
      if (mounted && revision == _revision) {
        setState(() {
          _error = '$error';
          _checking = false;
        });
      }
    } finally {
      if (_fetchRevision == revision) _fetchRevision = null;
    }
  }

  Future<void> _send() async {
    if (!_online ||
        !_foreground ||
        _saving ||
        _state?['ready'] != true ||
        !widget.allowSend ||
        _selected == null) {
      return;
    }
    final revision = ++_revision, began = _clock.elapsedMilliseconds;
    setState(() {
      _saving = true;
      _commandError = null;
    });
    try {
      final result = await _service.send(_serial, _selected!, newCommandId(),
          revision: _state?['config_revision']?.toString());
      if (mounted && revision == _revision) {
        setState(() {
          _state = result;
          _received = began;
        });
      }
    } catch (error) {
      if (mounted && revision == _revision) {
        setState(() => _commandError = '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        _refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final definitions = deviceNamedCommands(
        _state?['commands'] ?? widget.device['command_config']);
    final selected =
        definitions.where((command) => command['id'] == _selected).firstOrNull;
    final last = _state?['last_command'] is Map
        ? Map<String, dynamic>.from(_state!['last_command'])
        : null;
    final status = last?['status'];
    final statusLabel = switch (status) {
      'pending' => 'Awaiting confirmation',
      'confirmed' => 'Confirmed',
      'failed' => 'Failed',
      'expired' => 'Expired',
      _ => 'No commands sent'
    };
    final statusColor = switch (status) {
      'confirmed' => const Color(0xff16803d),
      'failed' => colors.error,
      'expired' => const Color(0xffb56b00),
      _ => colors.onSurfaceVariant
    };
    final canSend = widget.allowSend &&
        !_checking &&
        _online &&
        !_saving &&
        _state?['ready'] == true &&
        selected != null &&
        _error == null;
    final connection = _checking
        ? 'Checking'
        : _error != null
            ? 'Unavailable'
            : _state == null
                ? 'Connecting'
                : _online
                    ? 'Online'
                    : 'Offline';
    final lastTime =
        DateTime.tryParse('${last?['confirmed_at'] ?? last?['created_at']}');
    return Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.outlineVariant)),
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.terminal_rounded,
                            size: 24, color: colors.onPrimaryContainer)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                              '${widget.device['model_number'] ?? 'Command device'}',
                              style: AppTypography.titleSmall
                                  .copyWith(color: colors.onSurface)),
                          const SizedBox(height: 4),
                          Text('Command Device',
                              style: AppTypography.caption
                                  .copyWith(color: colors.onSurfaceVariant))
                        ])),
                    if (widget.onSettings != null)
                      IconButton(
                          tooltip: 'Configure device',
                          onPressed: _saving ? null : widget.onSettings,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.tune_rounded, size: 18)),
                  ]),
                  const SizedBox(height: 16),
                  Wrap(spacing: 14, runSpacing: 8, children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.circle,
                          size: 8,
                          color: _online
                              ? const Color(0xff16803d)
                              : colors.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(connection, style: AppTypography.caption)
                    ]),
                    Text('${definitions.length} configured commands',
                        style: AppTypography.caption
                            .copyWith(color: colors.onSurfaceVariant)),
                  ]),
                  const SizedBox(height: 12),
                  Text(
                      '${widget.device['farm_name'] ?? 'Unassigned farm'} · ${widget.device['location'] ?? 'Unassigned zone'}',
                      style: AppTypography.bodySmall),
                  const SizedBox(height: 4),
                  SelectableText(_serial,
                      style: AppTypography.caption
                          .copyWith(color: colors.onSurfaceVariant)),
                  const SizedBox(height: 18),
                  Text('Choose command', style: AppTypography.caption),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                      key: ValueKey(selected?['id']),
                      initialValue: selected?['id'],
                      isExpanded: true,
                      style: AppTypography.bodySmall
                          .copyWith(color: colors.onSurface),
                      decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: colors.surfaceContainerLow,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: colors.outlineVariant))),
                      hint: Text('Select a command',
                          style: AppTypography.bodySmall),
                      items: definitions
                          .map((command) => DropdownMenuItem(
                              value: command['id'],
                              child: Text(command['label']!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: _saving || _state?['pending'] == true
                          ? null
                          : (value) => setState(() => _selected = value)),
                  if (selected != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(selected['value']!,
                            style: AppTypography.caption
                                .copyWith(color: colors.onSurfaceVariant))),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                      onPressed: canSend ? _send : null,
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_rounded, size: 16),
                      label: Text(_saving ? 'Sending…' : 'Send command',
                          style: AppTypography.button)),
                  const SizedBox(height: 14),
                  Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(statusLabel,
                                style: AppTypography.caption
                                    .copyWith(color: statusColor)),
                            if (last != null) ...[
                              const SizedBox(height: 4),
                              Text('${last['label']}',
                                  style: AppTypography.bodySmall),
                              if (lastTime != null)
                                Text(
                                    DateFormat('dd MMM, h:mm a')
                                        .format(lastTime.toLocal()),
                                    style: AppTypography.caption)
                            ],
                            if ('${last?['result'] ?? ''}'.isNotEmpty)
                              Text('${last!['result']}',
                                  style: AppTypography.bodySmall),
                          ])),
                  if (!_online ||
                      _state?['enabled'] == false ||
                      !widget.allowSend ||
                      _state?['can_send'] == false)
                    Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                            !widget.allowSend || _state?['can_send'] == false
                                ? 'View-only access'
                                : _state?['enabled'] == false
                                    ? 'Activate this device to send commands.'
                                    : 'Connect the board to enable commands.',
                            style: AppTypography.caption)),
                  if (_error != null || _commandError != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(_commandError ?? _error!,
                            style: AppTypography.caption
                                .copyWith(color: colors.error))),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                                onPressed: () => showCommandDeviceSetupGuide(
                                    context, _serial),
                                icon: const Icon(Icons.menu_book_outlined,
                                    size: 16),
                                label: Text('Setup guide',
                                    style: AppTypography.caption)))),
                    IconButton(
                        tooltip: 'Refresh commands',
                        onPressed: _saving ? null : _refresh,
                        icon: const Icon(Icons.refresh, size: 18)),
                    if (widget.onDelete != null)
                      IconButton(
                          tooltip: 'Delete device',
                          onPressed: _saving ? null : widget.onDelete,
                          icon: Icon(Icons.delete_outline,
                              size: 18, color: colors.error)),
                  ]),
                ])));
  }
}
