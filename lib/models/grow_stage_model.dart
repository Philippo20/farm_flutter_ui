import 'enums.dart';

/// Grow Stage Model
/// Represents a growth stage for a farm's crop
class GrowStageModel {
  final String id;
  final String farmId;
  final GrowStage stageName;
  final bool started;
  final DateTime startTime;
  final DateTime? endTime;
  final String createdBy;
  final DateTime createdAt;

  GrowStageModel({
    required this.id,
    required this.farmId,
    required this.stageName,
    required this.started,
    required this.startTime,
    this.endTime,
    required this.createdBy,
    required this.createdAt,
  });

  /// Create GrowStageModel from JSON
  factory GrowStageModel.fromJson(Map<String, dynamic> json) {
    return GrowStageModel(
      id: json['id'] as String? ?? json['\$id'] as String,
      farmId: json['farmID'] as String,
      stageName: GrowStage.fromString(json['stage_name'] as String),
      started: json['started'] as bool,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Convert GrowStageModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmID': farmId,
      'stage_name': stageName.name,
      'started': started,
      'start_time': startTime.toIso8601String(),
      if (endTime != null) 'end_time': endTime!.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  GrowStageModel copyWith({
    String? id,
    String? farmId,
    GrowStage? stageName,
    bool? started,
    DateTime? startTime,
    DateTime? endTime,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return GrowStageModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      stageName: stageName ?? this.stageName,
      started: started ?? this.started,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if stage is active
  bool get isActive => started && endTime == null;

  /// Check if stage is completed
  bool get isCompleted => endTime != null;

  /// Get duration of stage
  Duration? get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    } else if (started) {
      return DateTime.now().difference(startTime);
    }
    return null;
  }

  /// Get duration in days
  int? get durationInDays => duration?.inDays;

  @override
  String toString() {
    return 'GrowStageModel(stage: ${stageName.displayName}, started: $started, active: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GrowStageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
