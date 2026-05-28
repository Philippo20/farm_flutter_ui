import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

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

  final List<String> _farms = const [
    'All Farms',
    'Green Valley Farm',
    'Sunny Acres',
    'Harvest Moon Farm',
    'Golden Fields',
  ];

  final List<_InventoryEntry> _items = const [
    _InventoryEntry(
      id: 'INV-001',
      name: 'NPK Fertilizer 20-20-20',
      category: 'Fertilizer',
      farm: 'Green Valley Farm',
      quantity: 64.0,
      unit: 'kg',
      minStock: 20.0,
      unitCost: 25.0,
      lastUpdatedBy: 'Kwame Mensah',
    ),
    _InventoryEntry(
      id: 'INV-002',
      name: 'Lettuce Seeds (Buttercrunch)',
      category: 'Seeds',
      farm: 'Sunny Acres',
      quantity: 9.0,
      unit: 'kg',
      minStock: 12.0,
      unitCost: 120.0,
      lastUpdatedBy: 'Ama Kusi',
    ),
    _InventoryEntry(
      id: 'INV-003',
      name: 'Calcium Nitrate',
      category: 'Nutrients',
      farm: 'Harvest Moon Farm',
      quantity: 0.0,
      unit: 'kg',
      minStock: 15.0,
      unitCost: 18.0,
      lastUpdatedBy: 'Nana Ofori',
    ),
    _InventoryEntry(
      id: 'INV-004',
      name: 'Neem Oil (Organic)',
      category: 'Pesticides',
      farm: 'Golden Fields',
      quantity: 4.0,
      unit: 'L',
      minStock: 6.0,
      unitCost: 45.0,
      lastUpdatedBy: 'Esi Boateng',
    ),
    _InventoryEntry(
      id: 'INV-005',
      name: 'Packaging Crates - Medium',
      category: 'Packaging',
      farm: 'Green Valley Farm',
      quantity: 140.0,
      unit: 'pcs',
      minStock: 60.0,
      unitCost: 5.5,
      lastUpdatedBy: 'Kojo Asare',
    ),
    _InventoryEntry(
      id: 'INV-006',
      name: 'pH Down Solution',
      category: 'Chemicals',
      farm: 'Sunny Acres',
      quantity: 17.0,
      unit: 'L',
      minStock: 8.0,
      unitCost: 35.0,
      lastUpdatedBy: 'Ama Kusi',
    ),
  ];

  late final List<_InventoryMovement> _movements = [
    _InventoryMovement(
      id: 'MOV-1001',
      itemName: 'NPK Fertilizer 20-20-20',
      farm: 'Green Valley Farm',
      type: _MovementType.stockIn,
      quantity: 20.0,
      unit: 'kg',
      actor: 'Kwame Mensah',
      timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 18)),
      note: 'Received from Agro Supplies Ltd.',
    ),
    _InventoryMovement(
      id: 'MOV-1002',
      itemName: 'Lettuce Seeds (Buttercrunch)',
      farm: 'Sunny Acres',
      type: _MovementType.stockOut,
      quantity: 4.0,
      unit: 'kg',
      actor: 'Ama Kusi',
      timestamp: DateTime.now().subtract(const Duration(hours: 5, minutes: 42)),
      note: 'Assigned to Nursery Block B',
    ),
    _InventoryMovement(
      id: 'MOV-1003',
      itemName: 'Calcium Nitrate',
      farm: 'Harvest Moon Farm',
      type: _MovementType.stockOut,
      quantity: 10.0,
      unit: 'kg',
      actor: 'Nana Ofori',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      note: 'Mixed for hydroponic line 2',
    ),
    _InventoryMovement(
      id: 'MOV-1004',
      itemName: 'Packaging Crates - Medium',
      farm: 'Green Valley Farm',
      type: _MovementType.stockIn,
      quantity: 60.0,
      unit: 'pcs',
      actor: 'Kojo Asare',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      note: 'Warehouse replenishment',
    ),
    _InventoryMovement(
      id: 'MOV-1005',
      itemName: 'Neem Oil (Organic)',
      farm: 'Golden Fields',
      type: _MovementType.stockOut,
      quantity: 2.0,
      unit: 'L',
      actor: 'Esi Boateng',
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      note: 'Pest treatment zone C',
    ),
    _InventoryMovement(
      id: 'MOV-1006',
      itemName: 'pH Down Solution',
      farm: 'Sunny Acres',
      type: _MovementType.stockIn,
      quantity: 12.0,
      unit: 'L',
      actor: 'Ama Kusi',
      timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
      note: 'Emergency reorder fulfilled',
    ),
  ];

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
        const SizedBox(height: AppSpacing.lg),
        _buildStats(isDark, _items),
        const SizedBox(height: AppSpacing.lg),
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
        boxShadow: [
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
                const SizedBox(height: AppSpacing.lg),
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
                  fontWeight: FontWeight.w800,
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
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card.title,
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? Colors.white60
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
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
                        fontWeight: FontWeight.w800,
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
                      fontWeight: FontWeight.w800,
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
                      fontWeight: FontWeight.w800,
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
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isDark ? Colors.white54 : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
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
                    fontWeight: FontWeight.w800,
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
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          _buildTabItem(
            isDark: isDark,
            label: 'Inventory',
            icon: Icons.inventory_2_rounded,
            index: 0,
          ),
          _buildTabItem(
            isDark: isDark,
            label: 'In/Out History',
            icon: Icons.history_rounded,
            index: 1,
          ),
        ],
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
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? AppColors.primary
                    : (isDark ? Colors.white70 : AppColors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.primary
                      : (isDark ? Colors.white70 : AppColors.textSecondary),
                ),
              ),
            ],
          ),
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
              fontWeight: FontWeight.w800,
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
                        fontWeight: FontWeight.w700,
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
                    fontWeight: FontWeight.w700,
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
            fontWeight: FontWeight.w700,
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
        );
        break;
      case _InventoryAction.stockOut:
        _showStockChangeModal(
          entry: entry,
          title: 'Stock Out',
          confirmLabel: 'Remove Stock',
          confirmColor: AppColors.warning,
          icon: Icons.remove_circle_outline_rounded,
        );
        break;
      case _InventoryAction.adjust:
        _showStockChangeModal(
          entry: entry,
          title: 'Inventory Adjustment',
          confirmLabel: 'Apply Adjustment',
          confirmColor: AppColors.primary,
          icon: Icons.tune_rounded,
        );
        break;
      case _InventoryAction.viewDetails:
        _showInventoryDetailsModal(entry);
        break;
    }
  }

  void _showStockChangeModal({
    required _InventoryEntry entry,
    required String title,
    required String confirmLabel,
    required Color confirmColor,
    required IconData icon,
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
                onConfirm: () {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('$confirmLabel completed for ${entry.id}')),
                  );
                },
              ),
            ],
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
                        _detailRow(isDark, 'Quantity',
                            '${entry.quantity} ${entry.unit}'),
                        _detailRow(isDark, 'Minimum Stock',
                            '${entry.minStock} ${entry.unit}'),
                        _detailRow(isDark, 'Unit Cost',
                            '\$${entry.unitCost.toStringAsFixed(2)}'),
                        _detailRow(isDark, 'Total Value',
                            '\$${entry.totalValue.toStringAsFixed(2)}'),
                        _detailRow(isDark, 'Status', statusText),
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
      decoration: InputDecoration(
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
              style: const TextStyle(fontWeight: FontWeight.w700),
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
                    fontWeight: FontWeight.bold,
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
        : AppColors.error;
    final typeText =
        movement.type == _MovementType.stockIn ? 'Stock In' : 'Stock Out';
    final sign = movement.type == _MovementType.stockIn ? '+' : '-';

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
                          fontWeight: FontWeight.w700,
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
                          fontWeight: FontWeight.w700,
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
              fontWeight: FontWeight.w700,
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
  final String name;
  final String category;
  final String farm;
  final double quantity;
  final String unit;
  final double minStock;
  final double unitCost;
  final String lastUpdatedBy;

  const _InventoryEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.farm,
    required this.quantity,
    required this.unit,
    required this.minStock,
    required this.unitCost,
    required this.lastUpdatedBy,
  });

  bool get isOutOfStock => quantity <= 0;
  bool get isLowStock => quantity <= minStock;
  double get totalValue => quantity * unitCost;
}

enum _MovementType { stockIn, stockOut }

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
