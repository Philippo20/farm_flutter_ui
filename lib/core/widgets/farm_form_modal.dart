import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/farm_team_assignment.dart';
import 'app_dialog.dart';
import 'app_bottom_sheet.dart';

Future<bool?> showFarmFormModal(
  BuildContext context, {
  Map<String, dynamic>? farm,
  required Map<String, List<Map<String, dynamic>>> teamOptions,
  required List<String> plantTypes,
  required List<String> Function(String) varietiesForPlant,
  required Future<void> Function(Map<String, dynamic>) onSubmit,
  VoidCallback? onDelete,
}) {
  final mobile = MediaQuery.sizeOf(context).width < 600;
  final modal = _FarmFormModal(
      farm: farm,
      teamOptions: teamOptions,
      plantTypes: plantTypes,
      varietiesForPlant: varietiesForPlant,
      onSubmit: onSubmit,
      onDelete: onDelete,
      mobile: mobile);
  if (mobile) {
    return showAppBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => modal);
  }
  return showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppDialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: modal));
}

class _FarmFormModal extends StatefulWidget {
  const _FarmFormModal(
      {required this.farm,
      required this.teamOptions,
      required this.plantTypes,
      required this.varietiesForPlant,
      required this.onSubmit,
      required this.onDelete,
      required this.mobile});
  final Map<String, dynamic>? farm;
  final Map<String, List<Map<String, dynamic>>> teamOptions;
  final List<String> plantTypes;
  final List<String> Function(String) varietiesForPlant;
  final Future<void> Function(Map<String, dynamic>) onSubmit;
  final VoidCallback? onDelete;
  final bool mobile;
  @override
  State<_FarmFormModal> createState() => _FarmFormModalState();
}

