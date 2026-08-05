import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/permission_gate.dart';
import '../../core/models/user/user_permissions.dart';
import '../../core/widgets/farm_manager_sidebar.dart';
import '../../core/widgets/farm_manager_header.dart';
import '../../core/widgets/farm_manager_mobile_drawer.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/app_filter_chip.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../services/superadmin_api_service.dart';

/// Inventory Management Screen
/// Manage farm inputs, track stock levels, and handle inventory transactions
class InventoryManagementScreen extends ConsumerStatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  ConsumerState<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState
    extends ConsumerState<InventoryManagementScreen> {
  final SuperAdminApiService _api = SuperAdminApiService();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _showLowStockOnly = false;
  int _selectedNavIndex = 2;
  final _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, dynamic>> _farms = [];
  final List<Map<String, dynamic>> _inventory = [];
  final List<Map<String, dynamic>> _movements = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _api.getFarms(),
        _api.getInventory(),
        _api.getInventoryMovements(),
      ]);
      if (!mounted) return;
      final assignedFarms = results[0].where(_isAssignedToCurrentManager);
      setState(() {
        _farms
          ..clear()
          ..addAll(assignedFarms);
        _inventory
          ..clear()
          ..addAll(
              results[1].where(_matchesAssignedFarm).map(_mapInventoryItem));
        _movements
          ..clear()
          ..addAll(results[2].where(_matchesAssignedFarm));
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  String _docId(Map<String, dynamic> doc) =>
      (doc[r'$id'] ?? doc['id'] ?? doc['farm_id'] ?? '').toString();

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

  double _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _isAssignedToCurrentManager(Map<String, dynamic> farm) {
    final user = ref.read(authProvider).user;
    if (user == null) return true;
    final managerId = _value(farm, ['farm_manager_id', 'farmManagerId']);
    final managerName = _value(farm, ['farm_manager_name', 'farmManagerName']);
    return managerId == user.id ||
        managerId == user.email ||
        managerName.toLowerCase() == user.name.toLowerCase();
  }

  bool _matchesAssignedFarm(Map<String, dynamic> doc) {
    if (_farms.isEmpty) return true;
    final farmIds = _farms.map(_docId).where((id) => id.isNotEmpty).toSet();
    final farmNames = _farms
        .map((farm) => _value(farm, ['name', 'farm_name']))
        .where((name) => name.isNotEmpty)
        .toSet();
    final farmId = _value(doc, ['farm_id', 'farmID', 'farmId']);
    final farmName = _value(doc, ['farm_name', 'farmName']);
    return farmIds.contains(farmId) || farmNames.contains(farmName);
  }

  Map<String, dynamic> _mapInventoryItem(Map<String, dynamic> doc) {
    final quantity = _doubleValue(
        doc['quantity_available'] ?? doc['quantity'] ?? doc['stock']);
    final reorderLevel = _doubleValue(
        doc['reorder_level'] ?? doc['minStock'] ?? doc['min_stock']);
    final unitCost = _doubleValue(doc['unit_price'] ?? doc['unitCost']);
    final maxStock = [
      quantity,
      reorderLevel * 2,
      _doubleValue(doc['maxStock'] ?? doc['max_stock']),
    ].reduce((a, b) => a > b ? a : b);
    final status = _inventoryStatus(quantity, reorderLevel, doc);
    final color = status == 'Out of Stock'
        ? AppColors.error
        : status == 'Low Stock'
            ? AppColors.warning
            : AppColors.success;
    return {
      ...doc,
      'id': _docId(doc),
      'name': _value(doc, ['item_name', 'name'], fallback: 'Inventory Item'),
      'category': _value(doc, ['item_type', 'category'], fallback: 'Other'),
      'quantity': quantity,
      'unit': _value(doc, ['unit'], fallback: 'unit'),
      'minStock': reorderLevel,
      'maxStock': maxStock <= 0 ? 1.0 : maxStock,
      'unitCost': unitCost,
      'expiryDate': _value(doc, ['expiry_date', 'expiryDate']),
      'status': status,
      'color': color,
      'farmName': _value(doc, ['farm_name', 'farmName']),
      'farmId': _value(doc, ['farm_id', 'farmID', 'farmId']),
      'supplier': _value(doc, ['supplier_name', 'supplierName']),
      'batchNumber': _value(doc, ['batch_number', 'batchNumber']),
      'notes': _value(doc, ['notes']),
    };
  }

  String _inventoryStatus(
      double quantity, double reorderLevel, Map<String, dynamic> doc) {
    final rawStatus = _value(doc, ['status']).trim();
    if (quantity <= 0) return 'Out of Stock';
    if (reorderLevel > 0 && quantity <= reorderLevel) return 'Low Stock';
    return rawStatus.isEmpty ? 'Good' : rawStatus;
  }

  String _formatCurrency(num value) {
    if (value >= 1000) return 'GHS ${(value / 1000).toStringAsFixed(1)}K';
    return 'GHS ${value.toStringAsFixed(2)}';
  }

  Future<void> _recordStockMovement(
    Map<String, dynamic> item,
    String movementType,
    double quantity,
  ) async {
    final currentQuantity = item['quantity'] as double;
    final nextQuantity = movementType == 'Stock In'
        ? currentQuantity + quantity
        : currentQuantity - quantity;
    if (quantity <= 0) {
      throw const SuperAdminApiException('Enter a quantity greater than zero.');
    }
    if (nextQuantity < 0) {
      throw const SuperAdminApiException(
          'Quantity is more than available stock.');
    }
    final user = ref.read(authProvider).user;
    final itemId = item['id']?.toString() ?? '';
    await _api.updateInventory(
      id: itemId,
      itemName: item['name'] as String,
      itemType: item['category'] as String,
      unit: item['unit'] as String,
      quantityAvailable: nextQuantity,
      reorderLevel: item['minStock'] as double,
      unitPrice: item['unitCost'] as double,
      supplierName: item['supplier'] as String,
      batchNumber: item['batchNumber'] as String,
      farmId: item['farmId'] as String,
      addedBy: user?.name ?? 'Farm Manager',
      status: _inventoryStatus(nextQuantity, item['minStock'] as double, item),
      notes: item['notes'] as String,
      dateAdded: _value(item, ['date_added', 'dateAdded'],
          fallback: DateTime.now().toIso8601String()),
    );
    await _api.createInventoryMovement(
      itemId: itemId,
      itemName: item['name'] as String,
      farmName: item['farmName'] as String,
      farmId: item['farmId'] as String,
      movementType: movementType,
      quantity: quantity,
      unit: item['unit'] as String,
      actor: user?.name ?? 'Farm Manager',
      note: '$movementType from Farm Manager inventory screen',
    );
    await _loadInventory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth < 1024;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Farm Manager';
    final userEmail = authState.user?.email ?? 'manager@farmestates.com';
    final userRole = 'Farm Manager';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? FarmManagerMobileDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (i) => setState(() => _selectedNavIndex = i),
              userName: userName,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(
              isDark, userName, userEmail, userRole, isTablet),
      bottomNavigationBar: isMobile
          ? FarmManagerMobileBottomNav(
              selectedIndex: 2,
              onItemSelected: (_) {},
            )
          : null,
      floatingActionButton: isMobile
          ? null
          : PermissionGate(
              permission: Permission.manageInventory,
              child: FloatingActionButton.extended(
                onPressed: () => _showAddInventoryDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
            ),
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail,
      String userRole, bool isTablet) {
    return Row(
      children: [
        FarmManagerSidebar(
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
              FarmManagerHeader(
                userName: userName,
                onNotificationTap: () {},
              ),
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    if (_isLoading || _errorMessage != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: _isLoading
                              ? const AdminDataSkeleton(rowCount: 6)
                              : _buildErrorState(isDark),
                        ),
                      )
                    else ...[
                      // Stats Summary Section
                      SliverToBoxAdapter(
                        child: _buildStatsSummary(isDark, isTablet),
                      ),

                      // Filter and Search Section
                      SliverToBoxAdapter(
                        child: _buildFilterSection(isDark, isTablet),
                      ),

                      // Inventory List Section
                      SliverPadding(
                        padding: EdgeInsets.only(
                          left: isTablet ? AppSpacing.lg : AppSpacing.xl,
                          right: isTablet ? AppSpacing.lg : AppSpacing.xl,
                          bottom: AppSpacing.xl,
                        ),
                        sliver: _buildInventoryGrid(isDark, isTablet),
                      ),
                    ],
                  ],
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
        // Header
        FarmManagerHeader(
          userName: userName,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),

        // Content
        Expanded(
          child: CustomScrollView(
            slivers: [
              if (_isLoading || _errorMessage != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: _isLoading
                        ? const AdminDataSkeleton(rowCount: 6)
                        : _buildErrorState(isDark),
                  ),
                )
              else ...[
                // Search and Filter Section
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      0,
                    ),
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AppSearchBar(
                                hintText: 'Search inventory...',
                                onChanged: (value) =>
                                    setState(() => _searchQuery = value),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _buildActionButton(
                              icon: Icons.filter_alt_outlined,
                              tooltip: 'Filter',
                              isDark: isDark,
                              onPressed: _showFilterDialog,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _buildActionButton(
                              icon: Icons.add,
                              tooltip: 'Add Item',
                              isDark: isDark,
                              onPressed: () => _showAddInventoryDialog(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Stats Section
                SliverToBoxAdapter(
                  child: _buildMobileStats(isDark),
                ),

                // Category Chips
                SliverToBoxAdapter(
                  child: _buildCategoryChips(isDark, true),
                ),

                // Inventory List
                _buildInventoryList(isDark, true),

                // Add padding at bottom for bottom navigation
                SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.lg),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 42, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Could not load inventory',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'The inventory service did not return data.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadInventory,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary(bool isDark, bool isTablet) {
    final totalItems = _inventory.length;
    final lowStock =
        _inventory.where((item) => item['status'] == 'Low Stock').length;
    final outOfStock =
        _inventory.where((item) => item['status'] == 'Out of Stock').length;
    final totalValue = _inventory.fold<double>(
      0,
      (sum, item) =>
          sum + ((item['quantity'] as double) * (item['unitCost'] as double)),
    );
    final stats = [
      {
        'title': 'Total Items',
        'value': '$totalItems',
        'icon': Icons.inventory_2,
        'color': AppColors.primary,
        'change': '+5.2%',
        'isPositive': true,
      },
      {
        'title': 'Low Stock',
        'value': '$lowStock',
        'icon': Icons.warning,
        'color': AppColors.warning,
        'change': '+2',
        'isPositive': false,
      },
      {
        'title': 'Out of Stock',
        'value': '$outOfStock',
        'icon': Icons.error,
        'color': AppColors.error,
        'change': '-1',
        'isPositive': true,
      },
      {
        'title': 'Total Value',
        'value': _formatCurrency(totalValue),
        'icon': Icons.attach_money,
        'color': AppColors.success,
        'change': '+12.5%',
        'isPositive': true,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        int crossAxisCount;
        double childAspectRatio;

        if (screenWidth < 600) {
          crossAxisCount = 2;
          childAspectRatio = 2.8;
        } else if (screenWidth < 900) {
          crossAxisCount = 2;
          childAspectRatio = 2.5;
        } else if (screenWidth < 1200) {
          crossAxisCount = 4;
          childAspectRatio = 2.3;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 2.2;
        }

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth < 600
                ? AppSpacing.md
                : (screenWidth < 900 ? AppSpacing.lg : AppSpacing.xl),
            vertical: screenWidth < 600 ? AppSpacing.lg : AppSpacing.xl,
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final stat = stats[index];
              return _buildStatCard(stat, isDark, screenWidth < 600);
            },
          ),
        );
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, bool isDark,
      [bool isMobile = false]) {
    final color = stat['color'] as Color;
    return LayoutBuilder(builder: (context, box) {
      final compact = box.maxWidth < 160;
      return Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14, vertical: compact ? 8 : 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(isDark ? 0.15 : 0.12)),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                      color: color.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 3))
                ],
        ),
        child: Row(children: [
          Container(
            padding: EdgeInsets.all(compact ? 6 : 8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(stat['icon'] as IconData,
                size: compact ? 16 : 20, color: color),
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stat['value'] as String,
                  style: GoogleFonts.inter(
                      fontSize: compact ? 16 : 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      height: 1.1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(stat['title'] as String,
                  style: GoogleFonts.inter(
                      fontSize: compact ? 10 : 11,
                      color: isDark ? Colors.white38 : AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          )),
          if (!compact && stat['change'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: ((stat['isPositive'] as bool)
                        ? AppColors.success
                        : AppColors.error)
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(stat['change'] as String,
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: (stat['isPositive'] as bool)
                          ? AppColors.success
                          : AppColors.error)),
            ),
        ]),
      );
    });
  }

  Widget _buildMobileStats(bool isDark) {
    final totalItems = _inventory.length;
    final lowStock =
        _inventory.where((item) => item['status'] == 'Low Stock').length;
    final outOfStock =
        _inventory.where((item) => item['status'] == 'Out of Stock').length;
    final totalValue = _inventory.fold<double>(
      0,
      (sum, item) =>
          sum + ((item['quantity'] as double) * (item['unitCost'] as double)),
    );
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: GridView.count(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.5,
        children: [
          _buildMobileStatCard(
              '$totalItems', 'Total Items', AppColors.primary, isDark),
          _buildMobileStatCard(
              '$lowStock', 'Low Stock', AppColors.warning, isDark),
          _buildMobileStatCard(
              '$outOfStock', 'Out of Stock', AppColors.error, isDark),
          _buildMobileStatCard(_formatCurrency(totalValue), 'Total Value',
              AppColors.success, isDark),
        ],
      ),
    );
  }

  Widget _buildMobileStatCard(
      String value, String title, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(isDark ? 0.15 : 0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(
              title == 'Total Items'
                  ? Icons.inventory_2_rounded
                  : title == 'Low Stock'
                      ? Icons.warning_rounded
                      : title == 'Out of Stock'
                          ? Icons.error_rounded
                          : Icons.attach_money_rounded,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildFilterSection(bool isDark, bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 900;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth < 600
                ? AppSpacing.md
                : (screenWidth < 900 ? AppSpacing.lg : AppSpacing.xl),
            vertical: AppSpacing.lg,
          ),
          color: isDark ? Colors.transparent : Colors.transparent,
          child: Column(
            children: [
              if (isSmallScreen) ...[
                // Stack vertically on small screens
                AppSearchBar(
                  hintText: 'Search by item name, category or SKU...',
                  onChanged: (value) => setState(() => _searchQuery = value),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.filter_alt_outlined,
                      tooltip: 'Filter',
                      isDark: isDark,
                      onPressed: _showFilterDialog,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppFilterChip(
                        label: 'Low Stock Only',
                        icon: Icons.warning,
                        isSelected: _showLowStockOnly,
                        onChanged: (value) =>
                            setState(() => _showLowStockOnly = value),
                        color: AppColors.warning,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Horizontal layout on larger screens
                Row(
                  children: [
                    Expanded(
                      child: AppSearchBar(
                        hintText: 'Search by item name, category or SKU...',
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _buildActionButton(
                      icon: Icons.filter_alt_outlined,
                      tooltip: 'Filter',
                      isDark: isDark,
                      onPressed: _showFilterDialog,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppFilterChip(
                      label: 'Low Stock Only',
                      icon: Icons.warning,
                      isSelected: _showLowStockOnly,
                      onChanged: (value) =>
                          setState(() => _showLowStockOnly = value),
                      color: AppColors.warning,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _buildCategoryChips(isDark, false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChips(bool isDark, bool isMobile) {
    final categoryNames = _inventory
        .map((item) => item['category'].toString())
        .where((category) => category.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final categories = [
      {'label': 'All', 'icon': Icons.all_inclusive, 'count': _inventory.length},
      ...categoryNames.map(
        (category) => {
          'label': category,
          'icon': _getCategoryIcon(category),
          'count': _inventory
              .where((item) => item['category'].toString() == category)
              .length,
        },
      ),
    ];

    return SizedBox(
      height: isMobile ? 40 : 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.lg : 0,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['label'];

          return Padding(
            padding: EdgeInsets.only(
                right: isMobile ? AppSpacing.xs : AppSpacing.sm),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    size: isMobile ? 14 : 16,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? Colors.white.withOpacity(0.8)
                            : AppColors.textPrimary),
                  ),
                  SizedBox(width: isMobile ? 4 : 6),
                  Text(
                    category['label'] as String,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 11 : 13,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? Colors.white.withOpacity(0.8)
                              : AppColors.textPrimary),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(width: isMobile ? 4 : 6),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 4 : 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : (isDark
                              ? Colors.white.withOpacity(0.1)
                              : AppColors.neutral100),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${category['count']}',
                      style: AppTypography.caption.copyWith(
                        fontSize: isMobile ? 9 : 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? Colors.white.withOpacity(0.6)
                                : AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category['label'] as String);
              },
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              selectedColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? Colors.white.withOpacity(0.1)
                          : AppColors.neutral200),
                ),
              ),
              elevation: 0,
            ),
          );
        },
      ),
    );
  }

  SliverGrid _buildInventoryGrid(bool isDark, bool isTablet) {
    final filteredItems = _getFilteredItems();
    // Use responsive crossAxisCount
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth =
        screenWidth - (isTablet ? 0 : 250); // account for sidebar
    final cols = contentWidth > 1000 ? 3 : (contentWidth > 600 ? 2 : 2);
    final ratio = contentWidth > 1000 ? 1.2 : (contentWidth > 600 ? 1.15 : 1.1);

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: ratio,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = filteredItems[index];
          return _buildInventoryCard(item, isDark, false);
        },
        childCount: filteredItems.length,
      ),
    );
  }

  SliverList _buildInventoryList(bool isDark, bool isMobile) {
    final filteredItems = _getFilteredItems();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = filteredItems[index];
          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl,
              vertical: AppSpacing.xs,
            ),
            child: _buildInventoryCard(item, isDark, true),
          );
        },
        childCount: filteredItems.length,
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item, bool isDark,
      [bool isMobile = false]) {
    final totalValue =
        (item['quantity'] as double) * (item['unitCost'] as double);
    final stockPercentage =
        (item['quantity'] as double) / (item['maxStock'] as double);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color:
                isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showItemDetails(item),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (item['color'] as Color).withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding:
                    EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(
                              isMobile ? AppSpacing.xs : AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: (item['color'] as Color).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            _getCategoryIcon(item['category'] as String),
                            color: item['color'] as Color,
                            size: isMobile ? 18 : 22,
                          ),
                        ),
                        SizedBox(
                            width: isMobile ? AppSpacing.xs : AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item['name'] as String,
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontSize: isMobile ? 13 : 15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.category_outlined,
                                    size: isMobile ? 10 : 12,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.5)
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      item['category'] as String,
                                      style: AppTypography.caption.copyWith(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.6)
                                            : AppColors.textSecondary,
                                        fontSize: isMobile ? 10 : 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 6 : 10,
                            vertical: isMobile ? 3 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                            border: Border.all(
                              color: (item['color'] as Color).withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            item['status'] as String,
                            style: AppTypography.caption.copyWith(
                              color: item['color'] as Color,
                              fontWeight: FontWeight.w700,
                              fontSize: isMobile ? 9 : 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),

                    // Stock Level Section
                    Container(
                      padding: EdgeInsets.all(
                          isMobile ? AppSpacing.xs : AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.03)
                            : AppColors.neutral50,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: isMobile ? 12 : 14,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.6)
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Stock Level',
                                      style: AppTypography.caption.copyWith(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.6)
                                            : AppColors.textSecondary,
                                        fontSize: isMobile ? 10 : 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 6 : 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (item['color'] as Color)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusFull),
                                ),
                                child: Text(
                                  '${(stockPercentage * 100).toStringAsFixed(0)}%',
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: item['color'] as Color,
                                    fontSize: isMobile ? 10 : 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 6 : 8),
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                            child: LinearProgressIndicator(
                              value: stockPercentage,
                              backgroundColor: isDark
                                  ? Colors.white10
                                  : AppColors.neutral100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  item['color'] as Color),
                              minHeight: isMobile ? 6 : 8,
                            ),
                          ),
                          SizedBox(height: isMobile ? 4 : 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: isMobile ? 10 : 12,
                                      color: item['color'] as Color,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '${item['quantity']} ${item['unit']}',
                                        style: AppTypography.caption.copyWith(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.7)
                                              : AppColors.textPrimary,
                                          fontSize: isMobile ? 10 : 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Max: ${item['maxStock']} ${item['unit']}',
                                        style: AppTypography.caption.copyWith(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.5)
                                              : AppColors.textSecondary,
                                          fontSize: isMobile ? 9 : 10,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),

                    // Details Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(
                                isMobile ? AppSpacing.xs : AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.03)
                                  : AppColors.neutral50,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.attach_money,
                                      size: isMobile ? 10 : 12,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.6)
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Unit Cost',
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
                                const SizedBox(height: 4),
                                Text(
                                  'GH₵${item['unitCost']}',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                            width: isMobile ? AppSpacing.xs : AppSpacing.sm),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(
                                isMobile ? AppSpacing.xs : AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.03)
                                  : AppColors.neutral50,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet_outlined,
                                      size: isMobile ? 10 : 12,
                                      color: isDark
                                          ? Colors.white.withOpacity(0.6)
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Total Value',
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
                                const SizedBox(height: 4),
                                Text(
                                  'GH₵${totalValue.toStringAsFixed(2)}',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (item['expiryDate'] != null) ...[
                      SizedBox(
                          height: isMobile ? AppSpacing.sm : AppSpacing.md),
                      Container(
                        padding: EdgeInsets.all(
                            isMobile ? AppSpacing.xs : AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: isMobile ? 12 : 14,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Exp: ${item['expiryDate']}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.warning,
                                  fontSize: isMobile ? 10 : 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showStockInDialog(item),
                            icon: Icon(
                              Icons.add,
                              size: isMobile ? 14 : 16,
                            ),
                            label: Text(
                              'Stock In',
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.success.withOpacity(0.1),
                              foregroundColor: AppColors.success,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 8 : 10,
                                horizontal:
                                    isMobile ? AppSpacing.xs : AppSpacing.sm,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                                side: BorderSide(
                                  color: AppColors.success.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                        SizedBox(
                            width: isMobile ? AppSpacing.xs : AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showStockOutDialog(item),
                            icon: Icon(
                              Icons.remove,
                              size: isMobile ? 14 : 16,
                            ),
                            label: Text(
                              'Stock Out',
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error.withOpacity(0.1),
                              foregroundColor: AppColors.error,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 8 : 10,
                                horizontal:
                                    isMobile ? AppSpacing.xs : AppSpacing.sm,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusMd),
                                side: BorderSide(
                                  color: AppColors.error.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/farm-manager'
      },
      {
        'icon': Icons.agriculture_outlined,
        'label': 'Farms',
        'index': 1,
        'route': '/farm-manager/farms'
      },
      {
        'icon': Icons.inventory_2_outlined,
        'label': 'Inventory',
        'index': 2,
        'route': '/farm-manager/inventory'
      },
      {
        'icon': Icons.local_shipping_outlined,
        'label': 'Deliveries',
        'index': 3,
        'route': '/farm-manager/deliveries'
      },
      {
        'icon': Icons.assessment_outlined,
        'label': 'Reports',
        'index': 4,
        'route': '/farm-manager/reports'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color:
                isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral100,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final index = item['index'] as int;
              final isSelected = index == _selectedNavIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_selectedNavIndex != index) {
                        setState(() => _selectedNavIndex = index);
                        try {
                          Navigator.pushReplacementNamed(
                              context, item['route'] as String);
                        } catch (e) {
                          debugPrint('Navigation error: $e');
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border(
                                top: BorderSide(
                                    color: AppColors.primary, width: 2),
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 22,
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
                          ),
                        ],
                      ),
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

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    VoidCallback? onPressed,
    int? badge,
  }) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : AppColors.neutral200,
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDark
                      ? Colors.white.withOpacity(0.9)
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (badge != null && badge > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  badge > 9 ? '9+' : badge.toString(),
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredItems() {
    var filteredItems = List<Map<String, dynamic>>.from(_inventory);
    if (_selectedCategory != 'All') {
      filteredItems = filteredItems
          .where((item) => item['category'] == _selectedCategory)
          .toList();
    }
    if (_showLowStockOnly) {
      filteredItems =
          filteredItems.where((item) => item['status'] != 'Good').toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredItems = filteredItems.where((item) {
        return (item['name'] as String).toLowerCase().contains(query) ||
            (item['category'] as String).toLowerCase().contains(query) ||
            (item['batchNumber'] as String).toLowerCase().contains(query) ||
            (item['farmName'] as String).toLowerCase().contains(query);
      }).toList();
    }

    return filteredItems;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Fertilizer':
        return Icons.grass;
      case 'Seeds':
        return Icons.eco;
      case 'Nutrients':
        return Icons.science;
      case 'Pesticides':
        return Icons.pest_control;
      case 'Tools':
        return Icons.build;
      case 'Packaging':
        return Icons.inventory;
      default:
        return Icons.category;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content:
            const Text('Advanced filtering options will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddInventoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Inventory Item'),
        content: const Text('Add inventory form will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item added successfully')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['name'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${item['category']}'),
            Text('Quantity: ${item['quantity']} ${item['unit']}'),
            Text('Unit Cost: GH₵${item['unitCost']}'),
            Text('Status: ${item['status']}'),
            if (item['expiryDate'] != null)
              Text('Expiry: ${item['expiryDate']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Edit item
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showStockInDialog(Map<String, dynamic> item) {
    final quantityController = TextEditingController();
    var isSaving = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Stock In'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Item: ${item['name']}'),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity (${item['unit']})',
                  border: const OutlineInputBorder(),
                  errorText: dialogError,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final quantity =
                          double.tryParse(quantityController.text.trim()) ?? 0;
                      setDialogState(() {
                        isSaving = true;
                        dialogError = null;
                      });
                      try {
                        await _recordStockMovement(item, 'Stock In', quantity);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Stock updated successfully')),
                        );
                      } catch (error) {
                        setDialogState(() {
                          dialogError = error.toString();
                          isSaving = false;
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStockOutDialog(Map<String, dynamic> item) {
    final quantityController = TextEditingController();
    var isSaving = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Stock Out'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Item: ${item['name']}'),
              Text('Available: ${item['quantity']} ${item['unit']}'),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity (${item['unit']})',
                  border: const OutlineInputBorder(),
                  errorText: dialogError,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final quantity =
                          double.tryParse(quantityController.text.trim()) ?? 0;
                      setDialogState(() {
                        isSaving = true;
                        dialogError = null;
                      });
                      try {
                        await _recordStockMovement(item, 'Stock Out', quantity);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Stock updated successfully')),
                        );
                      } catch (error) {
                        setDialogState(() {
                          dialogError = error.toString();
                          isSaving = false;
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
