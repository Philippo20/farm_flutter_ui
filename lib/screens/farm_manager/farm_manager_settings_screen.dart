import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_manager_sidebar.dart';
import '../../core/widgets/farm_manager_header.dart';
import '../../core/widgets/farm_manager_mobile_drawer.dart';
import '../../core/widgets/adaptive_logout_confirmation.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Farm Manager Settings Screen
/// Personal preferences, notifications, farm defaults, and account settings
class FarmManagerSettingsScreen extends ConsumerStatefulWidget {
  const FarmManagerSettingsScreen({super.key});

  @override
  ConsumerState<FarmManagerSettingsScreen> createState() =>
      _FarmManagerSettingsScreenState();
}

class _FarmManagerSettingsScreenState
    extends ConsumerState<FarmManagerSettingsScreen> {
  final SuperAdminApiService _api = SuperAdminApiService();
  int _selectedNavIndex = 9;
  final _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Map<String, dynamic>> _farms = [];
  Map<String, dynamic> _systemConfig = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // ── Settings State ──────────────────────────────────────────────────────

  // Notifications
  bool _batchAlerts = true;
  bool _harvestReminders = true;
  bool _deliveryUpdates = true;
  bool _fundRequestUpdates = true;
  bool _teamUpdates = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;

  // Farm Defaults
  String _defaultFarm = 'All Farms';
  String _currency = 'GHS (Ghana Cedi)';
  String _weightUnit = 'Kilograms (kg)';
  String _dateFormat = 'DD/MM/YYYY';

  // Security
  bool _twoFactorAuth = false;
  bool _biometricLogin = false;
  bool _sessionTimeout = true;

  // Display
  bool _compactView = false;
  bool _showWeather = true;
  bool _showQuickActions = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  String _value(Map<String, dynamic> doc, List<String> keys,
      {String fallback = ''}) {
    for (final key in keys) {
      final value = doc[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  bool _boolValue(Map<String, dynamic> doc, String key, bool fallback) {
    final value = doc[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  bool _isCurrentManagerFarm(Map<String, dynamic> farm) {
    final user = ref.read(authProvider).user;
    if (user == null) return true;
    final manager = _value(farm, ['farm_manager_id', 'farmManagerId']);
    return manager.isEmpty ||
        manager == 'Unassigned' ||
        manager == user.id ||
        manager == user.email ||
        manager == user.name;
  }

  List<String> get _farmOptions {
    final names = _farms
        .where(_isCurrentManagerFarm)
        .map((farm) => _value(farm, ['name', 'farm_name'], fallback: 'Farm'))
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All Farms', ...names];
  }

  String _currencyLabel(String code) {
    switch (code) {
      case 'USD':
        return 'USD (US Dollar)';
      case 'EUR':
        return 'EUR (Euro)';
      case 'GBP':
        return 'GBP (British Pound)';
      case 'GHS':
      default:
        return 'GHS (Ghana Cedi)';
    }
  }

  String _currencyCode(String label) => label.split(' ').first;

  int get _sessionTimeoutMinutes {
    final value = _systemConfig['session_timeout'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '30') ?? 30;
  }

  void _applySystemConfig(Map<String, dynamic> config) {
    _systemConfig = Map<String, dynamic>.from(config);
    _emailNotifications =
        _boolValue(config, 'email_notifications', _emailNotifications);
    _smsNotifications =
        _boolValue(config, 'sms_notifications', _smsNotifications);
    _twoFactorAuth = _boolValue(config, 'two_factor_auth', _twoFactorAuth);
    _sessionTimeout = _sessionTimeoutMinutes > 0;
    _currency = _currencyLabel(
      _value(config, ['currency_code'], fallback: 'GHS'),
    );
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final config = await _api.getSystemConfig();
      final farms = await _api.getFarms();
      if (!mounted) return;
      setState(() {
        _applySystemConfig(config);
        _farms
          ..clear()
          ..addAll(farms);
        if (!_farmOptions.contains(_defaultFarm)) {
          _defaultFarm = _farmOptions.first;
        }
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSystemConfig(Map<String, dynamic> patch) async {
    final user = ref.read(authProvider).user;
    setState(() => _isSaving = true);
    try {
      final updated = await _api.updateSystemConfig({
        ..._systemConfig,
        ...patch,
        'updated_by': user?.id ?? user?.email ?? 'farm_manager',
      });
      if (!mounted) return;
      setState(() {
        _applySystemConfig(updated);
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save settings: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Farm Manager';
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? FarmManagerMobileDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (i) => setState(() => _selectedNavIndex = i),
              userName: userName,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName, themeMode)
          : _buildDesktopLayout(isDark, userName, themeMode),
    );
  }

  Widget _buildDesktopLayout(
      bool isDark, String userName, ThemeMode themeMode) {
    final authState = ref.watch(authProvider);
    return Row(
      children: [
        FarmManagerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (i) => setState(() => _selectedNavIndex = i),
          userName: userName,
          userEmail: authState.user?.email ?? '',
          userRole: 'Farm Manager',
        ),
        Expanded(
          child: Column(
            children: [
              FarmManagerHeader(userName: userName),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.xl),
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
        FarmManagerHeader(
          userName: userName,
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildContent(isDark, true, themeMode),
          ),
        ),
        FarmManagerMobileBottomNav(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) => setState(() => _selectedNavIndex = index),
        ),
      ],
    );
  }

  // ── Content ─────────────────────────────────────────────────────────────

  Widget _buildContent(bool isDark, bool isMobile, ThemeMode themeMode) {
    if (_isLoading) {
      return const AdminDataSkeleton(rowCount: 6);
    }
    if (_errorMessage != null) {
      return _buildErrorState(isDark);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(isDark, isMobile),
        SizedBox(height: isMobile ? 0 : 24),
        if (isMobile) ...[
          _buildProfileSection(isDark, isMobile),
          const SizedBox(height: 16),
          _buildAppearanceSection(isDark, isMobile, themeMode),
          const SizedBox(height: 16),
          _buildFarmDefaultsSection(isDark, isMobile),
          const SizedBox(height: 16),
          _buildNotificationsSection(isDark, isMobile),
          const SizedBox(height: 16),
          _buildDisplaySection(isDark, isMobile),
          const SizedBox(height: 16),
          _buildSecuritySection(isDark, isMobile),
          const SizedBox(height: 16),
          _buildDangerZone(isDark, isMobile),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildProfileSection(isDark, isMobile),
                    const SizedBox(height: 20),
                    _buildAppearanceSection(isDark, isMobile, themeMode),
                    const SizedBox(height: 20),
                    _buildNotificationsSection(isDark, isMobile),
                    const SizedBox(height: 20),
                    _buildDangerZone(isDark, isMobile),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildFarmDefaultsSection(isDark, isMobile),
                    const SizedBox(height: 20),
                    _buildDisplaySection(isDark, isMobile),
                    const SizedBox(height: 20),
                    _buildSecuritySection(isDark, isMobile),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Page Header ─────────────────────────────────────────────────────────

  Widget _buildPageHeader(bool isDark, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your preferences and account settings',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 13 : 14,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (_isSaving) ...[
          const SizedBox(width: 12),
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 42, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Unable to load settings',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadSettings,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Profile Section ─────────────────────────────────────────────────────

  Widget _buildProfileSection(bool isDark, bool isMobile) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final name = user?.name ?? 'Farm Manager';
    final email = user?.email ?? 'manager@farmestates.com';
    final initials = name
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return _sectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Profile', Icons.person_rounded, isDark),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Farm Manager',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Edit profile coming soon'),
                        backgroundColor: AppColors.info,
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? Colors.white70 : AppColors.textPrimary,
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.12)
                          : AppColors.neutral300,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Change password coming soon'),
                        backgroundColor: AppColors.info,
                      ),
                    );
                  },
                  icon: const Icon(Icons.lock_outline, size: 16),
                  label: const Text('Password'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? Colors.white70 : AppColors.textPrimary,
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.12)
                          : AppColors.neutral300,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Appearance Section ──────────────────────────────────────────────────

  Widget _buildAppearanceSection(
      bool isDark, bool isMobile, ThemeMode themeMode) {
    return _sectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Appearance', Icons.palette_rounded, isDark),
          const SizedBox(height: 16),
          Text(
            'Theme',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _themeOption(
                label: 'Light',
                icon: Icons.light_mode_rounded,
                isSelected: themeMode == ThemeMode.light,
                isDark: isDark,
                onTap: () =>
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
              ),
              const SizedBox(width: 10),
              _themeOption(
                label: 'Dark',
                icon: Icons.dark_mode_rounded,
                isSelected: themeMode == ThemeMode.dark,
                isDark: isDark,
                onTap: () =>
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
              ),
              const SizedBox(width: 10),
              _themeOption(
                label: 'System',
                icon: Icons.settings_brightness_rounded,
                isSelected: themeMode == ThemeMode.system,
                isDark: isDark,
                onTap: () =>
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.system),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _themeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : (isDark
                    ? Colors.white.withOpacity(0.04)
                    : AppColors.neutral50),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                      ? Colors.white.withOpacity(0.08)
                      : AppColors.neutral200),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white54 : AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white54 : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Farm Defaults Section ───────────────────────────────────────────────

  Widget _buildFarmDefaultsSection(bool isDark, bool isMobile) {
    return _sectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Farm Defaults', Icons.agriculture_rounded, isDark),
          const SizedBox(height: 16),
          _dropdownSetting(
            label: 'Default Farm',
            value: _defaultFarm,
            options: _farmOptions,
            isDark: isDark,
            onChanged: (v) {
              if (v != null) setState(() => _defaultFarm = v);
            },
          ),
          const SizedBox(height: 14),
          _dropdownSetting(
            label: 'Currency',
            value: _currency,
            options: const [
              'GHS (Ghana Cedi)',
              'USD (US Dollar)',
              'EUR (Euro)',
              'GBP (British Pound)',
            ],
            isDark: isDark,
            onChanged: (v) {
              if (v == null) return;
              setState(() => _currency = v);
              _saveSystemConfig({
                'currency_code': _currencyCode(v),
                'currency_symbol': _currencyCode(v),
              });
            },
          ),
          const SizedBox(height: 14),
          _dropdownSetting(
            label: 'Weight Unit',
            value: _weightUnit,
            options: const ['Kilograms (kg)', 'Pounds (lbs)', 'Tonnes (t)'],
            isDark: isDark,
            onChanged: (v) {
              if (v != null) setState(() => _weightUnit = v);
            },
          ),
          const SizedBox(height: 14),
          _dropdownSetting(
            label: 'Date Format',
            value: _dateFormat,
            options: const ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
            isDark: isDark,
            onChanged: (v) {
              if (v != null) setState(() => _dateFormat = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _dropdownSetting({
    required String label,
    required String value,
    required List<String> options,
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color:
                isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : AppColors.neutral200,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isDark ? Colors.white38 : AppColors.textSecondary,
              ),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // ── Notifications Section ───────────────────────────────────────────────

  Widget _buildNotificationsSection(bool isDark, bool isMobile) {
    return _sectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Notifications', Icons.notifications_rounded, isDark),
          const SizedBox(height: 12),
          Text(
            'ALERT TYPES',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white38 : AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          _switchTile(
              'Batch Status Alerts',
              'Get notified when batch status changes',
              Icons.layers_rounded,
              _batchAlerts,
              (v) => setState(() => _batchAlerts = v),
              isDark),
          _switchTile(
              'Harvest Reminders',
              'Reminders for upcoming harvest dates',
              Icons.agriculture_rounded,
              _harvestReminders,
              (v) => setState(() => _harvestReminders = v),
              isDark),
          _switchTile(
              'Delivery Updates',
              'Track delivery status in real-time',
              Icons.local_shipping_rounded,
              _deliveryUpdates,
              (v) => setState(() => _deliveryUpdates = v),
              isDark),
          _switchTile(
              'Fund Request Updates',
              'Notifications for fund request approvals',
              Icons.payments_rounded,
              _fundRequestUpdates,
              (v) => setState(() => _fundRequestUpdates = v),
              isDark),
          _switchTile(
              'Team Updates',
              'Activity from your team members',
              Icons.groups_rounded,
              _teamUpdates,
              (v) => setState(() => _teamUpdates = v),
              isDark),
          const SizedBox(height: 16),
          Divider(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : AppColors.neutral200),
          const SizedBox(height: 12),
          Text(
            'CHANNELS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white38 : AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          _switchTile('Email', 'Receive notifications via email',
              Icons.email_rounded, _emailNotifications, (v) {
            setState(() => _emailNotifications = v);
            _saveSystemConfig({'email_notifications': v});
          }, isDark),
          _switchTile(
              'Push Notifications',
              'Mobile push notifications',
              Icons.phone_android_rounded,
              _pushNotifications,
              (v) => setState(() => _pushNotifications = v),
              isDark),
          _switchTile('SMS', 'Text message alerts for critical events',
              Icons.sms_rounded, _smsNotifications, (v) {
            setState(() => _smsNotifications = v);
            _saveSystemConfig({'sms_notifications': v});
          }, isDark),
        ],
      ),
    );
  }

  // ── Display Section ─────────────────────────────────────────────────────

  Widget _buildDisplaySection(bool isDark, bool isMobile) {
    return _sectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
              'Dashboard Display', Icons.dashboard_customize_rounded, isDark),
          const SizedBox(height: 12),
          _switchTile(
              'Compact View',
              'Use compact layout for tables and lists',
              Icons.view_compact_rounded,
              _compactView,
              (v) => setState(() => _compactView = v),
              isDark),
          _switchTile(
              'Show Weather',
              'Display weather information on dashboard',
              Icons.cloud_rounded,
              _showWeather,
              (v) => setState(() => _showWeather = v),
              isDark),
          _switchTile(
              'Quick Actions',
              'Show quick action cards on dashboard',
              Icons.flash_on_rounded,
              _showQuickActions,
              (v) => setState(() => _showQuickActions = v),
              isDark),
        ],
      ),
    );
  }

  // ── Security Section ────────────────────────────────────────────────────

  Widget _buildSecuritySection(bool isDark, bool isMobile) {
    return _sectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Security', Icons.shield_rounded, isDark),
          const SizedBox(height: 12),
          _switchTile(
              'Two-Factor Authentication',
              'Add an extra layer of security',
              Icons.security_rounded,
              _twoFactorAuth, (v) {
            setState(() => _twoFactorAuth = v);
            _saveSystemConfig({'two_factor_auth': v});
          }, isDark),
          _switchTile(
              'Biometric Login',
              'Use fingerprint or face ID to login',
              Icons.fingerprint_rounded,
              _biometricLogin,
              (v) => setState(() => _biometricLogin = v),
              isDark),
          _switchTile(
              'Session Timeout',
              'Auto logout after $_sessionTimeoutMinutes min of inactivity',
              Icons.timer_rounded,
              _sessionTimeout, (v) {
            setState(() => _sessionTimeout = v);
            _saveSystemConfig({'session_timeout': v ? 30 : 1440});
          }, isDark),
        ],
      ),
    );
  }

  // ── Danger Zone ─────────────────────────────────────────────────────────

  Widget _buildDangerZone(bool isDark, bool isMobile) {
    return _sectionCard(
      isDark: isDark,
      borderColor: AppColors.error.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Danger Zone', Icons.warning_amber_rounded, isDark,
              color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            'These actions are irreversible. Please proceed with caution.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white38 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showConfirmDialog(
                    'Clear Cache',
                    'This will clear all cached data. You may need to reload some information.',
                    Icons.cached_rounded,
                    AppColors.warning,
                    () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: const Text('Cache cleared successfully'),
                            backgroundColor: AppColors.success),
                      );
                    },
                  ),
                  icon: Icon(Icons.cached_rounded,
                      size: 16, color: AppColors.warning),
                  label: Text('Clear Cache',
                      style: TextStyle(color: AppColors.warning)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.warning.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showConfirmDialog(
                    'Logout',
                    'Are you sure you want to logout from your account?',
                    Icons.logout_rounded,
                    AppColors.error,
                    () async {
                      Navigator.pop(context);
                      await ref.read(authProvider.notifier).logout();
                      if (mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login', (route) => false);
                      }
                    },
                  ),
                  icon: Icon(Icons.logout_rounded,
                      size: 16, color: AppColors.error),
                  label:
                      Text('Logout', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmDialog(
    String title,
    String message,
    IconData icon,
    Color color,
    VoidCallback onConfirm,
  ) async {
    if (title == 'Logout') {
      final confirmed = await showAdaptiveLogoutConfirmation(
        context,
        message: message,
      );
      if (confirmed) {
        onConfirm();
      }
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.white70 : AppColors.textSecondary,
                        side: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.12)
                                : AppColors.neutral300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared Widgets ──────────────────────────────────────────────────────

  Widget _sectionCard(
      {required bool isDark, required Widget child, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ??
              (isDark ? Colors.white.withOpacity(0.06) : AppColors.neutral200),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(String title, IconData icon, bool isDark,
      {Color? color}) {
    final c = color ?? AppColors.primary;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: c),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _switchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : AppColors.neutral100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon,
                      size: 16,
                      color: isDark ? Colors.white54 : AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color:
                              isDark ? Colors.white38 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom Navigation ───────────────────────────────────────────────────

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/farm-manager'
      },
      {
        'icon': Icons.agriculture_outlined,
        'label': 'Farms',
        'index': 1,
        'route': '/farm-manager/farms'
      },
      {
        'icon': Icons.inventory_2_outlined,
        'label': 'Inventory',
        'index': 2,
        'route': '/farm-manager/inventory'
      },
      {
        'icon': Icons.local_shipping_outlined,
        'label': 'Deliveries',
        'index': 3,
        'route': '/farm-manager/deliveries'
      },
      {
        'icon': Icons.assessment_outlined,
        'label': 'Reports',
        'index': 4,
        'route': '/farm-manager/reports'
      },
      {
        'icon': Icons.settings_outlined,
        'label': 'Settings',
        'index': 8,
        'route': '/farm-manager/settings'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
        border: Border(
            top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08),
                width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final isSelected = index == _selectedNavIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_selectedNavIndex != index) {
                        setState(() => _selectedNavIndex = index);
                        try {
                          Navigator.pushReplacementNamed(context, route);
                        } catch (e) {
                          Navigator.pushNamed(context, route);
                        }
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 24,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : AppColors.textSecondary),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
