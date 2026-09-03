import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/fulfillment_manager_screen_shell.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

enum PackagingConfigurationAccess { superAdmin, admin, fulfillmentManager }

class PackagingConfigurationScreen extends ConsumerStatefulWidget {
  const PackagingConfigurationScreen({required this.access, super.key});

  final PackagingConfigurationAccess access;

  @override
  ConsumerState<PackagingConfigurationScreen> createState() =>
      _PackagingConfigurationScreenState();
}

class _PackagingConfigurationScreenState
    extends ConsumerState<PackagingConfigurationScreen> {
  final _api = SuperAdminApiService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _packages = [];
  List<Map<String, dynamic>> _plantTypes = [];
  bool _loading = true;
  String? _error;
  String _cropFilter = 'all';

  bool get _isSuperAdmin =>
      widget.access == PackagingConfigurationAccess.superAdmin;
  bool get _isAdmin => widget.access == PackagingConfigurationAccess.admin;
  int get _navIndex => _isSuperAdmin ? 5 : (_isAdmin ? 11 : 7);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshView);
    _load();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshView)
      ..dispose();
    super.dispose();
  }

  void _refreshView() => setState(() {});

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getPackages(),
        _api.getPlantTypes(),
      ]);
      if (!mounted) return;
      setState(() {
        _packages = results[0];
        _plantTypes = results[1]
            .where((plant) =>
                _text(plant, ['status'], 'Active').toLowerCase() == 'active')
            .toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visiblePackages {
    final query = _searchController.text.trim().toLowerCase();
    return _packages.where((package) {
      final crop = _text(package, ['plant_type_name']);
      final matchesCrop = _cropFilter == 'all' || crop == _cropFilter;
      final searchable = [
        _text(package, ['package_name']),
        crop,
        _text(package, ['material_used']),
        _text(package, ['status']),
      ].join(' ').toLowerCase();
      return matchesCrop && (query.isEmpty || searchable.contains(query));
    }).toList();
  }

  Future<void> _openEditor([Map<String, dynamic>? package]) async {
    final user = ref.read(currentUserProvider);
    final panel = _PackageConfigurationPanel(
      package: package,
      plantTypes: _plantTypes,
      api: _api,
      actorName: user?.name ?? _roleLabel,
    );
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final saved = mobile
        ? await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => panel,
          )
        : await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 700, maxHeight: 760),
                child: panel,
              ),
            ),
          );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(package == null
              ? 'Crop packaging configured.'
              : 'Packaging configuration updated.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _load();
    }
  }

  String get _roleLabel {
    if (_isSuperAdmin) return 'Super Administrator';
    if (_isAdmin) return 'Administrator';
    return 'Fulfillment Manager';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.access == PackagingConfigurationAccess.fulfillmentManager) {
      return FulfillmentManagerScreenShell(
        selectedIndex: _navIndex,
        child: _content(),
      );
    }

    final mobile = MediaQuery.sizeOf(context).width < 600;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final userName = user?.name ?? _roleLabel;
    final userEmail = user?.email ?? '';
    final firstName = userName.split(' ').first;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          dark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: mobile
          ? _isSuperAdmin
              ? SuperAdminDrawer(
                  selectedIndex: _navIndex,
                  onItemSelected: (_) {},
                  userName: userName,
                  userEmail: userEmail,
                  userRole: _roleLabel,
                )
              : AdminDrawer(
                  selectedIndex: _navIndex,
                  onItemSelected: (_) {},
                  userName: userName,
                  userEmail: userEmail,
                  userRole: _roleLabel,
                )
          : null,
      bottomNavigationBar: mobile
          ? _isSuperAdmin
              ? SuperAdminMobileBottomNav(
                  selectedIndex: _navIndex, onItemSelected: (_) {})
              : AdminMobileBottomNav(
                  selectedIndex: _navIndex, onItemSelected: (_) {})
          : null,
      body: mobile
          ? Column(
              children: [
                ModernAdminHeader(
                  userName: firstName,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  onProfileTap: () => Navigator.pushNamed(context, '/profile'),
                ),
                Expanded(child: _scrollContent(mobile: true)),
              ],
            )
          : Row(
              children: [
                if (_isSuperAdmin)
                  SuperAdminSidebar(
                    selectedIndex: _navIndex,
                    onItemSelected: (_) {},
                    userName: userName,
                    userEmail: userEmail,
                    userRole: _roleLabel,
                  )
                else
                  ModernAdminSidebar(
                    selectedIndex: _navIndex,
                    onItemSelected: (_) {},
                    userName: userName,
                    userEmail: userEmail,
                    userRole: _roleLabel,
                  ),
                Expanded(
                  child: Column(
                    children: [
                      ModernAdminHeader(
                        userName: firstName,
                        onProfileTap: () =>
                            Navigator.pushNamed(context, '/profile'),
                      ),
                      Expanded(child: _scrollContent(mobile: false)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _scrollContent({required bool mobile}) => RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(mobile ? AppSpacing.md : AppSpacing.xl),
          child: _content(),
        ),
      );

  Widget _content() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mobile = MediaQuery.sizeOf(context).width < 600;
    if (_loading) {
      return const AdminDataSkeleton(rowCount: 5, compact: true);
    }
    if (_error != null) {
      return _PackageErrorState(message: _error!, onRetry: _load);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CatalogHero(
          mobile: mobile,
          roleLabel: _roleLabel,
          onAdd: _plantTypes.isEmpty ? null : () => _openEditor(),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PackageMetrics(packages: _packages),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                'Crop Packaging Catalog',
                style: AppTypography.h5.copyWith(
                  color: dark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text('${_visiblePackages.length} configurations',
                style: AppTypography.caption),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _filters(mobile),
        const SizedBox(height: AppSpacing.md),
        if (_plantTypes.isEmpty)
          const _PackageEmptyState(
            icon: Icons.grass_outlined,
            title: 'No active plant types',
            message:
                'Create an active plant type before configuring packaging for a crop.',
          )
        else if (_visiblePackages.isEmpty)
          const _PackageEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No packaging configurations found',
            message:
                'Adjust the filters or add the first packaging option for this crop.',
          )
        else
          _catalogGrid(),
      ],
    );
  }

  Widget _filters(bool mobile) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cropNames = _plantTypes
        .map((plant) => _text(plant, ['plant_name', 'name']))
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final search = TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search package, crop, material or status',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: _searchController.clear,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: dark ? AppColors.surfaceDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide:
              BorderSide(color: dark ? Colors.white10 : AppColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide:
              BorderSide(color: dark ? Colors.white10 : AppColors.neutral200),
        ),
      ),
    );
    final crop = DropdownButtonFormField<String>(
      initialValue: _cropFilter,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.grass_outlined),
        filled: true,
        fillColor: dark ? AppColors.surfaceDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide:
              BorderSide(color: dark ? Colors.white10 : AppColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide:
              BorderSide(color: dark ? Colors.white10 : AppColors.neutral200),
        ),
      ),
      items: [
        const DropdownMenuItem(value: 'all', child: Text('All crops')),
        ...cropNames
            .map((name) => DropdownMenuItem(value: name, child: Text(name))),
      ],
      onChanged: (value) => setState(() => _cropFilter = value ?? 'all'),
    );
    if (mobile) {
      return Column(children: [search, const SizedBox(height: 10), crop]);
    }
    return Row(children: [
      Expanded(flex: 2, child: search),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: crop),
    ]);
  }

  Widget _catalogGrid() => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1100
              ? 3
              : constraints.maxWidth >= 700
                  ? 2
                  : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _visiblePackages.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisExtent: 285,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            itemBuilder: (_, index) => _PackageConfigurationCard(
              package: _visiblePackages[index],
              onEdit: () => _openEditor(_visiblePackages[index]),
            ),
          );
        },
      );
}

