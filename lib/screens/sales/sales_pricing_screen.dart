import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sales_manager_screen_shell.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../services/superadmin_api_service.dart';

class SalesPricingScreen extends ConsumerStatefulWidget {
  const SalesPricingScreen({super.key});

  @override
  ConsumerState<SalesPricingScreen> createState() => _SalesPricingScreenState();
}

class _SalesPricingScreenState extends ConsumerState<SalesPricingScreen> {
  final _api = SuperAdminApiService();
  List<Map<String, dynamic>> _pricing = const [];
  List<Map<String, dynamic>> _packages = const [];
  List<Map<String, dynamic>> _varieties = const [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _text(Map<String, dynamic>? item, List<String> keys,
      [String fallback = '']) {
    if (item == null) return fallback;
    for (final key in keys) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') return value;
    }
    return fallback;
  }

  String _id(Map<String, dynamic> item) =>
      _text(item, [r'$id', 'id', 'pricing_id', 'package_id']);

  double _number(Map<String, dynamic> item, String key) =>
      double.tryParse(_text(item, [key], '0')) ?? 0;

  List<Map<String, dynamic>> get _salePricing {
    final query = _search.trim().toLowerCase();
    final records = _pricing.where((price) {
      if (_text(price, ['pricing_type']).toLowerCase() != 'hub_sale') {
        return false;
      }
      return query.isEmpty ||
          [
            _text(price, ['plant_type']),
            _text(price, ['crop_variety']),
            _text(price, ['packaging']),
            _text(price, ['status']),
          ].any((value) => value.toLowerCase().contains(query));
    }).toList();
    records.sort((a, b) =>
        _text(a, ['crop_variety']).compareTo(_text(b, ['crop_variety'])));
    return records;
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await Future.wait<List<Map<String, dynamic>>>([
        _api.getPricing(),
        _api.getPackages(),
        _api.getCrops(),
      ]);
      if (!mounted) return;
      setState(() {
        _pricing = result[0];
        _packages = result[1];
        _varieties = result[2];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _openEditor([Map<String, dynamic>? pricing]) async {
    final editor = _SalesPricingEditor(
      api: _api,
      pricing: pricing,
      packages: _packages,
      varieties: _varieties,
    );
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final changed = mobile
        ? await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => editor,
          )
        : await showDialog<bool>(context: context, builder: (_) => editor);
    if (changed == true) await _load();
  }

  Future<void> _delete(Map<String, dynamic> pricing) async {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    var deleting = false;
    String? modalError;
    final modal = StatefulBuilder(builder: (context, setModalState) {
      final dark = Theme.of(context).brightness == Brightness.dark;
      return Material(
        color: dark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.vertical(
          top: const Radius.circular(20),
          bottom: Radius.circular(mobile ? 0 : 20),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Delete Sales Price',
                        style: AppTypography.titleMedium),
                  ),
                  IconButton(
                    onPressed: deleting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ]),
                const SizedBox(height: 16),
                Text(
                  'Remove the ${_text(pricing, [
                        'crop_variety'
                      ])} price for ${_text(pricing, [
                        'packaging'
                      ])}? Existing deliveries will keep their recorded unit price.',
                  style: AppTypography.bodyMedium,
                ),
                if (modalError != null) ...[
                  const SizedBox(height: 14),
                  _PricingMessage(message: modalError!, error: true),
                ],
                const SizedBox(height: 22),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: deleting ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error),
                      onPressed: deleting
                          ? null
                          : () async {
                              setModalState(() {
                                deleting = true;
                                modalError = null;
                              });
                              try {
                                await _api.deletePricing(_id(pricing));
                                if (context.mounted) {
                                  Navigator.pop(context, true);
                                }
                              } catch (error) {
                                setModalState(() {
                                  deleting = false;
                                  modalError = error.toString();
                                });
                              }
                            },
                      icon: deleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.delete_outline),
                      label: Text(deleting ? 'Deleting...' : 'Delete'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      );
    });
    final changed = mobile
        ? await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => modal,
          )
        : await showDialog<bool>(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: modal),
            ),
          );
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final active = _salePricing
        .where((price) => _text(price, ['status']) == 'Active')
        .length;
    final average = _salePricing.isEmpty
        ? 0.0
        : _salePricing.fold<double>(
                0, (sum, price) => sum + _number(price, 'regular_price')) /
            _salePricing.length;
    return SalesManagerScreenShell(
      selectedIndex: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PricingHero(onAdd: () => _openEditor()),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _PricingMetric(
                  label: 'Price records', value: '${_salePricing.length}'),
              _PricingMetric(label: 'Active', value: '$active'),
              _PricingMetric(
                  label: 'Average per pack',
                  value: 'GHS ${average.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (value) => setState(() => _search = value),
            decoration: InputDecoration(
              hintText: 'Search crop variety or package...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surfaceDark
                  : Colors.white,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: Text('Off-taker Price List',
                  style: AppTypography.titleLarge
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
            IconButton(
              tooltip: 'Refresh pricing',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ]),
          const SizedBox(height: 12),
          if (_loading && _pricing.isEmpty)
            const AdminDataSkeleton()
          else if (_error != null)
            _PricingMessage(message: _error!, error: true)
          else if (_salePricing.isEmpty)
            _PricingEmpty(onAdd: () => _openEditor())
          else
            LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth < 720
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 14) / 2;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: _salePricing
                    .map((price) => SizedBox(
                          width: width,
                          child: _PricingCard(
                            price: price,
                            onEdit: () => _openEditor(price),
                            onDelete: () => _delete(price),
                          ),
                        ))
                    .toList(),
              );
            }),
        ],
      ),
    );
  }
}

