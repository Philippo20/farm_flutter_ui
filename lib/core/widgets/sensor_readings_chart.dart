import '../utils/sensor_thresholds.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

/// Each bar is an actual sample, ordered chronologically (not a time bucket).
class SensorReadingsChart extends StatelessWidget {
  const SensorReadingsChart(
      {super.key,
      required this.readings,
      this.sensor = const {},
      this.compact = false});
  final bool compact;
  final List<Map<String, dynamic>> readings;
  final Map<String, dynamic> sensor;
  Color _statusColor(String status) => switch (status) {
        'Good' => AppColors.success,
        'Bad' => AppColors.error,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final valid = readings.where((row) {
      final value = double.tryParse('${row['value']}');
      return value != null &&
          value.isFinite &&
          DateTime.tryParse('${row['timestamp']}') != null;
    }).toList()
      ..sort((a, b) => DateTime.parse('${b['timestamp']}')
          .compareTo(DateTime.parse('${a['timestamp']}')));
    final latest = valid.take(20).toList().reversed;
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final row in latest) {
      groups.putIfAbsent('${row['unit'] ?? ''}'.trim(), () => []).add(row);
    }
    if (groups.isEmpty)
      return const Text('No numeric readings with valid timestamps to chart.');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final group in groups.entries)
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _series(context, group.key, group.value)),
      if (valid.length != readings.length)
        Text(
            '${readings.length - valid.length} readings with missing or invalid values/timestamps are available in the records only.',
            style: GoogleFonts.inter(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }

  Widget _series(
      BuildContext context, String unit, List<Map<String, dynamic>> rows) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final values = rows.map((row) => double.parse('${row['value']}')).toList();
    final thresholds = SensorThresholds(sensor, unit);
    final bounds = [
      ...values,
      if (thresholds.valid) ...[
        if (thresholds.minimum != null) thresholds.minimum!,
        if (thresholds.maximum != null) thresholds.maximum!,
      ]
    ];
    final low = math.min(0.0, bounds.reduce(math.min));
    final high = math.max(0.0, bounds.reduce(math.max));
    final span = high == low ? 1.0 : high - low;
    final minY = low < 0 ? low - span * .15 : 0.0;
    final maxY = high > 0 ? high + span * .15 : (low == 0 ? 1.0 : 0.0);
    String stamp(int index, String pattern) => DateFormat(pattern)
        .format(DateTime.parse('${rows[index]['timestamp']}').toLocal());
    final number = NumberFormat.compact();
    return Container(
        padding: compact ? EdgeInsets.zero : const EdgeInsets.all(14),
        decoration: compact
            ? null
            : BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: .04)
                    : AppColors.neutral50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: dark ? Colors.white10 : AppColors.neutral200)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
              unit.isEmpty
                  ? 'Reading value · unit unspecified'
                  : 'Reading value ($unit)',
              style:
                  GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text('${rows.length} samples · oldest to newest',
              style: GoogleFonts.inter(fontSize: 11, color: secondary)),
          const SizedBox(height: 12),
          Wrap(spacing: 16, runSpacing: 6, children: [
            Text('Low ${number.format(values.reduce(math.min))}',
                style: GoogleFonts.inter(fontSize: 11, color: secondary)),
            Text('High ${number.format(values.reduce(math.max))}',
                style: GoogleFonts.inter(fontSize: 11, color: secondary)),
          ]),
          const SizedBox(height: 12),
          Text(
              thresholds.valid
                  ? '${thresholds.normalLabel} $unit'
                  : 'Thresholds unavailable for this unit or configuration',
              style: GoogleFonts.inter(fontSize: 11, color: secondary)),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 8, children: [
            for (final label in ['Good', 'Bad', 'Unrated'])
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle, size: 8, color: _statusColor(label)),
                const SizedBox(width: 5),
                Text(label,
                    style: GoogleFonts.inter(fontSize: 10, color: secondary))
              ])
          ]),
          const SizedBox(height: 6),
          Text('Colors use current sensor thresholds',
              style: GoogleFonts.inter(fontSize: 10, color: secondary)),
          const SizedBox(height: 18),
          LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: compact,
                  child: SizedBox(
                      width: math.max(
                          constraints.maxWidth, rows.length * 46.0 + 48),
                      height: compact ? 160 : 220,
                      child: Semantics(
                          label:
                              '${rows.length} sensor readings in $unit. Exact values are available in Show reading records.',
                          child: BarChart(BarChartData(
                            minY: minY,
                            maxY: maxY,
                            alignment: BarChartAlignment.spaceAround,
                            rangeAnnotations:
                                RangeAnnotations(horizontalRangeAnnotations: [
                              if (thresholds.hasNormal)
                                HorizontalRangeAnnotation(
                                    y1: thresholds.minimum ?? minY,
                                    y2: thresholds.maximum ?? maxY,
                                    color: AppColors.success
                                        .withValues(alpha: .08)),
                            ]),
                            extraLinesData: ExtraLinesData(horizontalLines: [
                              if (thresholds.valid) ...[
                                for (final bound in [
                                  thresholds.minimum,
                                  thresholds.maximum
                                ])
                                  if (bound != null)
                                    HorizontalLine(
                                        y: bound,
                                        color: AppColors.success
                                            .withValues(alpha: .6),
                                        strokeWidth: 1,
                                        dashArray: [5, 4]),
                              ],
                            ]),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                                drawVerticalLine: false,
                                horizontalInterval: (maxY - minY) / 4,
                                getDrawingHorizontalLine: (_) => FlLine(
                                    color: dark
                                        ? Colors.white10
                                        : AppColors.neutral200,
                                    strokeWidth: 1,
                                    dashArray: [4, 4])),
                            titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        interval: (maxY - minY) / 4,
                                        getTitlesWidget: (value, meta) => Text(
                                            number.format(value),
                                            style: GoogleFonts.inter(
                                                fontSize: 9,
                                                color: secondary)))),
                                bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 36,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index < 0 || index >= rows.length)
                                            return const SizedBox();
                                          return Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: Text(stamp(index, 'HH:mm'),
                                                  style: GoogleFonts.inter(
                                                      fontSize: 9,
                                                      color: secondary)));
                                        }))),
                            barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                    fitInsideHorizontally: true,
                                    fitInsideVertically: true,
                                    maxContentWidth: 180,
                                    getTooltipItem: (group, index, rod,
                                            rodIndex) =>
                                        BarTooltipItem(
                                            compact
                                                ? '${rows[index]['value']} $unit\n${stamp(index, 'HH:mm:ss')} · ${thresholds.classify(values[index])}'
                                                : '${rows[index]['value']} $unit\n${stamp(index, 'd MMM yyyy, HH:mm:ss')}\n${thresholds.classify(values[index])} · current thresholds\nRecorded: ${rows[index]['status'] ?? 'Unknown status'}',
                                            GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.white)))),
                            barGroups: [
                              for (var i = 0; i < rows.length; i++)
                                BarChartGroupData(
                                    x: i,
                                    showingTooltipIndicators:
                                        compact && i == rows.length - 1
                                            ? [0]
                                            : [],
                                    barRods: [
                                      BarChartRodData(
                                          toY: values[i],
                                          width: 18,
                                          color: _statusColor(
                                              thresholds.classify(values[i])),
                                          borderRadius:
                                              BorderRadius.circular(4))
                                    ])
                            ],
                          )))))),
          const SizedBox(height: 8),
          Text(
              '${stamp(0, 'd MMM, HH:mm')} — ${stamp(rows.length - 1, 'd MMM, HH:mm')}',
              style: GoogleFonts.inter(fontSize: 10, color: secondary)),
          const SizedBox(height: 4),
          Text('Tap or hover for details · scroll sideways for more',
              style: GoogleFonts.inter(fontSize: 10, color: secondary)),
        ]));
  }
}
