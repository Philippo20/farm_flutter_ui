import 'maintenance_changes.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_connection.dart';
import 'auth_service.dart';
import 'superadmin_api_service.dart';

class DeviceMaintenanceApi {
  DeviceMaintenanceApi({http.Client? client})
      : _client = client ?? ConnectedApiClient();
  final http.Client _client;
  void dispose() => _client.close();
  Future<Map<String, dynamic>> request(String method, String path,
      [Map<String, dynamic>? data]) async {
    final uri =
        Uri.parse('${SuperAdminApiService.baseUrl}/device-maintenance$path');
    final headers = {
      'Authorization': 'Bearer ${AuthService().jwt ?? ''}',
      'Content-Type': 'application/json'
    };
    final response = method == 'GET'
        ? await _client.get(uri, headers: headers)
        : method == 'PUT'
            ? await _client.put(uri, headers: headers, body: jsonEncode(data))
            : await _client.post(uri, headers: headers, body: jsonEncode(data));
    final body = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(body is Map && body['detail'] is String
          ? body['detail']
          : 'Unable to save maintenance. Check the fields and try again.');
    }
    return Map<String, dynamic>.from(body as Map);
  }

  Future<Map<String, dynamic>> options() => request('GET', '/options');
  Future<Map<String, dynamic>> overview() => request('GET', '/overview');
  Future<void> saveDevice(Map<String, dynamic> data, {String? id}) async {
    await request(id == null ? 'POST' : 'PUT',
        id == null ? '/devices' : '/devices/${Uri.encodeComponent(id)}', data);
  }

  Future<void> complete(
      Map<String, dynamic> task, Map<String, dynamic> data) async {
    await request(
        'POST',
        '/devices/${Uri.encodeComponent(task['device_id'])}/plans/${Uri.encodeComponent(task['plan_id'])}/complete',
        data);
    notifyMaintenanceChanged();
  }
}
