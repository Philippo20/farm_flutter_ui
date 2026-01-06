import 'package:intl/intl.dart';

/// Batch Model - Core production tracking entity
/// Format: FA-20251001-20251101 (FarmPrefix-StartDate-EndDate)
class BatchModel {
  final String id;
  final String batchNumber; // Unique batch identifier
  final String farmId;
  final String farmName;
  final String farmManagerId;
  final String farmManagerName;
  final String plantType;
  final DateTime startDate;
  final DateTime endDate;
  final int plantMaturityDays;
  
  // Status tracking
  final BatchStatus status;
  
  // Production records
  final int nursedSeeds;
  final int transplantedPlants;
  final int harvestedHeads;
  final double harvestedWeight; // in kg
  
  // Caretaker info
  final String? caretakerId;
  final String? caretakerName;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? nurseryDate;
  final DateTime? transplantDate;
  final DateTime? harvestDate;
  final DateTime? packagedDate;
  final DateTime? deliveredDate;
  
  // Notes and metadata
  final String? notes;
  final Map<String, dynamic>? metadata;

  BatchModel({
    required this.id,
    required this.batchNumber,
    required this.farmId,
    required this.farmName,
    required this.farmManagerId,
    required this.farmManagerName,
    required this.plantType,
    required this.startDate,
    required this.endDate,
    required this.plantMaturityDays,
    this.status = BatchStatus.nursery,
    this.nursedSeeds = 0,
    this.transplantedPlants = 0,
    this.harvestedHeads = 0,
    this.harvestedWeight = 0.0,
    this.caretakerId,
    this.caretakerName,
    required this.createdAt,
    this.nurseryDate,
    this.transplantDate,
    this.harvestDate,
    this.packagedDate,
    this.deliveredDate,
    this.notes,
    this.metadata,
  });

  /// Generate unique batch number
  /// Format: FA-20251001-20251101
  static String generateBatchNumber(String farmName, DateTime start, DateTime end) {
    // Get first two letters of farm name
    final prefix = farmName.length >= 2 
        ? farmName.substring(0, 2).toUpperCase()
        : farmName.toUpperCase().padRight(2, 'X');
    
    // Format dates as YYYYMMDD
    final startStr = DateFormat('yyyyMMdd').format(start);
    final endStr = DateFormat('yyyyMMdd').format(end);
    
    return '$prefix-$startStr-$endStr';
  }

  /// Calculate expected harvest date
  DateTime get expectedHarvestDate {
    return startDate.add(Duration(days: plantMaturityDays));
  }

  /// Check if batch is overdue
  bool get isOverdue {
    if (status == BatchStatus.completed || status == BatchStatus.delivered) {
      return false;
    }
    return DateTime.now().isAfter(expectedHarvestDate);
  }

  /// Get days until harvest
  int get daysUntilHarvest {
    return expectedHarvestDate.difference(DateTime.now()).inDays;
  }

  /// Get days since start
  int get daysSinceStart {
    return DateTime.now().difference(startDate).inDays;
  }

  /// Calculate progress percentage
  double get progressPercentage {
    final totalDays = plantMaturityDays;
    final elapsedDays = daysSinceStart;
    return (elapsedDays / totalDays * 100).clamp(0, 100);
  }

  /// Calculate survival rate (transplanted / nursed)
  double get survivalRate {
    if (nursedSeeds == 0) return 0;
    return (transplantedPlants / nursedSeeds * 100);
  }

  /// Calculate harvest efficiency (harvested / transplanted)
  double get harvestEfficiency {
    if (transplantedPlants == 0) return 0;
    return (harvestedHeads / transplantedPlants * 100);
  }

  /// Check if batch is active
  bool get isActive {
    return status != BatchStatus.completed && 
           status != BatchStatus.delivered &&
           status != BatchStatus.cancelled;
  }

  /// Check if batch is ready for harvest
  bool get isReadyForHarvest {
    return status == BatchStatus.growing && 
           DateTime.now().isAfter(expectedHarvestDate.subtract(const Duration(days: 2)));
  }

