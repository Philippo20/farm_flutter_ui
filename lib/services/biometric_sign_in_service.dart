import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BiometricSignInStatus {
  const BiometricSignInStatus(
      {this.available = false, this.enabled = false, this.email});
  final bool available;
  final bool enabled;
  final String? email;
}

class BiometricCredentials {
  const BiometricCredentials(this.email, this.password);
  final String email;
  final String password;
}

/// Android owns both the biometric prompt and the per-use Keystore encryption.
/// Credentials are never saved in Flutter preferences or reused as a local login.
class BiometricSignInService {
  const BiometricSignInService();
  static const _channel = MethodChannel('farmestates/biometric_signin');
  bool get supportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<BiometricSignInStatus> status() async {
    if (!supportedPlatform) return const BiometricSignInStatus();
    try {
      final data = await _channel.invokeMapMethod<String, dynamic>('status');
      return BiometricSignInStatus(
          available: data?['available'] == true,
          enabled: data?['enabled'] == true,
          email: data?['email'] as String?);
    } on PlatformException {
      return const BiometricSignInStatus();
    } on MissingPluginException {
      return const BiometricSignInStatus();
    }
  }

  Future<bool> enable(String email, String password) async {
    if (!supportedPlatform) return false;
    return await _channel.invokeMethod<bool>(
            'enable', {'email': email, 'password': password}) ==
        true;
  }

  Future<BiometricCredentials?> unlock() async {
    if (!supportedPlatform) return null;
    final data = await _channel.invokeMapMethod<String, dynamic>('credentials');
    if (data == null) return null; // Native cancel / use-password action.
    final email = data['email'] as String?;
    final password = data['password'] as String?;
    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      throw PlatformException(
          code: 'invalidated',
          message: 'Sign in with your password to set up fingerprint again.');
    }
    return BiometricCredentials(email, password);
  }

  Future<void> disable() async {
    if (supportedPlatform) await _channel.invokeMethod<void>('disable');
  }
}

final biometricSignInProvider =
    Provider<BiometricSignInService>((ref) => const BiometricSignInService());
