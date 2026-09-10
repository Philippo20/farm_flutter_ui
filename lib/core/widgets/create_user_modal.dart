import 'app_dialog.dart';
import 'app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

Future<bool?> showCreateUserModal(
  BuildContext context, {
  Map<String, dynamic>? initialValues,
  VoidCallback? onDelete,
  bool includeAccountFields = false,
  String Function(String)? departmentForRole,
  required List<String> roles,
  required List<String> departments,
  required Future<void> Function(Map<String, dynamic>) onSubmit,
}) {
  final mobile = MediaQuery.sizeOf(context).width < 600;
  final modal = _CreateUserModal(
      includeAccountFields: includeAccountFields,
      departmentForRole: departmentForRole,
      initialValues: initialValues,
      onDelete: onDelete,
      roles: roles,
      departments: departments,
      onSubmit: onSubmit,
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

class _CreateUserModal extends StatefulWidget {
  const _CreateUserModal(
      {this.includeAccountFields = false,
      this.departmentForRole,
      this.initialValues,
      this.onDelete,
      required this.roles,
      required this.departments,
      required this.onSubmit,
      required this.mobile});
  final bool includeAccountFields;
  final String Function(String)? departmentForRole;
  final Map<String, dynamic>? initialValues;
  final VoidCallback? onDelete;
  final List<String> roles;
  final List<String> departments;
  final Future<void> Function(Map<String, dynamic>) onSubmit;
  final bool mobile;
  @override
  State<_CreateUserModal> createState() => _CreateUserModalState();
}

class _CreateUserModalState extends State<_CreateUserModal> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _fields = {
    for (final key in [
      'password',
      'phone',
      'address',
      'name',
      'email',
      'license',
      'vehicle',
      'vehicleType',
      'capacity'
    ])
      key: TextEditingController()
  };
  String _role = 'Caretaker';
  String _department = 'Field Work';
  String _status = 'Pending';
  bool get _editing => widget.initialValues != null;

  @override
  void initState() {
    super.initState();
    final values = widget.initialValues;
    if (values == null) return;
    for (final entry in _fields.entries) {
      entry.value.text = (values[entry.key] ?? '').toString();
    }
    _role = values['role'] as String;
    _department = values['department'] as String;
    _status = values['status'] as String;
  }

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit({
        for (final entry in _fields.entries)
          entry.key: entry.key == 'password'
              ? entry.value.text
              : entry.value.text.trim(),
        'role': _role,
        'department': widget.departmentForRole?.call(_role) ?? _department,
        'status': _status,
        'capacity': double.tryParse(_fields['capacity']!.text.trim()) ?? 0.0,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = dark ? Colors.white54 : AppColors.textSecondary;
    final text = dark ? Colors.white : AppColors.textPrimary;
    final keyboard =
        widget.mobile ? MediaQuery.viewInsetsOf(context).bottom : 0.0;
    final body = Container(
      constraints: BoxConstraints(
          maxWidth: widget.mobile ? double.infinity : 500,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: widget.mobile
              ? const BorderRadius.vertical(top: Radius.circular(24))
              : BorderRadius.circular(16),
          boxShadow: [
            if (!widget.mobile)
              const BoxShadow(
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
                        AppColors.primary.withValues(alpha: 0.75)
                      ]),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.person_add_outlined,
                      size: 20, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(_editing ? 'Edit user' : 'Add user',
                        style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: text)),
                    const SizedBox(height: 3),
                    Text(
                        _editing
                            ? 'Update account details and access'
                            : 'Create an account for your team',
                        style: GoogleFonts.inter(fontSize: 12, color: muted)),
                  ])),
              IconButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(false),
                  tooltip: 'Close',
                  icon: Icon(Icons.close_rounded, size: 16, color: muted)),
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
                              _input('name', 'Full name', Icons.person_outline),
                              _input('email', 'Email address',
                                  Icons.email_outlined,
                                  keyboard: TextInputType.emailAddress),
                              _pair(
                                  _select(
                                      'Role',
                                      _role,
                                      widget.roles,
                                      Icons.badge_outlined,
                                      (value) => setState(() => _role = value)),
                                  widget.departmentForRole != null
                                      ? _label(
                                          'Department',
                                          InputDecorator(
                                              decoration: _decoration(
                                                  Icons.business_outlined),
                                              child: Text(
                                                  widget.departmentForRole!(
                                                      _role),
                                                  style: GoogleFonts.inter(
                                                      fontSize: 12))))
                                      : _select(
                                          'Department',
                                          _department,
                                          widget.departments,
                                          Icons.business_outlined,
                                          (value) => setState(
                                              () => _department = value))),
                              if (widget.includeAccountFields || _editing)
                                _input(
                                    'password',
                                    _editing
                                        ? 'New password (leave blank to keep current)'
                                        : 'Password',
                                    Icons.lock_outline),
                              if (widget.includeAccountFields) ...[
                                _input('phone', 'Phone number',
                                    Icons.phone_outlined,
                                    keyboard: TextInputType.phone),
                                _input('address', 'Address',
                                    Icons.location_on_outlined),
                              ],
                              if (_editing || widget.includeAccountFields)
                                _select(
                                    'Status',
                                    _status,
                                    const ['Active', 'Pending', 'Suspended'],
                                    Icons.toggle_on_outlined,
                                    (value) => setState(() => _status = value)),
                              if (_role == 'Driver') ...[
                                _input('license', 'Driver license number',
                                    Icons.badge_outlined),
                                _input('vehicle', 'Vehicle registration',
                                    Icons.local_shipping_outlined),
                                _pair(
                                    _input('vehicleType', 'Vehicle type',
                                        Icons.directions_car_outlined),
                                    _input('capacity', 'Capacity (kg)',
                                        Icons.scale_outlined,
                                        keyboard: TextInputType.number)),
                              ],
                              if (widget.onDelete != null)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: TextButton.icon(
                                        onPressed: _saving
                                            ? null
                                            : () {
                                                Navigator.of(context)
                                                    .pop(false);
                                                widget.onDelete!();
                                              },
                                        style: TextButton.styleFrom(
                                            foregroundColor: AppColors.error),
                                        icon: const Icon(Icons.delete_outline,
                                            size: 16),
                                        label: const Text('Delete user'))),
                              if (_error != null)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: Semantics(
                                        liveRegion: true,
                                        child: Text(_error!,
                                            style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppColors.error)))),
                            ]))))),
        Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
            child: Row(children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: _buttonStyle(),
                      child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(
                  child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      style: _buttonStyle(),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_saving) ...[
                              const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                                child: Text(
                                    _saving
                                        ? (_editing ? 'Updating…' : 'Creating…')
                                        : (_editing
                                            ? 'Save changes'
                                            : 'Add user'),
                                    textAlign: TextAlign.center)),
                          ]))),
            ])),
      ]),
    );
    return PopScope(
        canPop: !_saving,
        child: Padding(
            padding: EdgeInsets.only(bottom: keyboard),
            child: widget.mobile ? SafeArea(top: false, child: body) : body));
  }

  ButtonStyle _buttonStyle() => ButtonStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
      textStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
      shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));

  Widget _pair(Widget first, Widget second) => widget.mobile
      ? Column(children: [first, second])
      : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: first),
          const SizedBox(width: 10),
          Expanded(child: second)
        ]);

  Widget _label(String label, Widget field) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        field,
      ]));

  InputDecoration _decoration(IconData icon) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
        filled: true,
        fillColor:
            dark ? Colors.white.withValues(alpha: 0.04) : AppColors.neutral50,
        prefixIcon: Icon(icon, size: 16),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: dark ? Colors.white10 : AppColors.neutral200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
        errorMaxLines: 2);
  }

  Widget _input(String key, String label, IconData icon,
          {TextInputType? keyboard}) =>
      _label(
          label,
          TextFormField(
              controller: _fields[key],
              keyboardType: keyboard,
              obscureText: key == 'password',
              enableSuggestions: key != 'password',
              autocorrect: key != 'password',
              style: GoogleFonts.inter(fontSize: 12),
              decoration: _decoration(icon),
              validator: (raw) {
                if (key == 'password') {
                  if (_editing && (raw ?? '').isEmpty) return null;
                  if ((raw ?? '').length < 8)
                    return 'Use at least 8 characters';
                  return null;
                }
                final value = (raw ?? '').trim();
                if (!['capacity', 'phone', 'address'].contains(key) &&
                    value.isEmpty) return 'Enter ${label.toLowerCase()}';
                if (key == 'email' &&
                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value))
                  return 'Enter a valid email';
                if (key == 'capacity' &&
                    value.isNotEmpty &&
                    (double.tryParse(value) == null ||
                        !double.parse(value).isFinite ||
                        double.parse(value) < 0)) {
                  return 'Enter a valid capacity';
                }
                return null;
              }));

  Widget _select(String label, String value, List<String> items, IconData icon,
          ValueChanged<String> onChanged) =>
      _label(
          label,
          DropdownButtonFormField<String>(
              value: value,
              isExpanded: true,
              style: GoogleFonts.inter(
                  fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
              decoration: _decoration(icon),
              // Retain an existing value that this admin cannot assign, without
              // adding it to their editable choices. Each value occurs once.
              items: {...items, value}
                  .map((item) => DropdownMenuItem(
                      value: item,
                      enabled: items.contains(item),
                      child: Text(item,
                          maxLines: 1, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: items.contains(value)
                  ? (value) {
                      if (value != null) onChanged(value);
                    }
                  : null));
}
