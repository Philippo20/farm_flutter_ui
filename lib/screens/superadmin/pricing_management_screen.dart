import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

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
  int _selectedNavIndex = 6;
  String _selectedTab = 'purchase';
  String _selectedFarm = 'all';
  bool _isLoadingPricing = false;
  String? _pricingError;
  final SuperAdminApiService _api = SuperAdminApiService();

  final List<_FarmPriceScope> _farms = [
    const _FarmPriceScope(
      id: 'all',
      name: 'Hub Pricing',
      subtitle: 'All prices sold into the hub',
      activePrices: '0',
      avgHubRate: 'GHS 0.00',
      icon: Icons.public_rounded,
      color: AppColors.primary,
      isGlobal: true,
    ),
  ];

  final List<_PricingItem> _pricingData = [];

  final List<_PackagingItem> _packagingData = [];
  final List<String> _plantTypeData = [];
  final List<Map<String, String>> _cropVarietyData = [];

  List<_PricingItem> get _visiblePrices {
    final typed = _pricingData
        .where((item) =>
            item.pricingType ==
            (_selectedTab == 'sale' ? 'hub_sale' : 'hub_purchase'))
        .toList();
    if (_selectedTab == 'sale' || _selectedFarm == 'all') return typed;
    return typed.where((item) => item.farmId == _selectedFarm).toList();
  }

  List<String> get _plantOptions => _uniqueOptions(
        [
          ..._plantTypeData,
          ..._pricingData.map((item) => item.plant),
        ],
        fallback: 'Plant Type',
      );

  List<String> get _packagingOptions => _uniqueOptions(
        [
          ..._pricingData.map((item) => item.packaging),
          ..._packagingData.map((item) => '${item.type} - ${item.size}'),
        ],
        fallback: 'Package',
      );

  List<String> _cropVarietyOptionsForPlant(String plantType) {
    final active = _cropVarietyData
        .where((item) => (item['variety'] ?? '').trim().isNotEmpty)
        .toList();
    final matched = active
        .where((item) => _catalogNamesMatch(item['plantType'] ?? '', plantType))
        .map((item) => item['variety'] ?? '')
        .toList();
    return _uniqueOptions(
      matched.isEmpty ? active.map((item) => item['variety'] ?? '') : matched,
      fallback: 'Crop Variety',
    );
  }

  List<String> _uniqueOptions(
    Iterable<String> values, {
    required String fallback,
  }) {
    final seen = <String>{};
    final options = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || !seen.add(trimmed)) continue;
      options.add(trimmed);
    }
    return options.isEmpty ? [fallback] : options;
  }

  bool _catalogNamesMatch(String cropName, String plantType) {
    final cropKey = _catalogKey(cropName);
    final plantKey = _catalogKey(plantType);
    if (cropKey.isEmpty || plantKey.isEmpty) return false;
    return cropKey == plantKey ||
        cropKey.contains(plantKey) ||
        plantKey.contains(cropKey);
  }

  String _catalogKey(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '').trim();
  }

  @override
  void initState() {
    super.initState();
    _loadPricingData();
  }

  Future<void> _loadPricingData() async {
    setState(() {
      _isLoadingPricing = true;
      _pricingError = null;
      _pricingData.clear();
      _packagingData.clear();
      _plantTypeData.clear();
      _cropVarietyData.clear();
    });

    try {
      final results = await Future.wait([
        _api.getPricing(),
        _api.getPackages(),
        _api.getFarms(),
        _api.getPlantTypes(),
        _api.getCrops(),
      ]);
      if (!mounted) return;
      final pricing = results[0].map(_mapPricingDocument).toList();
      final packaging = results[1].map(_mapPackagingDocument).toList();
      final farms = _buildFarmScopesFromDocuments(results[2], pricing);
      final plantTypes = results[3]
          .where((doc) => doc['is_category'] != true)
          .map((doc) => (doc['name'] ?? '').toString())
          .where((name) => name.trim().isNotEmpty)
          .toList();
      final cropVarieties = results[4]
          .map((doc) => {
                'plantType': (doc['crop_name'] ?? '').toString(),
                'variety': (doc['variety_name'] ?? '').toString(),
              })
          .where((doc) => doc['variety']!.trim().isNotEmpty)
          .toList();
      setState(() {
        _pricingData
          ..clear()
          ..addAll(pricing);
        _packagingData
          ..clear()
          ..addAll(packaging);
        _plantTypeData
          ..clear()
          ..addAll(plantTypes);
        _cropVarietyData
          ..clear()
          ..addAll(cropVarieties);
        _farms
          ..clear()
          ..addAll(farms);
        if (!_farms.any((farm) => farm.id == _selectedFarm)) {
          _selectedFarm = 'all';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _pricingError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoadingPricing = false);
      }
    }
  }

  _PricingItem _mapPricingDocument(Map<String, dynamic> doc) {
    final farmId = (doc['farm_id'] ?? 'all').toString();
    final farmName = (doc['farm_name'] ?? '').toString().trim();
    final packaging = (doc['packaging'] ?? '').toString();
    final pricingType = (doc['pricing_type'] ??
            (farmId == 'all' && packaging != 'Raw / Unpackaged'
                ? 'hub_sale'
                : 'hub_purchase'))
        .toString();
    return _PricingItem(
      id: (doc[r'$id'] ?? doc['pricing_id'] ?? doc['id'] ?? '').toString(),
      farmId: farmId.isEmpty ? 'all' : farmId,
      farm: farmName.isEmpty
          ? (pricingType == 'hub_sale' ? 'Hub Sales' : 'Hub Pricing')
          : farmName,
      pricingType: pricingType,
      plant: (doc['plant_type'] ?? 'Plant Type').toString(),
      cropVariety: (doc['crop_variety'] ?? '').toString(),
      packaging: packaging.isEmpty ? 'Raw / Unpackaged' : packaging,
      unit: (doc['unit'] ?? 'kg').toString(),
      hubSellingPrice: _toDouble(doc['regular_price']),
      hubBulkPrice: _toDouble(doc['bulk_price']),
      status: _labelFromSnakeCase((doc['status'] ?? 'Active').toString()),
      lastUpdated: _dateLabel(doc[r'$updatedAt'] ?? doc[r'$createdAt']),
    );
  }

  List<_FarmPriceScope> _buildFarmScopesFromDocuments(
    List<Map<String, dynamic>> farmDocs,
    List<_PricingItem> prices,
  ) {
    final purchasePrices =
        prices.where((price) => price.pricingType == 'hub_purchase').toList();
    final scopes = <_FarmPriceScope>[
      _FarmPriceScope(
        id: 'all',
        name: 'Hub Pricing',
        subtitle: 'Raw produce bought from spoke farms',
        activePrices: purchasePrices.length.toString(),
        avgHubRate: _money(_averageRate(purchasePrices)),
        icon: Icons.public_rounded,
        color: AppColors.primary,
        isGlobal: true,
      ),
    ];

    final knownFarmIds = <String>{'all'};
    final palette = <Color>[
      AppColors.success,
      AppColors.info,
      AppColors.warning,
      AppColors.secondary,
    ];

    for (var index = 0; index < farmDocs.length; index++) {
      final doc = farmDocs[index];
      final id = (doc[r'$id'] ?? doc['farm_id'] ?? doc['id'] ?? '').toString();
      if (id.isEmpty || knownFarmIds.contains(id)) continue;

      final name = (doc['name'] ?? 'Spoke Farm').toString();
      final location = (doc['location'] ?? '').toString();
      final plantType = (doc['plant_type'] ?? '').toString();
      final tier = (doc['tier_type'] ?? doc['tierType'] ?? '').toString();
      final farmPrices =
          purchasePrices.where((price) => price.farmId == id).toList();
      scopes.add(
        _FarmPriceScope(
          id: id,
          name: name,
          subtitle: _joinParts([location, plantType, tier], fallback: 'Farm'),
          activePrices: farmPrices.length.toString(),
          avgHubRate: _money(_averageRate(farmPrices)),
          icon: Icons.agriculture_rounded,
          color: palette[(index) % palette.length],
        ),
      );
      knownFarmIds.add(id);
    }

    for (final price in purchasePrices) {
      if (knownFarmIds.contains(price.farmId)) continue;
      final farmPrices =
          purchasePrices.where((item) => item.farmId == price.farmId).toList();
      scopes.add(
        _FarmPriceScope(
          id: price.farmId,
          name: price.farm,
          subtitle: 'Pricing record farm scope',
          activePrices: farmPrices.length.toString(),
          avgHubRate: _money(_averageRate(farmPrices)),
          icon: Icons.agriculture_rounded,
          color: palette[scopes.length % palette.length],
        ),
      );
      knownFarmIds.add(price.farmId);
    }

    return scopes;
  }

  double _averageRate(List<_PricingItem> prices) {
    if (prices.isEmpty) return 0;
    final total = prices.fold<double>(
      0,
      (sum, item) => sum + item.hubSellingPrice,
    );
    return total / prices.length;
  }

  String _joinParts(List<String> parts, {required String fallback}) {
    final cleaned = parts
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return cleaned.isEmpty ? fallback : cleaned.join(' | ');
  }

  _PackagingItem _mapPackagingDocument(Map<String, dynamic> doc) {
    final weight = doc['weight_capacity'] ?? '';
    final unit = doc['unit'] ?? '';
    return _PackagingItem(
      id: (doc[r'$id'] ?? doc['package_id'] ?? doc['id'] ?? '').toString(),
      type: (doc['package_name'] ?? 'Package').toString(),
      size: '$weight$unit',
      material: (doc['material_used'] ?? '-').toString(),
      cost: _toDouble(doc['cost_per_unit']),
      status: _labelFromSnakeCase((doc['status'] ?? 'Active').toString()),
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _labelFromSnakeCase(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _dateLabel(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.length >= 16) return text.substring(0, 16).replaceFirst('T', ' ');
    return text.isEmpty ? '-' : text;
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
      bottomNavigationBar: isMobile
          ? SuperAdminMobileBottomNav(
              selectedIndex: 6,
              onItemSelected: (_) {},
            )
          : null,
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
          selectedIndex: 6,
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
        if (_pricingError != null) ...[
          _buildSyncStatus(isDark),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (_isLoadingPricing && _pricingData.isEmpty && _packagingData.isEmpty)
          const AdminDataSkeleton()
        else ...[
          _buildTabs(isDark),
          const SizedBox(height: AppSpacing.lg),
          if (_selectedTab == 'purchase') ...[
            _buildFarmScopes(isDark, isMobile),
            const SizedBox(height: AppSpacing.lg),
            _buildPricingPanel(isDark, isMobile),
          ] else if (_selectedTab == 'sale')
            _buildPricingPanel(isDark, isMobile)
          else
            _buildPackagingPanel(isDark, isMobile),
        ],
      ],
    );
  }

  Widget _buildSyncStatus(bool isDark) {
    final hasError = _pricingError != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hasError
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Could not refresh pricing data: $_pricingError',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh pricing',
            onPressed: _isLoadingPricing ? null : _loadPricingData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
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
                  fontWeight: FontWeight.w500,
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
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Manage raw prices the hub pays spoke farms, then packaged prices the hub sells to offtakers.',
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
              _selectedTab == 'sale'
                  ? 'Avg selling price'
                  : 'Avg raw buying price',
              _money(averageHubSelling),
              isDark),
          const SizedBox(height: 10),
          _buildMetricLine(
              _selectedTab == 'sale'
                  ? 'Avg bulk selling price'
                  : 'Avg bulk raw buying price',
              _money(averageHubBulk),
              isDark),
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
          label: Text(_selectedTab == 'sale'
              ? 'Add Hub Sale Price'
              : 'Add Raw Purchase Price'),
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
        _buildTab(
            'Hub Purchase', 'purchase', Icons.agriculture_rounded, isDark),
        _buildTab('Hub Sales', 'sale', Icons.storefront_rounded, isDark),
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
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
                fontWeight: FontWeight.w500,
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
    final isSale = _selectedTab == 'sale';
    final scopeName = isSale
        ? 'Packaged products sold to offtakers'
        : _farms
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
                    _buildSectionHeader(
                      isSale
                          ? 'Hub Sales Price Book'
                          : 'Raw Purchase Price Book',
                      scopeName,
                      isDark,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildCountPill('${prices.length} prices', isDark),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                        child: _buildSectionHeader(
                            isSale
                                ? 'Hub Sales Price Book'
                                : 'Raw Purchase Price Book',
                            scopeName,
                            isDark)),
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
    final isSale = _selectedTab == 'sale';
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
              _buildTableHeader('Crop', flex: 3, isDark: isDark),
              _buildTableHeader(isSale ? 'Package' : 'Spoke Farm',
                  flex: 2, isDark: isDark),
              _buildTableHeader(isSale ? 'Sell To Offtaker' : 'Hub Buys Raw',
                  isDark: isDark),
              _buildTableHeader(isSale ? 'Bulk Sale' : 'Bulk Raw Buy',
                  isDark: isDark),
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
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _priceSubtitle(price),
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
              price.pricingType == 'hub_sale' ? price.packaging : price.farm,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
              child: _buildPriceValue(
                  '${_money(price.hubSellingPrice)}/${price.unit}',
                  AppColors.success,
                  isDark)),
          Expanded(
              child: _buildPriceValue(
                  '${_money(price.hubBulkPrice)}/${price.unit}',
                  AppColors.warning,
                  isDark)),
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _priceSubtitle(price),
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
                      price.pricingType == 'hub_sale'
                          ? 'Sell To Offtaker'
                          : 'Hub Buys Raw',
                      '${_money(price.hubSellingPrice)}/${price.unit}',
                      isDark)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _buildSmallMetric(
                      price.pricingType == 'hub_sale'
                          ? 'Bulk Sale'
                          : 'Bulk Raw Buy',
                      '${_money(price.hubBulkPrice)}/${price.unit}',
                      isDark)),
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
                  '${price.id} | ${price.lastUpdated}',
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${item.size} | ${item.material}',
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

  List<String> _ensureOption(List<String> options, String? value) {
    final normalized = value?.trim();
    if (normalized == null ||
        normalized.isEmpty ||
        options.contains(normalized)) {
      return options;
    }
    return [normalized, ...options];
  }

  Future<bool> _savePricing({
    required _PricingItem? item,
    required String pricingType,
    required String farmId,
    required String plant,
    required String cropVariety,
    required String packaging,
    required String unit,
    required String hubSellingPriceText,
    required String hubBulkPriceText,
    required String status,
  }) async {
    final hubSellingPrice = double.tryParse(hubSellingPriceText.trim());
    final hubBulkPrice = double.tryParse(hubBulkPriceText.trim());
    if (hubSellingPrice == null || hubBulkPrice == null) {
      return false;
    }

    final farm = pricingType == 'hub_sale'
        ? const _FarmPriceScope(
            id: 'all',
            name: 'Hub Sales',
            subtitle: 'Packaged products sold to offtakers',
            activePrices: '0',
            avgHubRate: 'GHS 0.00',
            icon: Icons.storefront_rounded,
            color: AppColors.primary,
            isGlobal: true,
          )
        : _farms.firstWhere(
            (scope) => scope.id == farmId && !scope.isGlobal,
            orElse: () => _farms.firstWhere(
              (scope) => !scope.isGlobal,
              orElse: () => _farms.first,
            ),
          );
    final normalizedPackaging =
        pricingType == 'hub_purchase' ? 'Raw / Unpackaged' : packaging;

    setState(() {
      _isLoadingPricing = true;
      _pricingError = null;
    });

    try {
      if (item == null) {
        await _api.createPricing(
          pricingType: pricingType,
          farmId: farm.id,
          farmName: farm.name,
          plantType: plant,
          cropVariety: cropVariety,
          packaging: normalizedPackaging,
          unit: unit,
          regularPrice: hubSellingPrice,
          bulkPrice: hubBulkPrice,
          status: status,
        );
      } else {
        await _api.updatePricing(
          id: item.id,
          pricingType: pricingType,
          farmId: farm.id,
          farmName: farm.name,
          plantType: plant,
          cropVariety: cropVariety,
          packaging: normalizedPackaging,
          unit: unit,
          regularPrice: hubSellingPrice,
          bulkPrice: hubBulkPrice,
          status: status,
        );
      }
      await _loadPricingData();
      if (!mounted) return false;
      _showSnack(
        item == null
            ? (pricingType == 'hub_sale'
                ? 'Hub sale pricing added.'
                : 'Raw purchase pricing added.')
            : (pricingType == 'hub_sale'
                ? 'Hub sale pricing updated.'
                : 'Raw purchase pricing updated.'),
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        _pricingError = error.toString();
        _isLoadingPricing = false;
      });
      _showErrorSnack(error.toString());
      return false;
    }
  }

  void _showPricingDialog(
    BuildContext context,
    bool isDark, {
    _PricingItem? item,
  }) {
    final formKey = GlobalKey<FormState>();
    final isMobile = MediaQuery.of(context).size.width < 600;
    final hubSellingController = TextEditingController(
      text: item?.hubSellingPrice.toStringAsFixed(2) ?? '',
    );
    final hubBulkController = TextEditingController(
      text: item?.hubBulkPrice.toStringAsFixed(2) ?? '',
    );
    final pricingType = item?.pricingType ??
        (_selectedTab == 'sale' ? 'hub_sale' : 'hub_purchase');
    final isSalePricing = pricingType == 'hub_sale';
    final farmOptions = _farms.where((farm) => !farm.isGlobal).toList();
    final dropdownFarmOptions = farmOptions.isEmpty ? _farms : farmOptions;
    final plantOptions = _ensureOption(_plantOptions, item?.plant);
    final initialPlant = item?.plant ?? plantOptions.first;
    final initialVarietyOptions = _ensureOption(
      _cropVarietyOptionsForPlant(initialPlant),
      item?.cropVariety,
    );
    final packagingOptions = _ensureOption(_packagingOptions, item?.packaging);
    String selectedFarm = item?.farmId ??
        (dropdownFarmOptions.isNotEmpty ? dropdownFarmOptions.first.id : 'all');
    if (!dropdownFarmOptions.any((farm) => farm.id == selectedFarm)) {
      selectedFarm =
          dropdownFarmOptions.isNotEmpty ? dropdownFarmOptions.first.id : 'all';
    }
    String selectedPlant = initialPlant;
    String selectedCropVariety = item?.cropVariety.trim().isNotEmpty == true
        ? item!.cropVariety
        : initialVarietyOptions.first;
    String selectedPackaging = item?.packaging ?? packagingOptions.first;
    String selectedUnit = item?.unit ?? 'kg';
    String selectedStatus = item?.status ?? 'Active';
    var saving = false;

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
                  item == null
                      ? (isSalePricing
                          ? 'Add Hub Sale Price'
                          : 'Add Raw Purchase Price')
                      : (isSalePricing
                          ? 'Edit Hub Sale Price'
                          : 'Edit Raw Purchase Price'),
                  isSalePricing
                      ? 'Set packaged prices the Hub sells to offtakers'
                      : 'Set raw crop prices the Hub pays spoke farms',
                  isSalePricing
                      ? Icons.storefront_rounded
                      : Icons.agriculture_rounded,
                  isSalePricing ? AppColors.primary : AppColors.warning,
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isSalePricing) ...[
                            _buildFormLabel('Spoke Farm', isDark),
                            const SizedBox(height: AppSpacing.sm),
                            _buildDropdownField(
                              value: selectedFarm,
                              items: dropdownFarmOptions
                                  .where((farm) => !farm.isGlobal)
                                  .map((farm) => farm.id)
                                  .toList(),
                              labels: {
                                for (final farm in _farms) farm.id: farm.name,
                              },
                              icon: Icons.agriculture_rounded,
                              isDark: isDark,
                              onChanged: saving
                                  ? null
                                  : (value) => setDialogState(
                                      () => selectedFarm = value!),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          _buildFormLabel('Plant Type', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildDropdownField(
                            value: selectedPlant,
                            items: plantOptions,
                            icon: Icons.eco_rounded,
                            isDark: isDark,
                            onChanged: saving
                                ? null
                                : (value) => setDialogState(() {
                                      selectedPlant = value!;
                                      selectedCropVariety =
                                          _cropVarietyOptionsForPlant(
                                                  selectedPlant)
                                              .first;
                                    }),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Crop Variety', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildDropdownField(
                            value: selectedCropVariety,
                            items: _ensureOption(
                              _cropVarietyOptionsForPlant(selectedPlant),
                              selectedCropVariety,
                            ),
                            icon: Icons.grass_rounded,
                            isDark: isDark,
                            onChanged: saving
                                ? null
                                : (value) => setDialogState(
                                    () => selectedCropVariety = value!),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (isSalePricing) ...[
                            _buildFormLabel('Packaging', isDark),
                            const SizedBox(height: AppSpacing.sm),
                            _buildDropdownField(
                              value: selectedPackaging,
                              items: packagingOptions,
                              icon: Icons.inventory_2_rounded,
                              isDark: isDark,
                              onChanged: saving
                                  ? null
                                  : (value) => setDialogState(
                                      () => selectedPackaging = value!),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          _buildFormLabel('Unit', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildDropdownField(
                            value: selectedUnit,
                            items: const ['kg', 'g', 'crate', 'box', 'bunch'],
                            icon: Icons.scale_rounded,
                            isDark: isDark,
                            onChanged: saving
                                ? null
                                : (value) =>
                                    setDialogState(() => selectedUnit = value!),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (isMobile)
                            Column(
                              children: [
                                _buildPriceInput(
                                    isSalePricing
                                        ? 'Selling Price To Offtaker (GHS)'
                                        : 'Raw Buying Price From Farm (GHS)',
                                    hubSellingController,
                                    Icons.sell_rounded,
                                    isDark,
                                    validator: _priceValidator),
                                const SizedBox(height: AppSpacing.lg),
                                _buildPriceInput(
                                    isSalePricing
                                        ? 'Bulk Selling Price To Offtaker (GHS)'
                                        : 'Bulk Raw Buying Price From Farm (GHS)',
                                    hubBulkController,
                                    Icons.local_offer_rounded,
                                    isDark,
                                    validator: _priceValidator),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                    child: _buildPriceInput(
                                        isSalePricing
                                            ? 'Selling Price To Offtaker (GHS)'
                                            : 'Raw Buying Price From Farm (GHS)',
                                        hubSellingController,
                                        Icons.sell_rounded,
                                        isDark,
                                        validator: _priceValidator)),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                    child: _buildPriceInput(
                                        isSalePricing
                                            ? 'Bulk Selling Price To Offtaker (GHS)'
                                            : 'Bulk Raw Buying Price From Farm (GHS)',
                                        hubBulkController,
                                        Icons.local_offer_rounded,
                                        isDark,
                                        validator: _priceValidator)),
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
                            onChanged: saving
                                ? null
                                : (value) => setDialogState(
                                    () => selectedStatus = value!),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildDialogActions(
                  isDark,
                  primaryLabel: item == null ? 'Add Pricing' : 'Save Changes',
                  primaryColor:
                      isSalePricing ? AppColors.primary : AppColors.warning,
                  isSaving: saving,
                  onPrimary: () async {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    setDialogState(() => saving = true);
                    final saved = await _savePricing(
                      item: item,
                      pricingType: pricingType,
                      farmId: selectedFarm,
                      plant: selectedPlant,
                      cropVariety: selectedCropVariety,
                      packaging: selectedPackaging,
                      unit: selectedUnit,
                      hubSellingPriceText: hubSellingController.text,
                      hubBulkPriceText: hubBulkController.text,
                      status: selectedStatus,
                    );
                    if (!context.mounted) return;
                    if (saved) {
                      Navigator.pop(context);
                    } else {
                      setDialogState(() => saving = false);
                    }
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
    bool isDark, {
    FormFieldValidator<String>? validator,
  }) {
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
          validator: validator,
        ),
      ],
    );
  }

  String? _priceValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Add a price when ready.';
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 0) return 'Use a valid amount.';
    return null;
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
                        _buildPriceInput('Cost (GHS)', costController,
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
      message: item.pricingType == 'hub_sale'
          ? 'Delete ${item.plant} packaged sale pricing for ${item.packaging}?'
          : 'Delete ${item.plant} raw purchase pricing from ${item.farm}?',
      onDelete: () => _deletePricing(item),
    );
  }

  Future<void> _deletePricing(_PricingItem item) async {
    setState(() {
      _isLoadingPricing = true;
      _pricingError = null;
    });
    try {
      await _api.deletePricing(item.id);
      await _loadPricingData();
      if (!mounted) return;
      _showSnack('Pricing deleted.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pricingError = error.toString();
        _isLoadingPricing = false;
      });
      _showErrorSnack(error.toString());
    }
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
                  fontWeight: FontWeight.w500,
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
                    fontWeight: FontWeight.w500,
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
    required FutureOr<void> Function() onPrimary,
    bool isSaving = false,
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
              onPressed: isSaving ? null : () => Navigator.pop(context),
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
              onPressed: isSaving ? null : () => onPrimary(),
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(isSaving ? 'Saving...' : primaryLabel),
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
            fontWeight: FontWeight.w500,
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
            fontWeight: FontWeight.w500,
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
              fontWeight: FontWeight.w500,
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
        fontWeight: FontWeight.w500,
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
            fontWeight: FontWeight.w500,
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
          fontWeight: FontWeight.w500,
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
          fontWeight: FontWeight.w500,
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
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
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
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required IconData icon,
    required bool isDark,
    required ValueChanged<String?>? onChanged,
    Map<String, String>? labels,
  }) {
    final normalizedItems = _uniqueOptions(items, fallback: value);
    final normalizedValue =
        normalizedItems.contains(value) ? value : normalizedItems.first;
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
          value: normalizedValue,
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
          items: normalizedItems
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

  String _money(double value) => 'GHS ${value.toStringAsFixed(2)}';

  String _priceSubtitle(_PricingItem price) {
    final variety = price.cropVariety.trim().isEmpty
        ? ''
        : ' | ${price.cropVariety.trim()}';
    if (price.pricingType == 'hub_sale') {
      return '${price.packaging}$variety';
    }
    return '${price.farm}$variety | Raw';
  }

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

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
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
    required this.pricingType,
    required this.plant,
    required this.cropVariety,
    required this.packaging,
    required this.unit,
    required this.hubSellingPrice,
    required this.hubBulkPrice,
    required this.status,
    required this.lastUpdated,
  });

  final String id;
  final String farmId;
  final String farm;
  final String pricingType;
  final String plant;
  final String cropVariety;
  final String packaging;
  final String unit;
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
