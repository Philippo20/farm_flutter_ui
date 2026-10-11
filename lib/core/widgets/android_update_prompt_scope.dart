import 'package:flutter/widgets.dart';

/// Gives the APK check and update sheet priority over native sign-in prompts.
/// Scoped to the host so a disposed app cannot leave a global login lock behind.
class AndroidUpdatePromptScope extends InheritedWidget {
  const AndroidUpdatePromptScope({
    super.key,
    required this.blocksBiometrics,
    required super.child,
  });

  final bool blocksBiometrics;

  static bool isBlocking(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AndroidUpdatePromptScope>()
          ?.blocksBiometrics ??
      false;

  @override
  bool updateShouldNotify(AndroidUpdatePromptScope oldWidget) =>
      blocksBiometrics != oldWidget.blocksBiometrics;
}