class _PackageConfigurationPanel extends StatefulWidget {
  const _PackageConfigurationPanel({
    required this.package,
    required this.plantTypes,
    required this.api,
    required this.actorName,
  });

  final Map<String, dynamic>? package;
  final List<Map<String, dynamic>> plantTypes;
  final SuperAdminApiService api;
  final String actorName;

  @override
  State<_PackageConfigurationPanel> createState() =>
      _PackageConfigurationPanelState();
}

class _PackageConfigurationPanelState
    extends State<_PackageConfigurationPanel> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _capacityController;
  late final TextEditingController _stockController;
  late final TextEditingController _costController;
  String? _plantId;
  String _unit = 'g';
  String _material = 'Biodegradable';
  String _status = 'Active';
  bool _saving = false;
  String? _error;

  bool get _editing => widget.package != null;

  @override
  void initState() {
    super.initState();
    final package = widget.package ?? const <String, dynamic>{};
    _nameController =
        TextEditingController(text: _text(package, ['package_name']));
    _capacityController =
        TextEditingController(text: _numberText(package['weight_capacity']));
    _stockController =
        TextEditingController(text: _numberText(package['quantity_available']));
    _costController =
        TextEditingController(text: _numberText(package['cost_per_unit']));
    _plantId = _text(package, ['plant_type_id']);
    if (_plantId!.isEmpty ||
        !widget.plantTypes.any((plant) => _docId(plant) == _plantId)) {
      _plantId = null;
    }
    _unit =
        _allowed(_text(package, ['unit']), const ['g', 'kg', 'lbs', 'oz'], 'g');
    _material = _allowed(
      _text(package, ['material_used']),
      const ['Biodegradable', 'Cardboard', 'Paper', 'Plastic', 'Glass'],
      'Biodegradable',
    );
    _status = _allowed(
      _text(package, ['status']),
      const ['Active', 'Damaged', 'Out_of_stock', 'Archived'],
      'Active',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _stockController.dispose();
    _costController.dispose();
    super.dispose();
  }

  String _allowed(String value, List<String> values, String fallback) =>
      values.contains(value) ? value : fallback;

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final plant = widget.plantTypes.firstWhere(
      (item) => _docId(item) == _plantId,
    );
    final stock = double.parse(_stockController.text.trim());
    final resolvedStatus =
        stock <= 0 && _status == 'Active' ? 'Out_of_stock' : _status;
    setState(() => _saving = true);
    try {
      if (_editing) {
        final package = widget.package!;
        await widget.api.updatePackage(
          id: _docId(package),
          packageName: _nameController.text.trim(),
          plantTypeId: _plantId!,
          plantTypeName: _text(plant, ['plant_name', 'name']),
          materialUsed: _material,
          weightCapacity: double.parse(_capacityController.text.trim()),
          unit: _unit,
          quantityAvailable: stock,
          costPerUnit: double.parse(_costController.text.trim()),
          createdBy: _text(package, ['created_by'], widget.actorName),
          createdAt: DateTime.tryParse(_text(package, ['created_at'])) ??
              DateTime.now().toUtc(),
          status: resolvedStatus,
        );
      } else {
        await widget.api.createPackage(
          packageName: _nameController.text.trim(),
          plantTypeId: _plantId!,
          plantTypeName: _text(plant, ['plant_name', 'name']),
          materialUsed: _material,
          weightCapacity: double.parse(_capacityController.text.trim()),
          unit: _unit,
          quantityAvailable: stock,
          costPerUnit: double.parse(_costController.text.trim()),
          createdBy: widget.actorName,
          status: resolvedStatus,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Material(
      color: dark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(18),
        bottom: Radius.circular(mobile ? 0 : 18),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (mobile)
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: dark ? Colors.white24 : AppColors.neutral300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _editing ? Icons.edit_outlined : Icons.add_box_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editing
                              ? 'Edit Crop Packaging'
                              : 'Configure Crop Packaging',
                          style: AppTypography.titleSmall.copyWith(
                            color: dark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Define the package used for one crop',
                          style: AppTypography.bodySmall.copyWith(
                            color:
                                dark ? Colors.white60 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(
                height: 1, color: dark ? Colors.white10 : AppColors.neutral200),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_error != null) ...[
                        _PackageFormError(message: _error!),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      _LabeledField(
                        label: 'Crop',
                        child: DropdownButtonFormField<String>(
                          initialValue: _plantId,
                          isExpanded: true,
                          decoration: _fieldDecoration(
                              context, Icons.grass_outlined, 'Select crop'),
                          items: widget.plantTypes.map((plant) {
                            final name = _text(plant, ['plant_name', 'name']);
                            return DropdownMenuItem(
                              value: _docId(plant),
                              child:
                                  Text(name, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _plantId = value),
                          validator: (value) => value == null
                              ? 'Select the crop this package supports.'
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _LabeledField(
                        label: 'Package name',
                        child: TextFormField(
                          controller: _nameController,
                          enabled: !_saving,
                          decoration: _fieldDecoration(
                              context,
                              Icons.inventory_2_outlined,
                              'e.g. 250 g produce pouch'),
                          validator: _requiredText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _responsivePair(
                        mobile,
                        _LabeledField(
                          label: 'Product capacity',
                          child: TextFormField(
                            controller: _capacityController,
                            enabled: !_saving,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _fieldDecoration(
                                context, Icons.scale_outlined, 'e.g. 250'),
                            validator: _positiveNumber,
                          ),
                        ),
                        _LabeledField(
                          label: 'Capacity unit',
                          child: _select(
                            context,
                            value: _unit,
                            icon: Icons.straighten_rounded,
                            values: const ['g', 'kg', 'lbs', 'oz'],
                            onChanged: (value) =>
                                setState(() => _unit = value!),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _responsivePair(
                        mobile,
                        _LabeledField(
                          label: 'Material',
                          child: _select(
                            context,
                            value: _material,
                            icon: Icons.category_outlined,
                            values: const [
                              'Biodegradable',
                              'Cardboard',
                              'Paper',
                              'Plastic',
                              'Glass'
                            ],
                            onChanged: (value) =>
                                setState(() => _material = value!),
                          ),
                        ),
                        _LabeledField(
                          label: 'Status',
                          child: _select(
                            context,
                            value: _status,
                            icon: Icons.toggle_on_outlined,
                            values: const [
                              'Active',
                              'Damaged',
                              'Out_of_stock',
                              'Archived'
                            ],
                            onChanged: (value) =>
                                setState(() => _status = value!),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _responsivePair(
                        mobile,
                        _LabeledField(
                          label: 'Available package units',
                          child: TextFormField(
                            controller: _stockController,
                            enabled: !_saving,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _fieldDecoration(
                                context, Icons.warehouse_outlined, 'e.g. 1000'),
                            validator: _wholeUnitNumber,
                          ),
                        ),
                        _LabeledField(
                          label: 'Cost per package (GHS)',
                          child: TextFormField(
                            controller: _costController,
                            enabled: !_saving,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _fieldDecoration(
                                context, Icons.payments_outlined, 'e.g. 0.50'),
                            validator: _nonNegativeNumber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(
                height: 1, color: dark ? Colors.white10 : AppColors.neutral200),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50)),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(_editing
                              ? Icons.save_outlined
                              : Icons.add_circle_outline_rounded),
                      label: Text(_saving
                          ? 'Saving...'
                          : _editing
                              ? 'Save changes'
                              : 'Add packaging'),
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

  Widget _responsivePair(bool mobile, Widget first, Widget second) {
    if (mobile) {
      return Column(children: [
        first,
        const SizedBox(height: AppSpacing.md),
        second,
      ]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: first),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: second),
    ]);
  }

  Widget _select(
    BuildContext context, {
    required String value,
    required IconData icon,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) =>
      DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: _fieldDecoration(context, icon, ''),
        items: values
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: _saving ? null : onChanged,
      );

  String? _requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  String? _positiveNumber(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    return number == null || number <= 0 ? 'Enter a value above zero.' : null;
  }

  String? _nonNegativeNumber(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    return number == null || number < 0
        ? 'Enter zero or a positive value.'
        : null;
  }

  String? _wholeUnitNumber(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    return number == null || number < 0
        ? 'Enter zero or a positive whole number.'
        : null;
  }
}

class _CatalogHero extends StatelessWidget {
  const _CatalogHero({
    required this.mobile,
    required this.roleLabel,
    required this.onAdd,
  });
  final bool mobile;
  final String roleLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 20 : 26),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: dark ? Colors.white10 : AppColors.neutral200),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          SizedBox(
            width: mobile ? double.infinity : 500,
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: AppColors.primary, size: 27),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Crop Packaging Configuration',
                          style: AppTypography.h4.copyWith(
                            color: dark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: mobile ? 22 : 26,
                          )),
                      const SizedBox(height: 4),
                      Text(
                        'Set the package capacity, material, stock and cost used to pack each crop.',
                        style: AppTypography.bodySmall.copyWith(
                          color:
                              dark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: Size(mobile ? double.infinity : 180, 48),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Configure packaging'),
          ),
        ],
      ),
    );
  }
}

class _PackageMetrics extends StatelessWidget {
  const _PackageMetrics({required this.packages});
  final List<Map<String, dynamic>> packages;

  @override
  Widget build(BuildContext context) {
    final active =
        packages.where((p) => _text(p, ['status']) == 'Active').length;
    final crops = packages
        .map((item) => _text(item, ['plant_type_name']))
        .where((name) => name.isNotEmpty)
        .toSet()
        .length;
    final lowStock =
        packages.where((p) => _number(p['quantity_available']) <= 100).length;
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth < 650 ? 2 : 4;
      final data = [
        (
          'Configurations',
          '${packages.length}',
          Icons.tune_rounded,
          AppColors.info
        ),
        ('Active', '$active', Icons.check_circle_outline, AppColors.success),
        ('Crops covered', '$crops', Icons.grass_outlined, AppColors.primary),
        (
          'Low stock',
          '$lowStock',
          Icons.warning_amber_rounded,
          AppColors.warning
        ),
      ];
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisExtent: 104,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
        ),
        itemBuilder: (_, index) {
          final item = data[index];
          return _MetricTile(
              label: item.$1, value: item.$2, icon: item.$3, color: item.$4);
        },
      );
    });
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dark ? Colors.white10 : AppColors.neutral200),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: AppTypography.h5.copyWith(
                      color: dark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption),
            ],
          ),
        ),
      ]),
    );
  }
}

class _PackageConfigurationCard extends StatelessWidget {
  const _PackageConfigurationCard(
      {required this.package, required this.onEdit});
  final Map<String, dynamic> package;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final status = _text(package, ['status'], 'Active');
    final statusColor = status == 'Active'
        ? AppColors.success
        : status == 'Damaged'
            ? AppColors.error
            : status == 'Out_of_stock'
                ? AppColors.warning
                : AppColors.neutral500;
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: dark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: dark ? Colors.white10 : AppColors.neutral200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_text(package, ['package_name'], 'Package'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h6.copyWith(
                            color: dark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                    Text(
                        _text(
                            package, ['plant_type_name'], 'Crop not assigned'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                            color: dark
                                ? Colors.white60
                                : AppColors.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit configuration',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _InfoChip(
                  icon: Icons.scale_outlined,
                  text:
                      '${_numberText(package['weight_capacity'])} ${_text(package, [
                        'unit'
                      ])}'),
              _InfoChip(
                  icon: Icons.category_outlined,
                  text: _text(package, ['material_used'])),
              _InfoChip(
                  icon: Icons.warehouse_outlined,
                  text: '${_numberText(package['quantity_available'])} units'),
            ]),
            const Spacer(),
            Divider(color: dark ? Colors.white10 : AppColors.neutral200),
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cost per unit', style: AppTypography.caption),
                    Text(
                        'GHS ${_number(package['cost_per_unit']).toStringAsFixed(2)}',
                        style: AppTypography.bodyMedium.copyWith(
                            color: dark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(status.replaceAll('_', ' '),
                    style: AppTypography.caption.copyWith(
                        color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: .05)
              : AppColors.neutral50,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(text, style: AppTypography.caption),
        ]),
      );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.label),
          const SizedBox(height: 7),
          child,
        ],
      );
}

