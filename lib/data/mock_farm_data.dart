import 'dart:math';
import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../models/enums.dart';

/// Mock data generator for Farm Management Platform
/// Simulates data from randomData.py and provides comprehensive farm data
class MockFarmData {
  static final Random _random = Random();

  // User data
  static Map<String, dynamic> getCurrentUser(String role) {
    final users = {
      'admin': {
        'id': 'admin_001',
        'name': 'Acquaye Johnson',
        'email': 'admin@farmestates.com',
        'role': 'Administrator',
        'avatar': 'AJ',
        'farms': ['All Farms'],
        'permissions': ['all'],
      },
      'owner': {
        'id': 'owner_001',
        'name': 'Lizzy Thompson',
        'email': 'lizzy@farmestates.com',
        'role': 'Farm Owner',
        'avatar': 'LT',
        'farms': ['Northern Estate', 'Southern Estate'],
        'permissions': ['view_all', 'manage_farms', 'manage_caretakers'],
      },
      'caretaker': {
        'id': 'care_001',
        'name': 'John Mensah',
        'email': 'john@farmestates.com',
        'role': 'Caretaker',
        'avatar': 'JM',
        'farms': ['Northern Estate'],
        'permissions': ['view_assigned', 'log_activities', 'update_tasks'],
      },
    };
    return users[role] ?? users['caretaker']!;
  }

  // Sensor data based on randomData.py
  static Map<String, dynamic> getSensorData() {
    return {
      'temperature': {
        'value': 15 + _random.nextInt(6),
        'unit': '°C',
        'status': 'normal',
        'icon': Icons.thermostat,
        'color': Colors.orange,
        'trend': _random.nextBool() ? 'up' : 'down',
        'change': _random.nextInt(5),
      },
      'humidity': {
        'value': 50 + _random.nextInt(21),
        'unit': '%',
        'status': 'normal',
        'icon': Icons.water_drop,
        'color': Colors.blue,
        'trend': _random.nextBool() ? 'up' : 'down',
        'change': _random.nextInt(10),
      },
      'soilMoisture': {
        'value': 30 + _random.nextInt(41),
        'unit': '%',
        'status': 'optimal',
        'icon': Icons.grass,
        'color': Colors.brown,
        'trend': 'stable',
        'change': _random.nextInt(3),
      },
      'waterLevel': {
        'value': _random.nextInt(101),
        'unit': 'cm',
        'status': _random.nextInt(100) > 30 ? 'adequate' : 'low',
        'icon': Icons.water,
        'color': Colors.cyan,
        'trend': _random.nextBool() ? 'up' : 'down',
        'change': _random.nextInt(15),
      },
      'ph': {
        'value': 5.5 + _random.nextDouble(),
        'unit': 'pH',
        'status': 'balanced',
        'icon': Icons.science,
        'color': Colors.purple,
        'trend': 'stable',
        'change': 0.1,
      },
      'ec': {
        'value': 1.0 + _random.nextDouble() * 0.2,
        'unit': 'mS/cm',
        'status': 'normal',
        'icon': Icons.electric_bolt,
        'color': Colors.yellow[700],
        'trend': _random.nextBool() ? 'up' : 'down',
        'change': 0.05,
      },
      'co2': {
        'value': 400 + _random.nextInt(801),
        'unit': 'ppm',
        'status': 'normal',
        'icon': Icons.air,
        'color': Colors.grey,
        'trend': _random.nextBool() ? 'up' : 'down',
        'change': _random.nextInt(50),
      },
      'tds': {
        'value': 300 + _random.nextInt(501),
        'unit': 'ppm',
        'status': 'optimal',
        'icon': Icons.opacity,
        'color': Colors.indigo,
        'trend': 'stable',
        'change': _random.nextInt(20),
      },
    };
  }

  // Power system data
  static Map<String, dynamic> getPowerData() {
    return {
      'grid': {
        'power': 100 + _random.nextInt(2901),
        'current': 1 + _random.nextInt(20),
        'voltage': 210 + _random.nextInt(41),
        'energy': _random.nextDouble() * 100,
        'bill': 1 + _random.nextInt(500),
        'status': 'active',
      },
      'solar': {
        'power': _random.nextDouble() * 1000,
        'supply': _random.nextDouble() * 1000,
        'efficiency': 70 + _random.nextInt(20),
        'status': _random.nextBool() ? 'generating' : 'idle',
      },
      'battery': {
        'power': 20 + _random.nextInt(81),
        'charge': 20 + _random.nextInt(81),
        'status': _random.nextInt(100) > 20 ? 'good' : 'low',
        'timeRemaining': '${2 + _random.nextInt(10)}h',
      },
    };
  }

