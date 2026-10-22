/// A successful, advancing controller heartbeat earns one complete grace window
/// from receipt. Cached packets and failed/stale requests cannot renew it.
class DevicePresence {
  DevicePresence({this.grace = const Duration(milliseconds: 5500)});
  final Duration grace;
  DateTime? _source;
  String? _session;
  int? _received;

  bool online(int elapsed) =>
      _received != null && elapsed - _received! < grace.inMilliseconds;
  int? expiresIn(int elapsed) =>
      online(elapsed) ? grace.inMilliseconds - (elapsed - _received!) : null;

  void accept(Map<String, dynamic> data, int elapsed) {
    final session =
        (data['controller_session_id'] ?? data['session_id'])?.toString();
    if (_session != null && session != null && _session != session) reset();
    _session = session ?? _session;
    if (data['enabled'] == false) {
      reset();
      return;
    }
    final source = DateTime.tryParse('${data['seen_at']}');
    if (data['online'] == true &&
        source != null &&
        (_source == null || source.isAfter(_source!))) {
      _source = source;
      _received = elapsed;
    }
  }

  void reset() {
    _source = null;
    _session = null;
    _received = null;
  }
}
