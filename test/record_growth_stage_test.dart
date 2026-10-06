import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/utils/production_plan.dart';

void main() {
  const plan = {
    'stages': [
      {'name': 'Sprouting', 'days': 7},
      {'name': 'Leaf Development', 'days': 14},
      {'name': 'Harvest stage', 'days': 7}
    ]
  };
  test('Start day, inclusive stages and transitions use calendar dates', () {
    for (final pair in [
      (1, 'Sprouting'),
      (7, 'Sprouting'),
      (8, 'Leaf Development'),
      (21, 'Leaf Development'),
      (22, 'Harvest stage'),
      (29, 'Harvest stage')
    ]) {
      expect(
          recordGrowthStage(plan, '2026-10-01', DateTime(2026, 10, pair.$1))
              .name,
          pair.$2);
    }
  });
  test('Earlier record dates use historical stage, not today', () {
    expect(recordGrowthStage(plan, '2026-10-01', DateTime(2026, 10, 3)).name,
        'Sprouting');
  });
  test('Missing plan and future start never invent a stage', () {
    expect(recordGrowthStage(null, '2026-10-01', DateTime(2026, 10, 2)).name,
        isNull);
    expect(recordGrowthStage(plan, null, DateTime(2026, 10, 2)).invalidDate,
        isTrue);
    expect(
        recordGrowthStage(plan, '2026-10-10', DateTime(2026, 10, 2))
            .invalidDate,
        isTrue);
  });
}
