// Local browser delivery: no push subscription or Firebase project is required.
import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('Notification')
extension type _BrowserNotification._(JSObject _) implements JSObject {
  external factory _BrowserNotification(JSString title, JSObject options);
  external static JSString get permission;
  external static JSPromise<JSString> requestPermission();
  external set onclick(JSFunction listener);
  external void close();
}

class LocalAlerts {
  static final instance = LocalAlerts();
  final _alerts = <String, _BrowserNotification>{};

  /// Invoke directly from the notification center's enable button.
  Future<bool> requestPermission() async {
    try {
      return (await _BrowserNotification.requestPermission().toDart).toDart ==
          'granted';
    } catch (_) {
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
      if (_BrowserNotification.permission.toDart != 'granted') return false;
      await dismiss(id);
      final alert = _BrowserNotification(
          title.toJS,
          {'body': body, 'tag': '$user:$id', 'silent': silent}.jsify()!
              as JSObject);
      _alerts[id] = alert;
      alert.onclick = ((JSAny? _) {
        alert.close();
        onTap();
      }).toJS;
      return true;
    } catch (_) {
      // Insecure origins and unsupported/mobile browsers retain the in-app inbox.
      return false;
    }
  }

  Future<void> dismiss(String id) async {
    _alerts.remove(id)?.close();
  }

  Future<void> clear() async {
    for (final alert in _alerts.values) {
      alert.close();
    }
    _alerts.clear();
  }
}
