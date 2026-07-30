import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/adaptive_logout_confirmation.dart';
import '../../core/widgets/farm_owner_header.dart';
import '../../core/widgets/farm_owner_mobile_drawer.dart';
import '../../core/widgets/farm_owner_sidebar.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Settings Screen for Farm Owner
/// Manage account details, preferences, and owner-specific defaults.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final SuperAdminApiService _api = SuperAdminApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final _profileFormKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  int _selectedNavIndex = 5;
  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isSavingConfig = false;
  String? _errorMessage;
  String? _profileError;
  Map<String, dynamic>? _currentUserDoc;
  Map<String, dynamic> _systemConfig = {};

  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  bool _farmUpdates = true;
  bool _walletAlerts = true;
  bool _reportDigest = false;
  bool _sessionTimeout = true;
  String _currency = 'GHS (Ghana Cedi)';
  String _dateFormat = 'DD/MM/YYYY';
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _value(Map<String, dynamic>? doc, List<String> keys,
      {String fallback = ''}) {
    if (doc == null) return fallback;
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

  String _currencyLabel(String code) {
    switch (code.toUpperCase()) {
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

  String get _userId => _value(_currentUserDoc, const ['id', r'$id']);
  String get _userName => _nameController.text.trim().isNotEmpty
      ? _nameController.text.trim()
      : 'Farm Owner';
  String get _userEmail => _emailController.text.trim();
  String get _userRole =>
      _value(_currentUserDoc, const ['role'], fallback: 'farm_owner');
  String get _userStatus =>
      _value(_currentUserDoc, const ['status'], fallback: 'Active');
  String get _userDepartment =>
      _value(_currentUserDoc, const ['department'], fallback: 'Farm Owner');

  void _applySystemConfig(Map<String, dynamic> config) {
    _systemConfig = Map<String, dynamic>.from(config);
    _emailNotifications =
        _boolValue(config, 'email_notifications', _emailNotifications);
    _smsNotifications =
        _boolValue(config, 'sms_notifications', _smsNotifications);
    _sessionTimeout = _sessionTimeoutMinutes > 0;
    _currency = _currencyLabel(
        _value(config, const ['currency_code'], fallback: 'GHS'));
  }

  void _populateProfile(Map<String, dynamic> userDoc) {
    final authUser = ref.read(authProvider).user;
    _nameController.text = _value(userDoc, const ['name'],
        fallback: authUser?.name ?? 'Farm Owner');
    _emailController.text =
        _value(userDoc, const ['email'], fallback: authUser?.email ?? '');
    _phoneController.text = _value(userDoc, const ['phone']);
    _addressController.text =
        _value(userDoc, const ['address'], fallback: authUser?.address ?? '');
  }

  Map<String, dynamic>? _findCurrentUser(List<Map<String, dynamic>> users) {
    final authUser = ref.read(authProvider).user;
    if (authUser == null) return null;
    for (final user in users) {
      final id = _value(user, const ['id', r'$id']);
      if (id == authUser.id) return user;
    }
    for (final user in users) {
      if (_value(user, const ['email']).toLowerCase() ==
          authUser.email.toLowerCase()) {
        return user;
      }
    }
    return null;
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _profileError = null;
    });

    try {
      final results = await Future.wait([
        _api.getUsers(),
        _api.getSystemConfig(),
      ]);
      final users = results[0] as List<Map<String, dynamic>>;
      final config = results[1] as Map<String, dynamic>;
      final userDoc = _findCurrentUser(users);
      if (userDoc == null) {
        throw const SuperAdminApiException(
          'Your user profile was not found in the backend users collection.',
        );
      }
      if (!mounted) return;
      setState(() {
        _currentUserDoc = Map<String, dynamic>.from(userDoc);
        _populateProfile(_currentUserDoc!);
        _applySystemConfig(config);
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

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    if (_userId.isEmpty) {
      setState(() => _profileError = 'User profile is missing an ID.');
      return;
    }

    setState(() {
      _isSavingProfile = true;
      _profileError = null;
    });

    try {
      final response = await _api.updateUser(
        id: _userId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _value(
          _currentUserDoc,
          const ['password'],
          fallback: 'FarmDemo#2026New',
        ),
        address: _addressController.text.trim(),
        role: _userRole,
        phone: _phoneController.text.trim(),
        department: _userDepartment,
        status: _userStatus,
      );
      final updated = response['user'];
      if (!mounted) return;
      await ref.read(authProvider.notifier).updateCurrentUserProfile(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            address: _addressController.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        if (updated is Map) {
          _currentUserDoc = Map<String, dynamic>.from(updated);
          _populateProfile(_currentUserDoc!);
        }
        _isSavingProfile = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _profileError = error.toString();
        _isSavingProfile = false;
      });
    }
  }

  Future<void> _saveSystemConfig(Map<String, dynamic> patch) async {
    final user = ref.read(authProvider).user;
    setState(() => _isSavingConfig = true);
    try {
      final updated = await _api.updateSystemConfig({
        ..._systemConfig,
        ...patch,
        'updated_by': user?.id ?? user?.email ?? 'farm_owner',
      });
      if (!mounted) return;
      setState(() {
        _applySystemConfig(updated);
        _isSavingConfig = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSavingConfig = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save settings: $error'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showAdaptiveLogoutConfirmation(
      context,
      message: 'Are you sure you want to logout from your owner account?',
    );
    if (!confirmed) return;
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final userName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : authState.user?.name ?? 'Farm Owner';
    final userEmail = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : authState.user?.email ?? '';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? FarmOwnerMobileDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (i) => setState(() => _selectedNavIndex = i),
              userName: userName,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName, themeMode)
          : _buildDesktopLayout(isDark, userName, userEmail, themeMode),
      bottomNavigationBar: isMobile
          ? SafeArea(top: false, child: _buildBottomNavigation(isDark))
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
        FarmOwnerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) => setState(() => _selectedNavIndex = index),
          userName: userName,
          userEmail: userEmail,
          userRole: 'Farm Owner',
        ),
        Expanded(
          child: Column(
            children: [
              FarmOwnerHeader(userName: userName, onNotificationTap: () {}),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
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

  Widget _buildMobileLayout(
    bool isDark,
    String userName,
    ThemeMode themeMode,
  ) {
    return Column(
      children: [
        FarmOwnerHeader(
          userName: userName,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildContent(isDark, true, themeMode),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark, bool isMobile, ThemeMode themeMode) {
    if (_isLoading) return const AdminDataSkeleton(rowCount: 6);
    if (_errorMessage != null) return _buildErrorState(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPageHeader(isDark, isMobile),
        SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
        if (isMobile) ...[
          _buildProfileSection(isDark),
          const SizedBox(height: AppSpacing.md),
          _buildAppearanceSection(isDark, themeMode),
          const SizedBox(height: AppSpacing.md),
          _buildPreferencesSection(isDark),
          const SizedBox(height: AppSpacing.md),
          _buildNotificationsSection(isDark),
          const SizedBox(height: AppSpacing.md),
          _buildSecuritySection(isDark),
          const SizedBox(height: AppSpacing.md),
          _buildAccountActions(isDark),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildProfileSection(isDark),
                    const SizedBox(height: AppSpacing.lg),
                    _buildNotificationsSection(isDark),
                    const SizedBox(height: AppSpacing.lg),
                    _buildAccountActions(isDark),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  children: [
                    _buildAppearanceSection(isDark, themeMode),
                    const SizedBox(height: AppSpacing.lg),
                    _buildPreferencesSection(isDark),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSecuritySection(isDark),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPageHeader(bool isDark, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: AppTypography.h4.copyWith(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your profile, alerts, and owner preferences',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (_isSavingConfig)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: _cardDecoration(isDark),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 42, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to load settings',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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

  Widget _buildProfileSection(bool isDark) {
    final initials = _userName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part[0])
        .take(2)
        .join()
        .toUpperCase();

    return _sectionCard(
      isDark: isDark,
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Profile Information', Icons.person_rounded, isDark),
            const SizedBox(height: AppSpacing.lg),
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
                  ),
                  child: Center(
                    child: Text(
                      initials.isNotEmpty ? initials : 'FO',
                      style: AppTypography.h5.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _userEmail,
                        style: AppTypography.bodySmall.copyWith(
                          color:
                              isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _statusPill('Farm Owner', AppColors.primary),
                          _statusPill(_userStatus, _statusColor(_userStatus)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _profileField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.badge_outlined,
              isDark: isDark,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Enter your full name';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _profileField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              isDark: isDark,
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return 'Enter your email address';
                if (!text.contains('@')) return 'Enter a valid email address';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _profileField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.md),
            _profileField(
              controller: _addressController,
              label: 'Address',
              icon: Icons.location_on_outlined,
              isDark: isDark,
              maxLines: 2,
            ),
            if (_profileError != null) ...[
              const SizedBox(height: AppSpacing.md),
              _inlineMessage(_profileError!, AppColors.error, isDark),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSavingProfile ? null : _saveProfile,
                icon: _isSavingProfile
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_isSavingProfile ? 'Saving...' : 'Save Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(bool isDark, ThemeMode themeMode) {
    return _sectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Appearance', Icons.palette_rounded, isDark),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _themeOption(
                'Light',
                Icons.light_mode_rounded,
                themeMode == ThemeMode.light,
                isDark,
                () =>
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
              ),
              const SizedBox(width: AppSpacing.sm),
              _themeOption(
                'Dark',
                Icons.dark_mode_rounded,
                themeMode == ThemeMode.dark,
                isDark,
                () => ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
              ),
              const SizedBox(width: AppSpacing.sm),
              _themeOption(
                'System',
                Icons.settings_brightness_rounded,
                themeMode == ThemeMode.system,
                isDark,
                () =>
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.system),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(bool isDark) {
    return _sectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Owner Preferences', Icons.tune_rounded, isDark),
          const SizedBox(height: AppSpacing.md),
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
            onChanged: (value) {
              if (value == null) return;
              setState(() => _currency = value);
              _saveSystemConfig({
                'currency_code': _currencyCode(value),
                'currency_symbol': _currencyCode(value),
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _dropdownSetting(
            label: 'Date Format',
            value: _dateFormat,
            options: const ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
            isDark: isDark,
            onChanged: (value) {
              if (value != null) setState(() => _dateFormat = value);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _dropdownSetting(
            label: 'Language',
            value: _language,
            options: const ['English'],
            isDark: isDark,
            onChanged: (value) {
              if (value != null) setState(() => _language = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(bool isDark) {
    return _sectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Notifications', Icons.notifications_rounded, isDark),
          const SizedBox(height: AppSpacing.sm),
          _switchTile(
            'Enable Notifications',
            'Receive system alerts and owner updates',
            Icons.notifications_active_outlined,
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
            isDark,
          ),
          _switchTile(
            'Farm Updates',
            'Activity from your farms and assigned team',
            Icons.agriculture_outlined,
            _farmUpdates,
            (value) => setState(() => _farmUpdates = value),
            isDark,
          ),
          _switchTile(
            'Wallet Alerts',
            'Withdrawal, payout, and revenue notifications',
            Icons.account_balance_wallet_outlined,
            _walletAlerts,
            (value) => setState(() => _walletAlerts = value),
            isDark,
          ),
          _switchTile(
            'Email',
            'Send important alerts to your email',
            Icons.email_outlined,
            _emailNotifications,
            (value) {
              setState(() => _emailNotifications = value);
              _saveSystemConfig({'email_notifications': value});
            },
            isDark,
          ),
          _switchTile(
            'Push Notifications',
            'Mobile notifications for time-sensitive updates',
            Icons.phone_android_rounded,
            _pushNotifications,
            (value) => setState(() => _pushNotifications = value),
            isDark,
          ),
          _switchTile(
            'SMS',
            'Text message alerts for critical items',
            Icons.sms_outlined,
            _smsNotifications,
            (value) {
              setState(() => _smsNotifications = value);
              _saveSystemConfig({'sms_notifications': value});
            },
            isDark,
          ),
          _switchTile(
            'Weekly Report Digest',
            'Summary of production, revenue, and farm status',
            Icons.summarize_outlined,
            _reportDigest,
            (value) => setState(() => _reportDigest = value),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(bool isDark) {
    return _sectionCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Security', Icons.shield_rounded, isDark),
          const SizedBox(height: AppSpacing.sm),
          _switchTile(
            'Session Timeout',
            'Auto logout after $_sessionTimeoutMinutes minutes of inactivity',
            Icons.timer_outlined,
            _sessionTimeout,
            (value) {
              setState(() => _sessionTimeout = value);
              _saveSystemConfig({'session_timeout': value ? 30 : 1440});
            },
            isDark,
          ),
          _actionTile(
            'Change Password',
            'Password updates will use the account security flow',
            Icons.lock_outline,
            () => _showUnavailable(
                'Password update will be connected to auth next.'),
            isDark,
          ),
          _actionTile(
            'Login Activity',
            'Review your recent account access',
            Icons.history_rounded,
            () => _showUnavailable(
                'Login activity is not available for this role yet.'),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(bool isDark) {
    return _sectionCard(
      isDark: isDark,
      borderColor: AppColors.error.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Account Actions',
            Icons.warning_amber_rounded,
            isDark,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Use these actions only when you are done with this session.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: AppTypography.bodyMedium.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color:
                isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color:
                isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
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
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color:
                isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
              items: options
                  .map((option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _themeOption(
    String label,
    IconData icon,
    bool selected,
    bool isDark,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.1)
                : isDark
                    ? Colors.white.withOpacity(0.04)
                    : AppColors.neutral50,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : isDark
                      ? Colors.white.withOpacity(0.08)
                      : AppColors.neutral200,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected
                    ? AppColors.primary
                    : isDark
                        ? Colors.white60
                        : AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: selected
                      ? AppColors.primary
                      : isDark
                          ? Colors.white60
                          : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 19, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _actionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required bool isDark,
    required Widget child,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration(isDark, borderColor: borderColor),
      child: child,
    );
  }

  BoxDecoration _cardDecoration(bool isDark, {Color? borderColor}) {
    return BoxDecoration(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      border: Border.all(
        color: borderColor ??
            (isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200),
      ),
      boxShadow: [
        if (!isDark)
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
      ],
    );
  }

  Widget _sectionHeader(
    String title,
    IconData icon,
    bool isDark, {
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.primary;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: effectiveColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, size: 18, color: effectiveColor),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _inlineMessage(String message, Color color, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? Colors.white : color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'suspended':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  void _showUnavailable(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/farm-owner',
      },
      {
        'icon': Icons.agriculture_outlined,
        'label': 'Farm',
        'index': 1,
        'route': '/farm-owner/farm',
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'Wallet',
        'index': 2,
        'route': '/farm-owner/digital-wallet',
      },
      {
        'icon': Icons.analytics_outlined,
        'label': 'Analytics',
        'index': 3,
        'route': '/farm-owner/analytics',
      },
      {
        'icon': Icons.settings_outlined,
        'label': 'Settings',
        'index': 5,
        'route': '/farm-owner/settings',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            children: navItems.map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final isSelected = index == _selectedNavIndex;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_selectedNavIndex == index) return;
                      setState(() => _selectedNavIndex = index);
                      try {
                        Navigator.pushReplacementNamed(context, route);
                      } catch (_) {
                        Navigator.pushNamed(context, route);
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
                              : isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : AppColors.textSecondary,
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