class _PricingHero extends StatelessWidget {
  const _PricingHero({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final icon = Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.price_change_outlined,
          color: AppColors.primary, size: 28),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sales Pricing',
            style: AppTypography.titleLarge.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            )),
        const SizedBox(height: 4),
        Text('Set the regular and bulk price charged per packaged unit.',
            style: AppTypography.bodyMedium),
      ],
    );
    final button = FilledButton.icon(
      onPressed: onAdd,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Sales Price'),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.centerLeft, child: icon),
                const SizedBox(height: 14),
                copy,
                const SizedBox(height: 16),
                button,
              ],
            )
          : Row(children: [
              icon,
              const SizedBox(width: 14),
              Expanded(child: copy),
              const SizedBox(width: 14),
              button,
            ]),
    );
  }
}

class _PricingMetric extends StatelessWidget {
  const _PricingMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        width: MediaQuery.sizeOf(context).width < 600 ? 160 : 210,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceDark
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white10
                  : AppColors.neutral200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: AppTypography.titleLarge
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.bodySmall),
          ],
        ),
      );
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.price,
    required this.onEdit,
    required this.onDelete,
  });
  final Map<String, dynamic> price;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _text(String key, [String fallback = '-']) =>
      price[key]?.toString().trim().isNotEmpty == true
          ? price[key].toString()
          : fallback;

  double _number(String key) => double.tryParse(_text(key, '0')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final active = _text('status') == 'Active';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: dark ? Colors.white10 : AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sell_outlined,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_text('crop_variety'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.w700)),
                  Text(_text('packaging'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: (active ? AppColors.success : AppColors.warning)
                    .withValues(alpha: .1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_text('status'),
                  style: AppTypography.labelSmall.copyWith(
                      color: active ? AppColors.success : AppColors.warning)),
            ),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: _PriceValue(
                label: 'Regular / pack',
                value: 'GHS ${_number('regular_price').toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PriceValue(
                label: 'Bulk / pack',
                value: 'GHS ${_number('bulk_price').toStringAsFixed(2)}',
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.outlined(
              tooltip: 'Delete price',
              onPressed: onDelete,
              color: AppColors.error,
              icon: const Icon(Icons.delete_outline),
            ),
          ]),
        ],
      ),
    );
  }
}

