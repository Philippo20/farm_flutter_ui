/// Maintenance Model - Equipment and system maintenance tracking
class MaintenanceModel {
  final String id;
  final String farmId;
  final String farmName;
  final MaintenanceType type;
  final String equipmentName;
  final String? equipmentId;
  final MaintenanceStatus status;
  final MaintenancePriority priority;
  
  // Schedule
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final String? frequency; // daily, weekly, monthly, quarterly
  final DateTime? nextDueDate;
  
  // Assignment
  final String? assignedTo;
  final String? assignedToName;
  final String createdBy;
  final String createdByName;
  
  // Details
  final String description;
  final List<String> tasksToPerform;
  final List<String> partsNeeded;
  final double? estimatedCost;
  final double? actualCost;
  final int? estimatedDuration; // in minutes
  final int? actualDuration; // in minutes
  
  // Results
  final String? completionNotes;
  final List<String> photoUrls;
  final bool requiresFollowUp;
  final String? followUpNotes;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;

  MaintenanceModel({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.type,
    required this.equipmentName,
    this.equipmentId,
    required this.status,
    required this.priority,
    required this.scheduledDate,
    this.completedDate,
    this.frequency,
    this.nextDueDate,
    this.assignedTo,
    this.assignedToName,
    required this.createdBy,
    required this.createdByName,
    required this.description,
    this.tasksToPerform = const [],
    this.partsNeeded = const [],
    this.estimatedCost,
    this.actualCost,
    this.estimatedDuration,
    this.actualDuration,
    this.completionNotes,
    this.photoUrls = const [],
    this.requiresFollowUp = false,
    this.followUpNotes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if maintenance is overdue
  bool get isOverdue {
    if (status == MaintenanceStatus.completed || status == MaintenanceStatus.cancelled) {
      return false;
    }
    return DateTime.now().isAfter(scheduledDate);
  }

  /// Check if maintenance is due soon (within 3 days)
  bool get isDueSoon {
    if (status == MaintenanceStatus.completed || status == MaintenanceStatus.cancelled) {
      return false;
    }
    final daysUntil = scheduledDate.difference(DateTime.now()).inDays;
    return daysUntil >= 0 && daysUntil <= 3;
  }

  /// Get days until scheduled date
  int get daysUntilDue {
    return scheduledDate.difference(DateTime.now()).inDays;
  }

  /// Check if maintenance is in progress
  bool get isInProgress {
    return status == MaintenanceStatus.inProgress;
  }

  /// Check if maintenance is pending
  bool get isPending {
    return status == MaintenanceStatus.scheduled;
  }

  /// Get time since creation
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  /// From JSON
  factory MaintenanceModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceModel(
      id: json['id'] as String,
      farmId: json['farmId'] as String,
      farmName: json['farmName'] as String,
      type: MaintenanceType.fromString(json['type'] as String),
      equipmentName: json['equipmentName'] as String,
      equipmentId: json['equipmentId'] as String?,
      status: MaintenanceStatus.fromString(json['status'] as String),
      priority: MaintenancePriority.fromString(json['priority'] as String),
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      frequency: json['frequency'] as String?,
      nextDueDate: json['nextDueDate'] != null
          ? DateTime.parse(json['nextDueDate'] as String)
          : null,
      assignedTo: json['assignedTo'] as String?,
      assignedToName: json['assignedToName'] as String?,
      createdBy: json['createdBy'] as String,
      createdByName: json['createdByName'] as String,
      description: json['description'] as String,
      tasksToPerform: (json['tasksToPerform'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      partsNeeded: (json['partsNeeded'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
      actualCost: (json['actualCost'] as num?)?.toDouble(),
      estimatedDuration: json['estimatedDuration'] as int?,
      actualDuration: json['actualDuration'] as int?,
      completionNotes: json['completionNotes'] as String?,
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      requiresFollowUp: json['requiresFollowUp'] as bool? ?? false,
      followUpNotes: json['followUpNotes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'farmName': farmName,
      'type': type.value,
      'equipmentName': equipmentName,
      'equipmentId': equipmentId,
      'status': status.value,
      'priority': priority.value,
      'scheduledDate': scheduledDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'frequency': frequency,
      'nextDueDate': nextDueDate?.toIso8601String(),
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'description': description,
      'tasksToPerform': tasksToPerform,
      'partsNeeded': partsNeeded,
      'estimatedCost': estimatedCost,
      'actualCost': actualCost,
      'estimatedDuration': estimatedDuration,
      'actualDuration': actualDuration,
      'completionNotes': completionNotes,
      'photoUrls': photoUrls,
      'requiresFollowUp': requiresFollowUp,
      'followUpNotes': followUpNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Copy with
  MaintenanceModel copyWith({
    String? id,
    String? farmId,
    String? farmName,
    MaintenanceType? type,
    String? equipmentName,
    String? equipmentId,
    MaintenanceStatus? status,
    MaintenancePriority? priority,
    DateTime? scheduledDate,
    DateTime? completedDate,
    String? frequency,
    DateTime? nextDueDate,
    String? assignedTo,
    String? assignedToName,
    String? createdBy,
    String? createdByName,
    String? description,
    List<String>? tasksToPerform,
    List<String>? partsNeeded,
    double? estimatedCost,
    double? actualCost,
    int? estimatedDuration,
    int? actualDuration,
    String? completionNotes,
    List<String>? photoUrls,
    bool? requiresFollowUp,
    String? followUpNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      type: type ?? this.type,
      equipmentName: equipmentName ?? this.equipmentName,
      equipmentId: equipmentId ?? this.equipmentId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      description: description ?? this.description,
      tasksToPerform: tasksToPerform ?? this.tasksToPerform,
      partsNeeded: partsNeeded ?? this.partsNeeded,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualCost: actualCost ?? this.actualCost,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      completionNotes: completionNotes ?? this.completionNotes,
      photoUrls: photoUrls ?? this.photoUrls,
      requiresFollowUp: requiresFollowUp ?? this.requiresFollowUp,
      followUpNotes: followUpNotes ?? this.followUpNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaintenanceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MaintenanceModel(id: $id, type: ${type.displayName}, equipment: $equipmentName, status: ${status.displayName})';
  }
}

/// Maintenance Type
enum MaintenanceType {
  preventive('preventive', 'Preventive', 'Scheduled preventive maintenance'),
  corrective('corrective', 'Corrective', 'Fix existing issues'),
  inspection('inspection', 'Inspection', 'Regular inspection'),
  calibration('calibration', 'Calibration', 'Equipment calibration'),
  cleaning('cleaning', 'Cleaning', 'Cleaning and sanitation'),
  replacement('replacement', 'Replacement', 'Part replacement'),
  upgrade('upgrade', 'Upgrade', 'System upgrade'),
  emergency('emergency', 'Emergency', 'Emergency repair');

  final String value;
  final String displayName;
  final String description;

  const MaintenanceType(this.value, this.displayName, this.description);

  static MaintenanceType fromString(String value) {
    return MaintenanceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MaintenanceType.preventive,
    );
  }

  /// Get type color
  String get colorHex {
    switch (this) {
      case MaintenanceType.preventive:
        return '#4CAF50'; // Green
      case MaintenanceType.corrective:
        return '#FF9800'; // Orange
      case MaintenanceType.inspection:
        return '#2196F3'; // Blue
      case MaintenanceType.calibration:
        return '#9C27B0'; // Purple
      case MaintenanceType.cleaning:
        return '#00BCD4'; // Cyan
      case MaintenanceType.replacement:
        return '#FF5722'; // Deep Orange
      case MaintenanceType.upgrade:
        return '#8BC34A'; // Light Green
      case MaintenanceType.emergency:
        return '#F44336'; // Red
    }
  }
}

/// Maintenance Status
enum MaintenanceStatus {
  scheduled('scheduled', 'Scheduled', 'Scheduled for future'),
  inProgress('in_progress', 'In Progress', 'Currently being performed'),
  completed('completed', 'Completed', 'Successfully completed'),
  cancelled('cancelled', 'Cancelled', 'Cancelled'),
  onHold('on_hold', 'On Hold', 'Temporarily on hold');

  final String value;
  final String displayName;
  final String description;

  const MaintenanceStatus(this.value, this.displayName, this.description);

  static MaintenanceStatus fromString(String value) {
    return MaintenanceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MaintenanceStatus.scheduled,
    );
  }

  /// Get status color
  String get colorHex {
    switch (this) {
      case MaintenanceStatus.scheduled:
        return '#2196F3'; // Blue
      case MaintenanceStatus.inProgress:
        return '#FF9800'; // Orange
      case MaintenanceStatus.completed:
        return '#4CAF50'; // Green
      case MaintenanceStatus.cancelled:
        return '#9E9E9E'; // Grey
      case MaintenanceStatus.onHold:
        return '#FF5722'; // Deep Orange
    }
  }
}

/// Maintenance Priority
enum MaintenancePriority {
  low('low', 'Low', 'Can be scheduled flexibly'),
  medium('medium', 'Medium', 'Should be done soon'),
  high('high', 'High', 'Needs attention'),
  critical('critical', 'Critical', 'Urgent - affects operations');

  final String value;
  final String displayName;
  final String description;

  const MaintenancePriority(this.value, this.displayName, this.description);

  static MaintenancePriority fromString(String value) {
    return MaintenancePriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => MaintenancePriority.medium,
    );
  }

  /// Get priority color
  String get colorHex {
    switch (this) {
      case MaintenancePriority.low:
        return '#4CAF50'; // Green
      case MaintenancePriority.medium:
        return '#2196F3'; // Blue
      case MaintenancePriority.high:
        return '#FF9800'; // Orange
      case MaintenancePriority.critical:
        return '#F44336'; // Red
    }
  }
}

/// Technical Issue Model - Track equipment and system issues
class TechnicalIssueModel {
  final String id;
  final String farmId;
  final String farmName;
  final String title;
  final String description;
  final IssueCategory category;
  final IssueSeverity severity;
  final IssueStatus status;
  
  // Equipment details
  final String? equipmentName;
  final String? equipmentId;
  final String? location;
  
  // Assignment
  final String reportedBy;
  final String reportedByName;
  final String? assignedTo;
  final String? assignedToName;
  
  // Resolution
  final DateTime reportedAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final List<String> actionsTaken;
  
  // Media
  final List<String> photoUrls;
  
  // Impact
  final bool affectsProduction;
  final String? impactDescription;

  TechnicalIssueModel({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.status,
    this.equipmentName,
    this.equipmentId,
    this.location,
    required this.reportedBy,
    required this.reportedByName,
    this.assignedTo,
    this.assignedToName,
    required this.reportedAt,
    this.acknowledgedAt,
    this.resolvedAt,
    this.resolutionNotes,
    this.actionsTaken = const [],
    this.photoUrls = const [],
    this.affectsProduction = false,
    this.impactDescription,
  });

  /// Check if issue is open
  bool get isOpen {
    return status != IssueStatus.resolved && status != IssueStatus.closed;
  }

  /// Check if issue is critical
  bool get isCritical {
    return severity == IssueSeverity.critical;
  }

  /// Get time since reported
  String get timeAgo {
    final diff = DateTime.now().difference(reportedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  /// From JSON
  factory TechnicalIssueModel.fromJson(Map<String, dynamic> json) {
    return TechnicalIssueModel(
      id: json['id'] as String,
      farmId: json['farmId'] as String,
      farmName: json['farmName'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: IssueCategory.fromString(json['category'] as String),
      severity: IssueSeverity.fromString(json['severity'] as String),
      status: IssueStatus.fromString(json['status'] as String),
      equipmentName: json['equipmentName'] as String?,
      equipmentId: json['equipmentId'] as String?,
      location: json['location'] as String?,
      reportedBy: json['reportedBy'] as String,
      reportedByName: json['reportedByName'] as String,
      assignedTo: json['assignedTo'] as String?,
      assignedToName: json['assignedToName'] as String?,
      reportedAt: DateTime.parse(json['reportedAt'] as String),
      acknowledgedAt: json['acknowledgedAt'] != null
          ? DateTime.parse(json['acknowledgedAt'] as String)
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      resolutionNotes: json['resolutionNotes'] as String?,
      actionsTaken: (json['actionsTaken'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      affectsProduction: json['affectsProduction'] as bool? ?? false,
      impactDescription: json['impactDescription'] as String?,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'farmName': farmName,
      'title': title,
      'description': description,
      'category': category.value,
      'severity': severity.value,
      'status': status.value,
      'equipmentName': equipmentName,
      'equipmentId': equipmentId,
      'location': location,
      'reportedBy': reportedBy,
      'reportedByName': reportedByName,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'reportedAt': reportedAt.toIso8601String(),
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolutionNotes': resolutionNotes,
      'actionsTaken': actionsTaken,
      'photoUrls': photoUrls,
      'affectsProduction': affectsProduction,
      'impactDescription': impactDescription,
    };
  }
}

/// Issue Category
enum IssueCategory {
  electrical('electrical', 'Electrical', 'Electrical system issues'),
  plumbing('plumbing', 'Plumbing', 'Water system issues'),
  hvac('hvac', 'HVAC', 'Climate control issues'),
  lighting('lighting', 'Lighting', 'Lighting system issues'),
  irrigation('irrigation', 'Irrigation', 'Irrigation system issues'),
  sensors('sensors', 'Sensors', 'Sensor malfunction'),
  structural('structural', 'Structural', 'Building/structure issues'),
  equipment('equipment', 'Equipment', 'Equipment malfunction'),
  other('other', 'Other', 'Other technical issues');

  final String value;
  final String displayName;
  final String description;

  const IssueCategory(this.value, this.displayName, this.description);

  static IssueCategory fromString(String value) {
    return IssueCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => IssueCategory.other,
    );
  }
}

/// Issue Severity (reusing from farm_record_model.dart)
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

  String get colorHex {
    switch (this) {
      case IssueSeverity.low:
        return '#2196F3';
      case IssueSeverity.medium:
        return '#FF9800';
      case IssueSeverity.high:
        return '#FF5722';
      case IssueSeverity.critical:
        return '#F44336';
    }
  }
}

/// Issue Status
enum IssueStatus {
  reported('reported', 'Reported', 'Issue reported'),
  acknowledged('acknowledged', 'Acknowledged', 'Issue acknowledged'),
  inProgress('in_progress', 'In Progress', 'Being worked on'),
  resolved('resolved', 'Resolved', 'Issue resolved'),
  closed('closed', 'Closed', 'Issue closed');

  final String value;
  final String displayName;
  final String description;

  const IssueStatus(this.value, this.displayName, this.description);

  static IssueStatus fromString(String value) {
    return IssueStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => IssueStatus.reported,
    );
  }

  String get colorHex {
    switch (this) {
      case IssueStatus.reported:
        return '#F44336'; // Red
      case IssueStatus.acknowledged:
        return '#FF9800'; // Orange
      case IssueStatus.inProgress:
        return '#2196F3'; // Blue
      case IssueStatus.resolved:
        return '#4CAF50'; // Green
      case IssueStatus.closed:
        return '#9E9E9E'; // Grey
    }
  }
}
