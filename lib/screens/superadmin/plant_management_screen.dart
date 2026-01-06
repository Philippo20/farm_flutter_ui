import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../providers/auth_provider.dart';

/// Plant Type Management - Create and manage plant varieties with maturity duration
class PlantManagementScreen extends ConsumerStatefulWidget {
  const PlantManagementScreen({super.key});

  @override
  ConsumerState<PlantManagementScreen> createState() => _PlantManagementScreenState();
}

class _PlantManagementScreenState extends ConsumerState<PlantManagementScreen> {
  final List<Map<String, dynamic>> _plantTypes = [
    {'id': 'P001', 'name': 'Lettuce - Romaine', 'category': 'Leafy Greens', 'maturity': 2, 'status': 'Active', 'created': '2024-01-15'},
    {'id': 'P002', 'name': 'Tomato - Cherry', 'category': 'Fruits', 'maturity': 3, 'status': 'Active', 'created': '2024-01-20'},
    {'id': 'P003', 'name': 'Basil - Sweet', 'category': 'Herbs', 'maturity': 1, 'status': 'Active', 'created': '2024-02-01'},
    {'id': 'P004', 'name': 'Spinach - Baby', 'category': 'Leafy Greens', 'maturity': 1, 'status': 'Active', 'created': '2024-02-10'},
    {'id': 'P005', 'name': 'Pepper - Bell', 'category': 'Vegetables', 'maturity': 4, 'status': 'Active', 'created': '2024-02-15'},
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
            selectedIndex: 3,
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
                        // Title & Add Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Plant Type Management', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                                Text('Create and manage plant varieties with maturity duration', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showAddPlantDialog(context, isDark),
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text('Add Plant Type'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Stats Cards
                        _buildStatsCards(isDark),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Plant Types Table
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
                              Text('All Plant Types', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                              const SizedBox(height: AppSpacing.lg),
                              ..._plantTypes.map((plant) => _buildPlantRow(plant, isDark)),
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
  
  Widget _buildStatsCards(bool isDark) {
    final stats = [
      {'title': 'Total Plant Types', 'value': '45', 'icon': Icons.eco, 'color': AppColors.success},
      {'title': 'Active Types', 'value': '42', 'icon': Icons.check_circle, 'color': AppColors.primary},
      {'title': 'Categories', 'value': '8', 'icon': Icons.category, 'color': AppColors.info},
      {'title': 'Avg Maturity', 'value': '2.5 mo', 'icon': Icons.schedule, 'color': AppColors.warning},
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
  
  Widget _buildPlantRow(Map<String, dynamic> plant, bool isDark) {
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.local_florist, color: AppColors.success, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plant['name'], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary)),
                Text(plant['category'], style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppColors.warning),
                const SizedBox(width: 4),
                Text('${plant['maturity']} months', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(plant['status'], style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ),
          ),
          Expanded(
            child: Text(plant['created'], style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(onPressed: () => _showEditPlantDialog(context, plant, isDark), icon: const Icon(Icons.edit_outlined, size: 18), color: AppColors.primary),
              IconButton(onPressed: () => _showDeleteDialog(context, plant, isDark), icon: const Icon(Icons.delete_outline, size: 18), color: AppColors.error),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showAddPlantDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final maturityController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Plant Type'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Plant Name',
                  hintText: 'e.g., Lettuce - Romaine',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g., Leafy Greens',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: maturityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maturity Duration (months)',
                  hintText: 'e.g., 2',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Add plant type logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plant type added successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add Plant Type'),
          ),
        ],
      ),
    );
  }
  
  void _showEditPlantDialog(BuildContext context, Map<String, dynamic> plant, bool isDark) {
    final nameController = TextEditingController(text: plant['name']);
    final categoryController = TextEditingController(text: plant['category']);
    final maturityController = TextEditingController(text: plant['maturity'].toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Plant Type'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Plant Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: maturityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maturity Duration (months)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Update plant type logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plant type updated successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteDialog(BuildContext context, Map<String, dynamic> plant, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plant Type'),
        content: Text('Are you sure you want to delete "${plant['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Delete plant type logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plant type deleted successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
