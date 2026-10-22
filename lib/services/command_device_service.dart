import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'api_session_context.dart';
import 'auth_service.dart';
import 'superadmin_api_service.dart';

String newCommandId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

List<Map<String, String>> deviceNamedCommands(dynamic raw) {
  try {
    final data = raw is String ? jsonDecode(raw) : raw;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => {
              for (final key in ['id', 'label', 'value'])
                key: '${item[key] ?? ''}'
            })
        .where((item) => item['id']!.isNotEmpty)
        .toList();
  } catch (_) {
    return [];
  }
}

class CommandDeviceService {
  CommandDeviceService(
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
  bool _disposed = false;
  int _pollGeneration = 0;
  void cancelPolling() {
    _pollGeneration++;
    for (final abort in _pollAborts.toList()) {
      if (!abort.isCompleted) abort.complete();
    }
  }

  void dispose() {
    _disposed = true;
    cancelPolling();
    _client.close();
  }

  Future<Map<String, dynamic>> state(String serial) => _request(serial);
  Future<Map<String, dynamic>> activity(String serial) =>
      _request(serial, resource: 'activity');
  Future<Map<String, dynamic>> activityHistory(String serial,
          {String? before}) =>
      _request(serial,
          resource: 'activity/events',
          query: {if (before != null) 'before': before});
  Future<Map<String, dynamic>> equipment(List<String> ids,
          {bool presenceOnly = false}) =>
      _request('',
          path: '/controller-equipment',
          query: {'device_id': ids, if (presenceOnly) 'presence_only': 'true'});
  Future<Map<String, dynamic>> calibrations(String serial) =>
      _request(serial, resource: 'calibrations');
  Future<Map<String, dynamic>> calibrationHistory(String serial,
          {String? before}) =>
      _request(serial,
          resource: 'calibrations/events',
          query: {if (before != null) 'before': before});
  Future<Map<String, dynamic>> send(
          String serial, String commandKey, String requestId,
          {String? revision}) =>
      _request(serial, data: {
        'command_key': commandKey,
        'request_id': requestId,
        if (revision != null) 'config_revision': revision
      });
  Future<Map<String, dynamic>> _request(String serial,
      {Map<String, String>? data,
      bool retried = false,
      int? pollGeneration,
      String? resource,
      Map<String, dynamic>? query,
      String? path}) async {
    if (_disposed) throw StateError('Device service has been disposed.');
    if (data == null) pollGeneration ??= _pollGeneration;
    if (pollGeneration != null && pollGeneration != _pollGeneration) {
      throw http.RequestAbortedException();
    }
    final jwt = _token();
    if (jwt == null) {
      throw const SuperAdminApiException(
          'Please sign in to use device commands.');
    }
    final uri = Uri.parse(
            '${SuperAdminApiService.baseUrl}${path ?? '/command-devices/${Uri.encodeComponent(serial)}/${resource ?? (data == null ? 'state' : 'commands')}'}')
        .replace(queryParameters: query);
    final headers = {
      'Authorization': 'Bearer $jwt',
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache',
      if (ApiSessionContext.role != null)
        'X-Active-Role': ApiSessionContext.role!,
    };
    final abort = Completer<void>();
    if (data == null) _pollAborts.add(abort);
    var timedOut = false;
    final timer = Timer(const Duration(seconds: 8), () {
      timedOut = true;
      if (!abort.isCompleted) abort.complete();
    });
    late http.Response response;
    try {
      final request = http.AbortableRequest(data == null ? 'GET' : 'POST', uri,
          abortTrigger: abort.future)
        ..headers.addAll(headers);
      if (data != null) request.body = jsonEncode(data);
      // Await the aborted transport too: a Future.timeout alone would leave
      // the old HTTP request running when the next heartbeat request starts.
      response = await http.Response.fromStream(await _client.send(request));
    } on http.RequestAbortedException {
      if (!timedOut) rethrow;
      throw const SuperAdminApiException(
          'Unable to reach device controls. Refresh the device before retrying.');
    } finally {
      timer.cancel();
      _pollAborts.remove(abort);
    }
    if (response.statusCode == 401 && !retried) {
      await _refresh();
      return _request(serial,
          data: data,
          retried: true,
          pollGeneration: pollGeneration,
          resource: resource,
          path: path,
          query: query);
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {/* HTTP errors can contain HTML from a proxy. */}
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(decoded is Map && decoded['detail'] is String
          ? decoded['detail'] as String
          : 'Unable to load device commands (${response.statusCode}).');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid command device response.');
    }
    return decoded;
  }
}
