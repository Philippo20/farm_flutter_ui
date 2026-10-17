import 'dart:async';
import 'package:flutter/foundation.dart';

/// Serial HTTP polling with a receipt-based heartbeat grace period.
///
/// [fetch] must finish (including aborting its transport on timeout) before the
/// next request is scheduled. Errors preserve presence until the grace expires.
/// For proxied devices, [sourceHeartbeat] prevents the same cached device
/// heartbeat from keeping a disconnected board online indefinitely.
class HeartbeatPoller<T> extends ChangeNotifier {
  HeartbeatPoller({
    required this.fetch,
    this.isHeartbeat,
    this.sourceHeartbeat,
    this.cancelFetch,
    this.interval = const Duration(seconds: 2),
    this.gracePeriod = const Duration(milliseconds: 5500),
  })  : assert(interval > Duration.zero),
        assert(gracePeriod > Duration.zero);

  final Future<T> Function() fetch;
  final bool Function(T)? isHeartbeat;
  final DateTime? Function(T)? sourceHeartbeat;
  final VoidCallback? cancelFetch;
  final Duration interval, gracePeriod;
  Timer? _nextPoll, _graceTimer;
  Future<void>? _inFlight;
  T? _data;
  Object? _lastError;
  DateTime? _lastSourceHeartbeat;
  bool _running = false, _online = false, _disposed = false;
  bool _hasCompleted = false;
  int _generation = 0;

  T? get data => _data;
  Object? get lastError => _lastError;
  bool get isOnline => _online;
  bool get isPolling => _running;
  bool get isFetching => _inFlight != null;
  bool get hasCompleted => _hasCompleted;

  void startPolling() {
    if (_disposed || _running) return;
    _running = true;
    _generation++;
    notifyListeners();
    unawaited(refresh());
  }

  /// Synchronously clears presence and invalidates every outstanding response.
  void stopPolling() {
    if (_disposed) return;
    _running = false;
    _online = false;
    _generation++;
    _nextPoll?.cancel();
    _graceTimer?.cancel();
    _lastSourceHeartbeat = null;
    cancelFetch?.call();
    notifyListeners();
  }

  /// Use when switching device/configuration; an old response cannot leak in.
  void reset() {
    stopPolling();
    _data = null;
    _lastError = null;
    _hasCompleted = false;
    if (!_disposed) notifyListeners();
  }

  /// A manual refresh joins the current request instead of stacking another.
  Future<void> refresh() {
    if (_disposed || !_running) return Future.value();
    if (_inFlight != null) return _inFlight!;
    _nextPoll?.cancel();
    final generation = _generation;
    // Assign before invoking fetch, including a synchronously throwing fetch.
    final completion = Completer<void>();
    _inFlight = completion.future;
    unawaited(_fetch(generation, completion));
    return completion.future;
  }

  Future<void> _fetch(int generation, Completer<void> completion) async {
    try {
      final result = await fetch();
      if (_active(generation)) _accept(result);
    } catch (error) {
      if (_active(generation)) {
        _lastError = error;
        _hasCompleted = true;
        // A single failed/delayed request does not clear a healthy heartbeat.
        notifyListeners();
      }
    } finally {
      _inFlight = null;
      completion.complete();
      if (!_disposed && _running) {
        // A stop/start waits for the old transport to finish before restarting.
        _nextPoll = Timer(interval, () => unawaited(refresh()));
      }
    }
  }

  bool _active(int generation) =>
      !_disposed && _running && generation == _generation;

  /// Adopt a successful command response without an older GET overwriting it.
  void acceptData(T value) {
    if (_disposed || !_running) return;
    _generation++;
    _nextPoll?.cancel();
    _accept(value);
    if (_inFlight == null) {
      _nextPoll = Timer(interval, () => unawaited(refresh()));
    }
  }

  void _accept(T value) {
    var heartbeat = isHeartbeat?.call(value) ?? true;
    final source = sourceHeartbeat?.call(value);
    if (sourceHeartbeat != null) {
      heartbeat = heartbeat &&
          source != null &&
          (_lastSourceHeartbeat == null ||
              source.isAfter(_lastSourceHeartbeat!));
    }
    _data = value;
    _lastError = null;
    _hasCompleted = true;
    if (heartbeat) {
      _lastSourceHeartbeat = source;
      _online = true;
      _graceTimer?.cancel();
      _graceTimer = Timer(gracePeriod, () {
        if (!_disposed && _running && _online) {
          _online = false;
          notifyListeners();
        }
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _running = false;
    _online = false;
    _generation++;
    _nextPoll?.cancel();
    _graceTimer?.cancel();
    cancelFetch?.call();
    super.dispose();
  }
}
