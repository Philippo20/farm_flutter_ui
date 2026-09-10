import 'sensor_reading_history.dart';
import '../utils/sensor_calibration_policy.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class SensorOverviewCard extends StatelessWidget {
  const SensorOverviewCard(
      {super.key,
      required this.sensor,
      required this.onInspect,
      required this.onCalibrate,
      this.loadReadings});
  final Map<String, dynamic> sensor;
  final Future<List<Map<String, dynamic>>> Function(String)? loadReadings;
  final VoidCallback onInspect, onCalibrate;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? Colors.white : AppColors.textPrimary;
    final secondary = dark ? Colors.white60 : AppColors.textSecondary;
    final color = sensor['color'] as Color;
    final isTemperature = ['temperature', 'temp']
        .contains('${sensor['type']}'.trim().toLowerCase());
    final calibration = sensorRequiresCalibration(sensor);
    final status = '${sensor['status']}';
    final statusLabel = status == 'unknown'
        ? 'Connection unknown'
        : status == 'normal'
            ? 'Normal'
            : (status == 'offline' || status == 'unknown')
                ? 'Offline'
                : status == 'alert'
                    ? 'Alert'
                    : 'Warning';
    String date(String key) => sensor[key] is DateTime
        ? DateFormat('d MMM, HH:mm').format((sensor[key] as DateTime).toLocal())
        : 'Not available';
    return Material(
        color: dark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: dark ? Colors.white10 : AppColors.neutral200)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onInspect,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: color.withValues(alpha: .1),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Icon(
                                    sensor['icon'] as IconData? ??
                                        Icons.sensors,
                                    size: 20,
                                    color: color)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('${sensor['name']}',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: foreground)),
                                  const SizedBox(height: 4),
                                  Text('${sensor['type']}'.toUpperCase(),
                                      style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: .6,
                                          color: secondary)),
                                ])),
                          ]),
                      const SizedBox(height: 12),
                      Wrap(spacing: 8, runSpacing: 6, children: [
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                                color: color.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(statusLabel,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: color))),
                        Text('${sensor['id']}',
                            style: TextStyle(fontSize: 11, color: secondary)),
                      ]),
                      if (sensor['connection_reason'] != null) ...[
                        const SizedBox(height: 6),
                        Text('${sensor['connection_reason']}',
                            style: TextStyle(fontSize: 11, color: secondary)),
                      ],
                      const SizedBox(height: 14),
                      Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: dark
                                  ? Colors.white.withValues(alpha: .04)
                                  : AppColors.neutral50,
                              borderRadius: BorderRadius.circular(12)),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isTemperature) ...[
                                  Text(
                                      status == 'offline'
                                          ? 'Last recorded reading'
                                          : 'Latest reading',
                                      style: TextStyle(
                                          fontSize: 11, color: secondary)),
                                  const SizedBox(height: 6),
                                  Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 6,
                                      children: [
                                        Text('${sensor['value']}',
                                            style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w600,
                                                color: foreground)),
                                        Text('${sensor['unit']}',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: secondary)),
                                      ]),
                                  const SizedBox(height: 5),
                                  Text('Updated ${date('lastReading')}',
                                      style: TextStyle(
                                          fontSize: 11, color: secondary)),
                                ],
                                if (isTemperature) ...[
                                  SensorReadingHistory(
                                    key: ValueKey(
                                        'temperature-history-${sensor['serialNumber'] ?? sensor['id']}'),
                                    serialNumber:
                                        '${sensor['serialNumber'] ?? ''}',
                                    sensor: sensor,
                                    compact: true,
                                    loadReadings: loadReadings,
                                  ),
                                ],
                              ])),
                      const SizedBox(height: 14),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 15, color: secondary),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text('${sensor['location']}',
                                    style: TextStyle(
                                        fontSize: 12, color: foreground)))
                          ]),
                      const SizedBox(height: 8),
                      Text(
                          calibration == false
                              ? 'Routine calibration not required'
                              : calibration == null
                                  ? 'Calibration: check device specifications'
                                  : 'Calibrated ${date('lastCalibrated')}',
                          style: TextStyle(fontSize: 11, color: secondary)),
                      const SizedBox(height: 14),
                      Row(children: [
                        if (calibration == true)
                          Expanded(
                              child: OutlinedButton(
                                  onPressed: onCalibrate,
                                  child: const Text('Calibrate',
                                      style: TextStyle(fontSize: 12)))),
                        if (calibration == true) const SizedBox(width: 10),
                        Expanded(
                            child: FilledButton.tonal(
                                onPressed: onInspect,
                                child: const Text('Inspect',
                                    style: TextStyle(fontSize: 12))))
                      ]),
                    ]))));
  }
}
