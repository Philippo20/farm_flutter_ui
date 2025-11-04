import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/batch/batch_model.dart';

/// Batch State Notifier
/// Manages batch data and operations
class BatchNotifier extends StateNotifier<List<BatchModel>> {
  BatchNotifier() : super(_generateMockBatches());

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

  /// Generate mock batches for testing
  static List<BatchModel> _generateMockBatches() {
    final now = DateTime.now();
    return [
      BatchModel(
        id: '1',
        batchNumber: 'LE-20241101-20241201',
        farmId: 'farm1',
        farmName: 'Green Valley Farm',
        farmManagerId: 'manager1',
        farmManagerName: 'John Manager',
        plantType: 'Lettuce',
        plantMaturityDays: 30,
        status: BatchStatus.growing,
        startDate: now.subtract(const Duration(days: 15)),
        endDate: now.add(const Duration(days: 15)),
        nursedSeeds: 500,
        transplantedPlants: 480,
        harvestedHeads: 0,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      BatchModel(
        id: '2',
        batchNumber: 'TO-20241015-20241115',
        farmId: 'farm2',
        farmName: 'Sunny Acres',
        farmManagerId: 'manager1',
        farmManagerName: 'John Manager',
        plantType: 'Tomatoes',
        plantMaturityDays: 60,
        status: BatchStatus.harvesting,
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.add(const Duration(days: 30)),
        nursedSeeds: 300,
        transplantedPlants: 285,
        harvestedHeads: 0,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      BatchModel(
        id: '3',
        batchNumber: 'BA-20241110-20241208',
        farmId: 'farm3',
        farmName: 'Fresh Farms',
        farmManagerId: 'manager1',
        farmManagerName: 'John Manager',
        plantType: 'Basil',
        plantMaturityDays: 28,
        status: BatchStatus.nursery,
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 23)),
        nursedSeeds: 400,
        transplantedPlants: 0,
        harvestedHeads: 0,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];
  }
}

/// Batch Provider
final batchProvider = StateNotifierProvider<BatchNotifier, List<BatchModel>>((ref) {
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
