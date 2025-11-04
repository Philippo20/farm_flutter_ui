// Alert model

import 'enums.dart';

/// Alert Model
/// Represents an alert in the Grow Room Monitoring system
class AlertModel {
  final String id;
  final String farmId;
  final String message;
  final SensorType sensorType;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool resolved;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  AlertModel({
    required this.id,
    required this.farmId,
    required this.message,
    required this.sensorType,
    required this.severity,
    required this.timestamp,
    this.resolved = false,
    this.resolvedAt,
    this.resolvedBy,
  });

  /// Create AlertModel from JSON
  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String? ?? json['\$id'] as String,
      farmId: json['farmID'] as String,
      message: json['message'] as String,
      sensorType: SensorType.fromString(json['sensorType'] as String),
      severity: AlertSeverity.fromString(json['severity'] as String),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      resolved: json['resolved'] as bool? ?? false,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      resolvedBy: json['resolvedBy'] as String?,
    );
  }

  /// Convert AlertModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmID': farmId,
      'message': message,
      'sensorType': sensorType.name,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'resolved': resolved,
      if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
      if (resolvedBy != null) 'resolvedBy': resolvedBy,
    };
  }

  /// Create a copy with updated fields
  AlertModel copyWith({
    String? id,
    String? farmId,
    String? message,
    SensorType? sensorType,
    AlertSeverity? severity,
    DateTime? timestamp,
    bool? resolved,
    DateTime? resolvedAt,
    String? resolvedBy,
  }) {
    return AlertModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      message: message ?? this.message,
      sensorType: sensorType ?? this.sensorType,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      resolved: resolved ?? this.resolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
    );
  }

  /// Check if alert is active (not resolved)
  bool get isActive => !resolved;

  /// Check if alert is critical
  bool get isCritical => severity == AlertSeverity.high;

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  String toString() {
    return 'AlertModel(severity: ${severity.displayName}, sensor: ${sensorType.displayName}, resolved: $resolved)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlertModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