  // System controls data (from randomData.py)
  static Map<String, dynamic> getSystemControls() {
    return {
      'pumps': {
        'waterPump': {
          'name': 'Water Pump',
          'state': _random.nextBool() ? 'ON' : 'OFF',
          'icon': Icons.water_drop,
          'color': Colors.blue,
          'lastToggled': DateTime.now().subtract(Duration(minutes: _random.nextInt(120))),
        },
        'airPump': {
          'name': 'Air Pump',
          'state': _random.nextBool() ? 'ON' : 'OFF',
          'icon': Icons.air,
          'color': Colors.cyan,
          'lastToggled': DateTime.now().subtract(Duration(minutes: _random.nextInt(120))),
        },
        'nutrientPump': {
          'name': 'Nutrient Pump',
          'state': _random.nextBool() ? 'ON' : 'OFF',
          'icon': Icons.science,
          'color': Colors.green,
          'lastToggled': DateTime.now().subtract(Duration(minutes: _random.nextInt(120))),
        },
      },
      'lights': {
        'rack1': {
          'name': 'Rack 1 Lights',
          'state': _random.nextBool() ? 'ON' : 'OFF',
          'icon': Icons.lightbulb,
          'color': Colors.yellow,
          'brightness': 70 + _random.nextInt(31),
        },
        'rack2': {
          'name': 'Rack 2 Lights',
          'state': _random.nextBool() ? 'ON' : 'OFF',
          'icon': Icons.lightbulb,
          'color': Colors.yellow,
          'brightness': 70 + _random.nextInt(31),
        },
        'rack3': {
          'name': 'Rack 3 Lights',
          'state': 'ON', // More likely to be ON
          'icon': Icons.lightbulb,
          'color': Colors.yellow,
          'brightness': 70 + _random.nextInt(31),
        },
      },
      'climate': {
        'airCondition': {
          'name': 'Air Conditioning',
          'state': _random.nextBool() ? 'ON' : 'OFF',
          'icon': Icons.ac_unit,
          'color': Colors.lightBlue,
          'temperature': 18 + _random.nextInt(7),
        },
      },
      'phControl': {
        'phUp': {
          'name': 'pH Up Relay',
          'state': _random.nextBool() ? 'ON' : 'OFF',
          'icon': Icons.arrow_upward,
          'color': Colors.purple,
        },
        'phDown': {
          'name': 'pH Down Relay',
          'state': _random.nextBool() ? 'ON' : 'OFF',
          'icon': Icons.arrow_downward,
          'color': Colors.purple,
        },
      },
    };
  }

