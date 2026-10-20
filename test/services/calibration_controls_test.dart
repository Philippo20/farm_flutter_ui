import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/services/calibration_controls.dart';

void main() {
  test('uses configured IDs for exact database protocol values', () {
    final commands = CalibrationCommands([
      {'id': 'select-ef', 'value': 'EF_D_SELECT'},
      {'id': 'select-p', 'value': 'P_D_SELECT'},
      {'id': 'select-fert', 'value': 'FERT_D_SELECT'},
      {'id': 'start-custom-id', 'value': 'CAL_START'},
      {'id': 'stop-custom-id', 'value': 'CAL_STOP'},
      {'id': 'cancel-custom-id', 'value': 'CAL_CANCEL'},
      {'id': 'unrelated', 'value': 'PUMP_START'},
    ]);
    expect(commands.selections.map((c) => c['id']),
        ['select-ef', 'select-p', 'select-fert']);
    expect(commands.action('start')?['id'], 'start-custom-id');
    expect(commands.action('stop')?['id'], 'stop-custom-id');
    expect(commands.action('cancel')?['id'], 'cancel-custom-id');
    expect(CalibrationCommands([]).action('start'), isNull);
  });
  test(
      'rejected start retains ready controls and terminal results return to selection',
      () {
    expect(
        calibrationStage({
          'status': 'rejected',
          'last_progress': {'type': 'calibration.waiting_for_start'}
        }),
        CalibrationStage.ready);
    expect(
        calibrationStage({
          'status': 'rejected',
          'latest_event': {'reason': 'no_calibration_selected'},
          'last_progress': {'type': 'calibration.waiting_for_start'}
        }),
        CalibrationStage.selection);
    expect(calibrationStage({'status': 'starting'}), CalibrationStage.running);
    for (final status in ['cancelled', 'completed', 'not_saved']) {
      expect(calibrationStage({'status': status}), CalibrationStage.selection);
    }
  });
}
