import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/utils/farm_team_assignment.dart';

void main() {
  const manager = {
    'id': 'auth-1',
    'email': 'manager@example.com',
    'name': 'Jane Manager'
  };
  const users = [
    {
      r'$id': 'profile-1',
      'email': 'manager@example.com',
      'name': 'Jane Manager'
    }
  ];
  bool matches(Map<String, dynamic> farm) =>
      isManagerTeamFarm(farm, manager: manager, users: users);

  test('matches manager assignment aliases, lists and embedded references', () {
    for (final key in farmTeamAssignmentKeys['Farm Manager']!) {
      expect(matches({key: 'profile-1'}), isTrue, reason: key);
    }
    expect(matches({'farm_manager_id': 'auth-1'}), isTrue);
    expect(matches({'farmManagerEmail': ' MANAGER@EXAMPLE.COM '}), isTrue);
    expect(
        matches({
          'assignedManagers': [
            {'id': 'profile-1'},
            'other'
          ]
        }),
        isTrue);
  });

  test('excludes other managers, unassigned farms and signed-out users', () {
    expect(matches({'farm_manager_id': 'other'}), isFalse);
    expect(matches({'farm_manager_id': 'Unassigned'}), isFalse);
    expect(matches({}), isFalse);
    expect(
        isManagerTeamFarm({'farm_manager_id': 'auth-1'},
            manager: null, users: users),
        isFalse);
  });

  test('legacy user farm assignment does not override another manager', () {
    const legacy = {'id': 'auth-1', 'farmID': 'farm-1'};
    expect(isManagerTeamFarm({'id': 'farm-1'}, manager: legacy, users: users),
        isTrue);
    expect(
        isManagerTeamFarm({'id': 'farm-1', 'farm_manager_id': 'other'},
            manager: legacy, users: users),
        isFalse);
    expect(isManagerTeamFarm({'id': 'farm-2'}, manager: legacy, users: users),
        isFalse);
  });

  test('resolves staff references without placeholder or duplicate tokens', () {
    expect(
        assignmentReferences([
          ' TECH-1 ',
          {'id': 'tech-1', 'email': 'TECH@EXAMPLE.COM'},
          'Unassigned',
          'system',
          null
        ]),
        {'tech-1', 'tech@example.com'});
    expect(farmTeamAssignmentKeys['Technician'], contains('technicianId'));
    expect(farmTeamAssignmentKeys['Farm Owner'], contains('owner_id'));
  });
}
