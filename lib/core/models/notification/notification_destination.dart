import '../../../models/enums.dart';
import 'notification_model.dart';

class NotificationDestination {
  const NotificationDestination(this.label, this.route, {this.peerId});
  final String label;
  final String route;
  final String? peerId;
}

/// Only known application routes are allowed. Never navigate to a backend URL
/// or infer permissions from free-form notification titles/messages.
NotificationDestination? notificationDestination(
    NotificationModel item, UserRole? role) {
  if (role == null || item.metadata?['resolved'] == true) return null;
  final peer = item.metadata?['peerId']?.toString().trim();
  if (item.type == NotificationType.message &&
      peer != null &&
      peer.isNotEmpty) {
    return NotificationDestination('Open conversation', '/chat', peerId: peer);
  }
  final source = item.metadata?['sourceType']?.toString() ?? item.type.value;
  final routes = switch (source) {
    'task' => {
        UserRole.caretaker: ('View calendar', '/calendar'),
        UserRole.farmManager: ('View farm tasks', '/farm-manager/farms'),
        UserRole.technician: ('View maintenance', '/maintenance-schedule'),
      },
    'maintenance' => {
        UserRole.technician: ('View maintenance', '/maintenance-schedule'),
        UserRole.superAdmin: ('View devices', '/superadmin/sensors'),
        UserRole.admin: ('View devices', '/sensors'),
      },
    'batch' || 'harvest' => {
        UserRole.superAdmin: ('View batches', '/superadmin/batches'),
        UserRole.admin: ('View batches', '/batches-admin'),
        UserRole.farmManager: (
          'View batches',
          '/farm-manager/batch-generation'
        ),
        UserRole.owner: ('View farm', '/farm-owner/farm'),
        UserRole.caretaker: ('View farm', '/farm'),
        UserRole.fulfillmentManager: (
          'View harvest intake',
          '/fulfillment/harvest'
        ),
        UserRole.packagingSupervisor: ('View packaging', '/package-recording'),
        UserRole.qualityAssurance: ('View quality checks', '/quality-approve'),
      },
    'sensor_alert' => {
        UserRole.superAdmin: ('View sensors', '/superadmin/sensors'),
        UserRole.admin: ('View sensors', '/sensors'),
        UserRole.farmManager: ('View sensors', '/farm-manager/sensors'),
        UserRole.owner: ('View farm', '/farm-owner/farm'),
        UserRole.caretaker: ('View farm', '/farm'),
        UserRole.technician: ('View sensors', '/sensor-management'),
      },
    'inventory_alert' => {
        UserRole.superAdmin: ('View inventory', '/superadmin/inventory'),
        UserRole.admin: ('View inventory', '/inventory-admin'),
        UserRole.farmManager: ('View inventory', '/farm-manager/inventory'),
      },
    'inventory' => {
        UserRole.superAdmin: ('View inventory', '/superadmin/inventory'),
        UserRole.admin: ('View inventory', '/inventory-admin'),
        UserRole.farmManager: ('View inventory', '/farm-manager/inventory'),
        UserRole.caretaker: ('View input requests', '/input-confirmation'),
        UserRole.fulfillmentManager: (
          'View materials',
          '/fulfillment/inventory'
        ),
      },
    'delivery' => {
        UserRole.superAdmin: ('View deliveries', '/superadmin/deliveries'),
        UserRole.admin: ('View deliveries', '/deliveries-admin'),
        UserRole.farmManager: ('View deliveries', '/farm-manager/deliveries'),
        UserRole.salesManager: ('View deliveries', '/sales-deliveries'),
        UserRole.salesPersonnel: (
          'View deliveries',
          '/sales-personnel-delivery-status'
        ),
        UserRole.driver: ('View deliveries', '/driver-deliveries'),
      },
    'sales' => {
        UserRole.salesManager: ('View off-takers', '/sales-off-takers'),
      },
    'fund_request' => {
        UserRole.accountant: ('Review requests', '/accountant/approvals'),
        UserRole.farmManager: (
          'View fund requests',
          '/farm-manager/fund-request'
        ),
      },
    'withdrawal' => {
        UserRole.accountant: ('Review requests', '/accountant/approvals'),
        UserRole.owner: ('View wallet', '/farm-owner/digital-wallet'),
      },
    'account_review' => {
        UserRole.superAdmin: ('Review users', '/superadmin/users'),
        UserRole.admin: ('Review users', '/users'),
      },
    _ => <UserRole, (String, String)>{},
  };
  final destination = routes[role];
  return destination == null
      ? null
      : NotificationDestination(destination.$1, destination.$2);
}
