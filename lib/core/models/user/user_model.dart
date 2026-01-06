import 'user_role.dart';
import 'user_permissions.dart';

/// Enhanced User Model with unique account validation
/// Ensures each user has a unique email, phone, and employee ID
class UserModel {
  final String id;
  final String email; // Unique identifier
  final String? phoneNumber; // Unique, optional
  final String? employeeId; // Unique, optional
  final String name;
  final UserRole role;
  final UserStatus status;
  final String? profileImageUrl;
  final String? department;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final List<String> assignedFarmIds; // Farms assigned to this user
  final Map<String, dynamic>? metadata; // Additional role-specific data

  UserModel({
    required this.id,
    required this.email,
    this.phoneNumber,
    this.employeeId,
    required this.name,
    required this.role,
    this.status = UserStatus.active,
    this.profileImageUrl,
    this.department,
    required this.createdAt,
    this.lastLoginAt,
    this.assignedFarmIds = const [],
    this.metadata,
  });

  /// Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      employeeId: json['employeeId'] as String?,
      name: json['name'] as String,
      role: UserRole.fromCode(json['role'] as String) ?? UserRole.caretaker,
      status: UserStatus.fromString(json['status'] as String? ?? 'active'),
      profileImageUrl: json['profileImageUrl'] as String?,
      department: json['department'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      assignedFarmIds: (json['assignedFarmIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phoneNumber': phoneNumber,
      'employeeId': employeeId,
      'name': name,
      'role': role.code,
      'status': status.value,
      'profileImageUrl': profileImageUrl,
      'department': department,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'assignedFarmIds': assignedFarmIds,
      'metadata': metadata,
    };
  }

  /// Copy with method for immutability
  UserModel copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? employeeId,
    String? name,
    UserRole? role,
    UserStatus? status,
    String? profileImageUrl,
    String? department,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    List<String>? assignedFarmIds,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      assignedFarmIds: assignedFarmIds ?? this.assignedFarmIds,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get user initials for avatar
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  /// Check if user has a specific permission
  bool hasPermission(String permission) {
    return RolePermissions.hasPermission(role, permission);
  }

  /// Check if user has any of the given permissions
  bool hasAnyPermission(List<String> permissions) {
    return RolePermissions.hasAnyPermission(role, permissions);
  }

  /// Check if user has all of the given permissions
  bool hasAllPermissions(List<String> permissions) {
    return RolePermissions.hasAllPermissions(role, permissions);
  }

  /// Get all permissions for this user
  List<String> get permissions {
    return RolePermissions.getPermissions(role);
  }

  /// Check if user is active
  bool get isActive => status == UserStatus.active;

  /// Check if user is suspended
  bool get isSuspended => status == UserStatus.suspended;

  /// Check if user is pending approval
  bool get isPending => status == UserStatus.pending;

  /// Check if user has assigned farms
  bool get hasFarms => assignedFarmIds.isNotEmpty;

  /// Get farm count
  int get farmCount => assignedFarmIds.length;

  /// Check if user is assigned to a specific farm
  bool isAssignedToFarm(String farmId) {
    return assignedFarmIds.contains(farmId);
  }

  /// Get dashboard route for this user
  String get dashboardRoute => role.dashboardRoute;

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number format (basic)
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s-]'), ''));
  }

  /// Validate employee ID format
  static bool isValidEmployeeId(String employeeId) {
    // Must be alphanumeric, 4-20 characters
    final idRegex = RegExp(r'^[A-Z0-9]{4,20}$');
    return idRegex.hasMatch(employeeId.toUpperCase());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, role: ${role.displayName}, status: ${status.displayName})';
  }
}

/// User account status
enum UserStatus {
  active('active', 'Active'),
  pending('pending', 'Pending Approval'),
  suspended('suspended', 'Suspended'),
  inactive('inactive', 'Inactive');

  final String value;
  final String displayName;

  const UserStatus(this.value, this.displayName);

  static UserStatus fromString(String value) {
    return UserStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => UserStatus.active,
    );
  }
}

/// User account validation errors
class UserValidationError {
  static const String emailExists = 'Email already exists';
  static const String phoneExists = 'Phone number already exists';
  static const String employeeIdExists = 'Employee ID already exists';
  static const String invalidEmail = 'Invalid email format';
  static const String invalidPhone = 'Invalid phone number format';
  static const String invalidEmployeeId = 'Invalid employee ID format';
  static const String nameRequired = 'Name is required';
  static const String roleRequired = 'Role is required';
}

/// User account validator
class UserValidator {
  /// Validate user data before creation/update
  static Map<String, String> validate({
    required String email,
    required String name,
    required UserRole role,
    String? phoneNumber,
    String? employeeId,
    List<UserModel>? existingUsers,
  }) {
    final errors = <String, String>{};

    // Validate name
    if (name.trim().isEmpty) {
      errors['name'] = UserValidationError.nameRequired;
    }

    // Validate email
    if (!UserModel.isValidEmail(email)) {
      errors['email'] = UserValidationError.invalidEmail;
    } else if (existingUsers != null) {
      final emailExists = existingUsers.any((user) => user.email == email);
      if (emailExists) {
        errors['email'] = UserValidationError.emailExists;
      }
    }

    // Validate phone number
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      if (!UserModel.isValidPhoneNumber(phoneNumber)) {
        errors['phone'] = UserValidationError.invalidPhone;
      } else if (existingUsers != null) {
        final phoneExists = existingUsers.any((user) => user.phoneNumber == phoneNumber);
        if (phoneExists) {
          errors['phone'] = UserValidationError.phoneExists;
        }
      }
    }

    // Validate employee ID
    if (employeeId != null && employeeId.isNotEmpty) {
      if (!UserModel.isValidEmployeeId(employeeId)) {
        errors['employeeId'] = UserValidationError.invalidEmployeeId;
      } else if (existingUsers != null) {
        final idExists = existingUsers.any((user) => user.employeeId == employeeId);
        if (idExists) {
          errors['employeeId'] = UserValidationError.employeeIdExists;
        }
      }
    }

    return errors;
  }

  /// Check if email is unique
  static bool isEmailUnique(String email, List<UserModel> existingUsers, {String? excludeUserId}) {
    return !existingUsers.any((user) => 
      user.email == email && user.id != excludeUserId
    );
  }

  /// Check if phone is unique
  static bool isPhoneUnique(String? phone, List<UserModel> existingUsers, {String? excludeUserId}) {
    if (phone == null || phone.isEmpty) return true;
    return !existingUsers.any((user) => 
      user.phoneNumber == phone && user.id != excludeUserId
    );
  }

  /// Check if employee ID is unique
  static bool isEmployeeIdUnique(String? employeeId, List<UserModel> existingUsers, {String? excludeUserId}) {
    if (employeeId == null || employeeId.isEmpty) return true;
    return !existingUsers.any((user) => 
      user.employeeId == employeeId && user.id != excludeUserId
    );
  }
}
