import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import 'sensor_gauge_card.dart';
import 'live_sensor_card.dart';

/// Full sensor overview panel.
/// Uses LayoutBuilder for responsiveness at every level.
class SensorOverviewPanel extends StatelessWidget {
  final Map<String, dynamic> sensorData;
  final VoidCallback? onViewAllTap;

  const SensorOverviewPanel({
    super.key,
    required this.sensorData,
    this.onViewAllTap,
  });

  // ─── helpers ──────────────────────────────────────────────────────────────

  double _v(String key, [double fallback = 0]) =>
      (sensorData[key]?['value'] ?? fallback).toDouble();

  List<double> _mockSpark(double base, double range) =>
      List.generate(24, (i) => base + range * (0.5 - (i % 7) / 14));

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final mobile = w < 580;
      final tablet = w >= 580 && w < 880;
      final pad = mobile ? 12.0 : 20.0;
      final gap = mobile ? 8.0 : 12.0;

      return Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.03)
              : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.04),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── header ──
            _header(isDark, mobile, pad),

            // ── primary gauges ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: _gauges(mobile, tablet, gap),
            ),

            SizedBox(height: gap + 4),

            // ── divider ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06),
              ),
            ),

            SizedBox(height: gap + 4),

            // ── secondary sensors ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: _secondary(isDark, mobile, tablet, gap),
            ),

            SizedBox(height: pad),
          ],
        ),
      );
    });
  }

  // ─── header ───────────────────────────────────────────────────────────────

  Widget _header(bool isDark, bool mobile, double pad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, mobile ? 10 : 14),
      child: mobile ? _mobileHeader(isDark) : _desktopHeader(isDark),
    );
  }

  Widget _mobileHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _iconBadge(),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Sensor Readings',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary)),
          ),
          _statusChip(isDark, true),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Text('Real-time monitoring data',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : AppColors.textSecondary)),
          const Spacer(),
          if (onViewAllTap != null)
            GestureDetector(
              onTap: onViewAllTap,
              child: Text('View all',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ),
        ]),
      ],
    );
  }

  Widget _desktopHeader(bool isDark) {
    return Row(children: [
      _iconBadge(),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sensor Readings',
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text('Real-time monitoring data',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : AppColors.textSecondary)),
          ],
        ),
      ),
      _statusChip(isDark, false),
      if (onViewAllTap != null) ...[
        const SizedBox(width: 12),
        TextButton(
          onPressed: onViewAllTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('View all',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 11),
          ]),
        ),
      ],
    ]);
  }

  Widget _iconBadge() {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.sensors_rounded, color: Colors.white, size: 18),
    );
  }

  Widget _statusChip(bool isDark, bool compact) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 10, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle)),
        SizedBox(width: compact ? 4 : 6),
        Text(compact ? 'Normal' : 'All Systems Normal',
            style: GoogleFonts.inter(
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            )),
      ]),
    );
  }

  // ─── gauges grid ──────────────────────────────────────────────────────────

  Widget _gauges(bool mobile, bool tablet, double gap) {
    final cols = mobile ? 2 : (tablet ? 2 : 4);
    final ratio = mobile ? 0.88 : (tablet ? 0.95 : 0.98);

    return GridView.count(
      crossAxisCount: cols,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: gap,
      mainAxisSpacing: gap,
      childAspectRatio: ratio,
      children: [
        SensorGaugeCard(
          label: 'Temperature',
          currentValue: _v('temperature', 25.5),
          unit: '°C',
          minValue: 10,
          maxValue: 45,
          optimalMin: 20,
          optimalMax: 30,
          accentColor: Colors.deepOrange,
          icon: Icons.thermostat_outlined,
          trendText: '+0.5',
          trendUp: true,
        ),
        SensorGaugeCard(
          label: 'Humidity',
          currentValue: _v('humidity', 65),
          unit: '%',
          minValue: 0,
          maxValue: 100,
          optimalMin: 50,
          optimalMax: 80,
          accentColor: Colors.blue,
          icon: Icons.water_drop_outlined,
          trendText: '-2',
          trendUp: false,
        ),
        SensorGaugeCard(
          label: 'pH Level',
          currentValue: _v('ph', 6.5),
          unit: 'pH',
          minValue: 0,
          maxValue: 14,
          optimalMin: 5.5,
          optimalMax: 7.5,
          accentColor: const Color(0xFF66BB6A),
          icon: Icons.science_outlined,
        ),
        SensorGaugeCard(
          label: 'EC Level',
          currentValue: _v('ec', 1.8),
          unit: 'mS/cm',
          minValue: 0,
          maxValue: 5,
          optimalMin: 1.2,
          optimalMax: 2.5,
          accentColor: const Color(0xFF7E57C2),
          icon: Icons.bolt_outlined,
          trendText: '+0.1',
          trendUp: true,
        ),
      ],
    );
  }

  // ─── secondary sensors ────────────────────────────────────────────────────

  Widget _secondary(bool isDark, bool mobile, bool tablet, double gap) {
    final cols = mobile ? 2 : (tablet ? 2 : 4);
    final ratio = mobile ? 0.95 : (tablet ? 1.1 : 1.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Additional Readings',
            style: GoogleFonts.inter(
              fontSize: mobile ? 12 : 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: isDark
                  ? Colors.white.withOpacity(0.45)
                  : AppColors.textSecondary,
            )),
        SizedBox(height: gap),
        GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: gap,
          mainAxisSpacing: gap,
          childAspectRatio: ratio,
          children: [
            LiveSensorCard(
              name: 'CO\u2082 Level',
              value: '${_v('co2', 850).toInt()}',
              unit: 'ppm',
              icon: Icons.cloud_outlined,
              color: Colors.teal,
              sparkData: _mockSpark(850, 80),
              status: 'Normal',
              trend: '+12',
              trendUp: true,
              lastUpdated:
                  DateTime.now().subtract(const Duration(seconds: 30)),
            ),
            LiveSensorCard(
              name: 'Light',
              value: '${(_v('light', 45000) / 1000).toStringAsFixed(1)}k',
              unit: 'lux',
              icon: Icons.wb_sunny_outlined,
              color: Colors.amber.shade700,
              sparkData: _mockSpark(45, 8),
              status: 'Optimal',
              lastUpdated:
                  DateTime.now().subtract(const Duration(minutes: 1)),
            ),
            LiveSensorCard(
              name: 'Water Temp',
              value: _v('waterTemp', 22.5).toStringAsFixed(1),
              unit: '°C',
              icon: Icons.waves_outlined,
              color: Colors.cyan,
              sparkData: _mockSpark(22.5, 3),
              status: 'Normal',
              trend: '-0.3',
              trendUp: false,
              lastUpdated:
                  DateTime.now().subtract(const Duration(seconds: 45)),
            ),
            LiveSensorCard(
              name: 'TDS',
              value: '${_v('tds', 620).toInt()}',
              unit: 'ppm',
              icon: Icons.opacity_outlined,
              color: Colors.indigo,
              sparkData: _mockSpark(620, 40),
              status: 'Normal',
              lastUpdated:
                  DateTime.now().subtract(const Duration(minutes: 2)),
            ),
          ],
        ),
      ],
    );
  }
}
