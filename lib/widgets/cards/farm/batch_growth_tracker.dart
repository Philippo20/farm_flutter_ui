import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/registered_sensor_readings.dart';

class BatchGrowthTracker extends StatefulWidget {
  const BatchGrowthTracker(
      {super.key, required this.batches, required this.records});
  final List<Map<String, dynamic>> batches;
  final List<Map<String, dynamic>> records;
  @override
  State<BatchGrowthTracker> createState() => _BatchGrowthTrackerState();
}

class _BatchGrowthTrackerState extends State<BatchGrowthTracker> {
  String? _selected;
  String id(Map<String, dynamic> batch) =>
      sensorText(batch, [r'$id', 'batch_id', 'id', 'batch_no']);
  String number(Map<String, dynamic> batch) =>
      sensorText(batch, ['batch_no', 'batch_number', 'batch_id']);
  DateTime? date(Map<String, dynamic> row, List<String> keys) =>
      DateTime.tryParse(sensorText(row, keys));
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final unique = <String, Map<String, dynamic>>{
      for (final b in widget.batches)
        if (id(b).isNotEmpty) id(b): b
    };
    final batches = unique.values.toList()
      ..sort((a, b) => number(a).compareTo(number(b)));
    final selected = unique.containsKey(_selected)
        ? _selected
        : batches.isEmpty
            ? null
            : id(batches.first);
    final batch = unique[selected];
    final records = batch == null
        ? <Map<String, dynamic>>[]
        : widget.records
            .where((record) {
              final recordId = sensorText(record, ['batch_id']);
              if (recordId.isNotEmpty)
                return [
                  id(batch),
                  sensorText(batch, ['batch_id'])
                ].contains(recordId);
              return number(batch).isNotEmpty &&
                  sensorText(record, ['batch_number']) == number(batch) &&
                  sensorText(record, ['farm_id', 'farmID']) ==
                      sensorText(batch, ['farmID', 'farm_id']);
            })
            .where((row) => sensorText(row, ['growth_stage']).isNotEmpty)
            .toList()
      ..sort((a, b) => (date(b, ['record_date', 'created_at', r'$createdAt']) ??
              DateTime(1970))
          .compareTo(date(a, ['record_date', 'created_at', r'$createdAt']) ??
              DateTime(1970)));
    final status =
        batch == null ? '' : sensorText(batch, ['production_status']);
    final finished =
        ['harvested', 'delivered', 'completed'].contains(status.toLowerCase());
    final stage = batch == null
        ? ''
        : finished
            ? status
            : records.isNotEmpty
                ? sensorText(records.first, ['growth_stage'])
                : sensorText(batch, ['growth_stage', 'production_status']);
    final start = batch == null ? null : date(batch, ['start_date']);
    final end = batch == null ? null : date(batch, ['end_date']);
    final now = DateTime.now();
    final elapsed = start == null ? null : now.difference(start).inDays;
    final progress = start != null && end != null && end.isAfter(start)
        ? (now.difference(start).inSeconds / end.difference(start).inSeconds)
            .clamp(0.0, 1.0)
            .toDouble()
        : null;
    final isDark = theme.brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Batch number',
          style: AppTypography.labelSmall
              .copyWith(color: colors.onSurfaceVariant)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        key: ValueKey(selected),
        initialValue: selected,
        isExpanded: true,
        style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface),
        dropdownColor: colors.surface,
        icon: Icon(Icons.expand_more_rounded, color: colors.onSurfaceVariant),
        decoration: InputDecoration(
          hintText: 'No batches assigned',
          filled: true,
          fillColor: colors.surfaceContainerLow,
          prefixIcon: const Icon(Icons.inventory_2_outlined, size: 18),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.outlineVariant)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.outlineVariant)),
        ),
        items: batches
            .map((b) => DropdownMenuItem(
                value: id(b),
                child: Text(number(b),
                    maxLines: 1, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: batches.isEmpty
            ? null
            : (value) => setState(() => _selected = value),
      ),
      const SizedBox(height: 16),
      if (batch == null)
        Text('Assigned farm batches will appear here.',
            style: theme.textTheme.bodySmall)
      else ...[
        _buildStageCard(
            icon: Icons.eco,
            stage: stage.isEmpty ? 'Stage not recorded' : stage,
            day: elapsed == null
                ? null
                : elapsed < 0
                    ? 0
                    : elapsed + 1,
            isDark: isDark),
        const SizedBox(height: 16),
        _buildTrackerProgressbarCard(
            isDark: isDark, progress: progress, icon: Icons.eco),
      ],
    ]);
  }

  Widget _buildStageCard({
    required IconData icon,
    required String stage,
    required int? day,
    required bool isDark,
  }) {
    return Align(
      alignment: Alignment.centerLeft, // Push card to the left
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          //border: Border.all(color: Colors.grey[600]!, width: 1)  ,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon with circular background
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.green[900] : Colors.green[100],
              ),
              child: Icon(
                icon,
                size: 30,
                color: isDark ? Colors.green[300] : Colors.green[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stage,
              style: AppTypography.font(
                fontSize: AppTypography.sectionTitleSize,
                fontWeight: AppTypography.headingWeight,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              day == null
                  ? 'Planting date not recorded'
                  : day == 0
                      ? 'Not planted yet'
                      : 'Day: $day',
              style: AppTypography.font(
                fontSize: AppTypography.bodySize,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerProgressbarCard({
    required bool isDark,
    required double? progress, // 0.0 to 1.0
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            "Product Grow Stage",
            style: AppTypography.font(
              fontSize: AppTypography.headingSize,
              fontWeight: AppTypography.labelWeight,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          Text(
              progress == null
                  ? 'Schedule dates not set'
                  : 'Based on planned growing period',
              style: AppTypography.bodySmall
                  .copyWith(color: isDark ? Colors.white60 : Colors.black54)),
          const SizedBox(height: 8),
          // Icon + progress bar + percentage
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.green[900] : Colors.green[100],
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDark ? Colors.green[300] : Colors.green[800],
                ),
              ),
              const SizedBox(width: 12),

              // Wider Progress bar using flex
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress ?? 0,
                    minHeight: 40, // Slightly taller too if you want
                    backgroundColor:
                        isDark ? Colors.grey[700] : Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.greenAccent : Colors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Percentage
              Text(
                progress == null
                    ? '—'
                    : '${(progress * 100).toStringAsFixed(0)}%',
                style: AppTypography.font(
                  fontSize: AppTypography.actionSize,
                  fontWeight: AppTypography.labelWeight,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
