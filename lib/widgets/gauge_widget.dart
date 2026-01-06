// Gauge widget

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';

/// Gauge Widget
/// Displays a circular gauge for sensor readings
class GaugeWidget extends StatelessWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final String unit;
  final String label;
  final Color? color;
  final double size;

  const GaugeWidget({
    super.key,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.unit,
    required this.label,
    this.color,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final gaugeColor = color ?? AppColors.primary;
    final percentage = ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(
          percentage: percentage,
          color: gaugeColor,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value.toStringAsFixed(1),
                style: AppTypography.sensorValueLarge.copyWith(
                  color: gaugeColor,
                  fontSize: size * 0.15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                unit,
                style: AppTypography.sensorUnit.copyWith(
                  fontSize: size * 0.08,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontSize: size * 0.06,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  _GaugePainter({
    required this.percentage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final strokeWidth = size.width * 0.08;

    // Background arc
    final backgroundPaint = Paint()
      ..color = AppColors.neutral200
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75, // Start angle (bottom left)
      math.pi * 1.5, // Sweep angle (270 degrees)
      false,
      backgroundPaint,
    );

    // Foreground arc (value)
    final foregroundPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.6),
          color,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5 * percentage,
      false,
      foregroundPaint,
    );

    // Draw min/max labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Min label (bottom left)
    textPainter.text = TextSpan(
      text: '${percentage * 100 ~/ 1}%',
      style: AppTypography.caption.copyWith(
        color: AppColors.textSecondary,
        fontSize: size.width * 0.06,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - radius - textPainter.width / 2,
        center.dy + radius * 0.7,
      ),
    );
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}

/// Simple Progress Gauge (Linear)
class LinearGaugeWidget extends StatelessWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final String label;
  final String unit;
  final Color? color;
  final double height;

  const LinearGaugeWidget({
    super.key,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.label,
    required this.unit,
    this.color,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    final gaugeColor = color ?? AppColors.primary;
    final percentage = ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);

    return Container(
      height: height,
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${value.toStringAsFixed(1)} $unit',
                style: AppTypography.labelSmall.copyWith(
                  color: gaugeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: AppColors.neutral200,
              valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
            ),
          ),
        ],
      ),
    );
  }
}
