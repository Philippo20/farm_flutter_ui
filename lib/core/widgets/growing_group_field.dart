import 'package:flutter/material.dart';
import '../theme/app_typography.dart';
import '../../services/superadmin_api_service.dart';

/// Optional link to a room/system shared by batches on the same farm.
class GrowingGroupField extends StatefulWidget {
  const GrowingGroupField(
      {super.key,
      required this.api,
      required this.farmId,
      required this.onChanged,
      this.initialId = '',
      this.initialName = '',
      this.enabled = true});
  final SuperAdminApiService api;
  final String farmId, initialId, initialName;
  final bool enabled;
  final void Function(String id, String name) onChanged;
  @override
  State<GrowingGroupField> createState() => _GrowingGroupFieldState();
}

class _GrowingGroupFieldState extends State<GrowingGroupField> {
  late String _id = widget.initialId;
  late final _name = TextEditingController(text: widget.initialName);
  final Map<String, String> _groups = {};
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final batches = await widget.api.getBatches();
      if (!mounted) return;
      setState(() {
        for (final batch in batches) {
          final id = '${batch['growing_group_id'] ?? ''}';
          if ('${batch['farmID']}' == widget.farmId && id.isNotEmpty) {
            _groups[id] = '${batch['growing_group_name'] ?? 'Growing group'}';
          }
        }
        if (_id.isNotEmpty && _id != 'new') _groups.putIfAbsent(_id, () => widget.initialName);
        _loading = false;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Unable to load growing groups.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    InputDecoration decoration(String label) => InputDecoration(
          labelText: label,
          labelStyle: AppTypography.bodySmall,
          filled: true,
          fillColor: colors.surfaceContainerHighest.withValues(alpha: .45),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Growing group (optional)', style: AppTypography.bodySmall),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        key: ValueKey('${widget.farmId}:$_id'),
        initialValue: _id,
        isExpanded: true,
        style: AppTypography.bodySmall.copyWith(color: colors.onSurface),
        decoration: decoration(
            _loading ? 'Loading groups…' : 'Room / shared water system'),
        items: [
          const DropdownMenuItem(value: '', child: Text('Individual batch')),
          const DropdownMenuItem(
              value: 'new', child: Text('Create growing group')),
          ..._groups.entries.map((g) => DropdownMenuItem(
              value: g.key,
              child:
                  Text(g.value, maxLines: 1, overflow: TextOverflow.ellipsis)))
        ],
        onChanged: !widget.enabled || _loading
            ? null
            : (id) {
                setState(() => _id = id!);
                widget.onChanged(_id,
                    _id == 'new' ? _name.text.trim() : (_groups[_id] ?? ''));
              },
      ),
      if (_id == 'new') ...[
        const SizedBox(height: 10),
        TextFormField(
            controller: _name,
            enabled: widget.enabled,
            maxLength: 100,
            style: AppTypography.bodySmall,
            decoration: decoration('Group name, e.g. Room 1 — System A'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter the growing group name.'
                : null,
            onChanged: (value) => widget.onChanged('new', value.trim())),
      ],
      Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 14),
          child: Text(
              'Linked batches share readings; crop observations and harvest totals stay separate.',
              style: AppTypography.caption
                  .copyWith(color: colors.onSurfaceVariant))),
      if (_error != null)
        TextButton.icon(
            onPressed: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _load();
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(_error!, style: AppTypography.bodySmall)),
    ]);
  }
}
