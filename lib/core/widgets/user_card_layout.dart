import 'package:flutter/material.dart';

/// Content-sized user cards with the same presentation across devices.
class UserCardLayout extends StatelessWidget {
  const UserCardLayout({super.key, required this.children, this.singleColumn = false});
  final List<Widget> children;
  final bool singleColumn;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    const gap = 12.0;
    final columns = singleColumn ? 1 : ((constraints.maxWidth + gap) / (320 + gap)).floor().clamp(1, 3);
    final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [for (final child in children) SizedBox(width: width, child: child)],
    );
  });
}
