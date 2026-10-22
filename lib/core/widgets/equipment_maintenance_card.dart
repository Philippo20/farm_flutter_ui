import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_typography.dart';
import 'controller_equipment_status.dart';
import '../../services/controller_equipment_monitor.dart';

/// Equipment without telemetry must not look like an offline measurement sensor.
class EquipmentMaintenanceCard extends StatelessWidget {
  const EquipmentMaintenanceCard(
      {super.key, required this.device, this.onConfigure, this.onDelete});
  final Map<String, dynamic> device;
  final VoidCallback? onConfigure, onDelete;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final raw = device['maintenance_plan'];
    final plans = raw is String && raw.isNotEmpty
        ? jsonDecode(raw) as List
        : raw is List
            ? raw
            : <dynamic>[];
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant)),
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(equipmentIcon('${device['sensortype']}'),
                  color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('${device['model_number'] ?? 'Air conditioner'}',
                      style: AppTypography.titleSmall)),
              if (onConfigure != null)
                IconButton(
                    onPressed: onConfigure,
                    tooltip: 'Device and maintenance settings',
                    icon: const Icon(Icons.tune, size: 20)),
              if (onDelete != null)
                IconButton(
                    onPressed: onDelete,
                    tooltip: 'Delete device',
                    icon: Icon(Icons.delete_outline,
                        size: 20, color: colors.error)),
            ]),
            const SizedBox(height: 12),
            Text(equipmentTypeLabel('${device['sensortype']}'),
                style: AppTypography.bodyMedium),
            const SizedBox(height: 6),
            Text('Serial: ${device['serial_number']}',
                style: AppTypography.bodySmall),
            const SizedBox(height: 6),
            Text('${device['farm_name']} · ${device['location']}',
                style: AppTypography.bodySmall),
            const Divider(height: 28),
            if (controllerOutputs.containsKey(device['sensortype'])) ...[
              ControllerEquipmentStatus(device: device),
              const Divider(height: 28),
            ],
            Text(
                plans.isEmpty
                    ? 'No scheduled maintenance'
                    : '${plans.length} maintenance schedules',
                style: AppTypography.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 6,
                children: plans
                    .map((plan) => Chip(
                        label: Text('${plan['type']}',
                            style: AppTypography.bodySmall)))
                    .toList()),
            const SizedBox(height: 8),
            Text('Condition: ${device['status']}',
                style: AppTypography.bodySmall),
          ])),
    );
  }
}
