/// Grow Room Monitoring App - Static Strings
/// Centralized string constants for the application
class AppStrings {
  // ========== APP INFO ==========
  static const String appName = 'Grow Room Monitor';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-Powered Grow Room Monitoring System';
  
  // ========== ROLES ==========
  static const String roleAdmin = 'Admin';
  static const String roleOwner = 'Farm Owner';
  static const String roleCaretaker = 'Caretaker';
  
  // ========== SENSOR TYPES ==========
  static const String sensorTemperature = 'Temperature';
  static const String sensorHumidity = 'Humidity';
  static const String sensorCO2 = 'CO₂';
  static const String sensorLight = 'Light Intensity';
  static const String sensorPH = 'pH Level';
  static const String sensorEC = 'EC Level';
  static const String sensorElectricity = 'Electricity';
  static const String sensorCurrent = 'Current';
  static const String sensorVoltage = 'Voltage';
  static const String sensorWattage = 'Wattage';
  
  // ========== SENSOR UNITS ==========
  static const String unitCelsius = '°C';
  static const String unitFahrenheit = '°F';
  static const String unitPercent = '%';
  static const String unitPPM = 'ppm';
  static const String unitLux = 'lux';
  static const String unitPH = 'pH';
  static const String unitEC = 'mS/cm';
  static const String unitAmpere = 'A';
  static const String unitVolt = 'V';
  static const String unitWatt = 'W';
  
  // ========== STATUS ==========
  static const String statusActive = 'Active';
  static const String statusInactive = 'Inactive';
  static const String statusOnline = 'Online';
  static const String statusOffline = 'Offline';
  static const String statusGood = 'Good';
  static const String statusWarning = 'Warning';
  static const String statusDanger = 'Danger';
  static const String statusCritical = 'Critical';
  
  // ========== NAVIGATION ==========
  static const String navDashboard = 'Dashboard';
  static const String navFarms = 'Farms';
  static const String navUsers = 'Users';
  static const String navSensors = 'Sensors';
  static const String navAlerts = 'Alerts';
  static const String navCharts = 'Charts';
  static const String navSettings = 'Settings';
  static const String navLogs = 'Logs';
  static const String navProfile = 'Profile';
  
  // ========== ACTIONS ==========
  static const String actionAdd = 'Add';
  static const String actionEdit = 'Edit';
  static const String actionDelete = 'Delete';
  static const String actionSave = 'Save';
  static const String actionCancel = 'Cancel';
  static const String actionRefresh = 'Refresh';
  static const String actionExport = 'Export';
  static const String actionImport = 'Import';
  static const String actionSearch = 'Search';
  static const String actionFilter = 'Filter';
  static const String actionViewAll = 'View All';
  static const String actionViewDetails = 'View Details';
  
  // ========== MESSAGES ==========
  static const String msgLoading = 'Loading...';
  static const String msgNoData = 'No data available';
  static const String msgError = 'An error occurred';
  static const String msgSuccess = 'Success!';
  static const String msgSaved = 'Saved successfully';
  static const String msgDeleted = 'Deleted successfully';
  static const String msgUpdated = 'Updated successfully';
  static const String msgConfirmDelete = 'Are you sure you want to delete?';
  
  // ========== AUTH ==========
  static const String authLogin = 'Login';
  static const String authLogout = 'Logout';
  static const String authEmail = 'Email';
  static const String authPassword = 'Password';
  static const String authForgotPassword = 'Forgot Password?';
  static const String authRememberMe = 'Remember Me';
  static const String authWelcomeBack = 'Welcome Back!';
  
  // ========== FARM ==========
  static const String farmName = 'Farm Name';
  static const String farmLocation = 'Location';
  static const String farmOwner = 'Owner';
  static const String farmCaretaker = 'Caretaker';
  static const String farmStatus = 'Status';
  static const String farmTierType = 'Tier Type';
  static const String farmPlantType = 'Plant Type';
  static const String farmPlantVariety = 'Plant Variety';
  
  // ========== TIER TYPES ==========
  static const String tierCompact = 'Compact';
  static const String tierMedium = 'Medium';
  static const String tierMega = 'Mega';
  
  // ========== PLANT TYPES ==========
  static const String plantLettuce = 'Lettuce';
  static const String plantTomatoes = 'Tomatoes';
  static const String plantBasil = 'Basil';
  static const String plantSpinach = 'Spinach';
  static const String plantKale = 'Kale';
  
  // ========== GROW STAGES ==========
  static const String stageGermination = 'Germination';
  static const String stageVegetative = 'Vegetative';
  static const String stageFlowering = 'Flowering';
  static const String stageHarvest = 'Harvest';
  
  // ========== ALERT SEVERITY ==========
  static const String severityLow = 'Low';
  static const String severityMedium = 'Medium';
  static const String severityHigh = 'High';
  static const String severityCritical = 'Critical';
  
  // ========== TIME PERIODS ==========
  static const String periodToday = 'Today';
  static const String periodYesterday = 'Yesterday';
  static const String periodWeek = 'This Week';
  static const String periodMonth = 'This Month';
  static const String periodYear = 'This Year';
  static const String periodCustom = 'Custom';
  
  // ========== DASHBOARD ==========
  static const String dashboardOverview = 'Overview';
  static const String dashboardRecentAlerts = 'Recent Alerts';
  static const String dashboardSensorReadings = 'Sensor Readings';
  static const String dashboardFarmStatus = 'Farm Status';
  static const String dashboardQuickActions = 'Quick Actions';
  
  // ========== VALIDATION ==========
  static const String validationRequired = 'This field is required';
  static const String validationInvalidEmail = 'Invalid email address';
  static const String validationPasswordTooShort = 'Password must be at least 8 characters';
  static const String validationNumbersOnly = 'Only numbers allowed';
  
  // ========== EMPTY STATES ==========
  static const String emptyFarms = 'No farms available';
  static const String emptyUsers = 'No users found';
  static const String emptyAlerts = 'No alerts at this time';
  static const String emptySensors = 'No sensors configured';
  static const String emptyLogs = 'No logs available';
}
