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
  int _selectedNavIndex = 5;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
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
            selectedIndex: 5,
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
            child: _buildContent(isDark),
          ),
        ),
      ],
    );
  }
  
  Widget _buildContent(bool isDark) {
    return Column(
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
          IconButton(onPressed: () => _showEditPricingDialog(context, pricing, isDark), icon: const Icon(Icons.edit_outlined, size: 18), color: AppColors.primary),
          IconButton(onPressed: () => _showDeletePricingDialog(context, pricing, isDark), icon: const Icon(Icons.delete_outline, size: 18), color: AppColors.error),
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
          IconButton(onPressed: () => _showEditPackagingItemDialog(context, packaging, isDark), icon: const Icon(Icons.edit_outlined, size: 18), color: AppColors.primary),
          IconButton(onPressed: () => _showDeletePackagingItemDialog(context, packaging, isDark), icon: const Icon(Icons.delete_outline, size: 18), color: AppColors.error),
        ],
      ),
    );
  }
  
  void _showEditPricingDialog(BuildContext context, Map<String, dynamic> pricing, bool isDark) {
    final regularPriceController = TextEditingController(text: pricing['price'].toString());
    final bulkPriceController = TextEditingController(text: pricing['bulkPrice'].toString());
    String selectedPlant = pricing['plant'];
    String selectedPackaging = pricing['packaging'];
    String selectedStatus = pricing['status'];
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
                    gradient: LinearGradient(colors: [AppColors.info, AppColors.info.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)), child: const Icon(Icons.edit, color: Colors.white, size: 24)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Edit Pricing', style: AppTypography.h6.copyWith(color: Colors.white, fontWeight: FontWeight.bold)), Text('Modify pricing details', style: AppTypography.bodySmall.copyWith(color: Colors.white70))])),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                // Preview Card
                Container(
                  margin: const EdgeInsets.all(AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : AppColors.success.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.success.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSm)), child: const Icon(Icons.price_check, color: AppColors.primary, size: 24)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(pricing['plant'], style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                        Text(pricing['packaging'], style: AppTypography.bodySmall.copyWith(color: isDark ? Colors.white60 : AppColors.textSecondary)),
                      ])),
                      Column(children: [
                        Text('\$${pricing['price'].toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Bulk: \$${pricing['bulkPrice'].toStringAsFixed(2)}', style: TextStyle(color: AppColors.warning, fontSize: 11)),
                      ]),
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
                        _buildFormLabel('Plant Type', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(value: selectedPlant, items: ['Lettuce - Romaine', 'Tomato - Cherry', 'Basil - Sweet', 'Spinach - Baby', 'Kale - Curly'], icon: Icons.eco, isDark: isDark, onChanged: (v) => setDialogState(() => selectedPlant = v!)),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Packaging', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(value: selectedPackaging, items: ['Box - 500g', 'Crate - 1kg', 'Bag - 100g', 'Box - 250g'], icon: Icons.inventory_2, isDark: isDark, onChanged: (v) => setDialogState(() => selectedPackaging = v!)),
                        const SizedBox(height: AppSpacing.lg),
                        if (!isMobile) Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Regular Price (\$)', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: regularPriceController, hint: '12.99', icon: Icons.attach_money, isDark: isDark, keyboardType: TextInputType.number)])),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Bulk Price (\$)', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: bulkPriceController, hint: '9.99', icon: Icons.sell, isDark: isDark, keyboardType: TextInputType.number)])),
                        ]) else ...[
                          _buildFormLabel('Regular Price (\$)', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: regularPriceController, hint: '12.99', icon: Icons.attach_money, isDark: isDark, keyboardType: TextInputType.number),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Bulk Price (\$)', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: bulkPriceController, hint: '9.99', icon: Icons.sell, isDark: isDark, keyboardType: TextInputType.number),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Status', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(value: selectedStatus, items: ['Active', 'Inactive', 'Promotional'], icon: Icons.toggle_on, isDark: isDark, onChanged: (v) => setDialogState(() => selectedStatus = v!)),
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
                      OutlinedButton(onPressed: () => _showDeletePricingDialog(context, pricing, isDark), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md), side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), side: BorderSide(color: isDark ? Colors.white24 : AppColors.neutral300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(flex: 2, child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), const Text('Pricing updated!')]), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)))); }, icon: const Icon(Icons.save, size: 18), label: const Text('Save Changes'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.info, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))))),
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
  
  void _showDeletePricingDialog(BuildContext context, Map<String, dynamic> pricing, bool isDark) {
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
              Text('Delete Pricing?', style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Text('Are you sure you want to delete pricing for "${pricing['plant']}"?', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), side: BorderSide(color: isDark ? Colors.white24 : AppColors.neutral300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.delete, color: Colors.white), const SizedBox(width: 8), const Text('Pricing deleted!')]), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)))); }, icon: const Icon(Icons.delete, size: 18), label: const Text('Delete'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showEditPackagingItemDialog(BuildContext context, Map<String, dynamic> packaging, bool isDark) {
    final typeController = TextEditingController(text: packaging['type']);
    final weightController = TextEditingController(text: packaging['weight'].toString());
    final costController = TextEditingController(text: packaging['cost'].toString());
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
            width: isMobile ? double.infinity : 480,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Weight', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: weightController, hint: '250', icon: Icons.scale, isDark: isDark, keyboardType: TextInputType.number)])),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Unit', isDark), const SizedBox(height: AppSpacing.sm), _buildDropdownField(value: selectedUnit, items: ['g', 'kg', 'lbs', 'oz'], icon: Icons.straighten, isDark: isDark, onChanged: (v) => setDialogState(() => selectedUnit = v!))])),
                        ]) else ...[
                          _buildFormLabel('Weight', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: weightController, hint: '250', icon: Icons.scale, isDark: isDark, keyboardType: TextInputType.number),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Unit', isDark), const SizedBox(height: AppSpacing.sm), _buildDropdownField(value: selectedUnit, items: ['g', 'kg', 'lbs', 'oz'], icon: Icons.straighten, isDark: isDark, onChanged: (v) => setDialogState(() => selectedUnit = v!)),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Material', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(value: selectedMaterial, items: ['Plastic', 'Cardboard', 'Paper', 'Biodegradable'], icon: Icons.category, isDark: isDark, onChanged: (v) => setDialogState(() => selectedMaterial = v!)),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Cost (\$)', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(controller: costController, hint: '0.50', icon: Icons.attach_money, isDark: isDark, keyboardType: TextInputType.number),
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
                      OutlinedButton(onPressed: () => _showDeletePackagingItemDialog(context, packaging, isDark), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md), side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20)),
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
  
  void _showDeletePackagingItemDialog(BuildContext context, Map<String, dynamic> packaging, bool isDark) {
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
  
  void _showAddPricingDialog(BuildContext context, bool isDark) {
    final regularPriceController = TextEditingController();
    final bulkPriceController = TextEditingController();
    String selectedPlant = 'Lettuce - Romaine';
    String selectedPackaging = 'Box - 500g';
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
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.warning, AppColors.warning.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl))),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)), child: const Icon(Icons.attach_money, color: Colors.white, size: 24)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Add Pricing', style: AppTypography.h6.copyWith(color: Colors.white, fontWeight: FontWeight.bold)), Text('Set price for plant packaging', style: AppTypography.bodySmall.copyWith(color: Colors.white70))])),
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
                        _buildFormLabel('Plant Type', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(value: selectedPlant, items: ['Lettuce - Romaine', 'Tomato - Cherry', 'Basil - Sweet', 'Spinach - Baby', 'Kale - Curly'], icon: Icons.eco, isDark: isDark, onChanged: (v) => setDialogState(() => selectedPlant = v!)),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Packaging', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(value: selectedPackaging, items: ['Box - 500g', 'Crate - 1kg', 'Bag - 100g', 'Box - 250g'], icon: Icons.inventory_2, isDark: isDark, onChanged: (v) => setDialogState(() => selectedPackaging = v!)),
                        const SizedBox(height: AppSpacing.lg),
                        if (!isMobile) Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Regular Price (\$)', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: regularPriceController, hint: '5.99', icon: Icons.sell, isDark: isDark, keyboardType: TextInputType.number)])),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Bulk Price (\$)', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: bulkPriceController, hint: '4.99', icon: Icons.local_offer, isDark: isDark, keyboardType: TextInputType.number)])),
                        ]) else ...[
                          _buildFormLabel('Regular Price (\$)', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: regularPriceController, hint: '5.99', icon: Icons.sell, isDark: isDark, keyboardType: TextInputType.number),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Bulk Price (\$)', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: bulkPriceController, hint: '4.99', icon: Icons.local_offer, isDark: isDark, keyboardType: TextInputType.number),
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
                      Expanded(flex: 2, child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), const Text('Pricing added!')]), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)))); }, icon: const Icon(Icons.add, size: 18), label: const Text('Add Pricing'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))))),
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
  
  void _showAddPackagingDialog(BuildContext context, bool isDark) {
    final typeController = TextEditingController();
    final weightController = TextEditingController();
    final costController = TextEditingController();
    String selectedUnit = 'g';
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
            width: isMobile ? double.infinity : 480,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl))),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)), child: const Icon(Icons.inventory_2, color: Colors.white, size: 24)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Add Packaging', style: AppTypography.h6.copyWith(color: Colors.white, fontWeight: FontWeight.bold)), Text('Create packaging option', style: AppTypography.bodySmall.copyWith(color: Colors.white70))])),
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
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Weight', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: weightController, hint: '250', icon: Icons.scale, isDark: isDark, keyboardType: TextInputType.number)])),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Unit', isDark), const SizedBox(height: AppSpacing.sm), _buildDropdownField(value: selectedUnit, items: ['g', 'kg', 'lbs', 'oz'], icon: Icons.straighten, isDark: isDark, onChanged: (v) => setDialogState(() => selectedUnit = v!))])),
                        ]) else ...[
                          _buildFormLabel('Weight', isDark), const SizedBox(height: AppSpacing.sm), _buildTextField(controller: weightController, hint: '250', icon: Icons.scale, isDark: isDark, keyboardType: TextInputType.number),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Unit', isDark), const SizedBox(height: AppSpacing.sm), _buildDropdownField(value: selectedUnit, items: ['g', 'kg', 'lbs', 'oz'], icon: Icons.straighten, isDark: isDark, onChanged: (v) => setDialogState(() => selectedUnit = v!)),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Material', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(value: selectedMaterial, items: ['Plastic', 'Cardboard', 'Paper', 'Biodegradable'], icon: Icons.category, isDark: isDark, onChanged: (v) => setDialogState(() => selectedMaterial = v!)),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Cost (\$)', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(controller: costController, hint: '0.50', icon: Icons.attach_money, isDark: isDark, keyboardType: TextInputType.number),
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
