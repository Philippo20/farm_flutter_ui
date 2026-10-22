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
  late final _monitor = widget.monitor ?? ControllerEquipmentMonitor();
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
        final label = _monitor.label(id);
        final current = _monitor.fresh(id) && state?['reported_on'] is bool;
        final colors = Theme.of(context).colorScheme;
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
        final maintenance =
            '${state?['maintenance_status'] ?? 'Maintenance status pending'}';
        final due = state?['next_due'];
        final warning = ['Overdue', 'Due soon'].contains(maintenance);
        final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.compact) ...[
                Icon(equipmentIcon('${widget.device['sensortype']}'),
                    color: color, size: 28),
                const SizedBox(height: 8),
                Text('${widget.device['model_number'] ?? outputLabel}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall),
                const SizedBox(height: 4),
                Text('Serial: ${widget.device['serial_number']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall),
                const SizedBox(height: 8),
              ],
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
              if (!widget.compact && state != null)
                Text('Controller: ${state['controller_serial']}',
                    style: AppTypography.bodySmall),
              if (_monitor.error != null)
                Text('Refreshing status…', style: AppTypography.bodySmall),
              if (widget.compact) ...[
                const SizedBox(height: 8),
                Text(maintenance,
                    style: AppTypography.bodySmall.copyWith(
                        color:
                            warning ? colors.error : colors.onSurfaceVariant)),
                if (due != null)
                  Text('Due $due', style: AppTypography.bodySmall),
              ],
            ]);
        if (!widget.compact) return content;
        return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outlineVariant)),
            child: content);
      });
}
