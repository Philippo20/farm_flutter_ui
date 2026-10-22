import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/services/controller_presence.dart';

Map<String, dynamic> observation(int server, int? seen,
        {bool online = true, String boot = 'boot-one'}) =>
    {
      'online': online,
      'server_time':
          DateTime.utc(2026, 10, 22, 12, 0, server).toIso8601String(),
      'seen_at': seen == null
          ? null
          : DateTime.utc(2026, 10, 22, 12, 0, seen).toIso8601String(),
      'controller_session_id': boot,
    };

void main() {
  test('UI silence expires live status without inventing controller offline',
      () {
    final presence = ControllerPresence();
    presence.accept(observation(0, 0), 0);
    expect(presence.online(5499), true);
    expect(presence.online(5500), false);
    expect(presence.confirmedOffline, false);
    presence.accept(observation(6, 6), 6000);
    expect(presence.online(6000), true);
  });

  test('only server-confirmed board timeout can report offline', () {
    final presence = ControllerPresence();
    presence.accept(observation(0, 0), 0);
    presence.accept(observation(2, 0, online: false), 2000);
    expect(presence.confirmedOffline, false);
    presence.accept(observation(6, 0, online: false), 3000);
    expect(presence.online(3000), false);
    expect(presence.confirmedOffline, true);
    presence.accept(observation(7, 7), 7000);
    expect(presence.confirmedOffline, false);
    expect(presence.online(7000), true);
  });

  test('old observations cannot regress output state or resurrect an old boot',
      () {
    final presence = ControllerPresence();
    presence.accept(observation(8, 8, boot: 'boot-two'), 0);
    expect(presence.accept(observation(6, 0, online: false), 2000), false);
    expect(presence.online(2000), true);
    expect(presence.confirmedOffline, false);
    expect(presence.accept(observation(9, 1, boot: 'boot-three'), 3000), true);
    expect(presence.invalidated, true);
    expect(presence.advanced, true);
  });

  test('cached frames cannot renew presence, and resume requires a new check',
      () {
    final presence = ControllerPresence();
    presence.accept(observation(0, 0), 0);
    presence.accept(observation(0, 0), 4000);
    expect(presence.online(5500), false);
    expect(presence.confirmedOffline, false);
    presence.reset();
    expect(presence.online(5500), false);
    expect(presence.confirmedOffline, false);
    presence.accept(observation(10, null, online: false), 6000);
    expect(presence.confirmedOffline, true);
  });
}
