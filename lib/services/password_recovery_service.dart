import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_connection.dart';
import 'superadmin_api_service.dart';

class PasswordRecoveryService {
  PasswordRecoveryService({http.Client? client})
      : _client = client ?? ConnectedApiClient();
  final http.Client _client;
  Future<void> request(String email) async {
    final response = await _client.post(
        Uri.parse('${SuperAdminApiService.baseUrl}/account/recovery'),
        body: {'email': email}).timeout(const Duration(seconds: 30));
    _check(response);
  }

  Future<void> reset(String userId, String secret, String password) async {
    final response = await _client
        .post(
            Uri.parse(
                '${SuperAdminApiService.baseUrl}/account/recovery/confirm'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
                {'user_id': userId, 'secret': secret, 'password': password}))
        .timeout(const Duration(seconds: 30));
    _check(response);
  }

  void _check(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {}
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        (data is Map && data.containsKey('error'))) {
      final detail = data is Map ? data['detail'] : null;
      throw Exception(detail is String
          ? detail
          : 'Unable to complete password recovery. Please try again.');
    }
  }

  void close() => _client.close();
}
