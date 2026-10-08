import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

class PlantTypeSelectionField extends StatelessWidget {
  const PlantTypeSelectionField(
      {super.key,
      required this.plants,
      required this.value,
      required this.onChanged,
      this.enabled = true});
  final List<Map<String, dynamic>> plants;
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final options = {
      for (final plant in plants)
        if (plant['is_category'] != true &&
            ('${plant['status'] ?? 'active'}'.toLowerCase() == 'active' ||
                '${plant[r'$id'] ?? plant['id']}' == value))
          '${plant[r'$id'] ?? plant['id']}':
              '${plant['name'] ?? plant['plant_name'] ?? ''}'
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Plant type',
          style: AppTypography.font(fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
          key: ValueKey(value),
          isExpanded: true,
          initialValue: options.containsKey(value) ? value : null,
          style: AppTypography.font(fontSize: 12, color: colors.onSurface),
          hint: const Text('Select the parent plant type'),
          decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: colors.surfaceContainerHighest.withValues(alpha: .35),
              prefixIcon: const Icon(Icons.account_tree_outlined, size: 16),
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
                  borderSide: BorderSide(color: colors.primary, width: 1.5)),
              helperText: options.isEmpty
                  ? 'Create an active plant type first.'
                  : 'One plant type can have multiple crop varieties.',
              helperMaxLines: 2),
          items: options.entries
              .map((entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value,
                      maxLines: 1, overflow: TextOverflow.ellipsis)))
              .toList(),
          validator: (id) => id == null || !options.containsKey(id)
              ? 'Select a plant type for this variety.'
              : null,
          onChanged: enabled
              ? (id) {
                  if (id != null) onChanged(id);
                }
              : null),
    ]);
  }
}