  // Get all sensors with detailed info for technician management
  static List<Map<String, dynamic>> getAllSensors() {
    final sensorData = getSensorData();
    return [
      {
        'id': 'TEMP_001',
        'name': 'Main Temperature Sensor',
        'type': 'temperature',
        'location': 'Greenhouse A - Zone 1',
        'value': sensorData['temperature']['value'],
        'unit': sensorData['temperature']['unit'],
        'status': sensorData['temperature']['status'],
        'icon': sensorData['temperature']['icon'],
        'color': sensorData['temperature']['color'],
        'lastCalibrated': DateTime.now().subtract(Duration(days: 15)),
        'batteryLevel': 85 + _random.nextInt(15),
        'signalStrength': 70 + _random.nextInt(30),
      },
      {
        'id': 'TEMP_002',
        'name': 'Secondary Temperature',
        'type': 'temperature',
        'location': 'Greenhouse A - Zone 2',
        'value': 15 + _random.nextInt(6),
        'unit': '°C',
        'status': 'normal',
        'icon': Icons.thermostat,
        'color': Colors.orange,
        'lastCalibrated': DateTime.now().subtract(Duration(days: 20)),
        'batteryLevel': 75 + _random.nextInt(20),
        'signalStrength': 65 + _random.nextInt(35),
      },
      {
        'id': 'TEMP_003',
        'name': 'Water Temperature',
        'type': 'temperature',
        'location': 'Water Tank',
        'value': 15 + _random.nextInt(6),
        'unit': '°C',
        'status': 'normal',
        'icon': Icons.water,
        'color': Colors.blue,
        'lastCalibrated': DateTime.now().subtract(Duration(days: 10)),
        'batteryLevel': 90 + _random.nextInt(10),
        'signalStrength': 80 + _random.nextInt(20),
      },
      {
        'id': 'HUM_001',
        'name': 'Primary Humidity Sensor',
        'type': 'humidity',
        'location': 'Greenhouse A - Zone 1',
        'value': sensorData['humidity']['value'],
        'unit': sensorData['humidity']['unit'],
        'status': sensorData['humidity']['status'],
        'icon': sensorData['humidity']['icon'],
        'color': sensorData['humidity']['color'],
        'lastCalibrated': DateTime.now().subtract(Duration(days: 12)),
        'batteryLevel': 88 + _random.nextInt(12),
        'signalStrength': 75 + _random.nextInt(25),
      },
      {
        'id': 'HUM_002',
        'name': 'Secondary Humidity',
        'type': 'humidity',
        'location': 'Greenhouse A - Zone 2',
        'value': 50 + _random.nextInt(21),
        'unit': '%',
        'status': 'normal',
        'icon': Icons.water_drop,
        'color': Colors.blue,
        'lastCalibrated': DateTime.now().subtract(Duration(days: 18)),
        'batteryLevel': 82 + _random.nextInt(18),
        'signalStrength': 70 + _random.nextInt(30),
      },
      {
        'id': 'PH_001',
        'name': 'pH Sensor',
        'type': 'ph',
        'location': 'Nutrient Tank',
        'value': sensorData['ph']['value'],
        'unit': sensorData['ph']['unit'],
        'status': sensorData['ph']['status'],
        'icon': sensorData['ph']['icon'],
        'color': sensorData['ph']['color'],
        'lastCalibrated': DateTime.now().subtract(Duration(days: 7)),
        'batteryLevel': 92 + _random.nextInt(8),
        'signalStrength': 85 + _random.nextInt(15),
      },
      {
        'id': 'EC_001',
        'name': 'EC Sensor',
        'type': 'ec',
        'location': 'Nutrient Tank',
        'value': sensorData['ec']['value'],
        'unit': sensorData['ec']['unit'],
        'status': sensorData['ec']['status'],
        'icon': sensorData['ec']['icon'],
        'color': sensorData['ec']['color'],
        'lastCalibrated': DateTime.now().subtract(Duration(days: 8)),
        'batteryLevel': 89 + _random.nextInt(11),
        'signalStrength': 82 + _random.nextInt(18),
      },
      {
        'id': 'TDS_001',
        'name': 'TDS Sensor',
        'type': 'tds',
        'location': 'Nutrient Tank',
        'value': sensorData['tds']['value'],
        'unit': sensorData['tds']['unit'],
        'status': sensorData['tds']['status'],
        'icon': sensorData['tds']['icon'],
        'color': sensorData['tds']['color'],
        'lastCalibrated': DateTime.now().subtract(Duration(days: 9)),
        'batteryLevel': 86 + _random.nextInt(14),
        'signalStrength': 78 + _random.nextInt(22),
      },
      {
        'id': 'CO2_001',
        'name': 'CO2 Sensor',
        'type': 'co2',
        'location': 'Greenhouse A - Center',
        'value': sensorData['co2']['value'],
        'unit': sensorData['co2']['unit'],
        'status': sensorData['co2']['status'],
        'icon': sensorData['co2']['icon'],
        'color': sensorData['co2']['color'],
        'lastCalibrated': DateTime.now().subtract(Duration(days: 14)),
        'batteryLevel': 84 + _random.nextInt(16),
        'signalStrength': 72 + _random.nextInt(28),
      },
      {
        'id': 'DIST_001',
        'name': 'Water Level Sensor',
        'type': 'distance',
        'location': 'Main Water Tank',
        'value': sensorData['waterLevel']['value'],
        'unit': sensorData['waterLevel']['unit'],
        'status': sensorData['waterLevel']['status'],
        'icon': sensorData['waterLevel']['icon'],
        'color': sensorData['waterLevel']['color'],
        'lastCalibrated': DateTime.now().subtract(Duration(days: 11)),
        'batteryLevel': 91 + _random.nextInt(9),
        'signalStrength': 88 + _random.nextInt(12),
      },
    ];
  }

