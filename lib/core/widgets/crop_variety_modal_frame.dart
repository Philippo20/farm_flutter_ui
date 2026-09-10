import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CropVarietyModalFrame extends StatelessWidget {
  const CropVarietyModalFrame(
      {super.key, required this.mobile, required this.isDark, required this.child});
  final bool mobile, isDark;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final content = Container(
        constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: (media.size.height -
                    media.viewInsets.bottom -
                    media.padding.top) *
                .9),
        decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: mobile
                ? []
                : const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 24,
                        offset: Offset(0, 12))
                  ]),
        child: SafeArea(top: false, bottom: mobile, child: child));
    if (mobile) {
      return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: content);
    }
    return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: content);
  }
}