class _PackageFormError extends StatelessWidget {
  const _PackageFormError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withValues(alpha: .25)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.error))),
        ]),
      );
}

class _PackageEmptyState extends StatelessWidget {
  const _PackageEmptyState(
      {required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          Icon(icon, size: 42, color: AppColors.neutral400),
          const SizedBox(height: 12),
          Text(title, style: AppTypography.h6),
          const SizedBox(height: 4),
          Text(message,
              textAlign: TextAlign.center, style: AppTypography.bodySmall),
        ]),
      );
}

class _PackageErrorState extends StatelessWidget {
  const _PackageErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(children: [
        _PackageFormError(message: message),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again')),
      ]);
}

InputDecoration _fieldDecoration(
    BuildContext context, IconData icon, String hint) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: dark ? Colors.white12 : AppColors.neutral300),
  );
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor:
        dark ? Colors.white.withValues(alpha: .045) : AppColors.neutral50,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
  );
}

String _text(Map<String, dynamic> item, List<String> keys,
    [String fallback = '']) {
  for (final key in keys) {
    final value = item[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return fallback;
}

String _docId(Map<String, dynamic> item) =>
    _text(item, [r'$id', 'plant_type_id', 'package_id', 'id']);

double _number(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;

String _numberText(dynamic value) {
  final number = _number(value);
  return number == number.roundToDouble()
      ? number.toInt().toString()
      : number.toStringAsFixed(2);
}
