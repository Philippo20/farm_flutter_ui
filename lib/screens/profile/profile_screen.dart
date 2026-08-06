import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
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
    if (!_formKey.currentState!.validate()) return;
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
    return message.isEmpty ? 'Something went wrong. Please try again.' : message;
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No active profile')));
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: isDark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _profileHero(user, isDark),
                  const SizedBox(height: AppSpacing.lg),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 760;
                      final profile = _profileCard(user, isDark);
                      final security = _securityCard(isDark);
                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: profile),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: security),
                          ],
                        );
                      }
                      return Column(children: [profile, security]);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _accessCard(user, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileHero(UserModel user, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white.withOpacity(0.18),
            child: Text(
              user.initials,
              style: AppTypography.h4.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h4.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium
                        .copyWith(color: Colors.white.withOpacity(0.86))),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(user.role.displayName,
                      style: AppTypography.caption.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Icon(Icons.verified_user_outlined,
              color: Colors.white.withOpacity(0.85), size: 28),
        ],
      ),
    );
  }

  Widget _profileCard(UserModel user, bool isDark) {
    return _card(
      isDark,
      title: 'Personal information',
      subtitle: 'Keep your account details current.',
      icon: Icons.badge_outlined,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _field(_nameController, 'Full name', Icons.person_outline,
                validator: (value) => value!.trim().length < 2
                    ? 'Enter your full name'
                    : null),
            const SizedBox(height: AppSpacing.sm),
            _field(_emailController, 'Email address', Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.contains('@')
                    ? null
                    : 'Enter a valid email address'),
            const SizedBox(height: AppSpacing.sm),
            _field(_addressController, 'Address', Icons.location_on_outlined),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _savingProfile ? null : _saveProfile,
                icon: _savingProfile
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _securityCard(bool isDark) {
    return _card(
      isDark,
      title: 'Security',
      subtitle: 'Protect access to your Farm Estates account.',
      icon: Icons.lock_outline,
      child: Column(
        children: [
          _field(_currentPasswordController, 'Current password', Icons.lock,
              obscureText: _obscureCurrent,
              suffix: IconButton(
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  icon: Icon(_obscureCurrent ? Icons.visibility : Icons.visibility_off))),
          const SizedBox(height: AppSpacing.sm),
          _field(_newPasswordController, 'New password', Icons.password,
              obscureText: _obscureNew,
              suffix: IconButton(
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off))),
          const SizedBox(height: AppSpacing.sm),
          _field(_confirmPasswordController, 'Confirm new password', Icons.password,
              obscureText: _obscureConfirm,
              suffix: IconButton(
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off))),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _savingPassword ? null : _changePassword,
              icon: _savingPassword
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.key_outlined),
              label: const Text('Change password'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accessCard(UserModel user, bool isDark) {
    return _card(
      isDark,
      title: 'Account access',
      subtitle: 'Your role and account identity used across the platform.',
      icon: Icons.admin_panel_settings_outlined,
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          _fact('Role', user.role.displayName, Icons.work_outline, isDark),
          _fact('User ID', user.id, Icons.fingerprint, isDark),
          _fact('Member since', _date(user.createdAt), Icons.calendar_today_outlined, isDark),
          _fact('Status', 'Active session', Icons.circle, isDark),
        ],
      ),
    );
  }

  String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  Widget _card(bool isDark,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(title, style: AppTypography.h6.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon,
      {String? Function(String?)? validator,
      TextInputType? keyboardType,
      bool obscureText = false,
      Widget? suffix}) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _fact(String label, String value, IconData icon, bool isDark) {
    return SizedBox(
      width: 210,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: AppTypography.caption.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary)),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
    );
  }
}
