import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

class ModernSettingsScreen extends ConsumerStatefulWidget {
  const ModernSettingsScreen({super.key});

  @override
  ConsumerState<ModernSettingsScreen> createState() =>
      _ModernSettingsScreenState();
}

class _ModernSettingsScreenState extends ConsumerState<ModernSettingsScreen> {
  final SuperAdminApiService _api = SuperAdminApiService();
  final TextEditingController _apiBaseUrlController = TextEditingController();
  final TextEditingController _webhookUrlController = TextEditingController();
  final TextEditingController _googleMapsKeyController =
      TextEditingController();

  Map<String, dynamic> _config = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String? _saveError;
  String? _saveMessage;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _apiBaseUrlController.dispose();
    _webhookUrlController.dispose();
    _googleMapsKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _saveError = null;
      _saveMessage = null;
    });

    try {
      final config = await _api.getSystemConfig();
      if (!mounted) return;
      _applyConfig(config);
      setState(() => _isLoading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  void _applyConfig(Map<String, dynamic> config) {
    _config = Map<String, dynamic>.from(config);
    _config['currency_code'] = 'GHS';
    _config['currency_symbol'] = 'GHS';
    _apiBaseUrlController.text = _string('api_base_url');
    _webhookUrlController.text = _string('webhook_url');
    _googleMapsKeyController.text = _string('google_maps_api_key');
  }

  Future<void> _saveConfig() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
      _saveMessage = null;
    });

    final user = ref.read(currentUserProvider);
    final payload = {
      ..._config,
      'currency_code': 'GHS',
      'currency_symbol': 'GHS',
      'api_base_url': _apiBaseUrlController.text.trim(),
      'webhook_url': _webhookUrlController.text.trim(),
      'google_maps_api_key': _googleMapsKeyController.text.trim(),
      'updated_by': user?.id ?? user?.email ?? 'admin',
    };

    try {
      final updated = await _api.updateSystemConfig(payload);
      if (!mounted) return;
      setState(() {
        _applyConfig(updated);
        _isSaving = false;
        _saveMessage = 'Settings saved to backend';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = error.toString();
      });
    }
  }

  bool _bool(String key, {bool fallback = false}) {
    final value = _config[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  int _int(String key, {int fallback = 0}) {
    final value = _config[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _double(String key, {double fallback = 0}) {
    final value = _config[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _string(String key, {String fallback = ''}) {
    final value = _config[key];
    return value?.toString() ?? fallback;
  }

  void _set(String key, Object? value) {
    setState(() {
      _config[key] = value;
      _saveError = null;
      _saveMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;
    final themeMode = ref.watch(themeProvider);
    final user = ref.watch(currentUserProvider);
    final userName = user?.name ?? 'Admin';

    return Scaffold(
      drawer: isMobile
          ? AdminDrawer(
              selectedIndex: 5,
              onItemSelected: (_) {},
              userName: userName,
              userEmail: user?.email ?? '',
              userRole: 'Administrator',
            )
          : null,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, themeMode, userName)
          : _buildDesktopLayout(isDark, themeMode, userName),
      bottomNavigationBar: isMobile
          ? AdminMobileBottomNav(selectedIndex: 5, onItemSelected: (_) {})
          : null,
    );
  }

  Widget _buildDesktopLayout(
    bool isDark,
    ThemeMode themeMode,
    String userName,
  ) {
    return Row(
      children: [
        ModernAdminSidebar(selectedIndex: 5, onItemSelected: (_) {}),
        Expanded(
          child: Column(
            children: [
              ModernAdminHeader(
                userName: userName.split(' ').first,
                onNotificationTap: () {},
                onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadConfig,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: _buildBody(isDark, themeMode, isMobile: false),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    bool isDark,
    ThemeMode themeMode,
    String userName,
  ) {
    return Column(
      children: [
        ModernAdminHeader(
          userName: userName.split(' ').first,
          onNotificationTap: () {},
          onProfileTap: () => Navigator.of(context).pushNamed('/profile'),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadConfig,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _buildBody(isDark, themeMode, isMobile: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    bool isDark,
    ThemeMode themeMode, {
    required bool isMobile,
  }) {
    if (_isLoading) return const AdminDataSkeleton(rowCount: 6);
    if (_loadError != null) return _buildError(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(isDark),
        const SizedBox(height: AppSpacing.lg),
        _buildStatusBanner(isDark),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 950;
            final left = Column(
              children: [
                _buildAppearanceSection(isDark, themeMode),
                const SizedBox(height: AppSpacing.lg),
                _buildNotificationSection(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildSecuritySection(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildSessionSection(isDark),
              ],
            );
            final right = Column(
              children: [
                _buildLocalizationSection(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildDataSection(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildMapsSection(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildApiSection(isDark),
              ],
            );
            if (!twoColumns) {
              return Column(
                children: [
                  left,
                  const SizedBox(height: AppSpacing.lg),
                  right,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: right),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildSaveBar(isDark),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: _cardDecoration(isDark).copyWith(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Settings',
                style: AppTypography.h4.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Backend-linked operational settings with Super Admin controls restricted.',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.64)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          _AccessPill(isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(bool isDark) {
    if (_saveError == null && _saveMessage == null) {
      return const SizedBox.shrink();
    }
    final isError = _saveError != null;
    final color = isError ? AppColors.error : AppColors.success;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _saveError ?? _saveMessage ?? '',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: _cardDecoration(isDark),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 44),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Settings could not be loaded',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _loadError ?? 'Unknown backend error',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.62)
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _loadConfig,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(bool isDark, ThemeMode themeMode) {
    return _SettingsCard(
      title: 'Appearance',
      subtitle: 'Local device display preference.',
      icon: Icons.palette_rounded,
      color: AppColors.primary,
      isDark: isDark,
      children: [
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_rounded, size: 16),
              label: Text('Light'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_rounded, size: 16),
              label: Text('Dark'),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.settings_suggest_rounded, size: 16),
              label: Text('Auto'),
            ),
          ],
          selected: {themeMode},
          onSelectionChanged: (_) {
            ref.read(themeProvider.notifier).toggleTheme();
          },
        ),
      ],
    );
  }

  Widget _buildNotificationSection(bool isDark) {
    return _SettingsCard(
      title: 'Notifications',
      subtitle: 'Saved to the system configuration backend.',
      icon: Icons.notifications_rounded,
      color: AppColors.info,
      isDark: isDark,
      children: [
        _switchRow(
          'Email Notifications',
          'Send operational updates by email.',
          _bool('email_notifications', fallback: true),
          (value) => _set('email_notifications', value),
          isDark,
        ),
        _switchRow(
          'SMS Notifications',
          'Send critical farm alerts by text message.',
          _bool('sms_notifications'),
          (value) => _set('sms_notifications', value),
          isDark,
        ),
      ],
    );
  }

  Widget _buildSecuritySection(bool isDark) {
    return _SettingsCard(
      title: 'Security',
      subtitle: 'Admin can manage operational security defaults.',
      icon: Icons.security_rounded,
      color: AppColors.error,
      isDark: isDark,
      children: [
        _switchRow(
          'Two-Factor Authentication',
          'Require additional login protection.',
          _bool('two_factor_auth', fallback: true),
          (value) => _set('two_factor_auth', value),
          isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _numberSlider(
          title: 'Password Length',
          subtitle: '${_int('password_min_length', fallback: 8)} characters',
          value: _int('password_min_length', fallback: 8).toDouble(),
          min: 6,
          max: 32,
          divisions: 26,
          onChanged: (value) => _set('password_min_length', value.round()),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildSessionSection(bool isDark) {
    return _SettingsCard(
      title: 'Session Settings',
      subtitle: 'Stored now; system-wide enforcement will be wired later.',
      icon: Icons.timer_rounded,
      color: AppColors.info,
      isDark: isDark,
      children: [
        _numberSlider(
          title: 'Session Timeout',
          subtitle: '${_int('session_timeout', fallback: 30)} minutes',
          value: _int('session_timeout', fallback: 30).toDouble(),
          min: 5,
          max: 1440,
          divisions: 287,
          onChanged: (value) => _set('session_timeout', value.round()),
          isDark: isDark,
        ),
        _numberSlider(
          title: 'Idle Warning',
          subtitle:
              '${_int('session_idle_warning_minutes', fallback: 5)} minutes before timeout',
          value: _int('session_idle_warning_minutes', fallback: 5).toDouble(),
          min: 1,
          max: 120,
          divisions: 119,
          onChanged: (value) =>
              _set('session_idle_warning_minutes', value.round()),
          isDark: isDark,
        ),
        _numberSlider(
          title: 'Max Concurrent Sessions',
          subtitle:
              '${_int('max_concurrent_sessions', fallback: 3)} active sessions per user',
          value: _int('max_concurrent_sessions', fallback: 3).toDouble(),
          min: 1,
          max: 20,
          divisions: 19,
          onChanged: (value) => _set('max_concurrent_sessions', value.round()),
          isDark: isDark,
        ),
        _switchRow(
          'Logout After Password Change',
          'End existing sessions after password update.',
          _bool('force_logout_on_password_change', fallback: true),
          (value) => _set('force_logout_on_password_change', value),
          isDark,
        ),
      ],
    );
  }

  Widget _buildLocalizationSection(bool isDark) {
    return _SettingsCard(
      title: 'Localization',
      subtitle: 'Currency is locked to Ghana cedis for this operation.',
      icon: Icons.public_rounded,
      color: AppColors.success,
      isDark: isDark,
      children: [
        _dropdownRow(
          label: 'Currency',
          value: 'GHS',
          items: const ['GHS'],
          onChanged: (_) {},
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.md),
        _infoRow('Currency Symbol', 'GHS', isDark),
        _infoRow(
          'Last Updated',
          _string('updated_at', fallback: 'Not saved yet'),
          isDark,
        ),
      ],
    );
  }

  Widget _buildDataSection(bool isDark) {
    return _SettingsCard(
      title: 'Data & Storage',
      subtitle: 'Storage limits and backup preference.',
      icon: Icons.storage_rounded,
      color: AppColors.warning,
      isDark: isDark,
      children: [
        _switchRow(
          'Auto Backup',
          'Allow scheduled backend backups.',
          _bool('auto_backup', fallback: true),
          (value) => _set('auto_backup', value),
          isDark,
        ),
        _numberSlider(
          title: 'Max Upload Size',
          subtitle: '${_int('max_upload_size', fallback: 50)} MB',
          value: _int('max_upload_size', fallback: 50).toDouble(),
          min: 1,
          max: 500,
          divisions: 499,
          onChanged: (value) => _set('max_upload_size', value.round()),
          isDark: isDark,
        ),
        _restrictedAction(
          'Backup & restore actions are controlled by Super Admin.',
          isDark,
        ),
      ],
    );
  }

  Widget _buildMapsSection(bool isDark) {
    return _SettingsCard(
      title: 'Google Maps',
      subtitle: 'Default map settings used by farm location views.',
      icon: Icons.map_rounded,
      color: AppColors.info,
      isDark: isDark,
      children: [
        _switchRow(
          'Enable Google Maps',
          'Use map views where location data exists.',
          _bool('google_maps_enabled'),
          (value) => _set('google_maps_enabled', value),
          isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _textField(
          controller: _googleMapsKeyController,
          label: 'Google Maps API Key',
          hint: 'Managed key for map services',
          icon: Icons.key_rounded,
          isDark: isDark,
          obscure: true,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _numberField(
                label: 'Latitude',
                value: _double('google_maps_default_lat', fallback: 5.6037),
                onChanged: (value) => _set('google_maps_default_lat', value),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _numberField(
                label: 'Longitude',
                value: _double('google_maps_default_lng', fallback: -0.1870),
                onChanged: (value) => _set('google_maps_default_lng', value),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _numberSlider(
          title: 'Default Zoom',
          subtitle: '${_int('google_maps_default_zoom', fallback: 10)}',
          value: _int('google_maps_default_zoom', fallback: 10).toDouble(),
          min: 1,
          max: 22,
          divisions: 21,
          onChanged: (value) => _set('google_maps_default_zoom', value.round()),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildApiSection(bool isDark) {
    return _SettingsCard(
      title: 'API Access',
      subtitle:
          'Admin can view service endpoints; key rotation stays restricted.',
      icon: Icons.api_rounded,
      color: AppColors.primary,
      isDark: isDark,
      children: [
        _textField(
          controller: _apiBaseUrlController,
          label: 'API Base URL',
          hint: 'https://api.farmestates.com',
          icon: Icons.link_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.md),
        _textField(
          controller: _webhookUrlController,
          label: 'Webhook URL',
          hint: 'https://hooks.farmestates.com',
          icon: Icons.webhook_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.md),
        _numberSlider(
          title: 'API Rate Limit',
          subtitle: '${_int('api_rate_limit', fallback: 1000)} req/min',
          value: _int('api_rate_limit', fallback: 1000).toDouble(),
          min: 10,
          max: 10000,
          divisions: 999,
          onChanged: (value) => _set('api_rate_limit', value.round()),
          isDark: isDark,
        ),
        _restrictedAction(
          'Sensor ingestion API key generation is Super Admin only.',
          isDark,
        ),
      ],
    );
  }

  Widget _buildSaveBar(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Changes are written to Appwrite through the FastAPI backend.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.64)
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _loadConfig,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reload'),
              ),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveConfig,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _switchRow(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _rowText(title, subtitle, isDark),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _numberSlider({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rowText(title, subtitle, isDark),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _dropdownRow({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : items.first,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      decoration: _inputDecoration(label, Icons.paid_rounded, isDark),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration:
          _inputDecoration(label, icon, isDark).copyWith(hintText: hint),
    );
  }

  Widget _numberField({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required bool isDark,
  }) {
    return TextFormField(
      initialValue: value.toStringAsFixed(4),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
      ],
      decoration: _inputDecoration(label, Icons.location_on_rounded, isDark),
      onChanged: (raw) {
        final parsed = double.tryParse(raw);
        if (parsed != null) onChanged(parsed);
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      filled: true,
      fillColor:
          isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.neutral50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : AppColors.neutral300,
        ),
      ),
    );
  }

  Widget _rowText(String title, String subtitle, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: isDark
                ? Colors.white.withValues(alpha: 0.58)
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.64)
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _restrictedAction(String text, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: AppColors.warning, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    const navItems = [
      _MobileNavItem(Icons.dashboard_outlined, 'Dashboard', '/dashboard'),
      _MobileNavItem(Icons.people_outline, 'Users', '/users'),
      _MobileNavItem(Icons.agriculture_outlined, 'Farms', '/farms'),
      _MobileNavItem(Icons.sensors_outlined, 'Sensors', '/sensors'),
      _MobileNavItem(Icons.analytics_outlined, 'Analytics', '/analytics'),
      _MobileNavItem(Icons.settings_outlined, 'Settings', '/settings'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.neutral300,
          ),
        ),
      ),
      child: Row(
        children: navItems.map((item) {
          final selected = item.label == 'Settings';
          return Expanded(
            child: InkWell(
              onTap: () {
                if (!selected) {
                  Navigator.pushReplacementNamed(context, item.route);
                }
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: selected
                          ? AppColors.primary
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.62)
                              : AppColors.textSecondary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        color: selected
                            ? AppColors.primary
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.62)
                                : AppColors.textSecondary),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.58)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}

class _AccessPill extends StatelessWidget {
  const _AccessPill({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.manage_accounts_rounded,
              color: AppColors.primary, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Admin 90% Control',
            style: AppTypography.label.copyWith(
              color: isDark ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration(bool isDark) {
  return BoxDecoration(
    color: isDark ? AppColors.surfaceDark : Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : AppColors.neutral300.withValues(alpha: 0.72),
    ),
    boxShadow: [
      if (!isDark)
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 20,
          offset: const Offset(0, 12),
        ),
    ],
  );
}

class _MobileNavItem {
  const _MobileNavItem(this.icon, this.label, this.route);

  final IconData icon;
  final String label;
  final String route;
}
