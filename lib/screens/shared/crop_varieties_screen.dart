import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final duration = _durationParts(doc);
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
      'duration': duration.label,
      'durationValue': duration.value,
      'durationUnit': duration.unit,
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

  ({int value, String unit, String label}) _durationParts(
    Map<String, dynamic> doc,
  ) {
    final rawValue = doc['plant_duration_value'];
    final value = rawValue is num
        ? rawValue.toInt()
        : int.tryParse(rawValue?.toString() ?? '') ?? 0;
    final unit = (doc['plant_duration_unit'] ?? '').toString().toLowerCase();

    if (value <= 0 || (unit != 'days' && unit != 'weeks' && unit != 'months')) {
      return (value: 0, unit: 'days', label: '-');
    }
    return (value: value, unit: unit, label: '$value $unit');
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
          SizedBox(
            width: 88,
            child: Text(
              'Actions',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white54 : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
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
            SizedBox(
              width: 88,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Edit crop variety',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showEditDialog(isDark, crop),
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete crop variety',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showDeleteDialog(crop, isDark),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
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
    final durationController = TextEditingController(
      text: _editText(crop, 'durationValue'),
    );
    var selectedDurationUnit = _editText(crop, 'durationUnit').toLowerCase();
    if (!const {'days', 'weeks', 'months'}.contains(selectedDurationUnit)) {
      selectedDurationUnit = 'days';
    }
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
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.82),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(
                          Icons.grass_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                isEditing
                                    ? 'Edit Crop Variety'
                                    : 'Add Crop Variety',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  height: 1.25,
                                )),
                            const SizedBox(height: 3),
                            Text(
                              isEditing
                                  ? 'Update seed and production specifications'
                                  : 'Define seed and production specifications',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                color: Colors.white70,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed:
                            saving ? null : () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          _formFieldPair(
                            firstController: cropController,
                            firstLabel: 'Crop Name',
                            firstHint: 'Enter crop name',
                            firstIcon: Icons.eco_outlined,
                            secondController: varietyController,
                            secondLabel: 'Variety Name',
                            secondHint: 'Enter variety name',
                            secondIcon: Icons.grass_outlined,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _imagePickerField(
                              imageController,
                              'Image File Name',
                              selectedImageBytes == null &&
                                      imageController.text.trim().isEmpty
                                  ? 'Select a crop image'
                                  : imageController.text,
                              Icons.image_outlined,
                              isDark,
                              previewBytes: selectedImageBytes,
                              existingCrop: crop,
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
                          const SizedBox(height: 16),
                          _widgetPair(
                            first: _durationField(
                              controller: durationController,
                              selectedUnit: selectedDurationUnit,
                              isDark: isDark,
                              onUnitChanged: saving
                                  ? null
                                  : (value) => setDialogState(
                                        () => selectedDurationUnit = value,
                                      ),
                            ),
                            second: _formField(
                              companyController,
                              'Seed Company',
                              'Enter seed company',
                              Icons.business_outlined,
                              isDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _numberPair(
                            harvestController,
                            'Harvest weight',
                            sproutingController,
                            'Sprouting ratio',
                            isDark,
                          ),
                          const SizedBox(height: 16),
                          _numberPair(ecMinController, 'EC minimum',
                              ecMaxController, 'EC maximum', isDark),
                          const SizedBox(height: 16),
                          _numberPair(phMinController, 'pH minimum',
                              phMaxController, 'pH maximum', isDark),
                          const SizedBox(height: 16),
                          _numberPair(tempMinController, 'Temperature minimum',
                              tempMaxController, 'Temperature maximum', isDark),
                          const SizedBox(height: 16),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : AppColors.neutral50,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppSpacing.radiusLg),
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
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      if (isEditing) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: saving
                                ? null
                                : () {
                                    Navigator.pop(dialogContext);
                                    _showDeleteDialog(crop, isDark);
                                  },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 17,
                            ),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(
                                color: AppColors.error.withValues(alpha: 0.45),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
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
                                          plantDurationValue:
                                              durationController.text,
                                          plantDurationUnit:
                                              selectedDurationUnit,
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
                                          plantDurationValue:
                                              durationController.text,
                                          plantDurationUnit:
                                              selectedDurationUnit,
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
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
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

  Future<void> _showDeleteDialog(
    Map<String, dynamic> crop,
    bool isDark,
  ) async {
    var deleting = false;
    String? deleteError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => PopScope(
          canPop: !deleting,
          child: Dialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_forever_outlined,
                        color: AppColors.error,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Delete Crop Variety?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This permanently removes the variety from the crop catalogue and cannot be undone.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        height: 1.5,
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : AppColors.neutral50,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: _buildCropImage(crop, isDark),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  crop['crop'].toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  crop['variety'].toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
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
                    ),
                    if (deleteError != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          deleteError!,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            height: 1.4,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: deleting
                                ? null
                                : () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: deleting
                                ? null
                                : () async {
                                    final id = crop['id']?.toString() ?? '';
                                    if (id.isEmpty) {
                                      setDialogState(() => deleteError =
                                          'This crop variety has no valid record ID.');
                                      return;
                                    }
                                    setDialogState(() {
                                      deleting = true;
                                      deleteError = null;
                                    });
                                    if (mounted) {
                                      setState(() => _isSaving = true);
                                    }
                                    try {
                                      await _api.deleteCropVariety(id);
                                      await _loadCrops();
                                      if (!dialogContext.mounted) return;
                                      Navigator.pop(dialogContext);
                                      if (mounted) {
                                        _showMessage(
                                          'Crop variety deleted successfully.',
                                        );
                                      }
                                    } catch (error) {
                                      if (!dialogContext.mounted) return;
                                      setDialogState(() {
                                        deleting = false;
                                        deleteError = error.toString();
                                      });
                                    } finally {
                                      if (mounted) {
                                        setState(() => _isSaving = false);
                                      }
                                    }
                                  },
                            icon: deleting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 17,
                                  ),
                            label: Text(deleting ? 'Deleting' : 'Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              textStyle: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
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
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.textPrimary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(
                  decimal: true, signed: true)
              : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 12.5,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
            errorStyle: GoogleFonts.poppins(fontSize: 10.5, height: 1.25),
            prefixIcon: Icon(icon, size: 18),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
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
    required Uint8List? previewBytes,
    required Map<String, dynamic>? existingCrop,
    required bool saving,
    required bool Function() hasImage,
    required VoidCallback onPick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.textPrimary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: saving ? null : onPick,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.neutral50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isDark ? Colors.white12 : AppColors.neutral200,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImagePickerPreview(
                  previewBytes: previewBytes,
                  existingCrop: existingCrop,
                  isDark: isDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: controller,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                readOnly: true,
                onTap: saving ? null : onPick,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                  errorStyle: GoogleFonts.poppins(fontSize: 10.5, height: 1.25),
                  prefixIcon: Icon(icon, size: 18),
                  suffixIcon: IconButton(
                    tooltip: 'Choose image',
                    onPressed: saving ? null : onPick,
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
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
                    borderSide:
                        const BorderSide(color: AppColors.success, width: 2),
                  ),
                ),
                validator: (value) {
                  if (!hasImage()) {
                    return 'Select an image file';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePickerPreview({
    required Uint8List? previewBytes,
    required Map<String, dynamic>? existingCrop,
    required bool isDark,
  }) {
    if (previewBytes != null && previewBytes.isNotEmpty) {
      return Image.memory(
        previewBytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePickerPlaceholder(isDark),
      );
    }
    if (existingCrop != null) {
      return _buildCropImage(existingCrop, isDark);
    }
    return _imagePickerPlaceholder(isDark);
  }

  Widget _imagePickerPlaceholder(bool isDark) {
    return Center(
      child: Icon(
        Icons.add_photo_alternate_outlined,
        size: 24,
        color: isDark ? Colors.white38 : AppColors.textSecondary,
      ),
    );
  }

  Widget _formFieldPair({
    required TextEditingController firstController,
    required String firstLabel,
    required String firstHint,
    required IconData firstIcon,
    required TextEditingController secondController,
    required String secondLabel,
    required String secondHint,
    required IconData secondIcon,
    required bool isDark,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final firstField = _formField(
          firstController,
          firstLabel,
          firstHint,
          firstIcon,
          isDark,
        );
        final secondField = _formField(
          secondController,
          secondLabel,
          secondHint,
          secondIcon,
          isDark,
        );

        if (constraints.maxWidth < 500) {
          return Column(
            children: [
              firstField,
              const SizedBox(height: 16),
              secondField,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: firstField),
            const SizedBox(width: 16),
            Expanded(child: secondField),
          ],
        );
      },
    );
  }

  Widget _widgetPair({required Widget first, required Widget second}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 500) {
          return Column(
            children: [
              first,
              const SizedBox(height: 16),
              second,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 16),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _durationField({
    required TextEditingController controller,
    required String selectedUnit,
    required bool isDark,
    required ValueChanged<String>? onUnitChanged,
  }) {
    InputDecoration decoration({String? hint, IconData? icon}) {
      return InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 12.5,
          color: isDark ? Colors.white54 : AppColors.textSecondary,
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 10.5, height: 1.25),
        prefixIcon: icon == null ? null : Icon(icon, size: 18),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        filled: true,
        fillColor:
            isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.neutral50,
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
      );
    }

    final textStyle = GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: isDark ? Colors.white : AppColors.textPrimary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plant Duration',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.textPrimary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                style: textStyle,
                keyboardType: TextInputType.number,
                decoration: decoration(
                  hint: 'e.g., 60',
                  icon: Icons.schedule_outlined,
                ),
                validator: (value) {
                  final duration = int.tryParse(value?.trim() ?? '');
                  if (duration == null || duration <= 0) {
                    return 'Enter a valid duration';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 108,
              child: DropdownButtonFormField<String>(
                initialValue: selectedUnit,
                isExpanded: true,
                style: textStyle,
                decoration: decoration(),
                items: const [
                  DropdownMenuItem(value: 'days', child: Text('Days')),
                  DropdownMenuItem(value: 'weeks', child: Text('Weeks')),
                  DropdownMenuItem(value: 'months', child: Text('Months')),
                ],
                onChanged: onUnitChanged == null
                    ? null
                    : (value) {
                        if (value != null) onUnitChanged(value);
                      },
              ),
            ),
          ],
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
        if (constraints.maxWidth < 500) {
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
    required String plantDurationValue,
    required String plantDurationUnit,
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
        plantDurationValue: int.parse(plantDurationValue.trim()),
        plantDurationUnit: plantDurationUnit,
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
    required String plantDurationValue,
    required String plantDurationUnit,
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
        plantDurationValue: int.parse(plantDurationValue.trim()),
        plantDurationUnit: plantDurationUnit,
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
