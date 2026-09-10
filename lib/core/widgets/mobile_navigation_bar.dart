import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shared mobile shell. Safe-area space is reserved once, below the destinations.
class MobileNavigationBar extends StatelessWidget {
  const MobileNavigationBar({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
            top: BorderSide(
                color: dark ? Colors.white10 : AppColors.neutral200)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.18 : 0.04),
              blurRadius: 18,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children),
          )),
    );
  }
}

class MobileNavigationDestination extends StatelessWidget {
  const MobileNavigationDestination(
      {super.key,
      required this.icon,
      required this.activeIcon,
      required this.label,
      required this.selected,
      required this.onTap});
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? (dark ? const Color(0xFF86D6AE) : AppColors.primary)
        : (dark ? Colors.white60 : AppColors.textSecondary);
    return Expanded(
        child: Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Tooltip(
          message: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    AnimatedContainer(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                                .withValues(alpha: dark ? 0.24 : 0.10)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(selected ? activeIcon : icon,
                          size: 22, color: color),
                    ),
                    const SizedBox(height: 4),
                    ExcludeSemantics(
                        child: Text(label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 10,
                                height: 1.4,
                                color: color,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500))),
                  ]),
                ),
              ),
            ),
          )),
    ));
  }
}
