import '../theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/api_connection.dart';

/// Sits above the navigator so every role uses the same recovery screen.
class ApiConnectionHost extends StatefulWidget {
  const ApiConnectionHost({super.key, required this.child, this.connection});
  final Widget child;
  final ApiConnection? connection;

  @override
  State<ApiConnectionHost> createState() => _ApiConnectionHostState();
}

class _ApiConnectionHostState extends State<ApiConnectionHost>
    with WidgetsBindingObserver {
  ApiConnection get state => widget.connection ?? ApiConnection.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null) {
      _updateLifecycle(lifecycle);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    _updateLifecycle(lifecycle);
  }

  void _updateLifecycle(AppLifecycleState lifecycle) {
    final desktop = !kIsWeb &&
        const {
          TargetPlatform.windows,
          TargetPlatform.macOS,
          TargetPlatform.linux,
        }.contains(defaultTargetPlatform);
    // Inactive on desktop means the visible window lost keyboard focus.
    if (desktop && lifecycle == AppLifecycleState.inactive) return;
    state.setForeground(lifecycle == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final colors = Theme.of(context).colorScheme;
          return Stack(children: [
            ExcludeSemantics(
                excluding: state.unavailable,
                child: ExcludeFocus(
                    excluding: state.unavailable, child: widget.child)),
            if (state.unavailable)
              Positioned.fill(
                child: Material(
                    color: colors.surface,
                    child: SafeArea(
                      child: Center(
                          child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(24, 24, 24,
                            24 + MediaQuery.viewInsetsOf(context).bottom),
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                          color: colors.primary
                                              .withValues(alpha: .1),
                                          borderRadius:
                                              BorderRadius.circular(24)),
                                      child: Icon(Icons.cloud_off_outlined,
                                          size: 40, color: colors.primary)),
                                  const SizedBox(height: 24),
                                  Text('Let’s reconnect',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: AppTypography.pageTitleSize,
                                          fontWeight:
                                              AppTypography.headingWeight,
                                          color: colors.onSurface)),
                                  const SizedBox(height: 12),
                                  Text(connectionMessage,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: AppTypography.bodySize,
                                          height: 1.5,
                                          color: colors.onSurfaceVariant)),
                                  const SizedBox(height: 12),
                                  Text(
                                      state.submissionInterrupted
                                          ? 'An action was interrupted. Check whether it completed before trying again.'
                                          : 'Your place is saved. Pending data will refresh when you reconnect.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: AppTypography.captionSize,
                                          height: 1.5,
                                          color: colors.onSurfaceVariant)),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                          onPressed: state.checking
                                              ? null
                                              : state.retry,
                                          style: FilledButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12))),
                                          icon: state.checking
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2))
                                              : const Icon(Icons.refresh_rounded,
                                                  size: 20),
                                          label: Text(state.checking ? 'Connecting…' : 'Try again'))),
                                ])),
                      )),
                    )),
              ),
          ]);
        });
  }
}
