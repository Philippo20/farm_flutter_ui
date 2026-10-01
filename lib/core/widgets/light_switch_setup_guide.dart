import '../theme/app_typography.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_dialog.dart';
import 'package:flutter/services.dart';
import '../../services/superadmin_api_service.dart';

Future<void> showLightSwitchSetupGuide(BuildContext context, String serial) =>
    showAppDialog<void>(
        context: context,
        builder: (_) => _LightSwitchSetupGuide(serial: serial));

class _LightSwitchSetupGuide extends StatefulWidget {
  const _LightSwitchSetupGuide({required this.serial});
  final String serial;
  @override
  State<_LightSwitchSetupGuide> createState() => _LightSwitchSetupGuideState();
}

class _LightSwitchSetupGuideState extends State<_LightSwitchSetupGuide> {
  String? _copyMessage;
  Future<void> _copy() async {
    try {
      await Clipboard.setData(
          ClipboardData(text: lightSwitchSetupText(widget.serial)));
      if (mounted) setState(() => _copyMessage = 'Setup guide copied.');
    } catch (_) {
      if (mounted)
        setState(() => _copyMessage =
            'Unable to copy. You can select the guide text instead.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.surfaceDark : Colors.white;
    final foreground = dark ? Colors.white : AppColors.textPrimary;
    final secondary = dark ? Colors.white70 : AppColors.textSecondary;
    final buttons = ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
        textStyle: WidgetStatePropertyAll(AppTypography.font(
            fontSize: AppTypography.actionSize,
            fontWeight: AppTypography.labelWeight)),
        padding:
            const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    return PopScope(
        canPop: true,
        child: AppDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
                height: MediaQuery.sizeOf(context).height * .9,
                constraints: BoxConstraints(
                    maxWidth: 500,
                    maxHeight: MediaQuery.sizeOf(context).height * .9),
                decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color:
                              Colors.black.withValues(alpha: dark ? .35 : .12),
                          blurRadius: 24,
                          offset: const Offset(0, 12))
                    ]),
                child: Material(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                          child: Row(children: [
                            Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [
                                      AppColors.primary,
                                      Color(0xff15803d)
                                    ]),
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.menu_book_outlined,
                                    size: 20, color: Colors.white)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('Switch setup guide',
                                      style: AppTypography.font(
                                          fontSize: AppTypography.cardTitleSize,
                                          fontWeight: FontWeight.bold,
                                          color: foreground)),
                                  const SizedBox(height: 3),
                                  Text('ESP32 connection and control',
                                      style: AppTypography.font(
                                          fontSize: AppTypography.captionSize,
                                          color: secondary)),
                                ])),
                            IconButton(
                                tooltip: 'Close',
                                onPressed: () => Navigator.pop(context),
                                constraints: const BoxConstraints(
                                    minWidth: 28, minHeight: 28),
                                padding: const EdgeInsets.all(6),
                                icon: Icon(Icons.close_rounded,
                                    size: 16, color: secondary)),
                          ])),
                      Expanded(
                          child: SingleChildScrollView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              physics: const BouncingScrollPhysics(),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (final section
                                        in lightSwitchSetupSections(
                                            widget.serial)) ...[
                                      Text(section.$1,
                                          style: AppTypography.font(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: foreground)),
                                      const SizedBox(height: 6),
                                      SelectableText(section.$2,
                                          style: AppTypography.font(
                                              fontSize: 12,
                                              color: secondary,
                                              height: 1.5)),
                                      const SizedBox(height: 18),
                                    ],
                                    if (_copyMessage != null)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 14),
                                          child: Text(_copyMessage!,
                                              style: AppTypography.caption
                                                  .copyWith(
                                                      color: foreground))),
                                  ]))),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                              color: surface,
                              border: Border(
                                  top: BorderSide(
                                      color: dark
                                          ? Colors.white10
                                          : AppColors.neutral200)),
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(16))),
                          child: Row(children: [
                            Expanded(
                                child: OutlinedButton(
                                    style: buttons,
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: FilledButton.icon(
                                    style: buttons,
                                    onPressed: _copy,
                                    icon: const Icon(Icons.copy_outlined,
                                        size: 16),
                                    label: const Text('Copy guide'))),
                          ])),
                    ])))));
  }
}

