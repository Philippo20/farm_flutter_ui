import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/permission_gate.dart';
import '../../core/models/user/user_permissions.dart';

/// Inventory Management Screen
/// Manage farm inputs, track stock levels, and handle inventory transactions
class InventoryManagementScreen extends ConsumerStatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  ConsumerState<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends ConsumerState<InventoryManagementScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _showLowStockOnly = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Inventory Management',
          style: AppTypography.h5.copyWith(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {},
            tooltip: 'Export Inventory',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Stats
          _buildHeaderStats(isDark),
          
          // Search and Filter Bar
          _buildSearchBar(isDark),
          
          // Category Tabs
          _buildCategoryTabs(isDark),
          
          // Inventory List
          Expanded(
            child: _buildInventoryList(isDark),
          ),
        ],
      ),
      floatingActionButton: PermissionGate(
        permission: Permission.manageInventory,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddInventoryDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Add Item'),
          backgroundColor: AppColors.success,
        ),
      ),
    );
  }

  Widget _buildHeaderStats(bool isDark) {
    final stats = [
      {'title': 'Total Items', 'value': '48', 'icon': Icons.inventory_2, 'color': AppColors.primary},
      {'title': 'Low Stock', 'value': '7', 'icon': Icons.warning, 'color': AppColors.warning},
      {'title': 'Out of Stock', 'value': '2', 'icon': Icons.error, 'color': AppColors.error},
      {'title': 'Total Value', 'value': '\$12.5K', 'icon': Icons.attach_money, 'color': AppColors.success},
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: stats.map((stat) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 24),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    stat['value'] as String,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    stat['title'] as String,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search inventory...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: _showLowStockOnly
                  ? AppColors.warning.withOpacity(0.1)
                  : (isDark ? AppColors.surfaceDark : Colors.white),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: _showLowStockOnly
                    ? AppColors.warning
                    : (isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.warning_amber,
                color: _showLowStockOnly ? AppColors.warning : (isDark ? Colors.white60 : AppColors.textSecondary),
              ),
              onPressed: () => setState(() => _showLowStockOnly = !_showLowStockOnly),
              tooltip: 'Show Low Stock Only',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(bool isDark) {
    final categories = ['All', 'Fertilizer', 'Seeds', 'Nutrients', 'Pesticides', 'Tools', 'Packaging', 'Other'];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : AppColors.textPrimary),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInventoryList(bool isDark) {
    // Demo inventory items
    final items = [
      {
        'name': 'NPK Fertilizer 20-20-20',
        'category': 'Fertilizer',
        'quantity': 45.5,
        'unit': 'kg',
        'minStock': 20.0,
        'maxStock': 100.0,
        'unitCost': 25.0,
        'expiryDate': '2025-12-31',
        'status': 'Good',
        'color': AppColors.success,
      },
      {
        'name': 'Lettuce Seeds (Buttercrunch)',
        'category': 'Seeds',
        'quantity': 8.0,
        'unit': 'kg',
        'minStock': 10.0,
        'maxStock': 50.0,
        'unitCost': 120.0,
        'expiryDate': '2025-06-30',
        'status': 'Low Stock',
        'color': AppColors.warning,
      },
      {
        'name': 'Calcium Nitrate',
        'category': 'Nutrients',
        'quantity': 0.0,
        'unit': 'kg',
        'minStock': 15.0,
        'maxStock': 80.0,
        'unitCost': 18.0,
        'expiryDate': '2026-03-15',
        'status': 'Out of Stock',
        'color': AppColors.error,
      },
      {
        'name': 'pH Down Solution',
        'category': 'Nutrients',
        'quantity': 12.5,
        'unit': 'L',
        'minStock': 5.0,
        'maxStock': 30.0,
        'unitCost': 35.0,
        'expiryDate': '2025-09-20',
        'status': 'Good',
        'color': AppColors.success,
      },
      {
        'name': 'Neem Oil (Organic Pesticide)',
        'category': 'Pesticides',
        'quantity': 3.2,
        'unit': 'L',
        'minStock': 5.0,
        'maxStock': 20.0,
        'unitCost': 45.0,
        'expiryDate': '2025-04-10',
        'status': 'Low Stock',
        'color': AppColors.warning,
      },
      {
        'name': 'Pruning Shears',
        'category': 'Tools',
        'quantity': 8.0,
        'unit': 'pcs',
        'minStock': 5.0,
        'maxStock': 15.0,
        'unitCost': 25.0,
        'expiryDate': null,
        'status': 'Good',
        'color': AppColors.success,
      },
    ];

    // Filter items
    var filteredItems = items;
    if (_selectedCategory != 'All') {
      filteredItems = items.where((item) => item['category'] == _selectedCategory).toList();
    }
    if (_showLowStockOnly) {
      filteredItems = filteredItems.where((item) => item['status'] != 'Good').toList();
    }
    if (_searchQuery.isNotEmpty) {
      filteredItems = filteredItems.where((item) =>
        (item['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        final totalValue = (item['quantity'] as double) * (item['unitCost'] as double);
        final stockPercentage = (item['quantity'] as double) / (item['maxStock'] as double);

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
          ),
          child: InkWell(
            onTap: () => _showItemDetails(item),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: (item['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Icon(
                          _getCategoryIcon(item['category'] as String),
                          color: item['color'] as Color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] as String,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              item['category'] as String,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                color: isDark ? Colors.white60 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (item['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          item['status'] as String,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 10,
                            color: item['color'] as Color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          'Quantity',
                          '${item['quantity']} ${item['unit']}',
                          Icons.inventory,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildInfoChip(
                          'Value',
                          '\$${totalValue.toStringAsFixed(2)}',
                          Icons.attach_money,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildInfoChip(
                          'Unit Cost',
                          '\$${item['unitCost']}',
                          Icons.price_check,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Stock Level',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 10,
                              color: isDark ? Colors.white60 : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${(stockPercentage * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item['color'] as Color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: stockPercentage,
                        backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(item['color'] as Color),
                      ),
                    ],
                  ),
                  if (item['expiryDate'] != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: isDark ? Colors.white60 : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Expires: ${item['expiryDate']}',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 10,
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showStockInDialog(item),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Stock In'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showStockOutDialog(item),
                          icon: const Icon(Icons.remove, size: 16),
                          label: const Text('Stock Out'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white60 : AppColors.textSecondary),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 9,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
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
        content: const Text('Advanced filtering options will be implemented here.'),
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
            Text('Unit Cost: \$${item['unitCost']}'),
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
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stock updated successfully')),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showStockOutDialog(Map<String, dynamic> item) {
    final quantityController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stock updated successfully')),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
