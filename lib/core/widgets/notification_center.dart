import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:badges/badges.dart' as badges;
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../screens/caretaker/chat_screen.dart';
import '../../services/local_alerts.dart';
import '../models/notification/notification_model.dart';
import '../models/notification/notification_destination.dart';
import '../providers/notification_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_dialog.dart';

final notificationViewerProvider =
    Provider<UserModel?>((ref) => ref.watch(authProvider).user);

Future<void> showNotificationDialog(BuildContext context) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final container = ProviderScope.containerOf(context, listen: false);
  final viewer = container.read(notificationViewerProvider);
  final destination = await showAppDialog<NotificationDestination>(
    context: context,
    builder: (_) => const AppDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: NotificationDialog(),
    ),
  );
  if (!navigator.mounted || destination == null || viewer == null) return;
  final current = container.read(notificationViewerProvider);
  if (current?.id != viewer.id || current?.role != viewer.role) return;
  if (destination.peerId != null) {
    await navigator.push(MaterialPageRoute<void>(
      builder: (_) => ChatScreen(initialPeerId: destination.peerId),
    ));
  } else {
    await navigator.pushNamed(destination.route);
  }
}

class NotificationCenter extends ConsumerWidget {
  const NotificationCenter({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread =
        ref.watch(notificationProvider).where((item) => !item.isRead).length;
    return badges.Badge(
      showBadge: unread > 0,
      badgeContent: Text('$unread',
          style: const TextStyle(color: Colors.white, fontSize: 10)),
      child: IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () => showNotificationDialog(context)),
    );
  }
}

