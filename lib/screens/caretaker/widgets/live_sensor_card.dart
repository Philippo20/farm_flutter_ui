import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// A compact live-sensor card with a smooth bezier sparkline.
/// Fully responsive via LayoutBuilder.
class LiveSensorCard extends StatefulWidget {
  final String name;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final List<double> sparkData;
  final String status; // Normal | Warning | Critical | Optimal
  final String? trend;
  final bool trendUp;
  final DateTime lastUpdated;
  final VoidCallback? onTap;

  const LiveSensorCard({
    super.key,
    required this.name,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.sparkData = const [],
    this.status = 'Normal',
    this.trend,
    this.trendUp = true,
    required this.lastUpdated,
    this.onTap,
  });

  @override
  State<LiveSensorCard> createState() => _LiveSensorCardState();
}

class _LiveSensorCardState extends State<LiveSensorCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.status.toLowerCase()) {
      case 'critical':
        return AppColors.error;
      case 'warning':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  String get _timeAgo {
    final d = DateTime.now().difference(widget.lastUpdated);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3)),
                  ],
          ),
          padding: EdgeInsets.all(compact ? 10 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── header ──
              Row(children: [
                // live dot
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: sc.withOpacity(0.4 + _pulse.value * 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: isDark
                          ? Colors.white.withOpacity(0.55)
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                Icon(widget.icon,
                    size: compact ? 13 : 14,
                    color: widget.color.withOpacity(0.7)),
              ]),

              SizedBox(height: compact ? 4 : 6),

              // ── value row ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      widget.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: compact ? 20 : 24,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 3),
                    child: Text(
                      widget.unit,
                      style: GoogleFonts.inter(
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white38
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (widget.trend != null) _chip(widget.trend!, widget.trendUp, compact),
                ],
              ),

              SizedBox(height: compact ? 3 : 5),

              // ── sparkline ──
              if (widget.sparkData.length > 1)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _BezierSparkPainter(
                        data: widget.sparkData,
                        lineColor: widget.color,
                        isDark: isDark,
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),

              SizedBox(height: compact ? 2 : 4),

              // ── footer ──
              Row(children: [
                Icon(Icons.schedule,
                    size: compact ? 9 : 10,
                    color: isDark
                        ? Colors.white24
                        : AppColors.textSecondary.withOpacity(0.5)),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    _timeAgo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: compact ? 8 : 9,
                      color: isDark
                          ? Colors.white24
                          : AppColors.textSecondary.withOpacity(0.5),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: sc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.status,
                    style: GoogleFonts.inter(
                      fontSize: compact ? 7 : 8,
                      fontWeight: FontWeight.w600,
                      color: sc,
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      );
    });
  }

  Widget _chip(String text, bool up, bool compact) {
    final c = up ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
          color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(up ? Icons.north_east_rounded : Icons.south_east_rounded,
            size: compact ? 8 : 9, color: c),
        const SizedBox(width: 1),
        Text(text,
            style: GoogleFonts.inter(
                fontSize: compact ? 8 : 9,
                fontWeight: FontWeight.w600,
                color: c)),
      ]),
    );
  }
}

// ─── Smooth Bezier Sparkline Painter ─────────────────────────────────────────

class _BezierSparkPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final bool isDark;

  _BezierSparkPainter(
      {required this.data, required this.lineColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2 || size.isEmpty) return;

    final lo = data.reduce(math.min);
    final hi = data.reduce(math.max);
    final range = hi - lo;

    List<Offset> pts = [];
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final norm = range == 0 ? 0.5 : (data[i] - lo) / range;
      pts.add(Offset(x, size.height - norm * size.height));
    }

    // build smooth bezier path
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1x = pts[i].dx + (pts[i + 1].dx - pts[i].dx) / 3;
      final cp2x = pts[i + 1].dx - (pts[i + 1].dx - pts[i].dx) / 3;
      path.cubicTo(cp1x, pts[i].dy, cp2x, pts[i + 1].dy, pts[i + 1].dx,
          pts[i + 1].dy);
    }

    // gradient fill
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withOpacity(0.18), lineColor.withOpacity(0.01)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // line
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // endpoint dot
    if (size.height > 14) {
      final last = pts.last;
      canvas.drawCircle(last, 3, Paint()..color = lineColor);
      canvas.drawCircle(
          last,
          3,
          Paint()
            ..color = isDark ? const Color(0xFF1E1E1E) : Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
    }
  }

  @override
  bool shouldRepaint(_BezierSparkPainter o) =>
      o.data != data || o.lineColor != lineColor;
}
