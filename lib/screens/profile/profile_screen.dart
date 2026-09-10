import '../../core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _api = SuperAdminApiService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_savingProfile || !_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _savingProfile = true);
    try {
      await _api.updateUserProfile(
        id: user.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
      );
      await ref.read(authProvider.notifier).updateCurrentUserProfile(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            address: _addressController.text.trim(),
          );
      _showMessage('Profile updated successfully', isError: false);
    } catch (error) {
      _showMessage(_messageFromError(error));
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    final user = ref.read(currentUserProvider);
    if (_savingPassword) return;
    final password = _newPasswordController.text;
    if (user == null) return;
    if (password.length < 8) {
      _showMessage('Use at least 8 characters for the new password.');
      return;
    }
    if (password != _confirmPasswordController.text) {
      _showMessage('The new passwords do not match.');
      return;
    }
    setState(() => _savingPassword = true);
    try {
      await _api.updateUserPassword(id: user.id, password: password);
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showMessage('Password changed successfully', isError: false);
    } catch (error) {
      _showMessage(_messageFromError(error));
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  String _messageFromError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    return message.isEmpty
        ? 'Something went wrong. Please try again.'
        : message;
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Color get _text => Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : AppColors.textPrimary;
  Color get _muted => Theme.of(context).brightness == Brightness.dark
      ? Colors.white54
      : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background =
        dark ? AppColors.backgroundDark : AppColors.backgroundLight;
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text('My profile',
            style: AppTypography.font(
                fontSize: AppTypography.sectionTitleSize, fontWeight: AppTypography.headingWeight, color: _text)),
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: background,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        ),
      ),
      body: user == null
          ? const Center(child: Text('Sign in to view your profile.'))
          : SafeArea(
              top: false,
              child: LayoutBuilder(builder: (context, viewport) {
                final compact = viewport.maxWidth < 760;
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                      compact ? 16 : 32, 8, compact ? 16 : 32, 16),
                  child: Center(
                      child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _identity(user, dark),
                          const SizedBox(height: 16),
                          LayoutBuilder(builder: (context, constraints) {
                            if (constraints.maxWidth < 760) {
                              return Column(children: [
                                _personal(dark),
                                const SizedBox(height: 16),
                                _security(dark),
                              ]);
                            }
                            return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 6, child: _personal(dark)),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 5, child: _security(dark)),
                                ]);
                          }),
                        ]),
                  )),
                );
              }),
            ),
    );
  }

  BoxDecoration _surface(bool dark) => BoxDecoration(
        color: dark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? Colors.white10 : AppColors.neutral200),
        boxShadow: [
          if (!dark)
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 16,
                offset: const Offset(0, 4))
        ],
      );

  Widget _identity(UserModel user, bool dark) {
    return Container(
      width: double.infinity,
      decoration: _surface(dark),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(user.initials,
                style: AppTypography.font(
                    fontSize: AppTypography.headingSize,
                    fontWeight: AppTypography.headingWeight,
                    color: Colors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(user.name,
                    style: AppTypography.font(
                        fontSize: AppTypography.headingSize,
                        fontWeight: AppTypography.headingWeight,
                        color: _text)),
                const SizedBox(height: 5),
                Text(user.email,
                    style: AppTypography.font(
                        fontSize: AppTypography.captionSize, height: 1.5, color: _muted)),
              ])),
        ]),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _detailChip(Icons.work_outline_rounded, user.role.displayName, dark),
          _detailChip(Icons.calendar_today_outlined,
              'Joined ${DateFormat('MMM yyyy').format(user.createdAt)}', dark),
        ]),
      ]),
    );
  }

  Widget _detailChip(IconData icon, String label, bool dark) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color:
              dark ? Colors.white.withValues(alpha: 0.04) : AppColors.neutral50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: _muted),
          const SizedBox(width: 6),
          Flexible(
              child: Text(label,
                  style: AppTypography.font(
                      fontSize: AppTypography.fieldLabelSize,
                      fontWeight: AppTypography.labelWeight,
                      color: _muted))),
        ]),
      );

  Widget _personal(bool dark) => _section(
        dark,
        Icons.person_outline_rounded,
        'Personal information',
        'Manage the details associated with your account.',
        Form(
            key: _formKey,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _field(_nameController, 'Full name', Icons.person_outline_rounded,
                  enabled: !_savingProfile,
                  validator: (value) => (value ?? '').trim().length < 2
                      ? 'Enter your full name'
                      : null),
              _field(_emailController, 'Email address',
                  Icons.alternate_email_rounded,
                  enabled: !_savingProfile,
                  keyboard: TextInputType.emailAddress,
                  validator: (value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                          .hasMatch((value ?? '').trim())
                      ? null
                      : 'Enter a valid email address'),
              _field(_addressController, 'Address', Icons.location_on_outlined,
                  enabled: !_savingProfile,
                  keyboard: TextInputType.streetAddress,
                  lines: 2),
              const SizedBox(height: 2),
              _action('Save changes', 'Saving changes…', Icons.check_rounded,
                  _savingProfile, _saveProfile),
            ])),
      );

  Widget _security(bool dark) => _section(
        dark,
        Icons.lock_outline_rounded,
        'Password & security',
        'Update your password to keep your account secure.',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _field(_currentPasswordController, 'Current password',
              Icons.lock_outline_rounded,
              enabled: !_savingPassword,
              obscure: _obscureCurrent,
              suffix: _visibility(_obscureCurrent,
                  () => setState(() => _obscureCurrent = !_obscureCurrent))),
          _field(_newPasswordController, 'New password', Icons.key_outlined,
              enabled: !_savingPassword,
              obscure: _obscureNew,
              suffix: _visibility(_obscureNew,
                  () => setState(() => _obscureNew = !_obscureNew))),
          _field(_confirmPasswordController, 'Confirm new password',
              Icons.key_outlined,
              enabled: !_savingPassword,
              obscure: _obscureConfirm,
              suffix: _visibility(_obscureConfirm,
                  () => setState(() => _obscureConfirm = !_obscureConfirm))),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text('Use at least 8 characters for your new password.',
                style: AppTypography.font(
                    fontSize: AppTypography.fieldLabelSize, height: 1.5, color: _muted)),
          ),
          _action('Update password', 'Updating password…',
              Icons.lock_reset_rounded, _savingPassword, _changePassword,
              outlined: true),
        ]),
      );

  Widget _visibility(bool obscure, VoidCallback action) => IconButton(
        tooltip: obscure ? 'Show password' : 'Hide password',
        onPressed: action,
        icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
            color: _muted),
      );

  Widget _section(bool dark, IconData icon, String title, String subtitle,
          Widget child) =>
      Container(
        width: double.infinity,
        decoration: _surface(dark),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon,
                  size: 18, color: dark ? Colors.white70 : AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: AppTypography.font(
                          fontSize: AppTypography.cardTitleSize,
                          fontWeight: AppTypography.headingWeight,
                          color: _text)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: AppTypography.font(
                          fontSize: AppTypography.captionSize, height: 1.5, color: _muted)),
                ])),
          ]),
          const SizedBox(height: 20),
          child,
        ]),
      );

  Widget _field(TextEditingController controller, String label, IconData icon,
      {bool enabled = true,
      bool obscure = false,
      int lines = 1,
      Widget? suffix,
      TextInputType? keyboard,
      String? Function(String?)? validator}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: AppTypography.font(
                fontSize: AppTypography.fieldLabelSize, fontWeight: AppTypography.headingWeight, color: _text)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          readOnly: !enabled,
          obscureText: obscure,
          maxLines: lines,
          keyboardType: keyboard,
          autocorrect: suffix == null,
          enableSuggestions: suffix == null,
          style: AppTypography.font(fontSize: AppTypography.captionSize, height: 1.5, color: _text),
          decoration: InputDecoration(
            filled: true,
            fillColor: dark
                ? Colors.white.withValues(alpha: 0.04)
                : AppColors.neutral50,
            prefixIcon: Icon(icon, size: 16, color: _muted),
            suffixIcon: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: dark ? Colors.white10 : AppColors.neutral200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
            errorMaxLines: 2,
          ),
        ),
      ]),
    );
  }

  Widget _action(String label, String loadingLabel, IconData icon, bool loading,
      VoidCallback onPressed,
      {bool outlined = false}) {
    final content = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (loading)
        const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2))
      else
        Icon(icon, size: 17),
      const SizedBox(width: 8),
      Flexible(
          child: Text(loading ? loadingLabel : label,
              textAlign: TextAlign.center)),
    ]);
    final style = ButtonStyle(
      padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 13)),
      textStyle: WidgetStatePropertyAll(
          AppTypography.font(fontSize: AppTypography.actionSize, fontWeight: AppTypography.headingWeight)),
      shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
    return SizedBox(
        width: double.infinity,
        child: outlined
            ? OutlinedButton(
                onPressed: loading ? null : onPressed,
                style: style,
                child: content)
            : FilledButton(
                onPressed: loading ? null : onPressed,
                style: style,
                child: content));
  }
}
