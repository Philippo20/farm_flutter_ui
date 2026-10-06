import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_notifier/local_notifier.dart';

/// Delivery only. The authenticated host owns polling and session checks.
class LocalAlerts {
  static final instance = LocalAlerts();
  static const channel = MethodChannel('farmestates/message_notifications');
  final _desktop = <String, LocalNotification>{};
  Future<void>? _setup;
  bool get _android => defaultTargetPlatform == TargetPlatform.android;
  bool get _supportedDesktop => const [
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux
      ].contains(defaultTargetPlatform);

  Future<bool> requestPermission() async {
    try {
      if (_android) {
        await channel.invokeMethod<void>('requestPermission');
        return true;
      }
      if (!_supportedDesktop) return false;
      await (_setup ??= localNotifier.setup(
          appName: 'Farm Estates',
          shortcutPolicy: ShortcutPolicy.requireCreate));
      return true;
    } catch (_) {
      _setup = null;
      return false;
    }
  }

  Future<bool> show(
      {required String id,
      required String user,
      required String title,
      required String body,
      required VoidCallback onTap,
      bool silent = false}) async {
    try {
      if (_android) {
        return await channel.invokeMethod<bool>('show', {
              'peerId': id,
              'recipientId': user,
              'title': title,
              'body': body,
              'silent': silent,
            }) ??
            false;
      }
      if (!await requestPermission()) return false;
      await dismiss(id);
      final alert = LocalNotification(
          identifier: id, title: title, body: body, silent: silent);
      _desktop[id] = alert;
      alert.onClick = () async {
        if (defaultTargetPlatform == TargetPlatform.windows) {
          try {
            await const MethodChannel('farmestates/notification_window')
                .invokeMethod<void>('show');
          } catch (_) {/* The inbox remains available if activation fails. */}
        }
        onTap();
      };
      await alert.show();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> dismiss(String id) async {
    try {
      if (_android) {
        await channel.invokeMethod<void>('dismiss', {'peerId': id});
      } else {
        await _desktop.remove(id)?.destroy();
      }
    } catch (_) {/* OS delivery must not interrupt the inbox. */}
  }

  Future<void> clear() async {
    if (_android) {
      try {
        await channel.invokeMethod<void>('clear');
      } catch (_) {}
    }
    for (final id in _desktop.keys.toList()) {
      await dismiss(id);
    }
  }
}
