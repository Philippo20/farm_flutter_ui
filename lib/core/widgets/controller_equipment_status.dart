import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/controller_equipment_monitor.dart';
import '../theme/app_typography.dart';

IconData equipmentIcon(String type) => switch (type) {
      'grow_light' => Icons.lightbulb_outline,
      'feeding_pump' || 'drainage_pump' => Icons.water_drop_outlined,
      _ => Icons.air,
    };

class ControllerEquipmentStatus extends StatefulWidget {
  const ControllerEquipmentStatus(
      {super.key, required this.device, this.monitor, this.compact = false});
  final Map<String, dynamic> device;
  final ControllerEquipmentMonitor? monitor;
  final bool compact;
  @override
  State<ControllerEquipmentStatus> createState() =>
      _ControllerEquipmentStatusState();
}

class _ControllerEquipmentStatusState extends State<ControllerEquipmentStatus> {
  late final _monitor =
      widget.monitor ?? ControllerEquipmentMonitor(statusOnly: widget.compact);
  @override
  void initState() {
    super.initState();
    if (widget.monitor == null) _monitor.setDevices([widget.device]);
  }

  @override
  void didUpdateWidget(covariant ControllerEquipmentStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.monitor == null) _monitor.setDevices([widget.device]);
  }

  @override
  void dispose() {
    if (widget.monitor == null) _monitor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: _monitor,
      builder: (context, _) {
        final id = '${widget.device[r'$id']}';
        final state = _monitor.states[id];
        final colors = Theme.of(context).colorScheme;
        if (widget.compact) {
          final label = switch (_monitor.label(id)) {
            'Controller offline' => 'OFFLINE',
            'Status unavailable' => 'RECONNECTING',
            'Syncing controller' => 'SYNCING',
            'Awaiting report' =>
              state == null ? 'CONNECTING' : 'AWAITING REPORT',
            final value => value,
          };
          final on = label == 'ON';
          final dark = Theme.of(context).brightness == Brightness.dark;
          final statusColor = switch (label) {
            'ON' => dark ? Colors.greenAccent : Colors.green,
            'OFFLINE' => Colors.redAccent,
            'OFF' => colors.onSurfaceVariant,
            _ => dark ? Colors.amberAccent : Colors.brown,
          };
          return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: dark ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: .08),
                        blurRadius: 6,
                        offset: const Offset(0, 3)),
                  ]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                    widget.device['sensortype'] == 'grow_light'
                        ? Icons.lightbulb
                        : equipmentIcon('${widget.device['sensortype']}'),
                    color: on ? statusColor : Colors.grey,
                    size: 30),
                const SizedBox(height: 8),
                Text(
                    '${widget.device['model_number'] ?? equipmentTypeLabel('${widget.device['sensortype']}')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.font(
                        fontSize: AppTypography.bodySize,
                        fontWeight: AppTypography.headingWeight,
                        color: colors.onSurface)),
                const SizedBox(height: 4),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.font(
                        fontSize: AppTypography.captionSize,
                        fontWeight: AppTypography.labelWeight,
                        color: statusColor)),
              ]));
        }
        final label = _monitor.label(id);
        final current = _monitor.fresh(id) && state?['reported_on'] is bool;
        final color = !current
            ? colors.onSurfaceVariant
            : state!['reported_on'] == true
                ? colors.primary
                : colors.onSurfaceVariant;
        final received =
            DateTime.tryParse('${state?['received_at']}')?.toLocal();
        final output = '${widget.device['controller_output']}';
        final outputLabel = controllerOutputs['${widget.device['sensortype']}']
                ?[output] ??
            output;
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Icon(current ? Icons.circle : Icons.info_outline,
                        size: 10, color: color),
                    Text(label,
                        style: AppTypography.bodySmall.copyWith(
                            color: color,
                            fontWeight: AppTypography.labelWeight)),
                  ]),
              const SizedBox(height: 5),
              Text(outputLabel, style: AppTypography.bodySmall),
              if (!current && state?['reported_on'] is bool)
                Text(
                    'Last reported: ${state!['reported_on'] == true ? 'ON' : 'OFF'}',
                    style: AppTypography.bodySmall),
              if (received != null)
                Text(
                    'Received ${DateFormat('d MMM, h:mm:ss a').format(received)}',
                    style: AppTypography.bodySmall),
              if (state != null)
                Text('Controller: ${state['controller_serial']}',
                    style: AppTypography.bodySmall),
              if (_monitor.error != null)
                Text('Refreshing status…', style: AppTypography.bodySmall),
            ]);
      });
}
