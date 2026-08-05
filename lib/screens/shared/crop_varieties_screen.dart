import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

class CropVarietiesScreen extends ConsumerStatefulWidget {
  const CropVarietiesScreen({required this.isSuperAdmin, super.key});

  final bool isSuperAdmin;

  @override
  ConsumerState<CropVarietiesScreen> createState() =>
      _CropVarietiesScreenState();
}

class _CropVarietiesScreenState extends ConsumerState<CropVarietiesScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _api = SuperAdminApiService();
  final List<Map<String, dynamic>> _crops = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool? _showCards;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    setState(() {
      _isLoading = true;
      _error = null;
      if (_crops.isEmpty) _crops.clear();
    });
    try {
      final documents = await _api.getCrops();
      if (!mounted) return;
      setState(() {
        _crops
          ..clear()
          ..addAll(documents.map(_mapCrop));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _mapCrop(Map<String, dynamic> doc) {
    return {
      'id': (doc[r'$id'] ?? doc['id'] ?? '').toString(),
      'crop': (doc['crop_name'] ?? 'Unnamed Crop').toString(),
      'imageName': (doc['crop_image'] ?? '').toString(),
      'imageFileId': (doc['crop_image_file_id'] ?? '').toString(),
      'image': (doc['crop_image_url'] ??
              doc['image_url'] ??
              doc['crop_image_download_url'] ??
              doc['crop_image'] ??
              '')
          .toString(),
      'variety': (doc['variety_name'] ?? 'Unspecified').toString(),
      'duration': (doc['plant_duration'] ?? '-').toString(),
      'company': (doc['company'] ?? '-').toString(),
      'harvestWeightValue': _rawNumber(doc['harvesting_weight']),
      'sproutingRatioValue': _rawNumber(doc['sprouting_ratio']),
      'ecMinValue': _rawNumber(doc['ec_level_min']),
      'ecMaxValue': _rawNumber(doc['ec_level_max']),
      'phMinValue': _rawNumber(doc['ph_level_min']),
      'phMaxValue': _rawNumber(doc['ph_level_max']),
      'tempMinValue': _rawNumber(doc['temp_min']),
      'tempMaxValue': _rawNumber(doc['temp_max']),
      'humidityMinValue': _rawNumber(doc['humidity_min']),
      'humidityMaxValue': _rawNumber(doc['humidity_max']),
      'harvestWeight': _number(doc['harvesting_weight']),
      'sproutingRatio': _number(doc['sprouting_ratio']),
      'ec': _range(doc['ec_level_min'], doc['ec_level_max']),
      'ph': _range(doc['ph_level_min'], doc['ph_level_max']),
      'temperature': _range(doc['temp_min'], doc['temp_max']),
      'humidity': _range(doc['humidity_min'], doc['humidity_max']),
    };
  }

  String _number(dynamic value) {
    if (value is num) return value.toStringAsFixed(1);
    return value?.toString() ?? '-';
  }

  String _rawNumber(dynamic value) {
    if (value is num) return value.toString();
    return value?.toString() ?? '';
  }

  String _range(dynamic minimum, dynamic maximum) {
    return '${_number(minimum)} - ${_number(maximum)}';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;
    final userName =
        user?.name ?? (widget.isSuperAdmin ? 'Super Admin' : 'Admin');
    final userEmail = user?.email ?? '';

    final navigation = widget.isSuperAdmin
        ? SuperAdminSidebar(
            selectedIndex: 3,
            onItemSelected: (_) {},
            userName: userName,
            userEmail: userEmail,
            userRole: 'Super Administrator',
          )
        : ModernAdminSidebar(
            selectedIndex: 8,
            onItemSelected: (_) {},
            userName: userName,
            userEmail: userEmail,
            userRole: 'Administrator',
          );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? Drawer(
              child: widget.isSuperAdmin
                  ? SuperAdminDrawer(
                      selectedIndex: 3,
                      onItemSelected: (_) {},
                      userName: userName,
                      userEmail: userEmail,
                      userRole: 'Super Administrator',
                    )
                  : AdminDrawer(
                      selectedIndex: 8,
                      onItemSelected: (_) {},
                      userName: userName,
                      userEmail: userEmail,
                      userRole: 'Administrator',
                    ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) navigation,
          Expanded(
            child: Column(
              children: [
                ModernAdminHeader(
                  userName: userName.split(' ').first,
                  onMenuTap: isMobile
                      ? () => _scaffoldKey.currentState?.openDrawer()
                      : null,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      isMobile ? AppSpacing.md : AppSpacing.xl,
                    ),
                    child: _buildContent(isDark, isMobile),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? widget.isSuperAdmin
              ? SuperAdminMobileBottomNav(
                  selectedIndex: 3,
                  onItemSelected: (_) {},
                )
              : AdminMobileBottomNav(
                  selectedIndex: 8,
                  onItemSelected: (_) {},
                )
          : null,
    );
  }

  Widget _buildContent(bool isDark, bool isMobile) {
    final showCards = _showCards ?? isMobile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageTitle(isDark, isMobile),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: _buildViewToggle(showCards, isDark)),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    tooltip: 'Add crop variety',
                    onPressed: _isSaving ? null : () => _showAddDialog(isDark),
                    icon: const Icon(Icons.add_rounded),
                  ),
                  IconButton(
                    tooltip: 'Refresh crop varieties',
                    onPressed: _isLoading ? null : _loadCrops,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: _buildPageTitle(isDark, isMobile)),
              _buildViewToggle(showCards, isDark),
              const SizedBox(width: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _showAddDialog(isDark),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Variety'),
              ),
              IconButton(
                tooltip: 'Refresh crop varieties',
                onPressed: _isLoading ? null : _loadCrops,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.xl),
        if (_isLoading && _crops.isEmpty)
          const AdminDataSkeleton()
        else if (_error != null)
          _buildError(isDark)
        else if (_crops.isEmpty)
          _buildEmpty(isDark)
        else if (showCards)
          _buildCards(isDark)
        else
          _buildTable(isDark),
      ],
    );
  }

  Widget _buildPageTitle(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crop Varieties',
          style: (isMobile ? AppTypography.h5 : AppTypography.h4).copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'Review crop varieties and production specifications.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggle(bool showCards, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.neutral200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewToggleButton(
            label: 'Cards',
            icon: Icons.dashboard_outlined,
            selected: showCards,
            isDark: isDark,
            onTap: () => setState(() => _showCards = true),
          ),
          _buildViewToggleButton(
            label: 'Table',
            icon: Icons.table_rows_outlined,
            selected: !showCards,
            isDark: isDark,
            onTap: () => setState(() => _showCards = false),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton({
    required String label,
    required IconData icon,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.success : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.textSecondary),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _panelDecoration(isDark),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth =
              constraints.maxWidth < 980 ? 980.0 : constraints.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'All Crop Varieties',
                          style: AppTypography.h6.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${_crops.length} records',
                        style: AppTypography.bodySmall.copyWith(
                          color:
                              isDark ? Colors.white60 : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildCropTableHeader(isDark),
                  const SizedBox(height: AppSpacing.sm),
                  for (final crop in _crops) _buildCropTableRow(crop, isDark),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCards(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 3
            : constraints.maxWidth >= 720
                ? 2
                : 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Crop Variety Cards',
                    style: AppTypography.h6.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${_crops.length} records',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                mainAxisExtent: 360,
              ),
              itemCount: _crops.length,
              itemBuilder: (context, index) =>
                  _buildCard(_crops[index], isDark),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCropTableHeader(bool isDark) {
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
          _buildTableHeader('Crop / Variety', flex: 3, isDark: isDark),
          _buildTableHeader('Duration', isDark: isDark),
          _buildTableHeader('Company', flex: 2, isDark: isDark),
          _buildTableHeader('pH', isDark: isDark),
          _buildTableHeader('Temperature', isDark: isDark),
          _buildTableHeader('Sprouting', isDark: isDark),
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

  Widget _buildCropTableRow(Map<String, dynamic> crop, bool isDark) {
    return InkWell(
      onTap: () => _showEditDialog(isDark, crop),
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color:
                isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.success.withValues(alpha: 0.1),
                    child: Text(
                      _initial(crop['crop']),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop['crop'],
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${crop['id']} | ${crop['variety']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white54
                                : AppColors.textSecondary,
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
            Expanded(child: _buildPlainCell(crop['duration'], isDark)),
            Expanded(flex: 2, child: _buildPlainCell(crop['company'], isDark)),
            Expanded(child: _buildMetricBadge(crop['ph'], AppColors.primary)),
            Expanded(
                child:
                    _buildMetricBadge(crop['temperature'], AppColors.warning)),
            Expanded(
                child: _buildMetricBadge(
                    '${crop['sproutingRatio']}%', AppColors.success)),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.edit_outlined,
                size: 18,
                color: isDark ? Colors.white38 : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildPlainCell(dynamic value, bool isDark) {
    return Text(
      value.toString(),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMetricBadge(String text, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  String _initial(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '?' : text.substring(0, 1).toUpperCase();
  }

  Widget _buildCard(Map<String, dynamic> crop, bool isDark) {
    return InkWell(
      onTap: () => _showEditDialog(isDark, crop),
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: _panelDecoration(isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCropImage(crop, isDark),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.68),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop['crop'],
                          style: AppTypography.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          crop['variety'],
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: _buildImageBadge(crop['duration'].toString()),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business_outlined,
                          size: 18, color: AppColors.success),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          crop['company'],
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _buildMetricBadge('pH ${crop['ph']}', AppColors.primary),
                      _buildMetricBadge('EC ${crop['ec']}', AppColors.warning),
                      _buildMetricBadge(
                          '${crop['sproutingRatio']}%', AppColors.success),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCropImage(Map<String, dynamic> crop, bool isDark) {
    final fileId = crop['imageFileId']?.toString().trim() ?? '';
    final image = crop['image']?.toString().trim() ?? '';
    final fallback = Container(
      color:
          isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.neutral100,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: isDark ? Colors.white38 : AppColors.textSecondary,
          size: 28,
        ),
      ),
    );

    if (fileId.isNotEmpty) {
      final encodedFileId = Uri.encodeComponent(fileId);
      return Image.network(
        '${SuperAdminApiService.baseUrl}/storage/buckets/crop-images/files/$encodedFileId/download',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    if (image.isEmpty) return fallback;
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return Image.asset(
      'assets/images/$image',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  Widget _buildError(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _panelDecoration(isDark),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(_error!)),
          IconButton(onPressed: _loadCrops, icon: const Icon(Icons.refresh)),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: _panelDecoration(isDark),
      child: const Column(
        children: [
          Icon(Icons.grass_outlined, size: 40, color: AppColors.textSecondary),
          SizedBox(height: AppSpacing.md),
          Text('No crop varieties have been created yet.'),
        ],
      ),
    );
  }

  String _editText(
    Map<String, dynamic>? crop,
    String key, {
    String? fallbackKey,
  }) {
    final primary = crop?[key]?.toString().trim() ?? '';
    if (primary.isNotEmpty && primary != '-') return primary;
    final fallback = crop?[fallbackKey]?.toString().trim() ?? '';
    return fallback == '-' ? '' : fallback;
  }

  String _editRangeText(
    Map<String, dynamic>? crop,
    String key,
    String rangeKey,
    int index,
  ) {
    final primary = _editText(crop, key);
    if (primary.isNotEmpty) return primary;
    final range = crop?[rangeKey]?.toString() ?? '';
    final parts = range.split('-').map((part) => part.trim()).toList();
    if (index >= parts.length || parts[index] == '-') return '';
    return parts[index];
  }

  void _showAddDialog(bool isDark) => _showVarietyDialog(isDark);

  void _showEditDialog(bool isDark, Map<String, dynamic> crop) =>
      _showVarietyDialog(isDark, crop: crop);

  void _showVarietyDialog(bool isDark, {Map<String, dynamic>? crop}) {
    final isEditing = crop != null;
    final formKey = GlobalKey<FormState>();
    final cropController = TextEditingController(text: _editText(crop, 'crop'));
    final varietyController =
        TextEditingController(text: _editText(crop, 'variety'));
    final imageController =
        TextEditingController(text: _editText(crop, 'imageName'));
    final durationController =
        TextEditingController(text: _editText(crop, 'duration'));
    final companyController =
        TextEditingController(text: _editText(crop, 'company'));
    final harvestController = TextEditingController(
      text: _editText(crop, 'harvestWeightValue', fallbackKey: 'harvestWeight'),
    );
    final sproutingController = TextEditingController(
      text:
          _editText(crop, 'sproutingRatioValue', fallbackKey: 'sproutingRatio'),
    );
    final ecMinController = TextEditingController(
      text: _editRangeText(crop, 'ecMinValue', 'ec', 0),
    );
    final ecMaxController = TextEditingController(
      text: _editRangeText(crop, 'ecMaxValue', 'ec', 1),
    );
    final phMinController = TextEditingController(
      text: _editRangeText(crop, 'phMinValue', 'ph', 0),
    );
    final phMaxController = TextEditingController(
      text: _editRangeText(crop, 'phMaxValue', 'ph', 1),
    );
    final tempMinController = TextEditingController(
      text: _editRangeText(crop, 'tempMinValue', 'temperature', 0),
    );
    final tempMaxController = TextEditingController(
      text: _editRangeText(crop, 'tempMaxValue', 'temperature', 1),
    );
    final humidityMinController = TextEditingController(
      text: _editRangeText(crop, 'humidityMinValue', 'humidity', 0),
    );
    final humidityMaxController = TextEditingController(
      text: _editRangeText(crop, 'humidityMaxValue', 'humidity', 1),
    );
    Uint8List? selectedImageBytes;
    var saving = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.82),
                      ],
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
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(Icons.grass_rounded,
                            color: Colors.white),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                isEditing
                                    ? 'Edit Crop Variety'
                                    : 'Add Crop Variety',
                                style: AppTypography.h6.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                )),
                            Text(
                              isEditing
                                  ? 'Update seed and production specifications'
                                  : 'Define seed and production specifications',
                              style: AppTypography.bodySmall
                                  .copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed:
                            saving ? null : () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          _formField(cropController, 'Crop Name',
                              'Enter crop name', Icons.eco_outlined, isDark),
                          const SizedBox(height: AppSpacing.lg),
                          _formField(
                              varietyController,
                              'Variety Name',
                              'Enter variety name',
                              Icons.grass_outlined,
                              isDark),
                          const SizedBox(height: AppSpacing.lg),
                          _imagePickerField(
                              imageController,
                              'Image File Name',
                              selectedImageBytes == null &&
                                      imageController.text.trim().isEmpty
                                  ? 'Select a crop image'
                                  : imageController.text,
                              Icons.image_outlined,
                              isDark,
                              saving: saving,
                              hasImage: () =>
                                  isEditing ||
                                  selectedImageBytes != null ||
                                  imageController.text.trim().isNotEmpty,
                              onPick: () async {
                                final result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  allowMultiple: false,
                                  withData: true,
                                );
                                final file = result?.files.single;
                                if (file == null) return;
                                setDialogState(() {
                                  selectedImageBytes = file.bytes;
                                  imageController.text = file.name;
                                });
                                formKey.currentState?.validate();
                              }),
                          const SizedBox(height: AppSpacing.lg),
                          _formField(durationController, 'Plant Duration',
                              'e.g., 60 days', Icons.schedule_outlined, isDark),
                          const SizedBox(height: AppSpacing.lg),
                          _formField(
                              companyController,
                              'Seed Company',
                              'Enter seed company',
                              Icons.business_outlined,
                              isDark),
                          const SizedBox(height: AppSpacing.lg),
                          _numberPair(
                            harvestController,
                            'Harvest weight',
                            sproutingController,
                            'Sprouting ratio',
                            isDark,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _numberPair(ecMinController, 'EC minimum',
                              ecMaxController, 'EC maximum', isDark),
                          const SizedBox(height: AppSpacing.lg),
                          _numberPair(phMinController, 'pH minimum',
                              phMaxController, 'pH maximum', isDark),
                          const SizedBox(height: AppSpacing.lg),
                          _numberPair(tempMinController, 'Temperature minimum',
                              tempMaxController, 'Temperature maximum', isDark),
                          const SizedBox(height: AppSpacing.lg),
                          _numberPair(
                              humidityMinController,
                              'Humidity minimum',
                              humidityMaxController,
                              'Humidity maximum',
                              isDark),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : AppColors.neutral50,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppSpacing.radiusXl),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
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
                                  final success = isEditing
                                      ? await _updateCropVariety(
                                          id: crop['id'].toString(),
                                          cropName: cropController.text,
                                          varietyName: varietyController.text,
                                          imageFileName: imageController.text,
                                          imageBytes: selectedImageBytes,
                                          plantDuration:
                                              durationController.text,
                                          company: companyController.text,
                                          harvestingWeight:
                                              harvestController.text,
                                          sproutingRatio:
                                              sproutingController.text,
                                          ecMin: ecMinController.text,
                                          ecMax: ecMaxController.text,
                                          phMin: phMinController.text,
                                          phMax: phMaxController.text,
                                          tempMin: tempMinController.text,
                                          tempMax: tempMaxController.text,
                                          humidityMin:
                                              humidityMinController.text,
                                          humidityMax:
                                              humidityMaxController.text,
                                        )
                                      : await _createCropVariety(
                                          cropName: cropController.text,
                                          varietyName: varietyController.text,
                                          imageFileName: imageController.text,
                                          imageBytes: selectedImageBytes!,
                                          plantDuration:
                                              durationController.text,
                                          company: companyController.text,
                                          harvestingWeight:
                                              harvestController.text,
                                          sproutingRatio:
                                              sproutingController.text,
                                          ecMin: ecMinController.text,
                                          ecMax: ecMaxController.text,
                                          phMin: phMinController.text,
                                          phMax: phMaxController.text,
                                          tempMin: tempMinController.text,
                                          tempMax: tempMaxController.text,
                                          humidityMin:
                                              humidityMinController.text,
                                          humidityMax:
                                              humidityMaxController.text,
                                        );
                                  if (!dialogContext.mounted) return;
                                  if (success) {
                                    Navigator.pop(dialogContext);
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
                              : const Icon(Icons.save_rounded, size: 18),
                          label: Text(saving
                              ? 'Saving'
                              : isEditing
                                  ? 'Update Variety'
                                  : 'Add Variety'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                          ),
                        ),
                      ),
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

  Widget _formField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
    bool isDark, {
    bool numeric = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppColors.textPrimary,
            )),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(
                  decimal: true, signed: true)
              : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.neutral50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : AppColors.neutral200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.success, width: 2),
            ),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return '$label is required';
            if (numeric && double.tryParse(text) == null) {
              return 'Enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _imagePickerField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
    bool isDark, {
    required bool saving,
    required bool Function() hasImage,
    required VoidCallback onPick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppColors.textPrimary,
            )),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: saving ? null : onPick,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: TextButton.icon(
              onPressed: saving ? null : onPick,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Choose'),
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.neutral50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : AppColors.neutral200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.success, width: 2),
            ),
          ),
          validator: (value) {
            if (!hasImage()) {
              return 'Select an image file';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _numberPair(
    TextEditingController first,
    String firstLabel,
    TextEditingController second,
    String secondLabel,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              _formField(
                  first, firstLabel, '0.0', Icons.straighten_rounded, isDark,
                  numeric: true),
              const SizedBox(height: AppSpacing.md),
              _formField(
                  second, secondLabel, '0.0', Icons.straighten_rounded, isDark,
                  numeric: true),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
                child: _formField(
                    first, firstLabel, '0.0', Icons.straighten_rounded, isDark,
                    numeric: true)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: _formField(second, secondLabel, '0.0',
                    Icons.straighten_rounded, isDark,
                    numeric: true)),
          ],
        );
      },
    );
  }

  Future<bool> _createCropVariety({
    required String cropName,
    required String varietyName,
    required String imageFileName,
    required Uint8List imageBytes,
    required String plantDuration,
    required String company,
    required String harvestingWeight,
    required String sproutingRatio,
    required String ecMin,
    required String ecMax,
    required String phMin,
    required String phMax,
    required String tempMin,
    required String tempMax,
    required String humidityMin,
    required String humidityMax,
  }) async {
    final numericValues = [
      harvestingWeight,
      sproutingRatio,
      ecMin,
      ecMax,
      phMin,
      phMax,
      tempMin,
      tempMax,
      humidityMin,
      humidityMax,
    ].map((value) => double.parse(value.trim())).toList();

    setState(() => _isSaving = true);
    try {
      final user = ref.read(currentUserProvider);
      await _api.createCropVariety(
        cropName: cropName.trim(),
        varietyName: varietyName.trim(),
        imageFileName: imageFileName.trim(),
        imageBytes: imageBytes,
        plantDuration: plantDuration.trim(),
        harvestingWeight: numericValues[0],
        company: company.trim(),
        sproutingRatio: numericValues[1],
        ecMin: numericValues[2],
        ecMax: numericValues[3],
        phMin: numericValues[4],
        phMax: numericValues[5],
        tempMin: numericValues[6],
        tempMax: numericValues[7],
        humidityMin: numericValues[8],
        humidityMax: numericValues[9],
        createdBy: user?.name ?? 'Administrator',
      );
      await _loadCrops();
      if (!mounted) return false;
      _showMessage('Crop variety added successfully.');
      return true;
    } catch (error) {
      if (!mounted) return false;
      _showMessage(error.toString(), isError: true);
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _updateCropVariety({
    required String id,
    required String cropName,
    required String varietyName,
    required String imageFileName,
    required Uint8List? imageBytes,
    required String plantDuration,
    required String company,
    required String harvestingWeight,
    required String sproutingRatio,
    required String ecMin,
    required String ecMax,
    required String phMin,
    required String phMax,
    required String tempMin,
    required String tempMax,
    required String humidityMin,
    required String humidityMax,
  }) async {
    final numericValues = [
      harvestingWeight,
      sproutingRatio,
      ecMin,
      ecMax,
      phMin,
      phMax,
      tempMin,
      tempMax,
      humidityMin,
      humidityMax,
    ].map((value) => double.parse(value.trim())).toList();

    setState(() => _isSaving = true);
    try {
      final user = ref.read(currentUserProvider);
      await _api.updateCropVariety(
        id: id,
        cropName: cropName.trim(),
        varietyName: varietyName.trim(),
        imageFileName: imageBytes == null ? null : imageFileName.trim(),
        imageBytes: imageBytes,
        plantDuration: plantDuration.trim(),
        harvestingWeight: numericValues[0],
        company: company.trim(),
        sproutingRatio: numericValues[1],
        ecMin: numericValues[2],
        ecMax: numericValues[3],
        phMin: numericValues[4],
        phMax: numericValues[5],
        tempMin: numericValues[6],
        tempMax: numericValues[7],
        humidityMin: numericValues[8],
        humidityMax: numericValues[9],
        createdBy: user?.name ?? 'Administrator',
      );
      await _loadCrops();
      if (!mounted) return false;
      _showMessage('Crop variety updated successfully.');
      return true;
    } catch (error) {
      if (!mounted) return false;
      _showMessage(error.toString(), isError: true);
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
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
}
