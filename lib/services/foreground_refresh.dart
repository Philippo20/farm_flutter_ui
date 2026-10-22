import 'dart:async';
import 'package:flutter/widgets.dart';

class RefreshTicket {
  RefreshTicket._(this._valid);
  final bool Function() _valid;
  bool get isCurrent => _valid();
}

/// Serial refreshes that pause during sleep. Old responses cannot update the UI
/// after a pause, resume or disposal. A resumed refresh waits for old work to end.
class ForegroundRefresh with WidgetsBindingObserver {
  ForegroundRefresh(
      {required this.fetch,
      this.cancelFetch,
      this.interval = const Duration(seconds: 5)}) {
    final state = WidgetsBinding.instance.lifecycleState;
    _active = state == null ||
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    WidgetsBinding.instance.addObserver(this);
  }
  final Future<void> Function(RefreshTicket) fetch;
  final VoidCallback? cancelFetch;
  final Duration interval;
  Timer? _next;
  Future<void>? _inFlight;
  bool _active = true, _disposed = false;
  int _generation = 0;

  Future<void> refresh() {
    if (_disposed || !_active) return Future.value();
    if (_inFlight != null) return _inFlight!;
    _next?.cancel();
    final completion = Completer<void>();
    _inFlight = completion.future;
    unawaited(_run(_generation, completion));
    return completion.future;
  }

  Future<void> _run(int generation, Completer<void> completion) async {
    try {
      await fetch(RefreshTicket._(
          () => !_disposed && _active && generation == _generation));
      completion.complete();
    } catch (error, stack) {
      completion.completeError(error, stack);
    } finally {
      _inFlight = null;
      if (!_disposed && _active) {
        if (generation != _generation) {
          unawaited(refresh());
        } else {
          _next = Timer(interval, () => unawaited(refresh()));
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Notification shade, permissions and desktop focus changes are not sleep.
    if (state == AppLifecycleState.inactive) return;
    final active = state == AppLifecycleState.resumed;
    if (active == _active) return;
    _active = active;
    _generation++;
    _next?.cancel();
    if (!_active) cancelFetch?.call();
    if (_active) unawaited(refresh());
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _next?.cancel();
    cancelFetch?.call();
    WidgetsBinding.instance.removeObserver(this);
  }
}
