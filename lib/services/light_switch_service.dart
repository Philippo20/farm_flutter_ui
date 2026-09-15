import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'api_connection.dart';
import 'auth_service.dart';
import 'superadmin_api_service.dart';

class LightSwitchService {
  LightSwitchService({http.Client? client})
      : _client = client ?? ConnectedApiClient();
  final http.Client _client;
  void dispose() => _client.close();
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
      {bool retried = false}) async {
    final token = AuthService().jwt;
    if (token == null) throw Exception('Please sign in to control lights.');
    final uri = Uri.parse(
        '${SuperAdminApiService.baseUrl}/switches/${Uri.encodeComponent(serial)}/${data == null ? 'state' : 'commands'}');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache'
    };
    final response = await (data == null
            ? _client.get(uri, headers: headers)
            : _client.post(uri, headers: headers, body: jsonEncode(data)))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 401 && !retried) {
      await AuthService().refreshSession();
      return _request(serial, data, retried: true);
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
