import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'superadmin_api_service.dart';

class MessagingService {
  MessagingService(
      {http.Client? client, String? baseUrl, String? Function()? token})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? SuperAdminApiService.baseUrl,
        _token = token ?? (() => AuthService().jwt);
  final http.Client _client;
  final String _baseUrl;
  final String? Function() _token;

  Future<dynamic> _request(String method, String path,
      [Map<String, dynamic>? data]) async {
    final token = _token();
    if (token == null || token.isEmpty)
      throw Exception('Please sign in to use messages.');
    final request = http.Request(method, Uri.parse('$_baseUrl/messages$path'))
      ..headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      });
    if (data != null) request.body = jsonEncode(data);
    final response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 20)));
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = body is Map ? body['detail'] : null;
      throw Exception(detail is String
          ? detail
          : 'Messages are unavailable. Please try again.');
    }
    return body;
  }

  Future<List<Map<String, dynamic>>> conversations() async {
    final data = await _request('GET', '/conversations');
    return List<Map<String, dynamic>>.from(data['conversations']);
  }

  Future<List<Map<String, dynamic>>> messages(String peer) async {
    final data =
        await _request('GET', '/conversations/${Uri.encodeComponent(peer)}');
    return List<Map<String, dynamic>>.from(data['messages']);
  }

  Future<Map<String, dynamic>> send(
          String peer, String text, String requestId) async =>
      Map<String, dynamic>.from(await _request(
          'POST',
          '/conversations/${Uri.encodeComponent(peer)}',
          {'text': text, 'request_id': requestId}));
  Future<void> markRead(String peer, List<String> ids) async {
    for (var offset = 0; offset < ids.length; offset += 100) {
      await _request('POST', '/conversations/${Uri.encodeComponent(peer)}/read',
          {'message_ids': ids.skip(offset).take(100).toList()});
    }
  }

  void dispose() => _client.close();
}
