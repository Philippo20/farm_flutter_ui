/// Farm Record Model - Daily farm activity tracking
/// Caretakers create records for monitoring and documentation
class FarmRecordModel {
  final String id;
  final String farmId;
  final String farmName;
  final String batchId;
  final String? batchNumber;
  final RecordType type;
  final DateTime recordDate;
  final String createdBy;
  final String createdByName;
  
  // Environmental readings
  final double? temperature;
  final double? humidity;
  final double? ph;
  final double? ec; // Electrical Conductivity
  final double? lightIntensity;
  
  // Plant observations
  final String? plantHealth;
  final String? growthStage;
  final int? plantCount;
  final String? observations;
  
  // Activities performed
  final List<String> activitiesPerformed;
  
  // Issues and concerns
  final bool hasIssues;
  final String? issueDescription;
  final IssueSeverity? issueSeverity;
  
  // Inputs used
  final List<InputUsed> inputsUsed;
  
  // Media attachments
  final List<String> photoUrls;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Notes
  final String? notes;

  FarmRecordModel({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.batchId,
    this.batchNumber,
    required this.type,
    required this.recordDate,
    required this.createdBy,
    required this.createdByName,
    this.temperature,
    this.humidity,
    this.ph,
    this.ec,
    this.lightIntensity,
    this.plantHealth,
    this.growthStage,
    this.plantCount,
    this.observations,
    this.activitiesPerformed = const [],
    this.hasIssues = false,
    this.issueDescription,
    this.issueSeverity,
    this.inputsUsed = const [],
    this.photoUrls = const [],
    required this.createdAt,
    this.updatedAt,
    this.notes,
  });

  /// Check if environmental readings are within normal range
  bool get hasAbnormalReadings {
    if (temperature != null && (temperature! < 18 || temperature! > 28)) return true;
    if (humidity != null && (humidity! < 50 || humidity! > 80)) return true;
    if (ph != null && (ph! < 5.5 || ph! > 6.5)) return true;
    if (ec != null && (ec! < 1.2 || ec! > 2.0)) return true;
    return false;
  }

  /// Check if record is recent (within 24 hours)
  bool get isRecent {
    return DateTime.now().difference(createdAt).inHours < 24;
  }

