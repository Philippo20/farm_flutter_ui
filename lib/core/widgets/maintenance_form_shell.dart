import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_bottom_sheet.dart';
import 'app_dialog.dart';

Future<bool?> showMaintenanceRoute(BuildContext context, Widget child) {
  final mobile = MediaQuery.sizeOf(context).width < 600 ||
      Theme.of(context).platform == TargetPlatform.android ||
      Theme.of(context).platform == TargetPlatform.iOS;
  if (mobile) {
    return showAppBottomSheet<bool>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        builder: (context) => AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: SafeArea(top: false, child: child)));
  }
  return showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppDialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: child));
}

class MaintenanceFormShell extends StatelessWidget {
  const MaintenanceFormShell(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.saving,
      required this.onSave,
      required this.child,
      this.action = 'Save',
      this.icon = Icons.build_outlined,
      this.error});
  final IconData icon;
  final String title, subtitle, action;
  final bool saving;
  final VoidCallback? onSave;
  final Widget child;
  final String? error;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.surfaceDark : Colors.white;
    final foreground = dark ? Colors.white : AppColors.textPrimary;
    final muted = dark ? Colors.white70 : AppColors.textSecondary;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
        canPop: !saving,
        child: Container(
          constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: (MediaQuery.sizeOf(context).height * .9 - keyboard)
                  .clamp(180, double.infinity)),
          decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: .12),
                    blurRadius: 24,
                    offset: const Offset(0, 12))
              ]),
          child: Material(
              color: surface,
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
                          child: Icon(icon, size: 20, color: Colors.white)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(title,
                                style: AppTypography.font(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: foreground)),
                            const SizedBox(height: 3),
                            Text(subtitle,
                                style: AppTypography.font(
                                    fontSize: 12, color: muted)),
                          ])),
                      IconButton(
                          onPressed:
                              saving ? null : () => Navigator.pop(context),
                          tooltip: 'Close',
                          icon: const Icon(Icons.close, size: 16)),
                    ])),
                Flexible(
                    child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              child,
                              if (error != null)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: Text(error!,
                                        style: AppTypography.bodySmall.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error))),
                            ]))),
                Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Row(children: [
                      Expanded(
                          child: OutlinedButton(
                              style: _buttonStyle(),
                              onPressed:
                                  saving ? null : () => Navigator.pop(context),
                              child: const Text('Cancel'))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: FilledButton(
                              style: _buttonStyle(),
                              onPressed: saving ? null : onSave,
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (saving) ...[
                                      const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)),
                                      const SizedBox(width: 8)
                                    ],
                                    Flexible(
                                        child: Text(
                                            saving ? 'Saving...' : action)),
                                  ]))),
                    ])),
              ])),
        ));
  }

  ButtonStyle _buttonStyle() => TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12),
      textStyle: AppTypography.font(
          fontSize: 13, fontWeight: AppTypography.labelWeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)));
}

Widget maintenanceField(String label, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: AppTypography.font(fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      child,
    ]));

InputDecoration maintenanceInput(BuildContext context,
    {IconData? icon, String? hint}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:
          BorderSide(color: dark ? Colors.white12 : AppColors.neutral200));
  return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.font(fontSize: 12),
      filled: true,
      fillColor:
          dark ? Colors.white.withValues(alpha: .04) : AppColors.neutral50,
      prefixIcon: icon == null ? null : Icon(icon, size: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorMaxLines: 3);
}

Widget maintenancePair(BuildContext context, Widget first, Widget second) =>
    MediaQuery.sizeOf(context).width >= 600
        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: first),
            const SizedBox(width: 10),
            Expanded(child: second)
          ])
        : Column(children: [first, second]);
