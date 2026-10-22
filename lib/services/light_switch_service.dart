import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'api_session_context.dart';
import 'auth_service.dart';
import 'superadmin_api_service.dart';

class LightSwitchService {
  LightSwitchService(
      {http.Client? client,
      String? Function()? token,
      Future<void> Function()? refresh})
      : _client = client ?? http.Client(),
        _token = token ?? (() => AuthService().jwt),
        _refresh = refresh ??
            (() async {
              await AuthService().refreshSession();
            });
  final http.Client _client;
  final String? Function() _token;
  final Future<void> Function() _refresh;
  final _pollAborts = <Completer<void>>{};
  int _generation = 0;
  bool _disposed = false;
  void cancelPolling() {
    _generation++;
    for (final abort in _pollAborts.toList()) {
      if (!abort.isCompleted) abort.complete();
    }
  }

  void dispose() {
    _disposed = true;
    cancelPolling();
    _client.close();
  }

  String requestId() {
    final bytes = List.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<Map<String, dynamic>> state(String serial) => _request(serial, null);
  Future<Map<String, dynamic>> command(
          String serial, bool on, String requestId) =>
      _request(serial, {'desired_on': on, 'request_id': requestId});
  Future<Map<String, dynamic>> _request(
      String serial, Map<String, dynamic>? data,
      {bool retried = false, int? generation}) async {
    if (_disposed) throw StateError('Light service has been disposed.');
    generation ??= _generation;
    if (generation != null && generation != _generation)
      throw http.RequestAbortedException();
    final token = _token();
    if (token == null) throw Exception('Please sign in to control lights.');
    final uri = Uri.parse(
        '${SuperAdminApiService.baseUrl}/switches/${Uri.encodeComponent(serial)}/${data == null ? 'state' : 'commands'}');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache',
      if (ApiSessionContext.role != null)
        'X-Active-Role': ApiSessionContext.role!,
    };
    final abort = Completer<void>();
    if (data == null) _pollAborts.add(abort);
    var timedOut = false;
    final timeout = Timer(const Duration(seconds: 8), () {
      timedOut = true;
      if (!abort.isCompleted) abort.complete();
    });
    late http.Response response;
    try {
      final request = http.AbortableRequest(data == null ? 'GET' : 'POST', uri,
          abortTrigger: abort.future)
        ..headers.addAll(headers);
      if (data != null) request.body = jsonEncode(data);
      response = await http.Response.fromStream(await _client.send(request));
    } on http.RequestAbortedException {
      if (!timedOut) rethrow;
      throw TimeoutException('Unable to refresh light status.');
    } finally {
      timeout.cancel();
      _pollAborts.remove(abort);
    }
    if (response.statusCode == 401 && !retried) {
      await _refresh();
      return _request(serial, data, retried: true, generation: generation);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message =
          'Unable to reach light controls (${response.statusCode}).';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded['detail'] is String) message = decoded['detail'];
      } catch (_) {}
      throw Exception(message);
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }
}
