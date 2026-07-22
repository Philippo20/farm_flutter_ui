import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/batch/batch_model.dart';

/// Batch State Notifier
/// Manages batch data and operations
class BatchNotifier extends StateNotifier<List<BatchModel>> {
  BatchNotifier() : super(const []);

  /// Replace all batches from the backend.
  void setBatches(List<BatchModel> batches) {
    state = batches;
  }

  /// Add a new batch
  void addBatch(BatchModel batch) {
    state = [...state, batch];
  }

  /// Update an existing batch
  void updateBatch(BatchModel updatedBatch) {
    state = [
      for (final batch in state)
        if (batch.id == updatedBatch.id) updatedBatch else batch
    ];
  }

  /// Delete a batch
  void deleteBatch(String batchId) {
    state = state.where((batch) => batch.id != batchId).toList();
  }

  /// Get batch by ID
  BatchModel? getBatchById(String id) {
    try {
      return state.firstWhere((batch) => batch.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get batches by farm
  List<BatchModel> getBatchesByFarm(String farmId) {
    return state.where((batch) => batch.farmId == farmId).toList();
  }

  /// Get batches by status
  List<BatchModel> getBatchesByStatus(BatchStatus status) {
    return state.where((batch) => batch.status == status).toList();
  }

  /// Get active batches
  List<BatchModel> getActiveBatches() {
    return state.where((batch) => batch.isActive).toList();
  }

  /// Get overdue batches
  List<BatchModel> getOverdueBatches() {
    return state.where((batch) => batch.isOverdue).toList();
  }
}

/// Batch Provider
final batchProvider =
    StateNotifierProvider<BatchNotifier, List<BatchModel>>((ref) {
  return BatchNotifier();
});

/// Active Batches Provider
final activeBatchesProvider = Provider<List<BatchModel>>((ref) {
  final batches = ref.watch(batchProvider);
  return batches.where((batch) => batch.isActive).toList();
});

/// Overdue Batches Provider
final overdueBatchesProvider = Provider<List<BatchModel>>((ref) {
  final batches = ref.watch(batchProvider);
  return batches.where((batch) => batch.isOverdue).toList();
});

/// Batch Count Provider
final batchCountProvider = Provider<int>((ref) {
  return ref.watch(batchProvider).length;
});

/// Active Batch Count Provider
final activeBatchCountProvider = Provider<int>((ref) {
  return ref.watch(activeBatchesProvider).length;
});
