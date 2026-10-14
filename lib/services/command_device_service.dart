import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'api_connection.dart';
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
      : _client = client ?? ConnectedApiClient(),
        _token = token ?? (() => AuthService().jwt),
        _refresh = refresh ??
            (() async {
              await AuthService().refreshSession();
            });
  final http.Client _client;
  final String? Function() _token;
  final Future<void> Function() _refresh;
  void dispose() => _client.close();
  Future<Map<String, dynamic>> state(String serial) => _request(serial);
  Future<Map<String, dynamic>> send(
          String serial, String commandKey, String requestId,
          {String? revision}) =>
      _request(serial, data: {
        'command_key': commandKey,
        'request_id': requestId,
        if (revision != null) 'config_revision': revision
      });
  Future<Map<String, dynamic>> _request(String serial,
      {Map<String, String>? data, bool retried = false}) async {
    final jwt = _token();
    if (jwt == null) {
      throw const SuperAdminApiException(
          'Please sign in to use device commands.');
    }
    final uri = Uri.parse(
        '${SuperAdminApiService.baseUrl}/command-devices/${Uri.encodeComponent(serial)}/${data == null ? 'state' : 'commands'}');
    final headers = {
      'Authorization': 'Bearer $jwt',
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache'
    };
    final response = await (data == null
            ? _client.get(uri, headers: headers)
            : _client.post(uri, headers: headers, body: jsonEncode(data)))
        .timeout(const Duration(seconds: 8),
            onTimeout: () => throw const SuperAdminApiException(
                'Unable to reach device controls. Refresh the device before retrying.'));
    if (response.statusCode == 401 && !retried) {
      await _refresh();
      return _request(serial, data: data, retried: true);
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
