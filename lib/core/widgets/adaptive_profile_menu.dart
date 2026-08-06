import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Uses a touch-friendly bottom sheet on mobile and a wider anchored menu on
/// larger screens while preserving each header's existing actions.
class AdaptiveProfilePopupMenuButton extends ConsumerWidget {
  final Widget child;
  final PopupMenuItemBuilder<String> itemBuilder;
  final PopupMenuItemSelected<String>? onSelected;
  final Offset offset;
  final ShapeBorder? shape;

  const AdaptiveProfilePopupMenuButton({
    super.key,
    required this.child,
    required this.itemBuilder,
    this.onSelected,
    this.offset = Offset.zero,
    this.shape,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (!isMobile) {
      return PopupMenuButton<String>(
        offset: offset,
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 380),
        shape: shape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
        itemBuilder: itemBuilder,
        onSelected: onSelected,
        child: child,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showMobileSheet(context, ref),
      child: child,
    );
  }

  Future<void> _showMobileSheet(BuildContext context, WidgetRef ref) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.read(currentUserProvider);
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.neutral300,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      _initials(user?.name),
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Farm Estates user',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyLarge.copyWith(
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.role.displayName ?? 'Account',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _sheetAction(sheetContext, Icons.person_outline, 'Profile', 'profile', isDark),
              _sheetAction(sheetContext, Icons.settings_outlined, 'Settings', 'settings', isDark),
              const Divider(height: AppSpacing.lg),
              _sheetAction(sheetContext, Icons.logout_rounded, 'Logout', 'logout', isDark,
                  color: AppColors.error),
            ],
          ),
        ),
      ),
    );
    if (selected != null && context.mounted) onSelected?.call(selected);
  }

  Widget _sheetAction(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    bool isDark, {
    Color? color,
  }) {
    final foreground = color ?? (isDark ? Colors.white : AppColors.textPrimary);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: foreground),
      title: Text(label, style: AppTypography.bodyMedium.copyWith(color: foreground)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      onTap: () => Navigator.of(context).pop(value),
    );
  }

  String _initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'FE';
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.first.substring(0, 1).toUpperCase();
  }
}
