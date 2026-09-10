import 'package:flutter/material.dart';
import '../../services/api_connection.dart';

/// Sits above the navigator so every role uses the same recovery screen.
class ApiConnectionHost extends StatelessWidget {
  const ApiConnectionHost({super.key, required this.child, this.connection});
  final Widget child;
  final ApiConnection? connection;

  @override
  Widget build(BuildContext context) {
    final state = connection ?? ApiConnection.instance;
    return ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final colors = Theme.of(context).colorScheme;
          return Stack(children: [
            ExcludeSemantics(
                excluding: state.unavailable,
                child:
                    ExcludeFocus(excluding: state.unavailable, child: child)),
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
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: colors.onSurface)),
                                  const SizedBox(height: 12),
                                  Text(connectionMessage,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: colors.onSurfaceVariant)),
                                  const SizedBox(height: 12),
                                  Text(
                                      state.submissionInterrupted
                                          ? 'An action was interrupted. Check whether it completed before trying again.'
                                          : 'Your place is saved. Pending data will refresh when you reconnect.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 12,
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
