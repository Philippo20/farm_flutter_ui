import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/android_app_updates.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_dialog.dart';
import 'crop_variety_modal_frame.dart';

class AndroidUpdateHost extends StatefulWidget {
  const AndroidUpdateHost(
      {super.key,
      required this.child,
      required this.navigatorKey,
      this.service});
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final AndroidAppUpdates? service;
  @override
  State<AndroidUpdateHost> createState() => _AndroidUpdateHostState();
}

class _AndroidUpdateHostState extends State<AndroidUpdateHost>
    with WidgetsBindingObserver {
  late final _updates = widget.service ?? AndroidAppUpdates();
  Timer? _timer;
  DateTime? _lastCheck;
  bool _foreground = true, _open = false, _checking = false;
  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  @override
  void initState() {
    super.initState();
    if (!_supported) return;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _check();
    });
    _timer = Timer.periodic(const Duration(hours: 6), (_) => _check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _updates.resumed().catchError((_) {});
      if (_lastCheck == null ||
          DateTime.now().difference(_lastCheck!) >=
              const Duration(minutes: 15)) {
        _check();
      }
    }
  }

  Future<void> _check() async {
    if (!mounted || !_foreground || _open || _checking) return;
    _checking = true;
    try {
      _lastCheck = DateTime.now();
      if (!await _updates.check() || !mounted || !_foreground) return;
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || !_foreground) return;
      final build = _updates.release!.build;
      final snoozed = prefs.getInt('app_update_snooze_build') == build &&
          DateTime.now().millisecondsSinceEpoch <
              (prefs.getInt('app_update_snooze_until') ?? 0);
      if (snoozed &&
          {AppUpdatePhase.available, AppUpdatePhase.failed}
              .contains(_updates.phase)) return;
      final context = widget.navigatorKey.currentState?.overlay?.context;
      if (context == null || !context.mounted) return;
      _open = true;
      await showAppDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AndroidUpdateModal(updates: _updates));
      await prefs.setInt('app_update_snooze_build', build);
      await prefs.setInt('app_update_snooze_until',
          DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch);
    } catch (_) {
      // Optional update checks stay quiet when the release website is offline.
    } finally {
      _open = false;
      _checking = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    if (widget.service == null) _updates.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class AndroidUpdateModal extends StatelessWidget {
  const AndroidUpdateModal({super.key, required this.updates});
  final AndroidAppUpdates updates;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: updates,
      builder: (context, _) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final colors = Theme.of(context).colorScheme;
        final mobile = Theme.of(context).platform == TargetPlatform.android ||
            MediaQuery.sizeOf(context).width < 600;
        final downloading = updates.phase == AppUpdatePhase.downloading;
        final verifying = updates.phase == AppUpdatePhase.verifying;
        final label = switch (updates.phase) {
          AppUpdatePhase.available => 'Download update',
          AppUpdatePhase.failed => 'Retry download',
          AppUpdatePhase.downloading => 'Downloading…',
          AppUpdatePhase.verifying => 'Verifying…',
          AppUpdatePhase.permission => 'Allow installation',
          AppUpdatePhase.ready || AppUpdatePhase.installing => 'Install update',
        };
        final action = updates.phase == AppUpdatePhase.permission
            ? updates.allowInstallation
            : {AppUpdatePhase.ready, AppUpdatePhase.installing}
                    .contains(updates.phase)
                ? updates.install
                : updates.download;
        final buttonStyle =
            AppTypography.font(fontSize: 13, fontWeight: FontWeight.w600);
        return CropVarietyModalFrame(
            mobile: mobile,
            isDark: dark,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [AppColors.success, Color(0xff4d8c32)]),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.system_update_rounded,
                            color: Colors.white, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('App update available',
                              style: AppTypography.font(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurface)),
                          const SizedBox(height: 4),
                          Text('Keep Farm Estates up to date',
                              style: AppTypography.font(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant)),
                        ])),
                    IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 16),
                        tooltip: 'Close'),
                  ])),
              Flexible(
                  child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: colors.surfaceContainerHighest
                                        .withValues(alpha: .35),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: colors.outlineVariant)),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Version ${updates.release?.version} · Build ${updates.release?.build}',
                                          style: AppTypography.font(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: colors.onSurface)),
                                      const SizedBox(height: 6),
                                      Text(
                                          'Installed ${updates.currentVersion}  ·  ${((updates.release?.bytes ?? 0) / 1024 / 1024).toStringAsFixed(1)} MB download',
                                          style: AppTypography.font(
                                              fontSize: 12,
                                              color: colors.onSurfaceVariant)),
                                    ])),
                            const SizedBox(height: 16),
                            Text(
                                updates.release?.notes.isNotEmpty == true
                                    ? updates.release!.notes
                                    : 'Get the latest improvements and fixes for your farm workspace.',
                                style: AppTypography.font(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: colors.onSurface)),
                            const SizedBox(height: 16),
                            if (downloading || verifying) ...[
                              LinearProgressIndicator(
                                  value: verifying ? null : updates.progress,
                                  borderRadius: BorderRadius.circular(6)),
                              const SizedBox(height: 8),
                              Text(
                                  verifying
                                      ? 'Checking the update before installation…'
                                      : 'Downloading ${updates.progress == null ? '' : '${(updates.progress! * 100).round()}%'}',
                                  style: AppTypography.font(
                                      fontSize: 12,
                                      color: colors.onSurfaceVariant)),
                              const SizedBox(height: 12),
                            ],
                            Text(
                                updates.phase == AppUpdatePhase.permission
                                    ? 'Android needs your permission. Tap Allow installation, enable “Allow from this source”, then return here.'
                                    : updates.phase == AppUpdatePhase.installing
                                        ? 'Confirm Update in the Android installer. If you cancelled, you can open the installer again.'
                                        : downloading
                                            ? 'You can close this sheet. The download continues in the background.'
                                            : 'Android will ask you to confirm installation. Your account and farm data will be kept.',
                                style: AppTypography.font(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: colors.onSurfaceVariant)),
                            if (updates.error != null)
                              Padding(
                                  padding: const EdgeInsets.only(top: 14),
                                  child: Text(updates.error!,
                                      style: AppTypography.font(
                                          fontSize: 12, color: colors.error))),
                          ]))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: Row(children: [
                    Expanded(
                        child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            child: Text('Cancel', style: buttonStyle))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: FilledButton(
                            onPressed: updates.busy || downloading || verifying
                                ? null
                                : action,
                            style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (updates.busy ||
                                      downloading ||
                                      verifying) ...[
                                    const SizedBox(
                                        width: 13,
                                        height: 13,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2)),
                                    const SizedBox(width: 7)
                                  ],
                                  Flexible(
                                      child: Text(
                                          updates.busy ? 'Please wait…' : label,
                                          style: buttonStyle,
                                          textAlign: TextAlign.center)),
                                ]))),
                  ])),
            ]));
      });
}
