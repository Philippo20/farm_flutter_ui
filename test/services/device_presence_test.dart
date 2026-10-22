import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/services/device_presence.dart';

Map<String, dynamic> packet(int second,
        {bool online = true, String session = 'boot-one'}) =>
    {
      'online': online,
      'seen_at': DateTime.utc(2026, 10, 22, 12, 0, second).toIso8601String(),
      'controller_session_id': session,
    };

void main() {
  test('a packet gets the complete 5.5 second grace from receipt', () {
    final presence = DevicePresence();
    presence
        .accept({...packet(0), 'server_time': '2026-10-22T12:00:05Z'}, 1000);
    expect(presence.online(6499), true);
    expect(presence.online(6500), false);
  });
  test('duplicate cached packets and offline packets cannot renew grace', () {
    final presence = DevicePresence();
    presence.accept(packet(0), 0);
    presence.accept(packet(0), 2000);
    presence.accept(packet(4, online: false), 4000);
    expect(presence.online(5000), true);
    presence.accept(packet(0), 5500);
    expect(presence.online(5500), false);
    presence.accept(packet(6), 6000);
    expect(presence.online(6000), true);
  });
  test('a reboot or disabled controller cannot inherit stale presence', () {
    final presence = DevicePresence();
    presence.accept(packet(10), 0);
    presence.accept(packet(1, online: false, session: 'boot-two'), 2000);
    expect(presence.online(2000), false);
    presence.accept(packet(2, session: 'boot-two'), 3000);
    expect(presence.online(3000), true);
    presence
        .accept({...packet(3, session: 'boot-two'), 'enabled': false}, 4000);
    expect(presence.online(4000), false);
  });
}
