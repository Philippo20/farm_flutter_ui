import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/fulfillment_manager_screen_shell.dart';

class FulfillmentSettingsScreen extends ConsumerStatefulWidget {
  const FulfillmentSettingsScreen({super.key});

  @override
  ConsumerState<FulfillmentSettingsScreen> createState() =>
      _FulfillmentSettingsScreenState();
}

class _FulfillmentSettingsScreenState
    extends ConsumerState<FulfillmentSettingsScreen> {
  static const _prefix = 'fulfillment_settings';

  bool _pushAlerts = true;
  bool _dockEscalations = true;
  bool _autoReorderDrafts = false;

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
      _dockEscalations = prefs.getBool('$_prefix.dockEscalations') ?? true;
      _autoReorderDrafts = prefs.getBool('$_prefix.autoReorderDrafts') ?? false;
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
    final themeMode = ref.watch(themeProvider);

    return FulfillmentManagerScreenShell(
      selectedIndex: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fulfillment Settings',
            style: AppTypography.h4.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Control fulfillment alerts, material automation, and display preferences.',
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildCard(
            isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Appearance', Icons.palette_outlined, isDark),
                const SizedBox(height: AppSpacing.md),
                _themeTile(
                  isDark,
                  'Light mode',
                  themeMode == ThemeMode.light,
                  () => ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
                ),
                const SizedBox(height: AppSpacing.sm),
                _themeTile(
                  isDark,
                  'Dark mode',
                  themeMode == ThemeMode.dark,
                  () => ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildCard(
            isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Operations', Icons.tune_outlined, isDark),
                const SizedBox(height: AppSpacing.md),
                _switchTile(
                  isDark,
                  'Push alerts',
                  'Notify immediately when harvest intake status changes',
                  _pushAlerts,
                  (value) => _setBool('pushAlerts', value, () => _pushAlerts = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                _switchTile(
                  isDark,
                  'Dock escalations',
                  'Escalate overdue dock confirmations automatically',
                  _dockEscalations,
                  (value) => _setBool(
                    'dockEscalations',
                    value,
                    () => _dockEscalations = value,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _switchTile(
                  isDark,
                  'Auto reorder drafts',
                  'Draft low-stock material requests before supervisor approval',
                  _autoReorderDrafts,
                  (value) => _setBool(
                    'autoReorderDrafts',
                    value,
                    () => _autoReorderDrafts = value,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTypography.bodyLarge.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _themeTile(
    bool isDark,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.10)
              : (isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: selected
                ? AppColors.primary.withOpacity(0.28)
                : (isDark ? Colors.white10 : AppColors.neutral200),
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
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchTile(
    bool isDark,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
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
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Switch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