  // Farm statistics
  static Map<String, dynamic> getFarmStats() {
    return {
      'totalFarms': 24,
      'activeBatches': 156,
      'totalRevenue': 48500 + _random.nextInt(10000),
      'activeSensors': 342,
      'totalCrops': 12,
      'totalAnimals': 450,
      'totalCaretakers': 18,
      'totalOwners': 8,
      'harvestReady': 3,
      'alertsActive': 5,
    };
  }

  // Weather data
  static Map<String, dynamic> getWeatherData() {
    final conditions = ['Sunny', 'Partly Cloudy', 'Cloudy', 'Rainy', 'Clear'];
    return {
      'condition': conditions[_random.nextInt(conditions.length)],
      'temperature': 20 + _random.nextInt(15),
      'humidity': 40 + _random.nextInt(40),
      'windSpeed': 5 + _random.nextInt(20),
      'precipitation': _random.nextInt(30),
      'uvIndex': 1 + _random.nextInt(10),
      'forecast': List.generate(7, (index) => {
        'day': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index],
        'high': 25 + _random.nextInt(10),
        'low': 15 + _random.nextInt(10),
        'condition': conditions[_random.nextInt(conditions.length)],
      }),
    };
  }

  // Activity feed
  static List<Map<String, dynamic>> getRecentActivities() {
    final activities = [
      {
        'id': '1',
        'type': 'harvest',
        'title': 'Harvest Completed',
        'description': 'Tomatoes harvested from Greenhouse A',
        'timestamp': DateTime.now().subtract(Duration(minutes: 30)),
        'user': 'John Mensah',
        'icon': Icons.agriculture,
        'color': Colors.green,
      },
      {
        'id': '2',
        'type': 'sensor',
        'title': 'Sensor Alert',
        'description': 'Low water level detected in Tank B',
        'timestamp': DateTime.now().subtract(Duration(hours: 1)),
        'user': 'System',
        'icon': Icons.warning,
        'color': Colors.orange,
      },
      {
        'id': '3',
        'type': 'maintenance',
        'title': 'Equipment Maintenance',
        'description': 'Water pump serviced and tested',
        'timestamp': DateTime.now().subtract(Duration(hours: 2)),
        'user': 'Mike Davis',
        'icon': Icons.build,
        'color': Colors.blue,
      },
      {
        'id': '4',
        'type': 'planting',
        'title': 'New Batch Started',
        'description': 'Lettuce seeds planted in Rack 3',
        'timestamp': DateTime.now().subtract(Duration(hours: 5)),
        'user': 'Sarah Wilson',
        'icon': Icons.spa,
        'color': Colors.green[700],
      },
      {
        'id': '5',
        'type': 'feeding',
        'title': 'Animal Feeding',
        'description': 'Morning feed completed for all livestock',
        'timestamp': DateTime.now().subtract(Duration(hours: 8)),
        'user': 'Tom Brown',
        'icon': Icons.pets,
        'color': Colors.brown,
      },
    ];
    return activities;
  }

  // Tasks data
  static List<Map<String, dynamic>> getTasks(String role) {
    final baseTasks = [
      {
        'id': '1',
        'title': 'Water crops in Greenhouse A',
        'priority': 'high',
        'status': 'pending',
        'dueTime': '10:00 AM',
        'assignedTo': 'John Mensah',
        'farm': 'Northern Estate',
        'category': 'irrigation',
      },
      {
        'id': '2',
        'title': 'Check pH levels in hydroponic system',
        'priority': 'medium',
        'status': 'in_progress',
        'dueTime': '11:30 AM',
        'assignedTo': 'Sarah Wilson',
        'farm': 'Southern Estate',
        'category': 'monitoring',
      },
      {
        'id': '3',
        'title': 'Feed chickens and collect eggs',
        'priority': 'high',
        'status': 'completed',
        'dueTime': '7:00 AM',
        'assignedTo': 'Tom Brown',
        'farm': 'Eastern Farm',
        'category': 'livestock',
      },
      {
        'id': '4',
        'title': 'Harvest tomatoes from Row 5',
        'priority': 'medium',
        'status': 'pending',
        'dueTime': '2:00 PM',
        'assignedTo': 'Mike Davis',
        'farm': 'Western Farm',
        'category': 'harvest',
      },
      {
        'id': '5',
        'title': 'Clean and maintain water pumps',
        'priority': 'low',
        'status': 'pending',
        'dueTime': '4:00 PM',
        'assignedTo': 'John Mensah',
        'farm': 'Northern Estate',
        'category': 'maintenance',
      },
    ];

    if (role == 'caretaker') {
      return baseTasks.where((task) => 
        task['assignedTo'] == 'John Mensah'
      ).toList();
    }
    return baseTasks;
  }

  // Crop data
  static List<Map<String, dynamic>> getCrops() {
    return [
      {
        'id': '1',
        'name': 'Tomatoes',
        'variety': 'Cherry',
        'plantedDate': DateTime.now().subtract(Duration(days: 45)),
        'harvestDate': DateTime.now().add(Duration(days: 15)),
        'status': 'growing',
        'health': 95,
        'location': 'Greenhouse A',
        'quantity': 500,
        'unit': 'plants',
        'growthStage': 'flowering',
        'image': '🍅',
      },
      {
        'id': '2',
        'name': 'Lettuce',
        'variety': 'Romaine',
        'plantedDate': DateTime.now().subtract(Duration(days: 20)),
        'harvestDate': DateTime.now().add(Duration(days: 10)),
        'status': 'growing',
        'health': 88,
        'location': 'Hydroponic Rack 2',
        'quantity': 200,
        'unit': 'heads',
        'growthStage': 'vegetative',
        'image': '🥬',
      },
      {
        'id': '3',
        'name': 'Peppers',
        'variety': 'Bell',
        'plantedDate': DateTime.now().subtract(Duration(days: 60)),
        'harvestDate': DateTime.now().add(Duration(days: 5)),
        'status': 'ready',
        'health': 92,
        'location': 'Field B',
        'quantity': 300,
        'unit': 'plants',
        'growthStage': 'fruiting',
        'image': '🌶️',
      },
      {
        'id': '4',
        'name': 'Corn',
        'variety': 'Sweet',
        'plantedDate': DateTime.now().subtract(Duration(days: 70)),
        'harvestDate': DateTime.now().add(Duration(days: 20)),
        'status': 'growing',
        'health': 85,
        'location': 'Field C',
        'quantity': 1000,
        'unit': 'plants',
        'growthStage': 'tasseling',
        'image': '🌽',
      },
    ];
  }

  // Animal/Livestock data
  static List<Map<String, dynamic>> getLivestock() {
    return [
      {
        'id': '1',
        'type': 'Chickens',
        'breed': 'Rhode Island Red',
        'count': 150,
        'health': 'good',
        'location': 'Coop A',
        'lastFed': DateTime.now().subtract(Duration(hours: 3)),
        'nextFeeding': DateTime.now().add(Duration(hours: 5)),
        'eggProduction': 120,
        'icon': '🐔',
      },
      {
        'id': '2',
        'type': 'Cattle',
        'breed': 'Holstein',
        'count': 25,
        'health': 'excellent',
        'location': 'Barn B',
        'lastFed': DateTime.now().subtract(Duration(hours: 2)),
        'nextFeeding': DateTime.now().add(Duration(hours: 6)),
        'milkProduction': 180,
        'icon': '🐄',
      },
      {
        'id': '3',
        'type': 'Goats',
        'breed': 'Boer',
        'count': 40,
        'health': 'good',
        'location': 'Pen C',
        'lastFed': DateTime.now().subtract(Duration(hours: 4)),
        'nextFeeding': DateTime.now().add(Duration(hours: 4)),
        'milkProduction': 60,
        'icon': '🐐',
      },
      {
        'id': '4',
        'type': 'Pigs',
        'breed': 'Yorkshire',
        'count': 30,
        'health': 'fair',
        'location': 'Pen D',
        'lastFed': DateTime.now().subtract(Duration(hours: 1)),
        'nextFeeding': DateTime.now().add(Duration(hours: 7)),
        'weightGain': 2.5,
        'icon': '🐷',
      },
    ];
  }

  // Financial data for owner dashboard
  static Map<String, dynamic> getFinancialData() {
    return {
      'revenue': {
        'current': 48500,
        'previous': 42000,
        'change': 15.5,
        'trend': 'up',
      },
      'expenses': {
        'current': 28300,
        'previous': 26500,
        'change': 6.8,
        'trend': 'up',
      },
      'profit': {
        'current': 20200,
        'previous': 15500,
        'change': 30.3,
        'trend': 'up',
      },
      'monthlyData': List.generate(6, (index) => {
        'month': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'][index],
        'revenue': 40000 + _random.nextInt(20000),
        'expenses': 25000 + _random.nextInt(10000),
        'profit': 15000 + _random.nextInt(10000),
      }),
      'categoryBreakdown': [
        {'category': 'Vegetables', 'amount': 18500, 'percentage': 38},
        {'category': 'Fruits', 'amount': 12300, 'percentage': 25},
        {'category': 'Livestock', 'amount': 10200, 'percentage': 21},
        {'category': 'Dairy', 'amount': 7500, 'percentage': 16},
      ],
    };
  }

  // Caretaker performance data
  static List<Map<String, dynamic>> getCaretakerPerformance() {
    return [
      {
        'id': '1',
        'name': 'John Mensah',
        'tasksCompleted': 45,
        'tasksTotal': 50,
        'efficiency': 90,
        'rating': 4.5,
        'farms': ['Northern Estate'],
        'specialization': 'Hydroponics',
        'status': 'active',
      },
      {
        'id': '2',
        'name': 'Sarah Wilson',
        'tasksCompleted': 38,
        'tasksTotal': 40,
        'efficiency': 95,
        'rating': 4.8,
        'farms': ['Southern Estate'],
        'specialization': 'Greenhouse',
        'status': 'active',
      },
      {
        'id': '3',
        'name': 'Mike Davis',
        'tasksCompleted': 42,
        'tasksTotal': 48,
        'efficiency': 87,
        'rating': 4.3,
        'farms': ['Eastern Farm'],
        'specialization': 'Livestock',
        'status': 'active',
      },
      {
        'id': '4',
        'name': 'Tom Brown',
        'tasksCompleted': 35,
        'tasksTotal': 45,
        'efficiency': 78,
        'rating': 4.0,
        'farms': ['Western Farm'],
        'specialization': 'Field Crops',
        'status': 'on_leave',
      },
    ];
  }

  // System notifications
  static List<Map<String, dynamic>> getNotifications() {
    return [
      {
        'id': '1',
        'title': 'Low Water Alert',
        'message': 'Water level in Tank B is below 30%',
        'type': 'warning',
        'timestamp': DateTime.now().subtract(Duration(minutes: 15)),
        'read': false,
        'priority': 'high',
      },
      {
        'id': '2',
        'title': 'Harvest Ready',
        'message': 'Peppers in Field B are ready for harvest',
        'type': 'success',
        'timestamp': DateTime.now().subtract(Duration(hours: 1)),
        'read': false,
        'priority': 'medium',
      },
      {
        'id': '3',
        'title': 'Maintenance Due',
        'message': 'Scheduled maintenance for irrigation system',
        'type': 'info',
        'timestamp': DateTime.now().subtract(Duration(hours: 3)),
        'read': true,
        'priority': 'low',
      },
      {
        'id': '4',
        'title': 'Temperature Alert',
        'message': 'Greenhouse A temperature exceeds optimal range',
        'type': 'warning',
        'timestamp': DateTime.now().subtract(Duration(hours: 5)),
        'read': true,
        'priority': 'high',
      },
      {
        'id': '5',
        'title': 'Task Completed',
        'message': 'Morning feeding completed by Tom Brown',
        'type': 'info',
        'timestamp': DateTime.now().subtract(Duration(hours: 8)),
        'read': true,
        'priority': 'low',
      },
    ];
  }

  // Equipment status
  static List<Map<String, dynamic>> getEquipmentStatus() {
    final statuses = ['ON', 'OFF'];
    return [
      {
        'name': 'Water Pump A',
        'status': statuses[_random.nextInt(2)],
        'lastMaintenance': DateTime.now().subtract(Duration(days: 30)),
        'nextMaintenance': DateTime.now().add(Duration(days: 60)),
        'health': 85,
      },
      {
        'name': 'Air Pump',
        'status': statuses[_random.nextInt(2)],
        'lastMaintenance': DateTime.now().subtract(Duration(days: 45)),
        'nextMaintenance': DateTime.now().add(Duration(days: 45)),
        'health': 92,
      },
      {
        'name': 'Nutrient Pump',
        'status': statuses[_random.nextInt(2)],
        'lastMaintenance': DateTime.now().subtract(Duration(days: 20)),
        'nextMaintenance': DateTime.now().add(Duration(days: 70)),
        'health': 88,
      },
      {
        'name': 'pH Controller',
        'status': 'ON',
        'lastMaintenance': DateTime.now().subtract(Duration(days: 60)),
        'nextMaintenance': DateTime.now().add(Duration(days: 30)),
        'health': 78,
      },
      {
        'name': 'Air Conditioner',
        'status': statuses[_random.nextInt(2)],
        'lastMaintenance': DateTime.now().subtract(Duration(days: 15)),
        'nextMaintenance': DateTime.now().add(Duration(days: 75)),
        'health': 95,
      },
      {
        'name': 'Grow Lights Rack 1',
        'status': statuses[_random.nextInt(2)],
        'lastMaintenance': DateTime.now().subtract(Duration(days: 90)),
        'nextMaintenance': DateTime.now().add(Duration(days: 0)),
        'health': 65,
      },
    ];
  }

  // Production metrics
  static Map<String, dynamic> getProductionMetrics() {
    return {
      'daily': {
        'vegetables': 250 + _random.nextInt(100),
        'fruits': 180 + _random.nextInt(80),
        'eggs': 120 + _random.nextInt(30),
        'milk': 180 + _random.nextInt(40),
      },
      'weekly': {
        'vegetables': 1750 + _random.nextInt(500),
        'fruits': 1260 + _random.nextInt(400),
        'eggs': 840 + _random.nextInt(200),
        'milk': 1260 + _random.nextInt(300),
      },
      'monthly': {
        'vegetables': 7500 + _random.nextInt(2000),
        'fruits': 5400 + _random.nextInt(1500),
        'eggs': 3600 + _random.nextInt(800),
        'milk': 5400 + _random.nextInt(1200),
      },
      'yieldTrend': List.generate(12, (index) => {
        'month': index + 1,
        'yield': 80 + _random.nextInt(20),
      }),
    };
  }

  // Alert generation based on sensor thresholds
  static List<AlertModel> getActiveAlerts() {
    final sensorData = getSensorData();
    final alerts = <AlertModel>[];
    
    // Check temperature
    final temp = sensorData['temperature']['value'] as int;
    if (temp < 15 || temp > 20) {
      alerts.add(AlertModel(
        id: 'alert_temp_001',
        farmId: 'farm_001',
        message: temp < 15 
            ? 'Temperature too low: ${temp}°C (optimal: 15-20°C)'
            : 'Temperature too high: ${temp}°C (optimal: 15-20°C)',
        sensorType: SensorType.temperature,
        severity: temp < 12 || temp > 25 ? AlertSeverity.high : AlertSeverity.medium,
        timestamp: DateTime.now().subtract(Duration(minutes: _random.nextInt(120))),
      ));
    }
    
    // Check humidity
    final humidity = sensorData['humidity']['value'] as int;
    if (humidity < 50 || humidity > 70) {
      alerts.add(AlertModel(
        id: 'alert_hum_001',
        farmId: 'farm_001',
        message: humidity < 50
            ? 'Humidity too low: $humidity% (optimal: 50-70%)'
            : 'Humidity too high: $humidity% (optimal: 50-70%)',
        sensorType: SensorType.humidity,
        severity: humidity < 40 || humidity > 80 ? AlertSeverity.high : AlertSeverity.medium,
        timestamp: DateTime.now().subtract(Duration(minutes: _random.nextInt(90))),
      ));
    }
    
    // Check pH
    final ph = sensorData['ph']['value'] as double;
    if (ph < 5.5 || ph > 6.5) {
      alerts.add(AlertModel(
        id: 'alert_ph_001',
        farmId: 'farm_001',
        message: ph < 5.5
            ? 'pH too low: ${ph.toStringAsFixed(1)} (optimal: 5.5-6.5)'
            : 'pH too high: ${ph.toStringAsFixed(1)} (optimal: 5.5-6.5)',
        sensorType: SensorType.ph,
        severity: ph < 5.0 || ph > 7.0 ? AlertSeverity.high : AlertSeverity.medium,
        timestamp: DateTime.now().subtract(Duration(minutes: _random.nextInt(60))),
      ));
    }
    
    // Check EC
    final ec = sensorData['ec']['value'] as double;
    if (ec < 1.0 || ec > 1.2) {
      alerts.add(AlertModel(
        id: 'alert_ec_001',
        farmId: 'farm_001',
        message: ec < 1.0
            ? 'EC too low: ${ec.toStringAsFixed(2)} mS/cm (optimal: 1.0-1.2)'
            : 'EC too high: ${ec.toStringAsFixed(2)} mS/cm (optimal: 1.0-1.2)',
        sensorType: SensorType.ec,
        severity: ec < 0.8 || ec > 1.5 ? AlertSeverity.high : AlertSeverity.low,
        timestamp: DateTime.now().subtract(Duration(minutes: _random.nextInt(45))),
      ));
    }
    
    // Check CO2
    final co2 = sensorData['co2']['value'] as int;
    if (co2 < 400 || co2 > 1200) {
      alerts.add(AlertModel(
        id: 'alert_co2_001',
        farmId: 'farm_001',
        message: co2 < 400
            ? 'CO₂ too low: $co2 ppm (optimal: 400-1200 ppm)'
            : 'CO₂ too high: $co2 ppm (optimal: 400-1200 ppm)',
        sensorType: SensorType.co2,
        severity: co2 > 1500 ? AlertSeverity.high : AlertSeverity.low,
        timestamp: DateTime.now().subtract(Duration(minutes: _random.nextInt(30))),
      ));
    }
    
    // Add some system alerts
    if (_random.nextBool()) {
      alerts.add(AlertModel(
        id: 'alert_sensor_001',
        farmId: 'farm_001',
        message: 'Sensor battery low: Temperature Sensor 2 (15% remaining)',
        sensorType: SensorType.temperature,
        severity: AlertSeverity.medium,
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
      ));
    }
    
    if (_random.nextInt(3) == 0) {
      alerts.add(AlertModel(
        id: 'alert_calib_001',
        farmId: 'farm_001',
        message: 'Calibration due: pH Sensor (last calibrated 21 days ago)',
        sensorType: SensorType.ph,
        severity: AlertSeverity.low,
        timestamp: DateTime.now().subtract(Duration(hours: 12)),
      ));
    }
    
    return alerts;
  }

  // Get all alerts (active + resolved)
  static List<AlertModel> getAllAlerts() {
    final activeAlerts = getActiveAlerts();
    final resolvedAlerts = <AlertModel>[
      AlertModel(
        id: 'alert_resolved_001',
        farmId: 'farm_001',
        message: 'Temperature normalized: 18.5°C',
        sensorType: SensorType.temperature,
        severity: AlertSeverity.medium,
        timestamp: DateTime.now().subtract(Duration(hours: 5)),
        resolved: true,
        resolvedAt: DateTime.now().subtract(Duration(hours: 3)),
        resolvedBy: 'John Mensah',
      ),
      AlertModel(
        id: 'alert_resolved_002',
        farmId: 'farm_001',
        message: 'Humidity adjusted: 62%',
        sensorType: SensorType.humidity,
        severity: AlertSeverity.low,
        timestamp: DateTime.now().subtract(Duration(days: 1)),
        resolved: true,
        resolvedAt: DateTime.now().subtract(Duration(hours: 20)),
        resolvedBy: 'System Auto',
      ),
      AlertModel(
        id: 'alert_resolved_003',
        farmId: 'farm_001',
        message: 'pH calibration completed',
        sensorType: SensorType.ph,
        severity: AlertSeverity.low,
        timestamp: DateTime.now().subtract(Duration(days: 2)),
        resolved: true,
        resolvedAt: DateTime.now().subtract(Duration(days: 2, hours: -2)),
        resolvedBy: 'Acquaye Johnson',
      ),
    ];
    
    return [...activeAlerts, ...resolvedAlerts];
  }

  // Get alert statistics
  static Map<String, dynamic> getAlertStats() {
    final allAlerts = getAllAlerts();
    final activeAlerts = allAlerts.where((a) => a.isActive).toList();
    
    return {
      'total': allAlerts.length,
      'active': activeAlerts.length,
      'resolved': allAlerts.where((a) => a.resolved).length,
      'critical': activeAlerts.where((a) => a.severity == AlertSeverity.high).length,
      'warning': activeAlerts.where((a) => a.severity == AlertSeverity.medium).length,
      'info': activeAlerts.where((a) => a.severity == AlertSeverity.low).length,
      'todayCount': activeAlerts.where((a) {
        final diff = DateTime.now().difference(a.timestamp);
        return diff.inHours < 24;
      }).length,
    };
  }
}
