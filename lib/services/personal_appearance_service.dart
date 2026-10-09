import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/typography_preferences.dart';
import 'api_connection.dart';
import 'auth_service.dart';
import 'superadmin_api_service.dart';

class PersonalAppearanceService {
  PersonalAppearanceService(this.userId, {http.Client? client})
      : _client = client ?? ConnectedApiClient();
  final String userId;
  final http.Client _client;
  Map<String, String> get _headers {
    final auth = AuthService();
    if (auth.currentUser?.id != userId || auth.jwt == null) {
      throw Exception('Please sign in again to change your text sizes.');
    }
    return {
      'Authorization': 'Bearer ${auth.jwt}',
      'Content-Type': 'application/json'
    };
  }

  Uri get _uri => Uri.parse('${SuperAdminApiService.baseUrl}/me/appearance');
  Future<TypographyPreferences> load() async =>
      _decode(await _client.get(_uri, headers: _headers));
  Future<TypographyPreferences> save(TypographyPreferences value) async =>
      _decode(await _client.put(_uri,
          headers: _headers, body: jsonEncode(value.toJson())));
  TypographyPreferences _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Could not ${response.request?.method == 'PUT' ? 'save' : 'load'} your text sizes. Please try again.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['typography'] is! Map) {
      throw Exception('Invalid text-size settings response. Please try again.');
    }
    return TypographyPreferences.fromJson(
        Map<String, dynamic>.from(decoded['typography'] as Map));
  }

  void dispose() => _client.close();
}
