import 'device_presence.dart';

/// Separates the board's heartbeat from the app's ability to refresh its view.
/// A missed UI refresh is unknown, not proof that the board disconnected.
class ControllerPresence {
  // A proxy refresh can take eight seconds, followed by the two-second poll
  // delay. Allow that round trip plus jitter without changing the board's
  // server-enforced 5.5-second heartbeat deadline. Only advancing heartbeats
  // renew this bounded observation window; cached replies never do.
  static const observationWindow = Duration(seconds: 12);
  final _lease = DevicePresence(grace: observationWindow);
  DateTime? _sample, _source;
  String? _session;
  bool confirmedOffline = false;
  bool advanced = false, invalidated = false;

  bool online(int elapsed) => _lease.online(elapsed);
  int? expiresIn(int elapsed) => _lease.expiresIn(elapsed);

  /// Rejects out-of-order API observations before they can replace device data.
  bool accept(Map<String, dynamic> data, int elapsed) {
    advanced = invalidated = false;
    final sample = DateTime.tryParse('${data['server_time']}');
    if (_sample != null && sample != null && sample.isBefore(_sample!)) {
      return false;
    }
    final session = data['controller_session_id']?.toString();
    final source = DateTime.tryParse('${data['seen_at']}');
    final reboot = _session != null && session != null && session != _session;
    if (reboot) {
      _lease.reset();
      _source = null;
      invalidated = true;
    }
    _sample = sample ?? _sample;
    _session = session ?? _session;
    final disabled = data['enabled'] == false;
    advanced = !disabled &&
        data['online'] == true &&
        source != null &&
        (_source == null || source.isAfter(_source!));
    if (advanced) _source = source;
    final age = data['heartbeat_age_ms'] is num
        ? (data['heartbeat_age_ms'] as num).toDouble()
        : sample != null && source != null
            ? sample.difference(source).inMilliseconds.toDouble()
            : null;
    // Only a successful server observation can confirm an expired board
    // heartbeat. API errors and local timers must never fabricate that result.
    confirmedOffline = disabled ||
        (sample != null &&
            data['online'] == false &&
            (source == null || (age != null && age > 5500)));
    invalidated = invalidated || confirmedOffline;
    if (confirmedOffline) {
      _lease.reset();
    } else {
      _lease.accept(data, elapsed);
    }
    return true;
  }

  void reset() {
    _lease.reset();
    _sample = _source = null;
    _session = null;
    confirmedOffline = advanced = invalidated = false;
  }
}
