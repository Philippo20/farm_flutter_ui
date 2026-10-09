import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../services/maintenance_changes.dart';
import '../providers/maintenance_reminders_provider.dart';
import '../theme/app_typography.dart';

class MaintenanceReminderHost extends ConsumerStatefulWidget {
  const MaintenanceReminderHost(
      {super.key, required this.child, required this.navigatorKey});
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  @override
  ConsumerState<MaintenanceReminderHost> createState() =>
      _MaintenanceReminderHostState();
}

class _MaintenanceReminderHostState
    extends ConsumerState<MaintenanceReminderHost> with WidgetsBindingObserver {
  Timer? _timer;
  bool _active = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    maintenanceChanges.addListener(_refresh);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  void _refresh() {
    if (!mounted || !_active) return;
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated || auth.user?.role != UserRole.technician) return;
    unawaited(ref
        .read(maintenanceRemindersProvider(auth.user!.id).notifier)
        .refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final items = auth.isAuthenticated && auth.user?.role == UserRole.technician
        ? ref.watch(maintenanceRemindersProvider(auth.user!.id))
        : <Map<String, dynamic>>[];
    return Column(children: [
      items.isEmpty
          ? const SizedBox.shrink()
          : MaintenanceWarningBanner(
              items: items,
              onOpen: () {
                widget.navigatorKey.currentState?.pushNamed('/maintenance');
              }),
      Expanded(
          child: MediaQuery.removePadding(
              context: context,
              removeTop: items.isNotEmpty,
              child: widget.child)),
    ]);
  }

  @override
  void dispose() {
    _timer?.cancel();
    maintenanceChanges.removeListener(_refresh);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class MaintenanceWarningBanner extends StatelessWidget {
  const MaintenanceWarningBanner(
      {super.key, required this.items, required this.onOpen});
  final List<Map<String, dynamic>> items;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final overdue = items.where((item) => item['overdue'] == true).length;
    final title = overdue > 0
        ? '$overdue overdue maintenance ${overdue == 1 ? 'task' : 'tasks'}'
        : '${items.length} maintenance ${items.length == 1 ? 'task' : 'tasks'} due today';
    final detail =
        '${items.first['title'] ?? 'Maintenance required'} · Due ${items.first['due_date'] ?? ''}';
    return Material(
        color: dark ? const Color(0xff382b16) : const Color(0xfffff3d6),
        child: SafeArea(
            bottom: false,
            child: Semantics(
                liveRegion: true,
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 24,
                              color: dark
                                  ? const Color(0xffffd37c)
                                  : const Color(0xff8b5700)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(title,
                                    style: AppTypography.body.copyWith(
                                        color: colors.onSurface,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(detail,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySmall
                                        .copyWith(color: colors.onSurface)),
                              ])),
                          const SizedBox(width: 8),
                          Semantics(
                              label: 'Open maintenance',
                              button: true,
                              child: TextButton(
                                  key: const ValueKey('open-maintenance'),
                                  onPressed: onOpen,
                                  child: Text('View',
                                      style: AppTypography.button
                                          .copyWith(color: colors.onSurface)))),
                        ])))));
  }
}
