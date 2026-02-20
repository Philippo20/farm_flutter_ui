import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// A clean, professional radial gauge card for sensor readings.
/// Uses LayoutBuilder for full responsiveness at any size.
class SensorGaugeCard extends StatefulWidget {
  final String label;
  final double currentValue;
  final String unit;
  final double minValue;
  final double maxValue;
  final double optimalMin;
  final double optimalMax;
  final Color accentColor;
  final IconData icon;
  final String? trendText;
  final bool trendUp;
  final VoidCallback? onTap;

  const SensorGaugeCard({
    super.key,
    required this.label,
    required this.currentValue,
    required this.unit,
    this.minValue = 0,
    this.maxValue = 100,
    required this.optimalMin,
    required this.optimalMax,
    required this.accentColor,
    required this.icon,
    this.trendText,
    this.trendUp = true,
    this.onTap,
  });

  @override
  State<SensorGaugeCard> createState() => _SensorGaugeCardState();
}

class _SensorGaugeCardState extends State<SensorGaugeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _progress;

  double get _percent =>
      ((widget.currentValue - widget.minValue) /
              (widget.maxValue - widget.minValue) *
              100)
          .clamp(0, 100);

  String get _status {
    final v = widget.currentValue;
    if (v < widget.optimalMin * 0.7 || v > widget.optimalMax * 1.3) return 'Critical';
    if (v < widget.optimalMin || v > widget.optimalMax) return 'Warning';
    return 'Optimal';
  }

  Color get _statusColor {
    switch (_status) {
      case 'Critical':
        return AppColors.error;
      case 'Warning':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _progress = Tween(begin: 0.0, end: _percent)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void didUpdateWidget(covariant SensorGaugeCard old) {
    super.didUpdateWidget(old);
    if (old.currentValue != widget.currentValue) {
      _progress = Tween(begin: _progress.value, end: _percent)
          .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
      _anim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sc = _statusColor;

    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final compact = w < 160;

      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06)),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4))
                  ],
          ),
          padding: EdgeInsets.all(compact ? 10 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── top row: icon + label + status dot ──
              Row(children: [
                Icon(widget.icon,
                    size: compact ? 14 : 16,
                    color: widget.accentColor.withOpacity(0.8)),
                SizedBox(width: compact ? 4 : 6),
                Expanded(
                  child: Text(widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withOpacity(0.7)
                            : AppColors.textSecondary,
                      )),
                ),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                      color: sc, shape: BoxShape.circle),
                ),
              ]),

              // ── gauge ──
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: compact ? 2 : 4,
                      horizontal: compact ? 4 : 8),
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (context, _) => CustomPaint(
                      painter: _ArcGaugePainter(
                        pct: _progress.value,
                        accent: widget.accentColor,
                        status: sc,
                        isDark: isDark,
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.currentValue.toStringAsFixed(
                                      widget.currentValue.truncateToDouble() ==
                                              widget.currentValue
                                          ? 0
                                          : 1),
                                  style: GoogleFonts.inter(
                                    fontSize: compact ? 18 : 22,
                                    fontWeight: FontWeight.w700,
                                    color: sc,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  widget.unit,
                                  style: GoogleFonts.inter(
                                    fontSize: compact ? 9 : 10,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white38
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── bottom row: range + trend ──
              Row(children: [
                Expanded(
                  child: Text(
                    '${widget.optimalMin.toStringAsFixed(0)}–${widget.optimalMax.toStringAsFixed(0)} ${widget.unit}',
                    style: GoogleFonts.inter(
                      fontSize: compact ? 8 : 9,
                      color: isDark
                          ? Colors.white24
                          : AppColors.textSecondary.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.trendText != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      widget.trendUp
                          ? Icons.north_east_rounded
                          : Icons.south_east_rounded,
                      size: compact ? 10 : 11,
                      color: widget.trendUp
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      widget.trendText!,
                      style: GoogleFonts.inter(
                        fontSize: compact ? 9 : 10,
                        fontWeight: FontWeight.w600,
                        color: widget.trendUp
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ]),
              ]),
            ],
          ),
        ),
      );
    });
  }
}

// ─── Arc Gauge Painter ───────────────────────────────────────────────────────

class _ArcGaugePainter extends CustomPainter {
  final double pct;
  final Color accent;
  final Color status;
  final bool isDark;

  _ArcGaugePainter({
    required this.pct,
    required this.accent,
    required this.status,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.58);
    final r = math.min(size.width, size.height) * 0.42;
    const start = math.pi * 0.8;
    const sweep = math.pi * 1.4;
    final strokeW = (r * 0.14).clamp(4.0, 9.0);

    // track
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start,
      sweep,
      false,
      Paint()
        ..color = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFEEEEEE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    // fill
    if (pct > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        sweep * pct / 100,
        false,
        Paint()
          ..shader = SweepGradient(
            startAngle: start,
            endAngle: start + sweep,
            colors: [accent.withOpacity(0.5), status],
          ).createShader(Rect.fromCircle(center: c, radius: r))
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcGaugePainter o) =>
      o.pct != pct || o.accent != accent || o.status != status;
}
