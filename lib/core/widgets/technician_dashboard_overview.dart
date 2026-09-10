import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../utils/sensor_connection.dart';

class TechnicianDashboardOverview extends StatelessWidget {
  const TechnicianDashboardOverview(
      {super.key,
      required this.sensors,
      required this.tasks,
      required this.alerts});
  final List<Map<String, dynamic>> sensors, tasks, alerts;
  String value(Map<String, dynamic> row, String key, [String fallback = '']) =>
      row[key]?.toString().trim().isNotEmpty == true
          ? row[key].toString()
          : fallback;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? Colors.white : AppColors.textPrimary;
    final secondary = dark ? const Color(0xFFCBD5E1) : AppColors.textSecondary;
    final online =
        sensors.where((s) => SensorConnection(s).state == 'online').length;
    final offline =
        sensors.where((s) => SensorConnection(s).state == 'offline').length;
    final openAlerts = alerts
        .where((a) =>
            a['resolved'] != true &&
            value(a, 'status').toLowerCase() != 'resolved')
        .length;
    final pending = tasks
        .where((t) => !['completed', 'cancelled']
            .contains(value(t, 'status').toLowerCase()))
        .toList()
      ..sort((a, b) =>
          (DateTime.tryParse(value(a, 'due_date')) ?? DateTime(9999)).compareTo(
              DateTime.tryParse(value(b, 'due_date')) ?? DateTime(9999)));
    BoxDecoration shell() => BoxDecoration(
        color: dark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: dark ? Colors.white10 : AppColors.neutral200));
    Widget heading(String title, String action, String route) => Row(children: [
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w600))),
          TextButton(
              onPressed: () => Navigator.pushNamed(context, route),
              child: Text(action,
                  style: TextStyle(color: foreground, fontSize: 12)))
        ]);
    Widget metric(String label, int count, IconData icon, Color color) =>
        Container(
            padding: const EdgeInsets.all(14),
            decoration: shell(),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 10),
              Text('$count',
                  style: TextStyle(
                      color: foreground,
                      fontSize: 26,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, color: secondary)),
            ]));
    Widget sensorPanel() => Container(
        padding: const EdgeInsets.all(16),
        decoration: shell(),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          heading('Sensor connectivity', 'View sensors', '/sensor-management'),
          const SizedBox(height: 8),
          Text(
              sensors.isEmpty
                  ? 'No sensors available'
                  : '$online of ${sensors.length} sensors online',
              style: TextStyle(
                  color: foreground,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                  value: sensors.isEmpty ? 0 : online / sensors.length,
                  minHeight: 8,
                  backgroundColor: dark ? Colors.white10 : AppColors.neutral100,
                  color: AppColors.success)),
          const SizedBox(height: 14),
          Wrap(spacing: 14, runSpacing: 8, children: [
            for (final item in [
              ('Online', online, AppColors.success),
              ('Offline', offline, AppColors.error),
              ('Unknown', sensors.length - online - offline, Colors.grey)
            ])
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle, size: 8, color: item.$3),
                const SizedBox(width: 5),
                Text('${item.$2} ${item.$1}',
                    style: TextStyle(fontSize: 11, color: secondary))
              ])
          ]),
          const SizedBox(height: 14),
          Text('Offline after 10 seconds without a reading.',
              style: TextStyle(fontSize: 11, color: secondary)),
          const SizedBox(height: 16),
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color:
                      (openAlerts > 0 ? AppColors.warning : AppColors.success)
                          .withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(10)),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(
                    openAlerts > 0
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    size: 20,
                    color:
                        openAlerts > 0 ? AppColors.warning : AppColors.success),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        openAlerts > 0
                            ? '$openAlerts open alerts need review'
                            : 'No unresolved alerts in the loaded records',
                        style: TextStyle(color: foreground, fontSize: 12)))
              ])),
        ]));
    Widget taskPanel() => Container(
        padding: const EdgeInsets.all(16),
        decoration: shell(),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          heading('Upcoming work', 'View tasks', '/maintenance-schedule'),
          if (pending.isEmpty)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('No open maintenance tasks.',
                    style: TextStyle(fontSize: 12, color: secondary)))
          else
            for (final task in pending.take(4))
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: InkWell(
                      onTap: () =>
                          Navigator.pushNamed(context, '/maintenance-schedule'),
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: .08),
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.build_outlined,
                                    size: 16, color: AppColors.primary)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(value(task, 'title', 'Maintenance task'),
                                      style: TextStyle(
                                          color: foreground,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 5),
                                  Text(
                                      value(task, 'farm_name',
                                          'Farm not recorded'),
                                      style: TextStyle(
                                          fontSize: 11, color: secondary)),
                                  const SizedBox(height: 6),
                                  Wrap(spacing: 10, runSpacing: 4, children: [
                                    Text(
                                        value(task, 'status',
                                            'Status not recorded'),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.info)),
                                    Text(_due(value(task, 'due_date')),
                                        style: TextStyle(
                                            fontSize: 11, color: secondary))
                                  ])
                                ])),
                            const Icon(Icons.chevron_right, size: 18),
                          ]))),
        ]));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Technical overview',
          style: TextStyle(
              color: foreground, fontSize: 20, fontWeight: FontWeight.w600)),
      const SizedBox(height: 5),
      Text('Monitor equipment and keep maintenance on track.',
          style: TextStyle(fontSize: 12, color: secondary)),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, constraints) {
        final items = [
          metric('Sensors online', online, Icons.sensors, AppColors.success),
          metric('Open alerts', openAlerts, Icons.warning_amber_rounded,
              AppColors.warning),
          metric('Open tasks', pending.length, Icons.build_outlined,
              AppColors.info),
          metric(
              'Completed tasks',
              tasks
                  .where((t) => value(t, 'status').toLowerCase() == 'completed')
                  .length,
              Icons.task_alt,
              AppColors.primary)
        ];
        final cols = constraints.maxWidth >= 800 ? 4 : 2;
        return Column(children: [
          for (var row = 0; row < items.length ~/ cols; row++) ...[
            if (row > 0) const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var col = 0; col < cols; col++) ...[
                if (col > 0) const SizedBox(width: 10),
                Expanded(child: items[row * cols + col])
              ]
            ])
          ]
        ]);
      }),
      const SizedBox(height: 16),
      LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= 900
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: sensorPanel()),
                  const SizedBox(width: 16),
                  Expanded(child: taskPanel())
                ])
              : Column(children: [
                  sensorPanel(),
                  const SizedBox(height: 16),
                  taskPanel()
                ])),
      const SizedBox(height: 20),
      Text('Workspace',
          style: TextStyle(
              color: foreground, fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      LayoutBuilder(builder: (context, constraints) {
        final cols = constraints.maxWidth >= 800
            ? 4
            : constraints.maxWidth >= 400
                ? 2
                : 1;
        final links = [
          (
            'Sensors',
            'Readings and history',
            Icons.sensors,
            '/sensor-management'
          ),
          (
            'Maintenance',
            'Schedules and issues',
            Icons.event_available_outlined,
            '/maintenance-schedule'
          ),
          (
            'Repair history',
            'Completed work and notes',
            Icons.history,
            '/repair-history'
          ),
          (
            'Settings',
            'Your preferences',
            Icons.settings_outlined,
            '/technician-settings'
          )
        ];
        return Column(children: [
          for (var row = 0; row < (links.length / cols).ceil(); row++) ...[
            if (row > 0) const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var col = 0; col < cols; col++) ...[
                if (col > 0) const SizedBox(width: 10),
                Expanded(child: Builder(builder: (context) {
                  final item = links[row * cols + col];
                  return Material(
                      color: Colors.transparent,
                      child: InkWell(
                          onTap: () => Navigator.pushNamed(context, item.$4),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: shell(),
                              child: Row(children: [
                                Icon(item.$3,
                                    size: 20, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(item.$1,
                                          style: TextStyle(
                                              color: foreground,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text(item.$2,
                                          style: TextStyle(
                                              fontSize: 11, color: secondary))
                                    ])),
                                const Icon(Icons.chevron_right, size: 16)
                              ]))));
                }))
              ]
            ])
          ]
        ]);
      }),
    ]);
  }

  String _due(String raw) {
    final date = DateTime.tryParse(raw);
    return date == null
        ? 'No due date'
        : 'Due ${DateFormat('d MMM').format(date.toLocal())}';
  }
}
