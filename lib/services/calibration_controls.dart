/// Protocol values verified against the registered controller commands.
/// Command IDs always come from the current API configuration, never this file.
class CalibrationCommands {
  CalibrationCommands(List<Map<String, String>> commands)
      : _commands = commands;
  final List<Map<String, String>> _commands;
  static const selectionValues = {'EF_D_SELECT', 'P_D_SELECT', 'FERT_D_SELECT'};
  List<Map<String, String>> get selections =>
      _commands.where((c) => selectionValues.contains(c['value'])).toList();
  Map<String, String>? action(String name) {
    final value = {
      'start': 'CAL_START',
      'stop': 'CAL_STOP',
      'cancel': 'CAL_CANCEL'
    }[name];
    return _commands.where((c) => c['value'] == value).firstOrNull;
  }
}

enum CalibrationStage { selection, selecting, ready, running }

String? calibrationCommandAction(String? value) => switch (value) {
      'EF_D_SELECT' || 'P_D_SELECT' || 'FERT_D_SELECT' => 'select',
      'CAL_START' => 'start',
      'CAL_STOP' => 'stop',
      'CAL_CANCEL' => 'cancel',
      _ => null,
    };

CalibrationStage calibrationStage(Map? session) {
  if (session == null) return CalibrationStage.selection;
  var status = session['status'];
  if (status == 'rejected') {
    final event = session['latest_event'] as Map? ?? session['event'] as Map?;
    if (event?['reason'] == 'no_calibration_selected') {
      return CalibrationStage.selection;
    }
    final previous = session['last_progress'] as Map?;
    status = '${previous?['type'] ?? ''}'.split('.').last;
    if (status == 'request_received') return CalibrationStage.selection;
  }
  return switch (status) {
    'request_received' => CalibrationStage.selecting,
    'waiting_for_start' => CalibrationStage.ready,
    'starting' || 'running' => CalibrationStage.running,
    _ => CalibrationStage.selection,
  };
}
