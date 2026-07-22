import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({required this.child, super.key});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.42, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    required this.height,
    this.width,
    this.borderRadius = AppSpacing.radiusSm,
    super.key,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.12)
            : AppColors.neutral200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class AdminDataSkeleton extends StatelessWidget {
  const AdminDataSkeleton({
    this.rowCount = 6,
    this.showStats = true,
    super.key,
  });

  final int rowCount;
  final bool showStats;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SkeletonPulse(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showStats) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 640 ? 2 : 4;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: columns,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: constraints.maxWidth < 640 ? 2 : 2.5,
                  ),
                  itemBuilder: (_, __) => _SkeletonStat(isDark: isDark),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.07),
              ),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Expanded(flex: 3, child: SkeletonBox(height: 14)),
                    SizedBox(width: AppSpacing.xl),
                    Expanded(flex: 2, child: SkeletonBox(height: 14)),
                    SizedBox(width: AppSpacing.xl),
                    Expanded(child: SkeletonBox(height: 14)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                for (var index = 0; index < rowCount; index++) ...[
                  const _SkeletonRow(),
                  if (index != rowCount - 1)
                    Divider(
                      height: AppSpacing.xl,
                      color: isDark ? Colors.white10 : AppColors.neutral200,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonStat extends StatelessWidget {
  const _SkeletonStat({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: const Row(
        children: [
          SkeletonBox(height: 38, width: 38, borderRadius: 8),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 12),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(height: 18, width: 54),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SkeletonBox(height: 34, width: 34, borderRadius: 17),
        SizedBox(width: AppSpacing.md),
        Expanded(flex: 3, child: SkeletonBox(height: 14)),
        SizedBox(width: AppSpacing.xl),
        Expanded(flex: 2, child: SkeletonBox(height: 14)),
        SizedBox(width: AppSpacing.xl),
        Expanded(child: SkeletonBox(height: 24, borderRadius: 12)),
      ],
    );
  }
}
