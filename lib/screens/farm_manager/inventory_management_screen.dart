import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/permission_gate.dart';
import '../../core/models/user/user_permissions.dart';
import '../../core/widgets/farm_manager_sidebar.dart';
import '../../core/widgets/farm_manager_header.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/app_filter_chip.dart';

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
  int _selectedNavIndex = 1;
  final _scrollController = ScrollController();

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
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole, isTablet),
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
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

  Widget _buildDesktopLayout(
      bool isDark, String userName, String userEmail, String userRole, bool isTablet) {
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
        ),

        // Content
        Expanded(
          child: CustomScrollView(
            slivers: [
              // Search and Filter Section
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppSearchBar(
                              hintText: 'Search inventory...',
                              onChanged: (value) => setState(() => _searchQuery = value),
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
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSummary(bool isDark, bool isTablet) {
    final stats = [
      {
        'title': 'Total Items',
        'value': '48',
        'icon': Icons.inventory_2,
        'color': AppColors.primary,
        'change': '+5.2%',
        'isPositive': true,
      },
      {
        'title': 'Low Stock',
        'value': '7',
        'icon': Icons.warning,
        'color': AppColors.warning,
        'change': '+2',
        'isPositive': false,
      },
      {
        'title': 'Out of Stock',
        'value': '2',
        'icon': Icons.error,
        'color': AppColors.error,
        'change': '-1',
        'isPositive': true,
      },
      {
        'title': 'Total Value',
        'value': '\$12,458',
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

  Widget _buildStatCard(Map<String, dynamic> stat, bool isDark, [bool isMobile = false]) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: isMobile ? 40 : 48,
              height: isMobile ? 40 : 48,
              decoration: BoxDecoration(
                color: (stat['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                stat['icon'] as IconData,
                color: stat['color'] as Color,
                size: isMobile ? 20 : 24,
              ),
            ),
            SizedBox(width: isMobile ? AppSpacing.sm : AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    stat['value'] as String,
                    style: AppTypography.h4.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: isMobile ? 20 : 24,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat['title'] as String,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
                      fontSize: isMobile ? 11 : 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (stat['isPositive'] as bool)
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (stat['isPositive'] as bool) ? Icons.trending_up : Icons.trending_down,
                          size: 12,
                          color: (stat['isPositive'] as bool) ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          stat['change'] as String,
                          style: AppTypography.caption.copyWith(
                            color:
                                (stat['isPositive'] as bool) ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'this month',
                    style: AppTypography.caption.copyWith(
                      color: isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileStats(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.5,
        children: [
          _buildMobileStatCard('48', 'Total Items', AppColors.primary, isDark),
          _buildMobileStatCard('7', 'Low Stock', AppColors.warning, isDark),
          _buildMobileStatCard('2', 'Out of Stock', AppColors.error, isDark),
          _buildMobileStatCard('\$12.5K', 'Total Value', AppColors.success, isDark),
        ],
      ),
    );
  }

  Widget _buildMobileStatCard(String value, String title, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.neutral100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 20,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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
                        onChanged: (value) => setState(() => _showLowStockOnly = value),
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
                        onChanged: (value) => setState(() => _searchQuery = value),
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
                      onChanged: (value) => setState(() => _showLowStockOnly = value),
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
    final categories = [
      {'label': 'All', 'icon': Icons.all_inclusive, 'count': 48},
      {'label': 'Fertilizer', 'icon': Icons.grass, 'count': 12},
      {'label': 'Seeds', 'icon': Icons.eco, 'count': 8},
      {'label': 'Nutrients', 'icon': Icons.science, 'count': 9},
      {'label': 'Pesticides', 'icon': Icons.pest_control, 'count': 6},
      {'label': 'Tools', 'icon': Icons.build, 'count': 7},
      {'label': 'Packaging', 'icon': Icons.inventory, 'count': 4},
      {'label': 'Other', 'icon': Icons.category, 'count': 2},
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
            padding: EdgeInsets.only(right: isMobile ? AppSpacing.xs : AppSpacing.sm),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    size: isMobile ? 14 : 16,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white.withOpacity(0.8) : AppColors.textPrimary),
                  ),
                  SizedBox(width: isMobile ? 4 : 6),
                  Text(
                    category['label'] as String,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 11 : 13,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white.withOpacity(0.8) : AppColors.textPrimary),
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
                          : (isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral100),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${category['count']}',
                      style: AppTypography.caption.copyWith(
                        fontSize: isMobile ? 9 : 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary),
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
                      : (isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200),
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

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 2 : 3,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: isTablet ? 1.15 : 1.2,
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

  Widget _buildInventoryCard(Map<String, dynamic> item, bool isDark, [bool isMobile = false]) {
    final totalValue = (item['quantity'] as double) * (item['unitCost'] as double);
    final stockPercentage = (item['quantity'] as double) / (item['maxStock'] as double);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isDark 
                ? Colors.white.withOpacity(0.1) 
                : AppColors.neutral200,
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
                padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isMobile ? AppSpacing.xs : AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: (item['color'] as Color).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                            SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item['name'] as String,
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.textPrimary,
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
                                        color: isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          item['category'] as String,
                                          style: AppTypography.caption.copyWith(
                                            color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
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
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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
                      padding: EdgeInsets.all(isMobile ? AppSpacing.xs : AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withOpacity(0.03) 
                            : AppColors.neutral50,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                                    color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Stock Level',
                                      style: AppTypography.caption.copyWith(
                                        color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
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
                                  color: (item['color'] as Color).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            child: LinearProgressIndicator(
                              value: stockPercentage,
                              backgroundColor: isDark ? Colors.white10 : AppColors.neutral100,
                              valueColor: AlwaysStoppedAnimation<Color>(item['color'] as Color),
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
                                          color: isDark ? Colors.white.withOpacity(0.7) : AppColors.textPrimary,
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
                                          color: isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary,
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
                            padding: EdgeInsets.all(isMobile ? AppSpacing.xs : AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.03) 
                                  : AppColors.neutral50,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
                                      color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Unit Cost',
                                      style: AppTypography.caption.copyWith(
                                        color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
                                        fontSize: isMobile ? 9 : 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${item['unitCost']}',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? AppSpacing.xs : AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.03) 
                                  : AppColors.neutral50,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
                                      color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Total Value',
                                      style: AppTypography.caption.copyWith(
                                        color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
                                        fontSize: isMobile ? 9 : 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${totalValue.toStringAsFixed(2)}',
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
                      SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
                      Container(
                        padding: EdgeInsets.all(isMobile ? AppSpacing.xs : AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
                              backgroundColor: AppColors.success.withOpacity(0.1),
                              foregroundColor: AppColors.success,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                vertical: isMobile ? 8 : 10,
                                horizontal: isMobile ? AppSpacing.xs : AppSpacing.sm,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                        SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),
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
                                horizontal: isMobile ? AppSpacing.xs : AppSpacing.sm,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
        'icon': Icons.inventory_2_outlined,
        'label': 'Inventory',
        'index': 1,
        'route': '/farm-manager/inventory'
      },
      {
        'icon': Icons.grid_view_outlined,
        'label': 'Batches',
        'index': 2,
        'route': '/farm-manager/batch-generation'
      },
      {
        'icon': Icons.request_quote_outlined,
        'label': 'Funds',
        'index': 3,
        'route': '/farm-manager/fund-request'
      },
      {'icon': Icons.assessment_outlined, 'label': 'Reports', 'index': 4, 'route': '/farm-manager/reports'},
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
            color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral100,
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
                          Navigator.pushReplacementNamed(context, item['route'] as String);
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
                                top: BorderSide(color: AppColors.primary, width: 2),
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
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
                    color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDark ? Colors.white.withOpacity(0.9) : AppColors.textPrimary,
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

    var filteredItems = items;
    if (_selectedCategory != 'All') {
      filteredItems = items.where((item) => item['category'] == _selectedCategory).toList();
    }
    if (_showLowStockOnly) {
      filteredItems = filteredItems.where((item) => item['status'] != 'Good').toList();
    }
    if (_searchQuery.isNotEmpty) {
      filteredItems = filteredItems
          .where(
              (item) => (item['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
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
            if (item['expiryDate'] != null) Text('Expiry: ${item['expiryDate']}'),
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
