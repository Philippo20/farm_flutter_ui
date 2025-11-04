import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../providers/auth_provider.dart';

/// Packaging Management - Define packaging types, weights, and materials
class PackagingScreen extends ConsumerStatefulWidget {
  const PackagingScreen({super.key});

  @override
  ConsumerState<PackagingScreen> createState() => _PackagingScreenState();
}

class _PackagingScreenState extends ConsumerState<PackagingScreen> {
  final List<Map<String, dynamic>> _packagingData = [
    {'id': 'PK001', 'type': 'Box', 'weight': 500, 'unit': 'g', 'material': 'Cardboard', 'cost': 0.50, 'stock': 1200},
    {'id': 'PK002', 'type': 'Crate', 'weight': 1, 'unit': 'kg', 'material': 'Plastic', 'cost': 1.20, 'stock': 450},
    {'id': 'PK003', 'type': 'Bag', 'weight': 100, 'unit': 'g', 'material': 'Biodegradable', 'cost': 0.15, 'stock': 3000},
    {'id': 'PK004', 'type': 'Box', 'weight': 250, 'unit': 'g', 'material': 'Cardboard', 'cost': 0.35, 'stock': 800},
    {'id': 'PK005', 'type': 'Container', 'weight': 2, 'unit': 'kg', 'material': 'Plastic', 'cost': 2.50, 'stock': 200},
    {'id': 'PK006', 'type': 'Bag', 'weight': 50, 'unit': 'g', 'material': 'Paper', 'cost': 0.10, 'stock': 5000},
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
            selectedIndex: 4,
            onItemSelected: (_) {},
            userName: user?.name ?? 'Super Admin',
            userEmail: user?.email ?? '',
            userRole: 'Super Administrator',
          ),
          Expanded(
            child: Column(
              children: [
                ModernAdminHeader(
                  userName: user?.name.split(' ').first ?? 'Super Admin',
                  onNotificationTap: () {},
                  onProfileTap: () {},
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Packaging Management', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                                Text('Define packaging types, weights, materials, and track inventory', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showAddPackagingDialog(context, isDark),
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text('Add Packaging'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Stats
                        _buildStats(isDark),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Packaging Table
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('All Packaging Types', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                              const SizedBox(height: AppSpacing.lg),
                              ..._packagingData.map((p) => _buildPackagingRow(p, isDark)),
                            ],
                          ),
                        ),
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
  
  Widget _buildStats(bool isDark) {
    final stats = [
      {'title': 'Total Types', 'value': '24', 'icon': Icons.inventory_2, 'color': AppColors.info},
      {'title': 'Materials', 'value': '5', 'icon': Icons.category, 'color': AppColors.success},
      {'title': 'Total Stock', 'value': '10.6K', 'icon': Icons.warehouse, 'color': AppColors.primary},
      {'title': 'Avg Cost', 'value': '\$0.80', 'icon': Icons.attach_money, 'color': AppColors.warning},
    ];
    
    return Row(
      children: stats.map((stat) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: stat != stats.last ? AppSpacing.md : 0),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: (stat['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: (stat['color'] as Color).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stat['value'] as String, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: stat['color'] as Color)),
                  Text(stat['title'] as String, style: TextStyle(fontSize: 11, color: (stat['color'] as Color).withOpacity(0.8))),
                ],
              ),
            ],
          ),
        ),
      )).toList(),
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
            child: Text('\$${packaging['cost'].toStringAsFixed(2)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning)),
          ),
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.warehouse, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('${packaging['stock']} units', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined, size: 18), color: AppColors.primary),
              IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline, size: 18), color: AppColors.error),
            ],
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
              SizedBox(height: AppSpacing.md),
              TextField(decoration: InputDecoration(labelText: 'Stock', border: OutlineInputBorder()), keyboardType: TextInputType.number),
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
