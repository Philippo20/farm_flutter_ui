import 'enums.dart';

/// Farm Model
/// Represents a farm in the Grow Room Monitoring system
class FarmModel {
  final String id;
  final String name;
  final String location;
  final String? latitude;
  final String? longitude;
  final String ownerId;
  final String? caretakerId;
  final TierType tierType;
  final FarmStatus status;
  final PlantType plantType;
  final String plantVariety;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FarmModel({
    required this.id,
    required this.name,
    required this.location,
    this.latitude,
    this.longitude,
    required this.ownerId,
    this.caretakerId,
    required this.tierType,
    required this.status,
    required this.plantType,
    required this.plantVariety,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create FarmModel from JSON
  factory FarmModel.fromJson(Map<String, dynamic> json) {
    return FarmModel(
      id: json['id'] as String? ?? json['\$id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      ownerId: json['ownerID'] as String,
      caretakerId: json['careTakerID'] as String?,
      tierType: TierType.fromString(json['tierType'] as String),
      status: FarmStatus.fromString(json['status'] as String),
      plantType: PlantType.fromString(json['plant_type'] as String),
      plantVariety: json['plant_variety'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert FarmModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'ownerID': ownerId,
      if (caretakerId != null) 'careTakerID': caretakerId,
      'tierType': tierType.name,
      'status': status.name,
      'plant_type': plantType.name,
      'plant_variety': plantVariety,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  FarmModel copyWith({
    String? id,
    String? name,
    String? location,
    String? latitude,
    String? longitude,
    String? ownerId,
    String? caretakerId,
    TierType? tierType,
    FarmStatus? status,
    PlantType? plantType,
    String? plantVariety,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FarmModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ownerId: ownerId ?? this.ownerId,
      caretakerId: caretakerId ?? this.caretakerId,
      tierType: tierType ?? this.tierType,
      status: status ?? this.status,
      plantType: plantType ?? this.plantType,
      plantVariety: plantVariety ?? this.plantVariety,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if farm is active
  bool get isActive => status == FarmStatus.active;

  /// Check if farm has caretaker assigned
  bool get hasCaretaker => caretakerId != null && caretakerId!.isNotEmpty;

  /// Get location coordinates if available
  Map<String, double>? get coordinates {
    if (latitude != null && longitude != null) {
      try {
        return {
          'latitude': double.parse(latitude!),
          'longitude': double.parse(longitude!),
        };
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'FarmModel(id: $id, name: $name, status: ${status.displayName}, plant: ${plantType.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FarmModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
