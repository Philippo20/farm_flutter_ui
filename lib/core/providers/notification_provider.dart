import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification/notification_model.dart';

class NotificationNotifier extends StateNotifier<List<NotificationModel>> {
  NotificationNotifier() : super(_generateMockNotifications());

  void addNotification(NotificationModel notification) {
    state = [notification, ...state];
  }

  void markAsRead(String id) {
    state = [
      for (final notification in state)
        if (notification.id == id)
          notification.copyWith(isRead: true)
        else
          notification,
    ];
  }

  void markAllAsRead() {
    state = [
      for (final notification in state) notification.copyWith(isRead: true),
    ];
  }

  void removeNotification(String id) {
    state = state.where((notification) => notification.id != id).toList();
  }

  void clearAll() {
    state = [];
  }

  int get unreadCount => state.where((n) => !n.isRead).length;

  /// Generate mock notifications
  static List<NotificationModel> _generateMockNotifications() {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: '1',
        title: 'Batch Ready for Harvest',
        message: 'Batch LE-20241101-20241201 is ready for harvesting',
        type: NotificationType.harvest,
        priority: NotificationPriority.high,
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      NotificationModel(
        id: '2',
        title: 'Low Inventory Alert',
        message: 'Lettuce Seeds stock is below minimum level (8kg)',
        type: NotificationType.inventory,
        priority: NotificationPriority.urgent,
        createdAt: now.subtract(const Duration(hours: 5)),
        isRead: false,
      ),
      NotificationModel(
        id: '3',
        title: 'Maintenance Scheduled',
        message: 'Irrigation system maintenance scheduled for tomorrow',
        type: NotificationType.maintenance,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      NotificationModel(
        id: '4',
        title: 'Technical Issue Reported',
        message: 'pH sensor malfunction in Farm A - Section 2',
        type: NotificationType.issue,
        priority: NotificationPriority.high,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        isRead: true,
      ),
      NotificationModel(
        id: '5',
        title: 'New Batch Created',
        message: 'Batch TO-20241215-20250114 has been created',
        type: NotificationType.batch,
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ];
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationModel>>(
  (ref) => NotificationNotifier(),
);

/// Unread Count Provider
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationProvider);
  return notifications.where((n) => !n.isRead).length;
});
