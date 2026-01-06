import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:badges/badges.dart' as badges;
import '../providers/notification_provider.dart';
import '../models/notification/notification_model.dart';
import '../theme/app_colors.dart';

class NotificationCenter extends ConsumerWidget {
  const NotificationCenter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const NotificationDialog(),
          );
        },
      ),
    );
  }
}

class NotificationDialog extends ConsumerWidget {
  const NotificationDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Notifications'),
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
              },
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 500,
        child: notifications.isEmpty
            ? const Center(child: Text('No notifications'))
            : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return ListTile(
                    leading: Icon(
                      _getIconForType(notification.type),
                      color: _getColorForType(notification.type),
                    ),
                    title: Text(notification.title),
                    subtitle: Text(notification.message),
                    trailing: notification.isRead
                        ? null
                        : Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                    onTap: () {
                      ref
                          .read(notificationProvider.notifier)
                          .markAsRead(notification.id);
                      // Action URL handling can be added here
                    },
                  );
                },
              ),
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
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
