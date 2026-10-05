import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_typography.dart';
import '../utils/production_plan.dart';

class ProductionScheduleCard extends StatelessWidget {
  const ProductionScheduleCard(
      {super.key, required this.plan, required this.start, this.previousBatch});
  final Object? plan;
  final DateTime start;
  final Map<String, dynamic>? previousBatch;
  @override
  Widget build(BuildContext context) {
    final stages = productionSchedule(plan, start);
    if (stages.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final interval =
        (productionPlan(plan)['interval_days'] as num? ?? 0).toInt();
    final previous = DateTime.tryParse('${previousBatch?['start_date'] ?? ''}');
    final previousInterval =
        (productionPlan(previousBatch?['production_plan'])['interval_days']
                    as num? ??
                0)
            .toInt();
    final expectedStart = previous != null && previousInterval > 0
        ? calendarAdd(previous, previousInterval)
        : null;
    final format = DateFormat('d MMM yyyy');
    final today = DateUtils.dateOnly(DateTime.now());
    final active = stages
        .where((s) =>
            !today.isBefore(s['start'] as DateTime) &&
            today.isBefore(s['end'] as DateTime))
        .firstOrNull;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Planned growth schedule', style: AppTypography.labelSmall),
        if (active != null) ...[
          const SizedBox(height: 6),
          Text('Expected stage now: ${active['name']}',
              style: AppTypography.bodySmall.copyWith(color: colors.primary)),
        ],
        const SizedBox(height: 8),
        for (final stage in stages)
          Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                  '${stage['name']} · ${format.format(stage['start'] as DateTime)} – ${format.format(stage['end'] as DateTime)}',
                  style: AppTypography.bodySmall)),
        Text(
            'Expected harvest: ${format.format(stages.last['end'] as DateTime)}',
            style: AppTypography.bodySmall),
        if (interval > 0) ...[
          const SizedBox(height: 10),
          Text(
              'Next batch target: ${format.format(calendarAdd(start, interval))}. Start separate batches every $interval days to maintain the harvest interval.',
              style: AppTypography.bodySmall.copyWith(color: colors.primary)),
        ],
        if (expectedStart != null) ...[
          const SizedBox(height: 8),
          Text(
              'Previous batch ${previousBatch?['batch_no'] ?? ''}: planned follow-up start ${format.format(expectedStart)}. ${DateUtils.isSameDay(expectedStart, start) ? 'This start follows the schedule.' : 'Your selected start changes the planned cadence.'}',
              style: AppTypography.bodySmall),
        ],
        const SizedBox(height: 6),
        Text(
            'Planned dates only; actual growth and harvest are recorded separately.',
            style:
                AppTypography.caption.copyWith(color: colors.onSurfaceVariant)),
      ]),
    );
  }
}
