import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/records/farm_record_model.dart';

/// Records State Notifier
/// Manages farm records data and operations
class RecordsNotifier extends StateNotifier<List<FarmRecordModel>> {
  RecordsNotifier() : super([]);

  /// Add a new record
  void addRecord(FarmRecordModel record) {
    state = [record, ...state]; // Add to beginning for chronological order
  }

  /// Update an existing record
  void updateRecord(FarmRecordModel updatedRecord) {
    state = [
      for (final record in state)
        if (record.id == updatedRecord.id) updatedRecord else record
    ];
  }

  /// Delete a record
  void deleteRecord(String recordId) {
    state = state.where((record) => record.id != recordId).toList();
  }

  /// Get record by ID
  FarmRecordModel? getRecordById(String id) {
    try {
      return state.firstWhere((record) => record.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get records by farm
  List<FarmRecordModel> getRecordsByFarm(String farmId) {
    return state.where((record) => record.farmId == farmId).toList();
  }

  /// Get records by batch
  List<FarmRecordModel> getRecordsByBatch(String batchId) {
    return state.where((record) => record.batchId == batchId).toList();
  }

  /// Get records by type
  List<FarmRecordModel> getRecordsByType(RecordType type) {
    return state.where((record) => record.type == type).toList();
  }

  /// Get today's records
  List<FarmRecordModel> getTodaysRecords() {
    final today = DateTime.now();
    return state.where((record) {
      final recordDate = record.recordDate;
      return recordDate.year == today.year &&
          recordDate.month == today.month &&
          recordDate.day == today.day;
    }).toList();
  }

  /// Get records with issues
  List<FarmRecordModel> getRecordsWithIssues() {
    return state.where((record) => record.hasIssues).toList();
  }

  /// Get records with abnormal readings
  List<FarmRecordModel> getRecordsWithAbnormalReadings() {
    return state.where((record) => record.hasAbnormalReadings).toList();
  }
}

/// Records Provider
final recordsProvider = StateNotifierProvider<RecordsNotifier, List<FarmRecordModel>>((ref) {
  return RecordsNotifier();
});

/// Today's Records Provider
final todaysRecordsProvider = Provider<List<FarmRecordModel>>((ref) {
  final records = ref.watch(recordsProvider);
  final today = DateTime.now();
  return records.where((record) {
    final recordDate = record.recordDate;
    return recordDate.year == today.year &&
        recordDate.month == today.month &&
        recordDate.day == today.day;
  }).toList();
});

/// Records with Issues Provider
final recordsWithIssuesProvider = Provider<List<FarmRecordModel>>((ref) {
  final records = ref.watch(recordsProvider);
  return records.where((record) => record.hasIssues).toList();
});

/// Records with Abnormal Readings Provider
final recordsWithAbnormalReadingsProvider = Provider<List<FarmRecordModel>>((ref) {
  final records = ref.watch(recordsProvider);
  return records.where((record) => record.hasAbnormalReadings).toList();
});

/// Total Records Count Provider
final recordsCountProvider = Provider<int>((ref) {
  return ref.watch(recordsProvider).length;
});

/// Today's Records Count Provider
final todaysRecordsCountProvider = Provider<int>((ref) {
  return ref.watch(todaysRecordsProvider).length;
});

/// Issues Count Provider
final issuesCountProvider = Provider<int>((ref) {
  return ref.watch(recordsWithIssuesProvider).length;
});
