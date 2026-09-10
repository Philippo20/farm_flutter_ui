import 'app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../screens/caretaker/chat_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'package:google_fonts/google_fonts.dart';

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
        itemBuilder: (context) => [
          ...itemBuilder(context),
          const PopupMenuItem(
              value: 'team_messages',
              child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.chat_bubble_outline),
                  title: Text('Messages'))),
        ],
        onSelected: (value) => _handleSelection(context, value),
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
    final selected = await showAppBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.9,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.75)
                      ]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.manage_accounts_outlined,
                        size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your account',
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text('Profile and preferences',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.textSecondary)),
                    ],
                  )),
                  IconButton(
                    tooltip: 'Close account menu',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    style: IconButton.styleFrom(
                      foregroundColor:
                          isDark ? Colors.white54 : AppColors.textSecondary,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : AppColors.neutral50,
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary
                            .withValues(alpha: isDark ? 0.12 : 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.12),
                              child: Text(_initials(user?.name),
                                  style: GoogleFonts.inter(
                                      fontSize: 15,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(user?.name ?? 'Farm Estates user',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Text(user?.role.displayName ?? 'Account',
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? Colors.white70
                                              : AppColors.primary)),
                                  if (user?.email.isNotEmpty == true) ...[
                                    const SizedBox(height: 4),
                                    Text(user!.email,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white54
                                                : AppColors.textSecondary)),
                                  ],
                                ])),
                          ]),
                    ),
                    const SizedBox(height: 12),
                    _sheetAction(
                        sheetContext,
                        Icons.person_outline_rounded,
                        'Profile',
                        'View and manage your details',
                        'profile',
                        isDark),
                    const SizedBox(height: 6),
                    _sheetAction(
                        sheetContext,
                        Icons.settings_outlined,
                        'Settings',
                        'Manage your preferences',
                        'settings',
                        isDark),
                    const SizedBox(height: 6),
                    _sheetAction(
                        sheetContext,
                        Icons.chat_bubble_outline_rounded,
                        'Messages',
                        'Stay in touch with your team',
                        'team_messages',
                        isDark),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: isDark
                                ? Colors.white10
                                : AppColors.neutral100))),
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(sheetContext).pop('logout'),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Log out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && context.mounted) {
      _handleSelection(context, selected);
    }
  }

  void _handleSelection(BuildContext context, String value) {
    if (value == 'team_messages') {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ChatScreen()));
    } else {
      onSelected?.call(value);
    }
  }

  Widget _sheetAction(
    BuildContext context,
    IconData icon,
    String label,
    String subtitle,
    String value,
    bool isDark,
  ) {
    return Material(
      color:
          isDark ? Colors.white.withValues(alpha: 0.035) : AppColors.neutral50,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.of(context).pop(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(children: [
            Icon(icon,
                size: 20, color: isDark ? Colors.white70 : AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondary)),
                ])),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? Colors.white38 : AppColors.textSecondary),
          ]),
        ),
      ),
    );
  }

  String _initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'FE';
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.first.substring(0, 1).toUpperCase();
  }
}
