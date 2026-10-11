import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

/// Currency glyph, avoiding Material money icons that contain a dollar sign.
class CediIcon extends StatelessWidget {
  const CediIcon({super.key, this.size = 20, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: size,
      height: size,
      child: Center(
          child: Text('₵',
              style: AppTypography.font(
                  fontSize: size,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: color ?? IconTheme.of(context).color))));
}
