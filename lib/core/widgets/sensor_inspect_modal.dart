import '../theme/app_typography.dart';
import 'dart:async';
import '../utils/sensor_connection.dart';
import '../utils/sensor_calibration_policy.dart';
import 'sensor_reading_history.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import 'app_dialog.dart';

/// Read-only inspection sheet. Returns true when calibration is requested.
class SensorInspectModal extends StatefulWidget {
  const SensorInspectModal(
      {super.key, required this.sensor, this.currentSensor});
  final Map<String, dynamic> sensor;
  final Map<String, dynamic> Function()? currentSensor;
  @override
  State<SensorInspectModal> createState() => _SensorInspectModalState();
}

class _SensorInspectModalState extends State<SensorInspectModal> {
  Timer? _timer;
  Map<String, dynamic> get sensor =>
      widget.currentSensor?.call() ?? widget.sensor;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.surfaceDark : Colors.white;
    final foreground = dark ? Colors.white : AppColors.textPrimary;
    final secondary = dark ? Colors.white60 : AppColors.textSecondary;
    final calibration = sensorRequiresCalibration(sensor);
    final connection = SensorConnection(sensor);
    final status = connection.state == 'online'
        ? '${sensor['status'] ?? 'normal'}'
        : connection.state;
    final accent = connection.state == 'online'
        ? sensor['color'] as Color? ?? AppColors.primary
        : AppColors.textSecondary;
    String value(String key) => '${sensor[key] ?? ''}'.trim().isEmpty
        ? 'Not available'
        : '${sensor[key]}';
    String date(String key) => sensor[key] is DateTime
        ? DateFormat('d MMM yyyy, HH:mm')
            .format((sensor[key] as DateTime).toLocal())
        : 'Not available';
    final guidance = switch (status) {
      'offline' =>
        'This sensor is offline. Check its power and connection before relying on the last recorded reading.',
      'unknown' =>
        'Connection cannot be confirmed without a valid recent sensor timestamp.',
      'alert' =>
        'Check the installation and compare this reading with field conditions before taking action.',
      'warning' =>
        'Review recent readings and check the sensor installation for possible drift.',
      _ =>
        'Continue routine monitoring and follow the sensor maintenance schedule.',
    };
    TextStyle text(double size, {bool strong = false, Color? color}) =>
        AppTypography.font(
            fontSize: AppTypography.resolveSize(size),
            fontWeight: strong ? AppTypography.headingWeight : AppTypography.bodyWeight,
            color: color ?? foreground);
    Widget field(String label, String content) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: text(11, strong: true, color: secondary)),
          const SizedBox(height: 6),
          SelectableText(content, style: text(12))
        ]);
    Widget section(String title, IconData icon, Widget child) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: .04)
                : AppColors.neutral50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: dark ? Colors.white10 : AppColors.neutral200)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(icon, size: 16, color: secondary),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: text(12, strong: true)))
          ]),
          const SizedBox(height: 14),
          child
        ]));
    final buttons = ButtonStyle(
        padding:
            const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
        textStyle: WidgetStatePropertyAll(text(13, strong: true)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    return AppDialog(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
            constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.sizeOf(context).height * .9),
            decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 24,
                      offset: Offset(0, 12))
                ]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [AppColors.primary, Color(0xff15803d)]),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.sensors,
                            size: 20, color: Colors.white)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Sensor details',
                              style: AppTypography.font(
                                  fontSize: AppTypography.cardTitleSize,
                                  fontWeight: AppTypography.headingWeight,
                                  color: foreground)),
                          const SizedBox(height: 4),
                          Text('Readings and device information',
                              style: text(12, color: secondary))
                        ])),
                    IconButton(
                        tooltip: 'Close',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 16))
                  ])),
              Flexible(
                  child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: accent.withValues(alpha: .07),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: accent.withValues(alpha: .18))),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(value('name'),
                                          style: text(14, strong: true)),
                                      const SizedBox(height: 8),
                                      Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 5),
                                          decoration: BoxDecoration(
                                              color:
                                                  accent.withValues(alpha: .12),
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          child: Text(status.toUpperCase(),
                                              style: text(11,
                                                  strong: true,
                                                  color: accent))),
                                      const SizedBox(height: 16),
                                      Text(
                                          (status == 'offline' ||
                                                  status == 'unknown')
                                              ? 'Last recorded reading'
                                              : 'Latest reading',
                                          style: text(11, color: secondary)),
                                      const SizedBox(height: 6),
                                      Wrap(
                                          spacing: 6,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(value('value'),
                                                style: text(28, strong: true)),
                                            Text('${sensor['unit'] ?? ''}',
                                                style:
                                                    text(12, color: secondary))
                                          ]),
                                      const SizedBox(height: 8),
                                      Text('Updated ${date('lastReading')}',
                                          style: text(11, color: secondary))
                                    ])),
                            const SizedBox(height: 14),
                            section(
                                'Device information',
                                Icons.info_outline,
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      field('Sensor ID', value('id')),
                                      const SizedBox(height: 14),
                                      LayoutBuilder(
                                          builder: (context, constraints) {
                                        final fields = [
                                          field('Type',
                                              value('type').toUpperCase()),
                                          field('Farm / location',
                                              value('location'))
                                        ];
                                        if (constraints.maxWidth < 360)
                                          return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                fields[0],
                                                const SizedBox(height: 14),
                                                fields[1]
                                              ]);
                                        return Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(child: fields[0]),
                                              const SizedBox(width: 10),
                                              Expanded(child: fields[1])
                                            ]);
                                      })
                                    ])),
                            const SizedBox(height: 14),
                            section(
                                'Connection',
                                Icons.wifi,
                                Text(
                                    '${connection.state.toUpperCase()} · ${connection.reason}',
                                    style: text(12, color: secondary))),
                            const SizedBox(height: 14),
                            section(
                                'Maintenance',
                                Icons.tune,
                                calibration == true
                                    ? field('Last calibrated',
                                        date('lastCalibrated'))
                                    : Text(
                                        calibration == false
                                            ? 'Routine calibration is not required for this sensor type.'
                                            : 'Check the device specifications to determine calibration requirements.',
                                        style: text(12, color: secondary))),
                            const SizedBox(height: 14),
                            SensorReadingHistory(
                                sensor: sensor,
                                serialNumber:
                                    '${sensor['serialNumber'] ?? ''}'),
                            const SizedBox(height: 14),
                            section(
                                'Recommended checks',
                                Icons.checklist_outlined,
                                Text(guidance,
                                    style: text(12, color: secondary))),
                          ]))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Row(children: [
                    Expanded(
                        child: OutlinedButton(
                            style: buttons,
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'))),
                    if (calibration == true) const SizedBox(width: 12),
                    if (calibration == true)
                      Expanded(
                          child: FilledButton(
                              style: buttons,
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Calibrate')))
                  ])),
            ])));
  }
}