  /// From JSON
  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id'] as String,
      batchNumber: json['batchNumber'] as String,
      farmId: json['farmId'] as String,
      farmName: json['farmName'] as String,
      farmManagerId: json['farmManagerId'] as String,
      farmManagerName: json['farmManagerName'] as String,
      plantType: json['plantType'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      plantMaturityDays: json['plantMaturityDays'] as int,
      status: BatchStatus.fromString(json['status'] as String? ?? 'nursery'),
      nursedSeeds: json['nursedSeeds'] as int? ?? 0,
      transplantedPlants: json['transplantedPlants'] as int? ?? 0,
      harvestedHeads: json['harvestedHeads'] as int? ?? 0,
      harvestedWeight: (json['harvestedWeight'] as num?)?.toDouble() ?? 0.0,
      caretakerId: json['caretakerId'] as String?,
      caretakerName: json['caretakerName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      nurseryDate: json['nurseryDate'] != null 
          ? DateTime.parse(json['nurseryDate'] as String) 
          : null,
      transplantDate: json['transplantDate'] != null 
          ? DateTime.parse(json['transplantDate'] as String) 
          : null,
      harvestDate: json['harvestDate'] != null 
          ? DateTime.parse(json['harvestDate'] as String) 
          : null,
      packagedDate: json['packagedDate'] != null 
          ? DateTime.parse(json['packagedDate'] as String) 
          : null,
      deliveredDate: json['deliveredDate'] != null 
          ? DateTime.parse(json['deliveredDate'] as String) 
          : null,
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batchNumber': batchNumber,
      'farmId': farmId,
      'farmName': farmName,
      'farmManagerId': farmManagerId,
      'farmManagerName': farmManagerName,
      'plantType': plantType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'plantMaturityDays': plantMaturityDays,
      'status': status.value,
      'nursedSeeds': nursedSeeds,
      'transplantedPlants': transplantedPlants,
      'harvestedHeads': harvestedHeads,
      'harvestedWeight': harvestedWeight,
      'caretakerId': caretakerId,
      'caretakerName': caretakerName,
      'createdAt': createdAt.toIso8601String(),
      'nurseryDate': nurseryDate?.toIso8601String(),
      'transplantDate': transplantDate?.toIso8601String(),
      'harvestDate': harvestDate?.toIso8601String(),
      'packagedDate': packagedDate?.toIso8601String(),
      'deliveredDate': deliveredDate?.toIso8601String(),
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// Copy with
  BatchModel copyWith({
    String? id,
    String? batchNumber,
    String? farmId,
    String? farmName,
    String? farmManagerId,
    String? farmManagerName,
    String? plantType,
    DateTime? startDate,
    DateTime? endDate,
    int? plantMaturityDays,
    BatchStatus? status,
    int? nursedSeeds,
    int? transplantedPlants,
    int? harvestedHeads,
    double? harvestedWeight,
    String? caretakerId,
    String? caretakerName,
    DateTime? createdAt,
    DateTime? nurseryDate,
    DateTime? transplantDate,
    DateTime? harvestDate,
    DateTime? packagedDate,
    DateTime? deliveredDate,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return BatchModel(
      id: id ?? this.id,
      batchNumber: batchNumber ?? this.batchNumber,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      farmManagerId: farmManagerId ?? this.farmManagerId,
      farmManagerName: farmManagerName ?? this.farmManagerName,
      plantType: plantType ?? this.plantType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      plantMaturityDays: plantMaturityDays ?? this.plantMaturityDays,
      status: status ?? this.status,
      nursedSeeds: nursedSeeds ?? this.nursedSeeds,
      transplantedPlants: transplantedPlants ?? this.transplantedPlants,
      harvestedHeads: harvestedHeads ?? this.harvestedHeads,
      harvestedWeight: harvestedWeight ?? this.harvestedWeight,
      caretakerId: caretakerId ?? this.caretakerId,
      caretakerName: caretakerName ?? this.caretakerName,
      createdAt: createdAt ?? this.createdAt,
      nurseryDate: nurseryDate ?? this.nurseryDate,
      transplantDate: transplantDate ?? this.transplantDate,
      harvestDate: harvestDate ?? this.harvestDate,
      packagedDate: packagedDate ?? this.packagedDate,
      deliveredDate: deliveredDate ?? this.deliveredDate,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BatchModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BatchModel(batchNumber: $batchNumber, farmName: $farmName, plantType: $plantType, status: ${status.displayName})';
  }
}

/// Batch Status Enum
enum BatchStatus {
  nursery('nursery', 'Nursery', 'Seeds in nursery stage'),
  transplanted('transplanted', 'Transplanted', 'Plants transplanted to grow beds'),
  growing('growing', 'Growing', 'Plants actively growing'),
  harvesting('harvesting', 'Harvesting', 'Harvest in progress'),
  harvested('harvested', 'Harvested', 'Harvest completed'),
  packaged('packaged', 'Packaged', 'Products packaged'),
  qualityChecked('quality_checked', 'Quality Checked', 'Passed quality inspection'),
  readyForSales('ready_for_sales', 'Ready for Sales', 'Ready for delivery'),
  delivered('delivered', 'Delivered', 'Delivered to customer'),
  completed('completed', 'Completed', 'Batch cycle completed'),
  cancelled('cancelled', 'Cancelled', 'Batch cancelled');

  final String value;
  final String displayName;
  final String description;

  const BatchStatus(this.value, this.displayName, this.description);

  static BatchStatus fromString(String value) {
    return BatchStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BatchStatus.nursery,
    );
  }

  /// Get status color
  String get colorHex {
    switch (this) {
      case BatchStatus.nursery:
        return '#8BC34A'; // Light Green
      case BatchStatus.transplanted:
        return '#4CAF50'; // Green
      case BatchStatus.growing:
        return '#009688'; // Teal
      case BatchStatus.harvesting:
        return '#FF9800'; // Orange
      case BatchStatus.harvested:
        return '#FF5722'; // Deep Orange
      case BatchStatus.packaged:
        return '#3F51B5'; // Indigo
      case BatchStatus.qualityChecked:
        return '#2196F3'; // Blue
      case BatchStatus.readyForSales:
        return '#00BCD4'; // Cyan
      case BatchStatus.delivered:
        return '#9C27B0'; // Purple
      case BatchStatus.completed:
        return '#4CAF50'; // Green
      case BatchStatus.cancelled:
        return '#F44336'; // Red
    }
  }
}

/// Plant Type with maturity days
class PlantType {
  final String name;
  final int maturityDays;
  final String category;
  final String? description;

  const PlantType({
    required this.name,
    required this.maturityDays,
    required this.category,
    this.description,
  });

  static const List<PlantType> all = [
    PlantType(name: 'Lettuce', maturityDays: 30, category: 'Leafy Greens'),
    PlantType(name: 'Spinach', maturityDays: 25, category: 'Leafy Greens'),
    PlantType(name: 'Kale', maturityDays: 35, category: 'Leafy Greens'),
    PlantType(name: 'Arugula', maturityDays: 20, category: 'Leafy Greens'),
    PlantType(name: 'Basil', maturityDays: 28, category: 'Herbs'),
    PlantType(name: 'Mint', maturityDays: 30, category: 'Herbs'),
    PlantType(name: 'Cilantro', maturityDays: 25, category: 'Herbs'),
    PlantType(name: 'Parsley', maturityDays: 30, category: 'Herbs'),
    PlantType(name: 'Tomatoes', maturityDays: 60, category: 'Fruits'),
    PlantType(name: 'Strawberries', maturityDays: 90, category: 'Fruits'),
    PlantType(name: 'Peppers', maturityDays: 70, category: 'Fruits'),
    PlantType(name: 'Cucumbers', maturityDays: 50, category: 'Fruits'),
    PlantType(name: 'Microgreens', maturityDays: 10, category: 'Microgreens'),
  ];

  static PlantType? getByName(String name) {
    try {
      return all.firstWhere((plant) => plant.name == name);
    } catch (e) {
      return null;
    }
  }

  static List<String> get allNames => all.map((p) => p.name).toList();
}
