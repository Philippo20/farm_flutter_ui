import '../theme/app_typography.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import 'app_dialog.dart';
import 'sensor_reading_history.dart';

class DeviceTelemetryDetails {
  const DeviceTelemetryDetails(
      {required this.name,
      required this.serial,
      required this.reading,
      required this.readingStatus,
      required this.color,
      required this.location,
      required this.configuration,
      required this.sensor});
  final String name, serial, reading, readingStatus;
  final Color color;
  final Map<String, String> location, configuration;
  final Map<String, dynamic> sensor;
}

class DeviceTelemetryDetailsModal extends StatefulWidget {
  const DeviceTelemetryDetailsModal(
      {super.key, required this.currentDetails, this.loadReadings});
  final DeviceTelemetryDetails Function() currentDetails;
  final Future<List<Map<String, dynamic>>> Function(String)? loadReadings;
  @override
  State<DeviceTelemetryDetailsModal> createState() =>
      _DeviceTelemetryDetailsModalState();
}

class _DeviceTelemetryDetailsModalState
    extends State<DeviceTelemetryDetailsModal> {
  Timer? _timer;
  bool _copied = false;
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
    final data = widget.currentDetails();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.surfaceDark : Colors.white;
    final foreground = dark ? Colors.white : AppColors.textPrimary;
    final secondary = dark ? Colors.white70 : AppColors.textSecondary;
    TextStyle text(double size, {bool bold = false, Color? color}) =>
        AppTypography.font(
            fontSize: AppTypography.resolveSize(size),
            fontWeight: bold ? AppTypography.headingWeight : AppTypography.bodyWeight,
            color: color ?? foreground);
    Widget fields(Map<String, String> values) =>
        LayoutBuilder(builder: (context, constraints) {
          const fullWidthFields = {
            'Serial number',
            'Farm',
            'Last telemetry',
            'Model / firmware',
            'Maintenance',
          };
          final compactWidth = (constraints.maxWidth - 10) / 2;
          return Wrap(
              spacing: 10,
              runSpacing: 14,
              children: values.entries
                  .map((entry) => SizedBox(
                      width: fullWidthFields.contains(entry.key) ||
                              constraints.maxWidth < 200
                          ? constraints.maxWidth
                          : compactWidth,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key,
                                style: text(11, bold: true, color: secondary)),
                            const SizedBox(height: 6),
                            SelectableText(
                                entry.value.trim().isEmpty
                                    ? 'Not available'
                                    : entry.value,
                                style: text(12)),
                          ])))
                  .toList());
        });
    Widget section(String title, IconData icon, Widget content) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: .035)
                : AppColors.neutral50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: dark ? Colors.white10 : AppColors.neutral200)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(icon, size: 16, color: secondary),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: text(12, bold: true)))
          ]),
          const SizedBox(height: 14),
          content,
        ]));
    return AppDialog(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
            constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.sizeOf(context).height * .9),
            decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? .35 : .12),
                      blurRadius: 24,
                      offset: const Offset(0, 12))
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
                        child: const Icon(Icons.sensors_rounded,
                            size: 20, color: Colors.white)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Device details',
                              style: AppTypography.font(
                                  fontSize: AppTypography.cardTitleSize,
                                  fontWeight: AppTypography.headingWeight,
                                  color: foreground)),
                          const SizedBox(height: 3),
                          Text(data.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text(12, color: secondary)),
                        ])),
                    const SizedBox(width: 8),
                    IconButton(
                        tooltip: 'Close details',
                        onPressed: () => Navigator.pop(context),
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                        padding: const EdgeInsets.all(6),
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.close_rounded,
                            size: 16, color: secondary)),
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
                                    color: data.color.withValues(alpha: .08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color:
                                            data.color.withValues(alpha: .2))),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Latest reading',
                                          style: text(11,
                                              bold: true, color: secondary)),
                                      const SizedBox(height: 8),
                                      Text(data.reading,
                                          style: text(28, bold: true)),
                                      const SizedBox(height: 6),
                                      Text(data.readingStatus,
                                          style: text(12, color: data.color)),
                                    ])),
                            const SizedBox(height: 12),
                            section(
                                'Device & connection',
                                Icons.router_outlined,
                                Column(children: [
                                  fields({
                                    'Serial number': data.serial,
                                    ...data.location
                                  }),
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                          onPressed: () async {
                                            await Clipboard.setData(
                                                ClipboardData(
                                                    text: data.serial));
                                            if (mounted)
                                              setState(() => _copied = true);
                                          },
                                          icon: const Icon(Icons.copy_outlined,
                                              size: 14),
                                          label: Text(
                                              _copied
                                                  ? 'Serial copied'
                                                  : 'Copy serial',
                                              style: text(12,
                                                  color: AppColors.primary)))),
                                ])),
                            const SizedBox(height: 12),
                            section('Configuration', Icons.tune_rounded,
                                fields(data.configuration)),
                            const SizedBox(height: 12),
                            SensorReadingHistory(
                                serialNumber: data.serial,
                                sensor: data.sensor,
                                loadReadings: widget.loadReadings),
                            const SizedBox(height: 4),
                          ]))),
              Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          child: Text('Close', style: text(13, bold: true))))),
            ])));
  }
}
