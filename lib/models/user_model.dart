import 'enums.dart';

/// User Model
/// Represents a user in the Grow Room Monitoring system
class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final List<UserRole> roles;
  final String address;
  final String? farmId; // For owner or caretaker
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    List<UserRole>? roles,
    required this.address,
    this.farmId,
    required this.createdAt,
    this.updatedAt,
  }) : roles = List.unmodifiable(
            roles == null || roles.isEmpty ? [role] : roles.toSet());

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? json['\$id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.fromString(json['role'] as String),
      roles: (json['roles'] as List?)
          ?.map((r) => UserRole.fromString(r.toString()))
          .toList(),
      address: json['address'] as String? ?? '',
      farmId: json['farmID'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.apiValue,
      'roles': roles.map((r) => r.apiValue).toList(),
      'address': address,
      if (farmId != null) 'farmID': farmId,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    List<UserRole>? roles,
    String? address,
    String? farmId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      roles: roles ?? this.roles,
      address: address ?? this.address,
      farmId: farmId ?? this.farmId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user is super admin
  bool get isSuperAdmin => role == UserRole.superAdmin;

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is owner
  bool get isOwner => role == UserRole.owner;

  /// Check if user is caretaker
  bool get isCaretaker => role == UserRole.caretaker;

  bool get isFarmManager => role == UserRole.farmManager;

  bool get isTechnician => role == UserRole.technician;

  bool get isFulfillmentManager => role == UserRole.fulfillmentManager;

  bool get isPackagingSupervisor => role == UserRole.packagingSupervisor;

  bool get isQualityAssurance => role == UserRole.qualityAssurance;

  bool get isSalesManager => role == UserRole.salesManager;

  bool get isSalesPersonnel => role == UserRole.salesPersonnel;

  bool get isDriver => role == UserRole.driver;

  bool get isAccountant => role == UserRole.accountant;

  /// Get user initials for avatar
  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: ${role.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.role == role &&
        other.roles.join() == roles.join();
  }

  @override
  int get hashCode => Object.hash(id, role, Object.hashAll(roles));
}
