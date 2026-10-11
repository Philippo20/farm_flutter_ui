import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'crop_variety_modal_frame.dart';
import 'cedi_icon.dart';

class PricingRateModal extends StatefulWidget {
  const PricingRateModal(
      {super.key,
      required this.initial,
      required this.farms,
      required this.plants,
      required this.varieties,
      required this.packages,
      required this.onSave,
      required this.editing});
  final Map<String, String> initial, farms;
  final List<String> plants, packages;
  final List<String> Function(String) varieties;
  final Future<void> Function(Map<String, String>, bool) onSave;
  final bool editing;
  @override
  State<PricingRateModal> createState() => _PricingRateModalState();
}

class _PricingRateModalState extends State<PricingRateModal> {
  final _form = GlobalKey<FormState>();
  late final _values = {...widget.initial};
  late final _regular = TextEditingController(text: _values['regular_price']);
  late final _bulk = TextEditingController(text: _values['bulk_price']);
  bool _saving = false, _applyUnpriced = false;
  String? _error;
  bool get _sale => _values['pricing_type'] == 'hub_sale';
  @override
  void dispose() {
    _regular.dispose();
    _bulk.dispose();
    super.dispose();
  }

  List<String> _options(List<String> options, String? selected) => {
        if (selected != null && selected.isNotEmpty) selected,
        ...options
      }.toList();

  TextStyle _text(double size, {FontWeight weight = FontWeight.normal}) =>
      AppTypography.font(
          fontSize: size,
          fontWeight: weight,
          color: Theme.of(context).colorScheme.onSurface);

  InputDecoration _decoration({bool money = false, IconData? icon}) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
        isDense: true,
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: .4),
        prefixIcon: money
            ? const Padding(
                padding: EdgeInsets.all(10), child: CediIcon(size: 16))
            : icon == null
                ? null
                : Icon(icon, size: 16),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.outlineVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)));
  }

  Widget _field(String label, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: _text(11, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        child
      ]));

  Widget _dropdown(String label, String key, List<String> options,
          {Map<String, String>? labels}) =>
      _field(
          label,
          DropdownButtonFormField<String>(
              key: ValueKey('$key:${_values[key]}'),
              initialValue: _values[key],
              isExpanded: true,
              style: _text(12),
              decoration: _decoration(
                  icon: switch (key) {
                'farm_id' => Icons.agriculture_outlined,
                'plant_type' => Icons.eco_outlined,
                'crop_variety' => Icons.grass_outlined,
                'packaging' => Icons.inventory_2_outlined,
                'unit' => Icons.straighten_outlined,
                'status' => Icons.check_circle_outline,
                _ => Icons.payments_outlined,
              }),
              items: options
                  .map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(labels?[value] ?? value,
                          maxLines: 1, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() {
                        _values[key] = value!;
                        if (key == 'plant_type') {
                          _values['crop_variety'] =
                              widget.varieties(value).firstOrNull ?? '';
                        }
                      }),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Select a value.' : null));

  Widget _price(String label, TextEditingController controller) => _field(
      label,
      TextFormField(
          controller: controller,
          enabled: !_saving,
          style: _text(12),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _decoration(money: true),
          validator: (value) {
            final amount = double.tryParse(value ?? '');
            return amount == null || !amount.isFinite || amount < 0
                ? 'Enter a valid cedi amount.'
                : null;
          }));

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final selected = _values['owner_price_tier'] == 'Bulk' ? _bulk : _regular;
    if (!_sale &&
        _values['status'] == 'Active' &&
        (double.tryParse(selected.text) ?? 0) <= 0) {
      setState(() => _error = 'The selected farm-owner rate must be above ₵0.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave({
        ..._values,
        'regular_price': _regular.text,
        'bulk_price': _bulk.text
      }, _applyUnpriced);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mobile = MediaQuery.sizeOf(context).width < 600 ||
        Theme.of(context).platform == TargetPlatform.android;
    Widget pair(Widget a, Widget b) => mobile
        ? Column(children: [a, b])
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: a),
            const SizedBox(width: 10),
            Expanded(child: b)
          ]);
    final units = _sale ? ['pack'] : ['kg', 'g', 'heads'];
    return PopScope(
        canPop: !_saving,
        child: CropVarietyModalFrame(
            mobile: mobile,
            isDark: dark,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [AppColors.primary, Color(0xff15803d)]),
                            borderRadius: BorderRadius.circular(10)),
                        child: const CediIcon(color: Colors.white)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                              '${widget.editing ? 'Edit' : 'Add'} ${_sale ? 'hub sale' : 'farm purchase'} price',
                              style: _text(16, weight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                              _sale
                                  ? 'Packaged prices for off-takers'
                                  : 'Choose the rate used for farm-owner revenue',
                              style: _text(12))
                        ])),
                    IconButton(
                        tooltip: 'Close',
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 16))
                  ])),
              Flexible(
                  child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Form(
                          key: _form,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (!_sale)
                                  _dropdown('Spoke farm', 'farm_id',
                                      widget.farms.keys.toList(),
                                      labels: widget.farms),
                                pair(
                                    _dropdown(
                                        'Plant type',
                                        'plant_type',
                                        _options(widget.plants,
                                            _values['plant_type'])),
                                    _dropdown(
                                        'Crop variety',
                                        'crop_variety',
                                        _options(
                                            widget.varieties(
                                                _values['plant_type']!),
                                            _values['crop_variety']))),
                                if (_sale)
                                  _dropdown(
                                      'Packaging',
                                      'packaging',
                                      _options(widget.packages,
                                          _values['packaging'])),
                                pair(
                                    _dropdown('Unit', 'unit',
                                        _options(units, _values['unit'])),
                                    _dropdown('Status', 'status',
                                        ['Active', 'Review', 'Inactive'])),
                                pair(_price('Regular price (₵)', _regular),
                                    _price('Bulk price (₵)', _bulk)),
                                if (!_sale) ...[
                                  _dropdown(
                                      'Price to use for farm-owner revenue',
                                      'owner_price_tier',
                                      ['Regular', 'Bulk']),
                                  Text(
                                      'Revenue = accepted quantity × selected rate. Saved receipt rates remain unchanged when prices are edited.',
                                      style: _text(12)),
                                  const SizedBox(height: 10),
                                  Material(
                                      color: Colors.transparent,
                                      child: CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                          title: Text(
                                              'Value existing receipts awaiting pricing',
                                              style: _text(12)),
                                          subtitle: Text(
                                              'Applies this rate only to unpriced receipts for this farm and crop. Previously valued receipts are preserved.',
                                              style: _text(11)),
                                          value: _applyUnpriced,
                                          onChanged: _saving
                                              ? null
                                              : (value) => setState(() =>
                                                  _applyUnpriced = value!))),
                                ],
                                if (_error != null)
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      child: Text(_error!,
                                          style: _text(12).copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error))),
                              ])))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: Row(children: [
                    Expanded(
                        child: OutlinedButton(
                            onPressed:
                                _saving ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            child: Text('Cancel', style: _text(13)))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_saving) ...[
                                    const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white)),
                                    const SizedBox(width: 8)
                                  ],
                                  Flexible(
                                      child: Text(
                                          _saving ? 'Saving…' : 'Save pricing',
                                          textAlign: TextAlign.center,
                                          style: AppTypography.font(
                                              fontSize: 13,
                                              color: Colors.white)))
                                ]))),
                  ]))
            ])));
  }
}
