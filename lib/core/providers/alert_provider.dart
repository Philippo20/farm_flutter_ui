import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock_farm_data.dart';
import '../../models/alert_model.dart';
import '../../models/enums.dart';

/// Alert State
class AlertState {
  final List<AlertModel> alerts;
  final bool isLoading;
  final String? error;

  AlertState({
    required this.alerts,
    this.isLoading = false,
    this.error,
  });

  AlertState copyWith({
    List<AlertModel>? alerts,
    bool? isLoading,
    String? error,
  }) {
    return AlertState(
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Computed properties
  List<AlertModel> get activeAlerts => alerts.where((a) => a.isActive).toList();
  List<AlertModel> get criticalAlerts => alerts.where((a) => a.isCritical && a.isActive).toList();
  int get activeCount => activeAlerts.length;
  int get criticalCount => criticalAlerts.length;
  
  Map<String, int> get stats {
    final active = activeAlerts;
    return {
      'total': alerts.length,
      'active': active.length,
      'resolved': alerts.where((a) => a.resolved).length,
      'critical': active.where((a) => a.severity == AlertSeverity.high).length,
      'warning': active.where((a) => a.severity == AlertSeverity.medium).length,
      'info': active.where((a) => a.severity == AlertSeverity.low).length,
    };
  }
}

/// Alert Notifier
class AlertNotifier extends StateNotifier<AlertState> {
  AlertNotifier() : super(AlertState(alerts: [])) {
    loadAlerts();
  }

  /// Load all alerts
  Future<void> loadAlerts() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      final alerts = MockFarmData.getAllAlerts();
      state = state.copyWith(
        alerts: alerts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh alerts
  Future<void> refreshAlerts() async {
    await loadAlerts();
  }

  /// Resolve an alert
  Future<void> resolveAlert(String alertId, String resolvedBy) async {
    try {
      final index = state.alerts.indexWhere((a) => a.id == alertId);
      if (index == -1) return;

      final updatedAlerts = List<AlertModel>.from(state.alerts);
      updatedAlerts[index] = updatedAlerts[index].copyWith(
        resolved: true,
        resolvedAt: DateTime.now(),
        resolvedBy: resolvedBy,
      );

      state = state.copyWith(alerts: updatedAlerts);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Dismiss an alert
  Future<void> dismissAlert(String alertId) async {
    try {
      final updatedAlerts = state.alerts.where((a) => a.id != alertId).toList();
      state = state.copyWith(alerts: updatedAlerts);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Filter alerts by severity
  List<AlertModel> filterBySeverity(AlertSeverity severity) {
    return state.activeAlerts.where((a) => a.severity == severity).toList();
  }

  /// Filter alerts by sensor type
  List<AlertModel> filterBySensorType(SensorType sensorType) {
    return state.activeAlerts.where((a) => a.sensorType == sensorType).toList();
  }

  /// Get alerts from today
  List<AlertModel> getTodayAlerts() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return state.activeAlerts.where((a) {
      final alertDate = DateTime(a.timestamp.year, a.timestamp.month, a.timestamp.day);
      return alertDate == today;
    }).toList();
  }
}

/// Alert Provider
final alertProvider = StateNotifierProvider<AlertNotifier, AlertState>((ref) {
  return AlertNotifier();
});

/// Active Alerts Count Provider
final activeAlertsCountProvider = Provider<int>((ref) {
  final alertState = ref.watch(alertProvider);
  return alertState.activeCount;
});

/// Critical Alerts Count Provider
final criticalAlertsCountProvider = Provider<int>((ref) {
  final alertState = ref.watch(alertProvider);
  return alertState.criticalCount;
});

/// Alert Stats Provider
final alertStatsProvider = Provider<Map<String, int>>((ref) {
  final alertState = ref.watch(alertProvider);
  return alertState.stats;
});

/// Has Critical Alerts Provider
final hasCriticalAlertsProvider = Provider<bool>((ref) {
  final alertState = ref.watch(alertProvider);
  return alertState.criticalCount > 0;
});