List<(String, String)> lightSwitchSetupSections(String serial) {
  final base = SuperAdminApiService.baseUrl.replaceFirst(RegExp(r'/+$'), '');
  final endpoint = '$base/switches/${Uri.encodeComponent(serial)}';
  return [
    (
      'This device',
      'Serial: $serial\nAPI: $base\nUse the full registered serial, not its shortened display label.'
    ),
    (
      '1. Configure the board',
      'Use an ESP32 with Arduino core and ArduinoJson 7. Set Wi-Fi credentials, this API address, the registered serial, relay GPIO and active-low/active-high polarity. Use a reachable HTTPS API address with its trusted root CA; synchronize time for certificate validation. A physical board cannot reach your computer through 127.0.0.1.'
    ),
    (
      '2. Authenticate',
      'Every board request must include:\nContent-Type: application/json\nx-sensor-key: YOUR_FARM_SENSOR_KEY\n\nUse the sensor ingestion key belonging to this device’s farm. Obtain it from the farm administrator. The board does not use an admin login token. This guide does not display or copy the key.'
    ),
    (
      '3. Poll every 2 seconds',
      'POST $endpoint/poll\n\n{"session_id":"YOUR_RANDOM_SESSION_ID","reported_on":false}\n\nGenerate a fresh random session ID at boot and after a failed network request or reconnection (8–64 letters, digits, underscores or hyphens). reported_on is the actual relay output state as a JSON boolean.'
    ),
    (
      '4. Read the response',
      'No action needed:\n{"command":null}\n\nWhen an admin taps On:\n{"command":{"id":"COMMAND_UUID","desired_on":true,"valid_for_ms":9000}}\n\nOnly apply a valid, unexpired command. Compare the request elapsed time with valid_for_ms; discard it if too old. Set the GPIO to desired_on rather than toggling blindly. Remember the command ID so repeated delivery cannot apply it twice.'
    ),
    (
      '5. Confirm the output',
      'POST $endpoint/ack\n\n{"session_id":"YOUR_RANDOM_SESSION_ID","command_id":"COMMAND_UUID","reported_on":true}\n\nUse the exact command ID returned by poll and the same session ID. Read back the output and send its actual boolean state, even if it differs from the request. A successful acknowledgement returns {"accepted":true}. Continue polling with the current output state.'
    ),
    (
      'Connection and recovery',
      'After 15 seconds without a poll, the device is offline. Commands expire after 10 seconds and are tied to a connection session, so a reconnected board must not replay old commands. The supplied sketch starts OFF at boot and retains its last output during network loss. GPIO confirmation does not prove the physical lamp is powered; that requires a feedback input.'
    ),
    (
      'Troubleshooting',
      '401: check the farm sensor key.\n404: check the full serial and that its registered type is Light Switch.\n409 on acknowledgement: check the command and session IDs.\n422: check the JSON field types and session format.\nConnection or TLS failure: check Wi-Fi, API address, clock and trusted certificate.\nPending or expired: confirm the board is polling and sending acknowledgements.'
    ),
    (
      'Reference firmware',
      'The backend repository includes a complete starting sketch:\nexamples/esp32_light_switch/esp32_light_switch.ino\n\nRepository: https://github.com/Philippo20/farm_appwrite_api\n\nConfigure its placeholders and compile for your board before uploading. The database migration has already been applied; the matching API must also be deployed.'
    ),
  ];
}

String lightSwitchSetupText(String serial) => lightSwitchSetupSections(serial)
    .map((section) => '${section.$1}\n${section.$2}')
    .join('\n\n');