class NotificationDialog extends ConsumerStatefulWidget {
  const NotificationDialog({super.key, this.loadOnOpen = true});
  final bool loadOnOpen;
  @override
  ConsumerState<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends ConsumerState<NotificationDialog> {
  bool _refreshing = false;
  NotificationModel? _selected;
  String? _notice;
  final _bodyScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.loadOnOpen) Future.microtask(_refresh);
  }

  @override
  void dispose() {
    _bodyScroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted || _refreshing) return;
    setState(() {
      _refreshing = true;
      _notice = null;
    });
    try {
      await ref.read(notificationProvider.notifier).refreshFromBackend(
          recipientId: ref.read(notificationViewerProvider)?.id);
    } catch (_) {
      if (mounted) {
        setState(() => _notice =
            'Could not refresh. Your previous notifications are still available.');
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _markRead(NotificationModel item) {
    ref.read(notificationProvider.notifier).markAsRead(item.id,
        recipientId: ref.read(notificationViewerProvider)?.id);
  }

  void _preview(NotificationModel? item) {
    if (item != null) _markRead(item);
    setState(() => _selected = item);
    if (_bodyScroll.hasClients) _bodyScroll.jumpTo(0);
  }

  void _open(NotificationModel item, NotificationDestination destination) {
    _markRead(item);
    Navigator.pop(context, destination);
  }

  TextStyle _text(double size, {bool bold = false, Color? color}) =>
      AppTypography.font(
          fontSize: size,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: color ?? Theme.of(context).colorScheme.onSurface);

  @override
  Widget build(BuildContext context) {
    ref.listen(notificationViewerProvider, (previous, next) {
      if (previous?.id != next?.id || previous?.role != next?.role) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && ModalRoute.of(context)?.isCurrent == true) {
            Navigator.pop(context);
          }
        });
      }
    });
    final items = ref.watch(notificationProvider);
    final viewer = ref.watch(notificationViewerProvider);
    final unread = items.where((item) => !item.isRead).length;
    final selected = _selected;
    final destination = selected == null
        ? null
        : notificationDestination(selected, viewer?.role);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark ? Colors.white60 : AppColors.textSecondary;
    final height = math.min(680.0, MediaQuery.sizeOf(context).height * .9);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: SizedBox(
          height: height,
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 24,
                        offset: Offset(0, 12)),
                  ]),
              child: Container(
                decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16)),
                child: SafeArea(
                    top: false,
                    child: Column(children: [
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
                                child: const Icon(
                                    Icons.notifications_active_outlined,
                                    color: Colors.white,
                                    size: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(
                                      selected == null
                                          ? 'Notifications'
                                          : 'Notification details',
                                      style: _text(16).copyWith(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 3),
                                  Text(
                                      selected == null
                                          ? (unread == 0
                                              ? 'You are all caught up'
                                              : '$unread unread')
                                          : 'Full message',
                                      style: _text(12, color: secondary)),
                                ])),
                            IconButton(
                                tooltip: 'Close',
                                iconSize: 16,
                                visualDensity: VisualDensity.compact,
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded)),
                          ])),
                      Expanded(
                          child: SingleChildScrollView(
                        controller: _bodyScroll,
                        physics: const BouncingScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_notice != null)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: Text(_notice!,
                                        style: _text(12, color: secondary))),
                              if (selected == null) ...[
                                Wrap(
                                    alignment: WrapAlignment.end,
                                    spacing: 8,
                                    children: [
                                      TextButton.icon(
                                          onPressed: () async {
                                            final enabled = await LocalAlerts
                                                .instance
                                                .requestPermission();
                                            if (mounted) {
                                              setState(() => _notice = enabled
                                                  ? 'Permission requested. Check your device notification settings.'
                                                  : 'Allow notifications in your browser or device settings. Your inbox remains available.');
                                            }
                                          },
                                          icon: const Icon(
                                              Icons
                                                  .notifications_active_outlined,
                                              size: 16),
                                          label: Text('Device alerts',
                                              style: _text(12))),
                                      TextButton.icon(
                                          onPressed:
                                              _refreshing ? null : _refresh,
                                          icon: _refreshing
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2))
                                              : const Icon(Icons.refresh,
                                                  size: 16),
                                          label: Text('Refresh',
                                              style: _text(12))),
                                    ]),
                                if (items.isEmpty)
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 36),
                                      child: Column(children: [
                                        Icon(Icons.notifications_none_rounded,
                                            size: 40, color: secondary),
                                        const SizedBox(height: 12),
                                        Text(
                                            _refreshing
                                                ? 'Loading notifications...'
                                                : 'No notifications yet',
                                            style: _text(13, bold: true)),
                                        const SizedBox(height: 6),
                                        Text(
                                            'Farm updates and team messages will appear here.',
                                            textAlign: TextAlign.center,
                                            style: _text(12, color: secondary)),
                                      ])),
                                for (final item in items)
                                  Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _tile(
                                          item,
                                          notificationDestination(
                                              item, viewer?.role),
                                          secondary)),
                              ] else ...[
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  Chip(
                                      label: Text(selected.type.displayName,
                                          style: _text(11)),
                                      visualDensity: VisualDensity.compact),
                                  if (selected.priority !=
                                      NotificationPriority.normal)
                                    Chip(
                                        label: Text(
                                            selected.priority.displayName,
                                            style: _text(11)),
                                        visualDensity: VisualDensity.compact),
                                ]),
                                const SizedBox(height: 12),
                                SelectableText(selected.title,
                                    style: _text(16, bold: true)),
                                const SizedBox(height: 8),
                                Text(
                                    DateFormat('d MMM yyyy, h:mm a')
                                        .format(selected.createdAt.toLocal()),
                                    style: _text(11, color: secondary)),
                                const SizedBox(height: 20),
                                SelectableText(selected.message,
                                    key: const ValueKey(
                                        'full-notification-message'),
                                    style: _text(13).copyWith(height: 1.6)),
                                const SizedBox(height: 20),
                                Text(
                                    destination == null
                                        ? 'No action is available for this notification.'
                                        : "Use ${destination.label} to continue.",
                                    style: _text(12, color: secondary)),
                              ],
                              const SizedBox(height: 8),
                            ]),
                      )),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(children: [
                            Expanded(
                                child: OutlinedButton(
                                    style: _buttonStyle(),
                                    onPressed: selected == null
                                        ? () => Navigator.pop(context)
                                        : () => _preview(null),
                                    child: Text(
                                        selected == null ? 'Close' : 'Back'))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: FilledButton(
                              style: _buttonStyle(),
                              onPressed: selected == null
                                  ? (unread == 0
                                      ? null
                                      : () => ref
                                          .read(notificationProvider.notifier)
                                          .markAllAsRead(
                                              recipientId: viewer?.id))
                                  : destination == null
                                      ? () => Navigator.pop(context)
                                      : () => _open(selected, destination),
                              child: Text(
                                  selected == null
                                      ? 'Mark all read'
                                      : destination?.label ?? 'Done',
                                  textAlign: TextAlign.center),
                            )),
                          ])),
                    ])),
              ),
            ),
          )),
    );
  }

  ButtonStyle _buttonStyle() => TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        textStyle:
            AppTypography.font(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  Widget _tile(NotificationModel item, NotificationDestination? destination,
      Color secondary) {
    final color = _getColorForType(item.type);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
              color: item.isRead
                  ? Theme.of(context).dividerColor.withValues(alpha: .18)
                  : color.withValues(alpha: .4))),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () =>
            destination == null ? _preview(item) : _open(item, destination),
        child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(_getIconForType(item.type), size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(child: Text(item.title, style: _text(13, bold: true))),
                if (!item.isRead)
                  Padding(
                      padding: const EdgeInsets.only(left: 6, top: 5),
                      child: Icon(Icons.circle, size: 6, color: color)),
              ]),
              const SizedBox(height: 8),
              Text(item.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: _text(12, color: secondary).copyWith(height: 1.45)),
              const SizedBox(height: 8),
              Text(item.timeAgo, style: _text(11, color: secondary)),
              Wrap(spacing: 8, children: [
                TextButton(
                    onPressed: () => _preview(item),
                    child: const Text('Read message')),
                if (destination != null)
                  TextButton.icon(
                      onPressed: () => _open(item, destination),
                      label: Text(destination.label),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 14)),
              ]),
            ])),
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.chat_bubble_outline_rounded;
      case NotificationType.task:
        return Icons.task_alt_rounded;
      case NotificationType.batch:
        return Icons.inventory_2;
      case NotificationType.harvest:
        return Icons.agriculture;
      case NotificationType.maintenance:
        return Icons.build;
      case NotificationType.issue:
        return Icons.error_outline;
      case NotificationType.inventory:
        return Icons.warehouse;
      case NotificationType.financial:
        return Icons.attach_money;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.general:
        return Icons.info_outline;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return AppColors.primary;
      case NotificationType.task:
        return AppColors.primary;
      case NotificationType.batch:
        return AppColors.primary;
      case NotificationType.harvest:
        return AppColors.success;
      case NotificationType.maintenance:
        return AppColors.warning;
      case NotificationType.issue:
        return AppColors.error;
      case NotificationType.inventory:
        return AppColors.warning;
      case NotificationType.financial:
        return AppColors.success;
      case NotificationType.system:
        return AppColors.info;
      case NotificationType.general:
        return AppColors.info;
    }
  }
}