  /// Get time since record was created
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  /// From JSON
  factory FarmRecordModel.fromJson(Map<String, dynamic> json) {
    return FarmRecordModel(
      id: json['id'] as String,
      farmId: json['farmId'] as String,
      farmName: json['farmName'] as String,
      batchId: json['batchId'] as String,
      batchNumber: json['batchNumber'] as String?,
      type: RecordType.fromString(json['type'] as String),
      recordDate: DateTime.parse(json['recordDate'] as String),
      createdBy: json['createdBy'] as String,
      createdByName: json['createdByName'] as String,
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      ph: (json['ph'] as num?)?.toDouble(),
      ec: (json['ec'] as num?)?.toDouble(),
      lightIntensity: (json['lightIntensity'] as num?)?.toDouble(),
      plantHealth: json['plantHealth'] as String?,
      growthStage: json['growthStage'] as String?,
      plantCount: json['plantCount'] as int?,
      observations: json['observations'] as String?,
      activitiesPerformed: (json['activitiesPerformed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      hasIssues: json['hasIssues'] as bool? ?? false,
      issueDescription: json['issueDescription'] as String?,
      issueSeverity: json['issueSeverity'] != null
          ? IssueSeverity.fromString(json['issueSeverity'] as String)
          : null,
      inputsUsed: (json['inputsUsed'] as List<dynamic>?)
              ?.map((e) => InputUsed.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'farmName': farmName,
      'batchId': batchId,
      'batchNumber': batchNumber,
      'type': type.value,
      'recordDate': recordDate.toIso8601String(),
      'createdBy': createdBy,
      'createdByName': createdByName,
      'temperature': temperature,
      'humidity': humidity,
      'ph': ph,
      'ec': ec,
      'lightIntensity': lightIntensity,
      'plantHealth': plantHealth,
      'growthStage': growthStage,
      'plantCount': plantCount,
      'observations': observations,
      'activitiesPerformed': activitiesPerformed,
      'hasIssues': hasIssues,
      'issueDescription': issueDescription,
      'issueSeverity': issueSeverity?.value,
      'inputsUsed': inputsUsed.map((e) => e.toJson()).toList(),
      'photoUrls': photoUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  /// Copy with
  FarmRecordModel copyWith({
    String? id,
    String? farmId,
    String? farmName,
    String? batchId,
    String? batchNumber,
    RecordType? type,
    DateTime? recordDate,
    String? createdBy,
    String? createdByName,
    double? temperature,
    double? humidity,
    double? ph,
    double? ec,
    double? lightIntensity,
    String? plantHealth,
    String? growthStage,
    int? plantCount,
    String? observations,
    List<String>? activitiesPerformed,
    bool? hasIssues,
    String? issueDescription,
    IssueSeverity? issueSeverity,
    List<InputUsed>? inputsUsed,
    List<String>? photoUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return FarmRecordModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      batchId: batchId ?? this.batchId,
      batchNumber: batchNumber ?? this.batchNumber,
      type: type ?? this.type,
      recordDate: recordDate ?? this.recordDate,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      ph: ph ?? this.ph,
      ec: ec ?? this.ec,
      lightIntensity: lightIntensity ?? this.lightIntensity,
      plantHealth: plantHealth ?? this.plantHealth,
      growthStage: growthStage ?? this.growthStage,
      plantCount: plantCount ?? this.plantCount,
      observations: observations ?? this.observations,
      activitiesPerformed: activitiesPerformed ?? this.activitiesPerformed,
      hasIssues: hasIssues ?? this.hasIssues,
      issueDescription: issueDescription ?? this.issueDescription,
      issueSeverity: issueSeverity ?? this.issueSeverity,
      inputsUsed: inputsUsed ?? this.inputsUsed,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FarmRecordModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FarmRecordModel(id: $id, type: ${type.displayName}, farm: $farmName, date: $recordDate)';
  }
}

/// Record Type
enum RecordType {
  dailyMonitoring('daily_monitoring', 'Daily Monitoring', 'Regular daily check'),
  watering('watering', 'Watering', 'Watering activity'),
  feeding('feeding', 'Feeding/Nutrients', 'Nutrient application'),
  pruning('pruning', 'Pruning', 'Plant pruning'),
  transplanting('transplanting', 'Transplanting', 'Plant transplanting'),
  harvesting('harvesting', 'Harvesting', 'Harvest activity'),
  cleaning('cleaning', 'Cleaning', 'Cleaning and maintenance'),
  pestControl('pest_control', 'Pest Control', 'Pest management'),
  issue('issue', 'Issue Report', 'Problem or concern'),
  other('other', 'Other', 'Other activity');

  final String value;
  final String displayName;
  final String description;

  const RecordType(this.value, this.displayName, this.description);

  static RecordType fromString(String value) {
    return RecordType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => RecordType.other,
    );
  }

  /// Get record type color
  String get colorHex {
    switch (this) {
      case RecordType.dailyMonitoring:
        return '#4CAF50'; // Green
      case RecordType.watering:
        return '#2196F3'; // Blue
      case RecordType.feeding:
        return '#FF9800'; // Orange
      case RecordType.pruning:
        return '#9C27B0'; // Purple
      case RecordType.transplanting:
        return '#00BCD4'; // Cyan
      case RecordType.harvesting:
        return '#8BC34A'; // Light Green
      case RecordType.cleaning:
        return '#607D8B'; // Blue Grey
      case RecordType.pestControl:
        return '#F44336'; // Red
      case RecordType.issue:
        return '#FF5722'; // Deep Orange
      case RecordType.other:
        return '#9E9E9E'; // Grey
    }
  }
}

/// Issue Severity
enum IssueSeverity {
  low('low', 'Low', 'Minor issue'),
  medium('medium', 'Medium', 'Moderate concern'),
  high('high', 'High', 'Urgent attention needed'),
  critical('critical', 'Critical', 'Immediate action required');

  final String value;
  final String displayName;
  final String description;

  const IssueSeverity(this.value, this.displayName, this.description);

  static IssueSeverity fromString(String value) {
    return IssueSeverity.values.firstWhere(
      (severity) => severity.value == value,
      orElse: () => IssueSeverity.low,
    );
  }

  /// Get severity color
  String get colorHex {
    switch (this) {
      case IssueSeverity.low:
        return '#2196F3'; // Blue
      case IssueSeverity.medium:
        return '#FF9800'; // Orange
      case IssueSeverity.high:
        return '#FF5722'; // Deep Orange
      case IssueSeverity.critical:
        return '#F44336'; // Red
    }
  }
}

/// Input Used - Track inputs consumed in activities
class InputUsed {
  final String itemName;
  final double quantity;
  final String unit;
  final String? notes;

  InputUsed({
    required this.itemName,
    required this.quantity,
    required this.unit,
    this.notes,
  });

  factory InputUsed.fromJson(Map<String, dynamic> json) {
    return InputUsed(
      itemName: json['itemName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'notes': notes,
    };
  }
}

/// Common activities list
class CommonActivities {
  static const List<String> all = [
    'Checked water levels',
    'Adjusted pH',
    'Added nutrients',
    'Pruned dead leaves',
    'Checked for pests',
    'Cleaned grow beds',
    'Monitored temperature',
    'Checked humidity',
    'Inspected roots',
    'Recorded observations',
    'Watered plants',
    'Transplanted seedlings',
    'Harvested produce',
    'Applied pest control',
    'Cleaned equipment',
  ];
}
