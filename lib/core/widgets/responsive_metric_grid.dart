import 'package:flutter/material.dart';

/// Lets compact metric cards grow with their text while retaining desktop grids.
class ResponsiveMetricGrid extends StatelessWidget {
  const ResponsiveMetricGrid({
    super.key,
    required this.useContentHeight,
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.children,
  });

  final bool useContentHeight;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!useContentHeight) {
      return GridView.count(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        children: children,
      );
    }
    return LayoutBuilder(builder: (context, constraints) {
      final width =
          (constraints.maxWidth - crossAxisSpacing * (crossAxisCount - 1)) /
              crossAxisCount;
      return Wrap(
        spacing: crossAxisSpacing,
        runSpacing: mainAxisSpacing,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    });
  }
}
