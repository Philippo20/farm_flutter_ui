import 'package:flutter/material.dart';
import 'app_bottom_sheet.dart';

/// Presents existing dialog workflows as sheets on phones and Android tablets.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  TraversalEdgeBehavior? traversalEdgeBehavior,
  bool? requestFocus,
}) async {
  final mobile = MediaQuery.sizeOf(context).width < 600 ||
      Theme.of(context).platform == TargetPlatform.android;
  TransitionRoute<dynamic>? route;
  Widget buildContent(BuildContext context) {
    route = ModalRoute.of(context) as TransitionRoute<dynamic>?;
    return _AppDialogScope(mobile: mobile, child: builder(context));
  }

  final T? result;
  if (mobile) {
    result = await showAppBottomSheet<T>(
        context: context,
        builder: buildContent,
        isScrollControlled: true,
        useSafeArea: useSafeArea,
        useRootNavigator: useRootNavigator,
        isDismissible: barrierDismissible,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        routeSettings: routeSettings,
        anchorPoint: anchorPoint,
        requestFocus: requestFocus);
  } else {
    result = await showDialog<T>(
        context: context,
        builder: buildContent,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        useSafeArea: useSafeArea,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
        anchorPoint: anchorPoint,
        traversalEdgeBehavior: traversalEdgeBehavior,
        requestFocus: requestFocus);
  }
  // Callers may now dispose form controllers without racing the closing route.
  await route?.completed;
  return result;
}

class _AppDialogScope extends InheritedWidget {
  const _AppDialogScope({required this.mobile, required super.child});
  final bool mobile;
  static bool mobileOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AppDialogScope>()?.mobile ??
      false;
  @override
  bool updateShouldNotify(_AppDialogScope oldWidget) =>
      mobile != oldWidget.mobile;
}

/// Drop-in Dialog shell; leaves established desktop layouts intact.
class AppDialog extends Dialog {
  const AppDialog(
      {super.key,
      super.backgroundColor,
      super.elevation,
      super.shadowColor,
      super.surfaceTintColor,
      super.insetAnimationDuration,
      super.insetAnimationCurve,
      super.insetPadding,
      super.clipBehavior,
      super.shape,
      super.alignment,
      super.child,
      super.constraints,
      super.semanticsRole});
  @override
  Widget build(BuildContext context) {
    if (!_AppDialogScope.mobileOf(context)) return super.build(context);
    return _SheetShell(
        color: backgroundColor, child: child ?? const SizedBox.shrink());
  }
}

/// Alert-style workflows keep their actions outside the scrolling content.
class AppAlertDialog extends AlertDialog {
  const AppAlertDialog(
      {super.key,
      super.icon,
      super.iconPadding,
      super.iconColor,
      super.title,
      super.titlePadding,
      super.titleTextStyle,
      super.content,
      super.contentPadding,
      super.contentTextStyle,
      super.actions,
      super.actionsPadding,
      super.actionsAlignment,
      super.actionsOverflowAlignment,
      super.actionsOverflowDirection,
      super.actionsOverflowButtonSpacing,
      super.buttonPadding,
      super.backgroundColor,
      super.elevation,
      super.shadowColor,
      super.surfaceTintColor,
      super.semanticLabel,
      super.insetPadding,
      super.clipBehavior,
      super.shape,
      super.alignment,
      super.scrollable,
      super.constraints});
  @override
  Widget build(BuildContext context) {
    if (!_AppDialogScope.mobileOf(context)) return super.build(context);
    return _SheetShell(
        color: backgroundColor,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null)
            Padding(
                padding: iconPadding ?? const EdgeInsets.only(top: 20),
                child: icon!),
          if (title != null)
            Padding(
                padding:
                    titlePadding ?? const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: DefaultTextStyle(
                        style: titleTextStyle ??
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                fontSize: 16, fontWeight: FontWeight.bold),
                        child: title!))),
          if (content != null)
            Flexible(
                child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: contentPadding ??
                        const EdgeInsets.symmetric(horizontal: 24),
                    child: DefaultTextStyle(
                        style: contentTextStyle ??
                            Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(fontSize: 12),
                        child: content!))),
          if (actions != null && actions!.isNotEmpty)
            Padding(
                padding: actionsPadding ?? const EdgeInsets.all(24),
                child: OverflowBar(
                    alignment: actionsAlignment ?? MainAxisAlignment.end,
                    spacing: 12,
                    overflowSpacing: 8,
                    children: actions!)),
          if (actions == null || actions!.isEmpty) const SizedBox(height: 16),
        ]));
  }
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child, this.color});
  final Widget child;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final surface = color != null && color!.a == 1
        ? color!
        : Theme.of(context).colorScheme.surface;
    return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: (media.size.height -
                            media.viewInsets.bottom -
                            media.padding.top)
                        .clamp(0.0, double.infinity) *
                    .9),
            child: Material(
                color: surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: SafeArea(
                    top: false,
                    child: SizedBox(width: double.infinity, child: child)))));
  }
}
