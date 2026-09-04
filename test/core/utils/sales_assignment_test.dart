import 'package:farmestates_ai_dashbaord/core/utils/sales_assignment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final identity = salesUserIdentity(
    id: 'sales-person-1',
    email: 'PERSON@FARM.TEST',
    name: 'Ama Sales',
  );

  test('matches a delivery assigned by user document id', () {
    expect(
      isSaleAssignedToIdentity(
        {'sales_person_id': 'sales-person-1', 'created_by': 'manager-1'},
        identity,
      ),
      isTrue,
    );
  });

  test('matches assignment values without case sensitivity', () {
    expect(
      isSaleAssignedToIdentity(
        {'sales_person_name': 'AMA SALES'},
        identity,
      ),
      isTrue,
    );
  });

  test('supports legacy records owned through created_by', () {
    expect(
      isSaleAssignedToIdentity(
        {'created_by': 'person@farm.test'},
        identity,
      ),
      isTrue,
    );
  });

  test('does not expose another personnel assignment', () {
    expect(
      isSaleAssignedToIdentity(
        {
          'sales_person_id': 'sales-person-2',
          'created_by': 'person@farm.test',
        },
        identity,
      ),
      isFalse,
    );
  });
}
