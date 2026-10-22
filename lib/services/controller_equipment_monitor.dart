import 'dart:async';
import 'package:flutter/widgets.dart';
import 'command_device_service.dart';
import 'device_presence.dart';

const controllerOutputs = {
  'grow_light': {
    'lights.E': 'Light E',
    'lights.F': 'Light F',
    'lights.P': 'Light P'
  },
  'feeding_pump': {'fertigation.pump_on': 'Fertigation pump (D12)'},
  'drainage_pump': {
    'drainage.ef.pump_on': 'Shared E/F drainage (D11)',
    'drainage.p.pump_on': 'P drainage (D10)'
  },
};
String equipmentTypeLabel(String type) => switch (type) {
      'grow_light' => 'Grow light',
      'feeding_pump' => 'Feeding pump',
      'drainage_pump' => 'Drainage pump',
      _ => 'Air conditioner',
    };

/// One adaptive request for all displayed equipment. Presence comes from board
/// polling, never from event delivery or a successful cached API response.
class ControllerEquipmentMonitor extends ChangeNotifier
    with WidgetsBindingObserver {
  ControllerEquipmentMonitor(
      {CommandDeviceService? service,
      int Function()? elapsedMilliseconds,
      this.presenceOnly = false})
      : _service = service ?? CommandDeviceService(),
        _elapsedMilliseconds = elapsedMilliseconds {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _active = lifecycle == null ||
        lifecycle == AppLifecycleState.resumed ||
        lifecycle == AppLifecycleState.inactive;
    WidgetsBinding.instance.addObserver(this);
  }
  final CommandDeviceService _service;
  final bool presenceOnly;
  final int Function()? _elapsedMilliseconds;
  final _clock = Stopwatch()..start();
  int get _elapsed =>
      _elapsedMilliseconds?.call() ?? _clock.elapsedMilliseconds;
  final states = <String, Map<String, dynamic>>{};
  final _received = <String, int>{};
  final _presence = <String, DevicePresence>{};
  final _bindings = <String, String>{};
  List<String> _ids = [];
  String _links = '';
  final _deviceLinks = <String, String>{};
  Timer? _next, _expiry;
  bool _active = true, _disposed = false, _fetching = false;
  int _generation = 0;
  String? error;

  void setDevices(Iterable<Map<String, dynamic>> devices) {
    final ids = devices
        .where((d) => controllerOutputs.containsKey(d['sensortype']))
        .map((d) => '${d[r'$id']}')
        .toSet()
        .toList()
      ..sort();
    final links = devices
        .where((d) => ids.contains('${d[r'$id']}'))
        .map((d) =>
            '${d[r'$id']}:${d['controller_id']}:${d['controller_output']}')
        .toList()
      ..sort();
    if (links.join('|') == _links) return;
    _links = links.join('|');
    _ids = ids;
    final nextLinks = {
      for (final d in devices.where((d) => ids.contains('${d[r'$id']}')))
        '${d[r'$id']}': '${d['controller_id']}:${d['controller_output']}'
    };
    states.removeWhere((id, _) => _deviceLinks[id] != nextLinks[id]);
    _deviceLinks
      ..clear()
      ..addAll(nextLinks);
    _bindings.removeWhere((id, _) => !states.containsKey(id));
    _presence.removeWhere((key, _) => !_bindings.values.contains(key));
    _generation++;
    _next?.cancel();
    _service.cancelPolling();
    _poll();
  }

  bool online(String id) {
    final state = states[id];
    if (!_active || state == null) return false;
    return _presence[_bindings[id]]?.online(_elapsed) == true;
  }

  bool fresh(String id) {
    final state = states[id];
    final received = DateTime.tryParse('${state?['received_at']}');
    final server = DateTime.tryParse('${state?['server_time']}');
    return online(id) &&
        received != null &&
        server != null &&
        server.difference(received).inMilliseconds +
                _elapsed -
                (_received[id] ?? 0) <=
            65000;
  }

  String label(String id) {
    if (!states.containsKey(id)) {
      return error == null ? 'Awaiting report' : 'Status unavailable';
    }
    if (!online(id)) {
      return error == null ? 'Controller offline' : 'Status unavailable';
    }
    if (!fresh(id) || states[id]?['reported_on'] is! bool) {
      return 'Awaiting report';
    }
    return states[id]!['reported_on'] == true ? 'ON' : 'OFF';
  }

  Future<void> _poll() async {
    if (_disposed || !_active || _fetching || _ids.isEmpty) return;
    _fetching = true;
    final generation = _generation;
    try {
      // Bound request size to the API limit without stacking requests.
      final collected = <Map<String, dynamic>>[];
      for (var i = 0; i < _ids.length; i += 100) {
        final result = await _service.equipment(_ids.skip(i).take(100).toList(),
            presenceOnly: presenceOnly);
        collected.addAll(
            List<Map<String, dynamic>>.from(result['equipment'] as List));
      }
      if (_disposed || generation != _generation) return;
      for (final state in collected) {
        final id = '${state['device_id']}';
        final key = '${state['controller_id'] ?? id}';
        if (_bindings[id] != null && _bindings[id] != key) states.remove(id);
        _bindings[id] = key;
        (_presence[key] ??= DevicePresence()).accept(state, _elapsed);
        states[id] = state;
        _received[id] = _elapsed;
      }
      final returned = collected.map((s) => '${s['device_id']}').toSet();
      states.removeWhere((id, _) => !returned.contains(id));
      error = null;
    } catch (e) {
      if (!_disposed && generation == _generation) error = '$e';
    } finally {
      _fetching = false;
      if (!_disposed && _active) {
        notifyListeners();
        _scheduleExpiry();
        _next?.cancel();
        if (generation != _generation) {
          unawaited(_poll());
        } else {
          _next = Timer(const Duration(seconds: 2), _poll);
        }
      }
    }
  }

  void _scheduleExpiry() {
    _expiry?.cancel();
    if (_disposed || !_active) return;
    final deadlines = _presence.values
        .map((p) => p.expiresIn(_elapsed))
        .whereType<int>()
        .toList()
      ..sort();
    if (deadlines.isEmpty) return;
    _expiry = Timer(Duration(milliseconds: deadlines.first), () {
      if (_disposed || !_active) return;
      notifyListeners();
      _scheduleExpiry();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) return;
    final active = state == AppLifecycleState.resumed;
    if (active == _active) return;
    _active = active;
    _generation++;
    _next?.cancel();
    _expiry?.cancel();
    _expiry = null;
    if (!_active) {
      for (final presence in _presence.values) {
        presence.reset();
      }
    }
    _service.cancelPolling();
    if (_active) _poll();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _next?.cancel();
    _expiry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _service.dispose();
    _clock.stop();
    super.dispose();
  }
}
