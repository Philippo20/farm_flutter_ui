import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'superadmin_api_service.dart';

/// Android transport only. Windows and web retain the existing local delivery.
class AndroidPushRegistration {
  static const channel = MethodChannel('farmestates/message_notifications');
  final http.Client _client;
  AndroidPushRegistration({http.Client? client, String? Function()? jwt})
      : _client = client ?? http.Client(),
        _jwt = jwt ?? (() => AuthService().jwt);
  final String? Function() _jwt;
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  String? _user, _token, _registeredUser, _registeredJwt;
  int _generation = 0;
  DateTime? _lastRegistration;
  bool _syncing = false;
  bool _disposed = false;
  Future<void> _cleanup = Future.value();

  void bind(String? user) {
    if (!supported || _disposed) return;
    _user = user;
    _generation++;
    _lastRegistration = null;
    // Suppress deliveries for the previous user immediately, even while offline.
    unawaited(channel.invokeMethod(
        'pushRecipient', {'recipientId': user ?? ''}).catchError((_) {}));
    if (user == null && _token != null && _registeredJwt != null) {
      final token = _token!;
      final jwt = _registeredJwt!;
      _cleanup = _cleanup.then((_) => _remove(token, jwt));
    }
  }

  Future<void> _remove(String token, String jwt) async {
    try {
      await _client
          .delete(Uri.parse('${SuperAdminApiService.baseUrl}/push/devices'),
              headers: {
                'Authorization': 'Bearer $jwt',
                'Content-Type': 'application/json'
              },
              body: jsonEncode({'token': token}))
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      /* Local recipient filtering also protects signed-out devices. */
    }
  }

  Future<void> sync() async {
    if (!supported || _disposed || _syncing || _user == null) return;
    _syncing = true;
    final generation = _generation;
    final user = _user;
    final jwt = _jwt();
    try {
      if (jwt == null) return;
      await _cleanup;
      if (_disposed || generation != _generation) return;
      final token = await channel.invokeMethod<String>('pushToken');
      if (_disposed ||
          generation != _generation ||
          token == null ||
          token.isEmpty) {
        return;
      }
      if (_token == token &&
          _registeredUser == user &&
          _lastRegistration != null &&
          DateTime.now().difference(_lastRegistration!) <
              const Duration(minutes: 5)) {
        return;
      }
      final response = await _client
          .post(Uri.parse('${SuperAdminApiService.baseUrl}/push/devices'),
              headers: {
                'Authorization': 'Bearer $jwt',
                'Content-Type': 'application/json'
              },
              body: jsonEncode({'token': token}))
          .timeout(const Duration(seconds: 10));
      if (_disposed || generation != _generation) {
        await _remove(token, jwt);
        return;
      }
      if (response.statusCode == 200) {
        final oldToken = _token;
        final oldJwt = _registeredJwt;
        _token = token;
        _registeredUser = user;
        _registeredJwt = jwt;
        _lastRegistration = DateTime.now();
        if (oldToken != null && oldToken != token && oldJwt != null) {
          await _remove(oldToken, oldJwt);
        }
      }
    } catch (_) {
      /* Retry on a later foreground poll/resume; inbox stays usable. */
    } finally {
      _syncing = false;
    }
  }

  Future<Set<String>> delivered() async {
    if (!supported || _disposed) return {};
    try {
      return (await channel.invokeListMethod<String>('pushDelivered') ?? [])
          .toSet();
    } catch (_) {
      return {};
    }
  }

  void dispose() {
    _disposed = true;
    _client.close();
  }
}
