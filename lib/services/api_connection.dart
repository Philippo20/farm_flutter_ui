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
    // Give Android's network transport time to resume after unlocking.
    _resumeRetry = Timer(const Duration(seconds: 2), () {
      _resuming = false;
      if (_recovery != null) retry();
    });
  }

  @override
  void dispose() {
    _resumeRetry?.cancel();
    super.dispose();
  }

  Future<void> failed(Future<bool> Function() probe,
      {bool submission = false, int? requestEpoch}) {
    _probe = probe;
    final interrupted = !foreground ||
        _resuming ||
        (requestEpoch != null && requestEpoch != lifecycleEpoch);
    unavailable = !interrupted;
    if (interrupted && foreground) _scheduleResumeRetry();
    submissionInterrupted |= submission;
    _recovery ??= Completer<void>();
    notifyListeners();
    return _recovery!.future;
  }

  Future<void> retry() async {
    if (checking || _probe == null || !foreground) return;
    final epoch = lifecycleEpoch;
    checking = true;
    notifyListeners();
    try {
      final reachable = await _probe!();
      if (epoch != lifecycleEpoch || !foreground) return;
      if (reachable) {
        unavailable = false;
        submissionInterrupted = false;
        final recovery = _recovery;
        _recovery = null;
        recovery?.complete();
      } else {
        unavailable = true;
      }
    } catch (_) {
      if (foreground && epoch == lifecycleEpoch) unavailable = true;
    } finally {
      checking = false;
      notifyListeners();
    }
  }
}

/// One bounded transport for every role. Only reads can be replayed.
class ConnectedApiClient extends http.BaseClient {
  ConnectedApiClient(
      {http.Client? inner,
      ApiConnection? connection,
      this.timeout = const Duration(seconds: 8)})
      : _inner = inner ?? http.Client(),
        connection = connection ?? ApiConnection.instance;
  final http.Client _inner;
  final ApiConnection connection;
  final Duration timeout;

  Future<http.Response> _perform(http.BaseRequest request) =>
      (() async => http.Response.fromStream(await _inner.send(request)))()
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
        if (response.statusCode >= 500) {
          throw http.ClientException(connectionMessage, url);
        }
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
        final result = await _perform(probe);
        return result.statusCode < 500;
      }, submission: !read, requestEpoch: requestEpoch);
      if (!read) throw http.ClientException(connectionMessage, url);
      await recovered;
      attempt = http.Request(method, url)..headers.addAll(headers);
    }
  }

  @override
  void close() => _inner.close();
}
