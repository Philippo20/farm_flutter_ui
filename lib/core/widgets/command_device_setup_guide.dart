import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/superadmin_api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_dialog.dart';
import 'crop_variety_modal_frame.dart';

String commandDeviceSetupText(String serial) =>
    '''COMMAND DEVICE — ESP32 / ARDUINO

Serial: $serial
API: ${SuperAdminApiService.baseUrl}

1. Register this board as a Command Device. Configure names and exact values such as Start pump → PUMP_START. The firmware must explicitly recognise those values.

2. Use HTTPS and the farm-specific sensor key in the x-sensor-key header. Keep the key inside the board configuration; never place it in a public URL or share it with users.

3. Generate a new session_id (8–64 letters, numbers, hyphens or underscores) on every boot. Start sequence at 0. Only one board should use this serial.

4. Poll every 2 seconds:
POST /command-devices/$serial/poll
{"session_id":"board-boot-unique-id","sequence":0}

No pending command returns command: null. If advance_sequence is true, increment sequence and poll again without executing anything.

5. A pending response includes command.id, command.value, command.sequence and valid_for_ms. Execute only recognised values within the remaining time, once per command ID. Use the value as data; never evaluate it as source code. Account for request time before execution.

6. Report the result:
POST /command-devices/$serial/ack
{"session_id":"board-boot-unique-id","sequence":0,"command_id":"UUID_FROM_POLL","success":true,"message":"Pump started"}

Use success: false with a clear message when execution fails. After an accepted acknowledgement, increment sequence. If the acknowledgement response is lost, retry the same result; do not execute again. A later poll with advance_sequence: true also means the slot is resolved.

The board is offline after 4 seconds without a successful poll. Commands expire after 10 seconds. Old commands are discarded on board restart, expiry or configuration changes. The app shows Confirmed only after the board acknowledges success.
''';

Future<void> showCommandDeviceSetupGuide(BuildContext context, String serial) =>
    showAppDialog(context: context, builder: (_) => _Guide(serial: serial));

class _Guide extends StatefulWidget {
  const _Guide({required this.serial});
  final String serial;
  @override
  State<_Guide> createState() => _GuideState();
}

class _GuideState extends State<_Guide> {
  String? _message;
  bool _copying = false;
  Future<void> _copy() async {
    setState(() => _copying = true);
    try {
      await Clipboard.setData(
          ClipboardData(text: commandDeviceSetupText(widget.serial)));
      if (mounted) setState(() => _message = 'Setup guide copied.');
    } catch (_) {
      if (mounted) {
        setState(
            () => _message = 'Unable to copy. Select the guide text instead.');
      }
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mobile = MediaQuery.sizeOf(context).width < 600 ||
        Theme.of(context).platform == TargetPlatform.android;
    return CropVarietyModalFrame(
        mobile: mobile,
        isDark: Theme.of(context).brightness == Brightness.dark,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Row(children: [
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xff15803d)]),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.terminal_rounded,
                        size: 20, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Command device setup',
                          style: AppTypography.font(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Board connection and acknowledgements',
                          style: AppTypography.font(fontSize: 12))
                    ])),
                IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 16)),
              ])),
          Flexible(
              child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SelectableText(commandDeviceSetupText(widget.serial),
                            style: AppTypography.font(
                                fontSize: 12, color: colors.onSurface)),
                        if (_message != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text(_message!,
                                  style: AppTypography.font(fontSize: 12))),
                      ]))),
          Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: Text('Close',
                            style: AppTypography.font(fontSize: 13)))),
                const SizedBox(width: 12),
                Expanded(
                    child: FilledButton(
                        onPressed: _copying ? null : _copy,
                        style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: Text(_copying ? 'Copying…' : 'Copy guide',
                            textAlign: TextAlign.center,
                            style: AppTypography.font(
                                fontSize: 13, color: Colors.white)))),
              ])),
        ]));
  }
}
