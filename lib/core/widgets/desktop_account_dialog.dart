import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_dialog.dart';

class DesktopAccountDialog extends StatelessWidget {
  const DesktopAccountDialog(
      {super.key,
      required this.name,
      required this.email,
      required this.role,
      required this.items});
  final String name, email, role;
  final List<PopupMenuItem<String>> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? 'FE'
        : (parts.first.characters.first +
                (parts.length > 1 ? parts.last.characters.first : ''))
            .toUpperCase();
    void select(PopupMenuItem<String> item) {
      Navigator.pop(context, item.value);
      item.onTap?.call();
    }

    final logout = items.where((item) => item.value == 'logout').firstOrNull;
    Widget action(PopupMenuItem<String> item) {
      final spec = switch (item.value) {
        'profile' => (
            Icons.person_outline_rounded,
            'Profile',
            'View and manage your personal details'
          ),
        'settings' => (
            Icons.settings_outlined,
            'Settings',
            'Manage your account preferences'
          ),
        'team_messages' => (
            Icons.chat_bubble_outline_rounded,
            'Messages',
            'Open conversations with your team'
          ),
        _ => (Icons.more_horiz_rounded, '', ''),
      };
      return Material(
          color:
              dark ? Colors.white.withValues(alpha: .035) : AppColors.neutral50,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
              onTap: item.enabled ? () => select(item) : null,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    Icon(spec.$1,
                        size: 20,
                        color: item.enabled
                            ? colors.primary
                            : colors.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                        child: spec.$2.isEmpty
                            ? (item.child ?? const SizedBox.shrink())
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(spec.$2,
                                        style: AppTypography.body.copyWith(
                                            fontWeight:
                                                AppTypography.labelWeight,
                                            color: colors.onSurface)),
                                    const SizedBox(height: 3),
                                    Text(spec.$3,
                                        style: AppTypography.caption.copyWith(
                                            color: colors.onSurfaceVariant)),
                                  ])),
                    const SizedBox(width: 10),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: colors.onSurfaceVariant),
                  ]))));
    }

    final buttons = ButtonStyle(
        padding:
            const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
        textStyle: WidgetStatePropertyAll(AppTypography.font(
            fontSize: AppTypography.actionSize,
            fontWeight: AppTypography.labelWeight)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    return AppDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
            constraints: BoxConstraints(
                maxWidth: 440,
                maxHeight: MediaQuery.sizeOf(context).height * .9),
            decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? .35 : .12),
                      blurRadius: 24,
                      offset: const Offset(0, 12))
                ]),
            child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Row(children: [
                        Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  AppColors.primary,
                                  Color(0xff15803d)
                                ]),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.manage_accounts_outlined,
                                size: 20, color: Colors.white)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Your account',
                                  style: AppTypography.titleSmall
                                      .copyWith(color: colors.onSurface)),
                              const SizedBox(height: 3),
                              Text('Profile and preferences',
                                  style: AppTypography.caption.copyWith(
                                      color: colors.onSurfaceVariant)),
                            ])),
                        IconButton(
                            tooltip: 'Close account menu',
                            onPressed: () => Navigator.pop(context),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                            icon: Icon(Icons.close_rounded,
                                size: 16, color: colors.onSurfaceVariant)),
                      ])),
                  Flexible(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          physics: const BouncingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                        color: colors.primary
                                            .withValues(alpha: .06),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: colors.primary
                                                .withValues(alpha: .15))),
                                    child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                              radius: 24,
                                              backgroundColor: colors.primary
                                                  .withValues(alpha: .12),
                                              child: Text(initials,
                                                  style: AppTypography
                                                      .titleSmall
                                                      .copyWith(
                                                          color:
                                                              colors.primary))),
                                          const SizedBox(width: 12),
                                          Expanded(
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                Text(name,
                                                    style: AppTypography.body
                                                        .copyWith(
                                                            color: colors
                                                                .onSurface,
                                                            fontWeight:
                                                                AppTypography
                                                                    .headingWeight)),
                                                const SizedBox(height: 4),
                                                Text(role,
                                                    style: AppTypography.caption
                                                        .copyWith(
                                                            color:
                                                                colors.primary,
                                                            fontWeight:
                                                                AppTypography
                                                                    .labelWeight)),
                                                if (email.isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  SelectableText(email,
                                                      style: AppTypography
                                                          .caption
                                                          .copyWith(
                                                              color: colors
                                                                  .onSurfaceVariant)),
                                                ],
                                              ])),
                                        ])),
                                const SizedBox(height: 16),
                                for (final item in items.where(
                                    (item) => item.value != 'logout')) ...[
                                  action(item),
                                  const SizedBox(height: 8),
                                ],
                              ]))),
                  Container(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                      decoration: BoxDecoration(
                          border: Border(
                              top: BorderSide(color: colors.outlineVariant))),
                      child: Row(children: [
                        Expanded(
                            child: OutlinedButton(
                                style: buttons,
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'))),
                        if (logout != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                              child: TextButton.icon(
                                  style: buttons.copyWith(
                                      foregroundColor:
                                          const WidgetStatePropertyAll(
                                              AppColors.error)),
                                  onPressed: logout.enabled
                                      ? () => select(logout)
                                      : null,
                                  icon: const Icon(Icons.logout_rounded,
                                      size: 16),
                                  label: const Text('Log out'))),
                        ],
                      ])),
                ]))));
  }
}
