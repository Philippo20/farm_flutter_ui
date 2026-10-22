import 'package:flutter/material.dart';
import '../../services/command_device_service.dart';
import '../theme/app_typography.dart';

class _CommandDraft {
  _CommandDraft(Map<String, String> data)
      : id = data['id'] ?? newCommandId(),
        label = TextEditingController(text: data['label']),
        value = TextEditingController(text: data['value']);
  final String id;
  final TextEditingController label, value;
  Map<String, String> get json =>
      {'id': id, 'label': label.text.trim(), 'value': value.text.trim()};
  void dispose() {
    label.dispose();
    value.dispose();
  }
}

class NamedCommandFields extends StatefulWidget {
  const NamedCommandFields(
      {super.key,
      required this.initial,
      required this.onChanged,
      this.enabled = true});
  final List<Map<String, String>> initial;
  final ValueChanged<List<Map<String, String>>> onChanged;
  final bool enabled;
  @override
  State<NamedCommandFields> createState() => _NamedCommandFieldsState();
}

class _NamedCommandFieldsState extends State<NamedCommandFields> {
  late final _rows =
      (widget.initial.isEmpty ? [<String, String>{}] : widget.initial)
          .map(_CommandDraft.new)
          .toList();
  final _retired = <_CommandDraft>[];
  @override
  void dispose() {
    for (final row in [..._rows, ..._retired]) {
      row.dispose();
    }
    super.dispose();
  }

  void _changed() => widget.onChanged(_rows.map((row) => row.json).toList());
  void _addRackCommands() {
    const presets = {
      'E_ON': 'Enable rack E feeding',
      'E_OFF': 'Disable rack E feeding',
      'F_ON': 'Enable rack F feeding',
      'F_OFF': 'Disable rack F feeding',
      'P_ON': 'Enable rack P feeding',
      'P_OFF': 'Disable rack P feeding',
      'ALL_ON': 'Enable all racks',
      'ALL_OFF': 'Disable all racks',
      'FERT_STATUS': 'Request controller status'
    };
    setState(() {
      final blank = _rows
          .where(
              (r) => r.label.text.trim().isEmpty && r.value.text.trim().isEmpty)
          .toList();
      for (final row in blank) {
        _rows.remove(row);
        _retired.add(row);
      }
      for (final entry in presets.entries) {
        if (_rows.length >= 24) break;
        if (_rows.any((r) =>
            r.value.text.trim().toUpperCase().replaceAll('-', '_') ==
                entry.key ||
            r.label.text.trim().toLowerCase() == entry.value.toLowerCase()))
          continue;
        _rows.add(_CommandDraft({'label': entry.value, 'value': entry.key}));
      }
    });
    _changed();
  }

  Widget _input(_CommandDraft row, bool name) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name ? 'Command name' : 'Value to send',
              style: AppTypography.font(
                  fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
              key: ValueKey('${row.id}:$name'),
              controller: name ? row.label : row.value,
              enabled: widget.enabled,
              maxLength: name ? 60 : 256,
              style: AppTypography.font(fontSize: 12, color: colors.onSurface),
              decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  counterText: '',
                  hintText: name ? 'Start pump' : 'PUMP_START',
                  prefixIcon: Icon(
                      name ? Icons.label_outline : Icons.code_rounded,
                      size: 16),
                  fillColor:
                      colors.surfaceContainerHighest.withValues(alpha: .4),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colors.outlineVariant)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colors.outlineVariant)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: colors.primary, width: 1.5))),
              onChanged: (_) => _changed(),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) {
                  return name
                      ? 'Enter a command name.'
                      : 'Enter the value the board expects.';
                }
                if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(text)) {
                  return 'Use printable text.';
                }
                if (name &&
                    _rows.any((other) =>
                        other != row &&
                        other.label.text.trim().toLowerCase() ==
                            text.toLowerCase())) {
                  return 'Use a unique command name.';
                }
                return null;
              }),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600 ||
        Theme.of(context).platform == TargetPlatform.android;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Named commands',
          style: AppTypography.font(fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text(
          'Give each command a clear name and the exact value your board firmware recognises. Up to 24 commands per device.',
          style: AppTypography.font(fontSize: 12)),
      TextButton.icon(
          onPressed:
              widget.enabled && _rows.length < 24 ? _addRackCommands : null,
          icon: const Icon(Icons.playlist_add, size: 16),
          label: Text('Add V1.7 rack commands',
              style: AppTypography.font(fontSize: 12))),
      Text(
          'Rack commands enable or disable scheduled feeding. They do not manually switch lights or pumps.',
          style: AppTypography.font(fontSize: 12)),
      const SizedBox(height: 14),
      for (final row in _rows) ...[
        Row(children: [
          Expanded(
              child: Text('Command ${_rows.indexOf(row) + 1}',
                  style: AppTypography.font(
                      fontSize: 11, fontWeight: FontWeight.w600))),
          IconButton(
              tooltip: 'Remove command',
              visualDensity: VisualDensity.compact,
              onPressed: !widget.enabled || _rows.length == 1
                  ? null
                  : () {
                      setState(() {
                        _rows.remove(row);
                        _retired.add(row);
                      });
                      _changed();
                    },
              icon: const Icon(Icons.remove_circle_outline, size: 16))
        ]),
        if (mobile) ...[_input(row, true), _input(row, false)] else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _input(row, true)),
            const SizedBox(width: 10),
            Expanded(child: _input(row, false))
          ]),
      ],
      Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
              onPressed: !widget.enabled || _rows.length >= 24
                  ? null
                  : () {
                      setState(() => _rows.add(_CommandDraft({})));
                      _changed();
                    },
              icon: const Icon(Icons.add, size: 16),
              label: Text('Add command',
                  style: AppTypography.font(fontSize: 12)))),
    ]);
  }
}
