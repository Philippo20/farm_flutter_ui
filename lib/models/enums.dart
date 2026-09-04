/// Grow Room Monitoring App - Enums
/// All enum types used across the application
library;

// ========== USER ROLES ==========

enum UserRole {
  superAdmin,
  admin,
  farmManager,
  owner,
  caretaker,
  technician,
  fulfillmentManager,
  packagingSupervisor,
  qualityAssurance,
  salesManager,
  salesPersonnel,
  driver,
  accountant;

  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.farmManager:
        return 'Farm Manager';
      case UserRole.owner:
        return 'Farm Owner';
      case UserRole.caretaker:
        return 'Caretaker';
      case UserRole.technician:
        return 'Technician';
      case UserRole.fulfillmentManager:
        return 'Fulfillment Manager';
      case UserRole.packagingSupervisor:
        return 'Packaging Supervisor';
      case UserRole.qualityAssurance:
        return 'Quality Assurance';
      case UserRole.salesManager:
        return 'Sales Manager';
      case UserRole.salesPersonnel:
        return 'Sales Personnel';
      case UserRole.driver:
        return 'Driver';
      case UserRole.accountant:
        return 'Accountant';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
      case 'super_admin':
      case 'super admin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'farmmanager':
      case 'farm_manager':
      case 'farm manager':
        return UserRole.farmManager;
      case 'owner':
      case 'farm_owner':
      case 'farm owner':
        return UserRole.owner;
      case 'caretaker':
        return UserRole.caretaker;
      case 'technician':
        return UserRole.technician;
      case 'fulfillmentmanager':
      case 'fulfillment_manager':
      case 'fulfillment manager':
        return UserRole.fulfillmentManager;
      case 'packagingsupervisor':
      case 'packaging_supervisor':
      case 'packaging supervisor':
        return UserRole.packagingSupervisor;
      case 'qualityassurance':
      case 'quality_assurance':
      case 'quality_assurance_officer':
      case 'quality officer':
      case 'quality assurance':
        return UserRole.qualityAssurance;
      case 'salesmanager':
      case 'sales_manager':
      case 'sales manager':
        return UserRole.salesManager;
      case 'salespersonnel':
      case 'sales_personnel':
      case 'sales_person':
      case 'sales personnel':
        return UserRole.salesPersonnel;
      case 'driver':
      case 'delivery_agent':
      case 'delivery agent':
        return UserRole.driver;
      case 'accountant':
        return UserRole.accountant;
      default:
        throw ArgumentError('Invalid user role: $role');
    }
  }
}

// ========== FARM STATUS ==========

enum FarmStatus {
  active,
  inactive;

  String get displayName {
    switch (this) {
      case FarmStatus.active:
        return 'Active';
      case FarmStatus.inactive:
        return 'Inactive';
    }
  }

  static FarmStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return FarmStatus.active;
      case 'inactive':
        return FarmStatus.inactive;
      default:
        throw ArgumentError('Invalid farm status: $status');
    }
  }
}

// ========== TIER TYPES ==========

enum TierType {
  compact,
  medium,
  mega;

  String get displayName {
    switch (this) {
      case TierType.compact:
        return 'Compact';
      case TierType.medium:
        return 'Medium';
      case TierType.mega:
        return 'Mega';
    }
  }

  static TierType fromString(String tier) {
    switch (tier.toLowerCase()) {
      case 'compact':
        return TierType.compact;
      case 'medium':
        return TierType.medium;
      case 'mega':
        return TierType.mega;
      default:
        throw ArgumentError('Invalid tier type: $tier');
    }
  }
}

// ========== PLANT TYPES ==========

enum PlantType {
  lettuce,
  tomatoes,
  basil,
  spinach,
  kale,
  arugula,
  chard,
  mint,
  cilantro,
  parsley,
  strawberries,
  peppers,
  cucumbers,
  microgreens;

  String get displayName {
    switch (this) {
      case PlantType.lettuce:
        return 'Lettuce';
      case PlantType.tomatoes:
        return 'Tomatoes';
      case PlantType.basil:
        return 'Basil';
      case PlantType.spinach:
        return 'Spinach';
      case PlantType.kale:
        return 'Kale';
      case PlantType.arugula:
        return 'Arugula';
      case PlantType.chard:
        return 'Chard';
      case PlantType.mint:
        return 'Mint';
      case PlantType.cilantro:
        return 'Cilantro';
      case PlantType.parsley:
        return 'Parsley';
      case PlantType.strawberries:
        return 'Strawberries';
      case PlantType.peppers:
        return 'Peppers';
      case PlantType.cucumbers:
        return 'Cucumbers';
      case PlantType.microgreens:
        return 'Microgreens';
    }
  }

  static PlantType fromString(String plant) {
    switch (plant.toLowerCase()) {
      case 'lettuce':
        return PlantType.lettuce;
      case 'tomatoes':
        return PlantType.tomatoes;
      case 'basil':
        return PlantType.basil;
      case 'spinach':
        return PlantType.spinach;
      case 'kale':
        return PlantType.kale;
      case 'arugula':
        return PlantType.arugula;
      case 'chard':
        return PlantType.chard;
      case 'mint':
        return PlantType.mint;
      case 'cilantro':
        return PlantType.cilantro;
      case 'parsley':
        return PlantType.parsley;
      case 'strawberries':
        return PlantType.strawberries;
      case 'peppers':
        return PlantType.peppers;
      case 'cucumbers':
        return PlantType.cucumbers;
      case 'microgreens':
        return PlantType.microgreens;
      default:
        throw ArgumentError('Invalid plant type: $plant');
    }
  }
}

