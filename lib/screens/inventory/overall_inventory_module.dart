// ignore_for_file: unused_field, unused_element_parameter

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../services/superadmin_api_service.dart';

class OverallInventoryModule extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isMobile;

  const OverallInventoryModule({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isMobile,
  });

  @override
  State<OverallInventoryModule> createState() => _OverallInventoryModuleState();
}

class _OverallInventoryModuleState extends State<OverallInventoryModule> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm');
  String _selectedFarm = 'All Farms';
  String _selectedStockState = 'All';
  int _selectedTab = 0;
  final SuperAdminApiService _api = SuperAdminApiService();

  final List<String> _farms = ['All Farms'];
  final Map<String, String> _farmIdsByName = {};
  final List<_InventoryEntry> _items = [];
  final List<_InventoryMovement> _movements = [];
  bool _isLoadingInventory = true;
  String? _inventoryError;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoadingInventory = true;
      _inventoryError = null;
    });

    try {
      final results = await Future.wait([
        _api.getInventory(),
        _api.getFarms(),
        _api.getInventoryMovements(),
      ]);
      if (!mounted) return;
      final inventory = results[0];
      final farms = results[1];
      final movements = results[2];
      final farmNamesById = {
        for (final farm in farms)
          (farm[r'$id'] ?? farm['farm_id'] ?? '').toString():
              _farmNameFromDocument(farm),
      };
      final farmNames = farms
          .map(_farmNameFromDocument)
          .where((name) => name.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      final items = inventory
          .map((doc) => _mapInventoryDocument(doc, farmNamesById))
          .toList();
      final movementItems = movements.map(_mapMovementDocument).toList();
      final nextSelectedFarm =
          farmNames.contains(_selectedFarm) ? _selectedFarm : 'All Farms';
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _movements
          ..clear()
          ..addAll(movementItems);
        _farms
          ..clear()
          ..add('All Farms')
          ..addAll(farmNames);
        _selectedFarm = nextSelectedFarm;
        _farmIdsByName
          ..clear()
          ..addEntries(
            farms.map(
              (farm) => MapEntry(
                _farmNameFromDocument(farm),
                (farm[r'$id'] ?? farm['farm_id'] ?? '').toString(),
              ),
            ),
          );
        _isLoadingInventory = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _items.clear();
        _movements.clear();
        _farms
          ..clear()
          ..add('All Farms');
        _farmIdsByName.clear();
        _isLoadingInventory = false;
        _inventoryError = error.toString();
      });
    }
  }

  _InventoryEntry _mapInventoryDocument(
    Map<String, dynamic> doc,
    Map<String, String> farmNamesById,
  ) {
    final farmId = (doc['farm_id'] ?? '').toString();
    return _InventoryEntry(
      id: (doc[r'$id'] ?? doc['item_id'] ?? '').toString(),
      farmId: farmId,
      name: (doc['item_name'] ?? 'Inventory Item').toString(),
      category: (doc['item_type'] ?? 'Inventory').toString(),
      farm: farmNamesById[farmId] ??
          (farmId.trim().isEmpty ? 'Unassigned Farm' : farmId),
      quantity: _toDouble(doc['quantity_available']),
      unit: (doc['unit'] ?? '').toString(),
      minStock: _toDouble(doc['reorder_level']),
      unitCost: _toDouble(doc['unit_price']),
      supplierName: (doc['supplier_name'] ?? '').toString(),
      batchNumber: (doc['batch_number'] ?? '').toString(),
      status: (doc['status'] ?? 'Available').toString(),
      notes: (doc['notes'] ?? '').toString(),
      dateAdded: (doc['date_added'] ?? _todayDate()).toString(),
      lastUpdatedBy: (doc['added_by'] ?? 'System').toString(),
    );
  }

  String _farmNameFromDocument(Map<String, dynamic> farm) {
    return (farm['name'] ?? farm['farm_name'] ?? 'Unassigned Farm').toString();
  }

  String _todayDate() => DateTime.now().toIso8601String().split('T').first;

  String _statusForQuantity(double quantity, double reorderLevel) {
    if (quantity <= 0) return 'Out of Stock';
    if (quantity <= reorderLevel) return 'Low Stock';
    return 'Available';
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  _InventoryMovement _mapMovementDocument(Map<String, dynamic> doc) {
    final type = (doc['movement_type'] ?? 'stock_in').toString();
    return _InventoryMovement(
      id: (doc[r'$id'] ?? doc['movement_id'] ?? '').toString(),
      itemName: (doc['item_name'] ?? 'Inventory Item').toString(),
      farm: (doc['farm_name'] ?? 'Unassigned Farm').toString(),
      type: type == 'stock_out'
          ? _MovementType.stockOut
          : type == 'adjustment'
              ? _MovementType.adjustment
              : _MovementType.stockIn,
      quantity: _toDouble(doc['quantity']),
      unit: (doc['unit'] ?? '').toString(),
      actor: (doc['actor'] ?? 'System').toString(),
      timestamp: DateTime.tryParse((doc['timestamp'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      note: (doc['note'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredItems = _filteredItems();
    final filteredMovements = _filteredMovements();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(isDark),
        Transform.translate(
          offset: Offset(0, widget.isMobile ? -50 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: widget.isMobile ? 0 : AppSpacing.lg),
              if (_inventoryError != null) ...[
                _buildSyncStatus(isDark),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (_isLoadingInventory)
                const AdminDataSkeleton(rowCount: 5)
              else ...[
                _buildStats(isDark, _items),
                SizedBox(
                  height: widget.isMobile ? AppSpacing.sm : AppSpacing.lg,
                ),
                _buildFarmOverview(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildFilters(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildTabs(isDark),
                const SizedBox(height: AppSpacing.md),
                if (_selectedTab == 0)
                  _buildInventoryList(isDark, filteredItems)
                else
                  _buildMovementHistory(isDark, filteredMovements),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyncStatus(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _inventoryError ?? 'Unable to load inventory records.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _loadInventory,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final totalValue =
        _items.fold<double>(0, (sum, entry) => sum + entry.totalValue);
    final farmsCovered = _items.map((entry) => entry.farm).toSet().length;

    return Container(
      padding: EdgeInsets.all(widget.isMobile ? AppSpacing.lg : AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primary.withOpacity(0.26),
                  AppColors.surfaceDark,
                  AppColors.backgroundDark,
                ]
              : [
                  AppColors.primary.withOpacity(0.11),
                  Colors.white,
                  AppColors.neutral50,
                ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.primary.withOpacity(0.14),
        ),
        boxShadow: widget.isMobile
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.24 : 0.06),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
      ),
      child: widget.isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCopy(isDark),
                const SizedBox(height: 0),
                _buildHeroMetrics(isDark, farmsCovered, totalValue),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildHeaderCopy(isDark)),
                const SizedBox(width: AppSpacing.xl),
                _buildHeroMetrics(isDark, farmsCovered, totalValue),
              ],
            ),
    );
  }

  Widget _buildHeaderCopy(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: AppTypography.bodyMedium.copyWith(
                  height: 1.45,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: _showAddInventoryModal,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Inventory'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroMetrics(bool isDark, int farmsCovered, double totalValue) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _heroMetric(
          isDark: isDark,
          label: 'Farms covered',
          value: '$farmsCovered',
          icon: Icons.agriculture_rounded,
          color: AppColors.success,
        ),
        _heroMetric(
          isDark: isDark,
          label: 'Global value',
          value: '\$${totalValue.toStringAsFixed(0)}',
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _heroMetric({
    required bool isDark,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: widget.isMobile ? double.infinity : 170,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool isDark, List<_InventoryEntry> items) {
    final totalItems = items.length;
    final lowStock = items.where((entry) => entry.isLowStock).length;
    final outOfStock = items.where((entry) => entry.isOutOfStock).length;
    final totalValue =
        items.fold<double>(0, (sum, entry) => sum + entry.totalValue);

    final cards = [
      _StatCardData(
        title: 'Global SKUs',
        value: '$totalItems',
        icon: Icons.inventory_2,
        color: AppColors.primary,
      ),
      _StatCardData(
        title: 'Low Stock',
        value: '$lowStock',
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
      ),
      _StatCardData(
        title: 'Out of Stock',
        value: '$outOfStock',
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
      ),
      _StatCardData(
        title: 'Total Value',
        value: '\$${totalValue.toStringAsFixed(0)}',
        icon: Icons.attach_money_rounded,
        color: AppColors.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = widget.isMobile ? 2 : (width > 1100 ? 4 : 2);
        final ratio = widget.isMobile ? 2.1 : (crossAxisCount == 4 ? 2.3 : 2.6);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: ratio,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color:
                      isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: card.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(card.icon, color: card.color, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.value,
                          style: AppTypography.h6.copyWith(
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card.title,
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? Colors.white60
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFarmOverview(bool isDark) {
    final summaries = _farmSummaries();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.agriculture_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Farm-Level Inventory',
                      style: AppTypography.h6.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select a farm to inspect its current stock, risk items, and inventory value.',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.isMobile)
                TextButton.icon(
                  onPressed: () => setState(() => _selectedFarm = 'All Farms'),
                  icon: const Icon(Icons.public_rounded, size: 18),
                  label: const Text('Global View'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = widget.isMobile ? 1 : (width > 1000 ? 4 : 2);
              final gap = AppSpacing.md;
              final cardWidth = columns == 1
                  ? width
                  : (width - (gap * (columns - 1))) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: summaries
                    .map(
                      (summary) => SizedBox(
                        width: cardWidth,
                        child: _buildFarmSummaryCard(summary, isDark),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFarmSummaryCard(_FarmInventorySummary summary, bool isDark) {
    final isSelected = _selectedFarm == summary.farm;
    final riskColor = summary.outOfStock > 0
        ? AppColors.error
        : summary.lowStock > 0
            ? AppColors.warning
            : AppColors.success;

    return InkWell(
      onTap: () => setState(() => _selectedFarm = summary.farm),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.09)
              : (isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.55)
                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.farm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white38 : AppColors.textSecondary),
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                    child: _farmMetric(
                        isDark, 'SKUs', '${summary.items}', AppColors.primary)),
                Expanded(
                    child: _farmMetric(
                        isDark,
                        'Value',
                        '\$${summary.value.toStringAsFixed(0)}',
                        AppColors.success)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: riskColor),
                  const SizedBox(width: 6),
                  Text(
                    summary.outOfStock > 0
                        ? '${summary.outOfStock} out, ${summary.lowStock} low'
                        : summary.lowStock > 0
                            ? '${summary.lowStock} low stock'
                            : 'Healthy stock',
                    style: AppTypography.caption.copyWith(
                      color: riskColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _farmMetric(bool isDark, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isDark ? Colors.white54 : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedFarm == 'All Farms'
                      ? 'Global Inventory Records'
                      : '$_selectedFarm Inventory Records',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              if (_selectedFarm != 'All Farms')
                TextButton.icon(
                  onPressed: () => setState(() => _selectedFarm = 'All Farms'),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Clear Farm'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (widget.isMobile)
            Column(
              children: [
                _buildSearchField(isDark),
                const SizedBox(height: AppSpacing.sm),
                _buildFarmDropdown(isDark),
              ],
            )
          else
            Row(
              children: [
                Expanded(flex: 2, child: _buildSearchField(isDark)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _buildFarmDropdown(isDark)),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: ['All', 'Low Stock', 'Out of Stock'].map((state) {
                final selected = _selectedStockState == state;
                return ChoiceChip(
                  label: Text(state),
                  selected: selected,
                  onSelected: (value) {
                    if (value) {
                      setState(() {
                        _selectedStockState = state;
                      });
                    }
                  },
                  selectedColor: AppColors.primary.withOpacity(0.18),
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : AppColors.neutral100,
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color: selected
                        ? AppColors.primary
                        : (isDark ? Colors.white70 : AppColors.textSecondary),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search item, category, ID...',
        hintStyle:
            TextStyle(color: isDark ? Colors.white38 : AppColors.textSecondary),
        prefixIcon: Icon(Icons.search,
            color: isDark ? Colors.white54 : AppColors.textSecondary),
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide:
              BorderSide(color: isDark ? Colors.white12 : AppColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide:
              BorderSide(color: isDark ? Colors.white12 : AppColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildFarmDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border:
            Border.all(color: isDark ? Colors.white12 : AppColors.neutral200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFarm,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down,
              color: isDark ? Colors.white54 : AppColors.textSecondary),
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          style:
              TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
          items: _farms
              .map((farm) => DropdownMenuItem<String>(
                    value: farm,
                    child: Text(farm),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedFarm = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildTabs(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabItem(
              isDark: isDark,
              label: 'Inventory',
              icon: Icons.inventory_2_rounded,
              index: 0,
            ),
            const SizedBox(width: 4),
            _buildTabItem(
              isDark: isDark,
              label: 'In/Out',
              icon: Icons.history_rounded,
              index: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required bool isDark,
    required String label,
    required IconData icon,
    required int index,
  }) {
    final selected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        width: 122,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? AppColors.primary
                  : (isDark ? Colors.white70 : AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? AppColors.primary
                      : (isDark ? Colors.white70 : AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList(bool isDark, List<_InventoryEntry> items) {
    if (items.isEmpty) {
      return _buildEmptyState(
        isDark: isDark,
        icon: Icons.inventory_2_outlined,
        title: 'No inventory records',
        subtitle: 'Try changing the farm or stock filters.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock Ledger',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...items.map((entry) => _buildInventoryRow(isDark, entry)),
        ],
      ),
    );
  }

  Widget _buildInventoryRow(bool isDark, _InventoryEntry entry) {
    final statusColor = entry.isOutOfStock
        ? AppColors.error
        : entry.isLowStock
            ? AppColors.warning
            : AppColors.success;
    final statusText = entry.isOutOfStock
        ? 'Out of Stock'
        : entry.isLowStock
            ? 'Low Stock'
            : 'Healthy';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.inventory,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.id}  |  ${entry.category}  |  ${entry.farm}',
                      style: AppTypography.caption.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  statusText,
                  style: AppTypography.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildMetaText(
                  isDark,
                  'Qty: ${entry.quantity.toStringAsFixed(1)} ${entry.unit}',
                ),
              ),
              Expanded(
                child: _buildMetaText(
                  isDark,
                  'Min: ${entry.minStock.toStringAsFixed(1)} ${entry.unit}',
                ),
              ),
              Expanded(
                child: _buildMetaText(
                  isDark,
                  'Value: \$${entry.totalValue.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildMetaText(isDark, 'Last Updated By: ${entry.lastUpdatedBy}'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _actionButton(
                label: 'Stock In',
                icon: Icons.add_circle_outline_rounded,
                color: AppColors.success,
                onPressed: () => _openInventoryActionModal(
                  action: _InventoryAction.stockIn,
                  entry: entry,
                ),
              ),
              _actionButton(
                label: 'Stock Out',
                icon: Icons.remove_circle_outline_rounded,
                color: AppColors.warning,
                onPressed: () => _openInventoryActionModal(
                  action: _InventoryAction.stockOut,
                  entry: entry,
                ),
              ),
              _actionButton(
                label: 'Adjust',
                icon: Icons.tune_rounded,
                color: AppColors.primary,
                onPressed: () => _openInventoryActionModal(
                  action: _InventoryAction.adjust,
                  entry: entry,
                ),
              ),
              _actionButton(
                label: 'View Details',
                icon: Icons.visibility_outlined,
                color: AppColors.info,
                onPressed: () => _openInventoryActionModal(
                  action: _InventoryAction.viewDetails,
                  entry: entry,
                ),
              ),
              _actionButton(
                label: 'Delete',
                icon: Icons.delete_outline_rounded,
                color: AppColors.error,
                onPressed: () => _showDeleteInventoryModal(entry),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.zero,
        ),
      ),
    );
  }

  void _openInventoryActionModal({
    required _InventoryAction action,
    required _InventoryEntry entry,
  }) {
    switch (action) {
      case _InventoryAction.stockIn:
        _showStockChangeModal(
          entry: entry,
          title: 'Stock In',
          confirmLabel: 'Add Stock',
          confirmColor: AppColors.success,
          icon: Icons.add_circle_outline_rounded,
          movementType: 'stock_in',
        );
        break;
      case _InventoryAction.stockOut:
        _showStockChangeModal(
          entry: entry,
          title: 'Stock Out',
          confirmLabel: 'Remove Stock',
          confirmColor: AppColors.warning,
          icon: Icons.remove_circle_outline_rounded,
          movementType: 'stock_out',
        );
        break;
      case _InventoryAction.adjust:
        _showStockChangeModal(
          entry: entry,
          title: 'Inventory Adjustment',
          confirmLabel: 'Apply Adjustment',
          confirmColor: AppColors.primary,
          icon: Icons.tune_rounded,
          movementType: 'adjustment',
        );
        break;
      case _InventoryAction.viewDetails:
        _showInventoryDetailsModal(entry);
        break;
    }
  }

  void _showAddInventoryModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemNameController = TextEditingController();
    final itemTypeController = TextEditingController();
    final unitController = TextEditingController(text: 'kg');
    final quantityController = TextEditingController();
    final reorderController = TextEditingController();
    final unitPriceController = TextEditingController();
    final supplierController = TextEditingController();
    final batchController = TextEditingController();
    final notesController = TextEditingController();
    final availableFarms = _farms.where((farm) => farm != 'All Farms').toList()
      ..sort();
    String selectedFarm =
        availableFarms.isNotEmpty ? availableFarms.first : 'Unassigned Farm';
    String? formError;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _modalHeader(
                  isDark: isDark,
                  title: 'Add Inventory',
                  subtitle: 'Create a stock item in the backend inventory',
                  color: AppColors.primary,
                  icon: Icons.add_box_rounded,
                  onClose: isSaving
                      ? () {}
                      : () => Navigator.of(dialogContext).pop(),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        if (formError != null) ...[
                          _modalError(isDark, formError!),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _textField(
                          isDark: isDark,
                          controller: itemNameController,
                          label: 'Item Name',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                isDark: isDark,
                                controller: itemTypeController,
                                label: 'Item Type',
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _textField(
                                isDark: isDark,
                                controller: unitController,
                                label: 'Unit',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          initialValue: selectedFarm,
                          dropdownColor:
                              isDark ? AppColors.surfaceDark : Colors.white,
                          decoration: _inputDecoration(isDark, 'Farm'),
                          items: [
                            if (availableFarms.isEmpty)
                              const DropdownMenuItem(
                                value: 'Unassigned Farm',
                                child: Text('Unassigned Farm'),
                              ),
                            ...availableFarms.map(
                              (farm) => DropdownMenuItem(
                                value: farm,
                                child: Text(farm),
                              ),
                            ),
                          ],
                          onChanged: isSaving
                              ? null
                              : (value) => setDialogState(
                                    () => selectedFarm =
                                        value ?? 'Unassigned Farm',
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                isDark: isDark,
                                controller: quantityController,
                                label: 'Quantity',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _textField(
                                isDark: isDark,
                                controller: reorderController,
                                label: 'Reorder Level',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _textField(
                          isDark: isDark,
                          controller: unitPriceController,
                          label: 'Unit Price',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _textField(
                                isDark: isDark,
                                controller: supplierController,
                                label: 'Supplier Name',
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _textField(
                                isDark: isDark,
                                controller: batchController,
                                label: 'Batch Number',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _textField(
                          isDark: isDark,
                          controller: notesController,
                          label: 'Notes',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                _modalActions(
                  isDark: isDark,
                  cancelLabel: 'Cancel',
                  confirmLabel: isSaving ? 'Saving...' : 'Create Inventory',
                  confirmColor: AppColors.primary,
                  onCancel: isSaving
                      ? () {}
                      : () => Navigator.of(dialogContext).pop(),
                  onConfirm: isSaving
                      ? () {}
                      : () async {
                          final itemName = itemNameController.text.trim();
                          final itemType = itemTypeController.text.trim();
                          final unit = unitController.text.trim();
                          final quantity =
                              double.tryParse(quantityController.text.trim());
                          final reorder =
                              double.tryParse(reorderController.text.trim());
                          final unitPrice =
                              double.tryParse(unitPriceController.text.trim());

                          if (itemName.isEmpty ||
                              itemType.isEmpty ||
                              unit.isEmpty) {
                            setDialogState(() => formError =
                                'Item name, item type, and unit are required.');
                            return;
                          }
                          if (quantity == null ||
                              reorder == null ||
                              unitPrice == null ||
                              quantity < 0 ||
                              reorder < 0 ||
                              unitPrice < 0) {
                            setDialogState(() => formError =
                                'Quantity, reorder level, and unit price must be valid numbers.');
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            formError = null;
                          });
                          final dialogNavigator = Navigator.of(dialogContext);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await _api.createInventory(
                              itemName: itemName,
                              itemType: itemType,
                              unit: unit,
                              quantityAvailable: quantity,
                              reorderLevel: reorder,
                              unitPrice: unitPrice,
                              supplierName: supplierController.text.trim(),
                              batchNumber: batchController.text.trim(),
                              farmId: _farmIdsByName[selectedFarm] ?? '',
                              addedBy: 'Super Admin',
                              status: _statusForQuantity(quantity, reorder),
                              notes: notesController.text.trim(),
                              dateAdded: _todayDate(),
                            );
                            if (!mounted) return;
                            dialogNavigator.pop();
                            await _loadInventory();
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('$itemName added to inventory'),
                              ),
                            );
                          } catch (error) {
                            if (!mounted) return;
                            setDialogState(() {
                              isSaving = false;
                              formError = error.toString();
                            });
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStockChangeModal({
    required _InventoryEntry entry,
    required String title,
    required String confirmLabel,
    required Color confirmColor,
    required IconData icon,
    required String movementType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qtyController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _modalHeader(
                isDark: isDark,
                title: title,
                subtitle: '${entry.id} | ${entry.name}',
                color: confirmColor,
                icon: icon,
                onClose: () => Navigator.of(dialogContext).pop(),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      _textField(
                        isDark: isDark,
                        controller: qtyController,
                        label: 'Quantity (${entry.unit})',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _textField(
                        isDark: isDark,
                        controller: noteController,
                        label: 'Reason / Notes',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              _modalActions(
                isDark: isDark,
                cancelLabel: 'Close',
                confirmLabel: confirmLabel,
                confirmColor: confirmColor,
                onCancel: () => Navigator.of(dialogContext).pop(),
                onConfirm: () async {
                  final quantity = double.tryParse(qtyController.text.trim());
                  if (quantity == null || quantity <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Quantity must be greater than zero'),
                      ),
                    );
                    return;
                  }
                  final updatedQuantity = movementType == 'stock_in'
                      ? entry.quantity + quantity
                      : movementType == 'stock_out'
                          ? entry.quantity - quantity
                          : quantity;
                  if (updatedQuantity < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Cannot remove more than ${entry.quantity.toStringAsFixed(1)} ${entry.unit}',
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.of(dialogContext).pop();
                  try {
                    await _api.updateInventory(
                      id: entry.id,
                      itemName: entry.name,
                      itemType: entry.category,
                      unit: entry.unit,
                      quantityAvailable: updatedQuantity,
                      reorderLevel: entry.minStock,
                      unitPrice: entry.unitCost,
                      supplierName: entry.supplierName,
                      batchNumber: entry.batchNumber,
                      farmId: entry.farmId,
                      addedBy: 'Super Admin',
                      status: _statusForQuantity(
                        updatedQuantity,
                        entry.minStock,
                      ),
                      notes: entry.notes,
                      dateAdded: entry.dateAdded,
                    );
                    await _api.createInventoryMovement(
                      itemId: entry.id,
                      itemName: entry.name,
                      farmId: entry.farmId,
                      farmName: entry.farm,
                      movementType: movementType,
                      quantity: quantity,
                      unit: entry.unit,
                      actor: 'System',
                      note: noteController.text.trim(),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('$confirmLabel completed for ${entry.id}'),
                      ),
                    );
                    await _loadInventory();
                  } catch (error) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error.toString())),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteInventoryModal(_InventoryEntry entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? formError;
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _modalHeader(
                  isDark: isDark,
                  title: 'Delete Inventory',
                  subtitle: entry.name,
                  color: AppColors.error,
                  icon: Icons.delete_outline_rounded,
                  onClose: isDeleting
                      ? () {}
                      : () => Navigator.of(dialogContext).pop(),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (formError != null) ...[
                        _modalError(isDark, formError!),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Text(
                        'This will remove the inventory item from the backend database. Existing movement logs will remain for audit history.',
                        style: AppTypography.bodyMedium.copyWith(
                          color:
                              isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : AppColors.neutral50,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color:
                                isDark ? Colors.white10 : AppColors.neutral200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _detailRow(isDark, 'Item', entry.name),
                            _detailRow(isDark, 'Farm', entry.farm),
                            _detailRow(
                              isDark,
                              'Quantity',
                              '${entry.quantity.toStringAsFixed(1)} ${entry.unit}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _modalActions(
                  isDark: isDark,
                  cancelLabel: 'Cancel',
                  confirmLabel: isDeleting ? 'Deleting...' : 'Delete',
                  confirmColor: AppColors.error,
                  onCancel: isDeleting
                      ? () {}
                      : () => Navigator.of(dialogContext).pop(),
                  onConfirm: isDeleting
                      ? () {}
                      : () async {
                          setDialogState(() {
                            isDeleting = true;
                            formError = null;
                          });
                          final dialogNavigator = Navigator.of(dialogContext);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await _api.deleteInventory(entry.id);
                            if (!mounted) return;
                            dialogNavigator.pop();
                            await _loadInventory();
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${entry.name} removed from inventory'),
                              ),
                            );
                          } catch (error) {
                            if (!mounted) return;
                            setDialogState(() {
                              isDeleting = false;
                              formError = error.toString();
                            });
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInventoryDetailsModal(_InventoryEntry entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusText = entry.isOutOfStock
        ? 'Out of Stock'
        : entry.isLowStock
            ? 'Low Stock'
            : 'Healthy';
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _modalHeader(
                isDark: isDark,
                title: 'Inventory Details',
                subtitle: '${entry.id} | ${entry.farm}',
                color: AppColors.info,
                icon: Icons.receipt_long_rounded,
                onClose: () => Navigator.of(dialogContext).pop(),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : AppColors.neutral50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isDark ? Colors.white10 : AppColors.neutral200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow(isDark, 'Item', entry.name),
                        _detailRow(isDark, 'Category', entry.category),
                        _detailRow(isDark, 'Farm', entry.farm),
                        _detailRow(isDark, 'Supplier', entry.supplierName),
                        _detailRow(isDark, 'Batch', entry.batchNumber),
                        _detailRow(isDark, 'Quantity',
                            '${entry.quantity} ${entry.unit}'),
                        _detailRow(isDark, 'Minimum Stock',
                            '${entry.minStock} ${entry.unit}'),
                        _detailRow(isDark, 'Unit Cost',
                            '\$${entry.unitCost.toStringAsFixed(2)}'),
                        _detailRow(isDark, 'Total Value',
                            '\$${entry.totalValue.toStringAsFixed(2)}'),
                        _detailRow(isDark, 'Status', statusText),
                        _detailRow(isDark, 'Notes',
                            entry.notes.isEmpty ? 'None' : entry.notes),
                        _detailRow(
                            isDark, 'Last Updated By', entry.lastUpdatedBy),
                      ],
                    ),
                  ),
                ),
              ),
              _modalActions(
                isDark: isDark,
                cancelLabel: 'Close',
                confirmLabel: 'Close',
                confirmColor: AppColors.primary,
                onCancel: () => Navigator.of(dialogContext).pop(),
                onConfirm: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: _inputDecoration(isDark, label),
    );
  }

  InputDecoration _inputDecoration(bool isDark, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? Colors.white60 : AppColors.textSecondary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(
          color: isDark ? Colors.white12 : AppColors.neutral200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _modalError(bool isDark, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.22)),
      ),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? Colors.white70 : AppColors.error,
        ),
      ),
    );
  }

  Widget _detailRow(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: RichText(
        text: TextSpan(
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _modalHeader({
    required bool isDark,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onClose,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h6.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _modalActions({
    required bool isDark,
    required String cancelLabel,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                side: BorderSide(
                  color: isDark ? Colors.white24 : AppColors.neutral300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(
                cancelLabel,
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(confirmLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaText(bool isDark, String value) {
    return Text(
      value,
      style: AppTypography.bodySmall.copyWith(
        color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMovementHistory(
      bool isDark, List<_InventoryMovement> movements) {
    if (movements.isEmpty) {
      return _buildEmptyState(
        isDark: isDark,
        icon: Icons.history,
        title: 'No movement logs',
        subtitle: 'No stock in/out entries match current filters.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: movements
            .map((movement) => _buildMovementRow(isDark, movement))
            .toList(),
      ),
    );
  }

  Widget _buildMovementRow(bool isDark, _InventoryMovement movement) {
    final typeColor = movement.type == _MovementType.stockIn
        ? AppColors.success
        : movement.type == _MovementType.adjustment
            ? AppColors.primary
            : AppColors.error;
    final typeText = movement.type == _MovementType.stockIn
        ? 'Stock In'
        : movement.type == _MovementType.adjustment
            ? 'Adjustment'
            : 'Stock Out';
    final sign = movement.type == _MovementType.stockIn
        ? '+'
        : movement.type == _MovementType.adjustment
            ? ''
            : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              movement.type == _MovementType.stockIn
                  ? Icons.call_received_rounded
                  : movement.type == _MovementType.adjustment
                      ? Icons.tune_rounded
                      : Icons.call_made_rounded,
              size: 18,
              color: typeColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        movement.itemName,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        '$typeText  $sign${movement.quantity.toStringAsFixed(1)} ${movement.unit}',
                        style: AppTypography.caption.copyWith(
                          color: typeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${movement.farm}  |  ${movement.actor}',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dateFormat.format(movement.timestamp),
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
                if ((movement.note ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    movement.note!,
                    style: AppTypography.caption.copyWith(
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(icon,
              size: 36,
              color: isDark ? Colors.white54 : AppColors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<_InventoryEntry> _filteredItems() {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((entry) {
      if (_selectedFarm != 'All Farms' && entry.farm != _selectedFarm) {
        return false;
      }
      if (_selectedStockState == 'Low Stock' && !entry.isLowStock) {
        return false;
      }
      if (_selectedStockState == 'Out of Stock' && !entry.isOutOfStock) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return entry.name.toLowerCase().contains(query) ||
          entry.category.toLowerCase().contains(query) ||
          entry.id.toLowerCase().contains(query);
    }).toList();
  }

  List<_InventoryMovement> _filteredMovements() {
    final query = _searchController.text.trim().toLowerCase();
    final sorted = [..._movements]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.where((movement) {
      if (_selectedFarm != 'All Farms' && movement.farm != _selectedFarm) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return movement.itemName.toLowerCase().contains(query) ||
          movement.actor.toLowerCase().contains(query) ||
          movement.id.toLowerCase().contains(query);
    }).toList();
  }

  List<_FarmInventorySummary> _farmSummaries() {
    final farms = _items.map((entry) => entry.farm).toSet().toList()..sort();
    return farms.map((farm) {
      final entries = _items.where((entry) => entry.farm == farm).toList();
      return _FarmInventorySummary(
        farm: farm,
        items: entries.length,
        lowStock: entries.where((entry) => entry.isLowStock).length,
        outOfStock: entries.where((entry) => entry.isOutOfStock).length,
        value: entries.fold<double>(0, (sum, entry) => sum + entry.totalValue),
      );
    }).toList();
  }
}

class _FarmInventorySummary {
  final String farm;
  final int items;
  final int lowStock;
  final int outOfStock;
  final double value;

  const _FarmInventorySummary({
    required this.farm,
    required this.items,
    required this.lowStock,
    required this.outOfStock,
    required this.value,
  });
}

class _InventoryEntry {
  final String id;
  final String farmId;
  final String name;
  final String category;
  final String farm;
  final double quantity;
  final String unit;
  final double minStock;
  final double unitCost;
  final String supplierName;
  final String batchNumber;
  final String status;
  final String notes;
  final String dateAdded;
  final String lastUpdatedBy;

  const _InventoryEntry({
    required this.id,
    required this.farmId,
    required this.name,
    required this.category,
    required this.farm,
    required this.quantity,
    required this.unit,
    required this.minStock,
    required this.unitCost,
    required this.supplierName,
    required this.batchNumber,
    required this.status,
    required this.notes,
    required this.dateAdded,
    required this.lastUpdatedBy,
  });

  bool get isOutOfStock => quantity <= 0;
  bool get isLowStock => quantity <= minStock;
  double get totalValue => quantity * unitCost;
}

enum _MovementType { stockIn, stockOut, adjustment }

class _InventoryMovement {
  final String id;
  final String itemName;
  final String farm;
  final _MovementType type;
  final double quantity;
  final String unit;
  final String actor;
  final DateTime timestamp;
  final String? note;

  const _InventoryMovement({
    required this.id,
    required this.itemName,
    required this.farm,
    required this.type,
    required this.quantity,
    required this.unit,
    required this.actor,
    required this.timestamp,
    this.note,
  });
}

class _StatCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

enum _InventoryAction { stockIn, stockOut, adjust, viewDetails }
