import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification/notification_model.dart';
import '../../services/superadmin_api_service.dart';
import '../../services/messaging_service.dart';

class NotificationNotifier extends StateNotifier<List<NotificationModel>> {
  NotificationNotifier() : super(const []);

  final SuperAdminApiService _api = SuperAdminApiService();
  final MessagingService _messages = MessagingService();
  int _generation = 0;

  void replaceMessages(List<NotificationModel> messages) {
    state = [
      ...state.where((item) => item.type != NotificationType.message),
      ...messages,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  void dispose() {
    _messages.dispose();
    super.dispose();
  }

  Future<void> refreshFromBackend({String? recipientId}) async {
    final generation = _generation;
    final results = await Future.wait([
      _api.getAlerts(),
      if (recipientId != null && recipientId.trim().isNotEmpty)
        _api.getNotifications(recipientId),
    ]);
    if (!mounted || generation != _generation) return;
    final alerts = results.first;
    final notifications =
        results.length > 1 ? results[1] : <Map<String, dynamic>>[];
    final readIds = {
      for (final notification in state)
        if (notification.isRead) notification.id,
    };
    final mappedAlerts = alerts
        .map((alert) => _fromAlert(alert, readIds.contains(_alertId(alert))))
        .whereType<NotificationModel>();
    final mappedNotifications = notifications
        .map((notification) => _fromNotification(
            notification, readIds.contains(_notificationId(notification))))
        .whereType<NotificationModel>();
    state = [
      ...mappedAlerts,
      ...mappedNotifications,
      ...state.where((item) => item.type == NotificationType.message)
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  NotificationModel? _fromNotification(
      Map<String, dynamic> notification, bool isRead) {
    final id = _notificationId(notification);
    final title = (notification['title'] ?? '').toString().trim();
    final message = (notification['message'] ?? '').toString().trim();
    if (id.isEmpty || title.isEmpty || message.isEmpty) return null;
    final createdAt = DateTime.tryParse(
          (notification['created_at'] ?? notification[r'$createdAt'] ?? '')
              .toString(),
        ) ??
        DateTime.now();
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: NotificationType.fromString(
          (notification['type'] ?? 'system').toString()),
      priority: NotificationPriority.fromString(
          (notification['priority'] ?? 'normal').toString()),
      createdAt: createdAt,
      isRead: isRead || notification['is_read'] == true,
      metadata: {
        'relatedTaskId': notification['related_task_id'] ?? '',
      },
    );
  }

  NotificationModel? _fromAlert(Map<String, dynamic> alert, bool isRead) {
    final id = _alertId(alert);
    final message = (alert['message'] ?? '').toString().trim();
    if (id.isEmpty || message.isEmpty) return null;

    final severity = (alert['severity'] ?? 'medium').toString().toLowerCase();
    final sensor = (alert['sensorType'] ?? 'system').toString();
    final timestamp = DateTime.tryParse(
          (alert['timestamp'] ?? alert[r'$createdAt'] ?? '').toString(),
        ) ??
        DateTime.now();
    final type = sensor.toLowerCase() == 'system'
        ? NotificationType.system
        : NotificationType.issue;
    final priority = severity == 'high'
        ? NotificationPriority.high
        : severity == 'low'
            ? NotificationPriority.low
            : NotificationPriority.normal;

    return NotificationModel(
      id: id,
      title: sensor.toLowerCase() == 'system'
          ? 'System alert'
          : '${_titleCase(sensor)} sensor alert',
      message: message,
      type: type,
      priority: priority,
      createdAt: timestamp,
      isRead: isRead,
      metadata: {
        'severity': severity,
        'resolved': alert['resolved'] == true,
        'farmId': alert['farmID'] ?? '',
      },
    );
  }

  String _alertId(Map<String, dynamic> alert) =>
      (alert[r'$id'] ?? alert['id'] ?? alert['alert_id'] ?? '').toString();

  String _notificationId(Map<String, dynamic> notification) =>
      (notification[r'$id'] ??
              notification['id'] ??
              notification['notification_id'] ??
              '')
          .toString();

  String _titleCase(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) =>
          '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');

  void addNotification(NotificationModel notification) {
    state = [notification, ...state];
  }

  void markAsRead(String id, {String? recipientId}) {
    final selected = state.where((item) => item.id == id).firstOrNull;
    if (selected?.type == NotificationType.message) {
      unawaited(_persistMessageRead(selected!));
      return;
    }
    state = [
      for (final notification in state)
        if (notification.id == id)
          notification.copyWith(isRead: true)
        else
          notification,
    ];
    final resolvedRecipientId = recipientId;
    if (resolvedRecipientId != null && resolvedRecipientId.trim().isNotEmpty) {
      unawaited(_persistRead(id));
    }
  }

  Future<void> _persistMessageRead(NotificationModel item) async {
    try {
      await _messages.markRead(item.metadata!['peerId'] as String,
          [item.metadata!['messageId'] as String]);
      if (!mounted) return;
      state = [
        for (final entry in state)
          if (entry.id == item.id) entry.copyWith(isRead: true) else entry
      ];
    } catch (_) {
      // Leave unread so a failed request can be retried from the center.
    }
  }

  Future<void> _persistRead(String id) async {
    try {
      await _api.markNotificationAsRead(id);
    } catch (_) {
      // Keep the optimistic state; the next refresh will retry from the UI.
    }
  }

  void markAllAsRead({String? recipientId}) {
    for (final item in state.where(
        (item) => item.type == NotificationType.message && !item.isRead)) {
      unawaited(_persistMessageRead(item));
    }
    state = [
      for (final notification in state)
        if (notification.type == NotificationType.message)
          notification
        else
          notification.copyWith(isRead: true),
    ];
    final resolvedRecipientId = recipientId;
    if (resolvedRecipientId != null && resolvedRecipientId.trim().isNotEmpty) {
      unawaited(_persistAllRead(resolvedRecipientId));
    }
  }

  Future<void> _persistAllRead(String recipientId) async {
    try {
      await _api.markAllNotificationsAsRead(recipientId);
    } catch (_) {
      // Keep the optimistic state; the next refresh will retry from the UI.
    }
  }

  void removeNotification(String id) {
    state = state.where((notification) => notification.id != id).toList();
  }

  void clearAll() {
    _generation++;
    state = [];
  }

  int get unreadCount => state.where((n) => !n.isRead).length;
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
