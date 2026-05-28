import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/caretaker_header.dart';
import '../../core/widgets/caretaker_mobile_bottom_nav.dart';
import '../../core/widgets/caretaker_sidebar.dart';
import '../../providers/auth_provider.dart';

/// Settings screen for caretaker workflows.
/// Preferences are stored locally on the device using SharedPreferences.
class CareTakerSettingsScreen extends ConsumerStatefulWidget {
  const CareTakerSettingsScreen({super.key});

  @override
  ConsumerState<CareTakerSettingsScreen> createState() =>
      _CareTakerSettingsScreenState();
}

class _CareTakerSettingsScreenState
    extends ConsumerState<CareTakerSettingsScreen> {
  static const _prefPrefix = 'caretaker_settings';

  int _selectedNavIndex = 5;

  bool _taskReminders = true;
  bool _anomalyAlerts = true;
  bool _weatherWarnings = true;
  bool _chatNotifications = true;
  bool _emailSummaries = false;
  bool _soundAlerts = true;

  bool _offlineMode = true;
  bool _autoSyncRecords = true;
  bool _compactCards = false;
  bool _biometricLock = false;

  String _shiftStart = '06:00 AM';
  String _reminderLeadTime = '30 minutes';
  String _defaultLandingPage = 'Dashboard';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _taskReminders = prefs.getBool(_prefKey('taskReminders')) ?? true;
      _anomalyAlerts = prefs.getBool(_prefKey('anomalyAlerts')) ?? true;
      _weatherWarnings = prefs.getBool(_prefKey('weatherWarnings')) ?? true;
      _chatNotifications = prefs.getBool(_prefKey('chatNotifications')) ?? true;
      _emailSummaries = prefs.getBool(_prefKey('emailSummaries')) ?? false;
      _soundAlerts = prefs.getBool(_prefKey('soundAlerts')) ?? true;
      _offlineMode = prefs.getBool(_prefKey('offlineMode')) ?? true;
      _autoSyncRecords = prefs.getBool(_prefKey('autoSyncRecords')) ?? true;
      _compactCards = prefs.getBool(_prefKey('compactCards')) ?? false;
      _biometricLock = prefs.getBool(_prefKey('biometricLock')) ?? false;
      _shiftStart = prefs.getString(_prefKey('shiftStart')) ?? '06:00 AM';
      _reminderLeadTime =
          prefs.getString(_prefKey('reminderLeadTime')) ?? '30 minutes';
      _defaultLandingPage =
          prefs.getString(_prefKey('defaultLandingPage')) ?? 'Dashboard';
    });
  }

  String _prefKey(String key) => '$_prefPrefix.$key';

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey(key), value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey(key), value);
  }

  Future<void> _resetPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final keys = [
      'taskReminders',
      'anomalyAlerts',
      'weatherWarnings',
      'chatNotifications',
      'emailSummaries',
      'soundAlerts',
      'offlineMode',
      'autoSyncRecords',
      'compactCards',
      'biometricLock',
      'shiftStart',
      'reminderLeadTime',
      'defaultLandingPage',
    ];

    for (final key in keys) {
      await prefs.remove(_prefKey(key));
    }

    if (!mounted) return;

    setState(() {
      _taskReminders = true;
      _anomalyAlerts = true;
      _weatherWarnings = true;
      _chatNotifications = true;
      _emailSummaries = false;
      _soundAlerts = true;
      _offlineMode = true;
      _autoSyncRecords = true;
      _compactCards = false;
      _biometricLock = false;
      _shiftStart = '06:00 AM';
      _reminderLeadTime = '30 minutes';
      _defaultLandingPage = 'Dashboard';
    });

    _showMessage('Caretaker preferences reset on this device.');
  }

  Color _primaryTextColor(bool isDark) {
    return isDark ? Colors.white : AppColors.textPrimary;
  }

  Color _secondaryTextColor(bool isDark) {
    return isDark ? AppColors.textOnDark.withOpacity(0.82) : AppColors.textSecondary;
  }

  Color _inactiveNavColor(bool isDark) {
    return isDark ? AppColors.textOnDark.withOpacity(0.75) : AppColors.textSecondary;
  }

  Future<void> _confirmLogout(bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(
          'Sign out',
          style: AppTypography.h6.copyWith(color: _primaryTextColor(isDark)),
        ),
        content: Text(
          'End the current caretaker session on this device?',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _setBoolPreference(
    String key,
    bool value,
    VoidCallback updater,
  ) async {
    setState(updater);
    await _saveBool(key, value);
  }

  Future<void> _setStringPreference(
    String key,
    String value,
    VoidCallback updater,
  ) async {
    setState(updater);
    await _saveString(key, value);
  }

  Future<void> _navigateTo(String route, int index) async {
    if (_selectedNavIndex == index) return;

    setState(() => _selectedNavIndex = index);

    try {
      await Navigator.pushReplacementNamed(context, route);
    } catch (_) {
      if (!mounted) return;
      try {
        await Navigator.pushNamed(context, route);
      } catch (error) {
        _showMessage('Navigation error: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final userName = authState.user?.name ?? 'Caretaker';
    final userEmail = authState.user?.email ?? 'caretaker@farmestates.com';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName, userEmail, themeMode)
          : _buildDesktopLayout(isDark, userName, userEmail, themeMode),
      bottomNavigationBar: isMobile
          ? CaretakerMobileBottomNav(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) => setState(() => _selectedNavIndex = index),
            )
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
        CaretakerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) => setState(() => _selectedNavIndex = index),
          userName: userName,
          userEmail: userEmail,
          userRole: 'Caretaker',
        ),
        Expanded(
          child: Column(
            children: [
              CaretakerHeader(
                userName: userName,
                onNotificationTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _buildContent(isDark, false, userName, userEmail, themeMode),
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
    String userEmail,
    ThemeMode themeMode,
  ) {
    return Column(
      children: [
        CaretakerHeader(
          userName: userName,
          onNotificationTap: () {},
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              100,
            ),
            child: _buildContent(isDark, true, userName, userEmail, themeMode),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    bool isDark,
    bool isMobile,
    String userName,
    String userEmail,
    ThemeMode themeMode,
  ) {
    final leftColumn = Column(
      children: [
        _buildProfileSection(isDark, userName, userEmail),
        const SizedBox(height: AppSpacing.md),
        _buildAppearanceSection(isDark, themeMode),
        const SizedBox(height: AppSpacing.md),
        _buildNotificationSection(isDark),
      ],
    );

    final rightColumn = Column(
      children: [
        _buildWorkPreferencesSection(isDark),
        const SizedBox(height: AppSpacing.md),
        _buildDeviceSection(isDark),
        const SizedBox(height: AppSpacing.md),
        _buildSupportSection(isDark),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroHeader(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        if (isMobile) ...[
          leftColumn,
          const SizedBox(height: AppSpacing.md),
          rightColumn,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leftColumn),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: rightColumn),
            ],
          ),
      ],
    );
  }

  Widget _buildHeroHeader(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.primary.withOpacity(0.22),
                  AppColors.surfaceDark,
                ]
              : [
                  AppColors.primary.withOpacity(0.12),
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.primary.withOpacity(isDark ? 0.3 : 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              'Caretaker Workspace',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Settings',
            style: AppTypography.h4.copyWith(
              color: _primaryTextColor(isDark),
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Control reminders, appearance, offline behavior, and device preferences for daily farm operations.',
            style: AppTypography.bodyMedium.copyWith(
              color: _secondaryTextColor(isDark),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: isDark ? Colors.white.withOpacity(0.9) : AppColors.primaryDark,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Changes save locally on this device immediately.',
                  style: AppTypography.bodySmall.copyWith(
                    color: _secondaryTextColor(isDark),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(bool isDark, String userName, String userEmail) {
    final initials = userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return _sectionCard(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            isDark,
            icon: Icons.person_outline_rounded,
            title: 'Profile',
            subtitle: 'Current account identity for caretaker operations',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Center(
                  child: Text(
                    initials.isEmpty ? 'CT' : initials,
                    style: AppTypography.h6.copyWith(
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
                      userName,
                      style: AppTypography.h6.copyWith(
                        color: _primaryTextColor(isDark),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: AppTypography.bodySmall.copyWith(
                        color: _secondaryTextColor(isDark),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        'Caretaker role',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            isDark,
            icon: Icons.assignment_turned_in_outlined,
            label: 'Primary workspace',
            value: _defaultLandingPage,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            isDark,
            icon: Icons.schedule_outlined,
            label: 'Shift starts',
            value: _shiftStart,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showMessage(
                    'Profile editing is not connected to backend data yet.',
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryTextColor(isDark),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.14)
                          : AppColors.neutral300,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showMessage(
                    'Password management is not wired to authentication yet.',
                  ),
                  icon: const Icon(Icons.lock_outline_rounded, size: 18),
                  label: const Text('Security'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(bool isDark, ThemeMode themeMode) {
    return _sectionCard(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            isDark,
            icon: Icons.palette_outlined,
            title: 'Appearance',
            subtitle: 'Choose how the caretaker workspace looks',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildThemeOption(
            isDark: isDark,
            title: 'Light mode',
            subtitle: 'Higher contrast for bright environments',
            icon: Icons.light_mode_outlined,
            isSelected: themeMode == ThemeMode.light,
            onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildThemeOption(
            isDark: isDark,
            title: 'Dark mode',
            subtitle: 'Reduce glare during night or indoor monitoring',
            icon: Icons.dark_mode_outlined,
            isSelected: themeMode == ThemeMode.dark,
            onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.dashboard_customize_outlined,
            title: 'Compact cards',
            subtitle: 'Use denser cards for more information on screen',
            value: _compactCards,
            onChanged: (value) => _setBoolPreference(
              'compactCards',
              value,
              () => _compactCards = value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(bool isDark) {
    return _sectionCard(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            isDark,
            icon: Icons.notifications_active_outlined,
            title: 'Notifications',
            subtitle: 'Tune alerts for work reminders and incidents',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.task_alt_outlined,
            title: 'Task reminders',
            subtitle: 'Remind me about scheduled field tasks',
            value: _taskReminders,
            onChanged: (value) => _setBoolPreference(
              'taskReminders',
              value,
              () => _taskReminders = value,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.sensors_outlined,
            title: 'Anomaly alerts',
            subtitle: 'Flag unexpected sensor readings immediately',
            value: _anomalyAlerts,
            onChanged: (value) => _setBoolPreference(
              'anomalyAlerts',
              value,
              () => _anomalyAlerts = value,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.cloud_queue_outlined,
            title: 'Weather warnings',
            subtitle: 'Surface weather-driven risk alerts',
            value: _weatherWarnings,
            onChanged: (value) => _setBoolPreference(
              'weatherWarnings',
              value,
              () => _weatherWarnings = value,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Chat notifications',
            subtitle: 'Show alerts for supervisor and team messages',
            value: _chatNotifications,
            onChanged: (value) => _setBoolPreference(
              'chatNotifications',
              value,
              () => _chatNotifications = value,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.mail_outline_rounded,
            title: 'Email summaries',
            subtitle: 'Send daily summaries to the signed-in email address',
            value: _emailSummaries,
            onChanged: (value) => _setBoolPreference(
              'emailSummaries',
              value,
              () => _emailSummaries = value,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.volume_up_outlined,
            title: 'Sound alerts',
            subtitle: 'Play a short tone when critical alerts arrive',
            value: _soundAlerts,
            onChanged: (value) => _setBoolPreference(
              'soundAlerts',
              value,
              () => _soundAlerts = value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkPreferencesSection(bool isDark) {
    return _sectionCard(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            isDark,
            icon: Icons.tune_outlined,
            title: 'Work Preferences',
            subtitle: 'Default behavior for daily caretaker routines',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDropdownField(
            isDark: isDark,
            icon: Icons.schedule_outlined,
            label: 'Shift start time',
            value: _shiftStart,
            items: const ['05:00 AM', '06:00 AM', '07:00 AM', '08:00 AM'],
            onChanged: (value) {
              if (value == null) return;
              _setStringPreference(
                'shiftStart',
                value,
                () => _shiftStart = value,
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDropdownField(
            isDark: isDark,
            icon: Icons.alarm_outlined,
            label: 'Reminder lead time',
            value: _reminderLeadTime,
            items: const ['15 minutes', '30 minutes', '1 hour', '2 hours'],
            onChanged: (value) {
              if (value == null) return;
              _setStringPreference(
                'reminderLeadTime',
                value,
                () => _reminderLeadTime = value,
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDropdownField(
            isDark: isDark,
            icon: Icons.home_outlined,
            label: 'Default landing page',
            value: _defaultLandingPage,
            items: const [
              'Dashboard',
              'Record Entry',
              'Input Confirmation',
              'Calendar',
            ],
            onChanged: (value) {
              if (value == null) return;
              _setStringPreference(
                'defaultLandingPage',
                value,
                () => _defaultLandingPage = value,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSection(bool isDark) {
    return _sectionCard(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            isDark,
            icon: Icons.phone_android_outlined,
            title: 'Device & Data',
            subtitle: 'Control sync, offline handling, and lock behavior',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.cloud_off_outlined,
            title: 'Offline mode',
            subtitle: 'Keep forms usable when connection quality drops',
            value: _offlineMode,
            onChanged: (value) => _setBoolPreference(
              'offlineMode',
              value,
              () => _offlineMode = value,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.sync_outlined,
            title: 'Auto-sync records',
            subtitle: 'Push saved records when connectivity returns',
            value: _autoSyncRecords,
            onChanged: (value) => _setBoolPreference(
              'autoSyncRecords',
              value,
              () => _autoSyncRecords = value,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.fingerprint_outlined,
            title: 'Biometric lock',
            subtitle: 'Require device biometrics before opening the app',
            value: _biometricLock,
            onChanged: (value) => _setBoolPreference(
              'biometricLock',
              value,
              () => _biometricLock = value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(bool isDark) {
    return _sectionCard(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            isDark,
            icon: Icons.shield_outlined,
            title: 'Support & Session',
            subtitle: 'Reset local settings, get help, or end this session',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildActionTile(
            isDark: isDark,
            icon: Icons.help_outline_rounded,
            title: 'Help center',
            subtitle: 'Get guidance for records, alerts, and reporting',
            onTap: () => _showMessage('Help center is not wired into this build yet.'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildActionTile(
            isDark: isDark,
            icon: Icons.restart_alt_rounded,
            title: 'Reset local preferences',
            subtitle: 'Restore the default caretaker settings on this device',
            onTap: _resetPreferences,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildActionTile(
            isDark: isDark,
            icon: Icons.logout_rounded,
            title: 'Sign out',
            subtitle: 'Log out and return to the login screen',
            iconColor: AppColors.error,
            onTap: () => _confirmLogout(isDark),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.h6.copyWith(
                  color: _primaryTextColor(isDark),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: _secondaryTextColor(isDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: _secondaryTextColor(isDark),
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: _primaryTextColor(isDark),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(isDark ? 0.18 : 0.1)
              : (isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.5)
                : (isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.18)
                    : AppColors.neutral300.withOpacity(0.18),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : _secondaryTextColor(isDark),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: _primaryTextColor(isDark),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: _secondaryTextColor(isDark),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected ? AppColors.primary : _secondaryTextColor(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: _primaryTextColor(isDark),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: _secondaryTextColor(isDark),
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

  Widget _buildDropdownField({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: _secondaryTextColor(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : AppColors.neutral300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : AppColors.neutral300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.3,
              ),
            ),
          ),
          style: AppTypography.bodyMedium.copyWith(
            color: _primaryTextColor(isDark),
          ),
          iconEnabledColor: _secondaryTextColor(isDark),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: AppTypography.bodySmall.copyWith(
                      color: _primaryTextColor(isDark),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final resolvedIconColor = iconColor ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: resolvedIconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, size: 20, color: resolvedIconColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: _primaryTextColor(isDark),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: _secondaryTextColor(isDark),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: _secondaryTextColor(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/caretaker_dashboard',
      },
      {
        'icon': Icons.edit_note_outlined,
        'label': 'Record',
        'index': 1,
        'route': '/record-entry',
      },
      {
        'icon': Icons.check_circle_outline,
        'label': 'Confirm',
        'index': 2,
        'route': '/input-confirmation',
      },
      {
        'icon': Icons.chat_bubble_outline,
        'label': 'Chat',
        'index': 3,
        'route': '/chat',
      },
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Calendar',
        'index': 4,
        'route': '/calendar',
      },
      {
        'icon': Icons.settings_outlined,
        'label': 'Settings',
        'index': 5,
        'route': '/caretaker_settings',
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
            color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            children: navItems.map((item) {
              final index = item['index'] as int;
              final isSelected = _selectedNavIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => _navigateTo(item['route'] as String, index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 24,
                        color: isSelected ? AppColors.primary : _inactiveNavColor(isDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'] as String,
                        style: AppTypography.caption.copyWith(
                          color:
                              isSelected ? AppColors.primary : _inactiveNavColor(isDark),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
