import '../../../services/superadmin_api_service.dart';
import 'package:flutter/material.dart';
import 'first_row.dart';
import 'second_row.dart';
import 'third_row.dart';
import 'fourth_row.dart';

/// Shared responsive monitoring panels for caretaker and farm owner views.
class FarmIotDashboard extends StatelessWidget {
  static final _telemetryApi = SuperAdminApiService();
  const FarmIotDashboard({
    super.key,
    required this.isDark,
    this.liveTemperature,
    this.liveTemperatureHistory,
    this.userName = '',
    this.sensors = const [],
    this.readings = const [],
    this.sensorCounts = const {},
    this.activeSensorCounts = const {},
  });
  final bool isDark;
  final List<Map<String, dynamic>> readings;
  final List<Map<String, dynamic>> sensors;
  final String userName;
  final double? liveTemperature;
  final List<double>? liveTemperatureHistory;
  final Map<String, int> sensorCounts;
  final Map<String, int> activeSensorCounts;

  Map<String, List<String>> get _serials {
    final result = <String, List<String>>{};
    for (final sensor in sensors) {
      final raw = '${sensor['sensortype'] ?? sensor['sensor_type'] ?? sensor['type'] ?? ''}'.trim().toLowerCase();
      final type = const {'temp': 'temperature', 'humid': 'humidity'}[raw] ?? raw;
      final serial = '${sensor['serial_number'] ?? ''}'.trim();
      if (serial.isEmpty || !['temperature', 'humidity'].contains(type)) continue;
      final entries = result.putIfAbsent(type, () => []);
      if (!entries.contains(serial)) entries.add(serial);
    }
    for (final entries in result.values) { entries.sort(); }
    return result;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final panels = <Widget>[
          FirstRow(isDark: isDark, userName: userName),
          SecondRow(
              loadTelemetry: _telemetryApi.getLiveSensorTelemetry,
              sensors: sensors, readings: readings,
              sensorSerials: _serials,
              isDark: isDark,
              liveTemperature: liveTemperature,
              liveTemperatureHistory: liveTemperatureHistory,
              sensorCounts: sensorCounts,
              activeSensorCounts: activeSensorCounts),
          ThirdRow(
              isDark: isDark,
              sensorCounts: sensorCounts,
              activeSensorCounts: activeSensorCounts),
          FourthRow(isDark: isDark),
        ];
        if (box.maxWidth > 1100) {
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < panels.length; i++) ...[
              if (i > 0) const SizedBox(width: 14),
              Expanded(child: panels[i]),
            ],
          ]);
        }
        if (box.maxWidth > 700) {
          return Wrap(spacing: 16, runSpacing: 16, children: [
            for (final panel in panels)
              SizedBox(width: (box.maxWidth - 16) / 2, child: panel),
          ]);
        }
        return Column(children: [
          for (var i = 0; i < panels.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            panels[i],
          ]
        ]);
      });
}
