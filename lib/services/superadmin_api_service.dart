import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class SuperAdminApiService {
  SuperAdminApiService({http.Client? client})
      : _client = client ?? http.Client();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-5u45d.ondigitalocean.app',
  );
  static const String uiBaseUrl = String.fromEnvironment(
    'UI_BASE_URL',
    defaultValue: 'https://apps.farmestates.farm',
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

  Future<Map<String, dynamic>> createSale(Map<String, dynamic> data) =>
      _submitSalesRecord('POST', '/sales/info', data);

  Future<Map<String, dynamic>> updateSale(
    String id,
    Map<String, dynamic> data,
  ) =>
      _submitSalesRecord(
        'PUT',
        '/sales/${Uri.encodeComponent(id)}',
        data,
      );

  Future<Map<String, dynamic>> updateSalesHandover(
    String id,
    Map<String, dynamic> data,
  ) async {
    final request = http.Request(
      'PATCH',
      Uri.parse('$baseUrl/sales/${Uri.encodeComponent(id)}/handover'),
    )
      ..headers['Content-Type'] = 'application/x-www-form-urlencoded'
      ..bodyFields = data.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
    final streamed = await _client.send(request).withApiTimeout();
    final response = await http.Response.fromStream(streamed);
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

  Future<void> deleteSale(String id) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/sales/${Uri.encodeComponent(id)}'))
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

  Future<Map<String, dynamic>> getSale(String id) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/sale/${Uri.encodeComponent(id)}'))
        .withApiTimeout();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to load invoice (${response.statusCode})',
        ),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid invoice response');
    }
    return decoded;
  }

  Uri salesInvoiceUrl(String id) => Uri.parse(
        '$uiBaseUrl/#/sales-invoice?id=${Uri.encodeQueryComponent(id)}',
      );

  Future<Map<String, dynamic>> _submitSalesRecord(
    String method,
    String path,
    Map<String, dynamic> data,
  ) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers['Content-Type'] = 'application/x-www-form-urlencoded'
      ..bodyFields = data.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
    final streamed = await _client.send(request).withApiTimeout();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to save delivery (${response.statusCode})',
        ),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid delivery response');
    }
    return decoded;
  }

  Future<List<Map<String, dynamic>>> getOffTakers() =>
      _getDocuments('/off-takers');
  Future<List<Map<String, dynamic>>> getOffTakerUpdateRequests() =>
      _getDocuments('/off-taker-update-requests');

  Future<Map<String, dynamic>> requestOffTakerUpdate({
    required Map<String, dynamic> data,
  }) async {
    return _submitOffTaker('POST', '/off-taker-update-requests', data);
  }

  Future<Map<String, dynamic>> reviewOffTakerUpdate({
    required String id,
    required String status,
    required String reviewedById,
    required String reviewedByName,
    String reviewNotes = '',
  }) async {
    return _submitOffTaker(
      'PUT',
      '/off-taker-update-requests/${Uri.encodeComponent(id)}/review',
      {
        'status': status,
        'reviewed_by_id': reviewedById,
        'reviewed_by_name': reviewedByName,
        'review_notes': reviewNotes,
      },
    );
  }

  Future<Map<String, dynamic>> createOffTaker({
    required Map<String, dynamic> data,
  }) async {
    return _submitOffTaker('POST', '/off-takers', data);
  }

  Future<Map<String, dynamic>> updateOffTaker({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    return _submitOffTaker(
      'PUT',
      '/off-takers/${Uri.encodeComponent(id)}',
      data,
    );
  }

  Future<void> deleteOffTaker(String id) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/off-takers/${Uri.encodeComponent(id)}'))
        .withApiTimeout();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to delete off-taker (${response.statusCode})',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _submitOffTaker(
    String method,
    String path,
    Map<String, dynamic> data,
  ) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers['Content-Type'] = 'application/x-www-form-urlencoded'
      ..bodyFields = data.map((key, value) => MapEntry(key, '$value'));
    final streamed = await _client.send(request).withApiTimeout();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to save off-taker (${response.statusCode})',
        ),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid off-taker response');
    }
    return decoded;
  }

  Future<List<Map<String, dynamic>>> getWallet() => _getDocuments('/wallet');
  Future<List<Map<String, dynamic>>> getAudits() => _getDocuments('/audits');
  Future<List<Map<String, dynamic>>> getAlerts() => _getDocuments('/alerts');
  Future<
      List<
          Map<String,
              dynamic>>> getNotifications(String recipientId) => _getDocuments(
      '/notifications?recipient_id=${Uri.encodeQueryComponent(recipientId)}');

  Future<void> markNotificationAsRead(String notificationId) async {
    final response = await _client
        .patch(
          Uri.parse(
              '$baseUrl/notifications/${Uri.encodeComponent(notificationId)}/read'),
        )
        .withApiTimeout();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback:
              'Failed to mark notification as read (${response.statusCode})',
        ),
      );
    }
  }

  Future<void> markAllNotificationsAsRead(String recipientId) async {
    final response = await _client
        .patch(
          Uri.parse(
              '$baseUrl/notifications/read-all?recipient_id=${Uri.encodeQueryComponent(recipientId)}'),
        )
        .withApiTimeout();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback:
              'Failed to mark notifications as read (${response.statusCode})',
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> getInventory() =>
      _getDocuments('/inventory');
  Future<List<Map<String, dynamic>>> getInventoryMovements() =>
      _getDocuments('/inventory/movements');
  Future<List<Map<String, dynamic>>> getFulfillments() =>
      _getDocuments('/fulfillments');

  Future<Map<String, dynamic>> inspectHarvestIntake({
    required String batchId,
    required Map<String, dynamic> data,
  }) async {
    return _postFulfillmentAction(
      '/fulfillments/intake/${Uri.encodeComponent(batchId)}/inspect',
      data,
      fallback: 'Failed to save the harvest inspection',
    );
  }

  Future<Map<String, dynamic>> releaseHarvestToPackaging({
    required String batchId,
    required String releasedById,
    required String releasedByName,
  }) async {
    return _postFulfillmentAction(
      '/fulfillments/intake/${Uri.encodeComponent(batchId)}/release',
      {
        'released_by_id': releasedById,
        'released_by_name': releasedByName,
      },
      fallback: 'Failed to release the harvest to packaging',
    );
  }

  Future<Map<String, dynamic>> recordPackagingOutput({
    required String fulfillmentId,
    required Map<String, dynamic> data,
  }) {
    return _postFulfillmentAction(
      '/fulfillments/${Uri.encodeComponent(fulfillmentId)}/packaging-record',
      data,
      fallback: 'Failed to record packaging output',
    );
  }

  Future<Map<String, dynamic>> recordQualityInspection({
    required String fulfillmentId,
    required Map<String, dynamic> data,
  }) {
    return _postFulfillmentAction(
      '/fulfillments/${Uri.encodeComponent(fulfillmentId)}/quality-inspection',
      data,
      fallback: 'Failed to save the quality inspection',
    );
  }

  Future<Map<String, dynamic>> recordQualityDecision({
    required String fulfillmentId,
    required Map<String, dynamic> data,
  }) {
    return _postFulfillmentAction(
      '/fulfillments/${Uri.encodeComponent(fulfillmentId)}/quality-decision',
      data,
      fallback: 'Failed to save the quality decision',
    );
  }

  Future<Map<String, dynamic>> _postFulfillmentAction(
    String path,
    Map<String, dynamic> data, {
    required String fallback,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        )
        .withApiTimeout();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: '$fallback (${response.statusCode})',
        ),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw SuperAdminApiException('$fallback: invalid server response');
    }
    return decoded;
  }

  Future<List<Map<String, dynamic>>> getSensors() => _getDocuments('/sensors');
  Future<List<Map<String, dynamic>>> getFundRequests() =>
      _getDocuments('/fund-requests');
  Future<List<Map<String, dynamic>>> getFarmTasks() =>
      _getDocuments('/farm-tasks');
  Future<List<Map<String, dynamic>>> getFarmRecords() =>
      _getDocuments('/farm-records');
  Future<List<Map<String, dynamic>>> getInputConfirmations({
    String? caretakerId,
    String? farmId,
  }) {
    final query = <String>[];
    if (caretakerId != null && caretakerId.isNotEmpty) {
      query.add('caretaker_id=${Uri.encodeQueryComponent(caretakerId)}');
    }
    if (farmId != null && farmId.isNotEmpty) {
      query.add('farm_id=${Uri.encodeQueryComponent(farmId)}');
    }
    final suffix = query.isEmpty ? '' : '?${query.join('&')}';
    return _getDocuments('/input-confirmations$suffix');
  }

  Future<Map<String, dynamic>> getCaretakerSettings(String userId) async {
    final response = await _client
        .get(Uri.parse(
            '$baseUrl/caretaker-settings?user_id=${Uri.encodeQueryComponent(userId)}'))
        .withApiTimeout();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback:
              'Failed to load caretaker settings (${response.statusCode})',
        ),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['settings'] is! Map) {
      throw const SuperAdminApiException('Invalid caretaker settings response');
    }
    return Map<String, dynamic>.from(decoded['settings'] as Map);
  }

  Future<Map<String, dynamic>> updateCaretakerSettings({
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    final response = await _client
        .put(
          Uri.parse(
              '$baseUrl/caretaker-settings/${Uri.encodeComponent(userId)}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(settings),
        )
        .withApiTimeout();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback:
              'Failed to save caretaker settings (${response.statusCode})',
        ),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['settings'] is! Map) {
      throw const SuperAdminApiException(
          'Invalid caretaker settings save response');
    }
    return Map<String, dynamic>.from(decoded['settings'] as Map);
  }

  Future<List<Map<String, dynamic>>> getSensorReadings(String serialNumber) =>
      _getDocuments('/sensors/${Uri.encodeComponent(serialNumber)}/readings');
  Future<List<Map<String, dynamic>>> getSensorReadingsAll() =>
      _getDocuments('/sensor-readings');

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

  Future<Map<String, dynamic>> createWalletWithdrawal({
    required Map<String, dynamic> data,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/wallet/withdrawals'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: data.map((key, value) => MapEntry(key, value.toString())),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback:
              'Failed to submit withdrawal request (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid withdrawal request response');
    }
    if (decoded['error'] is String) {
      throw SuperAdminApiException(decoded['error'].toString());
    }
    return decoded;
  }

  Future<Map<String, dynamic>> createWalletBankAccount({
    required Map<String, dynamic> data,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/wallet/bank-accounts'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: data.map((key, value) => MapEntry(key, value.toString())),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to add payout account (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid payout account response');
    }
    if (decoded['error'] is String) {
      throw SuperAdminApiException(decoded['error'].toString());
    }
    return decoded;
  }

  Future<Map<String, dynamic>> createFarmTask({
    required Map<String, dynamic> data,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/farm-tasks/info'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: data.map((key, value) => MapEntry(key, value.toString())),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to assign farm task (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid farm task create response');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> createFarmRecord({
    required Map<String, dynamic> data,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/farm-records/info'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: data.map((key, value) => MapEntry(key, value.toString())),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to submit farm record (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid farm record create response');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> updateInputConfirmationStatus({
    required String id,
    required String status,
    required String caretakerId,
    required String caretakerName,
  }) async {
    final response = await _client.patch(
      Uri.parse(
          '$baseUrl/input-confirmations/${Uri.encodeComponent(id)}/status'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'status': status,
        'caretaker_id': caretakerId,
        'caretaker_name': caretakerName,
      },
    ).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback:
              'Failed to update input confirmation (${response.statusCode})',
        ),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException(
          'Invalid input confirmation update response');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> updateFarmTask({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client
        .put(
          Uri.parse('$baseUrl/farm-tasks/${Uri.encodeComponent(id)}'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: data.map((key, value) => MapEntry(key, value.toString())),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to update farm task (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid farm task update response');
    }
    return decoded;
  }

  Future<void> deleteFarmTask(String id) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl/farm-tasks/${Uri.encodeComponent(id)}'))
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to delete farm task (${response.statusCode})',
        ),
      );
    }
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
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/batches/info'),
    )..fields.addAll(
        data.map((key, value) => MapEntry(key, value.toString())),
      );
    final streamedResponse = await _client.send(request).withApiTimeout();
    final response =
        await http.Response.fromStream(streamedResponse).withApiTimeout();

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

  Future<Map<String, dynamic>> updateBatch({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/batches/${Uri.encodeComponent(id)}'),
    )..fields.addAll(
        data.map((key, value) => MapEntry(key, value.toString())),
      );
    final streamedResponse = await _client.send(request).withApiTimeout();
    final response =
        await http.Response.fromStream(streamedResponse).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to update batch (${response.statusCode})',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid batch update response');
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
        'plant_variety': value(data['plant_variety'], ''),
        'total_heads': value(data['total_heads'], '0'),
        'total_weight': value(data['total_weight'], '0'),
        'harvest_received_images': value(data['harvest_received_images'], ''),
        'packaging_supervisor_id':
            value(data['packaging_supervisor_id'], 'superadmin'),
        'packaging_type': value(data['packaging_type'], 'Delivery'),
        'packaging_weight': value(data['packaging_weight'], '0'),
        'total_packaged_weight': value(data['total_packaged_weight'], '0'),
        'total_package_count': value(data['total_package_count'], '0'),
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
        'address': value(data['address'], ''),
        'scheduled_date': dateValue(data['scheduled_date']),
        'eta': value(data['eta'], ''),
        'temperature': value(data['temperature'], 'N/A'),
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
        if (data.containsKey('plant_variety'))
          'plant_variety': value(data['plant_variety'], ''),
        'total_heads': value(data['total_heads'], '0'),
        'total_weight': value(data['total_weight'], '0'),
        'harvest_received_images': value(data['harvest_received_images'], ''),
        'packaging_supervisor_id':
            value(data['packaging_supervisor_id'], 'system'),
        'packaging_type': value(data['packaging_type'], ''),
        'packaging_weight': value(data['packaging_weight'], '0'),
        'total_packaged_weight': value(data['total_packaged_weight'], '0'),
        if (data.containsKey('total_package_count'))
          'total_package_count': value(data['total_package_count'], '0'),
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
        'address': value(data['address'], ''),
        'scheduled_date': dateValue(data['scheduled_date']),
        'eta': value(data['eta'], ''),
        'temperature': value(data['temperature'], 'N/A'),
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
    required String actorId,
    required String actorRole,
    String driverLicenseNumber = '',
    String vehicle = '',
    String vehicleType = '',
    double vehicleCapacityKg = 0,
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
        'actor_id': actorId,
        'actor_role': actorRole,
        'driver_license_number': driverLicenseNumber,
        'vehicle': vehicle,
        'vehicle_type': vehicleType,
        'vehicle_capacity_kg': vehicleCapacityKg.toString(),
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

  Future<Map<String, dynamic>> updateUserProfile({
    required String id,
    required String name,
    required String email,
    required String address,
  }) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/users/${Uri.encodeComponent(id)}/profile'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'name': name, 'email': email, 'address': address},
    ).withApiTimeout();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(response.body,
            fallback: 'Failed to update profile (${response.statusCode})'),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid profile update response');
    }
    return decoded;
  }

  Future<void> updateUserPassword({
    required String id,
    required String password,
  }) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/users/${Uri.encodeComponent(id)}/password'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'password': password},
    ).withApiTimeout();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(response.body,
            fallback: 'Failed to update password (${response.statusCode})'),
      );
    }
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
    required String actorId,
    required String actorRole,
    String driverLicenseNumber = '',
    String vehicle = '',
    String vehicleType = '',
    double vehicleCapacityKg = 0,
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
        'actor_id': actorId,
        'actor_role': actorRole,
        'driver_license_number': driverLicenseNumber,
        'vehicle': vehicle,
        'vehicle_type': vehicleType,
        'vehicle_capacity_kg': vehicleCapacityKg.toString(),
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
    required int maturityMinValue,
    required int maturityMaxValue,
    required String maturityUnit,
    required String imageFileName,
    required String status,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/plant_type/info'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'name': name,
        'category': category,
        'maturity_min_value': maturityMinValue.toString(),
        'maturity_max_value': maturityMaxValue.toString(),
        'maturity_unit': maturityUnit.toLowerCase(),
        // Compatibility with an API container that has not been redeployed yet.
        'months_to_maturity': (maturityUnit.toLowerCase() == 'months'
                ? maturityMaxValue
                : (maturityMaxValue / 4.345).ceil())
            .toString(),
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
    required int maturityMinValue,
    required int maturityMaxValue,
    required String maturityUnit,
    required String imageFileName,
    required String status,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/plant_type/${Uri.encodeComponent(id)}'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'name': name,
        'category': category,
        'maturity_min_value': maturityMinValue.toString(),
        'maturity_max_value': maturityMaxValue.toString(),
        'maturity_unit': maturityUnit.toLowerCase(),
        // Compatibility with an API container that has not been redeployed yet.
        'months_to_maturity': (maturityUnit.toLowerCase() == 'months'
                ? maturityMaxValue
                : (maturityMaxValue / 4.345).ceil())
            .toString(),
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
    required int plantDurationValue,
    required String plantDurationUnit,
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
        'plant_duration_value': plantDurationValue.toString(),
        'plant_duration_unit': plantDurationUnit,
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
    required int plantDurationValue,
    required String plantDurationUnit,
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
        'plant_duration_value': plantDurationValue.toString(),
        'plant_duration_unit': plantDurationUnit,
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

  Future<void> deleteCropVariety(String id) async {
    final response = await _client
        .delete(
          Uri.parse('$baseUrl/crops/${Uri.encodeComponent(id)}'),
        )
        .withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to delete crop variety (${response.statusCode})',
        ),
      );
    }

    if (response.body.trim().isEmpty) return;
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic> && decoded['error'] is String) {
      throw SuperAdminApiException(decoded['error'].toString());
    }
  }

  Future<Map<String, dynamic>> createPackage({
    required String packageName,
    required double weightCapacity,
    required String unit,
    required String materialUsed,
    required double quantityAvailable,
    required double costPerUnit,
    required String createdBy,
    String cropVarietyId = '',
    String cropVarietyName = '',
    String cropName = '',
    String status = 'Active',
  }) async {
    final now = DateTime.now().toUtc();
    final response = await _client.post(
      Uri.parse('$baseUrl/package/info'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'package_name': packageName,
        'crop_variety_id': cropVarietyId,
        'crop_variety_name': cropVarietyName,
        'crop_name': cropName,
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

  Future<Map<String, dynamic>> updatePackage({
    required String id,
    required String packageName,
    required String cropVarietyId,
    required String cropVarietyName,
    required String cropName,
    required String materialUsed,
    required double weightCapacity,
    required String unit,
    required double quantityAvailable,
    required double costPerUnit,
    required String createdBy,
    required DateTime createdAt,
    required String status,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/package/${Uri.encodeComponent(id)}'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'package_name': packageName,
        'crop_variety_id': cropVarietyId,
        'crop_variety_name': cropVarietyName,
        'crop_name': cropName,
        'material_used': materialUsed,
        'weight_capacity': weightCapacity.toString(),
        'unit': unit,
        'quantity_available': quantityAvailable.toString(),
        'cost_per_unit': costPerUnit.toString(),
        'created_by': createdBy,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'status': status,
      },
    ).withApiTimeout();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to update package (${response.statusCode})',
        ),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid package update response');
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

  Future<Map<String, dynamic>> getTraceabilityOverview() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/traceability/overview'))
        .withApiTimeout();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback:
              'Failed to load traceability console (${response.statusCode})',
        ),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const SuperAdminApiException('Invalid traceability response');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> updateTraceabilitySettings(
    Map<String, dynamic> settings,
  ) async {
    final response = await _client
        .put(
          Uri.parse('$baseUrl/traceability/settings'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(settings),
        )
        .withApiTimeout();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback:
              'Failed to update traceability settings (${response.statusCode})',
        ),
      );
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<Map<String, dynamic>> updateBatchPublication({
    required String batchId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client
        .post(
          Uri.parse(
            '$baseUrl/traceability/batches/${Uri.encodeComponent(batchId)}/publish',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        )
        .withApiTimeout();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback:
              'Failed to update batch publication (${response.statusCode})',
        ),
      );
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<Map<String, dynamic>> saveTraceabilityPromotion({
    String? id,
    required Map<String, dynamic> data,
  }) async {
    final uri = id == null
        ? Uri.parse('$baseUrl/traceability/promotions')
        : Uri.parse(
            '$baseUrl/traceability/promotions/${Uri.encodeComponent(id)}',
          );
    final response = await (id == null
            ? _client.post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(data),
              )
            : _client.put(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(data),
              ))
        .withApiTimeout();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to save promotion (${response.statusCode})',
        ),
      );
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<void> deleteTraceabilityPromotion({
    required String id,
    required String actorId,
    required String actorRole,
  }) async {
    final uri = Uri.parse('$baseUrl/traceability/promotions/$id').replace(
      queryParameters: {'actor_id': actorId, 'actor_role': actorRole},
    );
    final response = await _client.delete(uri).withApiTimeout();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback: 'Failed to delete promotion (${response.statusCode})',
        ),
      );
    }
  }

  Future<Map<String, dynamic>> updateTraceabilityFeedback({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client
        .put(
          Uri.parse(
            '$baseUrl/traceability/feedback/${Uri.encodeComponent(id)}',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        )
        .withApiTimeout();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SuperAdminApiException(
        _extractErrorMessage(
          response.body,
          fallback:
              'Failed to update traceability feedback (${response.statusCode})',
        ),
      );
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
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

    final rawDocuments = decoded['users'] ??
        decoded['documents'] ??
        decoded['off_takers'] ??
        decoded['off_taker_update_requests'] ??
        decoded['sales'] ??
        [];
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
        if (detail is Map) {
          final message = detail['message']?.toString().trim();
          if (message != null && message.isNotEmpty) return message;
        }
        if (detail is List) {
          final messages = detail.whereType<Map>().map((item) {
            final location = item['loc'];
            final field = location is List && location.isNotEmpty
                ? location.last.toString()
                : 'request';
            final message = item['msg']?.toString() ?? 'Invalid value';
            return '$field: $message';
          }).where((message) => message.isNotEmpty);
          if (messages.isNotEmpty) return messages.join('\n');
        }
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
