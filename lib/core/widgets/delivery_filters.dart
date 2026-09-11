import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

class DeliveryFilters extends StatelessWidget {
  const DeliveryFilters(
      {super.key,
      required this.searchController,
      required this.farms,
      required this.farm,
      required this.status,
      required this.resultCount,
      required this.onSearchChanged,
      required this.onFarmChanged,
      required this.onStatusChanged,
      required this.onReset});
  final TextEditingController searchController;
  final List<String> farms;
  final String farm, status;
  final int resultCount;
  final ValueChanged<String> onSearchChanged, onFarmChanged, onStatusChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final active = farm != 'All Farms' ||
        status != 'All' ||
        searchController.text.isNotEmpty;
    InputDecoration decoration(String hint, IconData icon) => InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              fontSize: AppTypography.captionSize,
              color: colors.onSurfaceVariant),
          prefixIcon: Icon(icon, size: 18),
          filled: true,
          fillColor: colors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.outlineVariant)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.outlineVariant)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.primary, width: 1.5)),
        );
    Widget label(String title, Widget child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: AppTypography.fieldLabelSize,
                    fontWeight: AppTypography.labelWeight,
                    color: colors.onSurfaceVariant)),
            const SizedBox(height: 6),
            child
          ],
        );
    Widget dropdown(String title, String selected, List<String> options,
            IconData icon, ValueChanged<String> changed) =>
        label(
            title,
            DropdownButtonFormField<String>(
              value: options.contains(selected) ? selected : options.first,
              isExpanded: true,
              decoration: decoration(title, icon),
              style: TextStyle(
                  fontSize: AppTypography.captionSize, color: colors.onSurface),
              items: options
                  .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item == 'All' ? 'All statuses' : item,
                          maxLines: 1, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (value) {
                if (value != null) changed(value);
              },
            ));
    final search = label(
        'Search deliveries',
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          style: TextStyle(
              fontSize: AppTypography.captionSize, color: colors.onSurface),
          decoration: decoration(
                  'ID, crop, destination or driver', Icons.search_rounded)
              .copyWith(
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    }),
          ),
        ));
    final farmField = dropdown('Farm', farm, {'All Farms', ...farms}.toList(),
        Icons.agriculture_outlined, onFarmChanged);
    final statusField = dropdown(
        'Delivery status',
        status,
        const [
          'All',
          'Pending Approval',
          'Scheduled',
          'In Transit',
          'Delivered',
          'On Hold',
          'Cancelled'
        ],
        Icons.local_shipping_outlined,
        onStatusChanged);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Global Delivery Records',
                    style: TextStyle(
                        fontSize: AppTypography.cardTitleSize,
                        fontWeight: AppTypography.headingWeight,
                        color: colors.onSurface)),
                const SizedBox(height: 4),
                Text(
                    '$resultCount ${resultCount == 1 ? 'delivery' : 'deliveries'} found',
                    style: TextStyle(
                        fontSize: AppTypography.captionSize,
                        color: colors.onSurfaceVariant)),
              ])),
          if (active)
            TextButton(onPressed: onReset, child: const Text('Reset')),
        ]),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth >= 760) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 2, child: search),
              const SizedBox(width: 12),
              Expanded(child: farmField),
              const SizedBox(width: 12),
              Expanded(child: statusField),
            ]);
          }
          return Column(children: [
            search,
            const SizedBox(height: 12),
            if (constraints.maxWidth < 320 ||
                MediaQuery.textScalerOf(context).scale(12) > 18) ...[
              farmField,
              const SizedBox(height: 12),
              statusField
            ] else
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: farmField),
                const SizedBox(width: 12),
                Expanded(child: statusField),
              ]),
          ]);
        }),
      ]),
    );
  }
}
