import '../theme/app_typography.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import 'message_notification_host.dart';

/// One wall-clock inactivity monitor around every route, for all roles/devices.
class SessionSecurityHost extends ConsumerStatefulWidget {
  const SessionSecurityHost({super.key, required this.child, this.now, this.isPasswordRecovery});
  final Widget child;
  final DateTime Function()? now;
  final bool Function()? isPasswordRecovery;
  @override
  ConsumerState<SessionSecurityHost> createState() =>
      _SessionSecurityHostState();
}

class _SessionSecurityHostState extends ConsumerState<SessionSecurityHost>
    with WidgetsBindingObserver {
  Timer? _timer;
  String? _user;
  bool _warning = false, _checking = false, _ending = false, _active = true;
  String? _error;
  DateTime? _checkedAt;
  DateTime _now() => widget.now?.call() ?? DateTime.now();
  AuthService get _auth => ref.read(authServiceProvider);
  bool get _recovering => widget.isPasswordRecovery?.call() ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_key);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  bool _key(KeyEvent event) {
    if (event is KeyDownEvent) _activity();
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      _checkedAt = null;
      _tick();
    }
  }

  void _activity() {
    if (_recovering) return;
    if (_user == null || !_active || _ending || _warning) return;
    final now = _now();
    final last = _auth.lastActivity;
    // Never let an input arriving after a suspended timer revive an expired session.
    if (last == null ||
        now.difference(last) >=
            Duration(minutes: _auth.sessionTimeoutMinutes)) {
      unawaited(_end());
      return;
    }
    if (now.difference(last) >= const Duration(seconds: 1)) {
      unawaited(_auth.recordSessionActivity(now));
    }
  }

  void _tick() {
    if (!mounted || _ending) return;
    final user = ref.read(authProvider).user?.id;
    if (user != _user) {
      _user = user;
      _checkedAt = null;
      setState(() {
        _warning = false;
        _error = null;
      });
    }
    if (user == null) return;
    final last = _auth.lastActivity;
    final remaining = last == null
        ? Duration.zero
        : last
            .add(Duration(minutes: _auth.sessionTimeoutMinutes))
            .difference(_now());
    if (remaining <= Duration.zero) {
      unawaited(_end());
      return;
    }
    if (_recovering) {
      if (_warning) setState(() => _warning = false);
      return;
    }
    if (remaining <= Duration(minutes: _auth.sessionWarningMinutes) &&
        !_warning) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _warning = true);
    }
    if (_warning) setState(() {});
    if (_active &&
        !_checking &&
        (_checkedAt == null ||
            _now().difference(_checkedAt!) >= const Duration(minutes: 1))) {
      unawaited(_verify());
    }
  }

  Future<void> _verify({bool continuing = false}) async {
    if (_checking || _ending) return;
    final user = _user;
    final session = _auth.sessionId;
    setState(() {
      _checking = true;
      _error = null;
    });
    _checkedAt = _now();
    try {
      await _auth.refreshSession();
      if (!mounted ||
          user != ref.read(authProvider).user?.id ||
          session != _auth.sessionId ||
          _ending) {
        return;
      }
      final last = _auth.lastActivity;
      if (last == null ||
          _now().difference(last) >=
              Duration(minutes: _auth.sessionTimeoutMinutes)) {
        await _end();
        return;
      }
      if (continuing) {
        await _auth.recordSessionActivity(_now());
        if (mounted) setState(() => _warning = false);
      }
    } on SessionExpiredException {
      if (mounted &&
          user == ref.read(authProvider).user?.id &&
          session == _auth.sessionId) await _end();
    } catch (_) {
      if (mounted && continuing) {
        setState(() => _error =
            'Unable to verify your session. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _end() async {
    if (_ending) return;
    _ending = true;
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    final preserveRecovery = _recovering;
    if (!preserveRecovery) {
      messageNavigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (_) => false);
    }
    setState(() {
      _user = null;
      _warning = false;
      _ending = false;
    });
    if (!preserveRecovery) {
      messageScaffoldKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Your session has ended. Please sign in again.')));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    HardwareKeyboard.instance.removeHandler(_key);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final remaining = _auth.lastActivity
            ?.add(Duration(minutes: _auth.sessionTimeoutMinutes))
            .difference(_now())
            .inSeconds ??
        0;
    final seconds = remaining.clamp(0, 86400);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _activity(),
      onPointerMove: (_) => _activity(),
      onPointerSignal: (_) => _activity(),
      onPointerHover: (_) => _activity(),
      child: Stack(children: [
        ExcludeFocus(
            excluding: _warning,
            child: ExcludeSemantics(excluding: _warning, child: widget.child)),
        if (_warning) ...[
          const Positioned.fill(
              child: ModalBarrier(dismissible: false, color: Colors.black54)),
          Positioned.fill(
              child: Align(
            alignment: mobile ? Alignment.bottomCenter : Alignment.center,
            child: Padding(
              padding: mobile
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: 500,
                    maxHeight: MediaQuery.sizeOf(context).height * .9),
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.vertical(
                      top: const Radius.circular(16),
                      bottom: Radius.circular(mobile ? 0 : 16)),
                  elevation: mobile ? 0 : 12,
                  child: SafeArea(
                      top: false,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                            child: Row(children: [
                              Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [
                                        Color(0xff16a34a),
                                        Color(0xff15803d)
                                      ]),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.lock_clock_outlined,
                                      color: Colors.white, size: 20)),
                              const SizedBox(width: 12),
                              const Expanded(
                                  child: Text('Are you still there?',
                                      style: TextStyle(
                                          fontSize: AppTypography.cardTitleSize,
                                          fontWeight: AppTypography.headingWeight))),
                            ])),
                        Flexible(
                            child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'For your security, you will be signed out after inactivity. Your session ends in ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}.',
                                          style: const TextStyle(
                                              fontSize: AppTypography.captionSize)),
                                      if (_error != null)
                                        Padding(
                                            padding:
                                                const EdgeInsets.only(top: 14),
                                            child: Text(_error!,
                                                style: TextStyle(
                                                    fontSize: AppTypography.captionSize,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .error))),
                                    ]))),
                        Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(children: [
                              Expanded(
                                  child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          textStyle: const TextStyle(
                                              fontSize: AppTypography.actionSize),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10))),
                                      onPressed: _ending ? null : _end,
                                      child: const Text('Log out'))),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: FilledButton(
                                      style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          textStyle: const TextStyle(
                                              fontSize: AppTypography.actionSize),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10))),
                                      onPressed: _checking
                                          ? null
                                          : () => _verify(continuing: true),
                                      child: _checking
                                          ? const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                  SizedBox(
                                                      width: 14,
                                                      height: 14,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2)),
                                                  SizedBox(width: 8),
                                                  Flexible(
                                                      child: Text('Verifying…'))
                                                ])
                                          : const Text('Continue session'))),
                            ])),
                      ])),
                ),
              ),
            ),
          )),
        ],
      ]),
    );
  }
}
