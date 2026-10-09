import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/device_maintenance_api.dart';
import '../../services/auth_service.dart';

class MaintenanceRemindersNotifier
    extends StateNotifier<List<Map<String, dynamic>>> {
  MaintenanceRemindersNotifier(this.userId, this.api) : super(const []) {
    refresh();
  }
  final String userId;
  final DeviceMaintenanceApi api;
  bool _loading = false;
  bool _again = false;
  Future<void> refresh() async {
    if (!mounted || AuthService().currentUser?.id != userId) return;
    if (_loading) {
      _again = true;
      return;
    }
    _loading = true;
    try {
      final result = await api.request('GET', '/due-reminders');
      if (mounted)
        state = List<Map<String, dynamic>>.from(result['items'] as List);
    } catch (_) {
      /* Keep pending warnings until the server confirms completion. */
    } finally {
      _loading = false;
      if (_again && mounted) {
        _again = false;
        await refresh();
      }
    }
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }
}

final maintenanceRemindersProvider = StateNotifierProvider.autoDispose
    .family<MaintenanceRemindersNotifier, List<Map<String, dynamic>>, String>(
        (ref, userId) =>
            MaintenanceRemindersNotifier(userId, DeviceMaintenanceApi()));
