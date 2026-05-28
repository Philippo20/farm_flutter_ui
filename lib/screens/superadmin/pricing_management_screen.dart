import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../providers/auth_provider.dart';

/// Pricing & Packaging Management - Set hub and spoke farm prices.
class PricingManagementScreen extends ConsumerStatefulWidget {
  const PricingManagementScreen({super.key});

  @override
  ConsumerState<PricingManagementScreen> createState() =>
      _PricingManagementScreenState();
}

class _PricingManagementScreenState
    extends ConsumerState<PricingManagementScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedNavIndex = 5;
  String _selectedTab = 'pricing';
  String _selectedFarm = 'all';

  final List<_FarmPriceScope> _farms = const [
    _FarmPriceScope(
      id: 'all',
      name: 'Hub Pricing',
      subtitle: 'All spoke farm prices sold into the hub',
      activePrices: '42',
      avgHubRate: '\$3.42',
      icon: Icons.public_rounded,
      color: AppColors.primary,
      isGlobal: true,
    ),
    _FarmPriceScope(
      id: 'green-valley',
      name: 'Green Valley Spoke Farm',
      subtitle: 'Leafy greens and herbs supply',
      activePrices: '14',
      avgHubRate: '\$2.70',
      icon: Icons.agriculture_rounded,
      color: AppColors.success,
    ),
    _FarmPriceScope(
      id: 'north-ridge',
      name: 'North Ridge Spoke Farm',
      subtitle: 'Tomatoes, spinach, and seasonal crops',
      activePrices: '12',
      avgHubRate: '\$5.95',
      icon: Icons.terrain_rounded,
      color: AppColors.info,
    ),
    _FarmPriceScope(
      id: 'sunset-acres',
      name: 'Sunset Acres Spoke Farm',
      subtitle: 'Premium herbs and packaged produce',
      activePrices: '16',
      avgHubRate: '\$2.10',
      icon: Icons.wb_sunny_rounded,
      color: AppColors.warning,
    ),
  ];

  final List<_PricingItem> _pricingData = const [
    _PricingItem(
      id: 'PR-1001',
      farmId: 'green-valley',
      farm: 'Green Valley Spoke Farm',
      plant: 'Lettuce - Romaine',
      packaging: 'Box - 500g',
      hubSellingPrice: 2.85,
      hubBulkPrice: 2.55,
      status: 'Active',
      lastUpdated: 'Today, 09:15',
    ),
    _PricingItem(
      id: 'PR-1002',
      farmId: 'north-ridge',
      farm: 'North Ridge Spoke Farm',
      plant: 'Tomato - Cherry',
      packaging: 'Crate - 1kg',
      hubSellingPrice: 5.95,
      hubBulkPrice: 5.35,
      status: 'Active',
      lastUpdated: 'Today, 08:45',
    ),
    _PricingItem(
      id: 'PR-1003',
      farmId: 'sunset-acres',
      farm: 'Sunset Acres Spoke Farm',
      plant: 'Basil - Sweet',
      packaging: 'Bag - 100g',
      hubSellingPrice: 1.55,
      hubBulkPrice: 1.35,
      status: 'Active',
      lastUpdated: 'Yesterday, 16:20',
    ),
    _PricingItem(
      id: 'PR-1004',
      farmId: 'green-valley',
      farm: 'Green Valley Spoke Farm',
      plant: 'Spinach - Baby',
      packaging: 'Box - 250g',
      hubSellingPrice: 2.25,
      hubBulkPrice: 2.05,
      status: 'Review',
      lastUpdated: 'Yesterday, 11:05',
    ),
    _PricingItem(
      id: 'PR-1005',
      farmId: 'sunset-acres',
      farm: 'Sunset Acres Spoke Farm',
      plant: 'Kale - Curly',
      packaging: 'Bundle - 300g',
      hubSellingPrice: 2.65,
      hubBulkPrice: 2.35,
      status: 'Active',
      lastUpdated: 'May 16, 2026',
    ),
  ];

  final List<_PackagingItem> _packagingData = const [
    _PackagingItem(
      id: 'PK-001',
      type: 'Box',
      size: '500g',
      material: 'Cardboard',
      cost: 0.50,
      status: 'Active',
    ),
    _PackagingItem(
      id: 'PK-002',
      type: 'Crate',
      size: '1kg',
      material: 'Reusable Plastic',
      cost: 1.20,
      status: 'Active',
    ),
    _PackagingItem(
      id: 'PK-003',
      type: 'Bag',
      size: '100g',
      material: 'Biodegradable',
      cost: 0.15,
      status: 'Active',
    ),
    _PackagingItem(
      id: 'PK-004',
      type: 'Bundle Wrap',
      size: '300g',
      material: 'Paper Band',
      cost: 0.22,
      status: 'Active',
    ),
  ];

  List<_PricingItem> get _visiblePrices {
    if (_selectedFarm == 'all') return _pricingData;
    return _pricingData.where((item) => item.farmId == _selectedFarm).toList();
  }

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
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
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

  Widget _buildDesktopLayout(
    bool isDark,
    String userName,
    String userEmail,
    String firstName,
  ) {
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
                  child: _buildContent(isDark, isMobile: false),
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
            child: _buildContent(isDark, isMobile: true),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        _buildTabs(isDark),
        const SizedBox(height: AppSpacing.lg),
        if (_selectedTab == 'pricing') ...[
          _buildFarmScopes(isDark, isMobile),
          const SizedBox(height: AppSpacing.lg),
          _buildPricingPanel(isDark, isMobile),
        ] else
          _buildPackagingPanel(isDark, isMobile),
      ],
    );
  }

  Widget _buildHero(bool isDark, bool isMobile) {
    final prices = _visiblePrices;
    final averageHubSelling = prices.isEmpty
        ? 0.0
        : prices.map((item) => item.hubSellingPrice).reduce((a, b) => a + b) /
            prices.length;
    final averageHubBulk = prices.isEmpty
        ? 0.0
        : prices.map((item) => item.hubBulkPrice).reduce((a, b) => a + b) /
            prices.length;

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF211B11), const Color(0xFF101923)]
              : [const Color(0xFFFFF8E9), const Color(0xFFEFFAF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : AppColors.warning.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroText(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildHeroMetrics(
                    isDark, averageHubSelling, averageHubBulk, prices.length),
                const SizedBox(height: AppSpacing.md),
                _buildHeroActions(isDark),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildHeroText(isDark)),
                const SizedBox(width: AppSpacing.xl),
                SizedBox(
                  width: 340,
                  child: _buildHeroMetrics(
                    isDark,
                    averageHubSelling,
                    averageHubBulk,
                    prices.length,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                SizedBox(width: 180, child: _buildHeroActions(isDark)),
              ],
            ),
    );
  }

  Widget _buildHeroText(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border:
                Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.price_change_rounded,
                color: AppColors.warning,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Hub and spoke price control',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white : AppColors.warning,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Pricing Management',
          style: AppTypography.h4.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Manage each spoke farm price sold into the hub, including standard and bulk hub purchasing rates.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroMetrics(
    bool isDark,
    double averageHubSelling,
    double averageHubBulk,
    int priceCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          _buildMetricLine(
              'Avg selling price to hub', _money(averageHubSelling), isDark),
          const SizedBox(height: 10),
          _buildMetricLine(
              'Avg bulk price to hub', _money(averageHubBulk), isDark),
          const SizedBox(height: 10),
          _buildMetricLine('Active price records', '$priceCount', isDark),
        ],
      ),
    );
  }

  Widget _buildHeroActions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showPricingDialog(context, isDark),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Price'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.file_download_rounded, size: 18),
          label: const Text('Export'),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
            side: BorderSide(
              color: isDark ? Colors.white24 : AppColors.neutral300,
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(bool isDark) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        _buildTab('Pricing', 'pricing', Icons.attach_money_rounded, isDark),
        _buildTab('Packaging', 'packaging', Icons.inventory_2_rounded, isDark),
      ],
    );
  }

  Widget _buildTab(String label, String value, IconData icon, bool isDark) {
    final isSelected = _selectedTab == value;
    return InkWell(
      onTap: () => setState(() => _selectedTab = value),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white10 : AppColors.neutral200),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.textPrimary),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmScopes(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Spoke Farm Price Sources',
          'Select a spoke farm to review prices sold into the hub.',
          isDark,
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _farms.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : 4,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: isMobile ? 2.05 : 1.42,
          ),
          itemBuilder: (context, index) =>
              _buildFarmScopeCard(_farms[index], isDark),
        ),
      ],
    );
  }

  Widget _buildFarmScopeCard(_FarmPriceScope farm, bool isDark) {
    final isSelected = _selectedFarm == farm.id;
    return InkWell(
      onTap: () => setState(() => _selectedFarm = farm.id),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? farm.color.withValues(alpha: isDark ? 0.18 : 0.1)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isSelected
                ? farm.color.withValues(alpha: 0.65)
                : (isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.07)),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: farm.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(farm.icon, color: farm.color, size: 20),
                ),
                const Spacer(),
                _buildPill(farm.isGlobal ? 'Hub' : 'Spoke', farm.color),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              farm.name,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              farm.subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                    child:
                        _buildSmallMetric('Prices', farm.activePrices, isDark)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child:
                        _buildSmallMetric('Avg Hub', farm.avgHubRate, isDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingPanel(bool isDark, bool isMobile) {
    final prices = _visiblePrices;
    final scopeName = _farms
        .firstWhere((farm) => farm.id == _selectedFarm,
            orElse: () => _farms.first)
        .name;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _panelDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Price Book', scopeName, isDark),
                    const SizedBox(height: AppSpacing.md),
                    _buildCountPill('${prices.length} prices', isDark),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                        child: _buildSectionHeader(
                            'Price Book', scopeName, isDark)),
                    _buildCountPill('${prices.length} prices', isDark),
                  ],
                ),
          const SizedBox(height: AppSpacing.md),
          if (isMobile)
            ...prices.map((price) => _buildMobilePriceCard(price, isDark))
          else
            _buildPriceTable(prices, isDark),
        ],
      ),
    );
  }

  Widget _buildPriceTable(List<_PricingItem> prices, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : AppColors.neutral50,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              _buildTableHeader('Product', flex: 3, isDark: isDark),
              _buildTableHeader('Spoke Farm', flex: 2, isDark: isDark),
              _buildTableHeader('Sell To Hub', isDark: isDark),
              _buildTableHeader('Bulk To Hub', isDark: isDark),
              _buildTableHeader('Status', isDark: isDark),
              const SizedBox(width: 88),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...prices.map((price) => _buildPriceRow(price, isDark)),
      ],
    );
  }

  Widget _buildPriceRow(_PricingItem price, bool isDark) {
    final statusColor =
        price.status == 'Active' ? AppColors.success : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.sell_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        price.plant,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${price.farm} • ${price.packaging}',
                        style: AppTypography.bodySmall.copyWith(
                          color:
                              isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              price.farm,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
              child: _buildPriceValue(
                  _money(price.hubSellingPrice), AppColors.success, isDark)),
          Expanded(
              child: _buildPriceValue(
                  _money(price.hubBulkPrice), AppColors.warning, isDark)),
          Expanded(child: _buildPill(price.status, statusColor)),
          SizedBox(
            width: 88,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildIconAction(
                  Icons.edit_outlined,
                  AppColors.primary,
                  () => _showPricingDialog(context, isDark, item: price),
                  'Edit',
                ),
                _buildIconAction(
                  Icons.delete_outline_rounded,
                  AppColors.error,
                  () => _showDeletePricingDialog(context, price, isDark),
                  'Delete',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePriceCard(_PricingItem price, bool isDark) {
    final statusColor =
        price.status == 'Active' ? AppColors.success : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price.plant,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${price.farm} • ${price.packaging}',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildPill(price.status, statusColor),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                  child: _buildSmallMetric(
                      'Sell To Hub', _money(price.hubSellingPrice), isDark)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _buildSmallMetric(
                      'Bulk To Hub', _money(price.hubBulkPrice), isDark)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _buildSmallMetric('Status', price.status, isDark)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${price.id} • ${price.lastUpdated}',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ),
              _buildIconAction(
                Icons.edit_outlined,
                AppColors.primary,
                () => _showPricingDialog(context, isDark, item: price),
                'Edit',
              ),
              _buildIconAction(
                Icons.delete_outline_rounded,
                AppColors.error,
                () => _showDeletePricingDialog(context, price, isDark),
                'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackagingPanel(bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _panelDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'Packaging Types',
                      'Packaging costs used when pricing products.',
                      isDark,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton.icon(
                      onPressed: () => _showPackagingDialog(context, isDark),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Packaging'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildSectionHeader(
                        'Packaging Types',
                        'Packaging costs used when pricing products.',
                        isDark,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showPackagingDialog(context, isDark),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Packaging'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: AppSpacing.md),
          ..._packagingData.map((item) => _buildPackagingRow(item, isDark)),
        ],
      ),
    );
  }

  Widget _buildPackagingRow(_PackagingItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: AppColors.info,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.type,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${item.size} • ${item.material}',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: _buildPriceValue(
                  _money(item.cost), AppColors.warning, isDark)),
          Expanded(child: _buildPill(item.status, AppColors.success)),
          _buildIconAction(
            Icons.edit_outlined,
            AppColors.primary,
            () => _showPackagingDialog(context, isDark, item: item),
            'Edit',
          ),
          _buildIconAction(
            Icons.delete_outline_rounded,
            AppColors.error,
            () => _showDeletePackagingDialog(context, item, isDark),
            'Delete',
          ),
        ],
      ),
    );
  }

  void _showPricingDialog(
    BuildContext context,
    bool isDark, {
    _PricingItem? item,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final hubSellingController = TextEditingController(
      text: item?.hubSellingPrice.toStringAsFixed(2) ?? '',
    );
    final hubBulkController = TextEditingController(
      text: item?.hubBulkPrice.toStringAsFixed(2) ?? '',
    );
    String selectedFarm = item?.farmId ?? 'green-valley';
    String selectedPlant = item?.plant ?? 'Lettuce - Romaine';
    String selectedPackaging = item?.packaging ?? 'Box - 500g';
    String selectedStatus = item?.status ?? 'Active';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
          child: SizedBox(
            width: isMobile ? double.infinity : 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogHeader(
                  item == null ? 'Add Pricing' : 'Edit Pricing',
                  'Set spoke farm selling prices to the hub',
                  Icons.price_change_rounded,
                  AppColors.warning,
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormLabel('Spoke Farm', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedFarm,
                          items: _farms
                              .where((farm) => !farm.isGlobal)
                              .map((farm) => farm.id)
                              .toList(),
                          labels: {
                            for (final farm in _farms) farm.id: farm.name,
                          },
                          icon: Icons.agriculture_rounded,
                          isDark: isDark,
                          onChanged: (value) =>
                              setDialogState(() => selectedFarm = value!),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Plant Type', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedPlant,
                          items: const [
                            'Lettuce - Romaine',
                            'Tomato - Cherry',
                            'Basil - Sweet',
                            'Spinach - Baby',
                            'Kale - Curly',
                          ],
                          icon: Icons.eco_rounded,
                          isDark: isDark,
                          onChanged: (value) =>
                              setDialogState(() => selectedPlant = value!),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Packaging', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedPackaging,
                          items: const [
                            'Box - 500g',
                            'Crate - 1kg',
                            'Bag - 100g',
                            'Box - 250g',
                            'Bundle - 300g',
                          ],
                          icon: Icons.inventory_2_rounded,
                          isDark: isDark,
                          onChanged: (value) =>
                              setDialogState(() => selectedPackaging = value!),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (isMobile)
                          Column(
                            children: [
                              _buildPriceInput(
                                  'Selling Price To Hub (\$)',
                                  hubSellingController,
                                  Icons.sell_rounded,
                                  isDark),
                              const SizedBox(height: AppSpacing.lg),
                              _buildPriceInput(
                                  'Bulk Selling Price To Hub (\$)',
                                  hubBulkController,
                                  Icons.local_offer_rounded,
                                  isDark),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                  child: _buildPriceInput(
                                      'Selling Price To Hub (\$)',
                                      hubSellingController,
                                      Icons.sell_rounded,
                                      isDark)),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                  child: _buildPriceInput(
                                      'Bulk Selling Price To Hub (\$)',
                                      hubBulkController,
                                      Icons.local_offer_rounded,
                                      isDark)),
                            ],
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Status', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedStatus,
                          items: const ['Active', 'Review', 'Inactive'],
                          icon: Icons.verified_rounded,
                          isDark: isDark,
                          onChanged: (value) =>
                              setDialogState(() => selectedStatus = value!),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildDialogActions(
                  isDark,
                  primaryLabel: item == null ? 'Add Pricing' : 'Save Changes',
                  primaryColor: AppColors.primary,
                  onPrimary: () {
                    Navigator.pop(context);
                    _showSnack(item == null
                        ? 'Spoke farm hub pricing added.'
                        : 'Spoke farm hub pricing updated.');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInput(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormLabel(label, isDark),
        const SizedBox(height: AppSpacing.sm),
        _buildTextField(
          controller: controller,
          hint: '0.00',
          icon: icon,
          isDark: isDark,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  void _showPackagingDialog(
    BuildContext context,
    bool isDark, {
    _PackagingItem? item,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final typeController = TextEditingController(text: item?.type ?? '');
    final sizeController = TextEditingController(text: item?.size ?? '');
    final costController = TextEditingController(
      text: item?.cost.toStringAsFixed(2) ?? '',
    );
    String selectedMaterial = item?.material ?? 'Cardboard';
    String selectedStatus = item?.status ?? 'Active';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl,
          vertical: AppSpacing.xl,
        ),
        child: SizedBox(
          width: isMobile ? double.infinity : 480,
          child: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogHeader(
                  item == null ? 'Add Packaging' : 'Edit Packaging',
                  'Configure packaging material and cost',
                  Icons.inventory_2_rounded,
                  AppColors.primary,
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormLabel('Packaging Type', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(
                          controller: typeController,
                          hint: 'Box',
                          icon: Icons.inventory_2_outlined,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Size', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(
                          controller: sizeController,
                          hint: '500g',
                          icon: Icons.scale_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Material', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedMaterial,
                          items: const [
                            'Cardboard',
                            'Reusable Plastic',
                            'Biodegradable',
                            'Paper Band',
                          ],
                          icon: Icons.category_rounded,
                          isDark: isDark,
                          onChanged: (value) =>
                              setDialogState(() => selectedMaterial = value!),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildPriceInput('Cost (\$)', costController,
                            Icons.attach_money_rounded, isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Status', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                          value: selectedStatus,
                          items: const ['Active', 'Inactive'],
                          icon: Icons.verified_rounded,
                          isDark: isDark,
                          onChanged: (value) =>
                              setDialogState(() => selectedStatus = value!),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildDialogActions(
                  isDark,
                  primaryLabel: item == null ? 'Add Packaging' : 'Save Changes',
                  primaryColor: AppColors.primary,
                  onPrimary: () {
                    Navigator.pop(context);
                    _showSnack(item == null
                        ? 'Packaging added.'
                        : 'Packaging updated.');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeletePricingDialog(
    BuildContext context,
    _PricingItem item,
    bool isDark,
  ) {
    _showDeleteDialog(
      context,
      isDark,
      title: 'Delete Pricing?',
      message:
          'Delete ${item.plant} hub pricing from ${item.farm}? This removes the selling price to hub and bulk selling price to hub.',
      onDelete: () => _showSnack('Pricing deleted.'),
    );
  }

  void _showDeletePackagingDialog(
    BuildContext context,
    _PackagingItem item,
    bool isDark,
  ) {
    _showDeleteDialog(
      context,
      isDark,
      title: 'Delete Packaging?',
      message:
          'Delete ${item.type} packaging? Pricing records may be affected.',
      onDelete: () => _showSnack('Packaging deleted.'),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    bool isDark, {
    required String title,
    required String message,
    required VoidCallback onDelete,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.error,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color:
                              isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete();
                      },
                      icon: const Icon(Icons.delete_rounded, size: 18),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
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
  }

  Widget _buildDialogHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.82)],
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
              color: Colors.white.withValues(alpha: 0.2),
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
                  style:
                      AppTypography.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogActions(
    bool isDark, {
    required String primaryLabel,
    required Color primaryColor,
    required VoidCallback onPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.neutral50,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
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
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: onPrimary,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: Text(primaryLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h6.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white60 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  BoxDecoration _panelDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      border: Border.all(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.07),
      ),
    );
  }

  Widget _buildMetricLine(String label, String value, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallMetric(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white54 : AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceValue(String value, Color color, bool isDark) {
    return Text(
      value,
      style: AppTypography.bodyMedium.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildPill(String text, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildCountPill(String text, bool isDark) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildTableHeader(
    String label, {
    int flex = 1,
    required bool isDark,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? Colors.white54 : AppColors.textSecondary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildIconAction(
    IconData icon,
    Color color,
    VoidCallback onPressed,
    String tooltip,
  ) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: color,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildFormLabel(String label, bool isDark) => Text(
        label,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white38
              : AppColors.textSecondary.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white54 : AppColors.textSecondary,
          size: 20,
        ),
        filled: true,
        fillColor:
            isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.neutral50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : AppColors.neutral200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : AppColors.neutral200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required IconData icon,
    required bool isDark,
    required ValueChanged<String?> onChanged,
    Map<String, String>? labels,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.neutral200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 14,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(labels?[item] ?? item)),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}

class _PricingItem {
  const _PricingItem({
    required this.id,
    required this.farmId,
    required this.farm,
    required this.plant,
    required this.packaging,
    required this.hubSellingPrice,
    required this.hubBulkPrice,
    required this.status,
    required this.lastUpdated,
  });

  final String id;
  final String farmId;
  final String farm;
  final String plant;
  final String packaging;
  final double hubSellingPrice;
  final double hubBulkPrice;
  final String status;
  final String lastUpdated;
}

class _FarmPriceScope {
  const _FarmPriceScope({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.activePrices,
    required this.avgHubRate,
    required this.icon,
    required this.color,
    this.isGlobal = false,
  });

  final String id;
  final String name;
  final String subtitle;
  final String activePrices;
  final String avgHubRate;
  final IconData icon;
  final Color color;
  final bool isGlobal;
}

class _PackagingItem {
  const _PackagingItem({
    required this.id,
    required this.type,
    required this.size,
    required this.material,
    required this.cost,
    required this.status,
  });

  final String id;
  final String type;
  final String size;
  final String material;
  final double cost;
  final String status;
}
