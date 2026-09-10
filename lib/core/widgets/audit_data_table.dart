import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

/// Decode JSON without guessing at malformed text. Paths preserve nested keys.
Map<String, dynamic> decodeAuditFields(String source) {
  if (source.trim().isEmpty) return {};
  dynamic data = source;
  for (var i = 0; i < 3 && data is String; i++) {
    if (i > 0 &&
        !data.trimLeft().startsWith('{') &&
        !data.trimLeft().startsWith('[')) break;
    try {
      data = jsonDecode(data);
    } catch (_) {
      break;
    }
  }
  final fields = <String, dynamic>{};
  void flatten(dynamic value, String path, int depth) {
    if (depth < 20 && value is Map && value.isNotEmpty) {
      for (final entry in value.entries) {
        flatten(entry.value,
            path + '[' + jsonEncode(entry.key.toString()) + ']', depth + 1);
      }
    } else if (depth < 20 && value is List && value.isNotEmpty) {
      for (var i = 0; i < value.length; i++) {
        flatten(value[i], path + '[' + i.toString() + ']', depth + 1);
      }
    } else {
      fields[path.isEmpty ? 'Data' : path] = value;
    }
  }

  flatten(data, '', 0);
  return fields;
}

class AuditDataTable extends StatelessWidget {
  const AuditDataTable(
      {super.key, required this.previous, required this.current});
  final String previous, current;
  @override
  Widget build(BuildContext context) {
    final before = decodeAuditFields(previous);
    final after = decodeAuditFields(current);
    final compare = before.isNotEmpty && after.isNotEmpty;
    final keys = {...before.keys, ...after.keys};
    final colors = Theme.of(context).colorScheme;
    String display(dynamic value) =>
        value is String ? (value.isEmpty ? '""' : value) : jsonEncode(value);
    Widget cell(String text, {bool heading = false}) => Padding(
        padding: const EdgeInsets.all(10),
        child: SelectableText(text,
            style: AppTypography.bodySmall.copyWith(
                color: colors.onSurface,
                fontWeight: heading
                    ? AppTypography.labelWeight
                    : AppTypography.bodyWeight)));
    if (keys.isEmpty)
      return Text('No event data recorded.', style: AppTypography.bodySmall);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(
          compare
              ? 'Changes'
              : before.isNotEmpty
                  ? 'Previous data'
                  : 'Event data',
          style: AppTypography.titleSmall),
      const SizedBox(height: 8),
      if (compare) ...[
        Text(
            'Highlighted rows changed. “Not present” means the field was not recorded in that snapshot.',
            style:
                AppTypography.caption.copyWith(color: colors.onSurfaceVariant)),
        const SizedBox(height: 10),
      ],
      Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          columnWidths: compare
              ? const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(1.2)
                }
              : const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1.5)},
          border: TableBorder.all(
              color: colors.outlineVariant,
              borderRadius: BorderRadius.circular(10)),
          children: [
            TableRow(
                decoration:
                    BoxDecoration(color: colors.surfaceContainerHighest),
                children: [
                  cell('Field', heading: true),
                  if (compare) cell('Previous', heading: true),
                  cell(compare ? 'New' : 'Value', heading: true),
                ]),
            for (final key in keys)
              TableRow(
                  decoration: BoxDecoration(
                      color: compare &&
                              (before.containsKey(key) !=
                                      after.containsKey(key) ||
                                  jsonEncode(before[key]) !=
                                      jsonEncode(after[key]))
                          ? colors.primary.withValues(alpha: .06)
                          : Colors.transparent),
                  children: [
                    cell(key == 'Data'
                        ? key
                        : key
                            .replaceAllMapped(
                                RegExp(r'\["((?:[^"\\]|\\.)*)"\]'),
                                (m) =>
                                    '.' +
                                    (jsonDecode('"' + m[1]! + '"') as String))
                            .replaceFirst(RegExp(r'^\.'), '')),
                    if (compare)
                      cell(before.containsKey(key)
                          ? display(before[key])
                          : 'Not present'),
                    cell((compare || after.isNotEmpty)
                        ? (after.containsKey(key)
                            ? display(after[key])
                            : 'Not present')
                        : display(before[key])),
                  ]),
          ]),
    ]);
  }
}
