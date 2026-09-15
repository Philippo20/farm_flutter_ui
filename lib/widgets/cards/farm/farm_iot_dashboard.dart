import 'package:flutter/material.dart';
import 'first_row.dart';
import 'second_row.dart';
import 'third_row.dart';
import 'fourth_row.dart';

/// Shared responsive monitoring panels for caretaker and farm owner views.
class FarmIotDashboard extends StatelessWidget {
  const FarmIotDashboard({
    super.key,
    required this.isDark,
    this.liveTemperature,
    this.liveTemperatureHistory,
    this.userName = '',
    this.sensorCounts = const {},
    this.activeSensorCounts = const {},
  });
  final bool isDark;
  final String userName;
  final double? liveTemperature;
  final List<double>? liveTemperatureHistory;
  final Map<String, int> sensorCounts;
  final Map<String, int> activeSensorCounts;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final panels = <Widget>[
          FirstRow(isDark: isDark, userName: userName),
          SecondRow(
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
