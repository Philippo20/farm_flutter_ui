import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/maintenance/maintenance_model.dart';

/// Maintenance State Notifier
/// Manages maintenance schedules and technical issues
class MaintenanceNotifier extends StateNotifier<List<MaintenanceModel>> {
  MaintenanceNotifier() : super([]);

  /// Add a new maintenance schedule
  void addMaintenance(MaintenanceModel maintenance) {
    state = [maintenance, ...state];
  }

  /// Update an existing maintenance
  void updateMaintenance(MaintenanceModel updatedMaintenance) {
    state = [
      for (final maintenance in state)
        if (maintenance.id == updatedMaintenance.id) updatedMaintenance else maintenance
    ];
  }

  /// Delete a maintenance
  void deleteMaintenance(String maintenanceId) {
    state = state.where((maintenance) => maintenance.id != maintenanceId).toList();
  }

  /// Get maintenance by ID
  MaintenanceModel? getMaintenanceById(String id) {
    try {
      return state.firstWhere((maintenance) => maintenance.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get maintenance by farm
  List<MaintenanceModel> getMaintenanceByFarm(String farmId) {
    return state.where((maintenance) => maintenance.farmId == farmId).toList();
  }

  /// Get maintenance by status
  List<MaintenanceModel> getMaintenanceByStatus(MaintenanceStatus status) {
    return state.where((maintenance) => maintenance.status == status).toList();
  }

  /// Get maintenance by priority
  List<MaintenanceModel> getMaintenanceByPriority(MaintenancePriority priority) {
    return state.where((maintenance) => maintenance.priority == priority).toList();
  }

  /// Get scheduled maintenance
  List<MaintenanceModel> getScheduledMaintenance() {
    return state.where((maintenance) => maintenance.status == MaintenanceStatus.scheduled).toList();
  }

  /// Get in-progress maintenance
  List<MaintenanceModel> getInProgressMaintenance() {
    return state.where((maintenance) => maintenance.isInProgress).toList();
  }

  /// Get overdue maintenance
  List<MaintenanceModel> getOverdueMaintenance() {
    return state.where((maintenance) => maintenance.isOverdue).toList();
  }

  /// Get due soon maintenance
  List<MaintenanceModel> getDueSoonMaintenance() {
    return state.where((maintenance) => maintenance.isDueSoon).toList();
  }

  /// Get today's maintenance
  List<MaintenanceModel> getTodaysMaintenance() {
    final today = DateTime.now();
    return state.where((maintenance) {
      final schedDate = maintenance.scheduledDate;
      return schedDate.year == today.year &&
          schedDate.month == today.month &&
          schedDate.day == today.day;
    }).toList();
  }
}

/// Technical Issues State Notifier
class TechnicalIssuesNotifier extends StateNotifier<List<TechnicalIssueModel>> {
  TechnicalIssuesNotifier() : super([]);

  /// Add a new issue
  void addIssue(TechnicalIssueModel issue) {
    state = [issue, ...state];
  }

  /// Update an existing issue
  void updateIssue(TechnicalIssueModel updatedIssue) {
    state = [
      for (final issue in state)
        if (issue.id == updatedIssue.id) updatedIssue else issue
    ];
  }

  /// Delete an issue
  void deleteIssue(String issueId) {
    state = state.where((issue) => issue.id != issueId).toList();
  }

  /// Get issue by ID
  TechnicalIssueModel? getIssueById(String id) {
    try {
      return state.firstWhere((issue) => issue.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get issues by farm
  List<TechnicalIssueModel> getIssuesByFarm(String farmId) {
    return state.where((issue) => issue.farmId == farmId).toList();
  }

  /// Get issues by severity
  List<TechnicalIssueModel> getIssuesBySeverity(IssueSeverity severity) {
    return state.where((issue) => issue.severity == severity).toList();
  }

  /// Get issues by status
  List<TechnicalIssueModel> getIssuesByStatus(IssueStatus status) {
    return state.where((issue) => issue.status == status).toList();
  }

  /// Get open issues
  List<TechnicalIssueModel> getOpenIssues() {
    return state.where((issue) => issue.isOpen).toList();
  }

  /// Get critical issues
  List<TechnicalIssueModel> getCriticalIssues() {
    return state.where((issue) => issue.isCritical).toList();
  }

  /// Get issues affecting production
  List<TechnicalIssueModel> getProductionAffectingIssues() {
    return state.where((issue) => issue.affectsProduction).toList();
  }
}

/// Maintenance Provider
final maintenanceProvider = StateNotifierProvider<MaintenanceNotifier, List<MaintenanceModel>>((ref) {
  return MaintenanceNotifier();
});

/// Technical Issues Provider
final technicalIssuesProvider = StateNotifierProvider<TechnicalIssuesNotifier, List<TechnicalIssueModel>>((ref) {
  return TechnicalIssuesNotifier();
});

/// Scheduled Maintenance Provider
final scheduledMaintenanceProvider = Provider<List<MaintenanceModel>>((ref) {
  final maintenance = ref.watch(maintenanceProvider);
  return maintenance.where((m) => m.status == MaintenanceStatus.scheduled).toList();
});

/// In Progress Maintenance Provider
final inProgressMaintenanceProvider = Provider<List<MaintenanceModel>>((ref) {
  final maintenance = ref.watch(maintenanceProvider);
  return maintenance.where((m) => m.isInProgress).toList();
});

/// Overdue Maintenance Provider
final overdueMaintenanceProvider = Provider<List<MaintenanceModel>>((ref) {
  final maintenance = ref.watch(maintenanceProvider);
  return maintenance.where((m) => m.isOverdue).toList();
});

/// Due Soon Maintenance Provider
final dueSoonMaintenanceProvider = Provider<List<MaintenanceModel>>((ref) {
  final maintenance = ref.watch(maintenanceProvider);
  return maintenance.where((m) => m.isDueSoon).toList();
});

/// Today's Maintenance Provider
final todaysMaintenanceProvider = Provider<List<MaintenanceModel>>((ref) {
  final maintenance = ref.watch(maintenanceProvider);
  final today = DateTime.now();
  return maintenance.where((m) {
    final schedDate = m.scheduledDate;
    return schedDate.year == today.year &&
        schedDate.month == today.month &&
        schedDate.day == today.day;
  }).toList();
});

/// Open Issues Provider
final openIssuesProvider = Provider<List<TechnicalIssueModel>>((ref) {
  final issues = ref.watch(technicalIssuesProvider);
  return issues.where((issue) => issue.isOpen).toList();
});

/// Critical Issues Provider
final criticalIssuesProvider = Provider<List<TechnicalIssueModel>>((ref) {
  final issues = ref.watch(technicalIssuesProvider);
  return issues.where((issue) => issue.isCritical).toList();
});

/// Production Affecting Issues Provider
final productionAffectingIssuesProvider = Provider<List<TechnicalIssueModel>>((ref) {
  final issues = ref.watch(technicalIssuesProvider);
  return issues.where((issue) => issue.affectsProduction).toList();
});

/// Maintenance Count Provider
final maintenanceCountProvider = Provider<int>((ref) {
  return ref.watch(maintenanceProvider).length;
});

/// Open Issues Count Provider
final openIssuesCountProvider = Provider<int>((ref) {
  return ref.watch(openIssuesProvider).length;
});

/// Critical Issues Count Provider
final criticalIssuesCountProvider = Provider<int>((ref) {
  return ref.watch(criticalIssuesProvider).length;
});
