import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const connectionMessage =
    'Unable to reach Farm Estates. Check your internet connection and try again.';

class ApiConnection extends ChangeNotifier {
  static final instance = ApiConnection();
  bool unavailable = false;
  bool checking = false;
  bool submissionInterrupted = false;
  Future<bool> Function()? _probe;
  Completer<void>? _recovery;

  bool foreground = true;
  bool _resuming = false;
  int lifecycleEpoch = 0;
  Completer<void>? _resume;
  Timer? _resumeRetry;
  bool _disposed = false;
  Future<void> get whenForeground => _resume?.future ?? Future.value();

  void setForeground(bool value) {
    if (foreground == value) return;
    foreground = value;
    lifecycleEpoch++;
    _resumeRetry?.cancel();
    unavailable = false;
    if (!value) {
      _resume ??= Completer<void>();
    } else {
      _resume?.complete();
      _resume = null;
      _resuming = true;
      _scheduleResumeRetry();
    }
    notifyListeners();
  }

  void _scheduleResumeRetry() {
    _resumeRetry?.cancel();
    // Let the device's network transport settle after unlocking or resuming.
    _resumeRetry = Timer(const Duration(seconds: 2), () {
      _resuming = false;
      if (_recovery != null) retry();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _resumeRetry?.cancel();
    super.dispose();
  }

  Future<void> failed(Future<bool> Function() probe,
      {bool submission = false, int? requestEpoch}) {
    _probe = probe;
    final interrupted = !foreground ||
        _resuming ||
        (requestEpoch != null && requestEpoch != lifecycleEpoch);
    // Confirm failures quietly before replacing the current screen.
    if (interrupted) unavailable = false;
    if (interrupted && foreground) _scheduleResumeRetry();
    submissionInterrupted |= submission;
    _recovery ??= Completer<void>();
    if (!interrupted) _scheduleProbe(Duration.zero);
    notifyListeners();
    return _recovery!.future;
  }

  void _scheduleProbe(Duration delay) {
    _resumeRetry?.cancel();
    if (_disposed || !foreground) return;
    _resumeRetry = Timer(delay, () {
      if (!_disposed) retry();
    });
  }

  void succeeded(int epoch) {
    if (_disposed || !foreground || epoch != lifecycleEpoch) return;
    if (_recovery == null && !unavailable) return;
    _resumeRetry?.cancel();
    _resuming = false;
    unavailable = false;
    submissionInterrupted = false;
    final recovery = _recovery;
    _recovery = null;
    recovery?.complete();
    notifyListeners();
  }

  Future<void> retry() async {
    if (_disposed || checking || _probe == null || !foreground) return;
    _resumeRetry?.cancel();
    final epoch = lifecycleEpoch;
    checking = true;
    notifyListeners();
    try {
      final reachable = await _probe!();
      if (_disposed ||
          epoch != lifecycleEpoch ||
          !foreground ||
          _recovery == null) {
        return;
      }
      if (reachable) {
        succeeded(epoch);
      } else {
        unavailable = true;
      }
    } catch (_) {
      if (!_disposed &&
          foreground &&
          epoch == lifecycleEpoch &&
          _recovery != null) {
        unavailable = true;
      }
    } finally {
      checking = false;
      if (!_disposed) {
        if (_recovery != null && foreground) {
          _scheduleProbe(const Duration(seconds: 5));
        }
        notifyListeners();
      }
    }
  }
}

/// One bounded transport for every role. Only reads can be replayed.
class ConnectedApiClient extends http.BaseClient {
  ConnectedApiClient(
      {http.Client? inner,
      ApiConnection? connection,
      this.timeout = const Duration(seconds: 8)})
      : _ownsInner = inner == null,
        _inner = inner ?? http.Client(),
        connection = connection ?? ApiConnection.instance;
  final bool _ownsInner;
  final http.Client _inner;
  final ApiConnection connection;
  final Duration timeout;

  Future<http.Response> _perform(http.BaseRequest request,
          {http.Client? client}) =>
      (() async => http.Response.fromStream(
              await (client ?? _inner).send(request)))()
          .timeout(timeout);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final read = request.method == 'GET' || request.method == 'HEAD';
    final method = request.method;
    final url = request.url;
    final headers = Map<String, String>.from(request.headers);
    var attempt = request;
    while (true) {
      await connection.whenForeground;
      final requestEpoch = connection.lifecycleEpoch;
      try {
        final response = await _perform(attempt);
        // An HTTP error still proves the server is reachable. Let the caller
        // display its endpoint-specific error without declaring the app offline.
        connection.succeeded(requestEpoch);
        return http.StreamedResponse(
            Stream.value(response.bodyBytes), response.statusCode,
            headers: response.headers,
            contentLength: response.bodyBytes.length,
            reasonPhrase: response.reasonPhrase,
            request: response.request,
            isRedirect: response.isRedirect,
            persistentConnection: response.persistentConnection);
      } on TimeoutException {
        // The request timed out, including while receiving its body.
      } on http.ClientException {
        // Browser fetch failures and native connection failures arrive here.
      }
      final recovered = connection.failed(() async {
        final probe =
            http.Request(read ? method : 'GET', read ? url : url.resolve('/'))
              ..headers.addAll(headers);
        // Recovery must not depend on a closed or stale caller-owned transport.
        final transport = _ownsInner ? http.Client() : _inner;
        try {
          final result = await _perform(probe, client: transport);
          return result.statusCode >= 100;
        } finally {
          if (_ownsInner) transport.close();
        }
      }, submission: !read, requestEpoch: requestEpoch);
      if (!read) throw http.ClientException(connectionMessage, url);
      await recovered;
      attempt = http.Request(method, url)..headers.addAll(headers);
    }
  }

  @override
  void close() => _inner.close();
}
