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
  int _selectedNavIndex = 4;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
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
          selectedIndex: 4,
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
          'Packaging Management',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Define types, weights & materials',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showAddPackagingDialog(context, isDark),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Packaging'),
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
        
        // Packaging List - Mobile Cards
        Text(
          'All Packaging Types',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._packagingData.map((p) => _buildMobilePackagingCard(p, isDark)),
      ],
    );
  }
  
  Widget _buildContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Packaging Management', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                  Text('Define packaging types, weights, materials, and track inventory', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                ],
              ),
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
    );
  }
  
  Widget _buildMobileStats(bool isDark) {
    final stats = [
      {'title': 'Total Types', 'value': '24', 'icon': Icons.inventory_2, 'color': AppColors.info},
      {'title': 'Materials', 'value': '5', 'icon': Icons.category, 'color': AppColors.success},
      {'title': 'Stock', 'value': '10.6K', 'icon': Icons.warehouse, 'color': AppColors.primary},
      {'title': 'Avg Cost', 'value': '\$0.80', 'icon': Icons.attach_money, 'color': AppColors.warning},
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
  
  Widget _buildMobilePackagingCard(Map<String, dynamic> packaging, bool isDark) {
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
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.inventory_2, color: AppColors.info, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      packaging['type'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${packaging['weight']}${packaging['unit']} • ${packaging['material']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${packaging['cost'].toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _buildInfoChip(
                '${packaging['stock']} units',
                Icons.warehouse,
                isDark,
                color: AppColors.primary,
              ),
              const Spacer(),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _showEditPackagingDialog(context, packaging, isDark),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: AppColors.primary,
                ),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _showDeletePackagingDialog(context, packaging, isDark),
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
              IconButton(onPressed: () => _showEditPackagingDialog(context, packaging, isDark), icon: const Icon(Icons.edit_outlined, size: 18), color: AppColors.primary),
              IconButton(onPressed: () => _showDeletePackagingDialog(context, packaging, isDark), icon: const Icon(Icons.delete_outline, size: 18), color: AppColors.error),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showEditPackagingDialog(BuildContext context, Map<String, dynamic> packaging, bool isDark) {
    final typeController = TextEditingController(text: packaging['type']);
    final weightController = TextEditingController(text: packaging['weight'].toString());
    final costController = TextEditingController(text: packaging['cost'].toString());
    final stockController = TextEditingController(text: packaging['stock'].toString());
    String selectedUnit = packaging['unit'];
    String selectedMaterial = packaging['material'];
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
            width: isMobile ? double.infinity : 500,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.info, AppColors.info.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)), child: const Icon(Icons.edit, color: Colors.white, size: 24)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Edit Packaging', style: AppTypography.h6.copyWith(color: Colors.white, fontWeight: FontWeight.bold)), Text('Modify packaging details', style: AppTypography.bodySmall.copyWith(color: Colors.white70))])),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                // Preview Card
                Container(
                  margin: const EdgeInsets.all(AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : AppColors.info.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.info.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSm)), child: const Icon(Icons.inventory_2, color: AppColors.info, size: 24)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(packaging['type'], style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                        Text('${packaging['weight']}${packaging['unit']} • ${packaging['material']}', style: AppTypography.bodySmall.copyWith(color: isDark ? Colors.white60 : AppColors.textSecondary)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
                        child: Text('\$${packaging['cost'].toStringAsFixed(2)}', style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                // Form
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormLabel('Packaging Type', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(controller: typeController, hint: 'e.g., Small Box', icon: Icons.inventory_2_outlined, isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        if (!isMobile) Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Weight', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: weightController, hint: '500', icon: Icons.scale, isDark: isDark, keyboardType: TextInputType.number)])),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Unit', isDark), const SizedBox(height: AppSpacing.sm), _buildDropdownField(value: selectedUnit, items: ['g', 'kg', 'lbs', 'oz'], icon: Icons.straighten, isDark: isDark, onChanged: (v) => setDialogState(() => selectedUnit = v!))])),
                        ]) else ...[
                          _buildFormLabel('Weight', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: weightController, hint: '500', icon: Icons.scale, isDark: isDark, keyboardType: TextInputType.number),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Unit', isDark), const SizedBox(height: AppSpacing.sm), _buildDropdownField(value: selectedUnit, items: ['g', 'kg', 'lbs', 'oz'], icon: Icons.straighten, isDark: isDark, onChanged: (v) => setDialogState(() => selectedUnit = v!)),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Material', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(value: selectedMaterial, items: ['Plastic', 'Cardboard', 'Paper', 'Biodegradable', 'Glass'], icon: Icons.category, isDark: isDark, onChanged: (v) => setDialogState(() => selectedMaterial = v!)),
                        const SizedBox(height: AppSpacing.lg),
                        if (!isMobile) Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Cost (\$)', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: costController, hint: '2.50', icon: Icons.attach_money, isDark: isDark, keyboardType: TextInputType.number)])),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Stock', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: stockController, hint: '1000', icon: Icons.warehouse, isDark: isDark, keyboardType: TextInputType.number)])),
                        ]) else ...[
                          _buildFormLabel('Cost (\$)', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: costController, hint: '2.50', icon: Icons.attach_money, isDark: isDark, keyboardType: TextInputType.number),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Stock', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: stockController, hint: '1000', icon: Icons.warehouse, isDark: isDark, keyboardType: TextInputType.number),
                        ],
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
                      OutlinedButton(onPressed: () => _showDeletePackagingDialog(context, packaging, isDark), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md), side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), side: BorderSide(color: isDark ? Colors.white24 : AppColors.neutral300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(flex: 2, child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), Text('${typeController.text} updated!')]), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)))); }, icon: const Icon(Icons.save, size: 18), label: const Text('Save Changes'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.info, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))))),
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
  
  void _showDeletePackagingDialog(BuildContext context, Map<String, dynamic> packaging, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_forever, color: AppColors.error, size: 40),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Delete Packaging?', style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Text('Are you sure you want to delete "${packaging['type']}"?', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.warning.withOpacity(0.3))),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text('This will also affect associated pricing configurations.', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary))),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), side: BorderSide(color: isDark ? Colors.white24 : AppColors.neutral300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.delete, color: Colors.white), const SizedBox(width: 8), Text('${packaging['type']} deleted!')]), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)))); }, icon: const Icon(Icons.delete, size: 18), label: const Text('Delete'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showAddPackagingDialog(BuildContext context, bool isDark) {
    final typeController = TextEditingController();
    final weightController = TextEditingController();
    final costController = TextEditingController();
    final stockController = TextEditingController();
    String selectedUnit = 'kg';
    String selectedMaterial = 'Plastic';
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
            width: isMobile ? double.infinity : 500,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)), child: const Icon(Icons.inventory_2, color: Colors.white, size: 24)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Add Packaging', style: AppTypography.h6.copyWith(color: Colors.white, fontWeight: FontWeight.bold)), Text('Create new packaging option', style: AppTypography.bodySmall.copyWith(color: Colors.white70))])),
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
                        _buildFormLabel('Packaging Type', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(controller: typeController, hint: 'e.g., Small Box', icon: Icons.inventory_2_outlined, isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        if (!isMobile) Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Weight', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: weightController, hint: '500', icon: Icons.scale, isDark: isDark, keyboardType: TextInputType.number)])),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Unit', isDark), const SizedBox(height: AppSpacing.sm), _buildDropdownField(value: selectedUnit, items: ['g', 'kg', 'lbs', 'oz'], icon: Icons.straighten, isDark: isDark, onChanged: (v) => setDialogState(() => selectedUnit = v!))])),
                        ]) else ...[
                          _buildFormLabel('Weight', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: weightController, hint: '500', icon: Icons.scale, isDark: isDark, keyboardType: TextInputType.number),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Unit', isDark), const SizedBox(height: AppSpacing.sm), _buildDropdownField(value: selectedUnit, items: ['g', 'kg', 'lbs', 'oz'], icon: Icons.straighten, isDark: isDark, onChanged: (v) => setDialogState(() => selectedUnit = v!)),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Material', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(value: selectedMaterial, items: ['Plastic', 'Cardboard', 'Paper', 'Biodegradable', 'Glass'], icon: Icons.category, isDark: isDark, onChanged: (v) => setDialogState(() => selectedMaterial = v!)),
                        const SizedBox(height: AppSpacing.lg),
                        if (!isMobile) Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Cost (\$)', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: costController, hint: '2.50', icon: Icons.attach_money, isDark: isDark, keyboardType: TextInputType.number)])),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Stock', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: stockController, hint: '1000', icon: Icons.warehouse, isDark: isDark, keyboardType: TextInputType.number)])),
                        ]) else ...[
                          _buildFormLabel('Cost (\$)', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: costController, hint: '2.50', icon: Icons.attach_money, isDark: isDark, keyboardType: TextInputType.number),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Stock', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: stockController, hint: '1000', icon: Icons.warehouse, isDark: isDark, keyboardType: TextInputType.number),
                        ],
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
                      Expanded(flex: 2, child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), Text('${typeController.text.isEmpty ? "Packaging" : typeController.text} added!')]), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)))); }, icon: const Icon(Icons.add, size: 18), label: const Text('Add Packaging'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))))),
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
  
  // Helper widgets
  Widget _buildFormLabel(String label, bool isDark) => Text(label, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary));
  
  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, required bool isDark, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller, keyboardType: keyboardType, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: isDark ? Colors.white38 : AppColors.textSecondary.withOpacity(0.5)), prefixIcon: Icon(icon, color: isDark ? Colors.white54 : AppColors.textSecondary, size: 20), filled: true, fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.neutral200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.neutral200)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: const BorderSide(color: AppColors.primary, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md)),
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
