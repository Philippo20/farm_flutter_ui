import 'superadmin_api_service.dart';

/// Backend data used by the fulfillment role screens.
///
/// The API returns the source collections independently, so the fulfillment
/// screens can derive their summaries without maintaining a second dataset.
class FulfillmentDataService {
  FulfillmentDataService({SuperAdminApiService? api})
      : _api = api ?? SuperAdminApiService();

  final SuperAdminApiService _api;

  Future<FulfillmentSnapshot> load() async {
    final results = await Future.wait([
      _api.getFulfillments(),
      _api.getBatches(),
      _api.getInventory(),
      _api.getUsers(),
    ]);

    return FulfillmentSnapshot(
      fulfillments: results[0],
      batches: results[1],
      inventory: results[2],
      users: results[3],
    );
  }
}

class FulfillmentSnapshot {
  const FulfillmentSnapshot({
    required this.fulfillments,
    required this.batches,
    required this.inventory,
    required this.users,
  });

  final List<Map<String, dynamic>> fulfillments;
  final List<Map<String, dynamic>> batches;
  final List<Map<String, dynamic>> inventory;
  final List<Map<String, dynamic>> users;
}
