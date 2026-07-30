import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/widgets/technician_header.dart';
import '../../core/widgets/technician_mobile_bottom_nav.dart';
import '../../core/widgets/technician_sidebar.dart';
import '../../providers/auth_provider.dart';

class TechnicianSettingsScreen extends ConsumerStatefulWidget {
  const TechnicianSettingsScreen({super.key});

  @override
  ConsumerState<TechnicianSettingsScreen> createState() =>
      _TechnicianSettingsScreenState();
}

class _TechnicianSettingsScreenState
    extends ConsumerState<TechnicianSettingsScreen> {
  int _selectedNavIndex = 4;

  bool _pushAlerts = true;
  bool _smsAlerts = false;
  bool _criticalOnlyMode = false;
  bool _offlineDrafts = true;
  bool _biometricUnlock = false;

  static const _prefix = 'technician_settings';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _pushAlerts = prefs.getBool('$_prefix.pushAlerts') ?? true;
      _smsAlerts = prefs.getBool('$_prefix.smsAlerts') ?? false;
      _criticalOnlyMode = prefs.getBool('$_prefix.criticalOnlyMode') ?? false;
      _offlineDrafts = prefs.getBool('$_prefix.offlineDrafts') ?? true;
      _biometricUnlock = prefs.getBool('$_prefix.biometricUnlock') ?? false;
    });
  }

  Future<void> _setBool(String key, bool value, VoidCallback updater) async {
    setState(updater);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix.$key', value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final userName = authState.user?.name ?? 'Technician';
    final userEmail = authState.user?.email ?? 'technician@farmestates.com';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName, themeMode)
          : _buildDesktopLayout(isDark, userName, userEmail, themeMode),
      bottomNavigationBar: isMobile
          ? SafeArea(
              top: false,
              child: TechnicianMobileBottomNav(
                selectedIndex: _selectedNavIndex,
                onItemSelected: (index) =>
                    setState(() => _selectedNavIndex = index),
              ))
          : null,
    );
  }

  Widget _buildDesktopLayout(
    bool isDark,
    String userName,
    String userEmail,
    ThemeMode themeMode,
  ) {
    return Row(
      children: [
        TechnicianSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) => setState(() => _selectedNavIndex = index),
          userName: userName,
          userEmail: userEmail,
          userRole: 'Technician',
        ),
        Expanded(
          child: Column(
            children: [
              TechnicianHeader(userName: userName, onNotificationTap: () {}),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _buildContent(isDark, false, themeMode),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark, String userName, ThemeMode themeMode) {
    return Column(
      children: [
        TechnicianHeader(userName: userName, onNotificationTap: () {}),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              100,
            ),
            child: _buildContent(isDark, true, themeMode),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark, bool isMobile, ThemeMode themeMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Technician Settings',
          style: AppTypography.h4.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: isMobile ? 24 : 28,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Control alert behavior, display mode, and field-device preferences.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildSectionCard(
          isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Appearance', Icons.palette_outlined, isDark),
              const SizedBox(height: AppSpacing.md),
              _buildThemeTile(
                isDark,
                'Light mode',
                themeMode == ThemeMode.light,
                () =>
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildThemeTile(
                isDark,
                'Dark mode',
                themeMode == ThemeMode.dark,
                () => ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildSectionCard(
          isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                  'Alerts', Icons.notifications_outlined, isDark),
              const SizedBox(height: AppSpacing.md),
              _buildSwitchTile(
                isDark,
                'Push alerts',
                'Show device and maintenance alerts immediately',
                _pushAlerts,
                (value) =>
                    _setBool('pushAlerts', value, () => _pushAlerts = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSwitchTile(
                isDark,
                'SMS alerts',
                'Receive field alerts by text when offline',
                _smsAlerts,
                (value) =>
                    _setBool('smsAlerts', value, () => _smsAlerts = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSwitchTile(
                isDark,
                'Critical only mode',
                'Suppress low-priority notifications during active repairs',
                _criticalOnlyMode,
                (value) => _setBool(
                  'criticalOnlyMode',
                  value,
                  () => _criticalOnlyMode = value,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildSectionCard(
          isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                  'Device', Icons.phone_android_outlined, isDark),
              const SizedBox(height: AppSpacing.md),
              _buildSwitchTile(
                isDark,
                'Offline drafts',
                'Keep issue reports and inspections until sync returns',
                _offlineDrafts,
                (value) => _setBool(
                    'offlineDrafts', value, () => _offlineDrafts = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSwitchTile(
                isDark,
                'Biometric unlock',
                'Require device authentication before opening the app',
                _biometricUnlock,
                (value) => _setBool(
                  'biometricUnlock',
                  value,
                  () => _biometricUnlock = value,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
        ),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTypography.h6.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeTile(
    bool isDark,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(isDark ? 0.18 : 0.10)
              : (isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.35)
                : (isDark ? Colors.white12 : AppColors.neutral200),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? Colors.white70 : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    bool isDark,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
