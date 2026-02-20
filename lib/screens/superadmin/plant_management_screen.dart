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
  int _selectedNavIndex = 3;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final userName = user?.name ?? 'Super Admin';
    final userEmail = user?.email ?? '';
    final firstName = userName.split(' ').first;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? SuperAdminDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) {
                setState(() => _selectedNavIndex = index);
              },
              userName: userName,
              userEmail: userEmail,
              userRole: 'Super Administrator',
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, firstName)
          : _buildDesktopLayout(isDark, userName, userEmail, firstName),
    );
  }
  
  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail, String firstName) {
    return Row(
      children: [
        SuperAdminSidebar(
          selectedIndex: 3,
          onItemSelected: (_) {},
          userName: userName,
          userEmail: userEmail,
          userRole: 'Super Administrator',
        ),
        Expanded(
          child: Column(
            children: [
              ModernAdminHeader(
                userName: firstName,
                onNotificationTap: () {},
                onProfileTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: _buildContent(isDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMobileLayout(bool isDark, String firstName) {
    return Column(
      children: [
        ModernAdminHeader(
          userName: firstName,
          onNotificationTap: () {},
          onProfileTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildMobileContent(isDark),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMobileContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header - Mobile
        Text(
          'Plant Type Management',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage plant varieties & maturity',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showAddPlantDialog(context, isDark),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Plant Type'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Stats - Mobile Grid
        _buildMobileStats(isDark),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Plant Types - Mobile Cards
        Text(
          'All Plant Types',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._plantTypes.map((plant) => _buildMobilePlantCard(plant, isDark)),
      ],
    );
  }
  
  Widget _buildContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Add Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plant Type Management', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                  Text('Create and manage plant varieties with maturity duration', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                ],
              ),
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
    );
  }
  
  Widget _buildMobileStats(bool isDark) {
    final stats = [
      {'title': 'Total Types', 'value': '45', 'icon': Icons.eco, 'color': AppColors.success},
      {'title': 'Active', 'value': '42', 'icon': Icons.check_circle, 'color': AppColors.primary},
      {'title': 'Categories', 'value': '8', 'icon': Icons.category, 'color': AppColors.info},
      {'title': 'Avg Maturity', 'value': '2.5 mo', 'icon': Icons.schedule, 'color': AppColors.warning},
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.7,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        final statColor = stat['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: statColor.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: statColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(stat['icon'] as IconData, color: statColor, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      stat['title'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: statColor.withOpacity(0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatsCards(bool isDark) {
    final stats = [
      {'title': 'Total Types', 'value': '45', 'icon': Icons.eco, 'color': AppColors.success},
      {'title': 'Active', 'value': '42', 'icon': Icons.check_circle, 'color': AppColors.primary},
      {'title': 'Categories', 'value': '8', 'icon': Icons.category, 'color': AppColors.info},
      {'title': 'Avg Maturity', 'value': '2.5 mo', 'icon': Icons.schedule, 'color': AppColors.warning},
    ];
    
    return Row(
      children: stats.map((stat) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: stat != stats.last ? AppSpacing.md : 0),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: (stat['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: (stat['color'] as Color).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat['value'] as String,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: stat['color'] as Color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      stat['title'] as String,
                      style: TextStyle(fontSize: 10, color: (stat['color'] as Color).withOpacity(0.8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }
  
  Widget _buildMobilePlantCard(Map<String, dynamic> plant, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.local_florist, color: AppColors.success, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      plant['category'],
                      style: TextStyle(
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
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  plant['status'],
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _buildInfoChip(
                '${plant['maturity']} months',
                Icons.schedule,
                isDark,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildInfoChip(
                plant['created'],
                Icons.calendar_today,
                isDark,
              ),
              const Spacer(),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _showEditPlantDialog(context, plant, isDark),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: AppColors.primary,
                ),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _showDeleteDialog(context, plant, isDark),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoChip(String text, IconData icon, bool isDark, {Color? color}) {
    final chipColor = color ?? (isDark ? Colors.white54 : AppColors.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(fontSize: 10, color: chipColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
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
    final maturityController = TextEditingController();
    String selectedCategory = 'Leafy Greens';
    String selectedStatus = 'Active';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl, vertical: AppSpacing.xl),
          child: Container(
            width: isMobile ? double.infinity : 480,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.success, AppColors.success.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                        child: const Icon(Icons.eco, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Add Plant Type', style: AppTypography.h6.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Register a new plant variety', style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                // Form
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormLabel('Plant Name', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(controller: nameController, hint: 'e.g., Lettuce - Romaine', icon: Icons.eco, isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Category', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(value: selectedCategory, items: ['Leafy Greens', 'Herbs', 'Root Vegetables', 'Fruits', 'Flowers'], icon: Icons.category, isDark: isDark, onChanged: (v) => setDialogState(() => selectedCategory = v!)),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Maturity Duration (months)', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(controller: maturityController, hint: 'e.g., 2', icon: Icons.schedule, isDark: isDark, keyboardType: TextInputType.number),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Status', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(value: selectedStatus, items: ['Active', 'Inactive'], icon: Icons.toggle_on_outlined, isDark: isDark, onChanged: (v) => setDialogState(() => selectedStatus = v!)),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusXl))),
                  child: Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), side: BorderSide(color: isDark ? Colors.white24 : AppColors.neutral300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(flex: 2, child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), Text('${nameController.text.isEmpty ? "Plant" : nameController.text} added!')]), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)))); }, icon: const Icon(Icons.add, size: 18), label: const Text('Add Plant'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showEditPlantDialog(BuildContext context, Map<String, dynamic> plant, bool isDark) {
    final nameController = TextEditingController(text: plant['name']);
    final maturityController = TextEditingController(text: plant['maturity'].toString());
    String selectedCategory = plant['category'];
    String selectedStatus = plant['status'];
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl, vertical: AppSpacing.xl),
          child: Container(
            width: isMobile ? double.infinity : 480,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.success, AppColors.success.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)), child: const Icon(Icons.edit, color: Colors.white, size: 24)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Edit Plant Type', style: AppTypography.h6.copyWith(color: Colors.white, fontWeight: FontWeight.bold)), Text('Update plant information', style: AppTypography.bodySmall.copyWith(color: Colors.white70))])),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                // Preview
                Container(
                  margin: const EdgeInsets.all(AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08))),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)), child: const Icon(Icons.eco, color: AppColors.success, size: 24)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(plant['name'], style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)), Text('${plant['category']} • ${plant['maturity']} months', style: AppTypography.bodySmall.copyWith(color: isDark ? Colors.white60 : AppColors.textSecondary))])),
                    ],
                  ),
                ),
                // Form
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormLabel('Plant Name', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(controller: nameController, hint: 'Plant name', icon: Icons.eco, isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Category', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(value: selectedCategory, items: ['Leafy Greens', 'Herbs', 'Root Vegetables', 'Fruits', 'Flowers'], icon: Icons.category, isDark: isDark, onChanged: (v) => setDialogState(() => selectedCategory = v!)),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Maturity (months)', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(controller: maturityController, hint: 'Months', icon: Icons.schedule, isDark: isDark, keyboardType: TextInputType.number),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Status', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(value: selectedStatus, items: ['Active', 'Inactive'], icon: Icons.toggle_on_outlined, isDark: isDark, onChanged: (v) => setDialogState(() => selectedStatus = v!)),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusXl))),
                  child: Row(
                    children: [
                      OutlinedButton.icon(onPressed: () { Navigator.pop(context); _showDeleteDialog(context, plant, isDark); }, icon: const Icon(Icons.delete_outline, size: 18), label: const Text('Delete'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md), side: BorderSide(color: AppColors.error.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), side: BorderSide(color: isDark ? Colors.white24 : AppColors.neutral300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), Text('${nameController.text} updated!')]), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)))); }, icon: const Icon(Icons.save, size: 18), label: const Text('Save'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showDeleteDialog(BuildContext context, Map<String, dynamic> plant, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Delete Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_forever, color: AppColors.error, size: 40),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Delete Plant Type?', style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Text('Are you sure you want to delete "${plant['name']}"?', textAlign: TextAlign.center, style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              // Plant Preview Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : AppColors.error.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                      child: const Icon(Icons.eco, color: AppColors.success, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plant['name'], style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary)),
                          Text('${plant['category']} • ${plant['maturity']}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (plant['status'] == 'Active' ? AppColors.success : AppColors.warning).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(plant['status'], style: TextStyle(color: plant['status'] == 'Active' ? AppColors.success : AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Warning Banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text('This will also delete all associated pricing and batch data. This action cannot be undone.', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary))),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), side: BorderSide(color: isDark ? Colors.white24 : AppColors.neutral300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.delete, color: Colors.white), const SizedBox(width: 8), Text('${plant['name']} deleted')]), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)))); }, icon: const Icon(Icons.delete, size: 18), label: const Text('Delete'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper widgets
  Widget _buildFormLabel(String label, bool isDark) => Text(label, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary));
  
  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, required bool isDark, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: isDark ? Colors.white38 : AppColors.textSecondary.withOpacity(0.5)), prefixIcon: Icon(icon, color: isDark ? Colors.white54 : AppColors.textSecondary, size: 20), filled: true, fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.neutral200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.neutral200)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: const BorderSide(color: AppColors.success, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md)),
    );
  }
  
  Widget _buildDropdownField({required String value, required List<String> items, required IconData icon, required bool isDark, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: isDark ? Colors.white12 : AppColors.neutral200)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, icon: Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white54 : AppColors.textSecondary), dropdownColor: isDark ? AppColors.surfaceDark : Colors.white, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontSize: 14), items: items.map((item) => DropdownMenuItem(value: item, child: Row(children: [Icon(icon, color: isDark ? Colors.white54 : AppColors.textSecondary, size: 20), const SizedBox(width: AppSpacing.md), Text(item)]))).toList(), onChanged: onChanged)),
    );
  }
  
}
