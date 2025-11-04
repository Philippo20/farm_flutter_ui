// Sensor model

import 'enums.dart';

/// Sensor Model
/// Represents a sensor reading in the Grow Room Monitoring system
class SensorModel {
  final String id;
  final String farmId;
  final SensorType type;
  final double value;
  final String unit;
  final DateTime timestamp;

  SensorModel({
    required this.id,
    required this.farmId,
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
  });

  /// Create SensorModel from JSON
  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      id: json['id'] as String? ?? json['\$id'] as String,
      farmId: json['farmID'] as String,
      type: SensorType.fromString(json['type'] as String),
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Convert SensorModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmID': farmId,
      'type': type.name,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  SensorModel copyWith({
    String? id,
    String? farmId,
    SensorType? type,
    double? value,
    String? unit,
    DateTime? timestamp,
  }) {
    return SensorModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Get formatted value with unit
  String get formattedValue => '${value.toStringAsFixed(1)} $unit';

  /// Check if reading is recent (within last 5 minutes)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inMinutes <= 5;
  }

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
    return 'SensorModel(type: ${type.displayName}, value: $formattedValue, farm: $farmId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SensorModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}