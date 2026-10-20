import 'api_session_context.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const connectionMessage =
    'Farm Estates is temporarily unreachable. We’re reconnecting automatically. If this continues, check your connection and try again.';
const requestTimeoutMessage =
    'This request is taking longer than expected. Please try again.';

class ApiConnection extends ChangeNotifier {
  ApiConnection({
    this.gracePeriod = const Duration(seconds: 12),
    this.retryInterval = const Duration(seconds: 3),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  static final instance = ApiConnection();
  final Duration gracePeriod, retryInterval;
  final DateTime Function() _now;
  bool unavailable = false;
  bool checking = false;
  bool submissionInterrupted = false;
  Future<bool> Function()? _probe;
  Completer<void>? _recovery;

  bool foreground = true;
  bool _resuming = false;
  int lifecycleEpoch = 0;
  Completer<void>? _resume;
  Timer? _resumeTimer, _probeTimer;
  DateTime? _failureSince;
  int _failedProbes = 0, _generation = 0;
  bool _disposed = false;
  Future<void> get whenForeground => _resume?.future ?? Future.value();

  void setForeground(bool value) {
    if (_disposed) return;
    if (foreground == value) return;
    foreground = value;
    lifecycleEpoch++;
    _generation++;
    _resumeTimer?.cancel();
    _probeTimer?.cancel();
    _probeTimer = null;
    _failureSince = null;
    _failedProbes = 0;
    unavailable = false;
    _resuming = false;
    if (!value) {
      _resume ??= Completer<void>();
    } else {
      _resume?.complete();
      _resume = null;
      _resuming = true;
      // One settling window per resume; failures cannot keep extending it.
      _resumeTimer = Timer(const Duration(seconds: 2), () {
        _resuming = false;
        if (_recovery != null) _scheduleProbe(Duration.zero);
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _resumeTimer?.cancel();
    _probeTimer?.cancel();
    _resume?.complete();
    _resume = null;
    super.dispose();
  }

  Future<void> failed(Future<bool> Function() probe,
      {bool submission = false, int? requestEpoch}) {
    if (_disposed) return Future.value();
    _probe = probe;
    final interrupted = !foreground ||
        _resuming ||
        (requestEpoch != null && requestEpoch != lifecycleEpoch);
    // Confirm failures quietly before replacing the current screen.
    submissionInterrupted |= submission;
    _recovery ??= Completer<void>();
    if (foreground && !_resuming && !checking && _probeTimer == null) {
      _scheduleProbe(interrupted ? const Duration(seconds: 2) : Duration.zero);
    }
    notifyListeners();
    return _recovery!.future;
  }

  void _scheduleProbe(Duration delay) {
    _probeTimer?.cancel();
    _probeTimer = null;
    if (_disposed || !foreground || _resuming) return;
    _probeTimer = Timer(delay, () {
      _probeTimer = null;
      if (!_disposed) retry();
    });
  }

  void succeeded(int epoch) {
    if (_disposed || !foreground || epoch != lifecycleEpoch) return;
    if (_recovery == null && !unavailable) return;
    _generation++;
    _probeTimer?.cancel();
    _probeTimer = null;
    _failureSince = null;
    _failedProbes = 0;
    unavailable = false;
    submissionInterrupted = false;
    final recovery = _recovery;
    _recovery = null;
    recovery?.complete();
    notifyListeners();
  }

  Future<void> retry() async {
    if (_disposed ||
        checking ||
        _probe == null ||
        !foreground ||
        _resuming ||
        _recovery == null) {
      return;
    }
    _probeTimer?.cancel();
    _probeTimer = null;
    final epoch = lifecycleEpoch;
    final generation = _generation;
    final recovery = _recovery;
    final probe = _probe!;
    _failureSince ??= _now();
    checking = true;
    notifyListeners();
    try {
      final reachable = await probe();
      if (_disposed ||
          epoch != lifecycleEpoch ||
          !foreground ||
          generation != _generation ||
          !identical(recovery, _recovery)) {
        return;
      }
      if (reachable) {
        succeeded(epoch);
      } else {
        _recordFailedProbe();
      }
    } catch (_) {
      if (!_disposed &&
          foreground &&
          epoch == lifecycleEpoch &&
          generation == _generation &&
          identical(recovery, _recovery)) {
        _recordFailedProbe();
      }
    } finally {
      checking = false;
      if (!_disposed) {
        if (_recovery != null && foreground) {
          _scheduleProbe(retryInterval);
        }
        notifyListeners();
      }
    }
  }

  void _recordFailedProbe() {
    _failedProbes++;
    // A single timeout, or several simultaneous screen requests, is not an
    // outage. Only sequential health failures across this window can show it.
    unavailable =
        _failedProbes >= 2 && _now().difference(_failureSince!) >= gracePeriod;
  }
}

/// One bounded transport for every role. Only reads can be replayed.
class ConnectedApiClient extends http.BaseClient {
  ConnectedApiClient(
      {http.Client? inner,
      ApiConnection? connection,
      this.timeout = const Duration(seconds: 20)})
      : _ownsInner = inner == null,
        _inner = inner ?? http.Client(),
        connection = connection ?? ApiConnection.instance;
  final bool _ownsInner;
  final http.Client _inner;
  final ApiConnection connection;
  final Duration timeout;
  bool _closed = false;

  Future<http.Response> _perform(http.BaseRequest request,
      {http.Client? client, Duration? limit}) async {
    final abort = Completer<void>();
    final wrapped = _AbortableApiRequest(request, abort.future);
    try {
      return await (() async => http.Response.fromStream(
              await (client ?? _inner).send(wrapped)))()
          .timeout(limit ?? timeout, onTimeout: () {
        // Cancel the HTTP operation too, including a stalled response body.
        abort.complete();
        throw TimeoutException('API request timed out', limit ?? timeout);
      });
    } finally {
      if (!abort.isCompleted) abort.complete();
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.origin == ApiSessionContext.origin &&
        ApiSessionContext.jwt != null) {
      request.headers.putIfAbsent(
          'Authorization', () => 'Bearer ${ApiSessionContext.jwt}');
      if (ApiSessionContext.role != null &&
          request.headers['Authorization'] ==
              'Bearer ${ApiSessionContext.jwt}' &&
          !request.url.path.startsWith('/account/')) {
        request.headers
            .putIfAbsent('X-Active-Role', () => ApiSessionContext.role!);
      }
    }
    final read = request.method == 'GET' || request.method == 'HEAD';
    final method = request.method;
    final url = request.url;
    final headers = Map<String, String>.from(request.headers);
    var attempt = request;
    var attempts = 0;
    while (true) {
      await connection.whenForeground;
      if (_closed) throw http.ClientException('Client is closed.', url);
      attempts++;
      final requestEpoch = connection.lifecycleEpoch;
      try {
        final response = await _perform(attempt);
        // An HTTP error still proves the server is reachable. Let the caller
        // display its endpoint-specific error without declaring the app offline.
        if (url.origin == ApiSessionContext.origin) {
          connection.succeeded(requestEpoch);
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
      } on http.RequestAbortedException {
        rethrow;
      } on http.ClientException {
        // Browser fetch failures and native connection failures arrive here.
      }
      if (_closed) throw http.ClientException('Client is closed.', url);
      if (url.origin != ApiSessionContext.origin) {
        throw http.ClientException(requestTimeoutMessage, url);
      }
      final recovered = connection.failed(() async {
        // No database work, authentication, or replay of the failed endpoint.
        final probe = http.Request('GET', url.resolve('/health'))
          ..headers['Cache-Control'] = 'no-cache';
        // Recovery must not depend on a closed or stale caller-owned transport.
        final transport = _ownsInner ? http.Client() : _inner;
        try {
          final result = await _perform(probe,
              client: transport, limit: const Duration(seconds: 5));
          return result.statusCode >= 100;
        } finally {
          if (_ownsInner) transport.close();
        }
      }, submission: !read, requestEpoch: requestEpoch);
      if (!read) throw http.ClientException(connectionMessage, url);
      // One quiet retry is enough when health is fine but this endpoint is slow.
      // Never loop forever, stacking requests against an overloaded endpoint.
      if (attempts >= 2) throw http.ClientException(requestTimeoutMessage, url);
      await recovered;
      attempt = http.Request(method, url)..headers.addAll(headers);
    }
  }

  @override
  void close() {
    _closed = true;
    _inner.close();
  }
}

/// Preserve streamed/multipart bodies and caller cancellation while adding a
/// transport deadline. Multipart headers are populated during finalization.
class _AbortableApiRequest extends http.BaseRequest with http.Abortable {
  _AbortableApiRequest(this.original, Future<void> deadline)
      : abortTrigger =
            original is http.Abortable && original.abortTrigger != null
                ? Future.any([deadline, original.abortTrigger!])
                : deadline,
        super(original.method, original.url) {
    headers.addAll(original.headers);
    contentLength = original.contentLength;
    followRedirects = original.followRedirects;
    maxRedirects = original.maxRedirects;
    persistentConnection = original.persistentConnection;
  }
  final http.BaseRequest original;
  @override
  final Future<void> abortTrigger;
  @override
  http.ByteStream finalize() {
    final body = original.finalize();
    headers.addAll(original.headers);
    super.finalize();
    return body;
  }
}