// ========== PLANT VARIETIES ==========

enum LettuceVariety {
  romaine,
  butterhead,
  oakleaf,
  iceberg,
  lolloRosso,
  batavia;

  String get displayName {
    switch (this) {
      case LettuceVariety.romaine:
        return 'Romaine';
      case LettuceVariety.butterhead:
        return 'Butterhead';
      case LettuceVariety.oakleaf:
        return 'Oak Leaf';
      case LettuceVariety.iceberg:
        return 'Iceberg';
      case LettuceVariety.lolloRosso:
        return 'Lollo Rosso';
      case LettuceVariety.batavia:
        return 'Batavia';
    }
  }
}

enum TomatoVariety {
  cherryTomatoes,
  beefSteak,
  roma,
  grapeTomatoes,
  heirloom;

  String get displayName {
    switch (this) {
      case TomatoVariety.cherryTomatoes:
        return 'Cherry Tomatoes';
      case TomatoVariety.beefSteak:
        return 'Beef Steak';
      case TomatoVariety.roma:
        return 'Roma';
      case TomatoVariety.grapeTomatoes:
        return 'Grape Tomatoes';
      case TomatoVariety.heirloom:
        return 'Heirloom';
    }
  }
}

enum BasilVariety {
  sweetBasil,
  thaiBasil,
  lemonBasil,
  purpleBasil;

  String get displayName {
    switch (this) {
      case BasilVariety.sweetBasil:
        return 'Sweet Basil';
      case BasilVariety.thaiBasil:
        return 'Thai Basil';
      case BasilVariety.lemonBasil:
        return 'Lemon Basil';
      case BasilVariety.purpleBasil:
        return 'Purple Basil';
    }
  }
}

// ========== SENSOR TYPES ==========

enum SensorType {
  temperature,
  humidity,
  co2,
  light,
  ph,
  ec,
  electricityCurrent,
  electricityVoltage,
  electricityWattage;

  String get displayName {
    switch (this) {
      case SensorType.temperature:
        return 'Temperature';
      case SensorType.humidity:
        return 'Humidity';
      case SensorType.co2:
        return 'CO₂';
      case SensorType.light:
        return 'Light Intensity';
      case SensorType.ph:
        return 'pH Level';
      case SensorType.ec:
        return 'EC Level';
      case SensorType.electricityCurrent:
        return 'Current';
      case SensorType.electricityVoltage:
        return 'Voltage';
      case SensorType.electricityWattage:
        return 'Wattage';
    }
  }

  String get unit {
    switch (this) {
      case SensorType.temperature:
        return '°C';
      case SensorType.humidity:
        return '%';
      case SensorType.co2:
        return 'ppm';
      case SensorType.light:
        return 'lux';
      case SensorType.ph:
        return 'pH';
      case SensorType.ec:
        return 'mS/cm';
      case SensorType.electricityCurrent:
        return 'A';
      case SensorType.electricityVoltage:
        return 'V';
      case SensorType.electricityWattage:
        return 'W';
    }
  }

  static SensorType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'temperature':
        return SensorType.temperature;
      case 'humidity':
        return SensorType.humidity;
      case 'co2':
        return SensorType.co2;
      case 'light':
        return SensorType.light;
      case 'ph':
        return SensorType.ph;
      case 'ec':
        return SensorType.ec;
      case 'electricity_current':
      case 'current':
        return SensorType.electricityCurrent;
      case 'electricity_voltage':
      case 'voltage':
        return SensorType.electricityVoltage;
      case 'electricity_wattage':
      case 'wattage':
        return SensorType.electricityWattage;
      default:
        throw ArgumentError('Invalid sensor type: $type');
    }
  }
}

// ========== ALERT SEVERITY ==========

enum AlertSeverity {
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case AlertSeverity.low:
        return 'Low';
      case AlertSeverity.medium:
        return 'Medium';
      case AlertSeverity.high:
        return 'High';
    }
  }

  static AlertSeverity fromString(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return AlertSeverity.low;
      case 'medium':
        return AlertSeverity.medium;
      case 'high':
        return AlertSeverity.high;
      default:
        throw ArgumentError('Invalid alert severity: $severity');
    }
  }
}

// ========== GROW STAGES ==========

enum GrowStage {
  germination,
  vegetative,
  flowering,
  harvest;

  String get displayName {
    switch (this) {
      case GrowStage.germination:
        return 'Germination';
      case GrowStage.vegetative:
        return 'Vegetative';
      case GrowStage.flowering:
        return 'Flowering';
      case GrowStage.harvest:
        return 'Harvest';
    }
  }

  static GrowStage fromString(String stage) {
    switch (stage.toLowerCase()) {
      case 'germination':
        return GrowStage.germination;
      case 'vegetative':
        return GrowStage.vegetative;
      case 'flowering':
        return GrowStage.flowering;
      case 'harvest':
        return GrowStage.harvest;
      default:
        throw ArgumentError('Invalid grow stage: $stage');
    }
  }
}
