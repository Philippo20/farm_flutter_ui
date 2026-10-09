import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/typography_preferences.dart';
import '../../providers/auth_provider.dart';
import '../providers/personal_appearance_provider.dart';

/// Wraps the Navigator, including dialogs, without changing global font tokens.
class PersonalTypographyHost extends ConsumerStatefulWidget {
  const PersonalTypographyHost({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<PersonalTypographyHost> createState() =>
      _PersonalTypographyHostState();
}

class _PersonalTypographyHostState extends ConsumerState<PersonalTypographyHost>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _active = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _refresh());
  }

  void _refresh() {
    if (!mounted || !_active) return;
    final userId = ref.read(authProvider).user?.id;
    if (userId != null)
      unawaited(
          ref.read(personalAppearanceProvider(userId).notifier).refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider.select((auth) => auth.user?.id));
    final preferences = userId == null
        ? TypographyPreferences.defaults
        : ref.watch(personalAppearanceProvider(userId)).value;
    return MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler:
                PersonalTextScaler(preferences, systemTextScalerOf(context))),
        child: widget.child);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