class _FarmFormModalState extends State<_FarmFormModal> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  late final TextEditingController _name, _location;
  final _selected = <String, String>{};
  late final Set<String> _caretakers;
  late String _plant, _variety, _tier, _status;
  bool _saving = false;
  String? _error;
  bool get editing => widget.farm != null;
  @override
  void initState() {
    super.initState();
    final farm = widget.farm ?? <String, dynamic>{};
    _name = TextEditingController(text: farm['name']?.toString() ?? '');
    _location = TextEditingController(text: farm['location']?.toString() ?? '');
    for (final key in ['ownerID', 'farmManagerId', 'technicianId']) {
      _selected[key] = farm[key]?.toString() ?? '';
    }
    _caretakers = farmCaretakerIds(farm).toSet();
    _plant = farm['plantType']?.toString() ?? '';
    _variety = farm['plantVariety']?.toString() ?? '';
    _tier = farm['tier']?.toString() ?? 'Standard';
    _status = farm['status']?.toString() ?? 'Pending';
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _scroll.dispose();
    super.dispose();
  }

  TextStyle font(double size, {FontWeight weight = FontWeight.normal}) =>
      AppTypography.font(fontSize: size, fontWeight: weight);
  Widget label(String text, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(text, style: font(11, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        child
      ]));
  InputDecoration decoration(IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: .04)
            : AppColors.neutral50,
        prefixIcon: Icon(icon, size: 16),
        prefixIconConstraints: const BoxConstraints(minWidth: 36),
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
            borderSide: BorderSide(color: colors.primary, width: 1.5)));
  }

  Widget input(String title, TextEditingController controller, IconData icon) =>
      label(
          title,
          TextFormField(
              controller: controller,
              style: font(12),
              decoration: decoration(icon),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null));
  Widget select(String title, String value, Map<String, String> options,
      IconData icon, ValueChanged<String> changed) {
    return label(
        title,
        DropdownButtonFormField<String>(
            initialValue: options.containsKey(value) ? value : null,
            isExpanded: true,
            style: font(12)
                .copyWith(color: Theme.of(context).colorScheme.onSurface),
            decoration: decoration(icon),
            hint: Text('Select ${title.toLowerCase()}', style: font(12)),
            items: options.entries
                .map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value,
                        maxLines: 1, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => changed(v));
            },
            validator: (v) => v == null || v.isEmpty ? 'Required' : null));
  }

  Widget pair(Widget left, Widget right) => widget.mobile
      ? Column(children: [left, right])
      : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: left),
          const SizedBox(width: 10),
          Expanded(child: right)
        ]);
  Map<String, String> team(String key) => {
        for (final user in widget.teamOptions[key] ?? <Map<String, dynamic>>[])
          user['id'].toString(): user['name'].toString()
      };
  Widget member(String title, String key, IconData icon) => select(
      title, _selected[key]!, team(key), icon, (v) => _selected[key] = v);

  Future<void> save() async {
    if (_saving || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit({
        'name': _name.text.trim(),
        'location': _location.text.trim(),
        ..._selected,
        'caretaker_ids': _caretakers.toList(),
        'caretakerID': _caretakers.isEmpty ? 'Unassigned' : _caretakers.first,
        'plantType': _plant,
        'plantVariety': _variety,
        'tier': _tier,
        'status': _status
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients)
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final options = team('caretaker_ids');
    // Preserve existing assignments, including users who have since been suspended.
    for (final id in _caretakers) {
      options.putIfAbsent(id, () => 'Assigned caretaker ($id)');
    }
    final varieties =
        widget.varietiesForPlant(_plant).where((v) => v.isNotEmpty).toSet();
    final body = Container(
        constraints: BoxConstraints(
            maxWidth: widget.mobile ? double.infinity : 500,
            maxHeight: MediaQuery.sizeOf(context).height * .9),
        decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 24, offset: Offset(0, 12))
            ]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Row(children: [
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: .75)
                        ]),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.agriculture_outlined,
                        size: 20, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(editing ? 'Edit farm' : 'Add farm',
                          style: font(16, weight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text('Farm details and team assignments',
                          style:
                              font(12).copyWith(color: colors.onSurfaceVariant))
                    ])),
                IconButton(
                    onPressed:
                        _saving ? null : () => Navigator.pop(context, false),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, size: 16))
              ])),
          Flexible(
              child: SingleChildScrollView(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AbsorbPointer(
                      absorbing: _saving,
                      child: Form(
                          key: _form,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                input('Farm name', _name,
                                    Icons.agriculture_outlined),
                                input('Location', _location,
                                    Icons.location_on_outlined),
                                pair(
                                    member('Owner', 'ownerID',
                                        Icons.person_outline),
                                    member('Farm manager', 'farmManagerId',
                                        Icons.manage_accounts_outlined)),
                                member('Technician', 'technicianId',
                                    Icons.build_outlined),
                                label(
                                    'Caretakers',
                                    FormField<List<String>>(
                                        initialValue: _caretakers.toList(),
                                        validator: (_) => _caretakers.isEmpty
                                            ? 'Select at least one caretaker.'
                                            : null,
                                        builder: (field) => Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      'Select everyone who will work on this farm.',
                                                      style: font(12).copyWith(
                                                          color: colors
                                                              .onSurfaceVariant)),
                                                  const SizedBox(height: 6),
                                                  for (final entry
                                                      in options.entries)
                                                    Material(
                                                        color:
                                                            Colors.transparent,
                                                        child: CheckboxListTile(
                                                            contentPadding:
                                                                EdgeInsets.zero,
                                                            dense: true,
                                                            controlAffinity:
                                                                ListTileControlAffinity
                                                                    .leading,
                                                            title: Text(
                                                                entry.value,
                                                                style:
                                                                    font(12)),
                                                            value: _caretakers
                                                                .contains(
                                                                    entry.key),
                                                            onChanged:
                                                                (checked) {
                                                              setState(() {
                                                                if (checked ==
                                                                    true) {
                                                                  _caretakers
                                                                      .add(entry
                                                                          .key);
                                                                } else {
                                                                  _caretakers
                                                                      .remove(entry
                                                                          .key);
                                                                }
                                                              });
                                                              field.didChange(
                                                                  _caretakers
                                                                      .toList());
                                                            })),
                                                  if (options.isEmpty)
                                                    Text(
                                                        'Create an active Caretaker user first.',
                                                        style: font(12)),
                                                  if (field.hasError)
                                                    Text(field.errorText!,
                                                        style: font(11)
                                                            .copyWith(
                                                                color: colors
                                                                    .error)),
                                                ]))),
                                pair(
                                    select(
                                        'Plant type',
                                        _plant,
                                        {
                                          for (final p in widget.plantTypes)
                                            p: p
                                        },
                                        Icons.eco_outlined, (v) {
                                      _plant = v;
                                      _variety = '';
                                    }),
                                    KeyedSubtree(
                                        key: ValueKey(_plant),
                                        child: select(
                                            'Crop variety',
                                            _variety,
                                            {for (final v in varieties) v: v},
                                            Icons.grass_outlined,
                                            (v) => _variety = v))),
                                pair(
                                    select(
                                        'Tier',
                                        _tier,
                                        const {
                                          'Basic': 'Basic',
                                          'Standard': 'Standard',
                                          'Premium': 'Premium'
                                        },
                                        Icons.layers_outlined,
                                        (v) => _tier = v),
                                    select(
                                        'Status',
                                        _status,
                                        const {
                                          'Active': 'Active',
                                          'Pending': 'Pending',
                                          'Suspended': 'Suspended'
                                        },
                                        Icons.toggle_on_outlined,
                                        (v) => _status = v)),
                                if (widget.onDelete != null)
                                  TextButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context, false);
                                        widget.onDelete!();
                                      },
                                      icon: const Icon(Icons.delete_outline,
                                          size: 16),
                                      label: const Text('Delete farm'),
                                      style: TextButton.styleFrom(
                                          foregroundColor: colors.error)),
                                if (_error != null)
                                  Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 14),
                                      child: Text(_error!,
                                          style: font(12)
                                              .copyWith(color: colors.error))),
                              ]))))),
          Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: font(13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(
                    child: FilledButton(
                        onPressed: _saving ? null : save,
                        style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: font(13),
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
                                        strokeWidth: 2)),
                                const SizedBox(width: 8)
                              ],
                              Flexible(
                                  child: Text(_saving
                                      ? 'Saving...'
                                      : editing
                                          ? 'Save changes'
                                          : 'Add farm'))
                            ]))),
              ])),
        ]));
    return Padding(
        padding: EdgeInsets.only(
            bottom:
                widget.mobile ? MediaQuery.viewInsetsOf(context).bottom : 0),
        child: SafeArea(top: false, child: body));
  }
}
