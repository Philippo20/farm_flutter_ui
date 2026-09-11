import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_connection.dart';
import 'auth_service.dart';
import 'superadmin_api_service.dart';

class EmailSettingsService {
  Future<Map<String, dynamic>> _request(String method, String path,
      [Map<String, dynamic>? data]) async {
    final client = ConnectedApiClient();
    try {
      final request = http.Request(method,
          Uri.parse('${SuperAdminApiService.baseUrl}/system-config/email$path'))
        ..headers.addAll({
          'Authorization': 'Bearer ${AuthService().jwt ?? ''}',
          'Content-Type': 'application/json'
        });
      if (data != null) request.body = jsonEncode(data);
      final response =
          await http.Response.fromStream(await client.send(request))
              .timeout(const Duration(seconds: 30));
      final decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = decoded is Map ? decoded['detail'] : null;
        throw Exception(detail is String
            ? detail
            : 'Unable to update email settings. Check the field values and try again.');
      }
      return Map<String, dynamic>.from(decoded);
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> load() async =>
      Map<String, dynamic>.from((await _request('GET', ''))['config']);
  Future<Map<String, dynamic>> save(Map<String, dynamic> settings) async =>
      Map<String, dynamic>.from(
          (await _request('PUT', '', settings))['config']);
  Future<String> sendTest(String recipient) async =>
      (await _request('POST', '/test', {'recipient': recipient}))['message']
          as String;
}
