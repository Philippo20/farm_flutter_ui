import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class SuperAdminApiService {
  SuperAdminApiService({http.Client? client})
      : _client = client ?? http.Client();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  final http.Client _client;

  Future<List<Map<String, dynamic>>> getUsers() => _getDocuments('/users');
  Future<List<Map<String, dynamic>>> getFarms() => _getDocuments('/farms');
  Future<List<Map<String, dynamic>>> getBatches() => _getDocuments('/batches');
  Future<List<Map<String, dynamic>>> getPlantTypes() =>
      _getDocuments('/plant_type');
  Future<List<Map<String, dynamic>>> getCrops() => _getDocuments('/crops');
  Future<List<Map<String, dynamic>>> getPackages() => _getDocuments('/package');
  Future<List<Map<String, dynamic>>> getPricing() => _getDocuments('/pricing');
  Future<List<Map<String, dynamic>>> getSales() => _getDocuments('/sales');
  Future<List<Map<String, dynamic>>> getAudits() => _getDocuments('/audits');
  Future<List<Map<String, dynamic>>> getInventory() =>
      _getDocuments('/inventory');
  Future<List<Map<String, dynamic>>> getInventoryMovements() =>
      _getDocuments('/inventory/movements');
  Future<List<Map<String, dynamic>>> getFulfillments() =>
      _getDocuments('/fulfillments');
  Future<List<Map<String, dynamic>>> getSensors() => _getDocuments('/sensors');
  Future<List<Map<String, dynamic>>> getFundRequests() =>
      _getDocuments('/fund-requests');

  Future<List<Map<String, dynamic>>> getSensorReadings(String serialNumber) =>
      _getDocuments('/sensors/${Uri.encodeComponent(serialNumber)}/readings');

  Future<Map<String, dynamic>> createFundRequest({
    required Map<String, dynamic> data,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/fund-requests/info'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: data.map((key, value) => MapEntry(key, value.toString())),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to create fund request (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException(
          'Invalid fund request create response');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> updateFundRequest({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client
        .put(
          Uri.parse('$baseUrl/fund-requests/${Uri.encodeComponent(id)}'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: data.map((key, value) => MapEntry(key, value.toString())),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to update fund request (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException(
          'Invalid fund request update response');
    }
    return decoded;
  }

  Future<void> deleteFundRequest(String id) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/fund-requests/${Uri.encodeComponent(id)}'))
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to delete fund request (${response.statusCode})',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> createBatch({
    required Map<String, dynamic> data,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/batches/info'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: data.map((key, value) => MapEntry(key, value.toString())),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to create batch (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid batch create response');
    }
    if (decoded['error'] is String) {
      throw SuperAdminApiException(decoded['error'].toString());
    }
    return decoded;
  }

  Future<Map<String, dynamic>> createSensor({
    required Map<String, dynamic> data,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/sensors/info'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: data.map((key, value) => MapEntry(key, value.toString())),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to create sensor (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid sensor create response');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> updateSensor({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client
        .put(
          Uri.parse('$baseUrl/sensors/${Uri.encodeComponent(id)}'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: data.map((key, value) => MapEntry(key, value.toString())),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to update sensor (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid sensor update response');
    }
    return decoded;
  }

  Future<void> deleteSensor(String id) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/sensors/${Uri.encodeComponent(id)}'))
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to delete sensor (${response.statusCode})',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> createFulfillment({
    required Map<String, dynamic> data,
  }) async {
    String value(dynamic item, String fallback) {
      final text = item?.toString() ?? '';
      return text.trim().isEmpty ? fallback : text;
    }

    String dateValue(dynamic item) {
      final text = item?.toString() ?? '';
      if (text.trim().isNotEmpty) return text.split('T').first;
      return DateTime.now().toIso8601String().split('T').first;
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/fulfillment/info'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'batch_number': value(data['batch_number'], 'Unassigned Batch'),
        'farm_manager_id': value(data['farm_manager_id'], 'superadmin'),
        'farm_name': value(data['farm_name'], 'Unassigned Farm'),
        'plant_type': value(data['plant_type'], 'Crop'),
        'total_heads': value(data['total_heads'], '0'),
        'total_weight': value(data['total_weight'], '0'),
        'harvest_received_images': value(data['harvest_received_images'], ''),
        'packaging_supervisor_id':
            value(data['packaging_supervisor_id'], 'superadmin'),
        'packaging_type': value(data['packaging_type'], 'Delivery'),
        'packaging_weight': value(data['packaging_weight'], '0'),
        'total_packaged_weight': value(data['total_packaged_weight'], '0'),
        'packaging_waste_type': value(data['packaging_waste_type'], 'None'),
        'packaging_waste_weight': value(data['packaging_waste_weight'], '0'),
        'packaging_images': value(data['packaging_images'], ''),
        'yield_loss_percentage': value(data['yield_loss_percentage'], '0'),
        'received_date_time': dateValue(data['received_date_time']),
        'packaging_date_time': dateValue(data['packaging_date_time']),
        'sent_to_sales': value(data['sent_to_sales'], 'false'),
        'sent_to_sales_date_time': dateValue(data['sent_to_sales_date_time']),
        'status': value(data['status'], 'Packaged'),
        'delivery_status': value(data['delivery_status'], 'Scheduled'),
        'driver_name': value(data['driver_name'], 'Unassigned'),
        'vehicle': value(data['vehicle'], 'Pending'),
        'destination': value(data['destination'], 'Sales Hub'),
        'eta': value(data['eta'], ''),
        'priority': value(data['priority'], 'Medium'),
        'delivery_note': value(data['delivery_note'], ''),
      },
    ).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to create delivery (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid delivery create response');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> updateFulfillment({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    String value(dynamic item, String fallback) {
      final text = item?.toString() ?? '';
      return text.trim().isEmpty ? fallback : text;
    }

    String dateValue(dynamic item) {
      final text = item?.toString() ?? '';
      if (text.trim().isNotEmpty) return text.split('T').first;
      return DateTime.now().toIso8601String().split('T').first;
    }

    final response = await _client.put(
      Uri.parse('$baseUrl/fulfillments/${Uri.encodeComponent(id)}'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'batch_number': value(data['batch_number'], 'Unassigned Batch'),
        'farm_manager_id': value(data['farm_manager_id'], 'system'),
        'farm_name': value(data['farm_name'], 'Unassigned Farm'),
        'plant_type': value(data['plant_type'], 'Crop'),
        'total_heads': value(data['total_heads'], '0'),
        'total_weight': value(data['total_weight'], '0'),
        'harvest_received_images': value(data['harvest_received_images'], ''),
        'packaging_supervisor_id':
            value(data['packaging_supervisor_id'], 'system'),
        'packaging_type': value(data['packaging_type'], ''),
        'packaging_weight': value(data['packaging_weight'], '0'),
        'total_packaged_weight': value(data['total_packaged_weight'], '0'),
        'packaging_waste_type': value(data['packaging_waste_type'], ''),
        'packaging_waste_weight': value(data['packaging_waste_weight'], '0'),
        'packaging_images': value(data['packaging_images'], ''),
        'yield_loss_percentage': value(data['yield_loss_percentage'], '0'),
        'received_date_time': dateValue(data['received_date_time']),
        'packaging_date_time': dateValue(data['packaging_date_time']),
        'sent_to_sales': value(data['sent_to_sales'], 'false'),
        'sent_to_sales_date_time': dateValue(data['sent_to_sales_date_time']),
        'status': value(data['status'], 'Received'),
        'delivery_status': value(data['delivery_status'], 'Pending Approval'),
        'driver_name': value(data['driver_name'], 'Unassigned'),
        'vehicle': value(data['vehicle'], 'Pending'),
        'destination': value(data['destination'], 'Sales Hub'),
        'eta': value(data['eta'], ''),
        'priority': value(data['priority'], 'Medium'),
        'delivery_note': value(data['delivery_note'], ''),
      },
    ).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to update delivery (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid delivery update response');
    }
    return decoded;
  }

  Future<void> deleteFulfillment(String id) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/fulfillments/${Uri.encodeComponent(id)}'))
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to delete delivery (${response.statusCode})',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> createInventory({
    required String itemName,
    required String itemType,
    required String unit,
    required double quantityAvailable,
    required double reorderLevel,
    required double unitPrice,
    required String supplierName,
    required String batchNumber,
    required String farmId,
    required String addedBy,
    required String status,
    required String notes,
    required String dateAdded,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/inventory/info'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'item_name': itemName,
        'item_type': itemType,
        'unit': unit,
        'quantity_available': quantityAvailable.toString(),
        'reorder_level': reorderLevel.toString(),
        'unit_price': unitPrice.toString(),
        'total_value': (quantityAvailable * unitPrice).toString(),
        'supplier_name': supplierName,
        'batch_number': batchNumber,
        'farm_id': farmId,
        'added_by': addedBy,
        'status': status,
        'notes': notes,
        'date_added': dateAdded,
      },
    ).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to create inventory (${response.statusCode})',
        ),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid inventory create response');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> updateInventory({
    required String id,
    required String itemName,
    required String itemType,
    required String unit,
    required double quantityAvailable,
    required double reorderLevel,
    required double unitPrice,
    required String supplierName,
    required String batchNumber,
    required String farmId,
    required String addedBy,
    required String status,
    required String notes,
    required String dateAdded,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/inventory/${Uri.encodeComponent(id)}'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'item_name': itemName,
        'item_type': itemType,
        'unit': unit,
        'quantity_available': quantityAvailable.toString(),
        'reorder_level': reorderLevel.toString(),
        'unit_price': unitPrice.toString(),
        'total_value': (quantityAvailable * unitPrice).toString(),
        'supplier_name': supplierName,
        'batch_number': batchNumber,
        'farm_id': farmId,
        'added_by': addedBy,
        'status': status,
        'notes': notes,
        'date_added': dateAdded,
      },
    ).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to update inventory (${response.statusCode})',
        ),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid inventory update response');
    }
    return decoded;
  }

  Future<void> deleteInventory(String id) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/inventory/${Uri.encodeComponent(id)}'))
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to delete inventory (${response.statusCode})',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> createInventoryMovement({
    required String itemId,
    required String itemName,
    required String farmName,
    required String movementType,
    required double quantity,
    required String unit,
    required String actor,
    String farmId = '',
    String note = '',
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/inventory/movements'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'item_id': itemId,
        'item_name': itemName,
        'farm_id': farmId,
        'farm_name': farmName,
        'movement_type': movementType,
        'quantity': quantity.toString(),
        'unit': unit,
        'actor': actor,
        'note': note,
      },
    ).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to record inventory movement',
        ),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid movement create response');
    }
    return decoded;
  }

  Future<List<Map<String, dynamic>>> getBackups() async {
    final response =
        await _client.get(Uri.parse('$baseUrl/backups')).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to load backups',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const SuperAdminApiException('Invalid backups response');
    }
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> getBackupStats() async {
    final response =
        await _client.get(Uri.parse('$baseUrl/backups/stats')).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to load backup statistics',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid backup stats response');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> createBackup({String? notes}) async {
    final uri = Uri.parse('$baseUrl/backups/create').replace(
      queryParameters: notes == null || notes.trim().isEmpty
          ? null
          : {'notes': notes.trim()},
    );
    final response = await _client.post(uri).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to create backup',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid backup create response');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> getBackupDownload(String id) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/backups/${Uri.encodeComponent(id)}/download'))
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to get backup download link',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid backup download response');
    }
    return decoded;
  }

  Future<void> deleteBackup(String id) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/backups/${Uri.encodeComponent(id)}'))
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to delete backup',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> restoreBackup({
    required String fileName,
    required Uint8List fileBytes,
    bool replaceCollections = true,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/backups/restore').replace(
        queryParameters: {
          'replace_collections': replaceCollections.toString(),
        },
      ),
    )..files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

    final streamed = await request.send().withApiTimeout();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to restore backup',
        ),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid backup restore response');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> updateBackupRetention({
    required String id,
    required int retentionDays,
  }) async {
    final response = await _client
        .patch(
          Uri.parse('$baseUrl/backups/${Uri.encodeComponent(id)}/retention'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'retention_days': retentionDays}),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to update backup retention',
        ),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid retention update response');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> getSystemConfig() async {
    final response =
        await _client.get(Uri.parse('$baseUrl/system-config')).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to load system configuration',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['config'] is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid system config response');
    }
    return Map<String, dynamic>.from(decoded['config'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> updateSystemConfig(
      Map<String, dynamic> config) async {
    final response = await _client
        .put(
          Uri.parse('$baseUrl/system-config'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(config),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to update system configuration',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['config'] is! Map<String, dynamic>) {
      throw const SuperAdminApiException(
          'Invalid system config update response');
    }
    return Map<String, dynamic>.from(decoded['config'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> generateSensorIngestApiKey(
      {required String updatedBy}) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/system-config/sensor-api-key'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'updated_by': updatedBy}),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to generate sensor API key',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['config'] is! Map<String, dynamic>) {
      throw const SuperAdminApiException(
          'Invalid sensor API key generation response');
    }
    return Map<String, dynamic>.from(decoded['config'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> updateUser({
    required String id,
    required String name,
    required String email,
    required String password,
    required String address,
    required String role,
    required String phone,
    required String department,
    required String status,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/users/${Uri.encodeComponent(id)}'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'name': name,
        'email': email,
        'password': password,
        'address': address,
        'role': role,
        'phone': phone,
        'department': department,
        'status': status,
      },
    ).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to update user (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid update response');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String password,
    required String address,
    required String role,
    required String phone,
    required String department,
    required String status,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/users/signup'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'name': name,
        'email': email,
        'password': password,
        'address': address,
        'role': role,
        'phone': phone,
        'department': department,
        'status': status,
      },
    ).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to create user (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid create response');
    }
    return decoded;
  }

  Future<void> deleteUser(String id) async {
    final response = await _client
        .delete(
          Uri.parse('$baseUrl/users/${Uri.encodeComponent(id)}'),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to delete user (${response.statusCode})',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> createFarm({
    required String name,
    required String location,
    required String ownerID,
    required String caretakerID,
    String farmManagerId = 'Unassigned',
    String technicianId = 'Unassigned',
    required String plantType,
    required String plantVariety,
    required String tierType,
    required String status,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/farms/info'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'name': name,
        'location': location,
        'ownerID': ownerID,
        'caretakerID': caretakerID,
        'farm_manager_id': farmManagerId,
        'technician_id': technicianId,
        'plant_type': plantType,
        'plant_variety': plantVariety,
        'tier_type': tierType,
        'status': status,
      },
    ).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to create farm (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid farm create response');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> updateFarm({
    required String id,
    required String name,
    required String location,
    required String ownerID,
    required String caretakerID,
    String farmManagerId = 'Unassigned',
    String technicianId = 'Unassigned',
    required String plantType,
    required String plantVariety,
    required String tierType,
    required String status,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/farms/${Uri.encodeComponent(id)}'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'name': name,
        'location': location,
        'ownerID': ownerID,
        'caretakerID': caretakerID,
        'farm_manager_id': farmManagerId,
        'technician_id': technicianId,
        'plant_type': plantType,
        'plant_variety': plantVariety,
        'tier_type': tierType,
        'status': status,
      },
    ).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to update farm (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid farm update response');
    }
    return decoded;
  }

  Future<void> deleteFarm(String id) async {
    final response = await _client
        .delete(
          Uri.parse('$baseUrl/farms/${Uri.encodeComponent(id)}'),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to delete farm (${response.statusCode})',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> generateFarmSensorApiKey({
    required String farmId,
    required String updatedBy,
  }) async {
    final response = await _client
        .post(
          Uri.parse(
              '$baseUrl/farms/${Uri.encodeComponent(farmId)}/sensor-api-key'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'updated_by': updatedBy}),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to generate farm sensor API key',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['farm'] is! Map<String, dynamic>) {
      throw const SuperAdminApiException(
          'Invalid farm sensor API key response');
    }
    return Map<String, dynamic>.from(decoded['farm'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createPlantType({
    required String name,
    required String category,
    required int monthsToMaturity,
    required String imageFileName,
    required String status,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/plant_type/info'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'name': name,
        'category': category,
        'months_to_maturity': monthsToMaturity.toString(),
        'image_url': imageFileName,
        'status': status.toLowerCase(),
      },
    ).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to create plant type (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid plant type create response');
    }
    if (decoded['error'] is String) {
      throw SuperAdminApiException(decoded['error'].toString());
    }
    return decoded;
  }

  Future<Map<String, dynamic>> updatePlantType({
    required String id,
    required String name,
    required String category,
    required int monthsToMaturity,
    required String imageFileName,
    required String status,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/plant_type/${Uri.encodeComponent(id)}'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'name': name,
        'category': category,
        'months_to_maturity': monthsToMaturity.toString(),
        'image_url': imageFileName,
        'status': status.toLowerCase(),
      },
    ).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to update plant type (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid plant type update response');
    }
    if (decoded['error'] is String) {
      throw SuperAdminApiException(decoded['error'].toString());
    }
    return decoded;
  }

  Future<Map<String, dynamic>> createPlantCategory({
    required String name,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/plant_type/categories'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'name': name,
        'status': 'active',
      },
    ).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to create category (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid category create response');
    }
    return decoded;
  }

  Future<void> deletePlantCategory(String id) async {
    final response = await _client
        .delete(
          Uri.parse(
              '$baseUrl/plant_type/categories/${Uri.encodeComponent(id)}'),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to delete category (${response.statusCode})',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> createCropVariety({
    required String cropName,
    required String varietyName,
    required String imageFileName,
    required Uint8List imageBytes,
    required String plantDuration,
    required double harvestingWeight,
    required String company,
    required double sproutingRatio,
    required double ecMin,
    required double ecMax,
    required double phMin,
    required double phMax,
    required double tempMin,
    required double tempMax,
    required double humidityMin,
    required double humidityMax,
    required String createdBy,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/crops/info'),
    )
      ..fields.addAll({
        'crop_name': cropName,
        'variety_name': varietyName,
        'plant_duration': plantDuration,
        'harvesting_weight': harvestingWeight.toString(),
        'company': company,
        'sprouting_ratio': sproutingRatio.toString(),
        'ec_level_min': ecMin.toString(),
        'ec_level_max': ecMax.toString(),
        'ph_level_min': phMin.toString(),
        'ph_level_max': phMax.toString(),
        'temp_min': tempMin.toString(),
        'temp_max': tempMax.toString(),
        'humidity_min': humidityMin.toString(),
        'humidity_max': humidityMax.toString(),
        'created_by': createdBy,
      })
      ..files.add(
        http.MultipartFile.fromBytes(
          'crop_image',
          imageBytes,
          filename: imageFileName,
        ),
      );

    final streamed = await request.send().withApiTimeout();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to create crop variety (${response.statusCode})',
        ),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid crop variety response');
    }
    if (decoded['error'] is String) {
      throw SuperAdminApiException(decoded['error'].toString());
    }
    return decoded;
  }

  Future<Map<String, dynamic>> updateCropVariety({
    required String id,
    required String cropName,
    required String varietyName,
    required String plantDuration,
    required double harvestingWeight,
    required String company,
    required double sproutingRatio,
    required double ecMin,
    required double ecMax,
    required double phMin,
    required double phMax,
    required double tempMin,
    required double tempMax,
    required double humidityMin,
    required double humidityMax,
    required String createdBy,
    String? imageFileName,
    Uint8List? imageBytes,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/crops/info/${Uri.encodeComponent(id)}'),
    )..fields.addAll({
        'crop_name': cropName,
        'variety_name': varietyName,
        'plant_duration': plantDuration,
        'harvesting_weight': harvestingWeight.toString(),
        'company': company,
        'sprouting_ratio': sproutingRatio.toString(),
        'ec_level_min': ecMin.toString(),
        'ec_level_max': ecMax.toString(),
        'ph_level_min': phMin.toString(),
        'ph_level_max': phMax.toString(),
        'temp_min': tempMin.toString(),
        'temp_max': tempMax.toString(),
        'humidity_min': humidityMin.toString(),
        'humidity_max': humidityMax.toString(),
        'created_by': createdBy,
      });

    if (imageBytes != null && imageFileName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'crop_image',
          imageBytes,
          filename: imageFileName,
        ),
      );
    }

    final streamed = await request.send().withApiTimeout();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to update crop variety (${response.statusCode})',
        ),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException(
          'Invalid crop variety update response');
    }
    if (decoded['error'] is String) {
      throw SuperAdminApiException(decoded['error'].toString());
    }
    return decoded;
  }

  Future<Map<String, dynamic>> createPackage({
    required String packageName,
    required double weightCapacity,
    required String unit,
    required String materialUsed,
    required double quantityAvailable,
    required double costPerUnit,
    required String createdBy,
    String plantTypeId = 'all',
    String plantTypeName = 'All Plant Types',
    String status = 'Active',
  }) async {
    final now = DateTime.now().toUtc();
    final response = await _client.post(
      Uri.parse('$baseUrl/package/info'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'package_name': packageName,
        'plant_type_id': plantTypeId,
        'plant_type_name': plantTypeName,
        'material_used': materialUsed,
        'weight_capacity': weightCapacity.toString(),
        'unit': unit,
        'quantity_available': quantityAvailable.toString(),
        'cost_per_unit': costPerUnit.toString(),
        'created_by': createdBy,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'status': status,
      },
    ).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to create package (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid package create response');
    }
    if (decoded['error'] is String) {
      throw SuperAdminApiException(decoded['error'].toString());
    }
    return decoded;
  }

  Future<Map<String, dynamic>> createPricing({
    required String pricingType,
    required String farmId,
    required String farmName,
    required String plantType,
    required String cropVariety,
    required String packaging,
    required String unit,
    required double regularPrice,
    required double bulkPrice,
    required String status,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/pricing/info'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'pricing_type': pricingType,
        'farm_id': farmId,
        'farm_name': farmName,
        'plant_type': plantType,
        'crop_variety': cropVariety,
        'packaging': packaging,
        'unit': unit,
        'regular_price': regularPrice.toString(),
        'bulk_price': bulkPrice.toString(),
        'status': status,
      },
    ).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to create pricing (${response.statusCode})',
        ),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid pricing create response');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> updatePricing({
    required String id,
    required String pricingType,
    required String farmId,
    required String farmName,
    required String plantType,
    required String cropVariety,
    required String packaging,
    required String unit,
    required double regularPrice,
    required double bulkPrice,
    required String status,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/pricing/${Uri.encodeComponent(id)}'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'pricing_type': pricingType,
        'farm_id': farmId,
        'farm_name': farmName,
        'plant_type': plantType,
        'crop_variety': cropVariety,
        'packaging': packaging,
        'unit': unit,
        'regular_price': regularPrice.toString(),
        'bulk_price': bulkPrice.toString(),
        'status': status,
      },
    ).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to update pricing (${response.statusCode})',
        ),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid pricing update response');
    }
    return decoded;
  }

  Future<void> deletePricing(String id) async {
    final response = await _client
        .delete(
          Uri.parse('$baseUrl/pricing/${Uri.encodeComponent(id)}'),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to delete pricing (${response.statusCode})',
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _getDocuments(String path) async {
    final response =
        await _client.get(Uri.parse('$baseUrl$path')).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        'Request failed for $path (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw SuperAdminApiException('Invalid response for $path');
    }

    final rawDocuments = decoded['users'] ?? decoded['documents'] ?? [];
    if (rawDocuments is! List) {
      throw SuperAdminApiException('Invalid document list for $path');
    }

    return rawDocuments
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _extractErrorMessage(String body, {required String fallback}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) return detail;
      }
    } catch (_) {
      // Use fallback when the API response is not JSON.
    }
    return fallback;
  }
}

class SuperAdminApiException implements Exception {
  const SuperAdminApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

extension _ApiFuture<T> on Future<T> {
  Future<T> withApiTimeout() async {
    try {
      return await timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw const SuperAdminApiException(
        'The service is temporarily unavailable. Check the API and database connection, then retry.',
      );
    } on http.ClientException {
      throw const SuperAdminApiException(
        'Could not connect to the service. Check your network and API server, then retry.',
      );
    }
  }
}
