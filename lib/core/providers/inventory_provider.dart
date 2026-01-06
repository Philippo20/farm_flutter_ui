import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory/inventory_model.dart';

/// Inventory State Notifier
/// Manages inventory data and operations
class InventoryNotifier extends StateNotifier<List<InventoryModel>> {
  InventoryNotifier() : super(_generateMockInventory());

  /// Add a new inventory item
  void addItem(InventoryModel item) {
    state = [...state, item];
  }

  /// Update an existing item
  void updateItem(InventoryModel updatedItem) {
    state = [
      for (final item in state)
        if (item.id == updatedItem.id) updatedItem else item
    ];
  }

  /// Delete an item
  void deleteItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }

  /// Stock in - increase quantity
  void stockIn(String itemId, double quantityToAdd) {
    final item = state.firstWhere((i) => i.id == itemId);
    final updatedItem = item.copyWith(
      quantity: item.quantity + quantityToAdd,
      lastUpdated: DateTime.now(),
    );
    updateItem(updatedItem);
  }

  /// Stock out - decrease quantity
  void stockOut(String itemId, double quantityToRemove) {
    final item = state.firstWhere((i) => i.id == itemId);
    final updatedItem = item.copyWith(
      quantity: item.quantity - quantityToRemove,
      lastUpdated: DateTime.now(),
    );
    updateItem(updatedItem);
  }

  /// Get item by ID
  InventoryModel? getItemById(String id) {
    try {
      return state.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get items by category
  List<InventoryModel> getItemsByCategory(InventoryCategory category) {
    return state.where((item) => item.category == category).toList();
  }

  /// Get low stock items
  List<InventoryModel> getLowStockItems() {
    return state.where((item) => item.isLowStock).toList();
  }

  /// Get out of stock items
  List<InventoryModel> getOutOfStockItems() {
    return state.where((item) => item.quantity == 0).toList();
  }

  /// Get expiring soon items
  List<InventoryModel> getExpiringSoonItems() {
    return state.where((item) => item.isExpiringSoon).toList();
  }

  /// Generate mock inventory for testing
  static List<InventoryModel> _generateMockInventory() {
    final now = DateTime.now();
    return [
      InventoryModel(
        id: '1',
        itemName: 'Lettuce Seeds (Buttercrunch)',
        category: InventoryCategory.seeds,
        unit: 'kg',
        quantity: 8.0,
        minStockLevel: 10.0,
        maxStockLevel: 50.0,
        unitCost: 150.0,
        expiryDate: now.add(const Duration(days: 365)),
        supplier: 'Premium Seeds Ltd',
        lastUpdated: now.subtract(const Duration(days: 60)),
      ),
      InventoryModel(
        id: '2',
        itemName: 'Tomato Seeds (Cherry)',
        category: InventoryCategory.seeds,
        unit: 'kg',
        quantity: 25.0,
        minStockLevel: 15.0,
        maxStockLevel: 50.0,
        unitCost: 120.0,
        expiryDate: now.add(const Duration(days: 180)),
        supplier: 'Premium Seeds Ltd',
        lastUpdated: now.subtract(const Duration(days: 45)),
      ),
      InventoryModel(
        id: '3',
        itemName: 'Calcium Nitrate',
        category: InventoryCategory.nutrients,
        unit: 'kg',
        quantity: 0.0,
        minStockLevel: 15.0,
        maxStockLevel: 80.0,
        unitCost: 18.0,
        expiryDate: now.add(const Duration(days: 450)),
        supplier: 'Hydro Nutrients Inc',
        lastUpdated: now.subtract(const Duration(days: 90)),
      ),
      InventoryModel(
        id: '4',
        itemName: 'pH Down Solution',
        category: InventoryCategory.nutrients,
        unit: 'L',
        quantity: 12.5,
        minStockLevel: 5.0,
        maxStockLevel: 30.0,
        unitCost: 35.0,
        expiryDate: now.add(const Duration(days: 270)),
        supplier: 'Hydro Nutrients Inc',
        lastUpdated: now.subtract(const Duration(days: 30)),
      ),
      InventoryModel(
        id: '5',
        itemName: 'Neem Oil (Organic Pesticide)',
        category: InventoryCategory.pesticides,
        unit: 'L',
        quantity: 3.2,
        minStockLevel: 5.0,
        maxStockLevel: 20.0,
        unitCost: 45.0,
        expiryDate: now.add(const Duration(days: 120)),
        supplier: 'Organic Solutions',
        lastUpdated: now.subtract(const Duration(days: 75)),
      ),
      InventoryModel(
        id: '6',
        itemName: 'Pruning Shears',
        category: InventoryCategory.equipment,
        unit: 'pcs',
        quantity: 8.0,
        minStockLevel: 5.0,
        maxStockLevel: 15.0,
        unitCost: 25.0,
        supplier: 'Farm Tools Direct',
        lastUpdated: now.subtract(const Duration(days: 120)),
      ),
    ];
  }
}

/// Inventory Provider
final inventoryProvider = StateNotifierProvider<InventoryNotifier, List<InventoryModel>>((ref) {
  return InventoryNotifier();
});

/// Low Stock Items Provider
final lowStockItemsProvider = Provider<List<InventoryModel>>((ref) {
  final inventory = ref.watch(inventoryProvider);
  return inventory.where((item) => item.isLowStock).toList();
});

/// Out of Stock Items Provider
final outOfStockItemsProvider = Provider<List<InventoryModel>>((ref) {
  final inventory = ref.watch(inventoryProvider);
  return inventory.where((item) => item.quantity == 0).toList();
});

/// Expiring Soon Items Provider
final expiringSoonItemsProvider = Provider<List<InventoryModel>>((ref) {
  final inventory = ref.watch(inventoryProvider);
  return inventory.where((item) => item.isExpiringSoon).toList();
});

/// Total Inventory Value Provider
final totalInventoryValueProvider = Provider<double>((ref) {
  final inventory = ref.watch(inventoryProvider);
  return inventory.fold(0.0, (sum, item) => sum + item.totalValue);
});

/// Inventory Count Provider
final inventoryCountProvider = Provider<int>((ref) {
  return ref.watch(inventoryProvider).length;
});

/// Low Stock Count Provider
final lowStockCountProvider = Provider<int>((ref) {
  return ref.watch(lowStockItemsProvider).length;
});

/// Out of Stock Count Provider
final outOfStockCountProvider = Provider<int>((ref) {
  return ref.watch(outOfStockItemsProvider).length;
});
