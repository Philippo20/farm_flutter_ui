import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:badges/badges.dart' as badges;
import '../providers/notification_provider.dart';
import '../models/notification/notification_model.dart';
import '../theme/app_colors.dart';
import '../../providers/auth_provider.dart';

void showNotificationDialog(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  if (screenWidth < 600) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SafeArea(
        top: false,
        child: NotificationDialog(),
      ),
    );
    return;
  }

  final buttonBox = context.findRenderObject() as RenderBox?;
  final overlayBox =
      Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (buttonBox == null || overlayBox == null) return;

  final anchor = RelativeRect.fromRect(
    Rect.fromPoints(
      buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox),
      buttonBox.localToGlobal(
        buttonBox.size.bottomRight(Offset.zero),
        ancestor: overlayBox,
      ),
    ),
    Offset.zero & overlayBox.size,
  );
  final dropdownPosition = RelativeRect.fromLTRB(
    anchor.left,
    overlayBox.size.height - anchor.bottom + 8,
    anchor.right,
    anchor.bottom - 8,
  );

  showMenu<void>(
    context: context,
    position: dropdownPosition,
    elevation: 14,
    color: Colors.transparent,
    shadowColor: Colors.transparent,
    popUpAnimationStyle: AnimationStyle(
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 120),
    ),
    items: [
      PopupMenuItem<void>(
        enabled: false,
        padding: EdgeInsets.zero,
        child: SizedBox(
          width: screenWidth < 980 ? 440 : 490,
          height: 560,
          child: const NotificationDialog(),
        ),
      ),
    ],
  );
}

class NotificationCenter extends ConsumerStatefulWidget {
  const NotificationCenter({super.key});

  @override
  ConsumerState<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends ConsumerState<NotificationCenter> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final recipientId = ref.read(authProvider).user?.id;
      ref
          .read(notificationProvider.notifier)
          .refreshFromBackend(recipientId: recipientId)
          .ignore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return badges.Badge(
      showBadge: unreadCount > 0,
      badgeContent: Text(
        unreadCount.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      child: IconButton(
        icon: const Icon(Icons.notifications_outlined),
        tooltip: 'Notifications',
        onPressed: () => showNotificationDialog(context),
      ),
    );
  }
}

class NotificationDialog extends ConsumerStatefulWidget {
  const NotificationDialog({super.key});

  @override
  ConsumerState<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends ConsumerState<NotificationDialog> {
  bool _isRefreshing = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh() async {
    try {
      final recipientId = ref.read(authProvider).user?.id;
      await ref
          .read(notificationProvider.notifier)
          .refreshFromBackend(recipientId: recipientId);
    } catch (_) {
      // Keep the last successfully loaded notifications visible.
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650, maxHeight: 700),
      child: Container(
        constraints: const BoxConstraints(minHeight: 300),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 10, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Refresh notifications',
                    onPressed: _isRefreshing ? null : _refresh,
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 2, 22, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.notifications_active_rounded,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notifications',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                            )),
                        const SizedBox(height: 3),
                        Text(
                          unreadCount == 0
                              ? 'You are all caught up'
                              : '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (notifications.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: unreadCount == 0
                        ? null
                        : () {
                            final recipientId = ref.read(authProvider).user?.id;
                            ref
                                .read(notificationProvider.notifier)
                                .markAllAsRead(recipientId: recipientId);
                          },
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Mark all as read'),
                  ),
                ),
              ),
            Expanded(
              child: _isRefreshing && notifications.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : notifications.isEmpty
                      ? _emptyState(isDark)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 9),
                          itemBuilder: (context, index) =>
                              _notificationTile(notifications[index], isDark),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 48,
                color: isDark ? Colors.white38 : AppColors.neutral400),
            const SizedBox(height: 12),
            Text('No notifications yet',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: 5),
            Text('New farm alerts and system updates will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _notificationTile(NotificationModel notification, bool isDark) {
    final color = _getColorForType(notification.type);
    final severity = notification.metadata?['severity']?.toString();
    final resolved = notification.metadata?['resolved'] == true;
    return Material(
      color: notification.isRead
          ? (isDark ? Colors.white.withOpacity(0.025) : AppColors.neutral50)
          : color.withOpacity(isDark ? 0.1 : 0.06),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: () {
          final recipientId = ref.read(authProvider).user?.id;
          ref.read(notificationProvider.notifier).markAsRead(
                notification.id,
                recipientId: recipientId,
              );
        },
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(_getIconForType(notification.type),
                    color: color, size: 19),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              )),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notification.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: isDark
                                ? Colors.white60
                                : AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 5,
                      children: [
                        _metaChip(notification.timeAgo, Icons.schedule_rounded,
                            isDark ? Colors.white54 : AppColors.textSecondary),
                        if (severity != null)
                          _metaChip(severity.toUpperCase(),
                              Icons.priority_high_rounded, color),
                        if (resolved)
                          _metaChip(
                              'RESOLVED',
                              Icons.check_circle_outline_rounded,
                              AppColors.success),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
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
