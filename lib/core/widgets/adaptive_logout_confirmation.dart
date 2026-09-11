import 'app_dialog.dart';
import 'app_bottom_sheet.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

Future<bool> showAdaptiveLogoutConfirmation(
  BuildContext context, {
  String title = 'Logout',
  String message = 'Are you sure you want to logout?',
  String confirmLabel = 'Logout',
}) async {
  final mediaQuery = MediaQuery.of(context);
  final platform = Theme.of(context).platform;
  final useBottomSheet = mediaQuery.size.width < 600 ||
      platform == TargetPlatform.android ||
      platform == TargetPlatform.iOS;

  if (useBottomSheet) {
    return await showAppBottomSheet<bool>(
          context: context,
          useSafeArea: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) {
            return _LogoutConfirmationSheet(
              title: title,
              message: message,
              confirmLabel: confirmLabel,
            );
          },
        ) ??
        false;
  }

  return await showAppDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return _LogoutConfirmationDialog(
            title: title,
            message: message,
            confirmLabel: confirmLabel,
          );
        },
      ) ??
      false;
}

class _LogoutConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;

  const _LogoutConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final foreground = isDark ? Colors.white : AppColors.textPrimary;
    final secondary = isDark ? Colors.white60 : AppColors.textSecondary;
    final border = isDark ? Colors.white12 : AppColors.neutral200;
    final labelStyle = AppTypography.font(
        fontSize: AppTypography.actionSize,
        fontWeight: AppTypography.labelWeight);

    return AppDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? .24 : .12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              )
            ],
          ),
          child: Material(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: .75),
                        ]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            title == 'Logout'
                                ? 'Log out of Farm Estates?'
                                : title,
                            style: AppTypography.font(
                                fontSize: AppTypography.cardTitleSize,
                                fontWeight: AppTypography.headingWeight,
                                color: foreground)),
                        const SizedBox(height: 3),
                        Text('Account session',
                            style: AppTypography.font(
                                fontSize: AppTypography.captionSize,
                                color: secondary)),
                      ],
                    )),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      color: secondary,
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: .04)
                            : Colors.black.withValues(alpha: .04),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ]),
                ),
                Flexible(
                    child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Text(
                    message == 'Are you sure you want to logout?'
                        ? 'You will need to sign in again to access your workspace.'
                        : message,
                    style: AppTypography.font(
                      fontSize: AppTypography.captionSize,
                      height: 1.6,
                      color: secondary,
                    ),
                  ),
                )),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: border))),
                  child: Row(children: [
                    Expanded(
                        child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: foreground,
                        textStyle: labelStyle,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        textStyle: labelStyle,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                          confirmLabel == 'Logout' ? 'Log out' : confirmLabel),
                    )),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutConfirmationSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;

  const _LogoutConfirmationSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : AppColors.neutral300,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(
              fontSize: AppTypography.headingSize,
              fontWeight: AppTypography.headingWeight,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? Colors.white70 : AppColors.textPrimary,
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : AppColors.neutral300,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
