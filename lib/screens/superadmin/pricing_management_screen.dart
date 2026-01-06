import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../providers/auth_provider.dart';

/// Pricing & Packaging Management - Set prices and packaging for plant types
class PricingManagementScreen extends ConsumerStatefulWidget {
  const PricingManagementScreen({super.key});

  @override
  ConsumerState<PricingManagementScreen> createState() => _PricingManagementScreenState();
}

class _PricingManagementScreenState extends ConsumerState<PricingManagementScreen> {
  String _selectedTab = 'pricing';
  
  final List<Map<String, dynamic>> _pricingData = [
    {'id': 'PR001', 'plant': 'Lettuce - Romaine', 'packaging': 'Box - 500g', 'price': 4.99, 'bulkPrice': 4.49, 'status': 'Active'},
    {'id': 'PR002', 'plant': 'Tomato - Cherry', 'packaging': 'Crate - 1kg', 'price': 8.99, 'bulkPrice': 7.99, 'status': 'Active'},
    {'id': 'PR003', 'plant': 'Basil - Sweet', 'packaging': 'Bag - 100g', 'price': 2.99, 'bulkPrice': 2.49, 'status': 'Active'},
    {'id': 'PR004', 'plant': 'Spinach - Baby', 'packaging': 'Box - 250g', 'price': 3.99, 'bulkPrice': 3.49, 'status': 'Active'},
  ];
  
  final List<Map<String, dynamic>> _packagingData = [
    {'id': 'PK001', 'type': 'Box', 'weight': 500, 'unit': 'g', 'material': 'Cardboard', 'cost': 0.50},
    {'id': 'PK002', 'type': 'Crate', 'weight': 1, 'unit': 'kg', 'material': 'Plastic', 'cost': 1.20},
    {'id': 'PK003', 'type': 'Bag', 'weight': 100, 'unit': 'g', 'material': 'Biodegradable', 'cost': 0.15},
    {'id': 'PK004', 'type': 'Box', 'weight': 250, 'unit': 'g', 'material': 'Cardboard', 'cost': 0.35},
  ];
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          SuperAdminSidebar(
            selectedIndex: 5,
            onItemSelected: (_) {},
            userName: user?.name ?? 'Super Admin',
            userEmail: user?.email ?? '',
            userRole: 'Super Administrator',
          ),
          Expanded(
            child: Column(
              children: [
                ModernAdminHeader(userName: user?.name.split(' ').first ?? 'Super Admin', onNotificationTap: () {}, onProfileTap: () {}),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text('Pricing & Packaging Management', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                        Text('Set prices and packaging for plant types', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Tabs
                        _buildTabs(isDark),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Content based on selected tab
                        if (_selectedTab == 'pricing') _buildPricingContent(isDark) else _buildPackagingContent(isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabs(bool isDark) {
    return Row(
      children: [
        _buildTab('Pricing', 'pricing', Icons.attach_money, isDark),
        const SizedBox(width: AppSpacing.md),
        _buildTab('Packaging', 'packaging', Icons.inventory_2, isDark),
      ],
    );
  }
  
  Widget _buildTab(String label, String value, IconData icon, bool isDark) {
    final isSelected = _selectedTab == value;
    return InkWell(
      onTap: () => setState(() => _selectedTab = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : AppColors.neutral100),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textSecondary)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textPrimary), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPricingContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Product Pricing', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
            ElevatedButton.icon(
              onPressed: () => _showAddPricingDialog(context, isDark),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Pricing'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
          ),
          child: Column(
            children: _pricingData.map((pricing) => _buildPricingRow(pricing, isDark)).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPricingRow(Map<String, dynamic> pricing, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.price_check, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pricing['plant'], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary)),
                Text(pricing['packaging'], style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Regular', style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                Text('\$${pricing['price'].toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bulk (10+)', style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                Text('\$${pricing['bulkPrice'].toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.warning)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(pricing['status'], style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: AppSpacing.md),
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined, size: 18), color: AppColors.primary),
          IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline, size: 18), color: AppColors.error),
        ],
      ),
    );
  }
  
  Widget _buildPackagingContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Packaging Types', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
            ElevatedButton.icon(
              onPressed: () => _showAddPackagingDialog(context, isDark),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Packaging'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
          ),
          child: Column(
            children: _packagingData.map((packaging) => _buildPackagingRow(packaging, isDark)).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPackagingRow(Map<String, dynamic> packaging, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.inventory_2, color: AppColors.info, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(packaging['type'], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary)),
                Text('${packaging['weight']}${packaging['unit']}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: Text(packaging['material'], style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary)),
          ),
          Expanded(
            child: Text('Cost: \$${packaging['cost'].toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning)),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined, size: 18), color: AppColors.primary),
          IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline, size: 18), color: AppColors.error),
        ],
      ),
    );
  }
  
  void _showAddPricingDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Pricing'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              TextField(decoration: InputDecoration(labelText: 'Plant Type', border: OutlineInputBorder())),
              SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Packaging', border: OutlineInputBorder())),
              SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Regular Price', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Bulk Price', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pricing added successfully!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  void _showAddPackagingDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Packaging'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              TextField(decoration: InputDecoration(labelText: 'Packaging Type', border: OutlineInputBorder())),
              SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Weight', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Unit (g, kg, lbs)', border: OutlineInputBorder())),
              SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Material', border: OutlineInputBorder())),
              SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Cost', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Packaging added successfully!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
