import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_owner_sidebar.dart';
import '../../core/widgets/farm_owner_header.dart';
import '../../core/widgets/farm_owner_mobile_drawer.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';
import '../../utils/csv_download_launcher.dart';

/// Reports Screen for Farm Owner
/// View and download financial and performance reports
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final SuperAdminApiService _api = SuperAdminApiService();
  int _selectedNavIndex = 4;
  String _selectedReportType = 'All';
  String _selectedPeriod = 'Last 30 Days';
  String _selectedFarmId = 'all';
  String _selectedStatus = 'All Statuses';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, dynamic>> _farms = [];
  final List<Map<String, dynamic>> _sales = [];
  final List<Map<String, dynamic>> _batches = [];
  final List<Map<String, dynamic>> _fulfillments = [];
  final List<Map<String, dynamic>> _fundRequests = [];
  final List<Map<String, dynamic>> _walletRecords = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final results = await Future.wait([
        _api.getFarms(),
        _api.getSales(),
        _api.getBatches(),
        _api.getFulfillments(),
        _api.getFundRequests(),
        _api.getWallet(),
      ]);
      if (!mounted) return;
      setState(() {
        _farms
          ..clear()
          ..addAll(results[0]);
        _sales
          ..clear()
          ..addAll(results[1]);
        _batches
          ..clear()
          ..addAll(results[2]);
        _fulfillments
          ..clear()
          ..addAll(results[3]);
        _fundRequests
          ..clear()
          ..addAll(results[4]);
        _walletRecords
          ..clear()
          ..addAll(results[5]);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted || !showLoading) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  String _docId(Map<String, dynamic> doc) =>
      (doc[r'$id'] ?? doc['id'] ?? doc['farm_id'] ?? doc['farmID'] ?? '')
          .toString();

  String _value(Map<String, dynamic> doc, List<String> keys,
      {String fallback = ''}) {
    for (final key in keys) {
      final value = doc[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String _normalise(dynamic value) =>
      value?.toString().trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ??
      '';

  num _numValue(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
  }

  DateTime? _dateValue(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }

  DateTime get _periodStart {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Last 7 Days':
        return now.subtract(const Duration(days: 7));
      case 'Last 3 Months':
        return DateTime(now.year, now.month - 3, now.day);
      case 'Last Year':
        return DateTime(now.year - 1, now.month, now.day);
      case 'Last 30 Days':
      default:
        return now.subtract(const Duration(days: 30));
    }
  }

  bool _isWithinPeriod(DateTime? date) {
    if (date == null) return true;
    return !date.isBefore(_periodStart);
  }

  bool _isOwnerFarm(Map<String, dynamic> farm) {
    final user = ref.read(authProvider).user;
    if (user == null) return true;
    final ownerTokens = {
      _normalise(user.id),
      _normalise(user.email),
      _normalise(user.name),
    }..removeWhere((token) => token.isEmpty);
    final farmTokens = {
      _normalise(_value(farm, ['ownerID', 'owner_id', 'ownerId'])),
      _normalise(_value(farm, ['owner_name', 'ownerName'])),
      _normalise(_value(farm, ['owner_email', 'ownerEmail'])),
    }..removeWhere((token) => token.isEmpty || token == 'unassigned');
    return farmTokens.any(ownerTokens.contains);
  }

  List<Map<String, dynamic>> get _ownerFarms =>
      _farms.where(_isOwnerFarm).toList();

  Set<String> get _ownerFarmIds =>
      _ownerFarms.map(_docId).where((id) => id.isNotEmpty).toSet();

  Set<String> get _ownerFarmNames => _ownerFarms
      .map((farm) => _value(farm, ['name', 'farm_name']))
      .where((name) => name.isNotEmpty)
      .map(_normalise)
      .toSet();

  Set<String> get _ownerBatchIds => _batches
      .where((batch) {
        final farmId = _value(batch, ['farm_id', 'farmID', 'farmId']);
        final farmName = _value(batch, ['farm_name', 'farmName']);
        return (farmId.isNotEmpty && _ownerFarmIds.contains(farmId)) ||
            (farmName.isNotEmpty &&
                _ownerFarmNames.contains(_normalise(farmName)));
      })
      .expand((batch) => [
            _value(batch, ['batch_id']),
            _value(batch, ['batch_no']),
            _value(batch, ['batch_number']),
            _docId(batch),
          ])
      .where((id) => id.isNotEmpty)
      .toSet();

  bool _matchesOwnerFarm(Map<String, dynamic> doc) {
    final farmId = _value(doc, ['farm_id', 'farmID', 'farmId']);
    final farmName = _value(doc, ['farm_name', 'farmName']);
    final batchId = _value(doc, ['batch_id', 'batch_no', 'batch_number']);
    return (farmId.isNotEmpty && _ownerFarmIds.contains(farmId)) ||
        (farmName.isNotEmpty &&
            _ownerFarmNames.contains(_normalise(farmName))) ||
        (batchId.isNotEmpty && _ownerBatchIds.contains(batchId));
  }

  bool _matchesSelectedFarm(Map<String, dynamic> doc) {
    if (_selectedFarmId == 'all') return true;
    final selectedFarm = _selectedFarmRecord;
    final selectedIds = <String>{_selectedFarmId};
    final selectedNames = <String>{};
    if (selectedFarm != null) {
      selectedIds.add(_docId(selectedFarm));
      selectedIds.add(_value(selectedFarm, ['farm_id', 'farmID', 'farmId']));
      selectedNames.add(_normalise(_farmDisplayName(selectedFarm)));
      selectedNames
          .add(_normalise(_value(selectedFarm, ['name', 'farm_name'])));
    }
    selectedIds.removeWhere((id) => id.isEmpty);
    selectedNames.removeWhere((name) => name.isEmpty);
    final farmId = _normalise(_value(doc, ['farm_id', 'farmID', 'farmId']));
    final farmName = _normalise(_value(doc, ['farm_name', 'farmName']));
    final batchId = _value(doc, ['batch_id', 'batch_no', 'batch_number']);
    return selectedIds.map(_normalise).contains(farmId) ||
        selectedNames.contains(farmName) ||
        (batchId.isNotEmpty && _batchMatchesSelectedFarm(batchId));
  }

  bool _batchMatchesSelectedFarm(String batchId) {
    if (_selectedFarmId == 'all') return true;
    final selectedFarm = _selectedFarmRecord;
    final selectedIds = <String>{_selectedFarmId};
    final selectedNames = <String>{};
    if (selectedFarm != null) {
      selectedIds.add(_docId(selectedFarm));
      selectedIds.add(_value(selectedFarm, ['farm_id', 'farmID', 'farmId']));
      selectedNames.add(_normalise(_farmDisplayName(selectedFarm)));
      selectedNames
          .add(_normalise(_value(selectedFarm, ['name', 'farm_name'])));
    }
    selectedIds.removeWhere((id) => id.isEmpty);
    selectedNames.removeWhere((name) => name.isEmpty);
    return _batches.any((batch) {
      final ids = {
        _value(batch, ['batch_id']),
        _value(batch, ['batch_no']),
        _value(batch, ['batch_number']),
        _docId(batch),
      }..removeWhere((id) => id.isEmpty);
      if (!ids.contains(batchId)) return false;
      final farmId = _normalise(_value(batch, ['farm_id', 'farmID', 'farmId']));
      final farmName = _normalise(_value(batch, ['farm_name', 'farmName']));
      return selectedIds.map(_normalise).contains(farmId) ||
          selectedNames.contains(farmName);
    });
  }

  bool _matchesSelectedStatus(Map<String, dynamic> doc) {
    if (_selectedStatus == 'All Statuses') return true;
    final selected = _normalise(_selectedStatus);
    final statuses = {
      _normalise(_value(doc, ['status'])),
      _normalise(_value(doc, ['production_status'])),
      _normalise(_value(doc, ['financial_status'])),
      _normalise(_value(doc, ['delivery_status'])),
      _normalise(_value(doc, ['withdrawal_status'])),
      if (doc.containsKey('paid')) doc['paid'] == true ? 'paid' : 'pending',
    }..removeWhere((status) => status.isEmpty);
    return statuses.contains(selected);
  }

  List<Map<String, dynamic>> get _ownerSales => _sales.where((sale) {
        return _matchesOwnerFarm(sale) &&
            _matchesSelectedFarm(sale) &&
            _matchesSelectedStatus(sale) &&
            _isWithinPeriod(_dateValue(sale['payment_date'] ??
                sale['delivered_at'] ??
                sale[r'$createdAt']));
      }).toList();

  List<Map<String, dynamic>> get _ownerBatches => _batches.where((batch) {
        return _matchesOwnerFarm(batch) &&
            _matchesSelectedFarm(batch) &&
            _matchesSelectedStatus(batch) &&
            _isWithinPeriod(
                _dateValue(batch['created_at'] ?? batch['start_date']));
      }).toList();

  List<Map<String, dynamic>> get _ownerFulfillments =>
      _fulfillments.where((fulfillment) {
        return _matchesOwnerFarm(fulfillment) &&
            _matchesSelectedFarm(fulfillment) &&
            _matchesSelectedStatus(fulfillment) &&
            _isWithinPeriod(_dateValue(fulfillment['packaging_date_time'] ??
                fulfillment['received_date_time'] ??
                fulfillment[r'$createdAt']));
      }).toList();

  List<Map<String, dynamic>> get _ownerFundRequests =>
      _fundRequests.where((request) {
        return _matchesOwnerFarm(request) &&
            _matchesSelectedFarm(request) &&
            _matchesSelectedStatus(request) &&
            _isWithinPeriod(
                _dateValue(request['request_date'] ?? request[r'$createdAt']));
      }).toList();

  List<Map<String, dynamic>> get _ownerWalletRecords {
    final user = ref.read(authProvider).user;
    if (user == null) return _walletRecords;
    final tokens = {
      _normalise(user.id),
      _normalise(user.name),
      _normalise(user.email),
    }..removeWhere((token) => token.isEmpty);
    return _walletRecords
        .where((record) {
          final recordTokens = {
            _normalise(_value(record, ['user_id'])),
            _normalise(_value(record, ['user_name'])),
            _normalise(_value(record, ['email'])),
            _normalise(_value(record, ['created_by'])),
          }..removeWhere((token) => token.isEmpty);
          return recordTokens.any(tokens.contains);
        })
        .where(_matchesSelectedStatus)
        .toList();
  }

  String _farmOptionId(Map<String, dynamic> farm) {
    final id = _docId(farm);
    if (id.isNotEmpty) return id;
    return _value(farm, ['farm_id', 'farmID', 'farmId', 'name', 'farm_name']);
  }

  String _farmDisplayName(Map<String, dynamic> farm) {
    return _value(farm, ['name', 'farm_name'], fallback: _farmOptionId(farm));
  }

  Map<String, dynamic>? get _selectedFarmRecord {
    if (_selectedFarmId == 'all') return null;
    for (final farm in _ownerFarms) {
      final ids = {
        _farmOptionId(farm),
        _docId(farm),
        _value(farm, ['farm_id', 'farmID', 'farmId']),
      }..removeWhere((id) => id.isEmpty);
      if (ids.contains(_selectedFarmId)) return farm;
    }
    return null;
  }

  List<Map<String, String>> get _farmFilterOptions {
    final seen = <String>{};
    final options = <Map<String, String>>[
      {'id': 'all', 'label': 'All My Farms'},
    ];
    final sortedFarms = [..._ownerFarms]
      ..sort((a, b) => _farmDisplayName(a).compareTo(_farmDisplayName(b)));
    for (final farm in sortedFarms) {
      final id = _farmOptionId(farm);
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      options.add({'id': id, 'label': _farmDisplayName(farm)});
    }
    return options;
  }

  List<String> get _statusFilterItems {
    final statuses = <String>{};
    for (final doc in [
      ..._sales,
      ..._batches,
      ..._fulfillments,
      ..._fundRequests,
      ..._walletRecords,
    ]) {
      for (final key in [
        'status',
        'production_status',
        'financial_status',
        'delivery_status',
        'withdrawal_status',
      ]) {
        final value = _value(doc, [key]);
        if (value.isNotEmpty) statuses.add(value);
      }
      if (doc.containsKey('paid')) {
        statuses.add(doc['paid'] == true ? 'Paid' : 'Pending');
      }
    }
    final sorted = statuses.toList()..sort();
    return ['All Statuses', ...sorted];
  }

  String _formatMoney(num value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return 'GHS $whole.${parts.last}';
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _periodLabel() {
    final end = DateTime.now();
    return '${_formatDate(_periodStart)} to ${_formatDate(end)}';
  }

  num get _totalRevenue => _ownerSales.fold<num>(
        0,
        (sum, sale) => sum + _numValue(sale['total_amount'] ?? sale['amount']),
      );

  num get _totalYieldKg {
    final fulfillmentWeight = _ownerFulfillments.fold<num>(
      0,
      (sum, item) => sum + _numValue(item['total_weight']),
    );
    if (fulfillmentWeight > 0) return fulfillmentWeight;
    return _ownerBatches.fold<num>(
      0,
      (sum, batch) => sum + _numValue(batch['total_weight_kg']),
    );
  }

  num get _totalInputCost => _ownerFundRequests.fold<num>(
        0,
        (sum, request) => sum + _numValue(request['amount']),
      );

  num get _walletWithdrawals => _ownerWalletRecords.where((record) {
        final type = _normalise(_value(record, ['transaction_type']));
        final status = _normalise(_value(record, ['withdrawal_status']));
        return type == 'withdrawal' &&
            ['approved', 'paid', 'completed', 'disbursed'].contains(status);
      }).fold<num>(
        0,
        (sum, record) =>
            sum + _numValue(record['amount'] ?? record['total_debits']),
      );

  List<Map<String, dynamic>> get _reports {
    final generatedAt = _formatDate(DateTime.now());
    final period = _periodLabel();
    return [
      {
        'id': 'FIN-${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Financial Report',
        'type': 'Financial',
        'period': period,
        'date': generatedAt,
        'size': '${_ownerSales.length + _ownerFundRequests.length} records',
        'icon': Icons.description,
        'color': AppColors.primary,
        'rows': _financialRows(),
      },
      {
        'id': 'PER-${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Farm Performance Summary',
        'type': 'Performance',
        'period': period,
        'date': generatedAt,
        'size': '${_ownerFarms.length} farms',
        'icon': Icons.analytics,
        'color': AppColors.success,
        'rows': _performanceRows(),
      },
      {
        'id': 'REV-${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Revenue Analysis',
        'type': 'Revenue',
        'period': period,
        'date': generatedAt,
        'size': '${_ownerSales.length} sales',
        'icon': Icons.trending_up,
        'color': AppColors.info,
        'rows': _revenueRows(),
      },
      {
        'id': 'YLD-${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Yield Report',
        'type': 'Yield',
        'period': period,
        'date': generatedAt,
        'size': '${_ownerBatches.length + _ownerFulfillments.length} records',
        'icon': Icons.inventory,
        'color': AppColors.warning,
        'rows': _yieldRows(),
      },
    ];
  }

  List<List<String>> _financialRows() {
    return [
      ['Metric', 'Value'],
      ['Total revenue', _formatMoney(_totalRevenue)],
      ['Approved withdrawals', _formatMoney(_walletWithdrawals)],
      ['Fund requests', _formatMoney(_totalInputCost)],
      ['Sales records', _ownerSales.length.toString()],
      ['Fund request records', _ownerFundRequests.length.toString()],
    ];
  }

  List<List<String>> _performanceRows() {
    return [
      ['Metric', 'Value'],
      ['Owned farms', _ownerFarms.length.toString()],
      ['Active batches', _ownerBatches.length.toString()],
      ['Fulfillment records', _ownerFulfillments.length.toString()],
      ['Total yield', '${_totalYieldKg.toStringAsFixed(2)} kg'],
      ['Period', _periodLabel()],
    ];
  }

  List<List<String>> _revenueRows() {
    final rows = <List<String>>[
      ['Date', 'Farm', 'Batch', 'Buyer', 'Quantity', 'Amount', 'Paid'],
    ];
    for (final sale in _ownerSales) {
      rows.add([
        _formatDate(_dateValue(sale['payment_date'] ??
                sale['delivered_at'] ??
                sale[r'$createdAt']) ??
            DateTime.now()),
        _value(sale, ['farm_name'], fallback: 'Linked by batch'),
        _value(sale, ['batch_number', 'batch_id']),
        _value(sale, ['buyer_name']),
        _numValue(sale['quantity_delivered']).toStringAsFixed(2),
        _formatMoney(_numValue(sale['total_amount'] ?? sale['amount'])),
        (sale['paid'] == true).toString(),
      ]);
    }
    if (rows.length == 1) {
      rows.add(['No sales found', '', '', '', '', _formatMoney(0), 'false']);
    }
    return rows;
  }

  List<List<String>> _yieldRows() {
    final rows = <List<String>>[
      ['Date', 'Farm', 'Crop', 'Batch', 'Yield kg', 'Loss %', 'Status'],
    ];
    for (final batch in _ownerBatches) {
      rows.add([
        _formatDate(_dateValue(batch['actual_harvest_date'] ??
                batch['end_date'] ??
                batch['created_at'] ??
                batch['start_date']) ??
            DateTime.now()),
        _value(batch, ['farm_name']),
        _value(batch, ['plant_name', 'plant_type']),
        _value(batch, ['batch_no', 'batch_id']),
        _numValue(batch['total_weight_kg']).toStringAsFixed(2),
        '0.00',
        _value(batch, ['production_status'], fallback: 'Pending'),
      ]);
    }
    for (final fulfillment in _ownerFulfillments) {
      rows.add([
        _formatDate(_dateValue(fulfillment['packaging_date_time'] ??
                fulfillment['received_date_time'] ??
                fulfillment[r'$createdAt']) ??
            DateTime.now()),
        _value(fulfillment, ['farm_name']),
        _value(fulfillment, ['plant_type']),
        _value(fulfillment, ['batch_number']),
        _numValue(fulfillment['total_weight']).toStringAsFixed(2),
        _numValue(fulfillment['yield_loss_percentage']).toStringAsFixed(2),
        _value(fulfillment, ['status'], fallback: 'Pending'),
      ]);
    }
    if (rows.length == 1) {
      rows.add(['No yield data found', '', '', '', '0.00', '0.00', '']);
    }
    return rows;
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _fileSafe(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _exportReport(Map<String, dynamic> report) async {
    final rows = (report['rows'] as List<List<String>>?) ?? const [];
    final csv = rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
    final fileName =
        '${_fileSafe(report['title'].toString())}-${_formatDate(DateTime.now())}.csv';
    final downloaded = await downloadCsvFile(fileName: fileName, csv: csv);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(downloaded
            ? '${report['title']} downloaded'
            : 'Report download cancelled'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _exportCombinedReports() async {
    final buffer = StringBuffer();
    for (final report in _reports) {
      buffer.writeln(report['title']);
      final rows = (report['rows'] as List<List<String>>?) ?? const [];
      for (final row in rows) {
        buffer.writeln(row.map(_escapeCsv).join(','));
      }
      buffer.writeln();
    }
    final downloaded = await downloadCsvFile(
      fileName: 'farm-owner-reports-${_formatDate(DateTime.now())}.csv',
      csv: buffer.toString(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            downloaded ? 'Reports downloaded' : 'Report download cancelled'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Farm Owner';
    final userEmail = authState.user?.email ?? 'owner@farmestates.com';
    final userRole = 'Farm Owner';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? FarmOwnerMobileDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (i) => setState(() => _selectedNavIndex = i),
              userName: userName,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      bottomNavigationBar: isMobile
          ? SafeArea(top: false, child: _buildBottomNavigation(isDark))
          : null,
    );
  }

  Widget _buildDesktopLayout(
      bool isDark, String userName, String userEmail, String userRole) {
    return Row(
      children: [
        FarmOwnerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) {
            setState(() => _selectedNavIndex = index);
          },
          userName: userName,
          userEmail: userEmail,
          userRole: userRole,
        ),
        Expanded(
          child: Column(
            children: [
              FarmOwnerHeader(
                userName: userName,
                onNotificationTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildContent(isDark)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark, String userName) {
    return Column(
      children: [
        FarmOwnerHeader(
          userName: userName,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildContent(isDark)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (_isLoading) {
      return const AdminDataSkeleton(rowCount: 4, showStats: true);
    }
    if (_errorMessage != null) {
      return _buildErrorState(isDark);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(isDark),
        SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
        _buildFilterControls(isDark),
        SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
        _buildReportTypes(isDark),
        SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
        _buildReportsList(isDark),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assessment_outlined,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
            size: 42,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Unable to load reports',
            style: AppTypography.h6.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _loadReportData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports',
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : AppColors.neutral200,
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: [
                      'Last 7 Days',
                      'Last 30 Days',
                      'Last 3 Months',
                      'Last Year'
                    ].map((period) {
                      return DropdownMenuItem(
                        value: period,
                        child: Text(
                          period,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 12,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedPeriod = value!);
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton(
                onPressed: _exportCombinedReports,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Icon(Icons.download, size: 20),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Reports',
          style: AppTypography.h4.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : AppColors.neutral100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color:
                      isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
                ),
              ),
              child: DropdownButton<String>(
                value: _selectedPeriod,
                items: [
                  'Last 7 Days',
                  'Last 30 Days',
                  'Last 3 Months',
                  'Last Year'
                ].map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(
                      period,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPeriod = value!);
                },
                underline: const SizedBox(),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: _exportCombinedReports,
              icon: const Icon(Icons.download),
              label: const Text('Generate Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterControls(bool isDark) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final farmOptions = _farmFilterOptions;
    final statusItems = _statusFilterItems;
    if (!farmOptions.any((option) => option['id'] == _selectedFarmId)) {
      _selectedFarmId = 'all';
    }
    if (!statusItems.contains(_selectedStatus)) {
      _selectedStatus = 'All Statuses';
    }

    final children = [
      _buildFarmFilterDropdown(
        isDark,
        value: _selectedFarmId,
        options: farmOptions,
        onChanged: (value) => setState(() => _selectedFarmId = value),
      ),
      _buildFilterDropdown(
        isDark,
        label: 'Status',
        value: _selectedStatus,
        items: statusItems,
        onChanged: (value) => setState(() => _selectedStatus = value),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: isMobile
          ? Column(
              children: [
                for (final child in children) ...[
                  child,
                  if (child != children.last)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            )
          : Row(
              children: [
                Expanded(child: children[0]),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: children[1]),
              ],
            ),
    );
  }

  Widget _buildFarmFilterDropdown(
    bool isDark, {
    required String value,
    required List<Map<String, String>> options,
    required ValueChanged<String> onChanged,
  }) {
    final safeValue =
        options.any((option) => option['id'] == value) ? value : 'all';
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Farm',
        labelStyle: AppTypography.caption.copyWith(
          color: isDark ? Colors.white60 : AppColors.textSecondary,
        ),
        isDense: true,
        filled: true,
        fillColor: isDark ? Colors.white10 : AppColors.neutral100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
          ),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option['id'],
              child: Text(
                option['label'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            onChanged(value);
          },
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    bool isDark, {
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.caption.copyWith(
          color: isDark ? Colors.white60 : AppColors.textSecondary,
        ),
        isDense: true,
        filled: true,
        fillColor: isDark ? Colors.white10 : AppColors.neutral100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
          ),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            onChanged(value);
          },
        ),
      ),
    );
  }

  Widget _buildReportTypes(bool isDark) {
    final types = [
      'All',
      ..._reports
          .map((report) => report['type'].toString())
          .where((type) => type.isNotEmpty)
          .toSet()
    ];
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types.map((type) {
          final isSelected = type == _selectedReportType;
          return Padding(
            padding: EdgeInsets.only(
                right: isMobile ? AppSpacing.xs : AppSpacing.sm),
            child: FilterChip(
              label: Text(
                type,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedReportType = type);
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white : AppColors.textPrimary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: isMobile ? 11 : 12,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppSpacing.xs : AppSpacing.sm,
                vertical: isMobile ? 4 : 8,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReportsList(bool isDark) {
    final filteredReports = _selectedReportType == 'All'
        ? _reports
        : _reports
            .where((report) => report['type'] == _selectedReportType)
            .toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Reports',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 16 : 18,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (filteredReports.isEmpty)
          _buildEmptyReportsState(isDark)
        else
          ...filteredReports.map((report) {
            return _buildReportCard(report, isDark);
          }),
      ],
    );
  }

  Widget _buildEmptyReportsState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_outlined,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
            size: 36,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No reports found',
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: (report['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              report['icon'] as IconData,
              color: report['color'] as Color,
              size: isMobile ? 20 : 24,
            ),
          ),
          SizedBox(width: isMobile ? AppSpacing.sm : AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  report['title'] as String,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: isMobile ? 13 : 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? 3 : 4),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 4 : 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (report['color'] as Color).withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        report['type'] as String,
                        style: AppTypography.caption.copyWith(
                          color: report['color'] as Color,
                          fontSize: isMobile ? 9 : 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${report['period']} • ${report['size']}',
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? Colors.white.withOpacity(0.6)
                            : AppColors.textSecondary,
                        fontSize: isMobile ? 9 : 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _exportReport(report),
                icon: Icon(
                  Icons.download,
                  size: isMobile ? 20 : 24,
                ),
                color: AppColors.primary,
                tooltip: 'Download',
                padding: EdgeInsets.all(isMobile ? 4 : 8),
                constraints: BoxConstraints(
                  minWidth: isMobile ? 32 : 48,
                  minHeight: isMobile ? 32 : 48,
                ),
              ),
              if (!isMobile)
                Text(
                  report['date'] as String,
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/farm-owner'
      },
      {
        'icon': Icons.agriculture_outlined,
        'label': 'Farm',
        'index': 1,
        'route': '/farm-owner/farm'
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'Wallet',
        'index': 2,
        'route': '/farm-owner/digital-wallet'
      },
      {
        'icon': Icons.analytics_outlined,
        'label': 'Analytics',
        'index': 3,
        'route': '/farm-owner/analytics'
      },
      {
        'icon': Icons.assessment_outlined,
        'label': 'Reports',
        'index': 4,
        'route': '/farm-owner/reports'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.take(5).map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final isSelected = index == _selectedNavIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_selectedNavIndex != index) {
                        setState(() => _selectedNavIndex = index);
                        try {
                          Navigator.pushReplacementNamed(context, route);
                        } catch (e) {
                          try {
                            Navigator.pushNamed(context, route);
                          } catch (e2) {
                            debugPrint('Navigation error: $e2');
                          }
                        }
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 24,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : AppColors.textSecondary),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
