/// Inventory Model - Farm inputs tracking
/// Tracks fertilizers, seeds, nutrients, and other farm supplies
class InventoryModel {
  final String id;
  final String itemName;
  final InventoryCategory category;
  final String unit; // kg, liters, pieces, bags, etc.
  final double quantity;
  final double minStockLevel;
  final double maxStockLevel;
  final double unitCost;
  final String? supplier;
  final String? batchNumber;
  final DateTime? expiryDate;
  final DateTime lastUpdated;
  final String? farmId; // If farm-specific, otherwise null for central inventory
  final String? notes;

  InventoryModel({
    required this.id,
    required this.itemName,
    required this.category,
    required this.unit,
    required this.quantity,
    this.minStockLevel = 0,
    this.maxStockLevel = 0,
    this.unitCost = 0,
    this.supplier,
    this.batchNumber,
    this.expiryDate,
    required this.lastUpdated,
    this.farmId,
    this.notes,
  });

  /// Check if stock is low
  bool get isLowStock => quantity <= minStockLevel;

  /// Check if stock is critical (below 50% of min level)
  bool get isCriticalStock => quantity <= (minStockLevel * 0.5);

  /// Check if stock is overstocked
  bool get isOverstocked => maxStockLevel > 0 && quantity >= maxStockLevel;

  /// Check if item is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// Check if item is expiring soon (within 30 days)
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry > 0 && daysUntilExpiry <= 30;
  }

  /// Get stock status
  StockStatus get stockStatus {
    if (isExpired) return StockStatus.expired;
    if (isCriticalStock) return StockStatus.critical;
    if (isLowStock) return StockStatus.low;
    if (isOverstocked) return StockStatus.overstocked;
    return StockStatus.normal;
  }

  /// Calculate total value
  double get totalValue => quantity * unitCost;

  /// Get days until expiry
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  /// From JSON
  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json['id'] as String,
      itemName: json['itemName'] as String,
      category: InventoryCategory.fromString(json['category'] as String),
      unit: json['unit'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      minStockLevel: (json['minStockLevel'] as num?)?.toDouble() ?? 0,
      maxStockLevel: (json['maxStockLevel'] as num?)?.toDouble() ?? 0,
      unitCost: (json['unitCost'] as num?)?.toDouble() ?? 0,
      supplier: json['supplier'] as String?,
      batchNumber: json['batchNumber'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      farmId: json['farmId'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemName': itemName,
      'category': category.value,
      'unit': unit,
      'quantity': quantity,
      'minStockLevel': minStockLevel,
      'maxStockLevel': maxStockLevel,
      'unitCost': unitCost,
      'supplier': supplier,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate?.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'farmId': farmId,
      'notes': notes,
    };
  }

  /// Copy with
  InventoryModel copyWith({
    String? id,
    String? itemName,
    InventoryCategory? category,
    String? unit,
    double? quantity,
    double? minStockLevel,
    double? maxStockLevel,
    double? unitCost,
    String? supplier,
    String? batchNumber,
    DateTime? expiryDate,
    DateTime? lastUpdated,
    String? farmId,
    String? notes,
  }) {
    return InventoryModel(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      maxStockLevel: maxStockLevel ?? this.maxStockLevel,
      unitCost: unitCost ?? this.unitCost,
      supplier: supplier ?? this.supplier,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      farmId: farmId ?? this.farmId,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'InventoryModel(itemName: $itemName, quantity: $quantity $unit, status: ${stockStatus.displayName})';
  }
}

/// Inventory Category
enum InventoryCategory {
  fertilizer('fertilizer', 'Fertilizer', 'Soil nutrients and fertilizers'),
  seeds('seeds', 'Seeds', 'Plant seeds and seedlings'),
  nutrients('nutrients', 'Nutrients', 'Hydroponic nutrients and solutions'),
  pesticides('pesticides', 'Pesticides', 'Pest control products'),
  equipment('equipment', 'Equipment', 'Farm equipment and tools'),
  packaging('packaging', 'Packaging', 'Packaging materials'),
  chemicals('chemicals', 'Chemicals', 'pH adjusters and other chemicals'),
  other('other', 'Other', 'Other supplies');

  final String value;
  final String displayName;
  final String description;

  const InventoryCategory(this.value, this.displayName, this.description);

  static InventoryCategory fromString(String value) {
    return InventoryCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => InventoryCategory.other,
    );
  }

  /// Get category color
  String get colorHex {
    switch (this) {
      case InventoryCategory.fertilizer:
        return '#8BC34A'; // Light Green
      case InventoryCategory.seeds:
        return '#4CAF50'; // Green
      case InventoryCategory.nutrients:
        return '#00BCD4'; // Cyan
      case InventoryCategory.pesticides:
        return '#FF9800'; // Orange
      case InventoryCategory.equipment:
        return '#607D8B'; // Blue Grey
      case InventoryCategory.packaging:
        return '#3F51B5'; // Indigo
      case InventoryCategory.chemicals:
        return '#9C27B0'; // Purple
      case InventoryCategory.other:
        return '#757575'; // Grey
    }
  }
}

