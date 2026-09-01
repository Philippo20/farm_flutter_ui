import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Plant Type Management - Create and manage plant varieties with maturity duration
class PlantManagementScreen extends ConsumerStatefulWidget {
  const PlantManagementScreen({super.key});

  @override
  ConsumerState<PlantManagementScreen> createState() =>
      _PlantManagementScreenState();
}

class _PlantManagementScreenState extends ConsumerState<PlantManagementScreen> {
  int _selectedNavIndex = 4;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedCategoryFilter = 'All';
  bool _isLoadingPlants = false;
  String? _plantsError;
  final SuperAdminApiService _api = SuperAdminApiService();

  final List<String> _plantCategories = [
    'Leafy Greens',
    'Herbs',
    'Root Vegetables',
    'Fruits',
    'Vegetables',
    'Flowers',
  ];
  final Map<String, String> _categoryIds = {};

  @override
  void initState() {
    super.initState();
    _loadPlantTypes();
  }

  Future<void> _loadPlantTypes() async {
    setState(() {
      _isLoadingPlants = true;
      _plantsError = null;
      _plantTypes.clear();
    });

    try {
      final plants = await _api.getPlantTypes();
      if (!mounted) return;
      final mappedPlants = plants.map(_mapPlantDocument).toList();
      final categoryMarkers =
          mappedPlants.where((plant) => plant['isCategory'] == true).toList();
      final visiblePlants =
          mappedPlants.where((plant) => plant['isCategory'] != true).toList();
      final categories = mappedPlants
          .map((plant) => plant['category']?.toString() ?? '')
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      setState(() {
        _plantTypes
          ..clear()
          ..addAll(visiblePlants);
        _categoryIds
          ..clear()
          ..addEntries(categoryMarkers.map(
            (category) => MapEntry(
              category['category'].toString(),
              category['id'].toString(),
            ),
          ));
        if (categories.isNotEmpty) {
          _plantCategories
            ..clear()
            ..addAll(categories);
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _plantsError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoadingPlants = false);
      }
    }
  }

  Map<String, dynamic> _mapPlantDocument(Map<String, dynamic> doc) {
    return {
      'id': (doc[r'$id'] ?? doc['plant_type_id'] ?? doc['id'] ?? '').toString(),
      'name': (doc['name'] ?? 'Unnamed Plant').toString(),
      'category':
          (doc['category'] ?? doc['plant_type'] ?? 'Plant Types').toString(),
      'isCategory': doc['is_category'] == true,
      'maturityMin': doc['maturity_min_value'] ?? doc['months_to_maturity'] ?? doc['maturity'] ?? 0,
      'maturityMax': doc['maturity_max_value'] ?? doc['months_to_maturity'] ?? doc['maturity'] ?? 0,
      'maturity': doc['maturity_max_value'] ?? doc['months_to_maturity'] ?? doc['maturity'] ?? 0,
      'maturityUnit': (doc['maturity_unit'] ?? 'months').toString(),
      'imageUrl': (doc['image_url'] ?? '').toString(),
      'status': _statusLabel(doc['status']),
      'created': _dateLabel(doc[r'$createdAt'] ?? doc['created_at']),
    };
  }

  String _statusLabel(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return 'Active';
    return text
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _dateLabel(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.length >= 10) return text.substring(0, 10);
    return text.isEmpty ? '-' : text;
  }

  final List<Map<String, dynamic>> _plantTypes = [
    {
      'id': 'P001',
      'name': 'Lettuce - Romaine',
      'category': 'Leafy Greens',
      'maturity': 2,
      'maturityUnit': 'months',
      'status': 'Active',
      'created': '2024-01-15'
    },
    {
      'id': 'P002',
      'name': 'Tomato - Cherry',
      'category': 'Fruits',
      'maturity': 3,
      'maturityUnit': 'months',
      'status': 'Active',
      'created': '2024-01-20'
    },
    {
      'id': 'P003',
      'name': 'Basil - Sweet',
      'category': 'Herbs',
      'maturity': 1,
      'maturityUnit': 'months',
      'status': 'Active',
      'created': '2024-02-01'
    },
    {
      'id': 'P004',
      'name': 'Spinach - Baby',
      'category': 'Leafy Greens',
      'maturity': 1,
      'maturityUnit': 'months',
      'status': 'Active',
      'created': '2024-02-10'
    },
    {
      'id': 'P005',
      'name': 'Pepper - Bell',
      'category': 'Vegetables',
      'maturity': 4,
      'maturityUnit': 'months',
      'status': 'Active',
      'created': '2024-02-15'
    },
  ];

  List<Map<String, dynamic>> get _filteredPlantTypes {
    if (_selectedCategoryFilter == 'All') return _plantTypes;
    return _plantTypes
        .where((plant) => plant['category'] == _selectedCategoryFilter)
        .toList();
  }

  String _maturityLabel(Map<String, dynamic> plant) {
    final min = plant['maturityMin'] ?? plant['maturity'] ?? 0;
    final max = plant['maturityMax'] ?? plant['maturity'] ?? min;
    final unit = (plant['maturityUnit'] ?? 'months').toString();
    return '$min${min == max ? '' : '-$max'} $unit';
  }

  Future<bool> _savePlantType({
    required String name,
    required String category,
    required String maturityMin,
    required String maturityMax,
    required String maturityUnit,
    required String imageFileName,
    required String status,
  }) async {
    final min = int.tryParse(maturityMin.trim());
    final max = int.tryParse(maturityMax.trim());
    if (name.trim().isEmpty ||
        min == null ||
        max == null ||
        min <= 0 ||
        max < min ||
        imageFileName.trim().isEmpty) {
      return false;
    }

    setState(() {
      _isLoadingPlants = true;
      _plantsError = null;
    });

    try {
      await _api.createPlantType(
        name: name.trim(),
        category: category.trim(),
        maturityMinValue: min,
        maturityMaxValue: max,
        maturityUnit: maturityUnit,
        imageFileName: imageFileName.trim(),
        status: status,
      );
      await _loadPlantTypes();
      if (!mounted) return false;
      _showSuccessSnack('${name.trim()} added.');
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        _plantsError = error.toString();
        _isLoadingPlants = false;
      });
      _showErrorSnack(error.toString());
      return false;
    }
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
              selectedIndex: 4,
              onItemSelected: (_) {},
            )
          : null,
    );
  }

  Widget _buildDesktopLayout(
      bool isDark, String userName, String userEmail, String firstName) {
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
                onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
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
          onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
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
            fontWeight: FontWeight.w600,
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
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildCategoryFilters(isDark),
        const SizedBox(height: AppSpacing.md),
        ..._filteredPlantTypes
            .map((plant) => _buildMobilePlantCard(plant, isDark)),
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
                  Text('Plant Type Management',
                      style: AppTypography.h4.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : AppColors.textPrimary)),
                  Text(
                      'Create and manage plant varieties with maturity duration',
                      style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? Colors.white70
                              : AppColors.textSecondary)),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xl),

        // Stats Cards
        _buildStatsCards(isDark),

        const SizedBox(height: AppSpacing.xl),

        if (_plantsError != null) ...[
          _buildSyncStatus(isDark),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Plant Types Table
        if (_isLoadingPlants && _plantTypes.isEmpty)
          const AdminDataSkeleton(showStats: false)
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedCategoryFilter == 'All'
                            ? 'All Plant Types'
                            : '$_selectedCategoryFilter Plant Types',
                        style: AppTypography.h6.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${_filteredPlantTypes.length} records',
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildCategoryFilters(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildPlantTableHeader(isDark),
                const SizedBox(height: AppSpacing.sm),
                ..._filteredPlantTypes
                    .map((plant) => _buildPlantRow(plant, isDark)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSyncStatus(bool isDark) {
    final hasError = _plantsError != null;
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
              'Could not refresh plant types: $_plantsError',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh plant types',
            onPressed: _isLoadingPlants ? null : _loadPlantTypes,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(bool isDark) {
    final filters = ['All', ..._plantCategories];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: filters.map<Widget>((category) {
        final isSelected = _selectedCategoryFilter == category;
        final categoryId = _categoryIds[category];
        return InputChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _selectedCategoryFilter = category);
          },
          onDeleted: category == 'All' || categoryId == null
              ? null
              : () => _showDeleteCategoryDialog(
                    context,
                    category,
                    categoryId,
                    isDark,
                  ),
          deleteIcon: const Icon(Icons.close_rounded, size: 16),
          selectedColor: AppColors.success.withValues(alpha: 0.18),
          backgroundColor:
              isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
          side: BorderSide(
            color: isSelected
                ? AppColors.success
                : (isDark ? Colors.white12 : AppColors.neutral200),
          ),
          labelStyle: TextStyle(
            color: isSelected
                ? AppColors.success
                : (isDark ? Colors.white70 : AppColors.textSecondary),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        );
      }).toList()
        ..add(
          ActionChip(
            avatar: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Category'),
            onPressed: () => _showAddCategoryDialog(context, isDark),
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.neutral50,
            side: BorderSide(
              color: isDark ? Colors.white12 : AppColors.neutral200,
            ),
            labelStyle: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
    );
  }

  Widget _buildMobileStats(bool isDark) {
    final stats = _plantStats();
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
            color: statColor.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: statColor.withValues(alpha: 0.3)),
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
                        color: statColor.withValues(alpha: 0.9),
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
                  fontWeight: FontWeight.w500,
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

  List<Map<String, Object>> _plantStats() {
    final totalTypes = _plantTypes.length;
    final activeTypes =
        _plantTypes.where((plant) => plant['status'] == 'Active').length;
    final categories = _plantTypes
        .map((plant) => plant['category']?.toString() ?? '')
        .where((category) => category.isNotEmpty)
        .toSet()
        .length;
    final maturityValues = _plantTypes
        .map((plant) => plant['maturity'])
        .whereType<num>()
        .map((value) => value.toDouble())
        .toList();
    final avgMaturity = maturityValues.isEmpty
        ? 0
        : maturityValues.reduce((a, b) => a + b) / maturityValues.length;

    return [
      {
        'title': 'Total Types',
        'value': totalTypes.toString(),
        'icon': Icons.eco,
        'color': AppColors.success
      },
      {
        'title': 'Active',
        'value': activeTypes.toString(),
        'icon': Icons.check_circle,
        'color': AppColors.primary
      },
      {
        'title': 'Categories',
        'value': categories.toString(),
        'icon': Icons.category,
        'color': AppColors.info
      },
      {
        'title': 'Avg Maturity',
        'value': '${avgMaturity.toStringAsFixed(1)} mo',
        'icon': Icons.schedule,
        'color': AppColors.warning
      },
    ];
  }

  Widget _buildStatsCards(bool isDark) {
    final stats = _plantStats();

    return Row(
      children: stats
          .map((stat) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                      right: stat != stats.last ? AppSpacing.md : 0),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                        color: (stat['color'] as Color).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              (stat['color'] as Color).withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Icon(stat['icon'] as IconData,
                            color: stat['color'] as Color, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stat['value'] as String,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: stat['color'] as Color),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              stat['title'] as String,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: (stat['color'] as Color)
                                      .withValues(alpha: 0.8)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildMobilePlantCard(Map<String, dynamic> plant, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color:
                isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.local_florist,
                    color: AppColors.success, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
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
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  plant['status'],
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _buildInfoChip(
                _maturityLabel(plant),
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

  Widget _buildInfoChip(String text, IconData icon, bool isDark,
      {Color? color}) {
    final chipColor =
        color ?? (isDark ? Colors.white54 : AppColors.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
                fontSize: 10, color: chipColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantTableHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          _buildTableHeader('Plant Type', flex: 3, isDark: isDark),
          _buildTableHeader('Category', flex: 2, isDark: isDark),
          _buildTableHeader('Maturity', isDark: isDark),
          _buildTableHeader('Status', isDark: isDark),
          _buildTableHeader('Created', isDark: isDark),
          const SizedBox(width: 88),
        ],
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

  Widget _buildCategoryBadge(String category, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
        ),
        child: Text(
          category,
          style: const TextStyle(
            color: AppColors.info,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'Active' ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPlantRow(Map<String, dynamic> plant, bool isDark) {
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.local_florist,
                      color: AppColors.success, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plant['name'],
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary)),
                      Text(plant['id'],
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildCategoryBadge(plant['category'], isDark),
          ),
          Expanded(
            child: Text(
              _maturityLabel(plant),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(plant['status']),
            ),
          ),
          Expanded(
            child: Text(plant['created'],
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : AppColors.textSecondary)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  onPressed: () => _showEditPlantDialog(context, plant, isDark),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: AppColors.primary),
              IconButton(
                  onPressed: () => _showDeleteDialog(context, plant, isDark),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, bool isDark) {
    final categoryController = TextEditingController();
    final isMobile = MediaQuery.of(context).size.width < 600;
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
          child: Container(
            width: isMobile ? double.infinity : 420,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const Icon(
                        Icons.category_rounded,
                        color: AppColors.success,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Category',
                            style: AppTypography.h6.copyWith(
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Create a new plant type category',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? Colors.white60
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildFormLabel('Category Name', isDark),
                const SizedBox(height: AppSpacing.sm),
                _buildTextField(
                  controller: categoryController,
                  hint: 'e.g., Microgreens',
                  icon: Icons.label_outline_rounded,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: saving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                          side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : AppColors.neutral300),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: saving
                            ? null
                            : () async {
                                final category = categoryController.text.trim();
                                if (category.isEmpty) return;

                                final exists = _plantCategories.any(
                                  (item) =>
                                      item.toLowerCase() ==
                                      category.toLowerCase(),
                                );
                                if (exists) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '$category already exists as a category.'),
                                      backgroundColor: AppColors.warning,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() => saving = true);
                                try {
                                  await _api.createPlantCategory(
                                      name: category);
                                  await _loadPlantTypes();
                                  if (!context.mounted) return;
                                  setState(
                                      () => _selectedCategoryFilter = category);
                                  Navigator.pop(context);
                                  _showSuccessSnack(
                                      '$category category added.');
                                } catch (error) {
                                  if (!context.mounted) return;
                                  setDialogState(() => saving = false);
                                  _showErrorSnack(error.toString());
                                }
                              },
                        icon: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add_rounded, size: 18),
                        label: Text(saving ? 'Saving' : 'Add Category'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
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
    );
  }

  void _showDeleteCategoryDialog(
    BuildContext context,
    String category,
    String categoryId,
    bool isDark,
  ) {
    final hasPlants = _plantTypes.any((plant) => plant['category'] == category);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: const Text('Delete Category?'),
        content: Text(
          hasPlants
              ? '$category has plant types assigned to it. Move or edit those plant types before deleting the category.'
              : 'Delete $category from plant type categories?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: hasPlants
                ? null
                : () async {
                    try {
                      await _api.deletePlantCategory(categoryId);
                      await _loadPlantTypes();
                      if (!dialogContext.mounted) return;
                      if (_selectedCategoryFilter == category) {
                        setState(() => _selectedCategoryFilter = 'All');
                      }
                      Navigator.pop(dialogContext);
                      _showSuccessSnack('$category deleted.');
                    } catch (error) {
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      _showErrorSnack(error.toString());
                    }
                  },
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPlantDialog(BuildContext context, bool isDark) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final maturityMinController = TextEditingController();
    final maturityMaxController = TextEditingController();
    final imageController = TextEditingController();
    String selectedCategory =
        _plantCategories.isNotEmpty ? _plantCategories.first : 'Plant Types';
    String selectedStatus = 'Active';
    String selectedMaturityUnit = 'months';
    var saving = false;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl,
              vertical: AppSpacing.xl),
          child: Container(
            width: isMobile ? double.infinity : 480,
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.success,
                      AppColors.success.withValues(alpha: 0.8)
                    ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd)),
                        child: const Icon(Icons.eco,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Add Plant Type',
                                style: AppTypography.h6.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            Text('Register plant catalog details',
                                style: AppTypography.bodySmall
                                    .copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                // Form
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormLabel('Plant Name', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildTextField(
                              controller: nameController,
                              hint: 'e.g., Lettuce',
                              icon: Icons.eco,
                              isDark: isDark,
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return 'Add a plant name when ready.';
                                }
                                return null;
                              }),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Maturity Range', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildMaturityControls(
                            minController: maturityMinController,
                            maxController: maturityMaxController,
                            hint: 'Min',
                            value: selectedMaturityUnit,
                            isDark: isDark,
                            isMobile: isMobile,
                            onChanged: (v) => setDialogState(
                                () => selectedMaturityUnit = v ?? 'months'),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Image File Name', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildTextField(
                              controller: imageController,
                              hint: 'e.g., lettuce.jpg',
                              icon: Icons.image_outlined,
                              isDark: isDark,
                              validator: (value) {
                                if ((value ?? '').trim().isEmpty) {
                                  return 'Add an image file name if available.';
                                }
                                return null;
                              }),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Category', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildDropdownField(
                              value: selectedCategory,
                              items: _plantCategories.isEmpty
                                  ? ['Plant Types']
                                  : _plantCategories,
                              icon: Icons.category_outlined,
                              isDark: isDark,
                              onChanged: saving
                                  ? null
                                  : (v) => setDialogState(
                                      () => selectedCategory = v!)),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Status', isDark),
                          const SizedBox(height: AppSpacing.sm),
                          _buildDropdownField(
                              value: selectedStatus,
                              items: ['Active', 'Inactive'],
                              icon: Icons.toggle_on_outlined,
                              isDark: isDark,
                              onChanged: saving
                                  ? null
                                  : (v) => setDialogState(
                                      () => selectedStatus = v!)),
                        ],
                      ),
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : AppColors.neutral50,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(AppSpacing.radiusXl))),
                  child: Row(
                    children: [
                      Expanded(
                          child: OutlinedButton(
                              onPressed:
                                  saving ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md),
                                  side: BorderSide(
                                      color: isDark
                                          ? Colors.white24
                                          : AppColors.neutral300),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd))),
                              child: Text('Cancel',
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : AppColors.textSecondary)))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      if (!(formKey.currentState?.validate() ??
                                          false)) {
                                        return;
                                      }
                                      setDialogState(() => saving = true);
                                      final saved = await _savePlantType(
                                        name: nameController.text,
                                        category: selectedCategory,
                                        maturityMin:
                                            maturityMinController.text,
                                        maturityMax:
                                            maturityMaxController.text,
                                        maturityUnit: selectedMaturityUnit,
                                        imageFileName: imageController.text,
                                        status: selectedStatus,
                                      );
                                      if (!context.mounted) return;
                                      if (saved) {
                                        Navigator.pop(context);
                                      } else {
                                        setDialogState(() => saving = false);
                                      }
                                    },
                              icon: saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.add, size: 18),
                              label: Text(saving ? 'Saving' : 'Add Plant'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd))))),
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

  void _showEditPlantDialog(
      BuildContext context, Map<String, dynamic> plant, bool isDark) {
    final nameController = TextEditingController(text: plant['name']);
    final maturityMinController = TextEditingController(
        text: (plant['maturityMin'] ?? plant['maturity'] ?? 0).toString());
    final maturityMaxController = TextEditingController(
        text: (plant['maturityMax'] ?? plant['maturity'] ?? 0).toString());
    final imageFileName = (plant['imageUrl'] ?? '').toString();
    String selectedCategory = plant['category'];
    String selectedMaturityUnit =
        (plant['maturityUnit'] ?? 'months').toString();
    String selectedStatus = plant['status'];
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl,
              vertical: AppSpacing.xl),
          child: Container(
            width: isMobile ? double.infinity : 480,
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.success,
                      AppColors.success.withValues(alpha: 0.8)
                    ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd)),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 24)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('Edit Plant Type',
                                style: AppTypography.h6.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            Text('Update plant information',
                                style: AppTypography.bodySmall
                                    .copyWith(color: Colors.white70))
                          ])),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                // Preview
                Container(
                  margin: const EdgeInsets.all(AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppColors.neutral50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.08))),
                  child: Row(
                    children: [
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd)),
                          child: const Icon(Icons.eco,
                              color: AppColors.success, size: 24)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(plant['name'],
                                style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary)),
                            Text(
                                '${plant['category']} | ${_maturityLabel(plant)}',
                                style: AppTypography.bodySmall.copyWith(
                                    color: isDark
                                        ? Colors.white60
                                        : AppColors.textSecondary))
                          ])),
                    ],
                  ),
                ),
                // Form
                Flexible(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormLabel('Plant Name', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTextField(
                            controller: nameController,
                            hint: 'Plant name',
                            icon: Icons.eco,
                            isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Category', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                            value: selectedCategory,
                            items: _plantCategories,
                            icon: Icons.category,
                            isDark: isDark,
                            onChanged: (v) =>
                                setDialogState(() => selectedCategory = v!)),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Maturity Duration', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildMaturityControls(
                          minController: maturityMinController,
                          maxController: maturityMaxController,
                          hint: 'Duration',
                          value: selectedMaturityUnit,
                          isDark: isDark,
                          isMobile: isMobile,
                          onChanged: (v) =>
                              setDialogState(() => selectedMaturityUnit = v!),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Status', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildDropdownField(
                            value: selectedStatus,
                            items: ['Active', 'Inactive'],
                            icon: Icons.toggle_on_outlined,
                            isDark: isDark,
                            onChanged: (v) =>
                                setDialogState(() => selectedStatus = v!)),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : AppColors.neutral50,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(AppSpacing.radiusXl))),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showDeleteDialog(context, plant, isDark);
                          },
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                  horizontal: AppSpacing.md),
                              side: BorderSide(
                                  color:
                                      AppColors.error.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd)))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                          child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md),
                                  side: BorderSide(
                                      color: isDark
                                          ? Colors.white24
                                          : AppColors.neutral300),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd))),
                              child: Text('Cancel',
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : AppColors.textSecondary)))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                          child: ElevatedButton.icon(
                              onPressed: () async {
                                final plantName =
                                    nameController.text.trim().isEmpty
                                        ? plant['name']
                                        : nameController.text.trim();
                                final maturityMin = int.tryParse(
                                    maturityMinController.text.trim());
                                final maturityMax = int.tryParse(
                                    maturityMaxController.text.trim());
                                if (maturityMin == null ||
                                    maturityMax == null ||
                                    maturityMin <= 0 ||
                                    maturityMax < maturityMin) {
                                  setDialogState(() {});
                                  return;
                                }
                                try {
                                  await _api.updatePlantType(
                                    id: plant['id'].toString(),
                                    name: plantName,
                                    category: selectedCategory,
                                    maturityMinValue: maturityMin,
                                    maturityMaxValue: maturityMax,
                                    maturityUnit: selectedMaturityUnit,
                                    imageFileName: imageFileName,
                                    status: selectedStatus,
                                  );
                                  await _loadPlantTypes();
                                  if (!context.mounted) return;
                                  setState(() {
                                    _selectedCategoryFilter = selectedCategory;
                                  });
                                  Navigator.pop(context);
                                  _showSuccessSnack('$plantName updated.');
                                } catch (error) {
                                  if (!context.mounted) return;
                                  _showErrorSnack(error.toString());
                                }
                              },
                              icon: const Icon(Icons.save, size: 18),
                              label: const Text('Save'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd))))),
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

  void _showDeleteDialog(
      BuildContext context, Map<String, dynamic> plant, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Delete Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.delete_forever,
                    color: AppColors.error, size: 40),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Delete Plant Type?',
                  style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Text('Are you sure you want to delete "${plant['name']}"?',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                      color:
                          isDark ? Colors.white70 : AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              // Plant Preview Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm)),
                      child: const Icon(Icons.eco,
                          color: AppColors.success, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plant['name'],
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary)),
                          Text(
                              '${plant['category']} | ${_maturityLabel(plant)}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (plant['status'] == 'Active'
                                ? AppColors.success
                                : AppColors.warning)
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(plant['status'],
                          style: TextStyle(
                              color: plant['status'] == 'Active'
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Warning Banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: Text(
                            'This will also delete all associated pricing and batch data. This action cannot be undone.',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textSecondary))),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md),
                              side: BorderSide(
                                  color: isDark
                                      ? Colors.white24
                                      : AppColors.neutral300),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd))),
                          child: Text('Cancel',
                              style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textSecondary)))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                      child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Row(children: [
                                  const Icon(Icons.delete, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text('${plant['name']} deleted')
                                ]),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMd))));
                          },
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd))))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widgets
  Widget _buildFormLabel(String label, bool isDark) => Text(label,
      style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : AppColors.textPrimary));

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      required bool isDark,
      TextInputType keyboardType = TextInputType.text,
      FormFieldValidator<String>? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: isDark
                  ? Colors.white38
                  : AppColors.textSecondary.withValues(alpha: 0.5)),
          prefixIcon: Icon(icon,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
              size: 20),
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.neutral50,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                  color: isDark ? Colors.white12 : AppColors.neutral200)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                  color: isDark ? Colors.white12 : AppColors.neutral200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.success, width: 2)),
          errorStyle: TextStyle(
              color: AppColors.error.withValues(alpha: 0.9), fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md)),
      validator: validator,
    );
  }

  Widget _buildMaturityControls({
    required TextEditingController minController,
    required TextEditingController maxController,
    required String hint,
    required String value,
    required bool isDark,
    required bool isMobile,
    required ValueChanged<String?> onChanged,
  }) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: minController,
                  hint: 'Minimum',
                  icon: Icons.schedule,
                  isDark: isDark,
                  keyboardType: TextInputType.number,
                  validator: (value) => _rangeValueError(value),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildTextField(
                  controller: maxController,
                  hint: 'Maximum',
                  icon: Icons.event_available_outlined,
                  isDark: isDark,
                  keyboardType: TextInputType.number,
                  validator: (value) => _rangeValueError(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildCompactDropdownField(
            value: value,
            items: const ['weeks', 'months'],
            isDark: isDark,
            onChanged: onChanged,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: minController,
            hint: 'Minimum',
            icon: Icons.schedule,
            isDark: isDark,
            keyboardType: TextInputType.number,
            validator: (value) => _rangeValueError(value),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildTextField(
            controller: maxController,
            hint: 'Maximum',
            icon: Icons.event_available_outlined,
            isDark: isDark,
            keyboardType: TextInputType.number,
            validator: (value) {
              final error = _rangeValueError(value);
              if (error != null) return error;
              final min = int.tryParse(minController.text.trim());
              final max = int.tryParse(value?.trim() ?? '');
              return min != null && max != null && max < min
                  ? 'Must be >= min'
                  : null;
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 132,
          child: _buildCompactDropdownField(
            value: value,
            items: const ['weeks', 'months'],
            isDark: isDark,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  String? _rangeValueError(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    return number == null || number <= 0 ? 'Enter a positive number' : null;
  }

  Widget _buildCompactDropdownField({
    required String value,
    required List<String> items,
    required bool isDark,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
              color: isDark ? Colors.white12 : AppColors.neutral200)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down,
              color: isDark ? Colors.white54 : AppColors.textSecondary),
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 14),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDropdownField(
      {required String value,
      required List<String> items,
      required IconData icon,
      required bool isDark,
      required ValueChanged<String?>? onChanged,
      Map<String, String>? labels}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
              color: isDark ? Colors.white12 : AppColors.neutral200)),
      child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down,
                  color: isDark ? Colors.white54 : AppColors.textSecondary),
              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
              style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 14),
              items: items
                  .map((item) => DropdownMenuItem(
                      value: item,
                      child: Row(children: [
                        Icon(icon,
                            color: isDark
                                ? Colors.white54
                                : AppColors.textSecondary,
                            size: 20),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            labels?[item] ?? item,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ])))
                  .toList(),
              onChanged: onChanged)),
    );
  }

  void _showSuccessSnack(String message) {
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
