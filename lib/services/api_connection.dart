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

  Future<void> failed(Future<bool> Function() probe,
      {bool submission = false}) {
    _probe = probe;
    unavailable = true;
    submissionInterrupted |= submission;
    _recovery ??= Completer<void>();
    notifyListeners();
    return _recovery!.future;
  }

  Future<void> retry() async {
    if (checking || _probe == null) return;
    checking = true;
    notifyListeners();
    try {
      if (await _probe!()) {
        unavailable = false;
        submissionInterrupted = false;
        final recovery = _recovery;
        _recovery = null;
        recovery?.complete();
      }
    } catch (_) {
      // Keep the same connection panel until the service responds.
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
      }, submission: !read);
      if (!read) throw http.ClientException(connectionMessage, url);
      await recovered;
      attempt = http.Request(method, url)..headers.addAll(headers);
    }
  }

  @override
  void close() => _inner.close();
}