/// Stock Status
enum StockStatus {
  normal('normal', 'Normal', 'Stock level is adequate'),
  low('low', 'Low Stock', 'Stock is below minimum level'),
  critical('critical', 'Critical', 'Stock is critically low'),
  overstocked('overstocked', 'Overstocked', 'Stock exceeds maximum level'),
  expired('expired', 'Expired', 'Item has expired');

  final String value;
  final String displayName;
  final String description;

  const StockStatus(this.value, this.displayName, this.description);

  /// Get status color
  String get colorHex {
    switch (this) {
      case StockStatus.normal:
        return '#4CAF50'; // Green
      case StockStatus.low:
        return '#FF9800'; // Orange
      case StockStatus.critical:
        return '#F44336'; // Red
      case StockStatus.overstocked:
        return '#2196F3'; // Blue
      case StockStatus.expired:
        return '#9E9E9E'; // Grey
    }
  }
}

/// Inventory Transaction - Track inventory movements
class InventoryTransaction {
  final String id;
  final String inventoryId;
  final String itemName;
  final TransactionType type;
  final double quantity;
  final String unit;
  final String? farmId;
  final String? batchNumber;
  final String performedBy;
  final String performedByName;
  final DateTime timestamp;
  final String? notes;
  final double? costPerUnit;

  InventoryTransaction({
    required this.id,
    required this.inventoryId,
    required this.itemName,
    required this.type,
    required this.quantity,
    required this.unit,
    this.farmId,
    this.batchNumber,
    required this.performedBy,
    required this.performedByName,
    required this.timestamp,
    this.notes,
    this.costPerUnit,
  });

  /// Calculate total cost
  double get totalCost => (costPerUnit ?? 0) * quantity;

  /// From JSON
  factory InventoryTransaction.fromJson(Map<String, dynamic> json) {
    return InventoryTransaction(
      id: json['id'] as String,
      inventoryId: json['inventoryId'] as String,
      itemName: json['itemName'] as String,
      type: TransactionType.fromString(json['type'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      farmId: json['farmId'] as String?,
      batchNumber: json['batchNumber'] as String?,
      performedBy: json['performedBy'] as String,
      performedByName: json['performedByName'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String?,
      costPerUnit: (json['costPerUnit'] as num?)?.toDouble(),
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventoryId': inventoryId,
      'itemName': itemName,
      'type': type.value,
      'quantity': quantity,
      'unit': unit,
      'farmId': farmId,
      'batchNumber': batchNumber,
      'performedBy': performedBy,
      'performedByName': performedByName,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'costPerUnit': costPerUnit,
    };
  }
}

/// Transaction Type
enum TransactionType {
  stockIn('stock_in', 'Stock In', 'Items added to inventory'),
  stockOut('stock_out', 'Stock Out', 'Items removed from inventory'),
  adjustment('adjustment', 'Adjustment', 'Inventory adjustment'),
  transfer('transfer', 'Transfer', 'Transfer between locations'),
  damaged('damaged', 'Damaged', 'Items marked as damaged'),
  expired('expired', 'Expired', 'Items marked as expired');

  final String value;
  final String displayName;
  final String description;

  const TransactionType(this.value, this.displayName, this.description);

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TransactionType.adjustment,
    );
  }

  /// Get transaction color
  String get colorHex {
    switch (this) {
      case TransactionType.stockIn:
        return '#4CAF50'; // Green
      case TransactionType.stockOut:
        return '#FF9800'; // Orange
      case TransactionType.adjustment:
        return '#2196F3'; // Blue
      case TransactionType.transfer:
        return '#9C27B0'; // Purple
      case TransactionType.damaged:
        return '#F44336'; // Red
      case TransactionType.expired:
        return '#9E9E9E'; // Grey
    }
  }
}
