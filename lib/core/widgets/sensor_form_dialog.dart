import '../theme/app_typography.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_dialog.dart';

class SensorFormDialog extends StatelessWidget {
  const SensorFormDialog(
      {super.key,
      required this.editing,
      required this.saving,
      required this.onSave,
      required this.child});
  final bool editing, saving;
  final VoidCallback onSave;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.surfaceDark : Colors.white;
    final foreground = dark ? Colors.white : AppColors.textPrimary;
    final secondary = dark ? Colors.white70 : AppColors.textSecondary;
    final buttons = ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
        textStyle: WidgetStatePropertyAll(
            AppTypography.font(fontSize: AppTypography.actionSize, fontWeight: AppTypography.headingWeight)),
        padding:
            const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    return PopScope(
        canPop: !saving,
        child: AppDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
                height: MediaQuery.sizeOf(context).height * .9,
                constraints: BoxConstraints(
                    maxWidth: 500,
                    maxHeight: MediaQuery.sizeOf(context).height * .9),
                decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color:
                              Colors.black.withValues(alpha: dark ? .35 : .12),
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
                                child: const Icon(Icons.sensors_rounded,
                                    size: 20, color: Colors.white)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(
                                      editing
                                          ? 'Update Sensor'
                                          : 'Register Sensor',
                                      style: AppTypography.font(
                                          fontSize: AppTypography.cardTitleSize,
                                          fontWeight: AppTypography.headingWeight,
                                          color: foreground)),
                                  const SizedBox(height: 3),
                                  Text('Device settings and operating limits',
                                      style: AppTypography.font(
                                          fontSize: AppTypography.captionSize, color: secondary)),
                                ])),
                            IconButton(
                                tooltip: 'Close',
                                onPressed: saving
                                    ? null
                                    : () => Navigator.pop(context),
                                constraints: const BoxConstraints(
                                    minWidth: 28, minHeight: 28),
                                padding: const EdgeInsets.all(6),
                                icon: Icon(Icons.close_rounded,
                                    size: 16, color: secondary)),
                          ])),
                      Expanded(
                          child: SingleChildScrollView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              physics: const BouncingScrollPhysics(),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              child: child)),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                              color: surface,
                              border: Border(
                                  top: BorderSide(
                                      color: dark
                                          ? Colors.white10
                                          : AppColors.neutral200)),
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(16))),
                          child: Row(children: [
                            Expanded(
                                child: OutlinedButton(
                                    style: buttons,
                                    onPressed: saving
                                        ? null
                                        : () => Navigator.pop(context),
                                    child: const Text('Cancel'))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: FilledButton.icon(
                                    style: buttons,
                                    onPressed: saving ? null : onSave,
                                    icon: saving
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : const Icon(Icons.save_outlined,
                                            size: 16),
                                    label: Text(saving
                                        ? 'Saving…'
                                        : editing
                                            ? 'Update'
                                            : 'Save'))),
                          ])),
                    ])))));
  }
}

class SensorFormRow extends StatelessWidget {
  const SensorFormRow(
      {super.key, required this.children, this.stackOnMobile = false});
  final List<Widget> children;
  final bool stackOnMobile;
  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600 ||
        Theme.of(context).platform == TargetPlatform.android;
    if (!mobile || !stackOnMobile)
      return Row(
          crossAxisAlignment: CrossAxisAlignment.start, children: children);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final child in children)
        if (child is Expanded)
          child.child
        else if (child is SizedBox)
          const SizedBox(height: 14)
        else
          child,
    ]);
  }
}
