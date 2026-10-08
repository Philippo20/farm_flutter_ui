import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

class LinkedBatchObservations extends StatefulWidget {
  const LinkedBatchObservations(
      {super.key,
      required this.number,
      required this.crop,
      required this.stage,
      required this.initial,
      required this.onChanged});
  final String number, crop, stage;
  final Map<String, dynamic> initial;
  final ValueChanged<Map<String, dynamic>> onChanged;
  @override
  State<LinkedBatchObservations> createState() =>
      _LinkedBatchObservationsState();
}

class _LinkedBatchObservationsState extends State<LinkedBatchObservations> {
  late final _health =
      TextEditingController(text: widget.initial['plant_health'] ?? '');
  late final _observation =
      TextEditingController(text: widget.initial['observations'] ?? '');
  late final _issue =
      TextEditingController(text: widget.initial['issue_description'] ?? '');
  late bool _hasIssue = widget.initial['has_issues'] == true;
  late String _severity = ['low', 'medium', 'high', 'critical']
          .contains(widget.initial['issue_severity'])
      ? widget.initial['issue_severity']
      : 'low';
  @override
  void dispose() {
    _health.dispose();
    _observation.dispose();
    _issue.dispose();
    super.dispose();
  }

  void _changed() => widget.onChanged({
        'plant_health': _health.text,
        'observations': _observation.text,
        'has_issues': _hasIssue,
        'issue_description': _hasIssue ? _issue.text : '',
        'issue_severity': _hasIssue ? _severity : 'none'
      });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    InputDecoration decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: .35),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)));
    return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant)),
        child: Material(
            color: Colors.transparent,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.number, style: AppTypography.titleSmall),
                  Text('${widget.crop} · ${widget.stage}',
                      style: AppTypography.bodySmall
                          .copyWith(color: colors.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _health,
                      maxLength: 200,
                      style: AppTypography.bodySmall,
                      decoration: decoration('Plant health'),
                      onChanged: (_) => _changed()),
                  const SizedBox(height: 10),
                  TextFormField(
                      controller: _observation,
                      maxLength: 2000,
                      maxLines: 2,
                      style: AppTypography.bodySmall,
                      decoration: decoration('Observations for this batch'),
                      onChanged: (_) => _changed()),
                  SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Issue affects this batch',
                          style: AppTypography.bodySmall),
                      value: _hasIssue,
                      onChanged: (value) {
                        setState(() => _hasIssue = value);
                        _changed();
                      }),
                  if (_hasIssue) ...[
                    DropdownButtonFormField<String>(
                        initialValue: _severity,
                        isExpanded: true,
                        style: AppTypography.bodySmall
                            .copyWith(color: colors.onSurface),
                        decoration: decoration('Severity'),
                        items: ['low', 'medium', 'high', 'critical']
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (s) {
                          _severity = s!;
                          _changed();
                        }),
                    const SizedBox(height: 10),
                    TextFormField(
                        controller: _issue,
                        maxLength: 2000,
                        maxLines: 2,
                        style: AppTypography.bodySmall,
                        decoration:
                            decoration('Describe the issue for this batch'),
                        validator: (v) =>
                            _hasIssue && (v?.trim().isEmpty ?? true)
                                ? 'Describe this batch’s issue.'
                                : null,
                        onChanged: (_) => _changed()),
                  ],
                ])));
  }
}
