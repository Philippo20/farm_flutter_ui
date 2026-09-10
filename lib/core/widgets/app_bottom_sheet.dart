import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keeps the gesture/navigation area consistent with the visible sheet surface.
/// The annotated region is removed with the route, restoring the page's style.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  String? barrierLabel,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  double scrollControlDisabledMaxHeightRatio = 9 / 16,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  bool useSafeArea = false,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
  AnimationStyle? sheetAnimationStyle,
  bool? requestFocus,
}) =>
    showModalBottomSheet<T>(
      context: context,
      backgroundColor: backgroundColor,
      barrierLabel: barrierLabel,
      elevation: elevation ?? 0,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      barrierColor: barrierColor,
      isScrollControlled: isScrollControlled,
      scrollControlDisabledMaxHeightRatio: scrollControlDisabledMaxHeightRatio,
      useRootNavigator: useRootNavigator,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      useSafeArea: useSafeArea,
      routeSettings: routeSettings,
      transitionAnimationController: transitionAnimationController,
      anchorPoint: anchorPoint,
      sheetAnimationStyle: sheetAnimationStyle,
      requestFocus: requestFocus,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final surface = backgroundColor != null && backgroundColor.a == 1
            ? backgroundColor
            : theme.colorScheme.surface;
        final dark =
            ThemeData.estimateBrightnessForColor(surface) == Brightness.dark;
        final media = MediaQuery.of(sheetContext);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            systemNavigationBarColor: surface,
            systemNavigationBarDividerColor: surface,
            systemNavigationBarIconBrightness:
                dark ? Brightness.light : Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
          // One surface continues behind existing safe-area padding to the
          // gesture bar, matching the logout sheet without adding another inset.
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(children: [
              builder(sheetContext),
              // Inner form shadows must not darken the system gesture inset.
              // Paint over that reserved area without changing layout or taps.
              if (media.viewInsets.bottom == 0 && media.viewPadding.bottom > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: media.viewPadding.bottom,
                  child: IgnorePointer(child: ColoredBox(color: surface)),
                ),
            ]),
          ),
        );
      },
    );