class _PriceValue extends StatelessWidget {
  const _PriceValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.labelSmall),
            const SizedBox(height: 4),
            Text(value,
                style: AppTypography.titleSmall
                    .copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _SalesPricingEditor extends StatefulWidget {
  const _SalesPricingEditor({
    required this.api,
    required this.packages,
    required this.varieties,
    this.pricing,
  });
  final SuperAdminApiService api;
  final List<Map<String, dynamic>> packages;
  final List<Map<String, dynamic>> varieties;
  final Map<String, dynamic>? pricing;

  @override
  State<_SalesPricingEditor> createState() => _SalesPricingEditorState();
}

class _SalesPricingEditorState extends State<_SalesPricingEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _regularController;
  late final TextEditingController _bulkController;
  String? _varietyId;
  String? _packageId;
  String _status = 'Active';
  bool _saving = false;
  String? _error;

  bool get _editing => widget.pricing != null;

  String _text(Map<String, dynamic>? item, List<String> keys,
      [String fallback = '']) {
    if (item == null) return fallback;
    for (final key in keys) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') return value;
    }
    return fallback;
  }

  String _id(Map<String, dynamic> item) =>
      _text(item, [r'$id', 'id', 'package_id']);

  String _key(dynamic value) =>
      value.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');

  Map<String, dynamic>? get _variety {
    for (final item in widget.varieties) {
      if (_id(item) == _varietyId) return item;
    }
    return null;
  }

  List<Map<String, dynamic>> get _availablePackages {
    final variety = _variety;
    if (variety == null) return const [];
    final id = _id(variety);
    final name = _key(_text(variety, ['variety_name']));
    return widget.packages.where((item) {
      final status = _text(item, ['status'], 'Active').toLowerCase();
      return status == 'active' &&
          (_text(item, ['crop_variety_id']) == id ||
              _key(_text(item, ['crop_variety_name'])) == name);
    }).toList();
  }

  Map<String, dynamic>? get _package {
    for (final item in _availablePackages) {
      if (_id(item) == _packageId) return item;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final pricing = widget.pricing;
    final varietyName = _key(_text(pricing, ['crop_variety']));
    for (final item in widget.varieties) {
      if (_key(_text(item, ['variety_name'])) == varietyName) {
        _varietyId = _id(item);
        break;
      }
    }
    _varietyId ??=
        widget.varieties.isEmpty ? null : _id(widget.varieties.first);
    final packageName = _key(_text(pricing, ['packaging']));
    for (final item in _availablePackages) {
      final candidate = _key(_text(item, ['package_name']));
      if (candidate == packageName || packageName.contains(candidate)) {
        _packageId = _id(item);
        break;
      }
    }
    _packageId ??=
        _availablePackages.isEmpty ? null : _id(_availablePackages.first);
    _regularController =
        TextEditingController(text: _text(pricing, ['regular_price'], ''));
    _bulkController =
        TextEditingController(text: _text(pricing, ['bulk_price'], ''));
    _status = _text(pricing, ['status'], 'Active');
    if (!const ['Active', 'Review', 'Inactive'].contains(_status)) {
      _status = 'Active';
    }
  }

  @override
  void dispose() {
    _regularController.dispose();
    _bulkController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, IconData icon) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19),
      filled: true,
      fillColor:
          dark ? Colors.white.withValues(alpha: .04) : AppColors.neutral50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            BorderSide(color: dark ? Colors.white10 : AppColors.neutral200),
      ),
    );
  }

  String? _priceValidator(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || number <= 0) return 'Enter a price above GHS 0.';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final variety = _variety;
    final package = _package;
    if (variety == null || package == null) {
      setState(() =>
          _error = 'Select a crop variety and one of its configured packages.');
      return;
    }
    setState(() => _saving = true);
    try {
      final regular = double.parse(_regularController.text.trim());
      final bulk = double.parse(_bulkController.text.trim());
      if (_editing) {
        await widget.api.updatePricing(
          id: _id(widget.pricing!),
          pricingType: 'hub_sale',
          farmId: 'all',
          farmName: 'Hub Sales',
          plantType: _text(variety, ['crop_name'], 'Crop'),
          cropVariety: _text(variety, ['variety_name']),
          packaging: _text(package, ['package_name']),
          unit: 'pack',
          regularPrice: regular,
          bulkPrice: bulk,
          status: _status,
        );
      } else {
        await widget.api.createPricing(
          pricingType: 'hub_sale',
          farmId: 'all',
          farmName: 'Hub Sales',
          plantType: _text(variety, ['crop_name'], 'Crop'),
          cropVariety: _text(variety, ['variety_name']),
          packaging: _text(package, ['package_name']),
          unit: 'pack',
          regularPrice: regular,
          bulkPrice: bulk,
          status: _status,
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
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final content = Material(
      color: dark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(20),
        bottom: Radius.circular(mobile ? 0 : 20),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: MediaQuery.sizeOf(context).height * (mobile ? .95 : .9),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mobile) ...[
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: dark ? Colors.white24 : AppColors.neutral300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.price_change_outlined,
                      color: AppColors.primary, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_editing ? 'Update Sales Price' : 'Add Sales Price',
                          style: AppTypography.titleLarge
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text('Set the amount charged for each packaged unit',
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ]),
            ),
            Divider(
                height: 1, color: dark ? Colors.white10 : AppColors.neutral200),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: LayoutBuilder(builder: (context, constraints) {
                    final fieldWidth = constraints.maxWidth < 560
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 14) / 2;
                    return Wrap(
                      spacing: 14,
                      runSpacing: 16,
                      children: [
                        if (_error != null)
                          SizedBox(
                              width: constraints.maxWidth,
                              child: _PricingMessage(
                                  message: _error!, error: true)),
                        SizedBox(
                          width: fieldWidth,
                          child: DropdownButtonFormField<String>(
                            initialValue: _varietyId,
                            isExpanded: true,
                            decoration: _decoration(
                                'Crop variety', Icons.grass_outlined),
                            items: widget.varieties
                                .map((item) => DropdownMenuItem(
                                      value: _id(item),
                                      child: Text(
                                        '${_text(item, [
                                              'crop_name'
                                            ])} - ${_text(item, [
                                              'variety_name'
                                            ])}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: _saving
                                ? null
                                : (value) => setState(() {
                                      _varietyId = value;
                                      _packageId = _availablePackages.isEmpty
                                          ? null
                                          : _id(_availablePackages.first);
                                    }),
                            validator: (value) =>
                                value == null ? 'Select a crop variety.' : null,
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('package-$_varietyId-$_packageId'),
                            initialValue: _packageId,
                            isExpanded: true,
                            decoration: _decoration(
                                'Package', Icons.inventory_2_outlined),
                            items: _availablePackages
                                .map((item) => DropdownMenuItem(
                                      value: _id(item),
                                      child: Text(
                                        '${_text(item, [
                                              'package_name'
                                            ])} - ${_text(item, [
                                              'weight_capacity'
                                            ])}${_text(item, ['unit'])}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: _saving
                                ? null
                                : (value) => setState(() => _packageId = value),
                            validator: (value) => value == null
                                ? 'Configure and select a package.'
                                : null,
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: TextFormField(
                            controller: _regularController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _decoration(
                                'Regular price per pack (GHS)',
                                Icons.sell_outlined),
                            validator: _priceValidator,
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: TextFormField(
                            controller: _bulkController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: _decoration('Bulk price per pack (GHS)',
                                Icons.local_offer_outlined),
                            validator: _priceValidator,
                          ),
                        ),
                        SizedBox(
                          width: constraints.maxWidth,
                          child: DropdownButtonFormField<String>(
                            initialValue: _status,
                            decoration:
                                _decoration('Status', Icons.verified_outlined),
                            items: const ['Active', 'Review', 'Inactive']
                                .map((status) => DropdownMenuItem(
                                    value: status, child: Text(status)))
                                .toList(),
                            onChanged: _saving
                                ? null
                                : (value) => setState(() => _status = value!),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            Divider(
                height: 1, color: dark ? Colors.white10 : AppColors.neutral200),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving
                        ? 'Saving...'
                        : _editing
                            ? 'Save Changes'
                            : 'Add Price'),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
    return mobile
        ? Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: content,
          )
        : Dialog(backgroundColor: Colors.transparent, child: content);
  }
}

class _PricingMessage extends StatelessWidget {
  const _PricingMessage({required this.message, this.error = false});
  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? AppColors.error : AppColors.success;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Row(children: [
        Icon(error ? Icons.error_outline : Icons.check_circle_outline,
            color: color, size: 19),
        const SizedBox(width: 9),
        Expanded(
            child: Text(message,
                style: AppTypography.bodySmall.copyWith(color: color))),
      ]),
    );
  }
}

class _PricingEmpty extends StatelessWidget {
  const _PricingEmpty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceDark
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(children: [
          const Icon(Icons.price_change_outlined,
              size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Text('No sales prices configured',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Add a price before allocating packaged products.',
              textAlign: TextAlign.center, style: AppTypography.bodySmall),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Sales Price'),
          ),
        ]),
      );
}
